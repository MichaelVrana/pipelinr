# Pipelinr

## Overview
Pipelinr is an R package for defining and executing data analysis pipelines. A data analysis pipeline is a sequence of interdependent steps. In Pipelinr's terms these steps are called stages, which can be further broken down into individual tasks. These tasks can be executed in parallel or even remotely over SSH.

## Installation
Pipelinr currently is supported only on Linux, but it should probably work on MacOS too (not tested).

Install Pipelinr using the [`remotes`](https://remotes.r-lib.org/) package:

```
remotes::install_gitlab(host = 'https://gitlab.fit.cvut.cz', repo = 'vranami8/r-dsl')
```

If you want to use [GNU Parallel](https://www.gnu.org/software/parallel/) make sure it's installed.

If you also want to use the SSH functionality you need to have the [OpenSSH](https://www.openssh.com/) client installed. The SSH hosts need to have the following dependencies:  [Perl](https://www.perl.org/), [`rsync`](https://rsync.samba.org/), and [R](https://www.r-project.org/) with [`qs`](https://github.com/traversc/qs) and [`lubridate`](https://lubridate.tidyverse.org/) packages.

## Getting started
Start by creating a `pipeline.R` file:

```R
make_pipeline(
    a = stage(function() "Hello world"),
    b = stage(function(a) paste(a, "from the pipeline!"))
)
```

The `make_pipeline()` invocation needs to be the last expression in the file.

Run the pipeline by invoking the `make()` function from an R session:

```
> make()
Executing stage a [======================================] 1 / 1 100% ETA:  0s

Executing stage b [======================================] 1 / 1 100% ETA:  0s
```

Read the stage results using the `read()` function:

```
> read(b)
[[1]]
[1] "Hello world from the pipeline!"
```

You can explore more complex examples in `examples` directory.

## Dynamic branching
Dynamic branching allows the runtime to parallelize the execution of a given stage:

```R
gnu_parallel_executor <- make_gnu_parallel_executor()

make_pipeline(
    data = stage(function() 1:10),

    complex_computation = stage(
        inputs = stage_inputs(x = mapped(data)),
        body = function(x) {
            # Simulates a complex computation using the Sys.sleep()
            Sys.sleep(x)
            x
        },
        executor = gnu_parallel_executor
    )
)
```

The `mapped()` dynamic branching function will create a separate task for each element in the `data` stage results.

The `complex_computation` stage is going to be executed in parallel using the GNU Parallel executor. We can verify how long each time took to executed by inspecting the metadata using the `metadata_df()` function:

```R
> metadata_df(complex_computation)
# A tibble: 10 × 9
   args         hash         result failed stdout stderr start…¹ elapsed exit_…²
   <named list> <chr>        <list> <lgl>  <chr>  <chr>    <dbl>   <dbl>   <int>
 1 <int [1]>    4d2a43a7ffb… <int>  FALSE  ""     ""      1.68e9    8.01       0
 2 <int [1]>    50581f35817… <int>  FALSE  ""     ""      1.68e9    5.01       0
 3 <int [1]>    538226523d0… <int>  FALSE  ""     ""      1.68e9    1.00       0
 4 <int [1]>    611e10bf586… <int>  FALSE  ""     ""      1.68e9    3.00       0
 5 <int [1]>    62eecfce21f… <int>  FALSE  ""     ""      1.68e9    6.01       0
 6 <int [1]>    8524e43cacb… <int>  FALSE  ""     ""      1.68e9    2.00       0
 7 <int [1]>    918a73fb5b7… <int>  FALSE  ""     ""      1.68e9    9.01       0
 8 <int [1]>    d9c73c65d5e… <int>  FALSE  ""     ""      1.68e9    4.00       0
 9 <int [1]>    de4f160af6a… <int>  FALSE  ""     ""      1.68e9    10.0       0
10 <int [1]>    f223795cb7a… <int>  FALSE  ""     ""      1.68e9    7.01       0
# … with abbreviated variable names ¹​started_at, ²​exit_code
```

The elapsed column shows how long each task took to execute.

The following dynamic branching functions are available in the `stage_inputs()` expressions:

- `mapped()` - Creates new tasks from elements of lists, vectors, or rows of a data frame
- `remapped()` - Remaps values using a function
- `filtered()` - Filters values using a function
- `chained()` - Chains values to form a single input
- `zipped()` - Combines values into tuples
- `crossed()` - Creates all combination of values
- `take()` - Take first `n` values
- `collect()` - Collect values into a list
- `collect_df()` - Collect values into a data frame

These dynamic branching patterns are composable using pipe operators:

```R
stage_inputs(
    foo = filtered(bar, function(x) x > 0) %>% take(., 10)
)
```

Or using an ordinary function composition:

```R
stage_inputs(
    foo = take(filtered(bar, function(x) x > 0) , 10)
)
```

All of these functions actually operate on iterators and most are accessible outside of `stage_inputs()` expressions under different names:

| Pattern name | Function name   |
| ------------ | --------------- |
| `remapped()` | `map_iter()`    |
| `filtered()` | `filter_iter()` |
| `chained()`  | `chain_iter()`  |
| `zipped()`   | `zip_iter()`    |
| `crossed()`  | `cross_iter()`  |
| `take()`     | `head_iter()`   |
