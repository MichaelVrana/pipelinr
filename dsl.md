# R Pipeline DSL

The DSL is used to specifies stages of data processing pipeline and dependencies among those stages. The pipeline consists of multiple stages and each stage can have 0..n inputs from other stages. Stages must form a DAG, eg cycles are forbidden.

## Stage

Stage is the main building block of pipelines. Each stage can produce multiple tasks which can be executed in parallel. It is constructed using the `stage` function.

```R
function stage(body = (...inputs) -> Any, ...inputs)
```

Each stage has a mandatory body parameter that specifies a function that will be executed for each task input. If no input is provided, the body function will be invoked once.

Stage inputs are specified as named arguments. Each input is bound to the argument of the `body` function with the same name.


```R
stage(a = 1, b = "hello world", body = function (a, b) {
    # a == 1
    # b == "hello world"
})
```

In the example above we define two inputs, which are bound to parameters `a` and `b` inside the `body` function. The order of parameters in the `body` function does not matter. Since the `body` function can be executed in different processes it should not do any side-effects.

**TODO**: Should we require that the arity of the `body` function be equal or greater or equal than the number of inputs? I think it makes sense that we allow inputs that are not passed to the body function but instead are used as intermediate results for other inputs.

Stages can depend on results from other stages:

```R
data <- stage(body = function () {
    read.csv("data.csv")
})

result <- stage(input = data, body = function (input) {...})
```

Second stage defines an input named `input` which is the result of the first stage.

**TODO**: Should we make (if possible) the stage outputs as implicit inputs? In that case the example above would look like this:

```R
data <- stage(body = function () {
    read.csv("data.csv")
})

result <- stage(body = function (data) {...})
```

## Pipeline

The `stage` function returns an object representing the stage definition. To assemble the pipeline pass these objects into the `make_pipeline` function:

```R
pipeline <- make_pipeline(
    stage1,
    stage2,
    stage3,
    ...
)
```

You can also define pipeline stages inline:

```R
pipeline <- make_pipeline(
    data <- stage(body = function () {
        read.csv("data.csv")
    }),
    result <- stage(input = data, body = function (input) {...})
)
```

Run the pipeline using the `run_pipeline`:

```R
run_pipeline(pipeline, ...params)
```

## Input generators

**TODO**: should we call the input generators or input operators?

Each pipeline stage can generate multiple tasks which can be executed in parallel. You can use input generators to preprocess inputs and to map them to multiple tasks in a given stage.

### `map`

The `map` operator takes an iterable input and maps each element to a separate input:

```R
data <- list(1, 2, 3)

result <- stage(input = map(data), body = function (input) {...})
```

In the example above, the result stage will be executed three times with inputs `1`, `2` and `3`.Without the `map` generator the stage would have been executed once with list(1, 2, 3) as its input.

When using the `map` generator on multiple inputs, the final inputs are zipped together:

```R
numbers <- list(1, 2, 3)
strings <- list("a", "b")

result <- stage(number = map(list1), string = map(strings), body = function (number, string) {...})
```

In this example the result stage would have been invoked three times with inputs:

1. number = `1`, string = `"a"`
2. number = `2`, string = `"b"`
3. number = `3`, string = `NA`

If the inputs are not of the same length, `NA` value is substituted as the values of the shorter input.

**TODO**: This one I am not sure on, there could be an optional parameter in the `stage` function that would dictate behavior in the case of different input lengths.

**TODO**: Maybe the `map` behavior should be by default? That means all stage inputs must be lists and the body function is called for each element of those lists. If one would want to call the body function on all the outputs from the previous stage, it would have be wrapped inside another list (a list with one element). This would also simplify semantics of other input generators I think. The above example would look the same except there would be no `map` generators.

If a `stage` has multiple inputs, all of its outputs will be returned as a list. Each returned output will also contain metadata about its execution.

**TODO**: Decide if metadata will be part of the output object, or if they will be returned in a special variable, for example `result_metadata`.

### `metadata`

Metadata input generator takes an output from previous stage and returns the output with its execution metadata.

**TODO**: What about metadata for a single task output vs metadata for the whole stage? If the generator is given the whole output from the previous stage, should it just get metadata for each task in the given stage, eg given a list of outputs, should it map each output to its metadata?

### `failed`

Takes a previous stage output and filters out those outputs, that failed during execution. Also maps each output to its metadata.

### `filter`

Takes an iterable input and an predicate expression. Returns only those elements satisfying the predicate expression.

```R
data <- tibble(x = 1:3)

stage(input = filter(x % 2 == 0) %>% map, body = function (input) {
    #input == 2
})
```

**TODO**: What about filtering list vs filtering the results from `map` generator?

**TODO**: Should it be a dplyr like filter or a filter from other languages that takes in a predicate function returning a boolean?

### `merge`

Given a list of iterables, merges each element of the list together.

```R
data <- list(tibble(x = 1:3, y = 9:7), tibble(x = 4:6, y = 6:4))

stage(input = merge(data), body = function (input) {
    # input == tibble(x = 1:6, y = 9:4)
})
```

### `cross`

Given two iterables it creates their cartesian product.

```R
list1 <- list(1, 2)
list2 <- list("a", "b")

stage(input = cross(list1, list2) %>% map, body = function (input) {
    # 1. input == list(1, "a")
    # 2. input == list(1, "b")
    # 3. input == list(2, "a")
    # 4. input == list(2, "b")
})
```