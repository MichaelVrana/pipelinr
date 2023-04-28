library(codetools)
library(purrr)

is_ns_access_operator <- function(fun_name) fun_name == "::" || fun_name == ":::"

is_ns_access_call <- function(ast) {
    is.call(ast) && (ast[[1]] %>%
        toString() %>%
        is_ns_access_operator())
}

find_used_namespaces <- function(ast) {
    if (is_ns_access_call(ast)) {
        return(toString(ast[[2]]))
    }

    if (is.call(ast) || is.pairlist(ast)) {
        return(
            as.list(ast) %>%
                map(., find_used_namespaces) %>%
                unname() %>%
                unlist()
        )
    }

    character()
}

find_used_globals_and_packages <- function(fun) {
    empty_result <- list(globals = list(), packages = character())

    if (is.primitive(fun)) {
        return(empty_result)
    }

    fun_env <- environment(fun)

    if (isNamespace(fun_env)) {
        return(list(globals = list(), packages = environmentName(fun_env)))
    }

    find_used_globals_and_packages_rec <- function(fun, visited_globals = character()) {
        globals <- codetools::findGlobals(fun)

        used_packages <- if (some(globals, is_ns_access_operator)) {
            body(fun) %>% find_used_namespaces()
        } else {
            character()
        }

        new_visited_globals <- union(visited_globals, globals)

        fun_env <- environment(fun)

        keep(globals, function(global) !has_element(visited_globals, global)) %>%
            map(., function(global_name) {
                if (!exists(global_name, globalenv())) {
                    paste("Detected possible use of undeclared global", global_name) %>% warn()
                    return(c(empty_result))
                }

                value <- get(global_name, fun_env)

                result <- if (is.function(value)) {
                    if (is.primitive(value)) {
                        return(c(empty_result))
                    }

                    value_fun_env <- environment(value)

                    if (isNamespace(value_fun_env)) {
                        return(list(globals = list(), packages = environmentName(value_fun_env)))
                    }

                    find_used_globals_and_packages_rec(value, new_visited_globals)
                } else {
                    c(empty_result)
                }

                result$globals[[global_name]] <- value
                result
            }) %>%
            reduce(., .init = list(globals = list(), packages = used_packages), merge_lists)
    }

    find_used_globals_and_packages_rec(fun)
}
