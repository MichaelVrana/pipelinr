test_that("It loads pipeline and it doesn't pollute the global env", {
    foo <- "bar"
    pipeline <- load_pipeline()

    expect_equal(foo, "bar")

    expect_equal(names(pipeline$stages), c("a", "b"))
})