library(rlang)
library(purrr)
suppressPackageStartupMessages(library(qs))

stage_inputs <- function(...) enquos(...)

stage <- function(body, inputs = stage_inputs(), save_results = FALSE, override_executor = NULL) {
    list(body = body, input_quosures = inputs, save_results = save_results, override_executor = override_executor)
}

clear_stage_dir <- function(pipeline_dir, stage_name) {
    stage_dir <- file.path(pipeline_dir, stage_name)

    if (!file.exists(stage_dir)) {
        return()
    }

    list.files(stage_dir) %>%
        map(., function(filename) file.path(stage_dir, filename)) %>%
        unlist() %>%
        file.remove()
}

task_file_path_from_output_file_path <- function(output_file_path) {
    basename(output_file_path) %>%
        gsub("(task_[0-9]+)_out\\.qs$", "\\1.qs", .) %>%
        file.path(dirname(output_file_path), .)
}

stage_outputs_iter <- function(stage_name, pipeline_dir) {
    stage_dir <- file.path(pipeline_dir, stage_name)

    list.files(stage_dir, pattern = ".*_out\\.qs$") %>%
        vec_to_iter() %>%
        map_iter(., function(filename) {
            if (is.null(filename)) {
                return(NULL)
            }

            outputs_file_path <- file.path(stage_dir, filename)
            task_file_path <- task_file_path_from_output_file_path(outputs_file_path)

            outputs <- qread(outputs_file_path)
            task <- qread(task_file_path)

            list(task = task, outputs = outputs)
        })
}

stage_outputs_iter_to_results_iter <- function(ouputs_iter) map_iter(ouputs_iter, function(output) output$outputs$result)
