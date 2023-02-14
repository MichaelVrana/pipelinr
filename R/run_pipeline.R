library(purrr)

stage_task_iter <- function(stage, input_iters, tasks = list()) {
    input <- map(input_iters, function(iter) iter$value)

    task <- list(body = stage$body, args = input)

    next_iters <- map(input_iters, function(iter) iter$next_iter())

    all_iters_done <- every(next_iters, function(iter) iter$done)

    next_tasks <- append(tasks, list(task))

    if (all_iters_done) {
        return(list(tasks = next_tasks, id = stage$name))
    }

    stage_task_iter(stage, next_iters, next_tasks)
}

run_pipeline <- function(pipeline, executor = r_executor) {
    reduce(pipeline$exec_order, function(stage_results, stage) {
        input_iters <- eval_inputs(stage_results, stage$input_quosures)

        task_group <- stage_task_iter(stage, input_iters)

        stage_executor <- if (!is_null(stage$override_executor)) stage$override_executor else executor

        results_iter <- stage_executor(task_group)

        new_results <- c(stage_results)
        new_results[[stage$name]] <- results_iter
        new_results
    }, .init = list())
}
