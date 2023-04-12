test_that("Pipeline evaluates crossed inputs", {
    options(pipelinr_dir = "pipeline_crossed")

    pipeline <- make_pipeline(
        numbers = stage(function() {
            1:3
        }),
        strings = stage(function() {
            list("a", "b")
        }),
        doubled_numbers = stage(
            inputs = stage_inputs(number = mapped(numbers)),
            body = function(number) number * 2
        ),
        crossed = stage(
            inputs = stage_inputs(doubled_nums_with_strs = cross_iter(doubled_numbers, mapped(strings))),
            body = function(doubled_nums_with_strs) doubled_nums_with_strs
        )
    )

    make(pipeline = pipeline)

    actual <- read(crossed)

    expect_snapshot(actual)
})
