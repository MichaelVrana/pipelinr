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

    map(as.list(expr), find_symbols) %>% flatten()
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

mapped <- function(input) {
    iter <- if (is_iter(input)) input else make_iter(input)

    fold_iter(iter, init = make_empty_iter(), function(prev_iter, curr) {
        curr_iter <- if (is.data.frame(curr)) df_to_iter(curr) else vec_to_iter(curr)
        concat_iter(prev_iter, curr_iter)
    })
}
