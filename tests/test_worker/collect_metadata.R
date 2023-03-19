library(tools)
library(readr)
suppressPackageStartupMessages(library(qs))

args <- commandArgs(trailingOnly = TRUE)

task_filename <- args[[1]]
exit_code <- args[[2]]
stdout_filename <- args[[3]]
stderr_filename <- args[[4]]

task_result_filename <- paste(file_path_sans_ext(task_filename), "_out.qs", sep = "")

task_result <- if (file.exists(task_result_filename)) qread(task_result_filename) else list(result = NULL)

stdout <- read_file(stdout_filename)
stderr <- read_file(stderr_filename)

metadata <- list(failed = exit_code != "0", exit_code = strtoi(exit_code), stdout = stdout, stderr = stderr)

result_with_metadata <- append(task_result, metadata)

qsave(result_with_metadata, task_result_filename)
