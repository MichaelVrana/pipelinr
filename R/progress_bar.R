library(progress)

create_task_execution_progress_bar <- function(stage_name, task_count) {
    progress_bar$new(
        format = "Executing [:bar] completed: :current / :total :percent ETA: :eta",
        clear = FALSE,
        total = task_count,
    )
}
