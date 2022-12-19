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

collect_iter <- function(iter) fold_iter(iter, list(), function(acc, curr) c(acc, curr))

reverse_iter <- function(iter) {
    collect_iter(iter) %>%
        rev() %>%
        vec_to_iter()
}

fold_right_iter <- function(iter, init, fun) fold_iter(reverse_iter(iter), init, fun)

map_iter <- function(iter, fun) {
    fold_right_iter(iter, make_empty_iter(), function(next_iter, value) make_iter(fun(value), next_iter))
}

filter_iter <- function(iter, predicate) {
    fold_right_iter(iter, make_empty_iter(), function(next_iter, value) {
        if (predicate(value)) {
            return(make_iter(value, next_iter))
        }
        next_iter
    })
}

is_iterator <- function(iter_like) is_list(iter_like) && is_function(iter_like$next_iter) && is_logical(iter_like$done)

cross_iter <- function(iter1, iter2) cross2(collect_iter(iter1), collect_iter(iter2)) %>% vec_to_iter()
