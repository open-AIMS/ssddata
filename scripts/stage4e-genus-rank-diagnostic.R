# Stage 4e — Genus-rank accepted_name diagnostic (READ-ONLY)
#
# Quantifies how many uncurated pipeline entries are resolved only to genus rank.
# Does NOT modify any pipeline script or output CSV.
#
# Inputs:
#   data-raw/alldata/uncurated_raw_dedup_enriched.csv   (~228 MB, untracked)
#   data-raw/alldata/uncurated_raw_aggregated.csv       (untracked)
#
# Outputs (small, tracked artefacts):
#   scripts/stage4e-genus-rank-diagnostic.md            — readable report
#   data-raw/alldata/stage4e-genus-rank-candidates.csv  — per-species list
#
# Run from the repo root (WSL or Windows Positron; no DB required).

library(readr)
library(dplyr)

# ---------------------------------------------------------------------------
# Detection function (will be lifted verbatim into stage4e-aggregate.R)
# ---------------------------------------------------------------------------

flag_genus_rank <- function(name, genus = NULL) {
  nm   <- trimws(name)
  core <- trimws(sub("\\s+(spp|sp|cf|aff|nr|gen)\\.?(\\s.*)?$", "", nm,
                     ignore.case = TRUE))
  no_epithet    <- !grepl("\\s", core)                         # single token
  had_qualifier <- grepl("\\b(spp|sp|cf|aff|nr)\\.?(\\s|$)", nm,
                         ignore.case = TRUE)
  out <- no_epithet | had_qualifier
  if (!is.null(genus)) out <- out | (!is.na(genus) & nm == trimws(genus))
  out
}

# ---------------------------------------------------------------------------
# PART A — Raw-record level (enriched file)
# ---------------------------------------------------------------------------

message("Loading enriched file (this may take a minute) ...")
enriched <- read_csv(
  "data-raw/alldata/uncurated_raw_dedup_enriched.csv",
  guess_max = Inf,
  show_col_types = FALSE
)
message("Loaded: ", nrow(enriched), " rows × ", ncol(enriched), " cols")

# Reproduce Stage 4e clean subset
clean <- enriched |>
  filter(dedup_retained == TRUE, priority_kept == TRUE)
n_clean <- nrow(clean)
message("Clean subset (dedup_retained & priority_kept): ", n_clean, " rows")

# Flag genus-rank entries
clean <- clean |>
  mutate(is_genus_rank = flag_genus_rank(accepted_name, genus))

n_genus_clean     <- sum(clean$is_genus_rank, na.rm = TRUE)
pct_genus_clean   <- round(100 * n_genus_clean / n_clean, 2)
n_sp_genus_clean  <- n_distinct(clean$accepted_name[clean$is_genus_rank])
message("Genus-rank rows in clean subset: ", n_genus_clean,
        " (", pct_genus_clean, "%); ", n_sp_genus_clean, " distinct names")

# Breakdown by source
genus_by_source <- clean |>
  filter(is_genus_rank) |>
  count(source, name = "n_rows") |>
  arrange(desc(n_rows))

# Breakdown by resolution_status
genus_by_resolution <- clean |>
  filter(is_genus_rank) |>
  count(resolution_status, name = "n_rows") |>
  arrange(desc(n_rows))

# Breakdown by taxonomy_provenance
genus_by_provenance <- clean |>
  filter(is_genus_rank) |>
  count(taxonomy_provenance, name = "n_rows") |>
  arrange(desc(n_rows))

# How many flagged rows would reach aggregation today?
# Apply same conditions as stage4e Steps 2a/2b:
#   2a: drop NA effect_category
#   2b: drop acute-non-eligible (test_class == "acute" & acr_eligible != TRUE)
reaches_agg <- clean |>
  filter(
    !is.na(effect_category),
    !(test_class == "acute" & (is.na(acr_eligible) | acr_eligible != TRUE))
  )
n_reaches_agg_total  <- nrow(reaches_agg)
n_genus_reaches      <- sum(reaches_agg$is_genus_rank, na.rm = TRUE)
pct_genus_reaches    <- round(100 * n_genus_reaches / n_reaches_agg_total, 2)
message("Flagged genus-rank rows reaching aggregation today: ",
        n_genus_reaches, " / ", n_reaches_agg_total,
        " (", pct_genus_reaches, "%)")

# ---------------------------------------------------------------------------
# PART B — Output level (aggregated file)
# ---------------------------------------------------------------------------

message("Loading aggregated file ...")
agg <- read_csv(
  "data-raw/alldata/uncurated_raw_aggregated.csv",
  guess_max = Inf,
  show_col_types = FALSE
)
message("Loaded: ", nrow(agg), " rows × ", ncol(agg), " cols")

agg <- agg |>
  mutate(is_genus_rank = flag_genus_rank(accepted_name, genus))

n_agg_total       <- nrow(agg)
n_genus_agg       <- sum(agg$is_genus_rank, na.rm = TRUE)
pct_genus_agg     <- round(100 * n_genus_agg / n_agg_total, 2)
n_sp_genus_agg    <- n_distinct(agg$accepted_name[agg$is_genus_rank])
n_cas_genus_agg   <- n_distinct(agg$casnumber_grouped[agg$is_genus_rank])
message("Genus-rank rows in aggregated output: ", n_genus_agg,
        " (", pct_genus_agg, "%); ",
        n_sp_genus_agg, " distinct names; ",
        n_cas_genus_agg, " distinct CAS")

# Preview Stage 7 sufficiency impact: for each CAS × medium, how many
# distinct species are there now vs. after removing genus-rank entries?
species_counts <- agg |>
  group_by(casnumber_grouped, medium) |>
  summarise(
    n_sp_before = n_distinct(accepted_name),
    n_sp_after  = n_distinct(accepted_name[!is_genus_rank]),
    .groups = "drop"
  ) |>
  filter(n_sp_before != n_sp_after)

n_combinations_affected <- nrow(species_counts)
message("CAS × medium combinations whose species count changes: ",
        n_combinations_affected)

# Distinct chemicals affected (CAS level)
n_chemicals_affected <- n_distinct(species_counts$casnumber_grouped)
message("Distinct chemicals affected: ", n_chemicals_affected)

# ---------------------------------------------------------------------------
# Build candidates table (one row per distinct flagged accepted_name)
# ---------------------------------------------------------------------------

# Use clean subset (enriched) for modal resolution_status and provenance
# and one sample original_scientificname
candidates_enriched <- clean |>
  filter(is_genus_rank) |>
  group_by(accepted_name) |>
  summarise(
    genus                   = first(genus),
    n_rows_clean            = n(),
    resolution_status       = names(sort(table(resolution_status),
                                         decreasing = TRUE))[1],
    taxonomy_provenance     = names(sort(table(taxonomy_provenance),
                                         decreasing = TRUE))[1],
    sample_original_name    = first(original_scientificname),
    .groups = "drop"
  ) |>
  arrange(desc(n_rows_clean))

message("Candidate table: ", nrow(candidates_enriched),
        " distinct genus-rank accepted_names")

# ---------------------------------------------------------------------------
# Write outputs
# ---------------------------------------------------------------------------

write_csv(
  candidates_enriched,
  "data-raw/alldata/stage4e-genus-rank-candidates.csv"
)
message("Written: data-raw/alldata/stage4e-genus-rank-candidates.csv")

# Build markdown report
fmt_tbl <- function(df) {
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep    <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  rows   <- apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

report <- paste0(
  "# Stage 4e — Genus-rank accepted_name diagnostic\n\n",
  "Date: ", Sys.Date(), "\n\n",
  "Detection function: `flag_genus_rank()` — flags accepted_name values that\n",
  "resolve only to genus level (single-token names, names with sp./spp./cf./aff./nr.\n",
  "qualifiers, or names that exactly equal the resolved genus field).\n\n",
  "---\n\n",
  "## PART A — Raw-record level (enriched file)\n\n",
  "**Input:** `uncurated_raw_dedup_enriched.csv`\n\n",
  "| Metric | Count |\n",
  "| --- | --- |\n",
  "| Clean subset rows (dedup_retained & priority_kept) | ", format(n_clean, big.mark = ","), " |\n",
  "| Genus-rank rows in clean subset | ", format(n_genus_clean, big.mark = ","), " |\n",
  "| % of clean subset | ", pct_genus_clean, "% |\n",
  "| Distinct genus-rank accepted_name values | ", format(n_sp_genus_clean, big.mark = ","), " |\n\n",
  "### Breakdown by source\n\n",
  fmt_tbl(genus_by_source), "\n\n",
  "### Breakdown by resolution_status\n\n",
  fmt_tbl(genus_by_resolution), "\n\n",
  "### Breakdown by taxonomy_provenance\n\n",
  fmt_tbl(genus_by_provenance), "\n\n",
  "### Rows reaching aggregation (after Steps 2a/2b filters)\n\n",
  "Rows entering aggregation today (all species): ",
  format(n_reaches_agg_total, big.mark = ","), "\n\n",
  "| Metric | Count |\n",
  "| --- | --- |\n",
  "| Genus-rank rows reaching aggregation today | ",
  format(n_genus_reaches, big.mark = ","), " |\n",
  "| % of aggregation-entering rows | ", pct_genus_reaches, "% |\n\n",
  "---\n\n",
  "## PART B — Output level (aggregated file)\n\n",
  "**Input:** `uncurated_raw_aggregated.csv`\n\n",
  "| Metric | Count |\n",
  "| --- | --- |\n",
  "| Total output rows | ", format(n_agg_total, big.mark = ","), " |\n",
  "| Genus-rank output rows | ", format(n_genus_agg, big.mark = ","), " |\n",
  "| % of output | ", pct_genus_agg, "% |\n",
  "| Distinct genus-rank accepted_name values | ", format(n_sp_genus_agg, big.mark = ","), " |\n",
  "| Distinct casnumber_grouped affected | ", format(n_cas_genus_agg, big.mark = ","), " |\n",
  "| CAS × medium combinations with changed species count | ",
  format(n_combinations_affected, big.mark = ","), " |\n",
  "| Distinct chemicals affected (CAS level) | ",
  format(n_chemicals_affected, big.mark = ","), " |\n\n",
  "---\n\n",
  "## Output files\n\n",
  "- `scripts/stage4e-genus-rank-diagnostic.md` — this report\n",
  "- `data-raw/alldata/stage4e-genus-rank-candidates.csv` — ",
  nrow(candidates_enriched), " rows, one per distinct flagged accepted_name\n"
)

writeLines(report, "scripts/stage4e-genus-rank-diagnostic.md")
message("Written: scripts/stage4e-genus-rank-diagnostic.md")

message("Diagnostic complete.")
