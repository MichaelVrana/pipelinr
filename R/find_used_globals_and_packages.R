library(codetools)
library(purrr)

is_ns_access_operator <- function(fun_name) fun_name == "::" || fun_name == ":::"

find_used_namespaces <- function(ast) {
    if (is.call(ast)) {
        fun_name <- ast[[1]] %>% toString()

        if (is_ns_access_operator(fun_name)) {
            namespace <- ast[[2]] %>% toString()

            if (namespace == "base") {
                return(character())
            }

            return(namespace)
        }

        return(
            tail(ast, n = 1) %>% map(., find_used_namespaces) %>% unlist()
        )
    }

    if (is.pairlist(ast)) {
        return(map(ast, find_used_namespaces) %>% unlist())
    }

    character()
}

find_used_globals_and_packages <- function(fun) {
    empty_result <- list(globals = list(), packages = character())

    if (is.primitive(fun)) {
        return(empty_result)
    }

    fun_env <- environment(fun)
    env_name <- environmentName(fun_env)

    if (env_name == "base") {
        return(empty_result)
    }

    if (env_name != "R_GlobalEnv") {
        return(list(globals = list(), packages = env_name))
    }

    globals <- codetools::findGlobals(fun)

    used_packages <- if (some(globals, is_ns_access_operator)) {
        body(fun) %>% find_used_namespaces()
    } else {
        character()
    }

    map(globals, function(global_name) {
        value <- get(global_name, fun_env)

        result <- if (is.function(value)) {
            find_used_globals_and_packages(value)
        } else {
            c(empty_result)
        }

        result$globals[[global_name]] <- value
        result
    }) %>% reduce(., .init = list(globals = list(), packages = used_packages), merge_lists)
}
