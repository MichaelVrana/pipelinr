test_that("It maps iterator values", {
    actual <- vec_to_iter(1:3) %>% map_iter(., function(num) num * 2) %>% collect_iter()
    
    expect_equal(actual, list(2, 4, 6))
})