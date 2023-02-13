library(purrr)

make_gnu_parallel_executor <- function(ssh_login_file = "") {
    function(task_group) {
        results <- gnu_parallel_run_task_group(task_group, ssh_login_file)

        map(results, function(result) {
            print(result$stdout)
            print(result$stderr)
            result$result
        }) %>% vec_to_iter()
    }
}
