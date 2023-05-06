partition <- function(iterable, predicate) {
    purrr::reduce(iterable, function(acc, curr) {
        if (predicate(curr)) {
            list(true = append(acc$true, list(curr)), false = acc$false)
        } else {
            list(true = acc$true, false = append(acc$false, list(curr)))
        }
    }, .init = list(true = list(), false = list()))
}

without_name <- function(list, name) list[grep(name, names(list), invert = TRUE)]

merge_lists <- function(...) {
    lists <- list(...)

    keys <- purrr::reduce(lists, function(acc, l) c(names(acc), names(l))) %>% unique()

    purrr::reduce(lists, function(acc, l) {
        if (is.null(acc)) {
            return(l)
        }

        purrr::map2(acc[keys], l[keys], c) %>%
            set_names(keys)
    })
}

set_names <- function(obj, names) {
    names(obj) <- names
    obj
}

to_stage_names <- function(stages) purrr::map_chr(stages, function(stage) stage$name)
