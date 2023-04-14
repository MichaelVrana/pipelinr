library(progress)

create_task_execution_progress_bar <- function(stage_name, task_count) {
    progress_bar$new(
        format = paste("Executing stage ", stage_name, " [:bar] completed: :current / :total :percent ETA: :eta", sep = ""),
        width = 100,
        clear = FALSE,
        total = task_count,
        show_after = 0
    )$tick(0)
}
