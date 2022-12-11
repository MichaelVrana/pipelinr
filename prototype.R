library(rlang)
library(purrr)

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

    flatten(map(as.list(expr), find_symbols))
}

stage <- function(body, inputs) c(body = body, inputs_quo = enquo(inputs))

find_deps <- function(stage, other_stage_names) {
    inputs_expr <- quo_get_expr(stage$inputs_quo)
    inputs_env <- quo_get_env(stage$inputs_quo)

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

        deps <- find_deps(stage, other_stage_names)
        c(stage, deps = list(deps))
    })
}

topsort <- function(stages) {
    if (is_empty(stages)) return(list())

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

stage1 <- stage(body = function(x) x, inputs = c(str = "abc", number = 1))

stage2 <- stage(body = function(x) {
    x + 1
}, inputs = c(x = a))

pipeline <- make_pipeline(
    a = stage1,
    b = stage2
)

print(pipeline)
