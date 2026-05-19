#    Copyright 2021 Australian Institute of Marine Science
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

# Script to build _pkgdown.yml with structured reference headings.
# Run from the package root directory (e.g. via source("data-raw/build_pkgdown.R")).

output_file <- "_pkgdown.yml"

# Get all available datasets from the installed/loaded package
all_items <- utils::data(package = "ssddata")$results[, "Item"]

# Categorise individual datasets (exclude *_data multi-chemical datasets)
aims_individual <- sort(grep("^aims_(?!data$)", all_items, value = TRUE, perl = TRUE))
anon_individual <- sort(grep("^anon_(?!data$)", all_items, value = TRUE, perl = TRUE))
anzg_individual <- sort(grep("^anzg_(?!data$)", all_items, value = TRUE, perl = TRUE))
ccme_individual <- sort(grep("^ccme_(?!data$)", all_items, value = TRUE, perl = TRUE))
csiro_individual <- sort(grep("^csiro_(?!data$)", all_items, value = TRUE, perl = TRUE))

# Multi-chemical datasets (one per source organisation)
multi_datasets <- c("aims_data", "anon_data", "anzg_data", "ccme_data", "csiro_data")
multi_datasets <- multi_datasets[multi_datasets %in% all_items]

# Derived SSD datasets (added to the package over time)
derived_datasets <- c("anztox_data", "wqbench_data")
derived_datasets <- derived_datasets[derived_datasets %in% all_items]

# Helper to format a vector of dataset names as indented YAML list entries
format_yaml_list_items <- function(items) {
  paste0("  - ", items, collapse = "\n")
}

# Build YAML sections as character strings
lines <- c("reference:")

# ── 1. Individual SSD datasets ──────────────────────────────────────────────
lines <- c(lines, "- title: Individual SSD datasets")
lines <- c(lines, "  desc: Individual chemical-specific species sensitivity datasets.")

if (length(aims_individual) > 0) {
  lines <- c(
    lines,
    "- subtitle: Data from the Australian Institute of Marine Science",
    "  desc: Individual chemical datasets provided by the Australian Institute of Marine Science.",
    "  contents:",
    format_yaml_list_items(aims_individual)
  )
}

if (length(anon_individual) > 0) {
  lines <- c(
    lines,
    "- subtitle: Data provided from anonymous sources",
    "  contents:",
    format_yaml_list_items(anon_individual)
  )
}

if (length(anzg_individual) > 0) {
  lines <- c(
    lines,
    "- subtitle: Data from the Australian and New Zealand guidelines",
    "  desc: Individual chemical datasets from the Australian and New Zealand guidelines.",
    "  contents:",
    format_yaml_list_items(anzg_individual)
  )
}

if (length(ccme_individual) > 0) {
  lines <- c(
    lines,
    "- subtitle: Data from the Canadian Council of Ministers of the Environment",
    "  desc: Individual chemical datasets from the Canadian Council of Ministers of the Environment.",
    "  contents:",
    format_yaml_list_items(ccme_individual)
  )
}

if (length(csiro_individual) > 0) {
  lines <- c(
    lines,
    "- subtitle: Data provided by the Commonwealth Scientific and Industrial Research Organisation of Australia",
    "  desc: Individual chemical datasets provided by CSIRO.",
    "  contents:",
    format_yaml_list_items(csiro_individual)
  )
}

# ── 2. Multi chemical SSD datasets ──────────────────────────────────────────
if (length(multi_datasets) > 0) {
  lines <- c(
    lines,
    "- title: Multi chemical SSD datasets",
    "  desc: Datasets containing species sensitivity data for multiple chemicals.",
    "  contents:",
    format_yaml_list_items(multi_datasets)
  )
}

# ── 3. Derived SSD datasets ──────────────────────────────────────────────────
if (length(derived_datasets) > 0) {
  lines <- c(
    lines,
    "- title: Derived SSD datasets",
    "  desc: Datasets derived from the individual SSD datasets.",
    "  contents:",
    format_yaml_list_items(derived_datasets)
  )
}

# ── SSD Fit Results ──────────────────────────────────────────────────────────
if ("ssd_fits" %in% all_items) {
  lines <- c(
    lines,
    "- title: SSD Fit Results",
    "  desc: Results of fitting species sensitivity distributions using different software.",
    "  contents:",
    "  - ssd_fits"
  )
}

# ── Functions ────────────────────────────────────────────────────────────────
lines <- c(
  lines,
  "- title: Functions",
  "  desc: Functions for working with SSD data.",
  "  contents:",
  "  - ssd_data_sets",
  "  - get_ssddata",
  "  - gm_mean"
)

writeLines(lines, output_file)
message("_pkgdown.yml written successfully.")
