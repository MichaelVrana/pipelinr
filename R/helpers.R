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

mapped <- function(input) vec_to_iter(input$value)