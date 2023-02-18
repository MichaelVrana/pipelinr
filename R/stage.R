library(rlang)
library(purrr)
suppressPackageStartupMessages(library(qs))

stage_inputs <- function(...) enquos(...)

stage <- function(body, inputs = stage_inputs(), save_results = FALSE, override_executor = NULL) {
    list(body = body, input_quosures = inputs, save_results = save_results, override_executor = override_executor)
}

task_filename_from_output_filename <- function(output_filename) gsub("(task_[0-9]+)_out\\.qs", "\\1.qs", output_filename)

stage_outputs_iter <- function(stage_id, pipeline_dir) {
    stage_dir <- file.path(pipeline_dir, stage_id)

    list.files(stage_dir, pattern = ".*_out\\.qs$") %>%
        vec_to_iter() %>%
        map_iter(., function(filename) {
            if (is.null(filename)) {
                return(NULL)
            }

            outputs_filename <- file.path(stage_dir, filename)
            task_filename <- task_filename_from_output_filename(outputs_filename) %>% file.path(stage_dir, .)

            outputs <- qread(outputs_filename)
            task <- qread(task_filename)

            list(task = task, outputs = outputs)
        })
}

stage_outputs_iter_to_results_iter <- function(ouputs_iter) map_iter(ouputs_iter, function(output) output$result)

stage_outputs_iter_to_metadata_iter <- function(metadata_iter) map_iter(metadata_iter, function(output) without_name(output, "result"))
