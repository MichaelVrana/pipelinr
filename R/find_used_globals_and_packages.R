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
    empty_result <- list(globals = list(), packages = character())

    if (is.primitive(fun)) {
        return(empty_result)
    }

    globals <- codetools::findGlobals(fun)
    fun_env <- environment(fun)

    map(globals, function(global_name) {
        value <- get(global_name, fun_env)
        package_name <- get_package_name(global_name)

        if (!is.null(package_name)) {
            return(list(globals = list(), packages = package_name))
        }

        result <- if (is.function(value)) {
            find_used_globals_and_packages(value)
        } else {
            list(globals = list(), packages = character())
        }

        result$globals[[global_name]] <- value
        result
    }) %>% reduce(., .init = empty_result, merge_lists)
}
