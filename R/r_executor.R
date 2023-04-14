library(rlang)
library(purrr)
library(qs)
library(lubridate)

exec_task <- function(stage, task) {
    stdout <- character()
    stderr <- character()

    out_con <- textConnection("stdout", "w", local = TRUE)
    err_con <- textConnection("stderr", "w", local = TRUE)

    capture.output(
        capture.output(
            {
                started_at <- now()

                result <- tryCatch(
                    do.call(stage$body, task$args),
                    error = function(e) e
                )

                finished_at <- now()
            },
            file = out_con,
            type = "output"
        ),
        file = err_con,
        type = "message"
    )

    close(out_con)
    close(err_con)

    is_error <- inherits(result, "error")

    if (is_error) print(result)

    task_result <- if (is_error) list(error = result, failed = TRUE) else list(result = result, failed = FALSE)

    duration <- interval(started_at, finished_at) |> as.interval()

    task_result_with_metadata <- c(
        task_result,
        stdout = list(stdout),
        stderr = list(stderr),
        started_at = started_at,
        duration = duration
    )

    task_output_path <- get_task_output_path(stage$name, task$hash)

    qsave(task_result_with_metadata, task_output_path)
}

#' R task executor. This is the default executor that runs tasks in the main R process.
#' @export
r_executor <- function(task_iter, stage) {
    memoized_task_iter <- memoize_iter(task_iter)
    task_count <- iter_length(memoized_task_iter)

    bar <- create_task_execution_progress_bar(stage$name, task_count)

    for_each_iter(memoized_task_iter, function(task) {
        exec_task(stage, task)
        bar$tick()
    })
}
