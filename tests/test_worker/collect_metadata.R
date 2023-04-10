library(tools)
suppressPackageStartupMessages(library(qs))

args <- commandArgs(trailingOnly = TRUE)

task_filename <- args[[1]]
exit_code <- args[[2]]

task_result_filename <- paste(file_path_sans_ext(task_filename), "_out.qs", sep = "")

task_result <- if (file.exists(task_result_filename)) qread(task_result_filename) else list(failed = TRUE)

task_outputs_with_exit_code <- append(task_result, exit_code = strtoi(exit_code))

qsave(task_outputs_with_exit_code, task_result_filename)
