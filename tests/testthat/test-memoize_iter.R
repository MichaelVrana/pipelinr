test_that("It caches values", {
    call_count <- 0

    spy <- function(x) {
        call_count <<- call_count + 1
        x
    }

    iter <- vec_to_iter(1:3) %>%
        map_iter(., spy) %>%
        memoize_iter()


    expect_equal(iter$next_iter()$value, 2)

    expect_equal(collect_iter(iter), as.list(1:3))

    expect_equal(call_count, 3)
})
