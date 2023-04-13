library(tools)
suppressPackageStartupMessages(library(qs))

# the script is wrapped in a function to make the variables local as to not interfere with the tasks globals
exec_task <- function() {
    args <- commandArgs(trailingOnly = TRUE)

    task_filename <- args[[1]]

    body <- qread("body.qs")
    task <- qread(task_filename)

    for (package in body$packages) library(package, character.only = TRUE)

    attach(body$env)

    stdout <- character()
    stderr <- character()

    out_con <- textConnection("stdout", "w", local = TRUE)
    err_con <- textConnection("stderr", "w", local = TRUE)

    capture.output(
        capture.output(
            result <- tryCatch(
                do.call(body$fun, task$args),
                error = function(e) e
            ),
            file = out_con,
            type = "output"
        ),
        file = err_con,
        type = "message"
    )

    close(out_con)
    close(err_con)

    is_error <- inherits(result, "error")

    task_result <- if (is_error) list(error = result, failed = TRUE) else list(result = result, failed = FALSE)

    task_result_with_output_streams <- c(task_result, stdout = list(stdout), stderr = list(stderr))

    result_filename <- paste(file_path_sans_ext(task_filename), "_out.qs", sep = "")

    qsave(task_result_with_output_streams, result_filename)
}

exec_task()
