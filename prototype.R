library(rlang)
library(purrr)

filter <- function(iterable, predicate) {
    reduce(iterable, function(acc, curr) {
        if (predicate(curr)) {
            append(acc, curr)
        } else {
            acc
        }
    }, .init = list())
}

find_symbols <- function(expr) {
    if (is_syntactic_literal(expr)) return(list())
    if (is.symbol(expr)) return(list(as_string(expr)))

    flatten(map(as.list(expr), find_symbols))
}

stage <- function(body, inputs) c(body = body, inputs_quo = enquo(inputs))

find_deps <- function(other_stage_names, stage) {
    filter(other_stage_names, function(stage_name) {
        inputs_expr <- quo_get_expr(stage$inputs_quo)
        inputs_env <- quo_get_env(stage$inputs_quo)

        symbols <- find_symbols(inputs_expr)

        filter(symbols, function(symbol) {
            !env_has(inputs_env, symbol) && other_stage_names
        })
    })
}


with_deps <- function(stages) {
    stage_names <- names(stages)

    map(stage_names, function(stage_name) {
        other_stage_names <- filter(stage_names, function(name) name != stage_name)
        stage <- stages[[stage_name]]

        deps <- find_deps(other_stage_names, stage)
        print(deps)
        c(stage, deps = deps)
    })
}

make_pipeline <- function(...) {
    stages <- with_deps(list(...))
    # print(stages)
}

stage1 <- stage(body = function(x) x, inputs = c(str = "abc", number = 1))

stage2 <- stage(body = function(x) {
    x + 1
}, inputs = c(x = a))

pipeline <- make_pipeline(
    a = stage1,
    b = stage2
)
