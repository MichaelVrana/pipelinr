library(tools)
suppressPackageStartupMessages(library(qs))

args <- commandArgs(trailingOnly = TRUE)

task_filename <- args[[1]]

task <- qread(task_filename)

for (package in task$packages) library(package, character.only = TRUE)

if (typeof(task$body$fun) != "closure") {
    stop("Task is missing a body function or it's not a function")
}

if (typeof(task$args) != "list") {
    stop("Task is missing an args list or it's not a list")
}

result <- do.call(task$body$fun, task$args, envir = task$body$env)

result_filename <- paste(file_path_sans_ext(task_filename), "_out.qs", sep = "")

qsave(list(result = result), result_filename)
