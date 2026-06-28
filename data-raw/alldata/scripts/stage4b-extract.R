# =============================================================================
# scripts/stage4b-extract.R
# =============================================================================
# Purpose:
#   Stage 4b (revised) -- extract filtered-but-unaggregated records from all
#   three uncurated sources (anztox, wqbench, envirotox) onto a single
#   17-column common schema rich enough to support ANZG-compliant duplicate
#   detection (Stage 4c) and aggregation (Stage 4d): statistic_type,
#   duration_hours, effect_category, life_stage, and study_reference are the
#   fields the original 11-column Stage 4b schema lacked.
#
#   This script REPLACES both scripts/stage4b-anztox-extract.R and
#   scripts/stage4b-combine.R. Those two scripts and their outputs are
#   superseded by this run.
#
# Inputs:
#   - Local PostgreSQL "infogathering" database (toxicityvalue,
#     toxicityvalue2000, toxicityvalue2016, and all associated lookup tables:
#     chemical, species, mediatype, testtype, effect, endpoint, age,
#     duration, durationunit, reference)
#   - data-raw/anztox/endpoint_2016_to_2000_lookup.csv (2016 free-text
#     endpoint labels -> 2000 endpoint codes)
#   - data-raw/cas_parent_lookup_all.csv (master CAS parent lookup -- NOT
#     data-raw/anztox/cas_parent_lookup_all.csv)
#   - data-raw/wqbench/ecotox_ascii_12_11_2025.rds
#   - data-raw/envirotox/envirotox.xlsx (sheets "test", "substance")
#
# Outputs:
#   - data-raw/alldata/anztox_extracted.csv          (19 cols: 17 common + 2 supplementary)
#   - data-raw/alldata/uncurated_raw_combined.csv     (17 cols, common schema)
#   - data-raw/alldata/envirotox_effect_category_map.csv (effect-category mapping audit trail)
#
# Decisions implemented (see CLAUDE.md Section 5 "Key design decisions" and
# scripts/stage4c-schema-inventory.md for full rationale):
#   A1 -- anztox concentrationused units: "ug/L" for all rows. Confirmed for
#         source_dataset == "2000"; assumed for source_dataset == "2016"
#         (unit convention unconfirmed by the Stage 4a DB audit).
#   B1 -- anztox "Chronic QSAR" testtype rows: dropped explicitly. QSAR-
#         predicted values are not appropriate for SSD fitting alongside
#         measured data.
#   D-E -- anztox statistic_type structural difference: 2000 uses
#          effectused_id (curator-selected, narrower vocabulary), 2016 uses
#          effect_id (raw value, from the base toxicityvalue table) -- these
#          are NOT necessarily directly comparable across the two anztox
#          sub-datasets.
#   D-F (Decision F) -- acr_eligible: TRUE where
#          toupper(trimws(statistic_type)) %in% c("EC50", "LC50", "IC50").
#          Replaces the original Stage 4b's MORT/IMM endpoint-code proxy,
#          which was a workaround for anztox alone not retaining a separate
#          statistic-type field -- now resolved by extracting statistic_type
#          properly for all three sources.
#   K (added 2026-06-24, during Stage 4c Part 2) -- wqbench source_id fixed
#          to be row-unique (as.character(row_number())), matching the
#          convention already used for anztox (toxicityvalue_id) and
#          envirotox (row_number()). It was previously
#          paste0(species_number, "_", cas), a (species, chemical)-pair
#          identifier shared by every distinct study/endpoint record for
#          that pair -- discovered when Stage 4c Part 2's within-source
#          duplicate diagnostic found wqbench had no row-unique field at
#          all, masking genuinely separate records (e.g. one paper
#          reporting ~180 distinct gene-expression endpoints, all sharing
#          source_id, study_reference, and conc_value once collapsed onto
#          this schema's coarse effect_category vocabulary).
#
# NOTE: This script requires a live connection to the infogathering
#       PostgreSQL instance and must be run from Windows Positron, where that
#       connection is available. It is NOT part of the package build
#       pipeline (it is not sourced by any DATASET.R).
# =============================================================================

library(dplyr)
library(stringr)
library(tidyr)
library(DBI)
library(RPostgres)
library(readr)
library(openxlsx)
library(purrr)

# =============================================================================
# HELPERS
# =============================================================================

# Reproduced verbatim from data-raw/anztox/DATASET.R (not sourced from there,
# per the task constraint against sourcing/modifying DATASET.R).
normalize_cas <- function(x) {
  x |>
    as.character() |>
    str_squish() |>
    na_if("") |>
    na_if("-") |>
    str_replace("^([0-9]+)-([0-9]{2})-0([0-9])$", "\\1-\\2-\\3") |>
    str_replace_all("[^0-9]", "") |>
    str_replace("^0+", "") |>
    na_if("")
}

normalize_mediatype <- function(x) {
  x |>
    as.character() |>
    str_squish() |>
    str_to_lower() |>
    recode(
      "freshwater" = "Freshwater",
      "marine" = "Marine",
      "marine water" = "Marine",
      .default = NA_character_
    )
}

# Reproduced verbatim from data-raw/anztox/DATASET.R.
build_reference_bib <- function(
  authors,
  authorsabbreviated,
  year,
  title,
  journal,
  volume,
  issuenumber,
  firstpage,
  lastpage
) {
  str_squish(
    paste0(
      coalesce(authors, authorsabbreviated, ""),
      ifelse(
        !is.na(coalesce(authors, authorsabbreviated)) &
          coalesce(authors, authorsabbreviated) != "",
        " ",
        ""
      ),
      ifelse(!is.na(year), paste0("(", year, "). "), ""),
      ifelse(!is.na(title) & title != "", paste0(title, ". "), ""),
      ifelse(!is.na(journal) & journal != "", journal, ""),
      ifelse(!is.na(volume), paste0(", ", volume), ""),
      ifelse(!is.na(issuenumber), paste0("(", issuenumber, ")"), ""),
      ifelse(!is.na(firstpage), paste0(": ", firstpage), ""),
      ifelse(!is.na(lastpage), paste0("–", lastpage), ""),
      "."
    )
  ) |>
    na_if(".")
}

# Converts a numeric duration value to hours given an anztox `durationunit`
# lookup name. Matched case-insensitively since 2000 and 2016 use different
# capitalisation conventions ("Hours" vs "H", "Days" vs "D").
convert_duration_to_hours <- function(value, unit) {
  value_num <- suppressWarnings(as.numeric(value))
  unit_norm <- str_to_lower(str_squish(as.character(unit)))
  case_when(
    unit_norm %in% c("hours", "h") ~ value_num,
    unit_norm == "minutes" ~ value_num / 60,
    unit_norm %in% c("days", "d") ~ value_num * 24,
    unit_norm == "weeks" ~ value_num * 168,
    unit_norm == "months" ~ value_num * 730,
    unit_norm %in% c("year", "years") ~ value_num * 8760,
    TRUE ~ NA_real_
  )
}

# Diagnostic for convert_duration_to_hours() NAs -- distinguishes a genuinely
# unrecognised unit (e.g. a new durationunit lookup value) from a value that
# simply fails numeric coercion (e.g. free-text ranges like "7-14" that occur
# in a handful of anztox 2016 duration rows under an otherwise-valid "Days"
# unit) so the two distinct causes aren't conflated in the report.
report_duration_na_causes <- function(df, label) {
  known_units <- c(
    "hours", "h", "minutes", "days", "d", "weeks", "months", "year", "years"
  )
  na_rows <- df |>
    filter(!is.na(duration_value_raw), is.na(duration_hours))
  unrecognised_units <- na_rows |>
    filter(!str_to_lower(str_squish(durationunit_name)) %in% known_units) |>
    distinct(durationunit_name) |>
    pull(durationunit_name)
  nonnumeric_values <- na_rows |>
    filter(str_to_lower(str_squish(durationunit_name)) %in% known_units) |>
    distinct(duration_value_raw) |>
    pull(duration_value_raw)
  if (length(unrecognised_units) > 0) {
    message(
      "WARNING: ",
      label,
      " -- unrecognised duration unit(s): ",
      paste(unrecognised_units, collapse = ", ")
    )
  }
  if (length(nonnumeric_values) > 0) {
    message(
      "WARNING: ",
      label,
      " -- duration value(s) under a recognised unit that fail numeric ",
      "coercion (e.g. free-text ranges): ",
      paste(nonnumeric_values, collapse = ", ")
    )
  }
}

# anztox 2016 life_stage and wqbench lifestage both use "Not stated"-style
# placeholder text for missing values, but with source-specific variant
# spellings -- two separate normalisers rather than one shared one.
normalize_life_stage_anztox <- function(x) {
  x_norm <- str_to_lower(str_squish(x))
  if_else(
    x_norm %in% c("not stated", "not-stated", "not reported", "not coded"),
    NA_character_,
    x
  )
}

normalize_life_stage_wqbench <- function(x) {
  x_norm <- str_to_lower(str_squish(x))
  if_else(x_norm %in% c("not reported", "not coded"), NA_character_, x)
}

# Keyword-based mapping from envirotox's free-text `Effect` field to a
# controlled vocabulary consistent with anztox's/wqbench's effect categories.
# Priority order matters -- e.g. "Mortality/Growth" matches MORT (checked
# first), not GRO. Lowercased/punctuation-stripped text is matched against
# each pattern in turn; the first match wins.
normalise_effect_text <- function(x) {
  x |>
    str_to_lower() |>
    str_replace_all("[^a-z0-9]+", " ") |>
    str_squish()
}

envirotox_effect_category_rules <- tibble::tribble(
  ~effect_category_mapped, ~mapping_rule,
  "MORT", "mortal|surviv|lethali|death|lethal",
  # A3: "area" narrowed to (?<!unit )area so "per unit area" (in Abundance definition)
  # no longer triggers GRO before the ABD rule can fire.
  "GRO",  "growth|biomass|yield|length|weight|(?<!unit )area",
  "REP",  "reproduc|fertil|offspring|fecund|brood|egg|spawn",
  "IMM",  "immobil|mobil",
  "DVP",  "develop|metamorph|differentiat",
  "HAT",  "hatch",
  "PSE",  "photosyn|chlorophyll|pigment|physiol",
  # A3: ABD for standalone Abundance terms whose normalised description starts with
  # "abundance" (i.e. the term name is "Abundance: ..."). "Population, Abundance"
  # starts with "population" so it falls through to POP below — unchanged.
  "ABD",  "^abundance",
  "POP",  "populat|abundance|densit",
  "LUM",  "lumines|biolumines",
  "BEH",  "behaviour|behavior|avoidance|locomot",
  "BCH",  "biochem|enzyme|protein|lipid|hormone|oxidat",
  "MOR",  "morphol|deform|malform"
)

classify_envirotox_effect_one <- function(text) {
  for (i in seq_len(nrow(envirotox_effect_category_rules))) {
    if (str_detect(text, envirotox_effect_category_rules$mapping_rule[i])) {
      return(envirotox_effect_category_rules[i, ])
    }
  }
  tibble::tibble(effect_category_mapped = "OTHER", mapping_rule = "unmatched")
}

# =============================================================================
# COMMON SCHEMA
# =============================================================================

common_cols <- c(
  "source",
  "native_cas",
  "casnumber_grouped",
  "chemicalname_grouped",
  "scientificname",
  "medium",
  "test_class",
  "statistic_type",
  "effect_category",
  "duration_hours",
  "life_stage",
  "conc_value",
  "conc_unit",
  "acr_eligible",
  "study_reference",
  "source_id",
  "acr_applied"
)

# Master CAS parent lookup -- NOT data-raw/anztox/cas_parent_lookup_all.csv.
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
) |>
  transmute(
    casnumber = as.character(casnumber),
    parent_casnumber = as.character(parent_casnumber),
    parent_name = as.character(parent_name)
  )

apply_cas_parent_lookup <- function(df, native_cas_col, name_fallback_col) {
  df |>
    left_join(cas_parent_lookup, by = setNames("casnumber", native_cas_col)) |>
    mutate(
      casnumber_grouped = coalesce(parent_casnumber, .data[[native_cas_col]]),
      chemicalname_grouped = coalesce(parent_name, .data[[name_fallback_col]])
    ) |>
    select(-parent_casnumber, -parent_name)
}

# =============================================================================
# STEP 3 -- ANZTOX EXTRACTION
# =============================================================================

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

con <- DBI::dbConnect(
  RPostgres::Postgres(),
  dbname = "infogathering",
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = get_db_password()
)
on.exit(DBI::dbDisconnect(con), add = TRUE)

if (!DBI::dbIsValid(con)) {
  stop("Database connection is not valid")
}
message("Connected to infogathering database.")

# --- shared lookup tables ---
raw_toxicityvalue <- dbReadTable(con, "toxicityvalue")
raw_chemical <- dbReadTable(con, "chemical")
raw_species <- dbReadTable(con, "species")
lu_mediatype <- dbReadTable(con, "mediatype") |> rename(mediatype = name)
lu_testtype <- dbReadTable(con, "testtype") |> rename(testtype = name)
lu_effect <- dbReadTable(con, "effect")
lu_endpoint <- dbReadTable(con, "endpoint")
lu_age <- dbReadTable(con, "age") |> rename(life_stage_raw = name)
lu_duration <- dbReadTable(con, "duration") |> rename(duration_value_raw = name)
lu_durationunit <- dbReadTable(con, "durationunit") |>
  rename(durationunit_name = name)
lu_reference <- dbReadTable(con, "reference")

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

endpoint_lookup_duplicates <- endpoint_2016_to_2000_lookup |>
  distinct(endpoint_2016_raw, endpoint_2000_code) |>
  count(endpoint_2016_raw, name = "n_codes") |>
  filter(n_codes > 1)
if (nrow(endpoint_lookup_duplicates) > 0) {
  stop(
    "endpoint_2016_to_2000_lookup has non-unique endpoint_2016_raw mappings: ",
    paste(endpoint_lookup_duplicates$endpoint_2016_raw, collapse = ", ")
  )
}
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

# -----------------------------------------------------------------------------
# 3a -- toxicityvalue2000
# -----------------------------------------------------------------------------
raw_2000 <- dbReadTable(con, "toxicityvalue2000")

tox2000 <- raw_2000 |>
  left_join(raw_toxicityvalue, by = c("toxicityvalue_id" = "id")) |>
  left_join(lu_mediatype, by = c("mediatype_id" = "id")) |>
  left_join(lu_testtype, by = c("testtype_id" = "id")) |>
  left_join(
    lu_effect |> rename(effectused_name = name),
    by = c("effectused_id" = "id")
  ) |>
  left_join(
    lu_effect |> rename(effect_raw_name = name),
    by = c("effect_id" = "id")
  ) |>
  left_join(
    lu_endpoint |> select(id, effect_category_2000 = name),
    by = c("endpoint_id" = "id")
  ) |>
  left_join(
    raw_chemical |> select(id, casnumber, commonname),
    by = c("chemical_id" = "id")
  ) |>
  left_join(
    raw_species |> select(id, scientificname, majorgroup),
    by = c("species_id" = "id")
  ) |>
  left_join(lu_duration, by = c("duration_id" = "id")) |>
  left_join(lu_durationunit, by = c("durationunit_id" = "id")) |>
  left_join(lu_reference, by = c("reference_id" = "id")) |>
  mutate(
    native_cas = normalize_cas(casnumber),
    medium = normalize_mediatype(mediatype),
    testtype = as.character(testtype),
    # statistic_type: curator-selected effectused_id preferred; fall back to
    # the raw effect_id value where effectused_id is NA (Decision D-E).
    statistic_type = str_to_upper(str_squish(
      coalesce(effectused_name, effect_raw_name)
    )),
    effect_category = effect_category_2000,
    duration_hours = convert_duration_to_hours(
      duration_value_raw,
      durationunit_name
    ),
    life_stage = NA_character_,
    conc_value = concentrationused,
    study_reference = build_reference_bib(
      authors,
      authorsabbreviated,
      year,
      title,
      journal,
      volume,
      issuenumber,
      firstpage,
      lastpage
    ),
    source_id = as.character(toxicityvalue_id),
    source_dataset = "2000"
  )

message("toxicityvalue2000 rows: ", nrow(tox2000))

report_duration_na_causes(tox2000, "2000")

# -----------------------------------------------------------------------------
# 3b -- toxicityvalue2016
# -----------------------------------------------------------------------------
raw_2016 <- dbReadTable(con, "toxicityvalue2016")

# Reference resolution for 2016 -- replicated from DATASET.R lines 285-393.
# 2016 has no reference_id FK; datasource/record free-text fields are
# regex-matched against lu_reference$orgrefnumber as a best-effort proxy.
reference_orgref_unique <- lu_reference |>
  filter(!is.na(orgrefnumber)) |>
  add_count(orgrefnumber, name = "n_ref_per_org") |>
  filter(n_ref_per_org == 1) |>
  select(
    orgrefnumber,
    authors,
    authorsabbreviated,
    title,
    journal,
    year,
    volume,
    issuenumber,
    firstpage,
    lastpage
  )

ref_keys_2016 <- raw_2016 |>
  transmute(
    toxicityvalue_id,
    datasource,
    record,
    datasource_num = suppressWarnings(as.integer(str_extract(
      datasource,
      "\\d+"
    ))),
    record_num = suppressWarnings(as.integer(str_extract(record, "\\d+")))
  )

ref_from_datasource <- ref_keys_2016 |>
  left_join(
    reference_orgref_unique,
    by = c("datasource_num" = "orgrefnumber")
  ) |>
  transmute(
    toxicityvalue_id,
    ref_authors_ds = authors,
    ref_authabbr_ds = authorsabbreviated,
    ref_title_ds = title,
    ref_journal_ds = journal,
    ref_year_ds = year,
    ref_volume_ds = volume,
    ref_issue_ds = issuenumber,
    ref_firstpage_ds = firstpage,
    ref_lastpage_ds = lastpage
  )

ref_from_record <- ref_keys_2016 |>
  left_join(reference_orgref_unique, by = c("record_num" = "orgrefnumber")) |>
  transmute(
    toxicityvalue_id,
    ref_authors_rec = authors,
    ref_authabbr_rec = authorsabbreviated,
    ref_title_rec = title,
    ref_journal_rec = journal,
    ref_year_rec = year,
    ref_volume_rec = volume,
    ref_issue_rec = issuenumber,
    ref_firstpage_rec = firstpage,
    ref_lastpage_rec = lastpage
  )

ref_2016_best <- ref_keys_2016 |>
  select(toxicityvalue_id, datasource, record) |>
  left_join(ref_from_datasource, by = "toxicityvalue_id") |>
  left_join(ref_from_record, by = "toxicityvalue_id") |>
  mutate(
    ref_authors = coalesce(ref_authors_ds, ref_authors_rec),
    ref_authabbr = coalesce(ref_authabbr_ds, ref_authabbr_rec),
    ref_title = coalesce(ref_title_ds, ref_title_rec),
    ref_journal = coalesce(ref_journal_ds, ref_journal_rec),
    ref_year = coalesce(ref_year_ds, ref_year_rec),
    ref_volume = coalesce(ref_volume_ds, ref_volume_rec),
    ref_issue = coalesce(ref_issue_ds, ref_issue_rec),
    ref_firstpage = coalesce(ref_firstpage_ds, ref_firstpage_rec),
    ref_lastpage = coalesce(ref_lastpage_ds, ref_lastpage_rec),
    reference_bib = build_reference_bib(
      ref_authors,
      ref_authabbr,
      ref_year,
      ref_title,
      ref_journal,
      ref_volume,
      ref_issue,
      ref_firstpage,
      ref_lastpage
    )
  ) |>
  select(toxicityvalue_id, reference_bib)

tox2016 <- raw_2016 |>
  left_join(raw_toxicityvalue, by = c("toxicityvalue_id" = "id")) |>
  left_join(lu_mediatype, by = c("mediatype_id" = "id")) |>
  left_join(
    lu_endpoint |> select(id, endpoint_measured = name),
    by = c("endpointmeasurement_id" = "id")
  ) |>
  left_join(
    lu_endpoint |> select(id, endpoint_paper = name),
    by = c("endpointfrompaper_id" = "id")
  ) |>
  left_join(
    raw_chemical |> select(id, casnumber, commonname),
    by = c("chemical_id" = "id")
  ) |>
  left_join(
    raw_species |> select(id, scientificname, majorgroup),
    by = c("species_id" = "id")
  ) |>
  # statistic_type for 2016: effect_id from the base toxicityvalue table (no
  # effectused_id exists for 2016 -- Decision D-E).
  left_join(
    lu_effect |> rename(effect_2016_name = name),
    by = c("effect_id" = "id")
  ) |>
  left_join(lu_duration, by = c("duration_id" = "id")) |>
  left_join(lu_durationunit, by = c("durationunit_id" = "id")) |>
  left_join(lu_age, by = c("age_id" = "id")) |>
  left_join(ref_2016_best, by = "toxicityvalue_id") |>
  filter(scientificname != "-") |>
  mutate(endpoint_raw = coalesce(endpoint_measured, endpoint_paper)) |>
  left_join(
    endpoint_2016_to_2000_lookup_dedup,
    by = c("endpoint_raw" = "endpoint_2016_raw")
  ) |>
  mutate(
    native_cas = normalize_cas(casnumber),
    medium = normalize_mediatype(mediatype),
    testtype = if_else(ischronic %in% TRUE, "Chronic", "Acute"),
    statistic_type = str_to_upper(str_squish(effect_2016_name)),
    effect_category = coalesce(endpoint_2000_code, endpoint_raw),
    duration_hours = convert_duration_to_hours(
      duration_value_raw,
      durationunit_name
    ),
    life_stage = normalize_life_stage_anztox(life_stage_raw),
    conc_value = concentrationused,
    study_reference = coalesce(
      reference_bib,
      paste0("group_", guidelinegroup_id)
    ),
    source_id = as.character(toxicityvalue_id),
    source_dataset = "2016"
  )

message("toxicityvalue2016 rows: ", nrow(tox2016))

report_duration_na_causes(tox2016, "2016")

# -----------------------------------------------------------------------------
# 3c-3f -- combine, CAS lookup, base filters, test_class, acr_eligible
# -----------------------------------------------------------------------------

shared_cols_2000 <- c(
  "source_dataset",
  "native_cas",
  "commonname",
  "medium",
  "scientificname",
  "majorgroup",
  "testtype",
  "statistic_type",
  "effect_category",
  "duration_hours",
  "life_stage",
  "conc_value",
  "study_reference",
  "source_id"
)

anztox_combined <- bind_rows(
  tox2000 |> select(all_of(shared_cols_2000)),
  tox2016 |> select(all_of(shared_cols_2000))
) |>
  apply_cas_parent_lookup("native_cas", "commonname")

# --- 3d: base filters ---
n_before <- nrow(anztox_combined)
message("\n--- anztox base filter drops (not mutually exclusive) ---")
message(
  "  concentrationused (conc_value) NA or <= 0: ",
  sum(is.na(anztox_combined$conc_value) | anztox_combined$conc_value <= 0)
)
message("  scientificname NA: ", sum(is.na(anztox_combined$scientificname)))
message("  testtype NA: ", sum(is.na(anztox_combined$testtype)))
message("  medium NA: ", sum(is.na(anztox_combined$medium)))
message(
  "  casnumber_grouped NA: ",
  sum(is.na(anztox_combined$casnumber_grouped))
)

anztox_filtered <- anztox_combined |>
  filter(
    !is.na(conc_value),
    conc_value > 0,
    !is.na(scientificname),
    !is.na(testtype),
    !is.na(medium),
    !is.na(casnumber_grouped)
  )
message(
  "Rows surviving base filters: ",
  nrow(anztox_filtered),
  " (dropped ",
  n_before - nrow(anztox_filtered),
  " of ",
  n_before,
  ")"
)

# --- 3e: test_class classification (Decision B1) ---
anztox_classified <- anztox_filtered |>
  mutate(
    testtype_norm = str_to_lower(str_squish(testtype)),
    test_class = case_when(
      testtype_norm == "chronic" ~ "chronic",
      str_detect(testtype_norm, "^sub[ -]?chronic$") ~ "subchronic",
      testtype_norm == "acute" ~ "acute",
      testtype_norm == "chronic qsar" ~ "QSAR_DROP",
      TRUE ~ "OTHER_DROP"
    )
  )

n_qsar <- sum(anztox_classified$test_class == "QSAR_DROP")
message(
  "\nDecision B1: dropping ",
  n_qsar,
  " 'Chronic QSAR' rows -- QSAR-predicted values are not appropriate for ",
  "SSD fitting alongside measured data."
)
n_other <- sum(anztox_classified$test_class == "OTHER_DROP")
message("Dropping ", n_other, " rows with unclassified testtype ('other').")

anztox_classified <- anztox_classified |>
  filter(!test_class %in% c("QSAR_DROP", "OTHER_DROP"))
message("Rows after test_class classification: ", nrow(anztox_classified))

# --- 3f: acr_eligible (Decision F) ---
# Replaces the MORT/IMM endpoint-code proxy used in the original Stage 4b,
# which existed only because anztox previously had no separate statistic-type
# field. statistic_type is now extracted directly (3a/3b above).
anztox_classified <- anztox_classified |>
  mutate(
    acr_eligible = if_else(
      is.na(statistic_type),
      NA,
      str_to_upper(str_squish(statistic_type)) %in% c("EC50", "LC50", "IC50")
    ),
    acr_applied = FALSE
  )

# -----------------------------------------------------------------------------
# 3g -- populate output columns, sanity checks, write
# -----------------------------------------------------------------------------
anztox_extracted <- anztox_classified |>
  transmute(
    source = "anztox",
    native_cas,
    casnumber_grouped,
    chemicalname_grouped,
    scientificname,
    medium,
    test_class,
    statistic_type,
    effect_category,
    duration_hours,
    life_stage,
    conc_value,
    # Decision A1: confirmed ug/L for source_dataset == "2000"; assumed for
    # "2016" (unit convention unconfirmed by the Stage 4a DB audit).
    conc_unit = "ug/L",
    acr_eligible,
    study_reference,
    source_id,
    acr_applied,
    source_dataset,
    majorgroup
  )

# Phase 2 — recode anztox ABD -> BEH (avoidance/behaviour, not abundance).
# lu_endpoint id=175 (name="ABD") is documented as "Avoidance / behaviour" in
# endpoint_2016_to_2000_lookup_build_v2.md; "Abundance" is a separate lu_endpoint
# entry (id=216). After this recode, the unified ABD code means *abundance only*
# (driven by the envirotox A3 rule). BEH is excluded by Stage 4e's B1
# non-traditional filter, which is the intended outcome.
n_abd_recoded <- sum(anztox_extracted$effect_category == "ABD", na.rm = TRUE)
anztox_extracted <- anztox_extracted |>
  mutate(
    effect_category = if_else(
      effect_category == "ABD",
      "BEH",
      effect_category
    )
  )
message(
  "\nPhase 2 anztox ABD->BEH recode: ", n_abd_recoded, " rows recoded ",
  "(source=anztox only; envirotox Abundance->ABD rule unaffected)"
)

message("\n=== anztox_extracted.csv sanity checks ===")
message("Total rows: ", nrow(anztox_extracted))
message("\nBy test_class:")
print(count(anztox_extracted, test_class))
message("\nBy medium:")
print(count(anztox_extracted, medium))
message("\nBy source_dataset:")
print(count(anztox_extracted, source_dataset))
message(
  "\nNA statistic_type: ",
  sum(is.na(anztox_extracted$statistic_type))
)
message("NA duration_hours: ", sum(is.na(anztox_extracted$duration_hours)))
message("NA life_stage: ", sum(is.na(anztox_extracted$life_stage)))
message("NA acr_eligible: ", sum(is.na(anztox_extracted$acr_eligible)))

n_bad_conc_anztox <- sum(
  is.na(anztox_extracted$conc_value) | anztox_extracted$conc_value <= 0
)
if (n_bad_conc_anztox > 0) {
  stop(
    "FATAL: ",
    n_bad_conc_anztox,
    " anztox rows with NA or non-positive conc_value after filtering."
  )
}

dir.create("data-raw/alldata", showWarnings = FALSE, recursive = TRUE)
write_csv(anztox_extracted, "data-raw/alldata/anztox_extracted.csv")
message("\nWrote: data-raw/alldata/anztox_extracted.csv")

# =============================================================================
# STEP 4 -- WQBENCH EXTRACTION
# =============================================================================

wqbench_rds_expected <- "data-raw/wqbench/ecotox_ascii_12_11_2025.rds"
if (!file.exists(wqbench_rds_expected)) {
  stop("Expected wqbench RDS not found: ", wqbench_rds_expected)
}
wqbench_raw <- readRDS(wqbench_rds_expected)

n_wqbench_expected <- 361817
ncol_wqbench_expected <- 24
if (
  abs(nrow(wqbench_raw) - n_wqbench_expected) / n_wqbench_expected > 0.05
) {
  warning(
    "wqbench RDS row count (",
    nrow(wqbench_raw),
    ") differs from the expected ~",
    n_wqbench_expected,
    " by more than 5%. Continuing."
  )
}
if (ncol(wqbench_raw) != ncol_wqbench_expected) {
  warning(
    "wqbench RDS column count (",
    ncol(wqbench_raw),
    ") differs from the expected ",
    ncol_wqbench_expected,
    ". Continuing."
  )
}
message(
  "\n--- wqbench RDS loaded: ",
  wqbench_rds_expected,
  " (",
  nrow(wqbench_raw),
  " rows x ",
  ncol(wqbench_raw),
  " cols) ---"
)

wqbench_mapped <- wqbench_raw |>
  mutate(
    native_cas = normalize_cas(cas),
    # 4b: statistic_type is wqbench's own `endpoint` field (LC50/EC50/NOEC/...).
    statistic_type = str_to_upper(str_squish(endpoint)),
    # 4c: effect_category is wqbench's `effect` field, retained as-is.
    effect_category = effect,
    # 4d
    duration_hours = suppressWarnings(as.numeric(duration_hrs)),
    # 4e
    life_stage = normalize_life_stage_wqbench(lifestage),
    # 4f
    medium = case_when(
      media_type == "FW" ~ "Freshwater",
      media_type == "SW" ~ "Marine",
      TRUE ~ "Unknown"
    ),
    # 4g
    test_class = case_when(
      duration_class == "chronic" ~ "chronic",
      duration_class == "acute" ~ "acute",
      TRUE ~ duration_class
    ),
    # 4h: NA only where all four bibliographic fields are NA.
    study_reference = if_else(
      is.na(author) & is.na(title) & is.na(source) & is.na(publication_year),
      NA_character_,
      str_squish(paste(author, title, source, publication_year, sep = " | "))
    )
  )

message("\nwqbench duration_hrs NA count: ", sum(is.na(wqbench_mapped$duration_hours)))
message("\nwqbench medium counts:")
print(count(wqbench_mapped, medium))
message("\nwqbench test_class counts:")
print(count(wqbench_mapped, test_class))

# --- 4i: CAS parent lookup ---
wqbench_mapped <- wqbench_mapped |>
  apply_cas_parent_lookup("native_cas", "chemical_name")

# --- 4j: populate schema columns ---
conc_col <- "effect_conc_mg.L"
if (all(is.na(wqbench_mapped[[conc_col]]))) {
  message(
    "NOTE: effect_conc_mg.L is absent/all-NA; falling back to effect_conc_std_mg.L."
  )
  conc_col <- "effect_conc_std_mg.L"
}

wqbench_output <- wqbench_mapped |>
  mutate(
    conc_value = .data[[conc_col]],
    acr_eligible = if_else(
      is.na(statistic_type),
      NA,
      statistic_type %in% c("EC50", "LC50", "IC50")
    ),
    acr_applied = FALSE,
    # Row-unique identifier, matching the convention used for anztox
    # (toxicityvalue_id) and envirotox (row_number()) -- NOT
    # species_number/cas, which only identifies a (species, chemical) pair
    # and is shared by every distinct study/endpoint record for that pair
    # (confirmed empirically during Stage 4c Part 2: this was the reason
    # wqbench's within-source duplicate diagnostic could not distinguish
    # genuinely separate records at all).
    source_id = as.character(row_number())
  ) |>
  transmute(
    source = "wqbench",
    native_cas,
    casnumber_grouped,
    chemicalname_grouped,
    scientificname = latin_name,
    medium,
    test_class,
    statistic_type,
    effect_category,
    duration_hours,
    life_stage,
    conc_value,
    conc_unit = "mg/L",
    acr_eligible,
    study_reference,
    source_id,
    acr_applied
  )

n_bad_wqbench_conc <- sum(
  is.na(wqbench_output$conc_value) | wqbench_output$conc_value <= 0
)
if (n_bad_wqbench_conc > 0) {
  message(
    "Dropping ",
    n_bad_wqbench_conc,
    " wqbench rows with NA or non-positive conc_value."
  )
  wqbench_output <- wqbench_output |>
    filter(!is.na(conc_value), conc_value > 0)
}
message("\nwqbench output rows: ", nrow(wqbench_output))

# =============================================================================
# STEP 5 -- ENVIROTOX EXTRACTION
# =============================================================================

envirotox_test <- read.xlsx("data-raw/envirotox/envirotox.xlsx", sheet = "test")
envirotox_substance <- read.xlsx(
  "data-raw/envirotox/envirotox.xlsx",
  sheet = "substance"
)

n_envirotox_expected <- 80912
if (nrow(envirotox_test) != n_envirotox_expected) {
  warning(
    "envirotox test sheet row count (",
    nrow(envirotox_test),
    ") differs from the expected ",
    n_envirotox_expected,
    ". Continuing."
  )
}
message(
  "\n--- envirotox raw rows: test = ",
  nrow(envirotox_test),
  ", substance = ",
  nrow(envirotox_substance),
  " ---"
)

# --- 5b: statistic/type/solubility filter (reproduced exactly from DATASET.R) ---
envirotox_selected <- envirotox_test |>
  filter(
    (Test.statistic == "EC50" & Test.type == "A") |
      (Test.statistic == "LC50" & Test.type == "A") |
      (Test.statistic == "NOEC" & Test.type == "C") |
      (Test.statistic == "NOEL" & Test.type == "C")
  ) |>
  filter(Effect.is.5X.above.water.solubility == "0") |>
  mutate(source_id = as.character(row_number()))

message("Rows surviving statistic/type/solubility filter: ", nrow(envirotox_selected))

# --- 5c: statistic_type ---
envirotox_selected <- envirotox_selected |>
  mutate(statistic_type = str_to_upper(str_squish(Test.statistic)))

# --- 5d: effect_category mapping ---
effect_distinct <- envirotox_selected |>
  count(Effect, name = "n_rows") |>
  rename(raw_effect = Effect) |>
  mutate(normalised_effect_lower = normalise_effect_text(raw_effect))

effect_classified <- map_dfr(
  effect_distinct$normalised_effect_lower,
  classify_envirotox_effect_one
)

envirotox_effect_category_map <- bind_cols(effect_distinct, effect_classified) |>
  select(
    raw_effect,
    normalised_effect_lower,
    effect_category_mapped,
    n_rows,
    mapping_rule
  ) |>
  arrange(desc(n_rows))

write_csv(
  envirotox_effect_category_map,
  "data-raw/alldata/envirotox_effect_category_map.csv"
)
message("\nWrote: data-raw/alldata/envirotox_effect_category_map.csv")

n_other_values <- sum(envirotox_effect_category_map$effect_category_mapped == "OTHER")
message(
  "\nenvirotox effect_category: ",
  n_other_values,
  " distinct raw Effect value(s) mapped to OTHER (set to NA), covering ",
  sum(
    envirotox_effect_category_map$n_rows[
      envirotox_effect_category_map$effect_category_mapped == "OTHER"
    ]
  ),
  " rows. Values needing human review:"
)
print(
  envirotox_effect_category_map |>
    filter(effect_category_mapped == "OTHER") |>
    select(raw_effect, n_rows)
)

envirotox_selected <- envirotox_selected |>
  left_join(
    envirotox_effect_category_map |>
      select(Effect = raw_effect, effect_category_mapped),
    by = "Effect"
  ) |>
  mutate(
    effect_category = if_else(
      effect_category_mapped == "OTHER",
      NA_character_,
      effect_category_mapped
    )
  )

message("\nenvirotox effect_category distribution:")
print(count(envirotox_selected, effect_category))
message("NA effect_category rows: ", sum(is.na(envirotox_selected$effect_category)))

# --- 5e: duration_hours ---
n_nonnumeric_duration <- sum(
  is.na(suppressWarnings(as.numeric(envirotox_selected$`Duration.(hours)`))) &
    !is.na(envirotox_selected$`Duration.(hours)`) &
    envirotox_selected$`Duration.(hours)` != "NA"
)
message(
  "\nenvirotox non-numeric Duration (hours) values coerced to NA before this run: ",
  n_nonnumeric_duration
)
envirotox_selected <- envirotox_selected |>
  mutate(duration_hours = suppressWarnings(as.numeric(`Duration.(hours)`)))

# --- 5f: life_stage ---
envirotox_selected <- envirotox_selected |>
  mutate(life_stage = NA_character_)

# --- 5g: unit conversion and medium ---
envirotox_selected <- envirotox_selected |>
  mutate(
    Effect.value = Effect.value * 1000,
    medium = "Unknown"
  )

# --- 5h: test_class ---
envirotox_selected <- envirotox_selected |>
  mutate(
    test_class = case_when(
      Test.type == "A" ~ "acute",
      Test.type == "C" ~ "chronic"
    )
  )
message("\nenvirotox test_class counts:")
print(count(envirotox_selected, test_class))

# --- 5i: study_reference ---
envirotox_selected <- envirotox_selected |>
  mutate(study_reference = Source)

# --- 5j: CAS parent lookup ---
# native_cas is derived directly from the test sheet's own `original.CAS`
# column (confirmed present natively in scripts/stage4c-schema-inventory.md
# Step 3a -- no join to the substance sheet is needed to recover it). The
# substance sheet is still joined on original.CAS to recover the chemical
# name for the chemicalname_grouped fallback, exactly as in the original
# Stage 4b -- per the Stage 4a audit's explicit design decision, the
# substance sheet's own internal grouped `CAS` field (e.g. "Metalgrp.Ag") is
# bypassed in favour of cas_parent_lookup_all.csv as the sole chemical-
# grouping authority.
envirotox_selected <- envirotox_selected |>
  mutate(native_cas = normalize_cas(original.CAS)) |>
  left_join(
    envirotox_substance |>
      transmute(
        original.CAS = as.character(original.CAS),
        substance_chemical_name = Chemical.name
      ) |>
      mutate(original.CAS = normalize_cas(original.CAS)),
    by = c("native_cas" = "original.CAS")
  ) |>
  apply_cas_parent_lookup("native_cas", "substance_chemical_name")

# --- 5k: populate schema columns ---
envirotox_output <- envirotox_selected |>
  mutate(
    acr_eligible = if_else(
      is.na(statistic_type),
      NA,
      statistic_type %in% c("EC50", "LC50", "IC50")
    ),
    acr_applied = FALSE
  ) |>
  transmute(
    source = "envirotox",
    native_cas,
    casnumber_grouped,
    chemicalname_grouped,
    scientificname = Latin.name,
    medium,
    test_class,
    statistic_type,
    effect_category,
    duration_hours,
    life_stage,
    conc_value = Effect.value,
    conc_unit = "ug/L",
    acr_eligible,
    study_reference,
    source_id,
    acr_applied
  )

message("\nenvirotox output rows: ", nrow(envirotox_output))

# =============================================================================
# STEP 6 -- COMBINE AND WRITE uncurated_raw_combined.csv
# =============================================================================

# --- 6a: trim anztox to common schema ---
anztox_trimmed <- anztox_extracted |>
  select(-source_dataset, -majorgroup)

# --- 6b: validate schema alignment ---
for (nm in c("anztox_trimmed", "wqbench_output", "envirotox_output")) {
  df <- get(nm)
  if (!identical(names(df), common_cols)) {
    stop(
      nm,
      " does not match the common 17-column schema.\n",
      "Expected: ",
      paste(common_cols, collapse = ", "),
      "\n",
      "Found:    ",
      paste(names(df), collapse = ", ")
    )
  }
}

# --- 6c: row-bind ---
combined <- bind_rows(anztox_trimmed, wqbench_output, envirotox_output)

# --- 6d: sanity checks ---
message("\n=== Combined sanity checks ===")
message("\nRow count by source:")
print(count(combined, source))
message("\ntest_class distribution by source:")
print(count(combined, source, test_class))
message("\nmedium distribution by source:")
print(count(combined, source, medium))
message("\nstatistic_type distribution by source (top 10 each):")
combined |>
  count(source, statistic_type, sort = TRUE) |>
  group_by(source) |>
  slice_max(n, n = 10, with_ties = FALSE) |>
  ungroup() |>
  print(n = 30)
message("\neffect_category distribution by source:")
print(count(combined, source, effect_category))
message("\nNA duration_hours by source:")
print(combined |> group_by(source) |> summarise(n_na = sum(is.na(duration_hours))))
message("\nNA statistic_type by source:")
print(combined |> group_by(source) |> summarise(n_na = sum(is.na(statistic_type))))
message("\nNA life_stage by source:")
print(combined |> group_by(source) |> summarise(n_na = sum(is.na(life_stage))))
message("\nNA effect_category by source:")
print(combined |> group_by(source) |> summarise(n_na = sum(is.na(effect_category))))
message("\nNA casnumber_grouped by source:")
print(combined |> group_by(source) |> summarise(n_na = sum(is.na(casnumber_grouped))))

n_bad_conc <- sum(is.na(combined$conc_value) | combined$conc_value <= 0)
message("\nNA or <= 0 conc_value (combined): ", n_bad_conc)
if (n_bad_conc > 0) {
  stop(
    "FATAL: found ",
    n_bad_conc,
    " rows with NA or non-positive conc_value in the combined output."
  )
}

message("\nNA acr_eligible by source:")
print(combined |> group_by(source) |> summarise(n_na = sum(is.na(acr_eligible))))

# --- 6e: write output ---
write_csv(combined, "data-raw/alldata/uncurated_raw_combined.csv")
message("\nWrote: data-raw/alldata/uncurated_raw_combined.csv")
message("Total combined rows: ", nrow(combined))
