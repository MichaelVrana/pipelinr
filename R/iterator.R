library(utils)
library(purrr)
library(dplyr)

make_empty_iter <- function() {
    list(value = NULL, done = TRUE, next_iter = make_empty_iter)
}

make_iter <- function(value, next_iter = make_empty_iter) {
    list(value = value, done = FALSE, next_iter = next_iter)
}

vec_to_iter <- function(vec) {
    if (is_empty(vec)) {
        return(make_empty_iter())
    }

    make_iter(
        value = vec[[1]],
        next_iter = function() tail(vec, -1) %>% vec_to_iter()
    )
}

df_to_iter <- function(df) {
    if (nrow(df) == 0) {
        return(make_empty_iter())
    }

    make_iter(
        value = head(df, n = 1),
        next_iter = function() tail(df, n = -1) %>% df_to_iter()
    )
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

collect <- function(iter) fold_iter(iter, list(), function(acc, curr) c(acc, list(curr)))

collect_df <- function(iter) {
    collected <- collect(iter)

    if (every(collected, is.data.frame)) {
        return(bind_rows(collected))
    }

    lapply(collected, as.data.frame) %>% bind_rows()
}

map_iter <- function(iter, fun) {
    if (iter$done) {
        return(make_empty_iter())
    }

    make_iter(
        value = fun(iter$value),
        next_iter = function() map_iter(iter$next_iter(), fun)
    )
}

filter_iter <- function(iter, predicate) {
    if (iter$done) {
        return(make_empty_iter())
    }

    if (!predicate(iter$value)) {
        return(filter_iter(iter$next_iter(), predicate))
    }

    make_iter(
        value = iter$value,
        next_iter = function() filter_iter(iter$next_iter(), predicate)
    )
}

is_iter <- function(iter_like) is_list(iter_like) && is_function(iter_like$next_iter) && is_logical(iter_like$done)

cross_iter <- function(iter1, iter2) cross2(collect(iter1), collect(iter2)) %>% vec_to_iter()

# cross_iter <- function(...) {
#     original_iters <- list(...)

#     cross <- function(iters) {
#         if (all(iters, function(iter) iter$done)) return(make_empty_iter())

#         next_iter <- function() {
#             iterate <- TRUE

#             imap(iters, function(iter, idx) {
#                 if (!iterate) return(iter)

#                 new_iter <- iter$next_iter()

#                 if (iter$done) return(original_iters[[idx]])

#                 iterate <- FALSE
#                 iter <-
#             }) %>% cross()
#         }

#         list(value = map(iters, function(iter) iter$value, done = false, next_iter = next_iter))
#     }
# }

zip_iter <- function(...) {
    iters <- list(...)

    done <- every(iters, function(iter) iter$done)

    if (done) {
        return(make_empty_iter())
    }

    values <- map(iters, function(iter) iter$value)

    next_iter <- function() {
        do.call(zip_iter, map(iters, function(iter) iter$next_iter()))
    }

    make_iter(value = values, next_iter = next_iter)
}

memoize_iter <- function(iter) {
    next_iter_cache <- list()

    make_memoize_iter <- function(iter, cache_idx = 1) {
        if (iter$done) {
            return(make_empty_iter())
        }

        next_iter <- function() {
            if (length(next_iter_cache) >= cache_idx) {
                return(next_iter_cache[[cache_idx]])
            }

            new_iter <- make_memoize_iter(iter$next_iter(), cache_idx + 1)
            next_iter_cache[[cache_idx]] <<- new_iter
            new_iter
        }

        make_iter(value = iter$value, next_iter = next_iter)
    }

    make_memoize_iter(iter)
}

head_iter <- function(iter, n) {
    if (n < 0) stop("Cannot take negative number of elements from head", n)

    if (iter$done || n == 0) {
        return(make_empty_iter())
    }

    make_iter(
        value = iter$value,
        next_iter = function() head_iter(iter$next_iter(), n - 1)
    )
}

concat_iter <- function(...) {
    iters <- list(...)

    if (length(iters) == 0) {
        return(make_empty_iter())
    }

    if (length(iters) == 1) {
        return(iters[[1]])
    }

    curr_iter <- iters[[1]]
    iters_tail <- tail(iters, n = 1)

    if (iters[[1]]$done) {
        return(do.call(concat_iter, iters_tail))
    }

    make_iter(
        value = curr_iter$value,
        next_iter = function() {
            next_iters <- c(
                list(curr_iter$next_iter()),
                iters_tail
            )

            do.call(concat_iter, next_iters)
        }
    )
}
