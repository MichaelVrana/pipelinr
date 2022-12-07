library(rlang)
library(purrr)

filter <- function(iterable, predicate) {
    reduce(iterable, function(acc, curr) {
        if (predicate(acc)) {
            append(acc, curr)
        } else {
            acc
        }
    }, .init = list())
}

stage <- function(body, inputs) c(body = body, inputs = enquo(inputs))

find_exprs_stage_symbols <- function(stage_symbols, expr) {
    if (is_symbol(expr) && has_element(stage_symbols, as_string(expr))) {
        as_list
    }
}

find_deps <- function(other_stage_names, stage) {
    filter(other_stage_names, function(stage_name) env_has(stage$env, stage_name, inherit = TRUE))
}

with_deps <- function(stage_names, stages) {}

make_graph <- function(stage_names, stages) {
    stage_names <- names(stages)
}

make_pipeline <- function(...) {
    stages <- list(...)
}

stage1 <- stage(body = function(x) x, inputs = c(str = "abc", number = 1))

pipeline <- make_pipeline(
    a = stage1
)
