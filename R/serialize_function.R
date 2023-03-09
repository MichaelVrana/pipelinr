library(codetools)
library(purrr)
library(qs)

get_package_name <- function(global_name) {
    namespace_split <- find(global_name) %>%
        strsplit(., ":") %>%
        pluck(1)

    if (length(namespace_split) != 2 || namespace_split[[2]] == "base") {
        return(NULL)
    }

    if (namespace_split[[1]] == "package") namespace_split[[2]] else NULL
}

find_used_globals_and_packages <- function(fun) {
    globals <- codetools::findGlobals(fun)
    fun_env <- environment(fun)

    map(globals, function(global_name) {
        value <- get(global_name, fun_env)
        package_name <- get_package_name(global_name)

        if (!is_null(package_name)) {
            return(list(globals = list(), packages = package_name))
        }

        result <- if (is.function(value)) {
            find_used_globals_and_packages(value)
        } else {
            list(globals = list(), packages = character())
        }

        result$globals[[global_name]] <- value
        result
    }) %>% reduce(.,
        .init = list(globals = list(), packages = character()),
        function(acc, curr) {
            list(
                globals = c(acc$globals, curr$globals),
                packages = c(acc$packages, curr$packages)
            )
        }
    )
}

serialize_function <- function(fun, filename) {
    globals <- find_used_globals_and_packages(fun)

    qsave(list(fun = fun, globals = as.environment(globals)), filename)
}

# foo <- function(from, to) map(from:to, function(x) x * x)

# bar <- function() foo(1, 3)

# find_used_globals_and_packages(bar)
