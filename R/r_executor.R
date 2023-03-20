library(rlang)
library(purrr)
library(qs)

exec_task <- function(stage, task, pipeline_dir) {
    stage_dir <- get_stage_dir(pipeline_dir, stage$name)

    task_filename <- paste("task_", task$hash, ".qs", sep = "")
    task_filepath <- file.path(stage_dir, task_filename)

    qsave(task, task_filepath)

    result <- tryCatch(do.call(stage$body, task$args), error = function(e) e)

    is_error <- inherits(result, "error")

    if (is_error) print(result)

    task_result <- if (is_error) list(error = result, failed = TRUE) else list(result = result, failed = FALSE)

    task_outputs_filename <- paste("task_", task$hash, "_out.qs", sep = "")
    task_outputs_filepath <- file.path(stage_dir, task_outputs_filename)

    qsave(task_result, task_outputs_filepath)

    task_result
}

#' R task executor. This is the default executor that runs tasks in the main R process.
#' @export
r_executor <- function(task_iter, stage, pipeline_dir) {
    stage_dir <- get_stage_dir(pipeline_dir, stage$name)
    if (!dir.exists(stage_dir)) dir.create(stage_dir, recursive = TRUE)

    results_iter <- map_iter(task_iter, function(task) exec_task(stage, task, pipeline_dir)) %>% memoize_iter()

    list(
        results_iter = filter_iter(results_iter, function(task_result) !task_result$failed) %>% map_iter(., function(task_result) task_result$result),
        metadata_iter = results_iter
    )
}
