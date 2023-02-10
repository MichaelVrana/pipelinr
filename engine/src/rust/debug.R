# This files serves as an entrypoint for VS Code debugging

devtools::load_all("../..")

task <- list(body = function(x) x + 1, args = list(x = 1))

task_group <- list(tasks = list(task), id = "task_group_id")

results <- gnu_parallel_run_task_group(task_group = task_group, ssh_login_file = "../../test/nodefile")

print(results)
