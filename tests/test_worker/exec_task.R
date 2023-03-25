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

    result <- do.call(body$fun, task$args)

    result_filename <- paste(file_path_sans_ext(task_filename), "_out.qs", sep = "")

    qsave(list(result = result), result_filename)
}

exec_task()
