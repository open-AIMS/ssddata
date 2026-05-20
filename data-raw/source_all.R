datasets <- c("aims", "anon", "anzg", "ccme", "csiro")

files <- file.path("data-raw", datasets, "DATASET.R")

invisible(lapply(files, source))
