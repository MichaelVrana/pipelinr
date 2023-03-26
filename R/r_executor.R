library(rlang)
library(purrr)
library(qs)

exec_task <- function(stage, task) {
    stage_dir <- get_stage_dir(stage$name)

    result <- tryCatch(do.call(stage$body, task$args), error = function(e) e)

    is_error <- inherits(result, "error")

    if (is_error) print(result)

    task_result <- if (is_error) list(error = result, failed = TRUE) else list(result = result, failed = FALSE)

    task_output_path <- get_task_output_filename(stage$name, task$hash)

    qsave(task_result, task_output_path)
}

#' R task executor. This is the default executor that runs tasks in the main R process.
#' @export
r_executor <- function(task_iter, stage) {
    stage_dir <- get_stage_dir(stage$name)

    if (!dir.exists(stage_dir)) dir.create(stage_dir, recursive = TRUE)

    for_each_iter(task_iter, function(task) exec_task(stage, task))
}
