library(rlang)
library(purrr)
suppressPackageStartupMessages(library(qs))

task_file_pattern <- ".*_out\\.qs$"

#' Stage inputs constructor function. Should be used as the `inputs` parameter of a `stage` function.
#' @export
stage_inputs <- function(...) rlang::enquos(...)

#' Pipeline stage constructor function
#'
#' @param body A function that will be run with inputs as it's arguments
#' @param inputs An expression constructed using `stage_inputs`, describes the body's inputs
#' @export
#' @examples
#' stage(inputs = stage_inputs(a = 1:3 |> mapped()), body = function(a) a * 2)
#'
stage <- function(body, inputs = stage_inputs(), save_results = FALSE, executor = NULL) {
    list(body = body, input_quosures = inputs, save_results = save_results, executor = executor)
}

clear_stage_dir <- function(stage_name) {
    stage_dir <- get_stage_dir(stage_name)

    if (!file.exists(stage_dir)) {
        return()
    }

    files_to_remove <- list.files(stage_dir) %>%
        purrr::map(., function(filename) file.path(stage_dir, filename)) %>%
        unlist()

    if (!is_empty(files_to_remove)) file.remove(files_to_remove)
}

get_pipeline_dir <- function() getOption("pipelinr_dir", "pipeline") %>% normalizePath()

get_stage_dir <- function(stage_name) get_pipeline_dir() %>% file.path(., stage_name)

stage_outputs_iter_to_results_iter <- function(ouputs_iter) {
    filter_iter(ouputs_iter, function(output) !output$outputs$failed) %>%
        map_iter(., function(output) output$outputs$result)
}

find_child_stages <- function(stages, stage_name) {
    find_rec <- function(stage) {
        direct_childs <- purrr::keep(stages, function(child_stage) {
            purrr::has_element(child_stage$deps, stage$name)
        })

        purrr::map(direct_childs, find_rec) %>% purrr::reduce(., .init = stage$name, c)
    }

    find_rec(stages[[stage_name]]) %>% setdiff(., stage_name)
}

find_parent_stages <- function(stages, stage_name) {
    find_rec <- function(stage) {
        purrr::map(stage$deps, function(dep_name) find_rec(stages[[dep_name]])) %>%
            purrr::reduce(., .init = stage$name, c)
    }

    find_rec(stages[[stage_name]]) %>% setdiff(., stage_name)
}
