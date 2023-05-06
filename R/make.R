create_metadata_function <- function(metadata_iters) {
    function(stage_symbol) {
        stage_name <- rlang::ensym(stage_symbol) %>% toString()
        metadata_iters[[stage_name]]
    }
}

eval_inputs <- function(stage_results, input_quosures) {
    dsl_funcs <- list(
        metadata = create_metadata_function(stage_results$metadata),
        take = head_iter,
        filtered = filter_iter,
        crossed = cross_iter,
        chained = concat_iter,
        zipped = zip_iter,
        remapped = map_iter
    )

    purrr::map(input_quosures, function(input_quo) {
        input <- rlang::eval_tidy(input_quo, data = c(stage_results$results, dsl_funcs))

        if (is_iter(input)) {
            return(input)
        }

        make_iter(input)
    })
}

stage_tasks_iter_from_args <- function(stage, args_iter) {
    if (purrr::is_empty(stage$input_quosures)) {
        make_iter(list(args = list(), hash = rlang::hash(list())))
    } else {
        do.call(zip_iter, args_iter) %>%
            map_iter(., function(args) {
                list(args = args, hash = rlang::hash(args))
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
                qs::qread(task_output_path)
            } else {
                list()
            }

            result <- rlang::eval_tidy(filter_quo, data = c(task, task_output))

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
    updated_or_new_stages <- purrr::keep(stages, function(stage) {
        stage_hash_path <- file.path(get_stage_dir(stage$name), "stage_hash")

        if (!file.exists(stage_hash_path)) {
            return(TRUE)
        }

        prev_hash <- readr::read_file(stage_hash_path)
        curr_hash <- stage_hash(stage)

        curr_hash != prev_hash
    })

    purrr::map(updated_or_new_stages, function(stage) {
        c(find_child_stages(stages, stage$name), stage$name)
    }) %>%
        purrr::flatten_chr() %>%
        unique()
}

create_stage_dirs <- function(stage_names) {
    for (stage_name in stage_names) {
        stage_dir <- get_stage_dir(stage_name)

        if (!dir.exists(stage_dir)) dir.create(stage_dir, recursive = TRUE)
    }
}

load_pipeline <- function() {
    getOption("pipelinr_pipeline_file", "pipeline.R") %>%
        parse() %>%
        eval(., envir = new.env())
}

filter_stages_to_exec <- function(stages, from, only) {
    stage_names <- purrr::map_chr(stages, function(stage) stage$name)

    from_stages <- rlang::eval_tidy(from, stage_names) %>%
        as.character() %>%
        purrr::map(., function(stage_name) {
            find_child_stages(stages, stage_name) %>% c(., stage_name)
        }) %>%
        purrr::flatten_chr()

    only_stages <- rlang::eval_tidy(only, stage_names) %>% as.character()

    stage_names_to_keep <- intersect(from_stages, only_stages) %>% unique()

    purrr::keep(stages, function(stage) {
        purrr::has_element(stage_names_to_keep, stage$name)
    })
}

get_stage_outputs <- function(stage_names) {
    purrr::reduce(
        stage_names,
        .init = list(results = list(), metadata = list()),
        function(stage_outputs, stage_name) {
            stage_outputs$results[[stage_name]] <- stage_results_iter(stage_name)
            stage_outputs$metadata[[stage_name]] <- stage_metadata_iter(stage_name)
            stage_outputs
        }
    )
}

#' Executes a pipeline.
#' @param pipeline A pipeline object constructed using `make_pipeline`. By default it is loaded from the `pipeline.R` file.
#' @param only  Stage filter. Pipeline will execute only the defined stages.
#' @param from Stage filter. Pipeline will execute from the defined stages.
#' @param filter Task filter. Selects which tasks will be evaluated.
#' @param executor An executor function, defaults to R executor.
#' @param print_inputs Boolean, defaults to `FALSE`. If true, stage inputs will be printed to using the `str` function.
#' @param clean Boolean, defaults to FALSE. Before a stage is executed, all of it's tasks and task outputs will be deleted.
#' @export
#'
#' @examples
#'
#' # Loads pipeline from `pipeline.R` and executes all unevaluated tasks in all stages
#' make()
#'
#' # Executes only unevaluated tasks in the stage `s`
#' make(s)
#'
#' # Equivalent to above
#' make("s")
#'
#' # Executes only unevaluated tasks in the stages `s1` and `s2`
#' make(c(s1, s2))
#'
#' # Executes only unevaluated tasks in the stages depending transitively on `s`
#' make(from = s)
#'
#' # Executes all failed tasks in all stages
#' make(filter = failed)
#'
#' # Executes a task with hash "480a8ffaf8703c12704916bee8e21eaa" in stage s
#' make(s, filter = hash == "480a8ffaf8703c12704916bee8e21eaa")
#'
#' # Executes all unevaluated tasks in all stages in the provided pipeline
#' make(pipeline = p)
#'
make <- function(only = names(pipeline$stages),
                 pipeline = load_pipeline(),
                 from = names(pipeline$stages),
                 filter = NULL,
                 clean = FALSE,
                 executor = r_executor,
                 print_inputs = FALSE) {
    create_stage_dirs(pipeline$stages %>% names())

    task_filter_factory <- if (!missing(filter)) {
        rlang::enquo(filter) %>% create_metadata_task_filter_factory()
    } else {
        unevaluated_task_filter_factory
    }

    stages_to_exec <- filter_stages_to_exec(pipeline$stages, rlang::enquo(from), rlang::enquo(only))

    purrr::walk(stages_to_exec, function(stage) {
        stage_outputs <- get_stage_outputs(stage$deps)

        if (clean) clear_stage_dir(stage$name)

        input_iters <- eval_inputs(stage_outputs, stage$input_quosures)
        task_iter <- stage_tasks_iter_from_args(stage, input_iters) %>% filter_iter(., task_filter_factory(stage$name))

        if (task_iter$done) {
            paste("No unevaluated tasks found for stage ", stage$name, "\n", sep = "") %>% cat()
            return()
        }

        save_tasks(stage$name, task_iter)

        if (print_inputs) print_stage_tasks(stage$name, task_iter)

        stage_executor <- if (!is.null(stage$executor)) stage$executor else executor

        stage_executor(task_iter, stage = stage)
    })
}
