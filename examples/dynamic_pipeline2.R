devtools::load_all()

pipeline <- make_pipeline(
    numbers = stage(function() {
        1:3
    }),
    strings = stage(function() {
        list("a", "b")
    }),
    doubled_numbers = stage(
        inputs = stage_inputs(number = mapped(numbers)),
        body = function(number) {
            # print("doubled_numbers called")
            # print("number")
            # print(number)

            number * 2
        }
    ),
    crossed = stage(
        inputs = stage_inputs(doubled_nums_with_strs = cross_iter(doubled_numbers, mapped(strings))),
        body = function(doubled_nums_with_strs) {
            # print("crossed called")
            # print(doubled_nums_with_strs)
        }
    )
)

run_pipeline(pipeline, print_inputs = TRUE)
