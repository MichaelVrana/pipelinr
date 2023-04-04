test_that("Pipeline's only filter keeps specified stages", {
    options(pipelinr_dir = "pipeline_filters")

    call_count <- 0

    spy <- function(x) {
        call_count <<- call_count + 1
        x
    }

    pipeline <- make_pipeline(
        a = stage(function() 1:3),
        b = stage(inputs = stage_inputs(x = mapped(a)), spy)
    )

    make(pipeline = pipeline, clean = TRUE)

    expect_equal(call_count, 3)

    call_count <- 0

    pipeline <- make_pipeline(
        a = stage(function() 1),
        b = stage(inputs = stage_inputs(x = mapped(a)), spy)
    )

    make(pipeline = pipeline, only = b, where = TRUE)

    expect_equal(call_count, 3)
})
