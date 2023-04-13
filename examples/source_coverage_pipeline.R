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

Sys.setenv(PARALLEL_SSH = paste("ssh -F ", file.path(getwd(), "ssh_worker", "ssh.config"), sep = ""))
executor <- file.path(getwd(), "ssh_worker", "nodefile") |> make_gnu_parallel_executor()

pipeline <- make_pipeline(
    packages = stage(function() c("p1", "p2")),
    #
    package_source = stage(
        inputs = stage_inputs(
            package = mapped(packages)
        ),
        body = function(package) {
            data.frame(package = package, src = source_files(package))
        }
    ),
    #
    package_source_coverage = stage(
        inputs = stage_inputs(
            package_with_source = mapped(package_source)
        ),
        body = function(package_with_source) {
            cov <- source_coverage(package_with_source$package, package_with_source$src)
            data.frame(pkg = package_with_source$package, src = package_with_source$src, coverage = cov)
        },
        override_executor = executor
    ),
    #
    metadata = stage(
        inputs = stage_inputs(
            package_source_coverage_whole = collect_df(package_source_coverage)
        ),
        body = function(package_source_coverage_whole) {}
    )
)

outputs <- make(pipeline = pipeline, print_inputs = TRUE, clean = TRUE)
