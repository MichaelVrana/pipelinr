source("prototype.R")

make_pipeline(
    a = stage(body = function(x) x, inputs = list(x = 1)),
    b = stage(inputs = list(y = a + 2), body = function(y) {
        print(y + 1)
        y + 1
    })
) %>% run_pipeline()
