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

    map(as.list(expr), find_symbols) %>% purrr::flatten()
}

without_name <- function(list, name) list[grep(name, names(list), invert = TRUE)]

merge_lists <- function(...) {
    lists <- list(...)

    keys <- reduce(lists, function(acc, l) c(names(acc), names(l))) %>% unique()

    reduce(lists, function(acc, l) {
        if (is.null(acc)) {
            return(l)
        }

        map2(acc[keys], l[keys], c) %>%
            set_names(keys)
    })
}

#' DSL function to create a task for each value in `input`.
#' If the `input` is not an iterator, it will be converted into one using `make_iter`.
#'
#' Returns an iterator for each value in each returned value in the `input` iterator. If it encounters a dataframe, it will be mapped by each row.
#' @param input A stage output
#' @export
mapped <- function(input) {
    iter <- if (is_iter(input)) input else make_iter(input)

    fold_iter(iter, init = make_empty_iter(), function(prev_iter, curr) {
        curr_iter <- if (is.data.frame(curr)) df_to_iter(curr) else vec_to_iter(curr)
        concat_iter(prev_iter, curr_iter)
    })
}

set_names <- function(obj, names) {
    names(obj) <- names
    obj
}

to_stage_names <- function(stages) map_chr(stages, function(stage) stage$name)

stage_results_iter_from_symbol <- function(stage_symbol) {
    if (!is.symbol(stage_symbol)) stop("Invalid stage identifier")

    stage_name <- toString(stage_symbol)
    stage_dir <- get_stage_dir(stage_name)

    if (!dir.exists(stage_dir)) paste("Couldn't find results for stage", stage_name) %>% stop()

    stage_results_iter(stage_name)
}

read <- function(stage_symbol) {
    enexpr(stage_symbol) %>%
        stage_results_iter_from_symbol() %>%
        collect()
}

read_df <- function(stage_symbol) {
    enexpr(stage_symbol) %>%
        stage_results_iter_from_symbol() %>%
        collect_df()
}

stage_metadata_iter_from_symbol <- function(stage_symbol) {
    if (!is.symbol(stage_symbol)) stop("Invalid stage identifier")

    stage_name <- toString(stage_symbol)
    stage_dir <- get_stage_dir(stage_name)

    if (!dir.exists(stage_dir)) paste("Couldn't find metadata for stage", stage_name) %>% stop()

    stage_metadata_iter(stage_name)
}

metadata <- function(stage_symbol) {
    enexpr(stage_symbol) %>%
        stage_metadata_iter_from_symbol() %>%
        collect()
}

metadata_df <- function(stage_symbol) {
    enexpr(stage_symbol) %>%
        stage_metadata_iter_from_symbol() %>%
        collect_df()
}