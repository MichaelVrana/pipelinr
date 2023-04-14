.First <- function() {
    Sys.setenv(PARALLEL_SSH = paste("ssh -F ", file.path(getwd(), "ssh_worker", "ssh.config"), sep = ""))
    library(devtools)
    devtools::load_all()
}
