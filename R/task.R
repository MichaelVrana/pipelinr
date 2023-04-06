library(qs)
library(magrittr)
library(rlang)

get_task_filename <- function(task_hash) {
    paste("task_", task_hash, ".qs", sep = "")
}

get_task_path <- function(stage_name, task_hash) {
    file.path(get_stage_dir(stage_name), get_task_filename(task_hash))
}

get_task_output_filename <- function(task_hash) {
    paste("task_", task_hash, "_out.qs", sep = "")
}

get_task_output_path <- function(stage_name, task_hash) {
    file.path(get_stage_dir(stage_name), get_task_output_filename(task_hash))
}

read_task_output <- function(stage_name, task_hash) {
    get_task_output_path(stage_name, task_hash) %>% qread()
}

task_filename_regex <- "^task_[a-f0-9]+\\.qs$"

stage_metadata_iter <- function(stage_name) {
    stage_dir <- get_stage_dir(stage_name)

    list.files(stage_dir, pattern = task_filename_regex) %>%
        vec_to_iter() %>%
        map_iter(., function(task_filename) {
            task_path <- file.path(stage_dir, task_filename)

            task <- qread(task_path)

            output_path <- get_task_output_path(stage_name, task$hash)

            output <- if (file.exists(output_path)) {
                qread(output_path)
            } else {
                list()
            }

            c(task, output)
        })
}

task_output_filename_regex <- ".*_out\\.qs$"

stage_task_outputs_iter <- function(stage_name) {
    stage_dir <- get_stage_dir(stage_name)

    list.files(stage_dir, pattern = task_output_filename_regex) %>%
        vec_to_iter() %>%
        map_iter(., function(filename) {
            file.path(stage_dir, filename) %>% qread()
        })
}

stage_results_iter <- function(stage_name) {
    stage_task_outputs_iter(stage_name) %>%
        filter_iter(., function(task_output) !task_output$failed) %>%
        map_iter(., function(task_output) task_output$result)
}

task_path_from_output_path <- function(task_output_path) {
    basename(task_output_path) %>%
        gsub("(task_([a-f0-9])+)_out\\.qs$", "\\1.qs", .) %>%
        file.path(dirname(task_output_path), .)
}

save_tasks <- function(stage_name, task_iter) {
    for_each_iter(task_iter, function(task) {
        path <- get_task_path(stage_name, task$hash)
        qsave(task, path)
    })
}

stage_results_iter_from_symbol <- function(stage_symbol) {
    if (!is.symbol(stage_symbol)) stop("Invalid stage identifier")

    stage_name <- toString(stage_symbol)

    stage_results_iter(stage_name)
}

read <- function(stage_symbol) {
    enexpr(stage_symbol) %>% stage_results_iter_from_symbol() %>% collect()
}

read_df <- function(stage_symbol) {
    enexpr(stage_symbol) %>% stage_results_iter_from_symbol() %>% collect_df()
}