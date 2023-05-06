library(tools)
suppressPackageStartupMessages(library(qs))
suppressPackageStartupMessages(library(lubridate))

process_captured_output <- function(output) {
    if (length(output) == 0) {
        return("")
    }

    paste(output, collapse = "\n")
}

# the script is wrapped in a function to make the variables local as to not interfere with the tasks globals
exec_task <- function() {
    args <- commandArgs(trailingOnly = TRUE)

    task_filename <- args[[1]]

    body <- qread("body.qs")
    task <- qread(task_filename)

    attach(body$env)

    stdout <- character()
    stderr <- character()

    out_con <- textConnection("stdout", "w", local = TRUE)
    err_con <- textConnection("stderr", "w", local = TRUE)

    capture.output(
        capture.output(
            {
                for (package in body$packages) library(package, character.only = TRUE)

                started_at <- now()

                result <- tryCatch(
                    do.call(body$fun, task$args),
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

    stdout <- process_captured_output(stdout)
    stderr <- process_captured_output(stderr)

    is_error <- inherits(result, "error")

    task_result <- if (is_error) list(error = result, failed = TRUE) else list(result = result, failed = FALSE)

    elapsed <- as.duration(interval(started_at, finished_at))

    task_result_with_metadata <- c(
        task_result,
        stdout = list(stdout),
        stderr = list(stderr),
        started_at = started_at,
        elapsed = elapsed
    )

    result_filename <- paste(file_path_sans_ext(task_filename), "_out.qs", sep = "")

    qsave(task_result_with_metadata, result_filename)
}

exec_task()
