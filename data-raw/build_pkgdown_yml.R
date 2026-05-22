# data-raw/build_pkgdown_yml.R
#
# Generates _pkgdown.yml for the ssddata package.
#
# Run this script from the package root after calling devtools::document(),
# so that the man/ directory is up to date before the YAML is rebuilt.
#
# Usage (from package root in R console):
#   source("data-raw/build_pkgdown_yml.R")
#
# The script writes _pkgdown.yml to the package root, overwriting any
# existing file. Commit the result alongside any dataset changes.

# ---------------------------------------------------------------------------
# 0. Guard: must be run from the package root
# ---------------------------------------------------------------------------

if (!file.exists("DESCRIPTION")) {
  stop(
    "This script must be sourced from the package root directory ",
    "(the folder that contains DESCRIPTION)."
  )
}

# ---------------------------------------------------------------------------
# 1. Discover all documented topics from man/
# ---------------------------------------------------------------------------

rd_files <- list.files("man", pattern = "\\.Rd$", full.names = FALSE)

if (length(rd_files) == 0L) {
  stop(
    "No .Rd files found in man/. ",
    "Run devtools::document() before sourcing this script."
  )
}

all_topics <- tools::file_path_sans_ext(rd_files)
all_topics <- sort(all_topics)

message("Found ", length(all_topics), " documented topics in man/")

# ---------------------------------------------------------------------------
# 2. Define the known source prefixes and their full heading labels
#    (ordered as specified in issue #19)
# ---------------------------------------------------------------------------

source_prefixes <- c(
  "aims" = "Data from the Australian Institute of Marine Science",
  "anon" = "Data provided from anonymous sources",
  "anzg" = "Data from the Australian and New Zealand guidelines",
  "ccme" = "Data from the Canadian Council of Ministers of the Environment",
  "csiro" = "Data provided by the Commonwealth Scientific and Industrial Research Organisation of Australia"
)

# Aggregate (*_data) topic names for the known prefixes
aggregate_topics <- paste0(names(source_prefixes), "_data")

# Hard-coded derived datasets (do not follow the prefix_data naming pattern).
# Update this vector if new derived datasets are added to the package.
derived_topics <- c("anztox_data", "envirotox_data", "wqbench_data")

# Hard-coded fitted results dataset.
# Update this vector if additional fitted-results topics are added.
fitted_topics <- c("ssd_fits")

# Hard-coded package-overview topic.
# roxygen2 always names this <package>-package, so this rarely needs changing.
overview_topics <- c("ssddata-package")

# ---------------------------------------------------------------------------
# 3. Classify topics
# ---------------------------------------------------------------------------

# 3a. Individual datasets: match a known prefix, exclude the *_data aggregate
individual_by_prefix <- lapply(names(source_prefixes), function(pfx) {
  pattern <- paste0("^", pfx, "_")
  matched <- grep(pattern, all_topics, value = TRUE)
  matched <- matched[matched != paste0(pfx, "_data")]
  sort(matched)
})
names(individual_by_prefix) <- names(source_prefixes)

# 3b. Multi-chemical aggregate datasets: only include those that exist in man/
multi_topics <- intersect(aggregate_topics, all_topics)
multi_topics <- aggregate_topics[aggregate_topics %in% multi_topics] # preserve order

# 3c. Derived datasets: only include those that exist in man/
derived_topics_present <- intersect(derived_topics, all_topics)

# 3d. Fitted results: only include those that exist in man/
fitted_topics_present <- intersect(fitted_topics, all_topics)

# 3e. Package overview: only include if it exists in man/
overview_topics_present <- intersect(overview_topics, all_topics)

# 3f. The three underlying envirotox component datasets are documented via
#     @seealso links on the envirotox_data page and do not appear as separate
#     reference page entries. Include them in accounted_for so they are not
#     misclassified as package functions.
envirotox_component_topics <- c(
  "envirotox_acute",
  "envirotox_chronic",
  "envirotox_chemical"
)
envirotox_component_topics <- intersect(envirotox_component_topics, all_topics)

# 3g. Package functions: every remaining topic not matched by any category above.
#     Sorted alphabetically. Updates automatically as functions are added/removed.
accounted_for <- c(
  overview_topics_present,
  unlist(individual_by_prefix, use.names = FALSE),
  multi_topics,
  derived_topics_present,
  fitted_topics_present,
  envirotox_component_topics
)
function_topics <- sort(setdiff(all_topics, accounted_for))

if (length(function_topics) > 0L) {
  message(
    "  Placed ",
    length(function_topics),
    " topic(s) in 'Package functions':\n    ",
    paste(function_topics, collapse = ", ")
  )
}

# ---------------------------------------------------------------------------
# 4. Helper: append a line to a character vector
# ---------------------------------------------------------------------------

emit <- function(lines, ...) {
  c(lines, paste0(...))
}

# ---------------------------------------------------------------------------
# 5. Build the YAML lines
#
# pkgdown reference structure (title, subtitle, contents are SIBLINGS in the
# top-level reference list — subtitle is NOT nested inside contents):
#
#   reference:
#   - title: Section heading       # <h2>
#     desc: Optional description
#   - subtitle: Subheading         # <h3> — sibling of title, not child
#     desc: Optional description
#     contents:
#     - topic_name
#   - subtitle: Another subheading
#     contents:
#     - another_topic
#   - title: Next section
#     ...
# ---------------------------------------------------------------------------

yml <- character(0)

# -- File header -------------------------------------------------------------
yml <- emit(yml, "# Generated by data-raw/build_pkgdown_yml.R")
yml <- emit(yml, "# Do not edit by hand - re-run the script to regenerate.")
yml <- emit(yml, "")
yml <- emit(yml, "url: https://open-aims.github.io/ssddata/")
yml <- emit(yml, "")
yml <- emit(yml, "template:")
yml <- emit(yml, "  bootstrap: 5")
yml <- emit(yml, "")
yml <- emit(yml, "development:")
yml <- emit(yml, "  mode: auto")
yml <- emit(yml, "")

# -- Authors ----------------------------------------------------------------
fisher_url <- "https://www.aims.gov.au/about/our-people/dr-rebecca-fisher"
yml <- emit(yml, "authors:")
yml <- emit(yml, "  Rebecca Fisher:")
yml <- emit(yml, "    href: ", fisher_url)
yml <- emit(yml, "  Joe Thorley:")
yml <- emit(yml, "    href: https://github.com/joethorley")
yml <- emit(yml, "")
yml <- emit(yml, "  Ayla Pearson:")
yml <- emit(yml, "    href: https://github.com/aylapearson")
yml <- emit(yml, "")

# -- Reference section -------------------------------------------------------
yml <- emit(yml, "reference:")

# ---- Section 0: Package overview -------------------------------------------
if (length(overview_topics_present) > 0L) {
  yml <- emit(yml, "- title: Package overview")
  yml <- emit(
    yml,
    "  desc: Overview and introductory help for the ssddata package."
  )
  yml <- emit(yml, "- contents:")
  for (ov in overview_topics_present) {
    yml <- emit(yml, "  - ", ov)
  }
}

# ---- Section 1: Individual SSD datasets ------------------------------------
# The title entry has no contents of its own; each source group is a subtitle
# sibling that carries its own contents block.
yml <- emit(yml, "- title: Individual SSD datasets")
yml <- emit(
  yml,
  "  desc: Single-chemical species sensitivity datasets grouped by data source."
)

for (pfx in names(source_prefixes)) {
  heading <- source_prefixes[[pfx]]
  datasets <- individual_by_prefix[[pfx]]

  if (length(datasets) == 0L) {
    message("  Note: no individual datasets found for prefix '", pfx, "_'")
    next
  }

  yml <- emit(yml, "- subtitle: \"", heading, "\"")
  yml <- emit(yml, "  contents:")
  for (ds in datasets) {
    yml <- emit(yml, "  - ", ds)
  }
}

# ---- Section 2: Multi-chemical SSD datasets --------------------------------
yml <- emit(yml, "- title: Aggregate SSD datasets")
yml <- emit(
  yml,
  "  desc: Combined datasets containing all chemicals from each source organisation individual dataset."
)
yml <- emit(yml, "- contents:")
for (ds in multi_topics) {
  yml <- emit(yml, "  - ", ds)
}

# ---- Section 3: Derived SSD datasets ---------------------------------------
yml <- emit(yml, "- title: Multi-chemical derived SSD datasets")
yml <- emit(
  yml,
  "  desc: Datasets derived or aggregated from primary online sources."
)
# Non-envirotox derived datasets share a flat contents block
# non_envirotox_derived <- derived_topics_present[
#   derived_topics_present != "envirotox_data"
# ]
if (length(derived_topics_present) > 0L) {
  yml <- emit(yml, "- contents:")
  for (ds in derived_topics_present) {
    yml <- emit(yml, "  - ", ds)
  }
}
# # envirotox_data gets its own subtitle entry
# if ("envirotox_data" %in% derived_topics_present) {
#   yml <- emit(
#     yml,
#     "- subtitle: \"Species Sensitivity Data from the EnviroTox Database\""
#   )
#   yml <- emit(yml, "  contents:")
#   yml <- emit(yml, "  - envirotox_data")
# }

# ---- Section 4: Fitted SSD results -----------------------------------------
if (length(fitted_topics_present) > 0L) {
  yml <- emit(yml, "- title: Fitted SSD results")
  yml <- emit(
    yml,
    "  desc: Pre-fitted species sensitivity distribution model results."
  )
  yml <- emit(yml, "- contents:")
  for (ft in fitted_topics_present) {
    yml <- emit(yml, "  - ", ft)
  }
}

# ---- Section 5: Package functions ------------------------------------------
if (length(function_topics) > 0L) {
  yml <- emit(yml, "- title: Package functions")
  yml <- emit(yml, "  desc: Utility functions exported by the ssddata package.")
  yml <- emit(yml, "- contents:")
  for (fn in function_topics) {
    yml <- emit(yml, "  - ", fn)
  }
}

# ---------------------------------------------------------------------------
# 6. Write the file
# ---------------------------------------------------------------------------

out_path <- "_pkgdown.yml"
writeLines(yml, out_path)
message("Written: ", normalizePath(out_path))
message(
  "Next steps:\n",
  "  1. Review _pkgdown.yml for correctness\n",
  "  2. Run pkgdown::build_reference_index() to check the reference page only\n",
  "  3. Run pkgdown::build_site() for the full site\n",
  "  4. Commit _pkgdown.yml"
)
