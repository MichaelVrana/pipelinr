.First <- function() {
    library(devtools)
    library(processx)

    run(
        command = "./run_test_workers.sh",
        wd = "ssh_worker",
        stdout = "",
        stderr = "",
    )

    Sys.setenv(PARALLEL_SSH = paste("ssh -F ", file.path(getwd(), "ssh_worker", "ssh.config"), sep = ""))

    devtools::load_all()
}
