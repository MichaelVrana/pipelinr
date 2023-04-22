test_that("Metadata function retrieves stage metadata", {
    options(pipelinr_dir = "pipeline_metadata")

    gnu_parallel_executor <- make_gnu_parallel_executor(ssh_login_file = "../../ssh_worker/nodefile")

    pipeline <- make_pipeline(
        data = stage(function() list(
            list(number = 1, str = "a"),
            list(number = 2, str = "b"),
            list(number = 3, str = "c")
        )),
        stage1 = stage(inputs = stage_inputs(x = mapped(data)), executor = gnu_parallel_executor, body = function(x) {
            print("This will be in stdout")
            list(number = x$number * 2, str = x$str)
        }),
        metadata_stage = stage(inputs = stage_inputs(x = metadata(stage1)), body = function(x) x)
    )

    make(pipeline = pipeline, clean = TRUE)

    stdout <- read(metadata_stage) %>% map(., function(meta) meta$stdout)

    expect_equal(stdout, map(1:3, function(x) '[1] "This will be in stdout"'))
})

test_that("It correctly serializes function with it's globals", {
    options(pipelinr_dir = "pipeline_globals")

    gnu_parallel_executor <- make_gnu_parallel_executor(ssh_login_file = "../../ssh_worker/nodefile")

    foo <- 1
    bar <- function() foo + 1

    pipeline <- make_pipeline(
        s = stage(body = function() {
            bar()
        })
    )

    make(
        pipeline = pipeline,
        executor = gnu_parallel_executor,
        clean = TRUE
    )

    actual <- read(s)

    expect_equal(actual, list(2))
})