library(rlang)
library(purrr)
library(readr)

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
        make_iter(list(args = list(), hash = rlang::hash(list())))
    } else {
        do.call(zip_iter, input_iters) %>%
            map_iter(., function(inputs) {
                list(args = inputs, hash = rlang::hash(inputs))
            })
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

find_stage_names_to_run <- function(stages) {
    updated_or_new_stages <- keep(stages, function(stage) {
        stage_hash_path <- file.path(get_stage_dir(stage$name), "stage_hash")

        if (!file.exists(stage_hash_path)) {
            return(TRUE)
        }

        prev_hash <- read_file(stage_hash_path)
        curr_hash <- stage_hash(stage)

        curr_hash != prev_hash
    })

    map(updated_or_new_stages, function(stage) {
        c(find_child_stages(stages, stage$name), stage$name)
    }) %>%
        flatten_chr() %>%
        unique()
}
#' Runs a pipeline.
#' @param pipeline A pipeline object constructed using `make_pipeline`.
#' @param executor An executor function, defaults to R executor.
#' @param print_inputs Boolean, defaults to `FALSE`. If true, stage inputs will be printed to using the `str` function.
#' @export
run_pipeline <- function(pipeline, executor = r_executor, print_inputs = FALSE) {
    stages_to_run <- find_stage_names_to_run(pipeline$stages)

    exec_order <- keep(pipeline$exec_order, function(stage) has_element(stages_to_run, stage$name))

    init_results <- discard(pipeline$exec_order, function(stage) has_element(stages_to_run, stage$name)) %>%
        reduce(.,
            .init = list(
                results = list(),
                metadata = list()
            ), function(results, stage) {
                outputs_iter <- stage_outputs_iter(stage$name)
                results_iter <- stage_outputs_iter_to_results_iter(outputs_iter)

                results$results[[stage$name]] <- outputs_iter
                results$metadata[[stage$name]] <- results_iter
                results
            }
        )

    reduce(exec_order, function(stage_results, stage) {
        input_iters <- eval_inputs(stage_results, stage$input_quosures)
        task_iter <- stage_tasks_iter(stage, input_iters)

        if (print_inputs) print_stage_inputs(stage$name, task_iter)

        stage_executor <- if (!is.null(stage$override_executor)) stage$override_executor else executor

        output_iters <- stage_executor(task_iter, stage = stage)

        stage_results$results[[stage$name]] <- output_iters$results
        stage_results$metadata[[stage$name]] <- output_iters$metadata_iter
        stage_results
    }, .init = init_results)
}
