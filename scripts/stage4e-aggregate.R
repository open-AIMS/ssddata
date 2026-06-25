# Stage 4e — Aggregate uncurated sources to one value per species × chemical × medium
#
# Implements Section 3.4.4 of Warne et al. 2025 (ANZG technical guidance).
# Input:  data-raw/alldata/uncurated_raw_dedup_enriched.csv  (~228 MB, untracked)
# Output: data-raw/alldata/uncurated_raw_aggregated.csv      (untracked)
#         data-raw/alldata/stage4e-aggregation-report.md     (tracked)
#
# Can be run from WSL or Windows Positron — no DB connection required.
# Read with guess_max = Inf per project-wide convention (CLAUDE.md Section 5).

library(readr)
library(dplyr)

# ---------------------------------------------------------------------------
# Step 0 — Load and prepare
# ---------------------------------------------------------------------------

message("Loading enriched file (this may take a minute) ...")
enriched <- read_csv(
  "data-raw/alldata/uncurated_raw_dedup_enriched.csv",
  guess_max = Inf,
  show_col_types = FALSE
)
message("Loaded: ", nrow(enriched), " rows × ", ncol(enriched), " cols")

# Filter to the usable subset
clean <- enriched |>
  filter(dedup_retained == TRUE, priority_kept == TRUE)
n_clean <- nrow(clean)
message("After dedup_retained & priority_kept filter: ", n_clean, " rows")
stopifnot(n_clean > 380000)  # expect ~381,382

# Coerce literal "Not stated" in majorgroup / class to NA (4 rows)
n_not_stated_majorgroup <- sum(clean$majorgroup == "Not stated", na.rm = TRUE)
n_not_stated_class      <- sum(clean$class      == "Not stated", na.rm = TRUE)
clean <- clean |>
  mutate(
    majorgroup = if_else(majorgroup == "Not stated", NA_character_, majorgroup),
    class      = if_else(class      == "Not stated", NA_character_, class)
  )
message("Coerced 'Not stated' → NA: ", n_not_stated_majorgroup,
        " majorgroup rows, ", n_not_stated_class, " class rows")

# ---------------------------------------------------------------------------
# Step 1 — Unit conversion: wqbench mg/L → µg/L
# ---------------------------------------------------------------------------

n_mgL <- sum(clean$conc_unit == "mg/L", na.rm = TRUE)
clean <- clean |>
  mutate(
    conc_value = if_else(conc_unit == "mg/L", conc_value * 1000, conc_value),
    conc_unit  = if_else(conc_unit == "mg/L", "ug/L", conc_unit)
  )
stopifnot(all(clean$conc_unit == "ug/L"))
clean <- clean |> rename(conc_ug_L = conc_value)
message("Unit conversion: ", n_mgL, " wqbench rows converted from mg/L to µg/L")

# ---------------------------------------------------------------------------
# Step 2 — Drop rows that cannot enter aggregation
# ---------------------------------------------------------------------------

# 2a. Drop NA effect_category
n_before_ec_drop <- nrow(clean)
ec_drop_by_source <- clean |>
  filter(is.na(effect_category)) |>
  count(source, name = "n_dropped")
clean <- clean |> filter(!is.na(effect_category))
n_dropped_ec <- n_before_ec_drop - nrow(clean)
message("Dropped NA effect_category: ", n_dropped_ec, " rows")

# 2b. Drop acute-non-eligible rows (acute NOECs/LOECs — cannot be ACR-converted)
n_before_acute_drop <- nrow(clean)
acute_non_elig <- clean |>
  filter(test_class == "acute" & (is.na(acr_eligible) | acr_eligible != TRUE))
acute_drop_by_stattype <- acute_non_elig |>
  count(statistic_type, name = "n_dropped") |>
  arrange(desc(n_dropped))
clean <- clean |>
  filter(!(test_class == "acute" & (is.na(acr_eligible) | acr_eligible != TRUE)))
n_dropped_acute_non_eligible <- n_before_acute_drop - nrow(clean)
message("Dropped acute-non-eligible: ", n_dropped_acute_non_eligible, " rows")

n_aggregation_input <- nrow(clean)
message("Rows entering aggregation: ", n_aggregation_input)

# ---------------------------------------------------------------------------
# Step 3 — ACR conversion for retained acute records
# ---------------------------------------------------------------------------

acr_by_source <- clean |>
  filter(test_class == "acute", acr_eligible == TRUE) |>
  count(source, name = "n_converted")
clean <- clean |>
  mutate(
    conc_ug_L   = if_else(test_class == "acute" & acr_eligible == TRUE,
                          conc_ug_L / 10,
                          conc_ug_L),
    acr_applied = if_else(test_class == "acute" & acr_eligible == TRUE,
                          TRUE,
                          acr_applied)
  )
n_acr_converted <- sum(acr_by_source$n_converted)
message("ACR conversion applied to ", n_acr_converted, " acute-eligible rows")

# ---------------------------------------------------------------------------
# Step 4 — Step 1 of Section 3.4.4: geometric mean within grouping key
# ---------------------------------------------------------------------------
# Key: casnumber_grouped × accepted_name × medium × effect_category ×
#      statistic_type × duration_hours × life_stage
# NA treated as a distinct level (Decisions D1, D5).
# If max/min > 10 within a group, use min() and set geomean_flagged (Decision D2).

message("Computing geometric means within Step 1 grouping key ...")
geomean_step <- clean |>
  group_by(
    casnumber_grouped, accepted_name, medium,
    effect_category, statistic_type, duration_hours, life_stage
  ) |>
  summarise(
    conc_geomean = exp(mean(log(conc_ug_L))),
    conc_min     = min(conc_ug_L),
    conc_max     = max(conc_ug_L),
    n_in_group   = n(),
    any_acr      = any(acr_applied == TRUE, na.rm = TRUE),
    sources_raw  = paste(sort(unique(source)), collapse = ","),
    .groups      = "drop"
  ) |>
  mutate(
    geomean_flagged = (conc_max / conc_min) > 10,
    conc_step1      = if_else(geomean_flagged, conc_min, conc_geomean)
  )

n_step1_groups       <- nrow(geomean_step)
n_singleton_groups   <- sum(geomean_step$n_in_group == 1)
n_multi_groups       <- n_step1_groups - n_singleton_groups
n_groups_flagged     <- sum(geomean_step$geomean_flagged, na.rm = TRUE)
message("Step 1 groups: ", n_step1_groups, " total; ",
        n_singleton_groups, " singletons; ",
        n_multi_groups, " multi-record; ",
        n_groups_flagged, " geomean_flagged")

top_flagged <- geomean_step |>
  filter(geomean_flagged) |>
  mutate(spread_ratio = conc_max / conc_min) |>
  arrange(desc(spread_ratio)) |>
  slice_head(n = 10) |>
  select(casnumber_grouped, accepted_name, effect_category, statistic_type,
         duration_hours, life_stage, n_in_group, conc_min, conc_max, spread_ratio)

# ---------------------------------------------------------------------------
# Step 5 — Step 2 of Section 3.4.4: lowest value within each endpoint
# ---------------------------------------------------------------------------

message("Computing within-endpoint minimum (Step 2) ...")
endpoint_step <- geomean_step |>
  group_by(casnumber_grouped, accepted_name, medium, effect_category) |>
  summarise(
    conc_step2      = min(conc_step1),
    n_combinations  = n(),
    any_acr         = any(any_acr, na.rm = TRUE),
    geomean_flagged = any(geomean_flagged, na.rm = TRUE),
    # lifestage_mixed: has both NA and non-NA life_stage in this endpoint group
    lifestage_mixed = any(!is.na(life_stage)) & any(is.na(life_stage)),
    # duration_mixed: has both NA and non-NA duration_hours in this endpoint group
    duration_mixed  = any(!is.na(duration_hours)) & any(is.na(duration_hours)),
    sources_raw     = paste(
      sort(unique(unlist(strsplit(sources_raw, ",")))),
      collapse = ","
    ),
    n_records       = sum(n_in_group),
    .groups         = "drop"
  )

n_step2_groups <- nrow(endpoint_step)
message("Step 2 groups (casnumber × species × medium × effect_category): ",
        n_step2_groups)

# Counts for audit
n_na_lifestage_groups  <- sum(is.na(geomean_step$life_stage))
n_na_duration_groups   <- sum(is.na(geomean_step$duration_hours))
n_lifestage_mixed      <- sum(endpoint_step$lifestage_mixed, na.rm = TRUE)
n_duration_mixed       <- sum(endpoint_step$duration_mixed, na.rm = TRUE)

# ---------------------------------------------------------------------------
# Step 6 — Step 3 of Section 3.4.4: lowest value across endpoints
# ---------------------------------------------------------------------------

message("Computing across-endpoint minimum (Step 3) ...")
species_step <- endpoint_step |>
  group_by(casnumber_grouped, accepted_name, medium) |>
  summarise(
    conc_ug_L        = min(conc_step2),
    n_records        = sum(n_records),
    any_acr_applied  = any(any_acr, na.rm = TRUE),
    geomean_flagged  = any(geomean_flagged, na.rm = TRUE),
    lifestage_mixed  = any(lifestage_mixed, na.rm = TRUE),
    duration_mixed   = any(duration_mixed, na.rm = TRUE),
    sources_contributing = paste(
      sort(unique(unlist(strsplit(sources_raw, ",")))),
      collapse = ","
    ),
    .groups = "drop"
  )

n_output_rows <- nrow(species_step)
message("Output rows (species × chemical × medium): ", n_output_rows)

# ---------------------------------------------------------------------------
# Step 7 — Attach taxonomy
# ---------------------------------------------------------------------------

message("Attaching taxonomy ...")
taxonomy <- enriched |>
  filter(dedup_retained == TRUE, priority_kept == TRUE) |>
  select(accepted_name, kingdom, phylum, class, order_taxon, family, genus,
         majorgroup, taxonomy_provenance) |>
  mutate(
    majorgroup = if_else(majorgroup == "Not stated", NA_character_, majorgroup),
    class      = if_else(class      == "Not stated", NA_character_, class)
  ) |>
  group_by(accepted_name) |>
  slice(1) |>
  ungroup()

aggregated <- species_step |>
  left_join(taxonomy, by = "accepted_name")

n_missing_taxonomy <- sum(is.na(aggregated$kingdom))
if (n_missing_taxonomy > 20) {
  stop(paste("Unexpected number of missing taxonomy rows:", n_missing_taxonomy))
} else if (n_missing_taxonomy > 5) {
  warning(paste("More missing taxonomy rows than expected:", n_missing_taxonomy))
}
message("Missing kingdom (expected ≤5 from Sialis genus-only): ", n_missing_taxonomy)

# ---------------------------------------------------------------------------
# Step 8 — Attach chemical names, select and order output columns
# ---------------------------------------------------------------------------

chemical_names <- enriched |>
  distinct(casnumber_grouped, chemicalname_grouped)

n_cas_multi_name <- chemical_names |>
  count(casnumber_grouped) |>
  filter(n > 1) |>
  nrow()
if (n_cas_multi_name > 0) {
  warning(n_cas_multi_name, " casnumber_grouped values have multiple chemicalname_grouped entries — taking first")
}
chemical_names <- chemical_names |>
  group_by(casnumber_grouped) |>
  slice(1) |>
  ungroup()

output <- aggregated |>
  left_join(chemical_names, by = "casnumber_grouped") |>
  select(
    casnumber_grouped,
    chemicalname_grouped,
    accepted_name,
    medium,
    conc_ug_L,
    majorgroup,
    kingdom, phylum, class, order_taxon, family, genus,
    taxonomy_provenance,
    n_records,
    sources_contributing,
    any_acr_applied,
    geomean_flagged,
    lifestage_mixed,
    duration_mixed
  )

# ---------------------------------------------------------------------------
# Validation checks
# ---------------------------------------------------------------------------

message("Running validation checks ...")

# 1. No duplicate rows on the output key
stopifnot(
  nrow(output) == nrow(distinct(output, casnumber_grouped, accepted_name, medium))
)

# 2. All concentrations are positive and finite
stopifnot(all(is.finite(output$conc_ug_L) & output$conc_ug_L > 0))

# 3. n_records >= 1 always
stopifnot(all(output$n_records >= 1))

# 4. sources_contributing is never empty
stopifnot(all(nchar(output$sources_contributing) > 0))

# 5. Logical columns — no NAs introduced
stopifnot(
  is.logical(output$any_acr_applied),
  is.logical(output$geomean_flagged),
  is.logical(output$lifestage_mixed),
  is.logical(output$duration_mixed)
)

message("All validation checks passed.")

# ---------------------------------------------------------------------------
# Step 9 — Write output CSV
# ---------------------------------------------------------------------------

write_csv(output, "data-raw/alldata/uncurated_raw_aggregated.csv")
file_size_mb <- file.size("data-raw/alldata/uncurated_raw_aggregated.csv") / 1e6
message("Written: data-raw/alldata/uncurated_raw_aggregated.csv (",
        round(file_size_mb, 1), " MB)")

# ---------------------------------------------------------------------------
# Audit report statistics
# ---------------------------------------------------------------------------

n_distinct_cas     <- n_distinct(output$casnumber_grouped)
n_distinct_species <- n_distinct(output$accepted_name)
medium_counts      <- count(output, medium, name = "n_rows")
source_combos      <- count(output, sources_contributing, name = "n_rows") |>
  arrange(desc(n_rows))
n_acr_rows         <- sum(output$any_acr_applied, na.rm = TRUE)
n_geomean_rows     <- sum(output$geomean_flagged, na.rm = TRUE)
top_majorgroups    <- count(output, majorgroup, name = "n_rows") |>
  arrange(desc(n_rows)) |>
  slice_head(n = 10)

# ---------------------------------------------------------------------------
# Write audit report
# ---------------------------------------------------------------------------

report_lines <- c(
  "# Stage 4e — Aggregation Audit Report",
  "",
  paste("Generated:", Sys.time()),
  paste("Input file: data-raw/alldata/uncurated_raw_dedup_enriched.csv"),
  paste("Output file: data-raw/alldata/uncurated_raw_aggregated.csv"),
  "",
  "---",
  "",
  "## 1. Input summary",
  "",
  paste("- Rows loaded from enriched file:", nrow(enriched)),
  paste("- Rows after `dedup_retained & priority_kept` filter:", n_clean),
  paste("- 'Not stated' coerced to NA — majorgroup:", n_not_stated_majorgroup,
        "rows; class:", n_not_stated_class, "rows"),
  "",
  "## 2. Unit conversion",
  "",
  paste("- wqbench rows converted from mg/L to µg/L:", n_mgL),
  "- All rows now have `conc_unit == 'ug/L'` (assertion passed)",
  "",
  "## 3. Rows dropped before aggregation",
  "",
  "### 3a. NA effect_category",
  "",
  paste("- Total dropped:", n_dropped_ec,
        sprintf("(%.1f%% of clean subset)", 100 * n_dropped_ec / n_clean)),
  "",
  "**By source:**",
  "",
  paste(apply(ec_drop_by_source, 1,
              function(r) paste0("- ", r["source"], ": ", r["n_dropped"])),
        collapse = "\n"),
  "",
  "### 3b. Acute-non-eligible (acute NOECs/LOECs — cannot be ACR-converted)",
  "",
  paste("- Total dropped:", n_dropped_acute_non_eligible,
        sprintf("(%.1f%% of clean subset)", 100 * n_dropped_acute_non_eligible / n_clean)),
  "",
  "**By statistic_type:**",
  "",
  paste(apply(acute_drop_by_stattype, 1,
              function(r) paste0("- ", r["statistic_type"], ": ", r["n_dropped"])),
        collapse = "\n"),
  "",
  paste("- Rows entering aggregation:", n_aggregation_input),
  "",
  "## 4. ACR conversion",
  "",
  paste("- Total rows ACR-converted (÷10):", n_acr_converted),
  "",
  "**By source:**",
  "",
  paste(apply(acr_by_source, 1,
              function(r) paste0("- ", r["source"], ": ", r["n_converted"])),
        collapse = "\n"),
  "",
  "## 5. Geometric mean step (Step 1 of Section 3.4.4)",
  "",
  paste("- Total groups formed:", n_step1_groups),
  paste("- Singleton groups (n = 1):", n_singleton_groups,
        sprintf("(%.1f%%)", 100 * n_singleton_groups / n_step1_groups)),
  paste("- Multi-record groups:", n_multi_groups,
        sprintf("(%.1f%%)", 100 * n_multi_groups / n_step1_groups)),
  paste("- Groups flagged (max/min > 10):", n_groups_flagged,
        sprintf("(%.2f%%)", 100 * n_groups_flagged / n_step1_groups)),
  "",
  "### Top 10 flagged groups by spread (max/min ratio)",
  "",
  "| casnumber_grouped | accepted_name | effect_category | statistic_type | duration_hours | life_stage | n | conc_min | conc_max | ratio |",
  "|---|---|---|---|---|---|---|---|---|---|",
  paste(apply(top_flagged, 1, function(r) {
    paste0("| ", r["casnumber_grouped"], " | ", r["accepted_name"], " | ",
           r["effect_category"], " | ", r["statistic_type"], " | ",
           r["duration_hours"], " | ", r["life_stage"], " | ",
           r["n_in_group"], " | ",
           round(as.numeric(r["conc_min"]), 4), " | ",
           round(as.numeric(r["conc_max"]), 4), " | ",
           round(as.numeric(r["spread_ratio"]), 1), " |")
  }), collapse = "\n"),
  "",
  "## 6. Groups with NA life_stage or NA duration",
  "",
  paste("- Step 1 groups with NA life_stage:", n_na_lifestage_groups),
  paste("- Step 1 groups with NA duration_hours:", n_na_duration_groups),
  paste("- `lifestage_mixed = TRUE` flags at Step 2:", n_lifestage_mixed),
  paste("- `duration_mixed = TRUE` flags at Step 2:", n_duration_mixed),
  "",
  "## 7. Output summary",
  "",
  paste("- Total rows in `uncurated_raw_aggregated.csv`:", n_output_rows),
  paste("- Distinct chemicals (`casnumber_grouped`):", n_distinct_cas),
  paste("- Distinct species (`accepted_name`):", n_distinct_species),
  "",
  "**Rows by medium:**",
  "",
  paste(apply(medium_counts, 1,
              function(r) paste0("- ", r["medium"], ": ", r["n_rows"])),
        collapse = "\n"),
  "",
  "**Source combination breakdown:**",
  "",
  paste(apply(head(source_combos, 20), 1,
              function(r) paste0("- `", r["sources_contributing"], "`: ",
                                 r["n_rows"])),
        collapse = "\n"),
  "",
  paste("- Rows with `any_acr_applied == TRUE`:", n_acr_rows,
        sprintf("(%.1f%%)", 100 * n_acr_rows / n_output_rows)),
  paste("- Rows with `geomean_flagged == TRUE`:", n_geomean_rows,
        sprintf("(%.2f%%)", 100 * n_geomean_rows / n_output_rows)),
  "",
  "**Top 10 majorgroups by row count:**",
  "",
  paste(apply(top_majorgroups, 1,
              function(r) paste0("- ", r["majorgroup"], ": ", r["n_rows"])),
        collapse = "\n"),
  "",
  "## 8. File sizes",
  "",
  paste("- `uncurated_raw_aggregated.csv`:", round(file_size_mb, 1), "MB"),
  ""
)

writeLines(report_lines, "data-raw/alldata/stage4e-aggregation-report.md")
message("Audit report written: data-raw/alldata/stage4e-aggregation-report.md")
message("Stage 4e complete.")
