test_that("Pipeline's only filter keeps specified stages", {
    options(pipelinr_dir = "pipeline_filters")

    pipeline <- make_pipeline(
        a = stage(function() 1:3),
        b = stage(inputs = stage_inputs(x = mapped(a)), body =  function(x) x)
    )

    make(pipeline = pipeline, clean = TRUE)

    expect_equal(read(b) %>% length(), 3)

    pipeline <- make_pipeline(
        a = stage(function() 1),
        b = stage(inputs = stage_inputs(x = mapped(a)), body = function(x) x)
    )

    make(pipeline = pipeline, only = b, where = TRUE)

    expect_equal(read(b) %>% length(), 3)
})
