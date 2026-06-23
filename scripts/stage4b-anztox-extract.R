# =============================================================================
# scripts/stage4b-anztox-extract.R
# =============================================================================
# Purpose:
#   Extract and de-normalise toxicity data from the ANZTOX PostgreSQL database
#   (toxicityvalue2000 + toxicityvalue2016), apply the master CAS parent lookup,
#   base filters, and test_class classification, then write a flat intermediate
#   CSV for downstream Stage 4b consolidation.
#
# Inputs:
#   - Local PostgreSQL "infogathering" database (toxicityvalue2000,
#     toxicityvalue2016, and associated lookup tables)
#   - data-raw/cas_parent_lookup_all.csv (master CAS parent lookup -- NOT the
#     40-row anztox-specific version)
#   - data-raw/anztox/endpoint_2016_to_2000_lookup.csv
#
# Output:
#   - data-raw/alldata/anztox_extracted.csv (13 columns; see Step 6)
#
# Decisions implemented:
#   A1 -- Concentration units: all rows assigned "ug/L". Confirmed for
#         source_dataset == "2000" (99.77% tagged ug/L in raw concentrationunit
#         table, ratio ~ 1 for 90.6% of comparable rows). Assumed for
#         source_dataset == "2016" (~14% of combined rows, unit convention
#         unconfirmed by the DB audit).
#   B1 -- "Chronic QSAR" testtype: explicitly dropped. QSAR-predicted values
#         are not appropriate for SSD fitting alongside measured data.
#   C1 -- acr_eligible approximation: TRUE where endpoint %in% c("MORT", "IMM"),
#         FALSE otherwise. Proxy for LC50/EC50-type endpoints; anztox retains
#         no separate statistic-type field.
#
# NOTE: This script requires a live connection to the infogathering PostgreSQL
#       instance and is intended to be run from Windows Positron where that
#       connection is available. It is NOT part of the package build pipeline.
# =============================================================================

library(dplyr)
library(stringr)
library(DBI)
library(RPostgres)
library(readr)

# =============================================================================
# HELPERS (reproduced from data-raw/anztox/DATASET.R for standalone use)
# =============================================================================

normalize_mediatype <- function(x) {
  x |>
    as.character() |>
    str_squish() |>
    str_to_lower() |>
    dplyr::recode(
      "freshwater" = "Freshwater",
      "marine" = "Marine",
      "marine water" = "Marine",
      .default = NA_character_
    )
}

get_db_password <- function() {
  pw <- Sys.getenv("ANZTOX_DB_PASSWORD", unset = "")
  if (nzchar(pw)) {
    return(pw)
  }
  if (requireNamespace("keyring", quietly = TRUE)) {
    return(keyring::key_get("infogathering_postgres", username = "postgres"))
  }
  stop("No DB password found. Set ANZTOX_DB_PASSWORD or keyring credential.")
}

# =============================================================================
# STEP 1 -- Connect to database
# =============================================================================

con <- DBI::dbConnect(
  RPostgres::Postgres(),
  dbname = "infogathering",
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = get_db_password()
)

if (!DBI::dbIsValid(con)) {
  stop("Database connection is not valid")
}

message("Connected to infogathering database.")

# =============================================================================
# STEP 2 -- Read from DB and de-normalise
# =============================================================================

# Read shared lookup tables
raw_toxicityvalue <- dbReadTable(con, "toxicityvalue")
raw_chemical <- dbReadTable(con, "chemical")
raw_species <- dbReadTable(con, "species")
lu_mediatype <- dbReadTable(con, "mediatype") |> rename(mediatype = name)
lu_endpoint <- dbReadTable(con, "endpoint")
lu_testtype <- dbReadTable(con, "testtype") |> rename(testtype = name)

# Read endpoint harmonisation lookup (2016 labels -> 2000 codes)
endpoint_2016_to_2000_lookup <- read_csv(
  "data-raw/anztox/endpoint_2016_to_2000_lookup.csv",
  col_types = cols(
    endpoint_2016_raw = col_character(),
    endpoint_2016_abbrev = col_character(),
    endpoint_2016_norm = col_character(),
    n_rows_2016 = col_double(),
    endpoint_2000_code = col_character(),
    map_method = col_character(),
    needs_review = col_logical()
  )
)

# Deduplicate to one mapping per raw label (defensive -- should be 1:1)
endpoint_2016_to_2000_lookup_dedup <- endpoint_2016_to_2000_lookup |>
  group_by(endpoint_2016_raw) |>
  arrange(
    desc(!is.na(endpoint_2000_code)),
    desc(n_rows_2016),
    .by_group = TRUE
  ) |>
  slice(1) |>
  ungroup() |>
  select(endpoint_2016_raw, endpoint_2000_code)

# --- toxicityvalue2000 ---
raw_2000 <- dbReadTable(con, "toxicityvalue2000")

tox2000 <- raw_2000 |>
  left_join(raw_toxicityvalue, by = c("toxicityvalue_id" = "id")) |>
  left_join(lu_mediatype, by = c("mediatype_id" = "id")) |>
  left_join(lu_testtype, by = c("testtype_id" = "id")) |>
  left_join(
    raw_chemical,
    by = c("chemical_id" = "id"),
    suffix = c("", "_chemical")
  ) |>
  left_join(
    raw_species,
    by = c("species_id" = "id"),
    suffix = c("", "_species")
  ) |>
  left_join(lu_endpoint, by = c("endpoint_id" = "id")) |>
  mutate(
    casnumber = as.character(casnumber),
    mediatype = normalize_mediatype(mediatype),
    endpoint = name.y,
    testtype = as.character(testtype),
    source_dataset = "2000"
  ) |>
  select(
    toxicityvalue_id,
    casnumber,
    commonname,
    mediatype,
    scientificname,
    majorgroup,
    endpoint,
    testtype,
    concentrationused,
    source_dataset
  )

message("toxicityvalue2000 rows: ", nrow(tox2000))

# --- toxicityvalue2016 ---
raw_2016 <- dbReadTable(con, "toxicityvalue2016")

tox2016 <- raw_2016 |>
  left_join(raw_toxicityvalue, by = c("toxicityvalue_id" = "id")) |>
  left_join(lu_mediatype, by = c("mediatype_id" = "id")) |>
  left_join(
    lu_endpoint |>
      rename(endpoint_measured = name, abbreviation_measured = abbreviation),
    by = c("endpointmeasurement_id" = "id")
  ) |>
  left_join(
    lu_endpoint |>
      rename(endpoint_paper = name, abbreviation_paper = abbreviation),
    by = c("endpointfrompaper_id" = "id")
  ) |>
  left_join(
    raw_chemical,
    by = c("chemical_id" = "id"),
    suffix = c("", "_chemical")
  ) |>
  left_join(
    raw_species,
    by = c("species_id" = "id"),
    suffix = c("", "_species")
  ) |>
  mutate(endpoint_raw = coalesce(endpoint_measured, endpoint_paper)) |>
  left_join(
    endpoint_2016_to_2000_lookup_dedup,
    by = c("endpoint_raw" = "endpoint_2016_raw")
  ) |>
  mutate(
    casnumber = as.character(casnumber),
    mediatype = normalize_mediatype(mediatype),
    # Map 2016 free-text endpoint to 2000 code where possible; retain raw
    # label as fallback
    endpoint = coalesce(endpoint_2000_code, endpoint_raw),
    # Derive testtype from ischronic boolean (no testtype FK in 2016 table)
    testtype = if_else(ischronic %in% TRUE, "Chronic", "Acute"),
    source_dataset = "2016"
  ) |>
  select(
    toxicityvalue_id,
    casnumber,
    commonname,
    mediatype,
    scientificname,
    majorgroup,
    endpoint,
    testtype,
    concentrationused,
    source_dataset
  )

message("toxicityvalue2016 rows: ", nrow(tox2016))

# --- Combine ---
tox_combined <- bind_rows(tox2000, tox2016)
message("Combined rows: ", nrow(tox_combined))

# =============================================================================
# STEP 3 -- Apply CAS parent lookup
# =============================================================================

# CRITICAL: use the MASTER lookup at data-raw/ level, NOT data-raw/anztox/
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

tox_combined <- tox_combined |>
  left_join(
    cas_parent_lookup |>
      transmute(
        casnumber = as.character(casnumber),
        parent_casnumber = as.character(parent_casnumber),
        parent_name = as.character(parent_name)
      ),
    by = "casnumber"
  ) |>
  mutate(
    casnumber_grouped = coalesce(parent_casnumber, casnumber),
    chemicalname_grouped = coalesce(parent_name, commonname)
  )

# =============================================================================
# STEP 4 -- Apply base filters
# =============================================================================

n_before <- nrow(tox_combined)

drop_conc <- sum(
  is.na(tox_combined$concentrationused) |
    (!is.na(tox_combined$concentrationused) &
      tox_combined$concentrationused <= 0)
)
drop_species <- sum(is.na(tox_combined$scientificname))
drop_testtype <- sum(is.na(tox_combined$testtype))
drop_mediatype <- sum(is.na(tox_combined$mediatype))
drop_cas <- sum(is.na(tox_combined$casnumber_grouped))

message("\n--- Base filter drops (not mutually exclusive) ---")
message("  concentrationused NA or <= 0: ", drop_conc)
message("  scientificname NA: ", drop_species)
message("  testtype NA: ", drop_testtype)
message("  mediatype NA: ", drop_mediatype)
message("  casnumber_grouped NA: ", drop_cas)

tox_filtered <- tox_combined |>
  filter(
    !is.na(concentrationused),
    concentrationused > 0,
    !is.na(scientificname),
    !is.na(testtype),
    !is.na(mediatype),
    !is.na(casnumber_grouped)
  )

message(
  "Rows surviving all filters: ",
  nrow(tox_filtered),
  " (dropped ",
  n_before - nrow(tox_filtered),
  " of ",
  n_before,
  ")"
)

# =============================================================================
# STEP 5 -- Classify test_class (with Decision B1)
# =============================================================================

tox_classified <- tox_filtered |>
  mutate(
    testtype_norm = str_to_lower(str_squish(testtype)),
    test_class = case_when(
      testtype_norm == "chronic" ~ "chronic",
      str_detect(testtype_norm, "sub[ -]?chronic|subchronic") ~ "subchronic",
      testtype_norm == "acute" ~ "acute",
      testtype_norm == "chronic qsar" ~ "QSAR_DROP",
      TRUE ~ "OTHER_DROP"
    )
  )

# Decision B1: Drop "Chronic QSAR" -- QSAR-predicted values are not appropriate
# for SSD fitting alongside measured data.
n_qsar <- sum(tox_classified$test_class == "QSAR_DROP")
message(
  "\nDecision B1: Dropping ",
  n_qsar,
  " 'Chronic QSAR' rows -- ",
  "QSAR-predicted values are not appropriate for SSD fitting ",
  "alongside measured data."
)

n_other <- sum(tox_classified$test_class == "OTHER_DROP")
message("Dropping ", n_other, " rows with unclassified testtype ('other').")

tox_classified <- tox_classified |>
  filter(!test_class %in% c("QSAR_DROP", "OTHER_DROP"))

message("Rows after test_class classification: ", nrow(tox_classified))

# =============================================================================
# STEP 6 -- Populate output columns
# =============================================================================

output <- tox_classified |>
  transmute(
    source = "anztox",
    casnumber_grouped,
    chemicalname_grouped,
    scientificname,
    medium = mediatype,
    test_class,
    endpoint,
    conc_value = concentrationused,
    # Decision A1: all rows assigned "ug/L" -- confirmed for source_dataset ==
    # "2000" (99.77% of rows tagged ug/L in the raw concentrationunit table,
    # ratio ~ 1 for 90.6% of comparable rows) and assumed for source_dataset ==
    # "2016" (~14% of combined rows, unit convention unconfirmed by the DB audit)
    conc_unit = "ug/L",
    # Decision C1: acr_eligible approximation -- TRUE where endpoint is MORT or
    # IMM (proxied as LC50/EC50-type endpoints); anztox retains no separate
    # statistic-type field
    acr_eligible = endpoint %in% c("MORT", "IMM"),
    source_id = as.character(toxicityvalue_id),
    # Supplementary column: retained for QC and units confidence flagging
    source_dataset,
    # Supplementary column: retained unharmonised for Stage 4d eligibility
    # checks; the DB audit confirmed this field mixes 2-letter codes and full
    # taxonomic names as an internal species-table inconsistency, not a
    # 2000-vs-2016 artefact
    majorgroup
  )

# =============================================================================
# STEP 7 -- Sanity checks and write output
# =============================================================================

message("\n--- Sanity checks ---")
message("Total rows: ", nrow(output))

message("\nBy source_dataset:")
print(count(output, source_dataset))

message("\nBy test_class:")
print(count(output, test_class))

message("\nBy medium:")
print(count(output, medium))

message("\nDistinct casnumber_grouped: ", n_distinct(output$casnumber_grouped))
message("NA casnumber_grouped: ", sum(is.na(output$casnumber_grouped)))

n_bad_conc <- sum(is.na(output$conc_value) | output$conc_value <= 0)
message("NA or <= 0 conc_value: ", n_bad_conc)
if (n_bad_conc > 0) {
  stop(
    "FATAL: found ",
    n_bad_conc,
    " rows with NA or non-positive conc_value after filtering -- ",
    "this should not happen."
  )
}

# Write output
write_csv(output, "data-raw/alldata/anztox_extracted.csv")
message("\nWrote: data-raw/alldata/anztox_extracted.csv")

# Disconnect database
DBI::dbDisconnect(con)
message("Done.")
