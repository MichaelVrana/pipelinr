source("prototype.R")

pipeline <- make_pipeline(
    a = stage(body = function(x) x, inputs = stage_inputs(x = 1)),
    b = stage(inputs = stage_inputs(y = a), body = function(y) {
        print(y + 1)
        y + 1
    })
)

run_pipeline(pipeline)
