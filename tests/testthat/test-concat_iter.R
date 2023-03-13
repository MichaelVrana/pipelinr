test_that("It concatenates iterators", {
    iter1 <- vec_to_iter(1:3)
    iter2 <- vec_to_iter(c("a", "b", "c"))

    actual <- concat_iter(iter1, iter2) %>% collect()

    expect_equal(actual, list(1, 2, 3, "a", "b", "c"))
})

test_that("It returns empty iter when no arguments are provided", {
    iter <- concat_iter()

    expect_equal(iter$done, TRUE)
})

test_that("It correctly concatenates empty iterator", {
    iter <- vec_to_iter(1:3)

    actual <- concat_iter(make_empty_iter(), iter) %>% collect() %>% unlist()

    expect_equal(actual, 1:3)
})