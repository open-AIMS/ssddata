datasets <- c("aims", "anon", "anzg", "ccme", "csiro", "envirotox")

files <- file.path("data-raw", datasets, "DATASET.R")

invisible(lapply(files, source))
