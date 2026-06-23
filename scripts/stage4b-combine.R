# =============================================================================
# scripts/stage4b-combine.R
# =============================================================================
# Purpose:
#   Stage 4b, part 2 of 2. Reads the anztox intermediate CSV produced by part
#   1, extracts filtered-but-unaggregated records from wqbench and envirotox,
#   and row-binds all three uncurated sources into a single combined output
#   on a shared eleven-column schema. No database connection is required --
#   this script reads anztox_extracted.csv as a pre-built input produced by
#   scripts/stage4b-anztox-extract.R (run separately, from Windows Positron,
#   where the live ANZTOX PostgreSQL connection is available).
#
# Inputs:
#   - data-raw/alldata/anztox_extracted.csv (pre-built; see above)
#   - data-raw/wqbench/ecotox_ascii_12_11_2025.rds
#   - data-raw/envirotox/envirotox.xlsx (sheets "test", "substance")
#   - data-raw/cas_parent_lookup_all.csv (master CAS parent lookup -- NOT
#     data-raw/anztox/cas_parent_lookup_all.csv)
#
# Output:
#   - data-raw/alldata/uncurated_raw_combined.csv
#
# Decisions implemented:
#   - wqbench medium: "FW" -> "Freshwater", "SW" -> "Marine", else "Unknown".
#   - wqbench test_class: duration_class "chronic"/"acute" pass through
#     as-is; any other value is retained as-is (not dropped).
#   - wqbench endpoint/acr_eligible: the output "endpoint" column is
#     wqbench's effect-category field (`effect`, e.g. "Mortality",
#     "Growth"); acr_eligible is instead derived from wqbench's separate
#     statistic-type field (`endpoint`, e.g. "LC50") via a regex on
#     LC/EC/IC followed by a digit.
#   - envirotox statistic/type/solubility filter and the mg/L -> ug/L
#     conversion are reproduced exactly from data-raw/envirotox/DATASET.R.
#   - envirotox CAS join uses the test sheet's own `original.CAS` column
#     joined directly to the substance sheet's `original.CAS` (both already
#     present as raw columns) -- bypassing envirotox's internal grouped
#     `CAS` field (e.g. "Metalgrp.Ag"), per the Stage 4a audit's explicit
#     design decision that ssddata's own cas_parent_lookup_all.csv should be
#     the sole chemical-grouping authority.
#   - envirotox medium is hardcoded "Unknown" (Stage 3 decision).
#   - No within-group aggregation, no priority selection across test types,
#     no ACR conversion, and no eligibility thresholds are applied anywhere
#     in this script -- those are Stage 4c/4d. This script only filters and
#     reshapes each source onto the common schema, then combines them.
# =============================================================================

library(dplyr)
library(readr)
library(openxlsx)

# =============================================================================
# STEP 2 -- Load and validate anztox_extracted.csv
# =============================================================================

anztox_extracted <- read_csv(
  "data-raw/alldata/anztox_extracted.csv",
  col_types = cols(
    source = col_character(),
    casnumber_grouped = col_character(),
    chemicalname_grouped = col_character(),
    scientificname = col_character(),
    medium = col_character(),
    test_class = col_character(),
    endpoint = col_character(),
    conc_value = col_double(),
    conc_unit = col_character(),
    acr_eligible = col_logical(),
    source_id = col_character(),
    source_dataset = col_character(),
    majorgroup = col_character()
  )
)

expected_anztox_cols <- c(
  "source", "casnumber_grouped", "chemicalname_grouped", "scientificname",
  "medium", "test_class", "endpoint", "conc_value", "conc_unit",
  "acr_eligible", "source_id", "source_dataset", "majorgroup"
)

if (!identical(names(anztox_extracted), expected_anztox_cols)) {
  stop(
    "anztox_extracted.csv does not have the expected 13 columns/order.\n",
    "Expected: ", paste(expected_anztox_cols, collapse = ", "), "\n",
    "Found:    ", paste(names(anztox_extracted), collapse = ", ")
  )
}

n_bad_conc_anztox <- sum(
  is.na(anztox_extracted$conc_value) | anztox_extracted$conc_value <= 0
)
if (n_bad_conc_anztox > 0) {
  stop(
    "anztox_extracted.csv has ", n_bad_conc_anztox,
    " rows with NA or non-positive conc_value."
  )
}

bad_source <- setdiff(unique(anztox_extracted$source), "anztox")
if (length(bad_source) > 0) {
  stop(
    "anztox_extracted.csv has unexpected source value(s): ",
    paste(bad_source, collapse = ", ")
  )
}

bad_medium <- setdiff(unique(anztox_extracted$medium), c("Freshwater", "Marine"))
if (length(bad_medium) > 0) {
  stop(
    "anztox_extracted.csv has unexpected medium value(s): ",
    paste(bad_medium, collapse = ", ")
  )
}

bad_test_class <- setdiff(
  unique(anztox_extracted$test_class),
  c("chronic", "subchronic", "acute")
)
if (length(bad_test_class) > 0) {
  stop(
    "anztox_extracted.csv has unexpected test_class value(s): ",
    paste(bad_test_class, collapse = ", ")
  )
}

message("--- anztox_extracted.csv validated ---")
message("Rows: ", nrow(anztox_extracted))
message("\nBy test_class:")
print(count(anztox_extracted, test_class))
message("\nBy medium:")
print(count(anztox_extracted, medium))
message(
  "\nDistinct casnumber_grouped: ",
  n_distinct(anztox_extracted$casnumber_grouped)
)

# =============================================================================
# STEP 3 -- wqbench extraction
# =============================================================================

# --- 3a: load RDS ---

wqbench_rds_expected <- "data-raw/wqbench/ecotox_ascii_12_11_2025.rds"

if (file.exists(wqbench_rds_expected)) {
  wqbench_rds_path <- wqbench_rds_expected
} else {
  rds_files <- list.files(
    "data-raw/wqbench",
    pattern = "\\.rds$",
    full.names = TRUE
  )
  if (length(rds_files) != 1) {
    stop(
      "Expected wqbench RDS not found, and data-raw/wqbench/ does not ",
      "contain exactly one fallback .rds file (found ", length(rds_files),
      ")."
    )
  }
  wqbench_rds_path <- rds_files[1]
  message(
    "NOTE: expected file '", wqbench_rds_expected, "' not found; using ",
    "fallback file '", wqbench_rds_path, "' instead."
  )
}

wqbench_raw <- readRDS(wqbench_rds_path)

n_wqbench_expected <- 361817
ncol_wqbench_expected <- 24
pct_diff_rows <- abs(nrow(wqbench_raw) - n_wqbench_expected) / n_wqbench_expected

if (pct_diff_rows > 0.05) {
  warning(
    "wqbench RDS row count (", nrow(wqbench_raw), ") differs from the ",
    "Stage 4a audit's expected ~", n_wqbench_expected, " by more than 5%. ",
    "Continuing, but the RDS may have changed -- verify this is expected."
  )
}
if (ncol(wqbench_raw) != ncol_wqbench_expected) {
  warning(
    "wqbench RDS column count (", ncol(wqbench_raw), ") differs from the ",
    "Stage 4a audit's expected ", ncol_wqbench_expected, ". Continuing."
  )
}

message(
  "\n--- wqbench RDS loaded: ", wqbench_rds_path, " (",
  nrow(wqbench_raw), " rows x ", ncol(wqbench_raw), " cols) ---"
)

# --- 3b: medium mapping ---

wqbench_mapped <- wqbench_raw |>
  mutate(
    medium = case_when(
      media_type == "FW" ~ "Freshwater",
      media_type == "SW" ~ "Marine",
      TRUE ~ "Unknown"
    )
  )

message("\nwqbench medium counts:")
print(count(wqbench_mapped, medium))

# --- 3c: test_class classification ---

wqbench_mapped <- wqbench_mapped |>
  mutate(
    test_class = case_when(
      duration_class == "chronic" ~ "chronic",
      duration_class == "acute" ~ "acute",
      TRUE ~ duration_class
    )
  )

message("\nwqbench test_class counts:")
print(count(wqbench_mapped, test_class))

# --- 3d: CAS parent lookup ---

cas_parent_lookup <- read_csv(
  "data-raw/cas_parent_lookup_all.csv",
  col_types = cols(
    casnumber = col_character(),
    chemicalname = col_character(),
    parent_cas_dashed = col_character(),
    parent_casnumber = col_character(),
    parent_name = col_character(),
    match_rationale = col_character(),
    human_checked = col_character(),
    notes = col_character()
  )
)

wqbench_mapped <- wqbench_mapped |>
  left_join(
    cas_parent_lookup |>
      transmute(
        casnumber = as.character(casnumber),
        parent_casnumber = as.character(parent_casnumber),
        parent_name = as.character(parent_name)
      ),
    by = c("cas" = "casnumber")
  ) |>
  mutate(
    casnumber_grouped = coalesce(parent_casnumber, cas),
    chemicalname_grouped = coalesce(parent_name, chemical_name)
  )

# --- 3e: populate common schema columns ---
# NOTE: acr_eligible is derived from wqbench's own statistic-type `endpoint`
# field (e.g. "LC50") -- computed via mutate() *before* the output `endpoint`
# column is overwritten with `effect` below, since transmute() evaluates
# left-to-right and a later reference to `endpoint` would otherwise pick up
# the already-renamed value instead of the original field.

wqbench_mapped <- wqbench_mapped |>
  mutate(
    acr_eligible = grepl("LC[0-9]|EC[0-9]|IC[0-9]", endpoint, ignore.case = TRUE)
  )

wqbench_output <- wqbench_mapped |>
  transmute(
    source = "wqbench",
    casnumber_grouped,
    chemicalname_grouped,
    scientificname = latin_name,
    medium,
    test_class,
    endpoint = effect,
    conc_value = `effect_conc_mg.L`,
    conc_unit = "mg/L",
    acr_eligible,
    source_id = paste0(as.character(species_number), "_", cas)
  )

if (all(is.na(wqbench_output$conc_value))) {
  message("NOTE: effect_conc_mg.L is absent/all-NA; falling back to effect_conc_std_mg.L.")
  wqbench_output <- wqbench_mapped |>
    transmute(
      source = "wqbench",
      casnumber_grouped,
      chemicalname_grouped,
      scientificname = latin_name,
      medium,
      test_class,
      endpoint = effect,
      conc_value = `effect_conc_std_mg.L`,
      conc_unit = "mg/L",
      acr_eligible,
      source_id = paste0(as.character(species_number), "_", cas)
    )
}

# Basic validity filter (mirrors anztox part 1's base filter on
# concentrationused): the raw RDS contains 35 rows with effect_conc_mg.L
# exactly 0 (not NA). These are not a valid SSD input under any source's
# convention and would otherwise fail the Step 5c combined sanity check.
n_bad_wqbench_conc <- sum(
  is.na(wqbench_output$conc_value) | wqbench_output$conc_value <= 0
)
if (n_bad_wqbench_conc > 0) {
  message(
    "Dropping ", n_bad_wqbench_conc,
    " wqbench rows with NA or non-positive conc_value."
  )
  wqbench_output <- wqbench_output |>
    filter(!is.na(conc_value), conc_value > 0)
}

message("\nwqbench output rows: ", nrow(wqbench_output))

# =============================================================================
# STEP 4 -- envirotox extraction
# =============================================================================

# --- 4a: load raw data ---

envirotox_test <- read.xlsx("data-raw/envirotox/envirotox.xlsx", sheet = "test")
envirotox_substance <- read.xlsx(
  "data-raw/envirotox/envirotox.xlsx",
  sheet = "substance"
)

message(
  "\n--- envirotox raw rows: test = ", nrow(envirotox_test),
  ", substance = ", nrow(envirotox_substance), " ---"
)

# --- 4b: statistic/type/solubility filter (reproduced exactly from DATASET.R) ---

envirotox_selected <- envirotox_test |>
  filter(
    (Test.statistic == "EC50" & Test.type == "A") |
      (Test.statistic == "LC50" & Test.type == "A") |
      (Test.statistic == "NOEC" & Test.type == "C") |
      (Test.statistic == "NOEL" & Test.type == "C")
  ) |>
  filter(Effect.is.5X.above.water.solubility == "0")

message("Rows surviving statistic/type/solubility filter: ", nrow(envirotox_selected))

# Assign source_id from row position at this point, before any further filtering.
envirotox_selected <- envirotox_selected |>
  mutate(source_id = as.character(row_number()))

# --- 4c: unit conversion (mg/L -> ug/L, exactly as DATASET.R) ---

envirotox_selected <- envirotox_selected |>
  mutate(Effect.value = Effect.value * 1000)

# --- 4d: join substance sheet for CAS, then apply master CAS parent lookup ---

envirotox_selected <- envirotox_selected |>
  mutate(original.CAS = as.character(original.CAS)) |>
  left_join(
    envirotox_substance |>
      transmute(
        original.CAS = as.character(original.CAS),
        substance_chemical_name = Chemical.name
      ),
    by = c("original.CAS" = "original.CAS")
  )

envirotox_selected <- envirotox_selected |>
  left_join(
    cas_parent_lookup |>
      transmute(
        casnumber = as.character(casnumber),
        parent_casnumber = as.character(parent_casnumber),
        parent_name = as.character(parent_name)
      ),
    by = c("original.CAS" = "casnumber")
  ) |>
  mutate(
    casnumber_grouped = coalesce(parent_casnumber, original.CAS),
    chemicalname_grouped = coalesce(parent_name, substance_chemical_name)
  )

# --- 4e: test_class classification ---

envirotox_selected <- envirotox_selected |>
  mutate(
    test_class = case_when(
      Test.type == "A" ~ "acute",
      Test.type == "C" ~ "chronic"
    )
  )

message("\nenvirotox test_class counts:")
print(count(envirotox_selected, test_class))

# --- 4f: populate common schema columns ---

envirotox_output <- envirotox_selected |>
  transmute(
    source = "envirotox",
    casnumber_grouped,
    chemicalname_grouped,
    scientificname = Latin.name,
    medium = "Unknown",
    test_class,
    endpoint = Test.statistic,
    conc_value = Effect.value,
    conc_unit = "ug/L",
    acr_eligible = Test.statistic %in% c("EC50", "LC50"),
    source_id
  )

message("\nenvirotox output rows: ", nrow(envirotox_output))

# =============================================================================
# STEP 5 -- Combine and write output
# =============================================================================

# --- 5a: trim anztox to common schema ---

anztox_trimmed <- anztox_extracted |>
  select(-source_dataset, -majorgroup)

# --- 5b: validate schema alignment ---

common_cols <- c(
  "source", "casnumber_grouped", "chemicalname_grouped", "scientificname",
  "medium", "test_class", "endpoint", "conc_value", "conc_unit",
  "acr_eligible", "source_id"
)

for (nm in c("anztox_trimmed", "wqbench_output", "envirotox_output")) {
  df <- get(nm)
  if (!identical(names(df), common_cols)) {
    stop(
      nm, " does not match the common 11-column schema.\n",
      "Expected: ", paste(common_cols, collapse = ", "), "\n",
      "Found:    ", paste(names(df), collapse = ", ")
    )
  }
}

# --- 5c: row-bind and sanity checks ---

combined <- bind_rows(anztox_trimmed, wqbench_output, envirotox_output)

message("\n=== Combined sanity checks ===")

message("\nRow count by source:")
print(count(combined, source))

message("\nRow count by test_class, by source:")
print(count(combined, source, test_class))

message("\nRow count by medium, by source:")
print(count(combined, source, medium))

message("\nDistinct casnumber_grouped, by source:")
print(combined |> group_by(source) |> summarise(n_distinct_cas = n_distinct(casnumber_grouped)))
message("Distinct casnumber_grouped, overall: ", n_distinct(combined$casnumber_grouped))

message("\nNA casnumber_grouped, by source:")
print(combined |> group_by(source) |> summarise(n_na_cas = sum(is.na(casnumber_grouped))))

n_bad_conc <- sum(is.na(combined$conc_value) | combined$conc_value <= 0)
message("\nNA or <= 0 conc_value (combined): ", n_bad_conc)
if (n_bad_conc > 0) {
  stop(
    "FATAL: found ", n_bad_conc,
    " rows with NA or non-positive conc_value in the combined output."
  )
}

message("\nacr_eligible TRUE/FALSE, by source:")
print(count(combined, source, acr_eligible))

# --- 5d: write output ---

write_csv(combined, "data-raw/alldata/uncurated_raw_combined.csv")
message("\nWrote: data-raw/alldata/uncurated_raw_combined.csv")
message("Total combined rows: ", nrow(combined))
