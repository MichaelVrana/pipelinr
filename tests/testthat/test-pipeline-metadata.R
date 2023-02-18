test_that("Metadata function retrieves stage metadata", {
    data <- list(
        list(number = 1, str = "a"),
        list(number = 2, str = "b"),
        list(number = 3, str = "c")
    )

    pipeline <- make_pipeline(
        stage1 = stage(inputs = stage_inputs(x = data %>% vec_to_iter()), body = function(x) {
            print("stage1 called")
            print(x)
            list(number = x$number * 2, str = x$str)
        }),
        metadata_stage = stage(inputs = stage_inputs(metadata = metadata(stage1)), body = function(metadata) metadata)
    )

    results <- run_pipeline(pipeline, pipeline_dir = "tests/testthat/resources/pipeline")

    print(results)
})
