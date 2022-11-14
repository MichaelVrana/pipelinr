# R Pipeline DSL

The DSL is used to specifies stages of data processing pipeline and dependencies among those stages. The pipeline consists of multiple stages and each stage has 0..n inputs from other stages. Stages must form a DAG, eg cycles are forbidden.

## Stage

Stage is constructed using the `stage` function.

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

**TODO**: Should we require that the arity of the `body` function be equal or greater or equal than the number of inputs?

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

The `stage` function returns an object representing the stage definition. To assemble the pipeline pass these objects into the `make_pipeline` function:

```R

```