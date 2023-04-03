test_that("Pipeline evaluates mapped input", {
    options(pipelinr_dir = "pipeline_mapped")

    pipeline <- make_pipeline(
        stage1 = stage(function() {
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

    stage_results <- make(pipeline = pipeline)

    actual <- collect(stage_results$results$stage2)

    expect_snapshot(actual)
})
