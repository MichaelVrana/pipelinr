source("prototype.R")

pipeline <- make_pipeline(
    a = stage(inputs = stage_inputs(x = 1), body = function(x) x),
    b = stage(inputs = stage_inputs(y = a), body = function(y) {
        print(y + 1)
        y + 1
    })
)

run_pipeline(pipeline)
