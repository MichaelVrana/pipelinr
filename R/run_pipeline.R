library(purrr)

eval_inputs <- function(stage_results, input_quosures) {
    map(input_quosures, function(input_quo) {
        inputs_expr <- quo_get_expr(input_quo)
        inputs_env <- quo_get_env(input_quo)

        eval_env <- new_environment(data = stage_results, parent = inputs_env)

        input <- eval(inputs_expr, envir = eval_env)

        if (is_iter(input)) {
            return(input)
        }

        make_iter(input)
    })
}

stage_task_iter <- function(stage, input_iters) {
    if (is_empty(stage$input_quosures)) {
        make_iter(list(body = stage$body, args = list()))
    } else {
        lift_dl(zip_iter)(input_iters) %>% map_iter(., function(inputs) list(body = stage$body, args = inputs))
    }
}

run_pipeline <- function(pipeline, executor = r_executor) {
    reduce(pipeline$exec_order, function(stage_results, stage) {
        input_iters <- eval_inputs(stage_results, stage$input_quosures)

        task_iter <- stage_task_iter(stage, input_iters)
        
        stage_executor <- if (!is_null(stage$override_executor)) stage$override_executor else executor

        results_iter <- stage_executor(task_iter) %>%
            collect_iter() %>%
            vec_to_iter()

        new_results <- c(stage_results)
        new_results[[stage$name]] <- results_iter
        new_results
    }, .init = list())
}
