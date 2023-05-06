stage_results_iter_from_symbol <- function(stage_symbol) {
    if (!is.symbol(stage_symbol)) stop("Invalid stage identifier")

    stage_name <- toString(stage_symbol)
    stage_dir <- get_stage_dir(stage_name)

    if (!dir.exists(stage_dir)) paste("Couldn't find results for stage", stage_name) %>% stop()

    stage_results_iter(stage_name)
}

#' Retrieve results of a stage
#' @export
#' @examples
#' read(stage_name)
read <- function(stage_symbol) {
    rlang::enexpr(stage_symbol) %>%
        stage_results_iter_from_symbol() %>%
        collect()
}

#' Retrieve results of a stage as a data frame
#' This will throw if the results cannot be converted to a data frame
#' @export
#' @examples
#' read(stage_name)
read_df <- function(stage_symbol) {
    rlang::enexpr(stage_symbol) %>%
        stage_results_iter_from_symbol() %>%
        collect_df()
}

stage_metadata_iter_from_symbol <- function(stage_symbol) {
    if (!is.symbol(stage_symbol)) stop("Invalid stage identifier")

    stage_name <- toString(stage_symbol)
    stage_dir <- get_stage_dir(stage_name)

    if (!dir.exists(stage_dir)) paste("Couldn't find metadata for stage", stage_name) %>% stop()

    stage_metadata_iter(stage_name)
}

#' Retrieve metadata about stage's execution
#' @export
#' @examples
#' metadata(stage_name)
metadata <- function(stage_symbol) {
    rlang::enexpr(stage_symbol) %>%
        stage_metadata_iter_from_symbol() %>%
        collect()
}

#' Retrieve metadata about stage's execution as a data frame
#' This will throw if the results cannot be converted to a data frame
#' @export
#' @examples
#' metadata_df(stage_name)
metadata_df <- function(stage_symbol) {
    rlang::enexpr(stage_symbol) %>%
        stage_metadata_iter_from_symbol() %>%
        map_iter(., function(task_metadata) {
            task_metadata$result <- list(task_metadata$result)
            task_metadata
        }) %>%
        collect_df()
}
