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

If you also want to use the SSH functionality you need to have the [OpenSSH](https://www.openssh.com/) client installed. The SSH hosts need to have the following dependencies:  [Perl](https://www.perl.org/), [`rsync`](https://en.wikipedia.org/wiki/Rsync), and [R](https://www.r-project.org/) with [`qs`](https://github.com/traversc/qs) and [`lubridate`](https://lubridate.tidyverse.org/) packages.

## Getting started
Start by creating a `pipeline.R` file:

```R
make_pipeline(
    a = stage(function() "Hello world"),
    b = stage(function(a) paste(a, "from the pipeline!"))
)
```

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