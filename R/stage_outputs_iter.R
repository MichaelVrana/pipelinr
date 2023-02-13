library(purrr)
suppressPackageStartupMessages(library(qs))

stage_outputs_iter <- function(stage_id) {
    stage_dir <- file.path("pipeline", stage_id)

    list.files(stage_dir, pattern = ".*_out\\.qs$") %>%
        vec_to_iter() %>%
        map_iter(., function(filename) file.path(stage_dir, filename) %>% qread())
}

stage_results_iter <- function(stage_id) stage_outputs_iter(stage_id) %>% map_iter(., function(output) output$result)

stage_metadata_iter <- function(stage_id) stage_outputs_iter(stage_id) %>% map_iter(., function(output) without_name(output, result))
