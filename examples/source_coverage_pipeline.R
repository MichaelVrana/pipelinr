library(devtools)

devtools::load_all()

source_files <- function(package) {
    switch(package,
        p1 = c("a.R", "b.R", "c.R"),
        p2 = c("d.R", "e.R")
    )
}

source_coverage <- function(package, package_source) {
    switch(package_source,
        a.R = .1,
        b.R = .2,
        c.R = .3,
        d.R = .4,
        e.R = .5
    )
}

executor <- make_gnu_parallel_executor("tests/test_worker/nodefile")

pipeline <- make_pipeline(
    # () =>  Vec<character>
    packages = stage(function() c("p1", "p2")),
    # (char) => Vec<char>
    package_source = stage(inputs = stage_inputs(package = mapped(packages)), function(package) {
        data.frame(package = package, src = source_files(package))
    }),
    # (char, Vec<char>) => double
    package_source_coverage = stage(
        inputs = stage_inputs(
            package_with_source = collect_iter(package_source) %>% do.call(rbind, .) %>% transpose() %>% vec_to_iter()
        ),
        body = function(package_with_source) {
            cov <- source_coverage(package_with_source$package, package_with_source$src)

            data.frame(pkg = package_with_source$package, src = package_with_source$src, coverage = cov)
        },
        # override_executor = executor
    ),
    # (List<double>) => ...
    metadata = stage(
        inputs = stage_inputs(
            package_source_coverage_whole = collect_iter(package_source_coverage) %>% do.call(rbind, .)
        ),
        body = function(package_source_coverage_whole) {

        }
    )
)

run_pipeline(pipeline, print_inputs = TRUE)
