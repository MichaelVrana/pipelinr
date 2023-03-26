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

        file.path(stage_dir, "body.qs") %>% qsave(task_body, .)

        task_filenames <- fold_iter(task_iter, character(), function(acc, task) {
            c(acc, get_task_path(stage_dir, task$hash))
        })

        ssh_login_file_normalized_path <- normalizePath(ssh_login_file)

        curr_wd <- getwd()

        setwd(stage_dir)

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
    }
}
