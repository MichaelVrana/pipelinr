test_that("It filters iterator values", {
    actual <- vec_to_iter(1:6) %>% filter_iter(., function(num) num %% 2 == 0) %>% collect()
    
    expect_equal(actual, list(2, 4, 6))
})