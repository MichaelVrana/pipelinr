library(rlang)
library(purrr)

source("./dsl/iterator.R")

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

stage <- function(body, inputs = stage_inputs()) {
    structure(
        list(body = body, input_quosures = inputs),
        body = body,
        input_quosures = inputs
    )
}

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
        c(stage, deps = unique(deps))
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

eval_inputs <- function(stage_results, input_quosures) {
    input_iters <- map(input_quosures, function(input_quo) {
        inputs_expr <- quo_get_expr(input_quo)
        inputs_env <- quo_get_env(input_quo)

        eval_env <- new_environment(data = stage_results, parent = inputs_env)

        input <- eval(inputs_expr, envir = eval_env)

        if (is_iterator(input)) {
            return(input)
        }

        make_iter(input)
    })

    input_iters
}

r_engine <- function(task_group) {
    map(task_group$tasks, function(task) do.call(task$body, task$args)) %>% vec_to_iter()
}

make_gnu_parallel_engine <- function(ssh_login_file = "") function(task_group) {
    if (!exists("gnu_parallel_run_task_group")) devtools::load_all("./engine")
    results <- gnu_parallel_run_task_group(task_group, ssh_login_file)

    map(results, function(result) {
        print(result$stdout)
        print(result$stderr)
        result$result
    }) %>% vec_to_iter()
}

get_stage_task_group <- function(stage, input_iters, tasks = list()) {
    input <- map(input_iters, function(iter) iter$value)

    task <- list(body = stage$body, args = input)

    next_iters <- map(input_iters, function(iter) iter$next_iter())

    all_iters_done <- every(next_iters, function(iter) iter$done)

    next_tasks <- append(tasks, list(task))

    if (all_iters_done) {
        return(list(tasks = next_tasks, id = stage$name))
    }

    get_stage_task_group(stage, next_iters, next_tasks)
}

run_pipeline <- function(pipeline, engine = r_engine) {
    reduce(pipeline$exec_order, function(stage_results, stage) {
        input_iters <- eval_inputs(stage_results, stage$input_quosures)

        task_group <- get_stage_task_group(stage, input_iters)
        results_iter <- engine(task_group)

        new_results <- c(stage_results)
        new_results[[stage$name]] <- results_iter
        new_results
    }, .init = list())
}

mapped <- function(input) vec_to_iter(input$value)
