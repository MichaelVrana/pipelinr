test_that("Metadata function retrieves stage metadata", {
    options(pipeline_dir = "../resources/pipeline_metadata")

    data <- list(
        list(number = 1, str = "a"),
        list(number = 2, str = "b"),
        list(number = 3, str = "c")
    )

    gnu_parallel_executor <- make_gnu_parallel_executor(ssh_login_file = "../test_worker/nodefile")

    pipeline <- make_pipeline(
        stage1 = stage(inputs = stage_inputs(x = data %>% vec_to_iter()), override_executor = gnu_parallel_executor, body = function(x) {
            print("This will be in stdout")
            list(number = x$number * 2, str = x$str)
        }),
        metadata_stage = stage(inputs = stage_inputs(x = metadata(stage1)), body = function(x) x)
    )

    results <- run_pipeline(pipeline)

    stdout <- map_iter(results$results$metadata_stage, function(meta) meta$outputs$stdout) %>%
        collect()

    expect_equal(stdout, map(1:3, function(x) "[1] \"This will be in stdout\"\n"))
})

test_that("It correctly serializes function with it's globals", {
    options(pipeline_dir = "../resources/pipeline_globals")

    gnu_parallel_executor <- make_gnu_parallel_executor(ssh_login_file = "../test_worker/nodefile")

    foo <- 1
    bar <- function() foo + 1

    pipeline <- make_pipeline(
        s = stage(body = function() {
            bar()
        })
    )

    outputs <- run_pipeline(
        pipeline,
        executor = gnu_parallel_executor,
    )

    expect_equal(outputs$results$s$value, 2)
})
