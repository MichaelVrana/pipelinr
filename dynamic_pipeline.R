source("prototype.R")

data <- list(
    list(number = 1, str = "a"),
    list(number = 2, str = "b"),
    list(number = 3, str = "c")
)

pipeline <- make_pipeline(
    stage1 = stage(inputs = list(x = mapped(data)), body = function(x) {
        print("stage1 called")
        print(x)
        list(number = x$number * 2, str = x$str)
    }),
    stage2 = stage(inputs = list(x = stage1), body = function(x) {
        print("stage2 called")
        print(x)
    })
)

run_pipeline(pipeline)
