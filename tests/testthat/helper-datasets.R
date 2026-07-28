# Shared helpers for the package-wide data sweeps. testthat sources
# helper-*.R before any test file, so these are available everywhere.

# Cache for the sweeps below. The package-wide tests load every shipped data
# object several times over; loading is deterministic, so caching keeps the
# suite fast without weakening any assertion.
.cache <- new.env(parent = emptyenv())

# Load a package data object by name without attaching it to the global
# environment (the same trick ssd_data_sets() uses internally).
pkg_data <- function(name) {
  if (!exists(name, envir = .cache, inherits = FALSE)) {
    e <- new.env()
    utils::data(list = name, package = "ssddata", envir = e)
    assign(name, e[[name]], envir = .cache)
  }
  get(name, envir = .cache, inherits = FALSE)
}

# Names of every data object shipped by the package.
shipped_items <- function() {
  sort(utils::data(package = "ssddata")$results[, "Item"])
}

# Shipped items that are data frames. Excludes envirotox_data, which is a
# named list of three tibbles rather than a tibble itself.
shipped_data_frames <- function() {
  items <- shipped_items()
  items[vapply(items, function(x) is.data.frame(pkg_data(x)), logical(1))]
}

# The five source families that ship both per-chemical objects and an
# aggregate `{prefix}_data` object.
source_families <- c("aims", "anzg", "ccme", "csiro", "anon")

# Per-chemical objects for a family (i.e. the aggregate excluded).
family_components <- function(prefix) {
  items <- shipped_items()
  setdiff(grep(paste0("^", prefix, "_"), items, value = TRUE), paste0(prefix, "_data"))
}
