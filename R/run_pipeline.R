library(rlang)
library(purrr)
library(readr)
library(qs)

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

unevaluated_task_filter_factory <- function(stage_name) {
    function(task) {
        task_output_path <- get_task_output_path(stage_name, task$hash)
        !file.exists(task_output_path)
    }
}

create_metadata_task_filter_factory <- function(filter_quo) {
    function(stage_name) {
        function(task) {
            task_output_path <- get_task_output_path(stage_name, task$hash)

            task_output <- if (file.exists(task_output_path)) {
                qread(task_output_path)
            } else {
                list()
            }

            result <- eval_tidy(filter_quo, data = c(task, task_output))

            is.logical(result) && length(result) == 1 && result
        }
    }
}

print_stage_tasks <- function(stage_name, task_iter) {
    cat("Stage ", stage_name, " inputs:\n", sep = "")

    for_each_iter(task_iter, function(task) {
        cat("Task ", task$hash, ":\n", sep = "")
        cat("================================================================================\n")
        str(task$args)
        cat("================================================================================\n\n")
    })
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

create_stage_dirs <- function(stage_names) {
    for (stage_name in stage_names) {
        stage_dir <- get_stage_dir(stage_name)

        if (!dir.exists(stage_dir)) dir.create(stage_dir, recursive = TRUE)
    }
}

load_pipeline <- function() {
    getOption("pipelinr_pipeline_file", "pipeline.R") %>% read_file() %>% parse() %>% eval(., envir = new.env())
}

#' Runs a pipeline.
#' @param pipeline A pipeline object constructed using `make_pipeline`.
#' @param executor An executor function, defaults to R executor.
#' @param print_inputs Boolean, defaults to `FALSE`. If true, stage inputs will be printed to using the `str` function.
#' @export
make <- function(pipeline = load_pipeline(), only = NULL, from = NULL, where = NULL, clean = FALSE, executor = r_executor, print_inputs = FALSE) {
    create_stage_dirs(pipeline$stages %>% names())

    task_filter_factory <- if (!missing(where)) {
        enquo(where) %>% create_metadata_task_filter_factory()
    } else {
        unevaluated_task_filter_factory
    }

    stages_to_exec <- if (!missing(only)) {
        intersect(pipeline$exec_order, toString(only))
    } else {
        pipeline$exec_order
    }

    reduce(stages_to_exec,
        .init = list(
            results = list(),
            metadata = list()
        ), function(stage_results, stage) {
            paste("Executing stage ", stage$name, "\n", sep = "") %>% cat()

            if (clean) clear_stage_dir(stage$name)

            input_iters <- eval_inputs(stage_results, stage$input_quosures)
            task_iter <- stage_tasks_iter(stage, input_iters) %>% filter_iter(., task_filter_factory(stage$name))

            if (!task_iter$done) {
                save_tasks(stage$name, task_iter)

                if (print_inputs) print_stage_tasks(stage$name, task_iter)

                stage_executor <- if (!is.null(stage$override_executor)) stage$override_executor else executor

                stage_executor(task_iter, stage = stage)
            } else {
                paste("No unevaluated tasks found for stage ", stage$name, "\n", sep = "") %>% cat()
            }

            stage_results$results[[stage$name]] <- task_results_iter(stage$name)
            stage_results$metadata[[stage$name]] <- stage_metadata_iter(stage$name)
            stage_results
        }
    )
}
