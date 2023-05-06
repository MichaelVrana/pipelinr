process_captured_output <- function(output) {
    if (purrr::is_empty(output)) {
        return("")
    }

    paste(output, collapse = "\n")
}

exec_task <- function(stage, task) {
    stdout <- character()
    stderr <- character()

    out_con <- textConnection("stdout", "w", local = TRUE)
    err_con <- textConnection("stderr", "w", local = TRUE)

    capture.output(
        capture.output(
            {
                started_at <- lubridate::now()

                result <- tryCatch(
                    do.call(stage$body, task$args),
                    error = function(e) e
                )

                finished_at <- lubridate::now()
            },
            file = out_con,
            type = "output"
        ),
        file = err_con,
        type = "message"
    )

    close(out_con)
    close(err_con)

    stdout <- process_captured_output(stdout)
    stderr <- process_captured_output(stderr)

    is_error <- inherits(result, "error")

    task_result <- if (is_error) list(error = result, failed = TRUE) else list(result = result, failed = FALSE)

    elapsed <- lubridate::interval(started_at, finished_at) %>%
        lubridate::as.interval()

    task_result_with_metadata <- c(
        task_result,
        stdout = list(stdout),
        stderr = list(stderr),
        started_at = started_at,
        elapsed = elapsed
    )

    task_output_path <- get_task_output_path(stage$name, task$hash)

    qs::qsave(task_result_with_metadata, task_output_path)
}

#' R task executor. This is the default executor that runs tasks in the main R process.
#' @export
r_executor <- function(task_iter, stage) {
    memoized_task_iter <- memoize_iter(task_iter)
    task_count <- iter_length(memoized_task_iter)

    pb <- create_task_execution_progress_bar(stage$name, task_count)

    for_each_iter(memoized_task_iter, function(task) {
        exec_task(stage, task)
        pb$tick()
    })

    pb$terminate()
}
