source("./dsl/prototype.R")

pipeline <- make_pipeline(
    numbers = stage(body = function(x) {
        1:3
    }),
    strings = stage(body = function(x) {
        list("a", "b")
    }),
    doubled_numbers = stage(
        inputs = stage_inputs(number = mapped(numbers), string = mapped(strings)),
        body = function(number, string) {
            print("doubled_numbers called")
            print("number")
            print(number)
            print("string")
            print(string)

            number * 2
        }
    ),
    crossed = stage(
        inputs = stage_inputs(doubled_nums_with_strs = cross_iter(doubled_numbers, strings)),
        body = function(doubled_nums_with_strs) {
            print("crossed called")
            print(doubled_nums_with_strs)
        }
    )
)

run_pipeline(pipeline)
