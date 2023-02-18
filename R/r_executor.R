library(rlang)
library(purrr)

r_executor <- function(task_iter, pipeline_dir) {
    list(
        results_iter =
            task_iter %>%
                map_iter(., function(task) do.call(task$body, task$args)) %>%
                collect_iter() %>%
                vec_to_iter(),
        metadata_iter = make_empty_iter()
    )
}
