library(rlang)
library(purrr)
library(qs)

#' Constructor function of a GNU Parallel task executor. This executor runs tasks in parallel using GNU Parallel.
#' @param ssh_login_file Path to GNU Parallel SSH login file. If the file is specified, tasks will be executed over SSH.
#' @export
make_gnu_parallel_executor <- function(ssh_login_file = "") {
    function(task_iter, stage) {
        body_with_globals <- find_used_globals_and_packages(stage$body)

        task_body <- list(
            fun = stage$body,
            packages = body_with_globals$packages,
            env = as.environment(body_with_globals$globals)
        )

        stage_dir <- get_stage_dir(stage$name)

        if (!dir.exists(stage_dir)) dir.create(stage_dir, recursive = TRUE)

        file.path(stage_dir, "body.qs") %>% qsave(task_body, .)

        task_filenames <- fold_iter(task_iter, character(), function(acc, task) {
            filename <- paste("task_", task$hash, ".qs", sep = "")
            file.path(stage_dir, filename) %>% qsave(task, .)
            c(acc, filename)
        })

        ssh_login_file_normalized_path <- normalizePath(ssh_login_file)

        curr_wd <- getwd()

        setwd(stage_dir)

        clear_stage_dir(stage$name)

        args <- c(
            "--sshloginfile",
            ssh_login_file_normalized_path,
            "--transfer",
            "--return",
            "{.}_out.qs",
            "--basefile",
            "body.qs",
            "./exec_task_and_collect_metadata.sh",
            ":::",
            task_filenames
        )

        system2("parallel", args = args)

        setwd(curr_wd)

        outputs_iter <- stage_outputs_iter(stage$name)
        results_iter <- stage_outputs_iter_to_results_iter(outputs_iter)

        list(results_iter = results_iter, metadata_iter = outputs_iter)
    }
}
