library(rlang)
library(purrr)

r_executor <- function(task_iter, stage, pipeline_dir) {
    list(
        results_iter =
            task_iter %>%
                map_iter(., function(task) do.call(stage$body, task$args)) %>%
                collect() %>%
                vec_to_iter(),
        metadata_iter = make_empty_iter()
    )
}
