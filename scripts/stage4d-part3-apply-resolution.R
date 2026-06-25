# =============================================================================
# scripts/stage4d-part3-apply-resolution.R
# =============================================================================
# Purpose:
#   Stage 4d Part 3 -- apply the resolved species names, taxonomic hierarchy,
#   and synonym unification back to uncurated_raw_dedup.csv. Derives
#   `majorgroup` directly from `resolved_class` (no controlled vocabulary
#   lookup). Hard-excludes the 12 no_taxonomy residual species (~28 rows in
#   the full dataset). Produces the final taxonomy-enriched dedup file ready
#   for Stage 4e aggregation.
#
# Decisions implemented:
#   - Synonym unification: 254 groups, ~130,124 rows in the final clean subset
#     (from species_resolution_v2.csv). Raw `scientificname` is kept in the
#     output for audit; `accepted_name` is the new canonical column for Stage
#     4e aggregation.
#   - majorgroup = resolved_class directly (no controlled vocabulary lookup).
#     This is consistent with wqbench's filter(n_distinct(class) >= 4)
#     convention and is simpler and more reproducible than a manual mapping
#     to Warne et al. Table 5 categories. Acceptable deviation because this
#     dataset is for methodology testing, not official guideline values.
#   - Hard-exclusion: 12 species with taxonomy_provenance == "no_taxonomy"
#     (placeholder/category labels and unresolvable misspellings from anztox).
#     These cannot be assigned a majorgroup and cannot contribute to SSD
#     aggregation. Excluded rows are written to an audit CSV.
#
# Inputs (all read-only):
#   data-raw/alldata/uncurated_raw_dedup.csv          (449,888 rows x 21 cols;
#     UNTRACKED per .gitignore -- large file. readr default ok, no sparse cols)
#   data-raw/alldata/species_resolution_v2.csv        (4,348 rows x 30 cols;
#     TRACKED. MUST use guess_max = Inf -- has sparse audit columns past row
#     1000 that default read_csv() would silently nullify. See CLAUDE.md S5.)
#   data-raw/alldata/species_synonym_audit.csv        (tracked; synonym groups
#     for validation / spot-check only -- not used in the join itself)
#
# Outputs:
#   data-raw/alldata/uncurated_raw_dedup_enriched.csv  (UNTRACKED -- large
#     file in .gitignore. ~449,860 rows x 33 cols; Stage 4e reads this.)
#   data-raw/alldata/stage4d-part3-enrichment-report.md  (TRACKED -- audit
#     report of enrichment, synonym unification, and exclusion outcomes)
#   data-raw/alldata/stage4d-part3-excluded-rows.csv  (TRACKED -- audit trail
#     of hard-excluded rows from the 12 no_taxonomy species; small file)
#
# Output column order (21 original + 12 new):
#   source, native_cas, casnumber_grouped, chemicalname_grouped,
#   scientificname, medium, test_class, statistic_type, effect_category,
#   duration_hours, life_stage, conc_value, conc_unit, acr_eligible,
#   study_reference, source_id, acr_applied, within_source_duplicate,
#   dedup_retained, priority_kept, dedup_note,
#   original_scientificname, accepted_name, synonym_unified,
#   kingdom, phylum, class, order_taxon, family, genus,
#   majorgroup, taxonomy_provenance, resolution_status
#
# Runs from WSL or Windows Positron. No DB connection required.
#
# CRITICAL PATH NOTE: the master CAS lookup lives at
# data-raw/cas_parent_lookup_all.csv (NOT
# data-raw/anztox/cas_parent_lookup_all.csv). Not used in this script --
# noted here only because the path error has recurred across this project.
#
# read_csv() trap (CLAUDE.md Section 5): species_resolution_v2.csv has two
# sparse audit columns (manual_corrected_query_name, manual_correction_note)
# that are NA for all but 3 of 4,348 rows, all past row 1000. Default
# read_csv() would infer `logical` for these and silently convert the real
# string values to NA. Always use guess_max = Inf when reading this file.
# =============================================================================

library(dplyr)
library(readr)
library(stringr)

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------

dedup_path       <- "data-raw/alldata/uncurated_raw_dedup.csv"
v2_path          <- "data-raw/alldata/species_resolution_v2.csv"
synonym_path     <- "data-raw/alldata/species_synonym_audit.csv"
enriched_path    <- "data-raw/alldata/uncurated_raw_dedup_enriched.csv"
excluded_path    <- "data-raw/alldata/stage4d-part3-excluded-rows.csv"
report_path      <- "data-raw/alldata/stage4d-part3-enrichment-report.md"

# =============================================================================
# Step 2 -- Load inputs and validate
# =============================================================================

message("Loading uncurated_raw_dedup.csv ...")
dedup <- read_csv(dedup_path, show_col_types = FALSE)

message("Loading species_resolution_v2.csv (guess_max = Inf) ...")
# guess_max = Inf required: two sparse audit columns (manual_corrected_query_name,
# manual_correction_note) are NA for all but 3 rows, all past row 1000.
# Default read_csv() would infer logical for these and silently convert the
# real string values to NA. See CLAUDE.md Section 5 and the script header.
v2 <- read_csv(v2_path, show_col_types = FALSE, guess_max = Inf)

message("Loading species_synonym_audit.csv ...")
synonym_audit <- read_csv(synonym_path, show_col_types = FALSE)

# --- Validate uncurated_raw_dedup ---
expected_dedup_cols <- c(
  "source", "native_cas", "casnumber_grouped", "chemicalname_grouped",
  "scientificname", "medium", "test_class", "statistic_type", "effect_category",
  "duration_hours", "life_stage", "conc_value", "conc_unit", "acr_eligible",
  "study_reference", "source_id", "acr_applied", "within_source_duplicate",
  "dedup_retained", "priority_kept", "dedup_note"
)

if (!all(expected_dedup_cols %in% names(dedup))) {
  missing <- setdiff(expected_dedup_cols, names(dedup))
  stop("uncurated_raw_dedup.csv is missing expected columns: ",
       paste(missing, collapse = ", "))
}
if (nrow(dedup) != 449888) {
  stop("uncurated_raw_dedup.csv has ", nrow(dedup),
       " rows -- expected 449,888. Investigate before proceeding.")
}
if (ncol(dedup) != 21) {
  stop("uncurated_raw_dedup.csv has ", ncol(dedup),
       " columns -- expected 21. Investigate before proceeding.")
}
message("  uncurated_raw_dedup.csv: ", nrow(dedup), " rows x ", ncol(dedup), " cols [OK]")

# --- Validate species_resolution_v2 ---
expected_v2_cols <- c(
  "scientificname", "accepted_name", "taxonomy_provenance", "status",
  "resolved_kingdom", "resolved_phylum", "resolved_class", "resolved_order",
  "resolved_family", "resolved_genus",
  "manual_correction_applied", "manual_corrected_query_name"
)
if (!all(expected_v2_cols %in% names(v2))) {
  missing <- setdiff(expected_v2_cols, names(v2))
  stop("species_resolution_v2.csv is missing expected columns: ",
       paste(missing, collapse = ", "))
}
if (nrow(v2) != 4348) {
  stop("species_resolution_v2.csv has ", nrow(v2),
       " rows -- expected 4,348. Investigate before proceeding.")
}
expected_provenance <- c(
  "worms_full", "gbif_full", "ambiguous_partial",
  "source_native_fallback", "manual_genus_fallback", "no_taxonomy"
)
actual_provenance <- unique(v2$taxonomy_provenance)
if (!setequal(actual_provenance, expected_provenance)) {
  unexpected <- setdiff(actual_provenance, expected_provenance)
  missing_prov <- setdiff(expected_provenance, actual_provenance)
  msg <- character(0)
  if (length(unexpected) > 0)
    msg <- c(msg, paste("Unexpected values:", paste(unexpected, collapse = ", ")))
  if (length(missing_prov) > 0)
    msg <- c(msg, paste("Missing values:", paste(missing_prov, collapse = ", ")))
  stop("taxonomy_provenance does not have exactly the expected six values. ",
       paste(msg, collapse = "; "))
}
message("  species_resolution_v2.csv: ", nrow(v2), " rows [OK]")
message("  taxonomy_provenance: all 6 expected values present [OK]")

# =============================================================================
# Step 3 -- Build species-level lookup for joining
# =============================================================================

# accepted_name_final logic:
#   1. If accepted_name is non-NA, use it (covers fully-resolved and
#      unaccepted-but-redirected species).
#   2. Else keep the raw scientificname as a placeholder -- no species-level
#      identity fabricated for unresolved/no_taxonomy/ambiguous_partial cases.
lookup <- v2 |>
  select(
    scientificname,
    accepted_name,
    resolved_kingdom, resolved_phylum, resolved_class, resolved_order,
    resolved_family, resolved_genus,
    taxonomy_provenance,
    status,
    manual_correction_applied
  ) |>
  mutate(
    accepted_name_final = if_else(
      !is.na(accepted_name),
      accepted_name,
      scientificname   # placeholder: raw name used where no accepted name exists
    ),
    is_excluded = taxonomy_provenance == "no_taxonomy"
  )

# Validate lookup
if (nrow(lookup) != 4348) {
  stop("Lookup has ", nrow(lookup), " rows -- expected 4,348.")
}
n_excluded <- sum(lookup$is_excluded)
if (n_excluded != 12) {
  stop("Expected 12 no_taxonomy species to exclude, found ", n_excluded,
       ". Check species_resolution_v2.csv.")
}
if (any(is.na(lookup$accepted_name_final))) {
  stop("accepted_name_final is NA for some rows -- logic error in fallback.")
}
message("  Lookup built: ", nrow(lookup), " rows, ", n_excluded,
        " hard-exclude species [OK]")

# =============================================================================
# Step 4 -- Apply synonym unification and Step 5 -- Join taxonomic hierarchy
# =============================================================================

message("Joining resolution lookup to dedup file ...")
working <- dedup |>
  left_join(
    lookup |> select(
      scientificname, accepted_name_final, is_excluded,
      resolved_kingdom, resolved_phylum, resolved_class, resolved_order,
      resolved_family, resolved_genus,
      taxonomy_provenance, status, manual_correction_applied
    ),
    by = "scientificname"
  ) |>
  mutate(
    # Synonym unification (Step 4)
    original_scientificname = scientificname,
    accepted_name           = accepted_name_final,
    synonym_unified         = (accepted_name_final != scientificname),
    # Taxonomic hierarchy (Step 5) -- rename order to avoid clash with base R
    kingdom          = resolved_kingdom,
    phylum           = resolved_phylum,
    class            = resolved_class,
    order_taxon      = resolved_order,
    family           = resolved_family,
    genus            = resolved_genus,
    resolution_status = status
  )

# Check join completeness: all dedup rows should have matched a lookup entry
n_unmatched <- sum(is.na(working$taxonomy_provenance))
if (n_unmatched > 0) {
  unmatched_names <- working |>
    filter(is.na(taxonomy_provenance)) |>
    distinct(scientificname) |>
    pull(scientificname)
  stop(n_unmatched, " rows in dedup did not match any entry in the resolution ",
       "lookup. Unmatched scientificnames (first 20): ",
       paste(head(unmatched_names, 20), collapse = ", "))
}

# Synonym unification summary
n_synonym_rows <- sum(working$synonym_unified, na.rm = TRUE)
message("  Synonym unification: ", format(n_synonym_rows, big.mark = ","),
        " rows unified (expected ~130,124)")

# Sample of top synonym groups for reporting
top_synonym_sample <- working |>
  filter(synonym_unified) |>
  count(original_scientificname, accepted_name, name = "n") |>
  arrange(desc(n)) |>
  slice_head(n = 10)

message("  Top synonym pairings (by row count):")
for (i in seq_len(nrow(top_synonym_sample))) {
  message("    ", top_synonym_sample$original_scientificname[i], " -> ",
          top_synonym_sample$accepted_name[i],
          " (", format(top_synonym_sample$n[i], big.mark = ","), " rows)")
}

# Taxonomy coverage (before exclusion)
n_na_kingdom <- sum(is.na(working$kingdom))
n_na_phylum  <- sum(is.na(working$phylum))
n_na_class   <- sum(is.na(working$class))
pct_class    <- round(100 * (1 - n_na_class / nrow(working)), 2)
message("  Class-level coverage (pre-exclusion): ",
        format(nrow(working) - n_na_class, big.mark = ","),
        " / ", format(nrow(working), big.mark = ","),
        " rows (", pct_class, "%)")

# =============================================================================
# Step 6 -- Derive majorgroup
# =============================================================================

# majorgroup = resolved_class directly. No controlled vocabulary lookup.
# This is consistent with wqbench's own filter(n_distinct(class) >= 4)
# convention and avoids a hand-coded mapping that would be harder to audit
# and less reproducible. Acceptable because this dataset targets methodology
# testing, not official ANZG guideline values.
working <- working |>
  mutate(majorgroup = class)

majorgroup_dist <- working |>
  filter(!is.na(majorgroup)) |>
  count(majorgroup, name = "n_rows") |>
  arrange(desc(n_rows))

message("  Distinct majorgroup (class) values (pre-exclusion): ",
        nrow(majorgroup_dist))

# =============================================================================
# Step 7 -- Hard-exclude no_taxonomy species
# =============================================================================

excluded_rows <- working |>
  filter(is_excluded)

n_excluded_rows <- nrow(excluded_rows)
excluded_species <- excluded_rows |>
  count(original_scientificname, name = "n_rows") |>
  arrange(desc(n_rows))

message("  Hard-excluding ", n_excluded_rows, " rows from ", nrow(excluded_species),
        " no_taxonomy species")

# Sanity check: should be ~28 rows from 12 species (based on n_rows totals in
# the resolution file). Accept a small margin for rows appearing across clean
# and non-clean subsets of the dedup file.
if (nrow(excluded_species) != 12) {
  stop("Expected 12 no_taxonomy species to be excluded, but found ",
       nrow(excluded_species), " distinct scientificnames. Investigate.")
}
if (n_excluded_rows > 100) {
  stop("Hard-exclusion removed ", n_excluded_rows, " rows -- unexpectedly large. ",
       "Expected approximately 28-33. Investigate before proceeding.")
}

# Write audit file of excluded rows (all original + joined columns)
excluded_out <- excluded_rows |>
  select(-accepted_name_final, -is_excluded)  # internal working columns

write_csv(excluded_out, excluded_path)
message("  Excluded rows written to: ", excluded_path)

# Drop excluded rows and clean up working columns
enriched <- working |>
  filter(!is_excluded) |>
  select(
    # Original 21 columns in original order
    source, native_cas, casnumber_grouped, chemicalname_grouped,
    scientificname, medium, test_class, statistic_type, effect_category,
    duration_hours, life_stage, conc_value, conc_unit, acr_eligible,
    study_reference, source_id, acr_applied, within_source_duplicate,
    dedup_retained, priority_kept, dedup_note,
    # New columns from this script
    original_scientificname, accepted_name, synonym_unified,
    kingdom, phylum, class, order_taxon, family, genus,
    majorgroup, taxonomy_provenance, resolution_status
  )

expected_enriched_rows <- nrow(dedup) - n_excluded_rows
if (nrow(enriched) != expected_enriched_rows) {
  stop("Enriched file has ", nrow(enriched), " rows -- expected ",
       expected_enriched_rows, ". Something went wrong during filtering.")
}
message("  Enriched dataset: ", format(nrow(enriched), big.mark = ","),
        " rows x ", ncol(enriched), " cols")

# =============================================================================
# Step 8 -- Write the enriched dedup file
# =============================================================================

message("Writing enriched dedup file ...")
write_csv(enriched, enriched_path)
file_size_mb <- round(file.size(enriched_path) / 1024^2, 1)
message("  Written: ", enriched_path, " (", file_size_mb, " MB)")

# =============================================================================
# Step 9 -- Sanity checks
# =============================================================================

message("Running sanity checks ...")

# Confirm no no_taxonomy rows remain
if (any(enriched$taxonomy_provenance == "no_taxonomy")) {
  stop("SANITY FAIL: no_taxonomy rows found in enriched file -- should all be excluded.")
}
message("  No no_taxonomy rows in enriched file [OK]")

n_raw_species    <- n_distinct(enriched$original_scientificname)
n_accepted_species <- n_distinct(enriched$accepted_name)
message("  Distinct original scientificnames: ", format(n_raw_species, big.mark = ","))
message("  Distinct accepted_names: ", format(n_accepted_species, big.mark = ","),
        " (reduction of ", format(n_raw_species - n_accepted_species, big.mark = ","),
        " from synonym unification)")

# Per-source synonym unification
synonym_by_source <- enriched |>
  group_by(source) |>
  summarise(
    n_rows = n(),
    n_synonym_unified = sum(synonym_unified, na.rm = TRUE),
    .groups = "drop"
  )

# Final clean subset
final_clean <- enriched |>
  filter(dedup_retained == TRUE, priority_kept == TRUE)
n_final_clean <- nrow(final_clean)
message("  Final clean subset (dedup_retained & priority_kept): ",
        format(n_final_clean, big.mark = ","), " rows")

# Top 20 majorgroup values in final clean subset
top_majorgroup <- final_clean |>
  filter(!is.na(majorgroup)) |>
  count(majorgroup, name = "n_rows") |>
  arrange(desc(n_rows)) |>
  slice_head(n = 20)

# Taxonomy provenance in final clean subset by source
provenance_clean <- final_clean |>
  count(source, taxonomy_provenance, name = "n_rows") |>
  arrange(source, desc(n_rows))

# =============================================================================
# Step 10 -- Write report
# =============================================================================

message("Writing report ...")

# --- helper for markdown tables ---
md_table <- function(df) {
  col_widths <- pmax(nchar(names(df)), sapply(df, function(x) max(nchar(as.character(x)), na.rm = TRUE)))
  header <- paste("|", paste(str_pad(names(df), col_widths, "right"), collapse = " | "), "|")
  sep    <- paste("|", paste(strrep("-", col_widths), collapse = "|"), "|")
  rows   <- apply(df, 1, function(r)
    paste("|", paste(str_pad(r, col_widths, "right"), collapse = " | "), "|")
  )
  paste(c(header, sep, rows), collapse = "\n")
}

# Provenance distribution (all 4,348 species from v2)
prov_dist <- v2 |>
  count(taxonomy_provenance, name = "n_species") |>
  arrange(desc(n_species))

# Coverage by field (enriched, full dataset)
coverage <- tibble(
  field       = c("kingdom", "phylum", "class", "order_taxon", "family", "genus"),
  n_non_na    = c(
    sum(!is.na(enriched$kingdom)),
    sum(!is.na(enriched$phylum)),
    sum(!is.na(enriched$class)),
    sum(!is.na(enriched$order_taxon)),
    sum(!is.na(enriched$family)),
    sum(!is.na(enriched$genus))
  ),
  n_na        = c(
    sum(is.na(enriched$kingdom)),
    sum(is.na(enriched$phylum)),
    sum(is.na(enriched$class)),
    sum(is.na(enriched$order_taxon)),
    sum(is.na(enriched$family)),
    sum(is.na(enriched$genus))
  )
) |>
  mutate(
    pct_coverage = paste0(round(100 * n_non_na / nrow(enriched), 2), "%")
  )

# Top 20 synonym groups by row count in enriched file
top_synonyms <- enriched |>
  filter(synonym_unified) |>
  count(accepted_name, name = "n_rows") |>
  arrange(desc(n_rows)) |>
  slice_head(n = 20)

# Spot-check: top 5 synonym groups from synonym_audit
top5_accepted <- top_synonyms$accepted_name[1:5]
synonym_spot <- synonym_audit |>
  filter(accepted_name %in% top5_accepted) |>
  group_by(accepted_name) |>
  summarise(
    n_raw_names = n_distinct(raw_name),
    raw_names   = paste(sort(unique(raw_name)), collapse = "; "),
    .groups = "drop"
  )

# Majorgroup distribution in enriched file (all rows)
majorgroup_full <- enriched |>
  filter(!is.na(majorgroup)) |>
  count(majorgroup, name = "n_rows") |>
  arrange(desc(n_rows))

# Per-source breakdown of final clean subset
source_clean <- final_clean |>
  count(source, name = "n_rows") |>
  arrange(desc(n_rows))

# NA counts in final clean subset (key aggregation fields)
na_statistic <- sum(is.na(final_clean$statistic_type))
na_effect    <- sum(is.na(final_clean$effect_category))
na_duration  <- sum(is.na(final_clean$duration_hours))

lines <- c(
  paste0("# Stage 4d Part 3 -- Taxonomy Enrichment Report\n"),
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n"),
  "## 1. Input summary\n",
  paste0("- `uncurated_raw_dedup.csv`: ", format(nrow(dedup), big.mark = ","),
         " rows x ", ncol(dedup), " columns"),
  paste0("- `species_resolution_v2.csv`: ", nrow(v2),
         " species (4,348 unique scientificnames from the final clean subset)"),
  "\n`taxonomy_provenance` distribution across all 4,348 species:\n",
  md_table(prov_dist),

  "\n## 2. Synonym unification result\n",
  paste0("- Total rows with `synonym_unified == TRUE`: ",
         format(n_synonym_rows, big.mark = ",")),
  "\nTop 20 synonym groups by row count (unified):\n",
  md_table(top_synonyms |> rename("accepted_name (unified)" = accepted_name)),

  "\nSpot-check -- top 5 accepted names vs `species_synonym_audit.csv`:\n",
  md_table(synonym_spot),

  "\n## 3. Taxonomic hierarchy join result\n",
  "\nCoverage by field (full enriched dataset, ", format(nrow(enriched), big.mark = ","),
  " rows):\n",
  md_table(coverage),

  "\n## 4. Majorgroup distribution\n",
  "\nDistinct `majorgroup` (= `class`) values in the enriched file, all rows:\n",
  md_table(majorgroup_full),

  "\n## 5. Hard exclusions\n",
  paste0("- ", nrow(excluded_species), " no_taxonomy species excluded, ",
         n_excluded_rows, " rows removed from the enriched file.\n"),
  "\nExcluded species (all from anztox -- placeholder labels and ",
  "unresolvable misspellings):\n",
  md_table(excluded_species |> rename(scientificname = original_scientificname)),

  "\nThese match the `no_taxonomy` residual from the manual-corrections ",
  "fixup report (`stage4d-part2-manual-corrections-report.md`): 12 species ",
  "after the 3 manual corrections reduced the original 15-species list.\n",

  "\n## 6. Final clean subset summary\n",
  paste0("Filter: `dedup_retained == TRUE & priority_kept == TRUE`\n"),
  paste0("- Total rows: ", format(n_final_clean, big.mark = ",")),
  paste0("- Distinct species (`accepted_name`): ",
         format(n_distinct(final_clean$accepted_name), big.mark = ",")),
  "\nPer-source breakdown:\n",
  md_table(source_clean),
  "\nTop 20 majorgroup values in the final clean subset:\n",
  md_table(top_majorgroup),
  "\nTaxonomy provenance in the final clean subset by source:\n",
  md_table(provenance_clean),

  "\n## 7. Readiness for Stage 4e\n",
  paste0("- Stage 4e reads: `", enriched_path, "` (",
         format(nrow(enriched), big.mark = ","), " rows x ",
         ncol(enriched), " cols, ", file_size_mb, " MB)"),
  "- Aggregation grouping key for Stage 4e (Section 3.4.4, Warne et al. 2025):",
  "  `casnumber_grouped x accepted_name x medium x effect_category x",
  "   statistic_type x duration_hours x life_stage (where non-NA)`",
  "\nKnown data quality issues for Stage 4e planning:\n",
  paste0("- Rows with NA `statistic_type` (final clean subset): ",
         format(na_statistic, big.mark = ",")),
  paste0("- Rows with NA `effect_category` (final clean subset): ",
         format(na_effect, big.mark = ",")),
  paste0("- Rows with NA `duration_hours` (final clean subset): ",
         format(na_duration, big.mark = ",")),
  "- Rows with NA in any aggregation key field will be excluded from the ",
  "  geomean step or result in singleton groups -- Stage 4e should decide ",
  "  how to handle these (drop vs. retain as-is).",
  "- `conc_unit` is mg/L for wqbench rows and ug/L for anztox/envirotox. ",
  "  The wqbench mg/L -> ug/L conversion (x1000) is applied in Stage 4e ",
  "  before aggregation.",
  "- Acute records with `acr_eligible == FALSE` (NOECs, LOECs etc.) will be ",
  "  dropped at Stage 4e -- they cannot be ACR-converted per Warne et al. ",
  "  2025 Section 3.4.2.2.",
  paste0("- ", format(n_synonym_rows, big.mark = ","),
         " rows had `scientificname` replaced by `accepted_name` via synonym ",
         "unification. Stage 4e MUST aggregate on `accepted_name`, not the ",
         "original `scientificname` column.")
)

writeLines(paste(lines, collapse = "\n"), report_path)
message("  Report written to: ", report_path)
message("Done.")
