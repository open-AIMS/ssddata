# =============================================================================
# scripts/stage4b-effect-category-fixup.R
# =============================================================================
# Purpose:
#   Post-hoc correction to the Stage 4b envirotox effect_category mapping,
#   following human domain-expert review of the 13 raw `Effect` values that
#   scripts/stage4b-extract.R left in the OTHER bucket (effect_category_mapped
#   == "OTHER", effect_category == NA). This is a targeted fixup only -- it
#   does NOT re-run the full Stage 4b extraction and does NOT require a
#   database connection. It patches the two Stage 4b output files in place.
#
# Inputs:
#   - data-raw/alldata/envirotox_effect_category_map.csv (Stage 4b mapping
#     audit trail -- the 13 OTHER rows are corrected here)
#   - data-raw/alldata/uncurated_raw_combined.csv (Stage 4b combined output --
#     449,888 rows x 17 cols; only envirotox rows with NA effect_category are
#     touched)
#   - data-raw/envirotox/envirotox.xlsx (sheet "test") -- re-filtered using
#     the same statistic/type/solubility rule as scripts/stage4b-extract.R
#     Step 5b, solely to recover each row's source_id -> raw Effect text
#     mapping (uncurated_raw_combined.csv does not retain the raw Effect
#     field, only the already-mapped effect_category).
#
# Outputs (overwritten in place):
#   - data-raw/alldata/envirotox_effect_category_map.csv
#   - data-raw/alldata/uncurated_raw_combined.csv
#
# Join method note:
#   envirotox's source_id (assigned as row_number() over the filtered test
#   sheet in stage4b-extract.R Step 5b) is retained verbatim in
#   uncurated_raw_combined.csv and is unique 1:1 with that filtered row order.
#   It is used here as the join key back to the raw Effect text, in
#   preference to a native_cas x scientificname x conc_value x test_class
#   composite key, since the composite key risks collisions where several
#   rows share all four values. The join was cross-checked against
#   envirotox_effect_category_map.csv's n_rows counts before this script was
#   finalised -- all 14 reviewed raw_effect values matched exactly.
#
# CRITICAL PATH NOTE: the master CAS lookup lives at
#   data-raw/cas_parent_lookup_all.csv -- NOT
#   data-raw/anztox/cas_parent_lookup_all.csv. (Not used by this script, but
#   recorded per CLAUDE.md to avoid the recurring path error -- this fixup
#   does not touch CAS at all.)
# =============================================================================

library(dplyr)
library(readr)
library(openxlsx)

# =============================================================================
# STEP 1 -- human-reviewed corrections for the envirotox OTHER bucket
# =============================================================================
# "Intoxication, Immobile" is included for audit-trail completeness only --
# it was already correctly mapped to IMM by the Stage 4b keyword rules
# (mapping_rule "immobil|mobil", not "unmatched"), so it is not part of the
# OTHER bucket and requires no change below.
corrections <- tribble(
  ~raw_effect, ~corrected_effect_category,
  "Intoxication", NA_character_,
  "Intoxication, Intoxication, general", NA_character_,
  "Intoxication, Immobile", "IMM",
  "Shell Deposition: Change in the ability to grow a shell.", "GRO",
  "Filtration Rate: Change in rate of filtration.", "PSE",
  "Emergence: Change in the emergence from larval stage into the adult stage.", "DVP",
  "cell number", "POP",
  "Lifespan", NA_character_,
  "Loss of equilibrium", "BEH",
  "loss of equilibrium", "BEH",
  "Nitrogen Fixation: Change in ability of aquatic plants to fix nitrogen.", "PSE",
  "Regeneration: Change in ability to regenerate a body part, byssus production.", "MOR",
  "total embryotoxicity", "DVP",
  "cell count", "POP"
)

# =============================================================================
# STEP 2 -- update envirotox_effect_category_map.csv
# =============================================================================
map_path <- "data-raw/alldata/envirotox_effect_category_map.csv"
effect_map <- read_csv(
  map_path,
  col_types = cols(
    raw_effect = col_character(),
    normalised_effect_lower = col_character(),
    effect_category_mapped = col_character(),
    n_rows = col_double(),
    mapping_rule = col_character()
  )
)

effect_map_joined <- effect_map |>
  left_join(corrections, by = "raw_effect") |>
  mutate(
    reviewed = effect_category_mapped == "OTHER" & raw_effect %in% corrections$raw_effect,
    effect_category_mapped_new = if_else(
      reviewed & !is.na(corrected_effect_category),
      corrected_effect_category,
      effect_category_mapped
    ),
    mapping_rule_new = if_else(reviewed, "human_review", mapping_rule)
  )

n_reviewed <- sum(effect_map_joined$reviewed)
n_recategorised <- sum(
  effect_map_joined$reviewed & effect_map_joined$effect_category_mapped_new != "OTHER"
)

message(
  "\n=== Step 2: envirotox_effect_category_map.csv ===\n",
  n_reviewed, " OTHER rows reviewed by human; ",
  n_recategorised, " recategorised out of OTHER; ",
  n_reviewed - n_recategorised, " confirmed to remain OTHER (NA)."
)
message("\nRows recategorised (mapping_rule: unmatched -> human_review):")
print(
  effect_map_joined |>
    filter(reviewed, effect_category_mapped_new != "OTHER") |>
    select(raw_effect, n_rows, old_category = effect_category_mapped, new_category = effect_category_mapped_new)
)
message("\nRows confirmed to remain OTHER/NA after human review (mapping_rule: unmatched -> human_review):")
print(
  effect_map_joined |>
    filter(reviewed, effect_category_mapped_new == "OTHER") |>
    select(raw_effect, n_rows)
)

effect_map_final <- effect_map_joined |>
  transmute(
    raw_effect,
    normalised_effect_lower,
    effect_category_mapped = effect_category_mapped_new,
    n_rows,
    mapping_rule = mapping_rule_new
  )

write_csv(effect_map_final, map_path)
message("\nWrote: ", map_path)

# =============================================================================
# STEP 3 -- update uncurated_raw_combined.csv
# =============================================================================
combined_path <- "data-raw/alldata/uncurated_raw_combined.csv"
combined_col_types <- cols(
  source = col_character(),
  native_cas = col_character(),
  casnumber_grouped = col_character(),
  chemicalname_grouped = col_character(),
  scientificname = col_character(),
  medium = col_character(),
  test_class = col_character(),
  statistic_type = col_character(),
  effect_category = col_character(),
  duration_hours = col_double(),
  life_stage = col_character(),
  conc_value = col_double(),
  conc_unit = col_character(),
  acr_eligible = col_logical(),
  study_reference = col_character(),
  source_id = col_character(),
  acr_applied = col_logical()
)
combined <- read_csv(combined_path, col_types = combined_col_types)

stopifnot(
  "uncurated_raw_combined.csv row count changed from expected 449,888" =
    nrow(combined) == 449888,
  "uncurated_raw_combined.csv column count changed from expected 17" =
    ncol(combined) == 17
)
message(
  "\n=== Step 3: uncurated_raw_combined.csv ===\n",
  "Confirmed ", nrow(combined), " rows x ", ncol(combined), " cols."
)

na_by_source_before <- combined |>
  group_by(source) |>
  summarise(n_na = sum(is.na(effect_category)), .groups = "drop")
message("\nNA effect_category by source (before):")
print(na_by_source_before)

# Recover raw Effect text per envirotox row by replicating the Stage 4b
# Step 5b statistic/type/solubility filter and source_id assignment exactly.
envirotox_test <- read.xlsx("data-raw/envirotox/envirotox.xlsx", sheet = "test")
envirotox_selected <- envirotox_test |>
  filter(
    (Test.statistic == "EC50" & Test.type == "A") |
      (Test.statistic == "LC50" & Test.type == "A") |
      (Test.statistic == "NOEC" & Test.type == "C") |
      (Test.statistic == "NOEL" & Test.type == "C")
  ) |>
  filter(Effect.is.5X.above.water.solubility == "0") |>
  mutate(source_id = as.character(row_number()))

n_envirotox_combined <- sum(combined$source == "envirotox")
stopifnot(
  "Re-derived envirotox row count does not match uncurated_raw_combined.csv -- source_id join would be unsafe" =
    nrow(envirotox_selected) == n_envirotox_combined
)

# Only the 10 raw_effect values whose corrected category is non-NA need a
# value change (the 3 that remain OTHER/NA are already NA -- a no-op).
recategorised_effects <- corrections |>
  filter(!is.na(corrected_effect_category), raw_effect != "Intoxication, Immobile")

affected_source_ids <- envirotox_selected |>
  inner_join(recategorised_effects, by = c("Effect" = "raw_effect")) |>
  select(source_id, Effect, corrected_effect_category)

message(
  "\nenvirotox.xlsx rows matching a recategorised raw_effect value: ",
  nrow(affected_source_ids)
)
print(count(affected_source_ids, Effect, corrected_effect_category))

# Sanity check: every affected row should currently be source == "envirotox"
# with effect_category NA, before applying the update.
affected_check <- combined |>
  filter(source == "envirotox", source_id %in% affected_source_ids$source_id)
stopifnot(
  "Affected row count mismatch between envirotox.xlsx and uncurated_raw_combined.csv" =
    nrow(affected_check) == nrow(affected_source_ids),
  "Some affected rows do not currently have NA effect_category as expected" =
    all(is.na(affected_check$effect_category))
)

update_lookup <- affected_source_ids |>
  distinct(source_id, corrected_effect_category)

# Join restricted to the envirotox-filtered subset only -- source_id is a
# per-source row index, not globally unique across anztox/wqbench/envirotox,
# so joining on source_id alone against the full combined frame would risk
# cross-source key collisions.
combined <- combined |> mutate(.orig_row = row_number())
non_envirotox_rows <- combined |> filter(source != "envirotox")
envirotox_rows <- combined |>
  filter(source == "envirotox") |>
  left_join(update_lookup, by = "source_id") |>
  mutate(effect_category = coalesce(corrected_effect_category, effect_category)) |>
  select(-corrected_effect_category)

combined_updated <- bind_rows(non_envirotox_rows, envirotox_rows) |>
  arrange(.orig_row) |>
  select(-.orig_row)

stopifnot(
  "Row count changed after update -- aborting before write" =
    nrow(combined_updated) == 449888
)

na_by_source_after <- combined_updated |>
  group_by(source) |>
  summarise(n_na = sum(is.na(effect_category)), .groups = "drop")
message("\nNA effect_category by source (after):")
print(na_by_source_after)

non_envirotox_unchanged <- identical(
  na_by_source_before |> filter(source != "envirotox") |> arrange(source),
  na_by_source_after |> filter(source != "envirotox") |> arrange(source)
)
stopifnot(
  "Non-envirotox NA effect_category counts changed unexpectedly" =
    non_envirotox_unchanged
)
message("Non-envirotox NA effect_category counts unchanged: ", non_envirotox_unchanged)

n_rows_updated <- sum(
  combined$source == "envirotox" & combined$source_id %in% update_lookup$source_id
)
message("\nRows updated: ", n_rows_updated)

message("\nenvirotox effect_category distribution (after):")
envirotox_dist_after <- combined_updated |>
  filter(source == "envirotox") |>
  count(effect_category)
print(envirotox_dist_after)

stopifnot(
  "BEH not found in envirotox effect_category distribution after update" =
    "BEH" %in% envirotox_dist_after$effect_category
)
message("Confirmed BEH present as a new effect_category value for envirotox.")

write_csv(combined_updated, combined_path)
message("\nWrote: ", combined_path)
