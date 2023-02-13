library(purrr)

get_stage_task_group <- function(stage, input_iters, tasks = list()) {
    input <- map(input_iters, function(iter) iter$value)

    task <- list(body = stage$body, args = input)

    next_iters <- map(input_iters, function(iter) iter$next_iter())

    all_iters_done <- every(next_iters, function(iter) iter$done)

    next_tasks <- append(tasks, list(task))

    if (all_iters_done) {
        return(list(tasks = next_tasks, id = stage$name))
    }

    get_stage_task_group(stage, next_iters, next_tasks)
}

run_pipeline <- function(pipeline, engine = r_executor) {
    reduce(pipeline$exec_order, function(stage_results, stage) {
        input_iters <- eval_inputs(stage_results, stage$input_quosures)

        task_group <- get_stage_task_group(stage, input_iters)
        results_iter <- engine(task_group)

        new_results <- c(stage_results)
        new_results[[stage$name]] <- results_iter
        new_results
    }, .init = list())
}
