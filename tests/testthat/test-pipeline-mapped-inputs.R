test_that("Pipeline evaluates mapped input", {
    data <-
        pipeline <- make_pipeline(
            stage1 = stage(inputs = stage_inputs(x = data %>% vec_to_iter()), body = function(x) {
                list(
                    list(number = 1, str = "a"),
                    list(number = 2, str = "b"),
                    list(number = 3, str = "c")
                )
            }),
            stage2 = stage(inputs = stage_inputs(x = mapped(stage1)), body = function(x) {
                list(number = x$number * 2, str = x$str)
            })
        )

    stage_results <- run_pipeline(pipeline)

    actual <- collect(stage_results$results$stage2)

    expect_equal(actual, list(
        list(number = 2, str = "a"),
        list(number = 4, str = "b"),
        list(number = 6, str = "c")
    ))
})
