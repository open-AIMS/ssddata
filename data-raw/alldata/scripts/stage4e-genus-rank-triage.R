# Stage 4e — Genus-rank triage: raw_genus_level vs floored_binomial (READ-ONLY)
#
# Separates the 765 flagged genus-rank accepted_name values into:
#   raw_genus_level  — raw name was already genus-level in the source (expected)
#   floored_binomial — raw name was a binomial that the resolver floored to genus
#                      (worth reviewing for potential resolver misses)
#
# Does NOT modify any pipeline script or intermediate CSV.
#
# Inputs:
#   data-raw/alldata/uncurated_raw_dedup_enriched.csv   (~228 MB, untracked)
#
# Outputs (small, tracked artefacts):
#   scripts/stage4e-genus-rank-triage.md          — counts and cross-tabs
#   data-raw/alldata/stage4e-genus-rank-triage.csv — one row per distinct
#                                                    original_scientificname
#
# Run from the repo root (WSL or Windows Positron; no DB required).

library(readr)
library(dplyr)

# ---------------------------------------------------------------------------
# Detection function (self-contained; identical to stage4e-genus-rank-diagnostic.R)
# ---------------------------------------------------------------------------

flag_genus_rank <- function(name, genus = NULL) {
  nm   <- trimws(name)
  core <- trimws(sub("\\s+(spp|sp|cf|aff|nr|gen)\\.?(\\s.*)?$", "", nm,
                     ignore.case = TRUE))
  no_epithet    <- !grepl("\\s", core)
  had_qualifier <- grepl("\\b(spp|sp|cf|aff|nr)\\.?(\\s|$)", nm,
                         ignore.case = TRUE)
  out <- no_epithet | had_qualifier
  if (!is.null(genus)) out <- out | (!is.na(genus) & nm == trimws(genus))
  out
}

# Modal value helper
modal <- function(x) {
  tb <- table(x, useNA = "no")
  if (length(tb) == 0L) return(NA_character_)
  names(sort(tb, decreasing = TRUE))[1]
}

# ---------------------------------------------------------------------------
# Load enriched file and reproduce the genus-rank subset
# ---------------------------------------------------------------------------

message("Loading enriched file (this may take a minute) ...")
enriched <- read_csv(
  "data-raw/alldata/uncurated_raw_dedup_enriched.csv",
  guess_max = Inf,
  show_col_types = FALSE
)
message("Loaded: ", nrow(enriched), " rows x ", ncol(enriched), " cols")

# Stage 4e clean subset
clean <- enriched |>
  filter(dedup_retained == TRUE, priority_kept == TRUE)
n_clean <- nrow(clean)
message("Clean subset: ", n_clean, " rows")

# Flag genus-rank rows (genus cross-check included, as in the diagnostic)
clean <- clean |>
  mutate(is_genus_rank = flag_genus_rank(accepted_name, genus))

genus_rows <- clean |> filter(is_genus_rank)
n_flagged  <- nrow(genus_rows)
message("Genus-rank rows: ", n_flagged)

# Sanity-check against diagnostic
stopifnot(n_flagged == 11199L)

# ---------------------------------------------------------------------------
# Classify by raw name form
# ---------------------------------------------------------------------------

genus_rows <- genus_rows |>
  mutate(
    orig_indeterminate = flag_genus_rank(original_scientificname),   # genus = NULL
    bucket = if_else(orig_indeterminate, "raw_genus_level", "floored_binomial")
  )

# ---------------------------------------------------------------------------
# Row-level counts by bucket
# ---------------------------------------------------------------------------

bucket_counts <- genus_rows |>
  count(bucket, name = "n_rows") |>
  mutate(pct = round(100 * n_rows / n_flagged, 2)) |>
  arrange(bucket == "raw_genus_level")   # floored first

message("\nBucket row counts:")
print(bucket_counts)

# Distinct names per bucket
bucket_names <- genus_rows |>
  group_by(bucket) |>
  summarise(
    n_distinct_accepted  = n_distinct(accepted_name),
    n_distinct_original  = n_distinct(original_scientificname),
    .groups = "drop"
  )

message("\nDistinct name counts per bucket:")
print(bucket_names)

# ---------------------------------------------------------------------------
# Cross-tabs: bucket x resolution_status (row level)
# ---------------------------------------------------------------------------

xtab_resolution <- genus_rows |>
  count(bucket, resolution_status, name = "n_rows") |>
  arrange(bucket == "raw_genus_level", resolution_status)

message("\nCross-tab bucket x resolution_status:")
print(xtab_resolution, n = Inf)

# ---------------------------------------------------------------------------
# Cross-tab: bucket x source (row level)
# ---------------------------------------------------------------------------

xtab_source <- genus_rows |>
  count(bucket, source, name = "n_rows") |>
  arrange(bucket == "raw_genus_level", source)

message("\nCross-tab bucket x source:")
print(xtab_source)

# ---------------------------------------------------------------------------
# Build triage CSV: one row per distinct original_scientificname
# ---------------------------------------------------------------------------

triage <- genus_rows |>
  group_by(original_scientificname) |>
  summarise(
    bucket              = modal(bucket),
    accepted_name       = modal(accepted_name),
    genus               = modal(genus),
    resolution_status   = modal(resolution_status),
    taxonomy_provenance = modal(taxonomy_provenance),
    sources             = paste(sort(unique(source)), collapse = ", "),
    n_rows              = n(),
    .groups = "drop"
  ) |>
  arrange(bucket == "raw_genus_level", desc(n_rows))   # floored first, then by n_rows

message("\nTriage table: ", nrow(triage), " distinct original_scientificname values")
message("  floored_binomial: ",
        sum(triage$bucket == "floored_binomial"), " rows")
message("  raw_genus_level:  ",
        sum(triage$bucket == "raw_genus_level"), " rows")

# ---------------------------------------------------------------------------
# Write outputs
# ---------------------------------------------------------------------------

write_csv(triage, "data-raw/alldata/stage4e-genus-rank-triage.csv")
message("Written: data-raw/alldata/stage4e-genus-rank-triage.csv")

# ---------------------------------------------------------------------------
# Build markdown report
# ---------------------------------------------------------------------------

fmt_tbl <- function(df) {
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep    <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  rows   <- apply(df, 1, function(r) {
    paste0("| ", paste(r, collapse = " | "), " |")
  })
  paste(c(header, sep, rows), collapse = "\n")
}

n_floored <- sum(triage$bucket == "floored_binomial")
n_raw     <- sum(triage$bucket == "raw_genus_level")

report <- paste0(
  "# Stage 4e — Genus-rank triage: raw_genus_level vs floored_binomial\n\n",
  "Date: ", Sys.Date(), "\n\n",
  "Classifies the ", format(n_flagged, big.mark = ","),
  " genus-rank flagged rows from the Stage 4e diagnostic into two buckets:\n\n",
  "- **raw_genus_level**: raw source name was already at genus level (expected)\n",
  "- **floored_binomial**: raw name was a binomial but the resolver floored it to genus\n\n",
  "---\n\n",
  "## Row counts by bucket\n\n",
  fmt_tbl(
    bucket_counts |>
      mutate(pct = paste0(pct, "%"))
  ), "\n\n",
  "## Distinct name counts by bucket\n\n",
  fmt_tbl(bucket_names), "\n\n",
  "---\n\n",
  "## Cross-tab: bucket x resolution_status (row level)\n\n",
  fmt_tbl(xtab_resolution), "\n\n",
  "---\n\n",
  "## Cross-tab: bucket x source (row level)\n\n",
  fmt_tbl(xtab_source), "\n\n",
  "---\n\n",
  "## Triage CSV summary\n\n",
  "File: `data-raw/alldata/stage4e-genus-rank-triage.csv`\n\n",
  "One row per distinct `original_scientificname` among the ",
  format(n_flagged, big.mark = ","), " flagged rows.\n\n",
  "| Bucket | Distinct original_scientificname |\n",
  "| --- | --- |\n",
  "| floored_binomial | ", n_floored, " |\n",
  "| raw_genus_level | ", n_raw, " |\n",
  "| **Total** | **", nrow(triage), "** |\n\n",
  "Filter to `bucket == \"floored_binomial\"` for the review-candidate set.\n\n",
  "---\n\n",
  "## Files to commit\n\n",
  "- `data-raw/alldata/scripts/stage4e-genus-rank-triage.R` — this script\n",
  "- `data-raw/alldata/scripts/stage4e-genus-rank-triage.md` — this report\n",
  "- `data-raw/alldata/stage4e-genus-rank-triage.csv` — per-original-name triage table\n"
)

writeLines(report, "data-raw/alldata/scripts/stage4e-genus-rank-triage.md")
message("Written: data-raw/alldata/scripts/stage4e-genus-rank-triage.md")

message("\nTriage complete.")
message("  floored_binomial: ", n_floored, " distinct original names")
message("  raw_genus_level:  ", n_raw, " distinct original names")
message("  Triage CSV: data-raw/alldata/stage4e-genus-rank-triage.csv")
