library(rlang)
library(purrr)
suppressPackageStartupMessages(library(qs))

stage_inputs <- function(...) enquos(...)

stage <- function(body, inputs = stage_inputs(), save_results = TRUE, override_executor = NULL) {
    list(body = body, input_quosures = inputs, save_results = save_results, override_executor = override_executor)
}

stage_outputs_iter <- function(stage_id) {
    stage_dir <- file.path("pipeline", stage_id)

    list.files(stage_dir, pattern = ".*_out\\.qs$") %>%
        vec_to_iter() %>%
        map_iter(., function(filename) {
            if (is.null(filename)) {
                return(NULL)
            }
            file.path(stage_dir, filename) %>% qread()
        })
}

stage_outputs_iter_to_results_iter <- function(ouputs_iter) map_iter(ouputs_iter, function(output) output$result)

stage_outputs_iter_to_metadata_iter <- function(metadata_iter) map_iter(metadata_iter, function(output) without_name(output, "result"))

stage_results_iter <- function(stage_id) stage_outputs_iter(stage_id) %>% stage_outputs_iter_to_results_iter()

stage_metadata_iter <- function(stage_id) stage_outputs_iter(stage_id) %>% stage_outputs_iter_to_metadata_iter()
