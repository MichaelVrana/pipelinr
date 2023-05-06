test_that("It creates na iterator of dataframe rows", {
    df <- data.frame(strings = c("a", "b", "c"), numbers = 1:3)

    actual <- df_to_iter(df) %>% collect() %>% dplyr::bind_rows()

    expect_equal(actual, df)
})