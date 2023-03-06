library(rlang)
library(purrr)

find_unbound_body_args <- function(stage) {
    args <- formals(stage$body) %>% names()
    input_names <- stage$input_quosures %>% names()

    if (is.null(args) || is.null(input_names)) {
        return(character())
    }

    unbound <- setdiff(args, input_names)

    if (is_empty(unbound)) {
        return(character())
    }

    names(unbound) <- unbound
    unbound
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
        other_stage_names <- setdiff(stage_names, stage$name)

        deps <- map(stage$input_quosures, function(input_quo) find_deps(input_quo, other_stage_names)) %>%
            flatten() %>%
            unlist()

        unbound_args <- find_unbound_body_args(stage)

        unknown_deps <- setdiff(deps %>% unname(), other_stage_names)

        if (length(unknown_deps) > 0) {
            c("Unbound stage dependencies detected: ", unknown_deps) %>%
                do.call(paste, .) %>%
                stop()
        }

        unbound_arg_quos <- map(unbound_args, function(arg) as.symbol(arg) %>% new_quosure(., env = empty_env())) %>% new_quosures()

        stage$input_quosures <- c(stage$input_quosures, unbound_arg_quos)
        stage$deps <- c(deps, unbound_args) %>% unique()
        stage
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
        new_deps <- setdiff(stage$deps, stage_names_without_deps)

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
