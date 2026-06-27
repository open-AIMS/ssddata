# =============================================================================
# scripts/stage4d-part2-source-native-fallback.R
# =============================================================================
# Purpose:
#   Stage 4d Part 2 fixup -- U3 source-native taxonomy fallback. For the 148
#   species left `ambiguous_after_filter`, `unresolved`, or `api_error` by
#   the context-aware WoRMS/GBIF resolution (stage4d-context-aware-resolution.R),
#   populates any still-NA `resolved_*` hierarchy field from the species'
#   already-pooled source-native taxonomy (`source_taxonomy_*` columns,
#   carried over from Part 1.5 via Part 2's own Decision-P3 pooling step) and
#   tags every one of the 4,348 species with a `taxonomy_provenance` flag so
#   downstream stages can apply lower confidence to fallback-derived records.
#
#   Small standalone fixup. Does NOT touch Stage 4d Part 3 (majorgroup
#   derivation, not yet started) and does NOT fabricate an `accepted_name`,
#   `aphia_id`, `gbif_key`, or `rank_resolved` for unresolved species -- only
#   the taxonomic hierarchy fields are ever populated by the fallback.
#
# Decision implemented:
#   U3 (partial use with source-native fallback): for problem species, fill
#   each NA `resolved_<field>` from the corresponding non-NA
#   `source_taxonomy_<field>` (already pooled per Decision P3 -- single
#   source per species, never mixed). Fields that are NA in both stay NA.
#   Already-populated `resolved_<field>` values (e.g. a partially-resolved
#   `ambiguous_after_filter` candidate) are never overwritten.
#
# Inputs (read-only except species_resolution_v2.csv, which this script
# overwrites in place):
#   data-raw/alldata/species_resolution_v2.csv      (Part 2 output, 4,348 rows)
#   data-raw/alldata/species_source_taxonomy.csv    (Part 1.5 output, 6,198
#     rows -- loaded for audit/validation only; the fallback itself reads the
#     `source_taxonomy_*` columns already pooled into species_resolution_v2.csv
#     by Part 2, per Decision P3, so no re-pooling happens here)
#
# Outputs:
#   data-raw/alldata/species_resolution_v2.csv  (overwritten -- original
#     columns/order preserved, `taxonomy_provenance` appended at the end,
#     `resolved_*` filled for problem species only)
#   data-raw/alldata/species_resolution_v2_problem_species.csv  (new --
#     148-row focused audit file, before/after hierarchy comparison)
#   data-raw/alldata/stage4d-part2-fallback-report.md  (new -- short report)
#
# Idempotency:
#   If species_resolution_v2.csv already has a `taxonomy_provenance` column,
#   the script recomputes the fallback + provenance logic in memory and
#   compares the result to what's on disk. If identical, it reports that no
#   change is needed and exits WITHOUT writing any of the three outputs
#   (the fallback rule itself -- "never overwrite an already-populated
#   resolved_<field>" -- is a no-op on its own second application, so this
#   check is a belt-and-braces confirmation, not the only thing making the
#   script safe to re-run).
#
# Runs from WSL or Windows Positron. No DB connection required.
#
# CRITICAL PATH NOTE: the master CAS lookup lives at
# data-raw/cas_parent_lookup_all.csv (NOT
# data-raw/anztox/cas_parent_lookup_all.csv). Not used in this script --
# noted here only because the path error has recurred across this project.
# =============================================================================

library(dplyr)
library(readr)

v2_path <- "data-raw/alldata/species_resolution_v2.csv"
taxonomy_path <- "data-raw/alldata/species_source_taxonomy.csv"
problem_species_path <- "data-raw/alldata/species_resolution_v2_problem_species.csv"
report_path <- "data-raw/alldata/stage4d-part2-fallback-report.md"

# =============================================================================
# Step 2: load inputs
# =============================================================================

species_resolution_v2_raw <- read_csv(v2_path, show_col_types = FALSE)
species_source_taxonomy <- read_csv(taxonomy_path, show_col_types = FALSE)

expected_cols <- c(
  "scientificname", "sources", "n_rows", "is_genus_placeholder",
  "is_non_binomial", "taxonomy_source", "filter_level_used", "status",
  "accepted_name", "aphia_id", "gbif_key", "rank_resolved",
  "resolved_kingdom", "resolved_phylum", "resolved_class", "resolved_order",
  "resolved_family", "resolved_genus", "habitat",
  "source_taxonomy_kingdom", "source_taxonomy_phylum", "source_taxonomy_class",
  "source_taxonomy_order", "source_taxonomy_family", "source_taxonomy_genus",
  "hierarchy_match"
)
missing_cols <- setdiff(expected_cols, names(species_resolution_v2_raw))
if (length(missing_cols) > 0) {
  stop("species_resolution_v2.csv is missing expected columns: ",
       paste(missing_cols, collapse = ", "))
}
if (nrow(species_resolution_v2_raw) != 4348) {
  stop("Expected 4,348 rows in species_resolution_v2.csv, found ",
       nrow(species_resolution_v2_raw))
}
cat("Loaded species_resolution_v2.csv:", nrow(species_resolution_v2_raw), "rows,",
    ncol(species_resolution_v2_raw), "columns.\n")
cat("Loaded species_source_taxonomy.csv:", nrow(species_source_taxonomy), "rows",
    "(read for audit/validation only -- fallback uses the source_taxonomy_*",
    "columns already pooled into species_resolution_v2.csv by Part 2).\n")

hierarchy_fields <- c("kingdom", "phylum", "class", "order", "family", "genus")
resolved_cols <- paste0("resolved_", hierarchy_fields)
source_cols <- paste0("source_taxonomy_", hierarchy_fields)
problem_statuses <- c("ambiguous_after_filter", "unresolved", "api_error")
worms_statuses <- c("exact_filtered", "exact_unaccepted_filtered", "fuzzy_filtered", "genus_resolved")

# =============================================================================
# Fallback (Step 4) and provenance (Step 5) logic -- defined as functions so
# the idempotency check (below) and the real run share identical code.
# =============================================================================

apply_source_native_fallback <- function(df) {
  is_problem <- df$status %in% problem_statuses
  for (i in seq_along(hierarchy_fields)) {
    rc <- resolved_cols[i]
    sc <- source_cols[i]
    needs_fallback <- is_problem & is.na(df[[rc]]) & !is.na(df[[sc]])
    df[[rc]][needs_fallback] <- df[[sc]][needs_fallback]
  }
  df
}

compute_taxonomy_provenance <- function(df) {
  resolved_any <- Reduce(`|`, lapply(resolved_cols, function(cn) !is.na(df[[cn]])))
  case_when(
    df$status %in% worms_statuses ~ "worms_full",
    df$status == "gbif_resolved" ~ "gbif_full",
    df$status == "ambiguous_after_filter" ~ "ambiguous_partial",
    df$status %in% c("unresolved", "api_error") & resolved_any ~ "source_native_fallback",
    df$status %in% c("unresolved", "api_error") & !resolved_any ~ "no_taxonomy",
    TRUE ~ NA_character_
  )
}

# =============================================================================
# Idempotency check
# =============================================================================

if ("taxonomy_provenance" %in% names(species_resolution_v2_raw)) {
  recomputed_hierarchy <- apply_source_native_fallback(species_resolution_v2_raw)
  recomputed_provenance <- compute_taxonomy_provenance(recomputed_hierarchy)

  hierarchy_unchanged <- isTRUE(all.equal(
    as.data.frame(recomputed_hierarchy[resolved_cols]),
    as.data.frame(species_resolution_v2_raw[resolved_cols])
  ))
  existing_provenance <- species_resolution_v2_raw$taxonomy_provenance
  provenance_matches <- !anyNA(existing_provenance) &&
    all(existing_provenance == recomputed_provenance)

  if (hierarchy_unchanged && provenance_matches) {
    cat("\nspecies_resolution_v2.csv already has a taxonomy_provenance column",
        "consistent with a fresh fallback computation.\n")
    cat("No changes needed -- exiting without modifying any output file.\n")
    quit(save = "no", status = 0)
  }
  cat("\ntaxonomy_provenance column exists but does not match a fresh",
      "computation (hierarchy_unchanged =", hierarchy_unchanged,
      ", provenance_matches =", provenance_matches, ") -- recomputing and",
      "overwriting.\n")
}

# =============================================================================
# Step 3: identify problem species
# =============================================================================

is_problem <- species_resolution_v2_raw$status %in% problem_statuses
problem_status_counts <- species_resolution_v2_raw |>
  filter(is_problem) |>
  count(status, name = "n_species") |>
  arrange(status)
problem_row_counts <- species_resolution_v2_raw |>
  filter(is_problem) |>
  group_by(status) |>
  summarise(n_rows = sum(n_rows), .groups = "drop") |>
  arrange(status)

cat("\nProblem species (status %in% ambiguous_after_filter/unresolved/api_error):",
    sum(is_problem), "species,", sum(species_resolution_v2_raw$n_rows[is_problem]),
    "rows.\n")
print(problem_status_counts)
print(problem_row_counts)

# Snapshot pre-fallback resolved_* values for the audit file (Step 6b) before
# Step 4 modifies them in place.
pre_resolved <- species_resolution_v2_raw[resolved_cols]
names(pre_resolved) <- paste0("pre_", resolved_cols)

# =============================================================================
# Step 4: apply source-native fallback (U3)
# =============================================================================

species_resolution_v2 <- apply_source_native_fallback(species_resolution_v2_raw)

# Per-row count of hierarchy fields that were NA before and non-NA after --
# nonzero only for problem species, since apply_source_native_fallback() only
# ever touches rows with status %in% problem_statuses.
n_fields_recovered <- rowSums(is.na(pre_resolved) & !is.na(species_resolution_v2[resolved_cols]))
cat("\nProblem species with >=1 hierarchy field recovered from source-native",
    "fallback:", sum(n_fields_recovered[is_problem] > 0), "of", sum(is_problem), "\n")

# =============================================================================
# Step 5: add taxonomy_provenance column (applied to ALL 4,348 species)
# =============================================================================

species_resolution_v2$taxonomy_provenance <- compute_taxonomy_provenance(species_resolution_v2)

provenance_dist <- species_resolution_v2 |>
  count(taxonomy_provenance, name = "n_species") |>
  arrange(desc(n_species))
cat("\ntaxonomy_provenance distribution (all 4,348 species):\n")
print(provenance_dist)

# Known edge case: one exact_unaccepted_filtered row (Cryptomonas obovata) has
# a fully WoRMS-populated resolved_* hierarchy (aphia_id present) but a NA
# accepted_name -- a pre-existing Part 2 data quirk, out of scope to fix here.
# Classified "worms_full" by status (the structurally reliable signal: WoRMS-
# derived statuses always carry aphia_id, never gbif_key, verified across all
# 4,348 rows) rather than gated on accepted_name, which would otherwise leave
# this single row in none of the five provenance categories.
accepted_name_na_in_worms_full <- species_resolution_v2 |>
  filter(taxonomy_provenance == "worms_full", is.na(accepted_name) | accepted_name == "")
if (nrow(accepted_name_na_in_worms_full) > 0) {
  cat("\nNote:", nrow(accepted_name_na_in_worms_full), "worms_full row(s) have a",
      "NA accepted_name despite a fully WoRMS-derived hierarchy -- see report",
      "for detail (pre-existing Part 2 anomaly, not introduced by this fixup):\n")
  print(accepted_name_na_in_worms_full$scientificname)
}

# =============================================================================
# Step 6a: write augmented species_resolution_v2.csv
# =============================================================================

write_csv(species_resolution_v2, v2_path, na = "NA")
cat("\nWrote", nrow(species_resolution_v2), "rows to", v2_path, "\n")

# =============================================================================
# Step 6b: species_resolution_v2_problem_species.csv
# =============================================================================

# Audit-only working tibble (post-fallback values + pre-fallback snapshot +
# per-row recovery count) -- never written as species_resolution_v2.csv
# itself, only used to build the two report/audit artefacts below. Built from
# species_resolution_v2 (unreordered since Step 4), so bind_cols() and the
# n_fields_recovered vector both stay row-aligned.
species_resolution_v2_audit <- species_resolution_v2 |>
  bind_cols(pre_resolved) |>
  mutate(n_fields_recovered = n_fields_recovered)

problem_species <- species_resolution_v2_audit |>
  filter(status %in% problem_statuses) |>
  select(
    scientificname, sources, n_rows, status, taxonomy_provenance,
    pre_resolved_kingdom, resolved_kingdom,
    pre_resolved_phylum, resolved_phylum,
    pre_resolved_class, resolved_class,
    pre_resolved_order, resolved_order,
    pre_resolved_family, resolved_family,
    pre_resolved_genus, resolved_genus,
    starts_with("source_taxonomy_")
  ) |>
  arrange(status, desc(n_rows))

write_csv(problem_species, problem_species_path, na = "NA")
cat("Wrote", nrow(problem_species), "rows to", problem_species_path, "\n")

# =============================================================================
# Step 6c: short report
# =============================================================================

md_table <- function(df) {
  df <- as.data.frame(df)
  df[] <- lapply(df, function(col) {
    col <- as.character(col)
    col[is.na(col)] <- "NA"
    col
  })
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|")
  rows <- apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

lines <- character(0)
add <- function(...) lines <<- c(lines, ...)

add(
  "# Stage 4d Part 2 Fixup -- U3 Source-Native Taxonomy Fallback Report",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  ""
)

# --- Section 1: problem species summary ---
add("## 1. Problem species summary", "")
add(paste0(
  "- Total problem species (status %in% c(\"ambiguous_after_filter\", ",
  "\"unresolved\", \"api_error\")): ", sum(is_problem), " species, ",
  format(sum(species_resolution_v2$n_rows[is_problem]), big.mark = ","), " rows"
))
add("", "By status:", "")
add(md_table(
  problem_status_counts |>
    left_join(problem_row_counts, by = "status")
))
add("")

# --- Section 2: fallback results ---
add("## 2. Fallback results", "")
add(paste0(
  "- Of the ", sum(is_problem), " problem species, ",
  sum(n_fields_recovered[is_problem] > 0),
  " had at least one hierarchy field recovered from source-native taxonomy."
))
add("", "`taxonomy_provenance` distribution (all 4,348 species):", "")
add(md_table(provenance_dist))
add("", "`taxonomy_provenance` distribution restricted to the 148 problem species:", "")
add(md_table(
  species_resolution_v2 |>
    filter(status %in% problem_statuses) |>
    count(taxonomy_provenance, name = "n_species") |>
    arrange(desc(n_species))
))

class_before <- sum(!is.na(species_resolution_v2_raw$resolved_class))
class_after <- sum(!is.na(species_resolution_v2$resolved_class))
class_after_problem <- sum(!is.na(species_resolution_v2$resolved_class[is_problem]))
add(
  "",
  paste0(
    "- Class-level coverage among the 148 problem species: ", class_after_problem,
    " of 148 now have a non-NA `resolved_class` (was 0 of 148 before this fixup, ",
    "since all problem species entered Part 2 with fully NA `resolved_*` fields)."
  ),
  paste0(
    "- Dataset-wide class-level coverage: ", class_before, " -> ", class_after,
    " of 4,348 species (", sprintf("%.1f%%", 100 * class_before / 4348), " -> ",
    sprintf("%.1f%%", 100 * class_after / 4348), ")."
  ),
  ""
)

if (nrow(accepted_name_na_in_worms_full) > 0) {
  add(paste0(
    "**Note:** ", nrow(accepted_name_na_in_worms_full),
    " `exact_unaccepted_filtered` row(s) (`",
    paste(accepted_name_na_in_worms_full$scientificname, collapse = "`, `"),
    "`) have a NA `accepted_name` despite a fully WoRMS-derived `resolved_*` ",
    "hierarchy (their `aphia_id` is populated) -- a pre-existing Part 2 data ",
    "quirk, not introduced here. Classified `worms_full` on the structural ",
    "signal that WoRMS-derived statuses always carry `aphia_id` (verified ",
    "across all 4,348 rows), rather than gating on `accepted_name`, which ",
    "would otherwise leave this row outside all five provenance categories."
  ), "")
}

# --- Section 3: no_taxonomy residual ---
no_taxonomy <- species_resolution_v2 |>
  filter(taxonomy_provenance == "no_taxonomy") |>
  arrange(desc(n_rows))

add("## 3. The `no_taxonomy` residual", "")
add(paste0(
  "- ", nrow(no_taxonomy), " species (",
  format(sum(no_taxonomy$n_rows), big.mark = ","),
  " rows) have NO usable taxonomy from WoRMS, GBIF, OR source-native ",
  "taxonomy. These are the hard-exclude candidates for Stage 4d Part 3, or ",
  "a manual-review queue if time allows."
), "")
if (nrow(no_taxonomy) > 0) {
  add(md_table(no_taxonomy |> select(scientificname, sources, n_rows, status)))
} else {
  add("(none)")
}
add("")

# --- Section 4: sample successful fallback cases ---
successful <- species_resolution_v2_audit |>
  filter(status %in% problem_statuses, n_fields_recovered > 0) |>
  arrange(desc(n_rows))

n_sample <- min(20, nrow(successful))
sample_cases <- successful |>
  slice_head(n = n_sample) |>
  select(
    scientificname, status, n_rows,
    source_taxonomy_kingdom, source_taxonomy_phylum, source_taxonomy_class,
    source_taxonomy_order, source_taxonomy_family, source_taxonomy_genus,
    resolved_kingdom, resolved_phylum, resolved_class, resolved_order,
    resolved_family, resolved_genus
  )

add(paste0(
  "## 4. Sample of ", n_sample,
  " successful fallback cases (top ", n_sample, " by n_rows, not a random ",
  "sample -- deterministic so this report is stable across re-runs)"
), "")
add(md_table(sample_cases))
add("")

# --- Section 5: recommendation for Stage 4d Part 3 ---
add("## 5. Recommendation for Stage 4d Part 3", "")
threshold_met <- (class_after / 4348) >= 0.95
add(paste0(
  "- Dataset-wide class-level coverage after the U3 fallback is ",
  sprintf("%.1f%%", 100 * class_after / 4348), " (", class_after, " of 4,348 ",
  "species), ", if (threshold_met) "meeting" else "still short of",
  " the 95% threshold suggested in the Part 2 report."
))
add(paste0(
  "- Genuine residual: ", nrow(no_taxonomy), " species (",
  format(sum(no_taxonomy$n_rows), big.mark = ","), " rows, ",
  sprintf("%.2f%%", 100 * sum(no_taxonomy$n_rows) / sum(species_resolution_v2$n_rows)),
  " of the final clean rows) have `taxonomy_provenance == \"no_taxonomy\"` -- ",
  "no usable hierarchy from any source. Recommend Part 3 hard-excludes these ",
  "from majorgroup derivation (and flags them for the SSD aggregation stage ",
  "to drop, since a record with no taxonomic hierarchy cannot be assigned a ",
  "majorgroup), or queues them for manual domain-expert review given the ",
  "small size."
))
add(paste0(
  "- The remaining ", sum(is_problem) - nrow(no_taxonomy),
  " problem species now carry at least a partial hierarchy (",
  sum(species_resolution_v2$taxonomy_provenance[is_problem] == "ambiguous_partial"),
  " `ambiguous_partial`, ",
  sum(species_resolution_v2$taxonomy_provenance[is_problem] == "source_native_fallback"),
  " `source_native_fallback`) and can be used in Part 3 with the ",
  "`taxonomy_provenance` flag carried forward as a lower-confidence marker."
))
add("")

writeLines(lines, report_path)
cat("\nWrote report to", report_path, "\n")

cat("\nDone.\n")
