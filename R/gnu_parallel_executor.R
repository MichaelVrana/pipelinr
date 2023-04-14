library(rlang)
library(purrr)
library(qs)

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
                "--sshloginfile",
                normalizePath(ssh_login_file),
                get_basefile_args(),
                "--trc",
                "{.}_out.qs",
                flags,
                "./exec_task_and_collect_metadata.sh",
                "./exec_task.R",
                "./collect_metadata.R",
                ":::",
                task_filenames
            )
        } else {
            c(
                flags,
                system.file(
                    "./exec_task_and_collect_metadata.sh",
                    package = "pipelinr"
                ),
                system.file("exec_task.R", package = "pipelinr"),
                system.file("collect_metadata.R", package = "pipelinr"),
                ":::",
                task_filenames
            )
        }

        curr_wd <- getwd()
        setwd(stage_dir)
        # TODO: --joblog
        tryCatch(
            system2("parallel", args = parallel_args),
            finally = setwd(curr_wd)
        )
    }
}
