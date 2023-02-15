library(rlang)
library(purrr)

r_executor <- function(task_iter) {
    map_iter(task_iter, function(task) do.call(task$body, task$args))
}
