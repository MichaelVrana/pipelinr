test_that("it serializes function with globals", {
    foo <- function() 1
    bar <- function() foo()

    actual <- find_used_globals_and_packages(bar)

    expect_equal(actual$globals$foo, foo)
})

test_that("it serializes function and detects correct packages", {
    foo <- function(from, to) map(from:to, function(x) x * x)

    bar <- function() foo(1, 3)

    actual <- find_used_globals_and_packages(bar)

    expect_equal(actual$globals$foo, foo)
    expect_equal(actual$packages, "purrr")
})
