test_that("Implicit dependency is correctly detected", {
    pipeline <- make_pipeline(
        a = stage(function() 1:3),
        b = stage(function(a) a * 2)
    )

    results <- run_pipeline(pipeline)

    expect_equal(results$results$b$value, c(2, 4, 6))
})
