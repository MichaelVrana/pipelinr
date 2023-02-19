library(purrr)

make_gnu_parallel_executor <- function(ssh_login_file = "") {
    function(task_iter, stage_name, pipeline_dir) {
        task_group <- list(tasks = collect_iter(task_iter), stage_name = stage_name)

        clear_stage_dir(pipeline_dir, stage_name)
        gnu_parallel_run_task_group(task_group, normalizePath(ssh_login_file), normalizePath(pipeline_dir))

        outputs_iter <- stage_outputs_iter(stage_name, pipeline_dir)
        results_iter <- stage_outputs_iter_to_results_iter(outputs_iter)
        metadata_iter <- stage_outputs_iter_to_metadata_iter(outputs_iter)

        list(results_iter = results_iter, metadata_iter = metadata_iter)
    }
}
