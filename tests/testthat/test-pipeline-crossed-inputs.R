test_that("Pipeline evaluates crossed inputs", {
    pipeline <- make_pipeline(
        numbers = stage(body = function(x) {
            1:3
        }),
        strings = stage(body = function(x) {
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

    results <- run_pipeline(pipeline)

    stage_results <- run_pipeline(pipeline)
    
    actual <- collect_iter(stage_results$results$crossed)

    expect_equal(actual, list(
        list(2, "a"),
        list(4, "a"),
        list(6, "a"),
        list(2, "b"),
        list(4, "b"),
        list(6, "b")
    ))
})
