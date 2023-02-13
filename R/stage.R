library(rlang)

stage_inputs <- function(...) enquos(...)

stage <- function(body, inputs = stage_inputs()) {
    list(body = body, input_quosures = inputs)
}
