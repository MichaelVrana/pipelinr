test_that("It collects an iterator of data frames", {
    iter <- list(
        tibble::tibble(strings = c("a", "b", "c"), numbers = 1:3),
        tibble::tibble(strings = "d", numbers = 4)
    ) %>% vec_to_iter()

    actual <- collect_df(iter)

    expect_equal(actual, tibble::tibble(strings = c("a", "b", "c", "d"), numbers = 1:4))
})


test_that("It collects an iterator of named lists and merges the into a dataframe", {
    iter <- list(
        list(strings = c("a", "b", "c"), numbers = 1:3),
        list(strings = "d", numbers = 4)
    ) %>% vec_to_iter()

    actual <- collect_df(iter)

    expect_equal(as.data.frame(actual), data.frame(strings = c("a", "b", "c", "d"), numbers = 1:4))
})