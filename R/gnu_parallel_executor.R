library(purrr)

make_gnu_parallel_executor <- function(ssh_login_file = "") {
    function(task_group) {
        gnu_parallel_run_task_group(task_group, ssh_login_file)

        outputs_iter <- stage_outputs_iter(task_group$stage_id)
        results_iter <- stage_outputs_iter_to_results_iter(outputs_iter)
        metadata_iter <- stage_outputs_iter_to_metadata_iter(outputs_iter)

        list(results_iter = results_iter, metadata_iter = metadata_iter)
    }
}
