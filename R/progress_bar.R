create_task_execution_progress_bar <- function(stage_name, task_count) {
    progress::progress_bar$new(
        format = paste("Executing stage ", stage_name, " [:bar] :current / :total :percent ETA: :eta", sep = ""),
        total = task_count,
        clear = FALSE,
        show_after = 0
    )$tick(0)
}
