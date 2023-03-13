library(rlang)
library(purrr)

make_gnu_parallel_executor <- function(ssh_login_file = "") {
    function(task_iter, stage, pipeline_dir) {
        body_with_globals <- find_used_globals_and_packages(stage$body)

        task_body <- list(
            fun = stage$body,
            packages = body_with_globals$packages,
            env = as.environment(body_with_globals$globals)
        )

        tasks <- map_iter(task_iter, function(task) {
            list(body = task_body, args = task$args)
        })

        task_group <- list(tasks = collect(tasks), stage_name = stage$name)

        clear_stage_dir(pipeline_dir, stage$name)
        gnu_parallel_run_task_group(task_group, normalizePath(ssh_login_file), normalizePath(pipeline_dir))

        outputs_iter <- stage_outputs_iter(stage$name, pipeline_dir)
        results_iter <- stage_outputs_iter_to_results_iter(outputs_iter)

        list(results_iter = results_iter, metadata_iter = outputs_iter)
    }
}
