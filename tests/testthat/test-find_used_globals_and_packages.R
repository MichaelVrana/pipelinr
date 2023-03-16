test_that("It detects globals", {
    foo <- function() 1
    bar <- function() foo()

    actual <- find_used_globals_and_packages(bar)

    expect_equal(actual$globals$foo, foo)
})

test_that("It detects globals from packages", {
    foo <- function(from, to) map(from:to, function(x) x * x)

    bar <- function() foo(1, 3)

    actual <- find_used_globals_and_packages(bar)

    expect_equal(actual$globals$foo, foo)
    expect_equal(actual$packages, "purrr")
})

test_that("It detects packages that are accessed using a namespace", {
    foo <- function(from, to) purrr::map(from:to, function(x) x * x)

    bar <- function() foo(1, 3)

    actual <- find_used_globals_and_packages(bar)

    expect_equal(actual$globals$foo, foo)
    expect_equal(actual$packages, "purrr")
})

test_that("It detects multiple packages that are accessed using a namespace", {
    foo <- function(from, to) purrr::map(from:to, function(x = rlang:::enexpr()) x * x)

    bar <- function() foo(1, 3)

    actual <- find_used_globals_and_packages(bar)

    expect_equal(actual$globals$foo, foo)
    expect_equal(actual$packages, c("purrr", "rlang"))
})
