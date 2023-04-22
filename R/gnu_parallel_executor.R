library(rlang)
library(purrr)
library(qs)
library(processx)
library(readr)
library(stringr)

parallel_job_log_filename <- "joblog"

get_basefile_args <- function() {
    script_paths <- c("exec_task.R", "collect_metadata.R", "exec_task_and_collect_metadata.sh") %>%
        system.file(., package = "pipelinr") %>%
        map(., function(path) {
            dir <- dirname(path)
            name <- basename(path)

            file.path(dir, ".", name)
        })

    c(script_paths, "body.qs") %>%
        reduce(., .init = character(), function(acc, script_path) {
            c(acc, "--basefile", script_path)
        })
}

#' Constructor function of a GNU Parallel task executor. This executor runs tasks in parallel using GNU Parallel.
#' @param ssh_login_file Path to GNU Parallel SSH login file. If the file is specified, tasks will be executed over SSH.
#' @export
make_gnu_parallel_executor <- function(ssh_login_file = "", flags = character()) {
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
            c(acc, get_task_filename(task$hash))
        })

        parallel_args <- if (ssh_login_file != "") {
            c(
                flags,
                "--joblog",
                parallel_job_log_filename,
                "--sshloginfile",
                normalizePath(ssh_login_file),
                get_basefile_args(),
                "--trc",
                "{.}_out.qs",
                "./exec_task_and_collect_metadata.sh",
                "./exec_task.R",
                "./collect_metadata.R"
            )
        } else {
            c(
                flags,
                "--joblog",
                parallel_job_log_filename,
                system.file(
                    "./exec_task_and_collect_metadata.sh",
                    package = "pipelinr"
                ),
                system.file("exec_task.R", package = "pipelinr"),
                system.file("collect_metadata.R", package = "pipelinr")
            )
        }

        job_log_path <- file.path(stage_dir, parallel_job_log_filename)

        if (file.exists(job_log_path)) file.remove(job_log_path)

        proc <- process$new(
            command = "parallel",
            args = parallel_args,
            wd = stage_dir,
            stdout = "",
            stderr = "",
            stdin = "|"
        )

        proc_stdin <- proc$get_input_connection()
        conn_write(proc_stdin, task_filenames)
        close(proc_stdin)

        task_count <- length(task_filenames)

        pb <- create_task_execution_progress_bar(stage$name, task_count)

        while (proc$is_alive()) {
            proc$wait(1000)

            tasks_completed <- if (file.exists(job_log_path)) {
                read_file(job_log_path) %>%
                    str_count(., "\n") - 1
            } else {
                0
            }

            if (!pb$finished && tasks_completed != 0) {
                pb$update(tasks_completed / task_count)
            }
        }

        pb$terminate()
    }
}
