library(purrr)

vec_tail <- function(vec) {
    if (is_empty(vec)) list()
    tail(vec, length(vec) - 1)
}

make_empty_iter <- function() {
    list(value = NULL, done = TRUE, next_iter = make_empty_iter)
}

make_iter <- function(value, next_iter = make_empty_iter()) {
    list(value = value, done = FALSE, next_iter = function() next_iter)
}

vec_to_iter <- function(vec) {
    if (is_empty(vec)) {
        return(make_empty_iter())
    }

    list(value = vec[[1]], done = FALSE, next_iter = function() vec_tail(vec) %>% vec_to_iter())
}

fold_iter <- function(iter, init, fun) {
    fold <- function(iter, acc) {
        if (iter$done) {
            return(acc)
        }

        next_acc <- fun(acc, iter$value)
        fold(iter$next_iter(), next_acc)
    }

    fold(iter, init)
}

collect_iter <- function(iter) fold_iter(iter, list(), function(acc, curr) c(acc, list(curr)))

map_iter <- function(iter, fun) {
    if (iter$done) return(make_empty_iter())
    list(value = fun(iter$value), done = FALSE, next_iter = function() map_iter(iter$next_iter(), fun))
}

filter_iter <- function(iter, predicate) {
    if (iter$done) {
        return(make_empty_iter())
    }

    if (!predicate(iter$value)) {
        return(filter_iter(iter$next_iter(), predicate))
    }

    list(value = iter$value, done = FALSE, next_iter = function() filter_iter(iter$next_iter(), predicate))
}

is_iter <- function(iter_like) is_list(iter_like) && is_function(iter_like$next_iter) && is_logical(iter_like$done)

cross_iter <- function(iter1, iter2) cross2(collect_iter(iter1), collect_iter(iter2)) %>% vec_to_iter()

zip_iter <- function(...) {
    iters <- list(...)

    done <- every(iters, function(iter) iter$done)
    values <- map(iters, function(iter) iter$value)

    next_iter <- function() {
        lift_dl(zip_iter)(map(iters, function(iter) iter$next_iter()))
    }

    list(value = values, done = done, next_iter = next_iter)
}
