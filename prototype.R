library(rlang)
library(purrr)

source("iterator.R")

partition <- function(iterable, predicate) {
    reduce(iterable, function(acc, curr) {
        if (predicate(curr)) {
            list(true = append(acc$true, list(curr)), false = acc$false)
        } else {
            list(true = acc$true, false = append(acc$false, list(curr)))
        }
    }, .init = list(true = list(), false = list()))
}

find_symbols <- function(expr) {
    if (is_syntactic_literal(expr)) {
        return(list())
    }

    if (is.symbol(expr)) {
        return(list(as_string(expr)))
    }

    map(as.list(expr), find_symbols) %>% flatten()
}

stage_inputs <- function(...) enquos(...)

stage <- function(body, inputs) list(body = body, input_quosures = inputs)

find_deps <- function(input_quo, other_stage_names) {
    inputs_expr <- quo_get_expr(input_quo)
    inputs_env <- quo_get_env(input_quo)

    symbols <- find_symbols(inputs_expr)

    keep(symbols, function(symbol) {
        !env_has(inputs_env, symbol) && has_element(other_stage_names, symbol)
    })
}

with_names <- function(stages) {
    imap(stages, function(stage, stage_name) c(stage, name = stage_name))
}

with_deps <- function(stages) {
    stage_names <- names(stages)

    map(stages, function(stage) {
        other_stage_names <- discard(stage_names, function(name) name == stage$name)

        deps <- map(stage$input_quosures, function(input_quo) find_deps(input_quo, other_stage_names))
        c(stage, deps = deps)
    })
}

topsort <- function(stages) {
    if (is_empty(stages)) {
        return(list())
    }

    partitioned_stages <- partition(stages, function(stage) is_empty(stage$deps))

    stages_without_deps <- partitioned_stages$true
    stages_with_deps <- partitioned_stages$false

    if (is_empty(stages_without_deps)) {
        stop("Cycle in stage dependencies detected")
    }

    stage_names_without_deps <- map(stages_without_deps, function(stage) stage$name)

    stages_with_new_deps <- map(stages_with_deps, function(stage) {
        new_deps <- discard(stage$deps, function(dep) {
            has_element(stage_names_without_deps, dep)
        })

        new_stage <- c(stage)
        new_stage$deps <- new_deps
        new_stage
    })

    topsorted_stages_with_new_deps <- topsort(stages_with_new_deps)

    append(stages_without_deps, topsorted_stages_with_new_deps)
}

make_pipeline <- function(...) {
    stages <- list(...) %>%
        with_names() %>%
        with_deps()

    list(stages = stages, exec_order = topsort(stages))
}

mapped_input <- function(iterable) list(input = iterable, is_mapped = TRUE)

is_mapped <- function(input) {
    input_as_list <- as.list(input)
    !is.null(input_as_list$is_mapped) && input_as_list$is_mapped
}

eval_inputs <- function(stage_results, input_quosures) {
    inputs <- map(input_quosures, function(input_quo) {
        inputs_expr <- quo_get_expr(input_quo)
        inputs_env <- quo_get_env(input_quo)

        eval_env <- new_environment(data = stage_results, parent = inputs_env)

        input <- eval(inputs_expr, envir = eval_env)

        if (is_iterator(input)) {
            return(input)
        }

        make_iter(input)
    })

    processed_inputs <- map(inputs, function(input) {
        if (is_mapped(input)) {
            input$input
        } else {
            list(input)
        }
    }) %>% transpose()

    contains_mapped_input <- some(inputs, is_mapped)

    list(contains_mapped_input = contains_mapped_input, inputs = processed_inputs)
}

run_pipeline <- function(pipeline) {
    reduce(pipeline$exec_order, function(stage_results, stage) {
        inputs <- eval_inputs(stage_results, stage$input_quosures)

        result <- map(inputs$inputs, function(input) do.call(stage$body, input))

        new_results <- c(stage_results)
        new_results[[stage$name]] <- if (inputs$contains_mapped_input) mapped(result) else result
        new_results
    }, .init = list())
}
