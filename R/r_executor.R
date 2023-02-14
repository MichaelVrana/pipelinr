library(rlang)
library(purrr)

eval_inputs <- function(stage_results, input_quosures) {
    input_iters <- map(input_quosures, function(input_quo) {
        inputs_expr <- quo_get_expr(input_quo)
        inputs_env <- quo_get_env(input_quo)

        eval_env <- new_environment(data = stage_results, parent = inputs_env)

        input <- eval(inputs_expr, envir = eval_env)

        if (is_iter(input)) {
            return(input)
        }

        make_iter(input)
    })

    input_iters
}

r_executor <- function(task_group) {
    map(task_group$tasks, function(task) do.call(task$body, task$args)) %>% vec_to_iter()
}
