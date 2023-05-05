library(rlang)
library(purrr)

find_unbound_body_args <- function(stage) {
    args <- formals(stage$body) %>% names()
    input_names <- stage$input_quosures %>% names()

    if (is.null(args) || is.null(input_names)) {
        return(character())
    }

    unbound <- setdiff(args, input_names)

    if (purrr::is_empty(unbound)) {
        return(character())
    }

    names(unbound) <- as.character(unbound)
    unbound
}

find_deps <- function(input_quo, other_stage_names) {
    inputs_expr <- rlang::quo_get_expr(input_quo)

    symbols <- find_symbols(inputs_expr)

    purrr::keep(symbols, function(symbol) {
        purrr::has_element(other_stage_names, symbol)
    })
}

with_names <- function(stages) {
    purrr::imap(stages, function(stage, stage_name) c(stage, name = stage_name))
}

with_deps <- function(stages) {
    stage_names <- names(stages)

    purrr::map(stages, function(stage) {
        other_stage_names <- setdiff(stage_names, stage$name)

        deps <- purrr::map(stage$input_quosures, function(input_quo) find_deps(input_quo, other_stage_names)) %>%
            purrr::flatten() %>%
            unlist()

        unbound_args <- find_unbound_body_args(stage)

        unknown_deps <- setdiff(deps %>% unname(), other_stage_names)

        if (!purrr::is_empty(unknown_deps)) {
            c("Unbound stage dependencies detected: ", unknown_deps) %>%
                do.call(paste, .) %>%
                stop()
        }

        unbound_arg_quos <- purrr::map(unbound_args, function(arg) {
            as.symbol(arg) %>% rlang::new_quosure(., env = rlang::empty_env())
        }) %>% rlang::new_quosures()

        stage$input_quosures <- c(stage$input_quosures, unbound_arg_quos)
        stage$deps <- c(deps, unbound_args) %>% unique()
        stage
    })
}

topsort <- function(stages, sorted_stages = list()) {
    if (purrr::is_empty(stages)) {
        return(sorted_stages)
    }

    sorted_stage_names <- to_stage_names(sorted_stages)

    partitioned_stages <- partition(stages, function(stage) {
        setdiff(stage$deps, sorted_stage_names) %>% purrr::is_empty()
    })

    stages_without_deps <- partitioned_stages$true
    stages_with_deps <- partitioned_stages$false

    if (purrr::is_empty(stages_without_deps)) {
        stop("Cycle in stage dependencies detected")
    }

    topsort(stages_with_deps, append(sorted_stages, stages_without_deps))
}

with_stage_names <- function(stages) {
    purrr::map_chr(stages, function(stage) stage$name) %>% purrr::set_names(stages, .)
}

#' Create a pipeline. Pipelines consists of stages constructed by `stage`. Each argument must be named and must be a stage object.
#' @export
#' @examples
#'
#' pipeline <- make_pipeline(
#'     numbers = stage(function() 1:3),
#'     doubled = stage(function(numbers) numbers * 2),
#'     squared = stage(
#'         inputs = stage_inputs(
#'             num = mapped(doubled_numbers)
#'         ),
#'         body = function(num) num * num
#'     )
#' )
#'
make_pipeline <- function(...) {
    stages <- list(...) %>%
        with_names() %>%
        with_deps() %>%
        topsort() %>%
        with_stage_names()

    list(stages = stages)
}
