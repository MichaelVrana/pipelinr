devtools::load_all()

data <- list(
    list(number = 1, str = "a"),
    list(number = 2, str = "b"),
    list(number = 3, str = "c")
)

pipeline <- make_pipeline(
    stage1 = stage(inputs = stage_inputs(x = data %>% vec_to_iter()), body = function(x) {
        print("stage1 called")
        print(x)
        list(number = x$number * 2, str = x$str)
    }),
    stage2 = stage(inputs = stage_inputs(x = stage1), body = function(x) {
        print("stage2 called")
        print(x)
    }),
    stage3 = stage(
        inputs = stage_inputs(
            single_elem = stage2,
            collected = stage2 %>% collect()
        ),
        body = function(single_elem, collected) {
            print("stage3 called")
            print("single_elem")
            print(single_elem)
            print("collected")
            print(collected)
        }
    )
)

results <- run_pipeline(pipeline)
