library(utils)
library(purrr)
library(dplyr)

#' Create an empty iterator returning no values.
#' @export
#'
make_empty_iter <- function() {
    list(value = NULL, done = TRUE, next_iter = make_empty_iter)
}

#' Create an iterator returning a given value.
#'
#' @param value A value to be returned by the iterator.
#' @param next_iter Used to specify the next iterator, defaults to empty iterator.
#' @export
#' 
make_iter <- function(value, next_iter = make_empty_iter) {
    list(value = value, done = FALSE, next_iter = next_iter)
}

#' Create an iterator of a vector or a list.
#' @param vec A vector or a list.
#' @export
#' 
vec_to_iter <- function(vec) {
    if (is_empty(vec)) {
        return(make_empty_iter())
    }

    make_iter(
        value = vec[[1]],
        next_iter = function() tail(vec, -1) %>% vec_to_iter()
    )
}

#' Create an iterator over data frame rows
#' @param df A data frame
#' @export
#' 
df_to_iter <- function(df) {
    if (nrow(df) == 0) {
        return(make_empty_iter())
    }

    make_iter(
        value = head(df, n = 1),
        next_iter = function() tail(df, n = -1) %>% df_to_iter()
    )
}

#' Fold an iterator to a single value using a function
#' @param iter An iterator to fold
#' @param init Initial value of the accumulator
#' @param fun A folding function accepting two arguments, first is a previous result and second is the current element
#' @export
#' @examples
#' 
#' iter <- vec_to_iter(1:5)
#' sum <- fold_iter(iter, init = 0, fun(acc, curr) acc + curr)
#' sum == 1 + 2 + 3 + 4 + 5
#' 
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

#' Collect an iterator to a list of values
#' @param iter Iterator
#' @export
#' @examples
#' 
#' iter <- vec_to_iter(1:3)
#' collected <- collect(iter)
#' collected == as.list(1:3)
#' 
collect <- function(iter) fold_iter(iter, list(), function(acc, curr) c(acc, list(curr)))

#' Collect an iterator of named lists or dataframes into a data frame
#' @param iter An iterator returning named lists
#' @export
#' @examples
#' 
#' data <- list(
#'      list(numbers = 1, string = "a"),
#'      data.frame(numbers = 2:3, strings = c("b", "c"))
#' )
#' 
#' iter <- vec_to_iter(data)
#' collected <- collect_df(iter)
#' collected == data.frame(numbers = 1:3, strings = c("a", "b", "c"))
#' 
collect_df <- function(iter) {
    collected <- collect(iter)

    if (every(collected, is.data.frame)) {
        return(bind_rows(collected))
    }

    lapply(collected, as.data.frame) %>% bind_rows()
}

#' Map values of an iterator using a function
#' @param iter An iterator
#' @param fun A mapping function accepting a single argument
#' @export 
#' @examples
#' 
#' iter <- vec_to_iter(1:3)
#' mapped_iter <- map_iter(iter, function(x) x * 2)
#' collected <- collect(mapped_iter)
#' collected == list(2, 4, 6)
#' 
map_iter <- function(iter, fun) {
    if (iter$done) {
        return(make_empty_iter())
    }

    make_iter(
        value = fun(iter$value),
        next_iter = function() map_iter(iter$next_iter(), fun)
    )
}

#' Filter an iterators values using a predicate function
#' @param iter An iterator
#' @param predicate A predicate function taking a single argument and returning a boolean
#' @export
#' @examples 
#' 
#' iter <- vec_to_iter(1:5)
#' filtered_iter <- filter_iter(iter, function(x) x %% 2 == 0)
#' collected <- collect(filtered_iter)
#' collected == list(2, 4)
#' 
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

#' Check if a value is an iterator
#' @param iter_like A value to check
#' @export
#' 
is_iter <- function(iter_like) is_list(iter_like) && is_function(iter_like$next_iter) && is_logical(iter_like$done)

#' Create a cross-product of two vectors
#' @param iter1 An iterator
#' @param iter2 An iterator
#' @export
#' @examples
#' 
#' numbers <- vec_to_iter(1:3)
#' strings <- c("a", "b") |> vec_to_iter()
#' crossed <- cross_iter(numbers, string)
#' collected <- collect_iter(crossed)
#' collected == list(
#'     list(1, "a"),
#'     list(1, "b"),
#'     list(2, "a"),
#'     list(2, "b"),
#'     list(3, "a"),
#'     list(3, "b"),
#' )
#' 
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

#' Zips iterators together into a single iterator
#' @export
#' @examples
#' 
#' numbers <- vec_to_iter(1:3)
#' strings <- c("a", "b") |> vec_to_iter()
#' zipped <- zip_iter(numbers = numbers, strings = strings)
#' collected <- collect(zipped)
#' collected = list(
#'     list(1, "a")
#'     list(2, "b")
#'     list(3, NULL)
#' )
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

#' Creates an iterator that will cache returned values
#' @param iter An iterator whose values will be cached
#' @export
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

#' Take top `n` return by an iterator
#' @param iter An iterator
#' @param n An integer
#' @export
#' @examples
#' 
#' iter <- vec_to_iter(1:5)
#' head <- head_iter(iter, 3)
#' collected <- collect(iter)
#' collected == as.list(1:3)
#' 
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

#' Chain iterators together
#' @export
#' @examples
#' 
#' numbers <- vec_to_iter(1:3)
#' strings <- c("a", "b") |> vec_to_iter()
#' concatenated <- concat_iter(numbers, strings)
#' collected <- collect(concatenated)
#' collected == list(1, 2, 3, "a", "b")
#' 
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

for_each_iter <- function(iter, fun) {
    if (iter$done) return(NULL)
    fun(iter$value)
    for_each_iter(iter$next_iter(), fun)
}