test_that("It zips iterators", {
    numbers <- vec_to_iter(1:3)
    strings <- list("a", "b") %>% vec_to_iter()

    zipped <- zip_iter(numbers, strings) %>% collect()

    expect_equal(zipped, list(
        list(1, "a"),
        list(2, "b"),
        list(3, NULL)
    ))
})
