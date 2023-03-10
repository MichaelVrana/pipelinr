library(rlang)
library(purrr)

create_metadata_function <- function(metadata_iters) {
    function(stage_symbol) {
        stage_name <- ensym(stage_symbol) %>% toString()
        metadata_iters[[stage_name]]
    }
}

eval_inputs <- function(stage_results, input_quosures) {
    dsl_funcs <- list(metadata = create_metadata_function(stage_results$metadata))

    map(input_quosures, function(input_quo) {
        inputs_expr <- quo_get_expr(input_quo)
        inputs_env <- quo_get_env(input_quo)

        eval_env <- new_environment(data = c(stage_results$results, dsl_funcs), parent = inputs_env)

        input <- eval(inputs_expr, envir = eval_env)

        if (is_iter(input)) {
            return(input)
        }

        make_iter(input)
    })
}

stage_tasks_iter <- function(stage, input_iters) {
    if (is_empty(stage$input_quosures)) {
        make_iter(list(body = stage$body, args = list()))
    } else {
        do.call(zip_iter, input_iters) %>% map_iter(., function(inputs) list(body = stage$body, args = inputs))
    }
}

print_task_iter <- function(task_iter, idx = 0) {
    if (task_iter$done) {
        return()
    }

    cat("Input ", toString(idx), ":\n", sep = "")
    cat("================================================================================\n")
    str(task_iter$value$args)
    cat("================================================================================\n\n")

    print_task_iter(task_iter$next_iter(), idx + 1)
}

print_stage_inputs <- function(stage_name, task_iter) {
    cat("Stage ", stage_name, " inputs:\n", sep = "")
    print_task_iter(task_iter)
}

run_pipeline <- function(pipeline, executor = r_executor, pipeline_dir = "pipeline", print_inputs = FALSE) {
    reduce(pipeline$exec_order, function(stage_results, stage) {
        input_iters <- eval_inputs(stage_results, stage$input_quosures)
        task_iter <- stage_tasks_iter(stage, input_iters)

        if (print_inputs) print_stage_inputs(stage$name, task_iter)

        stage_executor <- if (!is.null(stage$override_executor)) stage$override_executor else executor

        outputs_iter <- stage_executor(task_iter, stage = stage, pipeline_dir = pipeline_dir)

        stage_results$results[[stage$name]] <- outputs_iter$results
        stage_results$metadata[[stage$name]] <- outputs_iter$metadata_iter
        stage_results
    }, .init = list(results = list(), metadata = list()))
}
