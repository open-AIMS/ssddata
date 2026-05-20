library(dplyr)
library(stringr)
library(tidyr)
library(DBI)
library(RPostgres)
library(readr)

# =============================================================================
# CONFIG
# =============================================================================
run_diagnostics <- TRUE
write_outputs <- TRUE

# Default acute-to-chronic ratio (Warne et al. 2025, Section 3.4.2.2;
# ANZECC & ARMCANZ 2000). Applied to acute LC/EC/IC50 values when no
# chronic or subchronic data exist for a species × chemical × mediatype
# group. Divide concentration by ACR_DEFAULT to convert to a chronic
# negligible-effect equivalent.
ACR_DEFAULT <- 10

# =============================================================================
# HELPERS
# =============================================================================
normalize_cas <- function(x) {
  x |>
    as.character() |>
    str_squish() |>
    na_if("") |>
    na_if("-") |>
    # fix Excel-style extra zero in checksum block: 7783-06-04 -> 7783-06-4
    str_replace("^([0-9]+)-([0-9]{2})-0([0-9])$", "\\1-\\2-\\3") |>
    str_replace_all("[^0-9]", "") |>
    # remove leading zeroes: 0131113 -> 131113
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

normalize_name <- function(x) {
  x |>
    as.character() |>
    str_to_lower() |>
    str_replace_all("[^a-z0-9]+", " ") |>
    str_squish()
}

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

# =============================================================================
# INPUTS
# =============================================================================
cas_parent_lookup <- read_csv(
  "data-raw/anztox/raw/cas_parent_lookup.csv",
  col_types = cols(
    chemicalname = col_character(),
    casnumber = col_character(),
    parent_cas_dashed = col_character(),
    parent_casnumber = col_character(),
    parent_name = col_character(),
    match_rationale = col_character()
  )
)

dgv_raw <- read_csv(
  "data-raw/anztox/raw/toxicants-dgvs-mastertable-april2026.csv",
  show_col_types = FALSE
)

# Endpoint harmonisation lookup (2016 labels -> 2000 codes).
# Validated for uniqueness below.
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

# Guard: non-unique raw labels would cause incorrect joins downstream.
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

# Safe dedup version (defensive; should be a no-op given the guard above).
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

# =============================================================================
# DATABASE
# =============================================================================
# DATABASE
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

if (
  exists("con_local") &&
    inherits(con_local, "PqConnection") &&
    DBI::dbIsValid(con_local)
) {
  DBI::dbDisconnect(con_local)
}

con_local <- DBI::dbConnect(
  RPostgres::Postgres(),
  dbname = "infogathering",
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = get_db_password()
)

if (!DBI::dbIsValid(con_local)) {
  stop("Database connection is not valid")
}

# Read shared lookup tables once
raw_toxicityvalue <- dbReadTable(con_local, "toxicityvalue")
raw_chemical <- dbReadTable(con_local, "chemical")
raw_species <- dbReadTable(con_local, "species")
lu_mediatype <- dbReadTable(con_local, "mediatype") |> rename(mediatype = name)
lu_endpoint <- dbReadTable(con_local, "endpoint")
lu_effect <- dbReadTable(con_local, "effect")
lu_testtype <- dbReadTable(con_local, "testtype") |> rename(testtype = name)
lu_concentrationcode <- dbReadTable(con_local, "concentrationcode") |>
  rename(concentrationcode = name)
lu_status <- dbReadTable(con_local, "status") |> rename(status = name)
lu_reference <- dbReadTable(con_local, "reference")

# =============================================================================
# BUILD toxicityvalue2000_clean
# =============================================================================
raw_2000 <- dbReadTable(con_local, "toxicityvalue2000")

toxicityvalue2000_clean <- raw_2000 |>
  left_join(raw_toxicityvalue, by = c("toxicityvalue_id" = "id")) |>
  left_join(lu_mediatype, by = c("mediatype_id" = "id")) |>
  left_join(lu_testtype, by = c("testtype_id" = "id")) |>
  left_join(
    lu_effect |> rename(effectused = name),
    by = c("effectused_id" = "id")
  ) |>
  left_join(lu_concentrationcode, by = c("concentrationcode_id" = "id")) |>
  left_join(lu_status, by = c("status_id" = "id")) |>
  left_join(lu_reference, by = c("reference_id" = "id")) |>
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
  left_join(lu_effect, by = c("effect_id" = "id")) |>
  select(where(~ !all(is.na(.)))) |>
  select(where(~ mean(!is.na(.)) >= 0.05)) |>
  select(-matches("_id$"), toxicityvalue_id) |>
  mutate(
    reference_bib = str_squish(paste0(
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
    )),
    source_dataset = "2000",
    casnumber = as.character(casnumber),
    mediatype = normalize_mediatype(mediatype),
    endpoint = name.y,
    testtype = as.character(testtype)
  ) |>
  select(
    -authors,
    -authorsabbreviated,
    -title,
    -journal,
    -year,
    -volume,
    -issuenumber,
    -firstpage,
    -lastpage
  )

# =============================================================================
# BUILD toxicityvalue2016_clean
# =============================================================================
raw_2016 <- dbReadTable(con_local, "toxicityvalue2016")

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

# candidate keys from toxicityvalue2016
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

# datasource-based reference
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

# record-based reference
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

# merged best reference for each 2016 toxicityvalue_id
ref_2016_best <- ref_keys_2016 |>
  select(toxicityvalue_id, datasource, record) |>
  left_join(ref_from_datasource, by = "toxicityvalue_id") |>
  left_join(ref_from_record, by = "toxicityvalue_id") |>
  mutate(
    # prefer datasource match; fallback to record match
    ref_authors = coalesce(ref_authors_ds, ref_authors_rec),
    ref_authabbr = coalesce(ref_authabbr_ds, ref_authabbr_rec),
    ref_title = coalesce(ref_title_ds, ref_title_rec),
    ref_journal = coalesce(ref_journal_ds, ref_journal_rec),
    ref_year = coalesce(ref_year_ds, ref_year_rec),
    ref_volume = coalesce(ref_volume_ds, ref_volume_rec),
    ref_issue = coalesce(ref_issue_ds, ref_issue_rec),
    ref_firstpage = coalesce(ref_firstpage_ds, ref_firstpage_rec),
    ref_lastpage = coalesce(ref_lastpage_ds, ref_lastpage_rec),
    reference_match_method = case_when(
      !is.na(ref_title_ds) |
        !is.na(ref_authors_ds) |
        !is.na(ref_authabbr_ds) ~ "orgref_from_datasource",
      !is.na(ref_title_rec) |
        !is.na(ref_authors_rec) |
        !is.na(ref_authabbr_rec) ~ "orgref_from_record",
      TRUE ~ "unmatched"
    ),
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
  select(
    toxicityvalue_id,
    reference_bib,
    reference_match_method,
    datasource,
    record
  )

lu_reference_bib <- lu_reference |>
  mutate(
    reference_bib_lu = build_reference_bib(
      authors,
      authorsabbreviated,
      year,
      title,
      journal,
      volume,
      issuenumber,
      firstpage,
      lastpage
    )
  ) |>
  select(id, reference_bib_lu)

toxicityvalue2016_clean <- raw_2016 |>
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
  select(where(~ !all(is.na(.)))) |>
  select(where(~ mean(!is.na(.)) >= 0.05), toxicityvalue_id) |>
  filter(scientificname != "-") |>
  mutate(endpoint_raw = coalesce(endpoint_measured, endpoint_paper)) |>
  left_join(
    endpoint_2016_to_2000_lookup_dedup,
    by = c("endpoint_raw" = "endpoint_2016_raw")
  ) |>
  left_join(
    ref_2016_best |>
      select(toxicityvalue_id, reference_bib, reference_match_method),
    by = "toxicityvalue_id"
  ) |>
  mutate(
    source_dataset = "2016",
    casnumber = as.character(casnumber),
    mediatype = normalize_mediatype(mediatype),
    endpoint = coalesce(endpoint_2000_code, endpoint_raw),
    endpoint_mapping_missing = is.na(endpoint_2000_code),
    testtype = if_else(ischronic %in% TRUE, "Chronic", "Acute")
  )

# =============================================================================
# HARMONISE + COMBINE
# =============================================================================
core_cols <- c(
  "source_dataset",
  "toxicityvalue_id",
  "casnumber",
  "commonname",
  "mediatype",
  "scientificname",
  "commonname_species",
  "majorgroup",
  "minorgroup",
  "testtype",
  "endpoint",
  "concentrationused",
  "concentration",
  "reference_bib"
)

tox2000_core <- toxicityvalue2000_clean |>
  mutate(concentration = concentrationused) |>
  select(any_of(core_cols))

tox2016_core <- toxicityvalue2016_clean |>
  mutate(concentration = concentrationused) |>
  select(any_of(core_cols))

toxicityvalue_combined_clean <- bind_rows(tox2000_core, tox2016_core) |>
  left_join(
    cas_parent_lookup |>
      transmute(
        casnumber = as.character(casnumber),
        parent_casnumber = as.character(parent_casnumber),
        parent_name = as.character(parent_name)
      ),
    by = join_by(casnumber)
  ) |>
  mutate(
    casnumber_grouped = coalesce(parent_casnumber, casnumber),
    chemicalname_grouped = coalesce(parent_name, commonname)
  )

write_csv(
  toxicityvalue_combined_clean,
  "data-raw/anztox/toxicityvalue_combined_clean.csv"
)

# =============================================================================
# SHARED SSD WORKFLOW
# =============================================================================
# Step 1 – Base filters
# ---------------------
# Use concentrationused throughout. For the 2000 dataset this field is
# pre-calculated by database curators to flag values appropriate for
# guideline derivation. For the 2016 dataset all rows are populated.
# Records with NA or non-positive concentrationused are excluded.
#
# Step 2 – Test type classification and priority selection
# --------------------------------------------------------
# Each record is classified as chronic, subchronic, or acute.
# Within each chemical × mediatype × species × endpoint group:
#   • If any chronic data exist, retain only chronic records.
#   • If no chronic data exist but subchronic data do, retain only
#     subchronic records (reclassified as "Chronic").
#   • Otherwise retain acute records.
#
# Step 3 – ACR conversion for retained acute records (NEW in v5)
# ---------------------------------------------------------------
# Per Warne et al. (2025) Section 3.4.2.2 and ANZECC & ARMCANZ (2000):
# When no chronic or subchronic data are available for a species, acute
# LC/EC/IC50 values must be converted to chronic negligible-effect
# equivalents before use in SSD fitting. A default ACR of 10 is applied
# (divide concentration by ACR_DEFAULT = 10) unless chemical- or
# taxon-specific ACRs are available in the database. The resulting column
# is named `concentration_chronic_equiv`; `acr_applied` flags which
# records were converted.
#
# NOTE: The ANZTOX concentrationused field stores raw acute concentrations
# for acute records — it does NOT pre-apply the ACR. The ACR conversion
# must therefore be applied here, in this script, for all retained acute
# records.
#
# Steps 4–6 – Geometric mean, most-sensitive endpoint, eligibility threshold
# ---------------------------------------------------------------------------
# Geometric mean within chemical × mediatype × species × endpoint ×
# testtype groups, then most-sensitive endpoint per species, then
# ≥ 5 species from ≥ 4 major groups threshold.

ssd_species_eligible_combined <- toxicityvalue_combined_clean |>

  # --- Step 1: base filters ---
  filter(
    !is.na(concentrationused),
    concentrationused > 0,
    !is.na(scientificname),
    !is.na(testtype),
    !is.na(mediatype),
    !is.na(casnumber_grouped)
  ) |>

  # --- Step 2: classify test types ---
  mutate(
    testtype_norm = str_to_lower(str_squish(testtype)),
    test_class = case_when(
      testtype_norm == "chronic" ~ "chronic",
      str_detect(testtype_norm, "^sub[ -]?chronic$") ~ "subchronic",
      testtype_norm == "acute" ~ "acute",
      TRUE ~ "other"
    )
  ) |>

  # --- Step 2 continued: priority selection within species groups ---
  group_by(casnumber_grouped, mediatype, scientificname, endpoint) |>
  mutate(
    has_chronic = any(test_class == "chronic", na.rm = TRUE),
    has_subchronic = any(test_class == "subchronic", na.rm = TRUE)
  ) |>
  ungroup() |>
  filter(
    (has_chronic & test_class == "chronic") |
      (!has_chronic & has_subchronic & test_class == "subchronic") |
      (!has_chronic & !has_subchronic & test_class == "acute")
  ) |>

  # Reclassify retained subchronic records as chronic (consistent with
  # Warne et al. 2025 Section 3.1.2 guidance that subchronic data meeting
  # duration criteria can be treated as chronic).
  mutate(testtype = if_else(test_class == "subchronic", "Chronic", testtype)) |>

  # --- Step 3: ACR conversion for retained acute records ---
  # Apply only to records still classed as "acute" after the priority
  # filter (i.e. species × endpoint groups where NO chronic or subchronic
  # data existed). The concentrationused value for these records is a raw
  # acute LC/EC/IC50 and must be divided by ACR_DEFAULT before SSD fitting.
  # Warne et al. (2025) Section 3.4.2.2: "In the absence of an ACR for a
  # particular toxicant, a default ACR of 10 should be used to convert
  # acute LC/EC/IC50 values to chronic negligible-effect values."
  mutate(
    acr_applied = test_class == "acute",
    concentration_chronic_equiv = if_else(
      acr_applied,
      concentrationused / ACR_DEFAULT,
      concentrationused
    )
  ) |>

  # --- Step 4: geometric mean within species × endpoint groups ---
  summarise(
    endpoint_concentration = exp(mean(
      log(concentration_chronic_equiv),
      na.rm = TRUE
    )),
    source_datasets = paste(sort(unique(source_dataset)), collapse = ";"),
    n_acute_converted = sum(acr_applied, na.rm = TRUE),
    .by = c(
      casnumber_grouped,
      chemicalname_grouped,
      mediatype,
      scientificname,
      commonname_species,
      majorgroup,
      minorgroup,
      endpoint,
      testtype
    )
  ) |>

  # --- Step 5: most sensitive endpoint per species ---
  slice_min(
    endpoint_concentration,
    n = 1,
    with_ties = FALSE,
    by = c(casnumber_grouped, mediatype, scientificname)
  ) |>

  # --- Step 6: minimum SSD eligibility threshold ---
  # ≥ 5 species from ≥ 4 distinct major taxonomic groups required.
  # (Warne et al. 2025 Section 3.4.5; note the 2000 script used ≥ 5 / ≥ 4
  # consistently with the 2000 guidelines; v5 retains this threshold.)
  filter(
    n_distinct(scientificname) >= 5 & n_distinct(majorgroup) >= 4,
    .by = c(casnumber_grouped, mediatype)
  )

# Nest for ssdtools input
anztox_data <- ssd_species_eligible_combined |>
  nest(.by = c(casnumber_grouped, chemicalname_grouped, mediatype))

# =============================================================================
# DGV MATCHING (2000 DGV TABLE)
# =============================================================================
# Build a canonical name -> CAS map from the lookup + combined tox data.
# Used as a fallback when a DGV row is missing a raw CAS number.
name_cas_lookup <- bind_rows(
  cas_parent_lookup |>
    transmute(
      name_key = normalize_name(parent_name),
      cas_key = normalize_cas(parent_casnumber),
      source = "cas_parent_lookup"
    ),
  toxicityvalue_combined_clean |>
    transmute(
      name_key = normalize_name(coalesce(chemicalname_grouped, commonname)),
      cas_key = normalize_cas(casnumber_grouped),
      source = "toxicityvalue_combined_clean"
    )
) |>
  filter(!is.na(name_key), name_key != "", !is.na(cas_key), cas_key != "") |>
  distinct(name_key, cas_key, source)

# Keep only unambiguous mappings (one CAS per normalised name).
name_cas_unique <- name_cas_lookup |>
  distinct(name_key, cas_key) |>
  add_count(name_key, name = "n_cas_per_name") |>
  filter(n_cas_per_name == 1) |>
  select(name_key, cas_key) |>
  distinct()

dgv_method_flag_2000 <- dgv_raw |>
  filter(`Publish date` == 2000) |>
  transmute(
    tox_name = `Toxicant name`,
    name_key = normalize_name(`Toxicant name`),
    cas_key_raw = normalize_cas(`Tox CAS`),
    mediatype = normalize_mediatype(`Tox Medium`),
    tox_reliability = str_to_lower(str_squish(as.character(`Tox Reliability`))),
    likely_ssd_derived = tox_reliability != "unknown"
  ) |>
  left_join(
    name_cas_unique |> rename(cas_key_name = cas_key),
    by = "name_key"
  ) |>
  mutate(
    cas_key = coalesce(cas_key_raw, cas_key_name),
    cas_fill_method = case_when(
      !is.na(cas_key_raw) ~ "raw_cas",
      is.na(cas_key_raw) & !is.na(cas_key_name) ~ "name_fallback_unique",
      TRUE ~ "missing"
    )
  ) |>
  filter(!is.na(mediatype)) |>
  select(
    tox_name,
    cas_key,
    mediatype,
    tox_reliability,
    likely_ssd_derived,
    cas_fill_method
  )

dgv2000 <- dgv_method_flag_2000 |>
  select(tox_name, cas_key, mediatype)

ssd_keys_combined <- anztox_data |>
  mutate(
    cas_key = normalize_cas(casnumber_grouped),
    chem_key = normalize_name(chemicalname_grouped)
  ) |>
  select(
    casnumber_grouped,
    chemicalname_grouped,
    mediatype,
    cas_key,
    chem_key,
    data
  )

matched_combined <- anztox_data |>
  mutate(cas_key = normalize_cas(casnumber_grouped)) |>
  semi_join(dgv2000, by = join_by(cas_key, mediatype))

matched_dgv_rows <- dgv_method_flag_2000 |>
  semi_join(
    ssd_keys_combined |> distinct(cas_key, mediatype),
    by = join_by(cas_key, mediatype)
  )

unmatched_dgv_rows <- dgv_method_flag_2000 |>
  anti_join(
    ssd_keys_combined |> distinct(cas_key, mediatype),
    by = join_by(cas_key, mediatype)
  )

dgv_missing_from_ssd_combined <- dgv2000 |>
  anti_join(
    ssd_keys_combined |> distinct(cas_key, mediatype),
    by = join_by(cas_key, mediatype)
  )

summary_2000_dgvs_combined <- tibble::tibble(
  category = c(
    "Total 2000 DGVs",
    "Matched to anztox_data (DGV rows)",
    "Unmatched - likely SSD (reliability != Unknown)",
    "Unmatched - other method (reliability == Unknown)"
  ),
  count = c(
    nrow(dgv_method_flag_2000),
    nrow(matched_dgv_rows),
    nrow(unmatched_dgv_rows |> filter(likely_ssd_derived)),
    nrow(unmatched_dgv_rows |> filter(!likely_ssd_derived))
  )
)

# =============================================================================
# OPTIONAL DIAGNOSTICS
# =============================================================================
if (run_diagnostics) {
  source_counts <- toxicityvalue_combined_clean |>
    count(source_dataset, name = "n_rows")

  source_eligible_counts <- ssd_species_eligible_combined |>
    separate_rows(source_datasets, sep = ";") |>
    count(source_datasets, name = "n_rows") |>
    rename(source_dataset = source_datasets)

  # Proportion of species rows that required ACR conversion
  acr_summary <- ssd_species_eligible_combined |>
    summarise(
      n_species_rows = n(),
      n_acr_converted = sum(n_acute_converted > 0, na.rm = TRUE),
      pct_acr_converted = round(100 * n_acr_converted / n_species_rows, 1),
      .by = c(casnumber_grouped, mediatype)
    ) |>
    arrange(desc(pct_acr_converted))
} else {
  source_counts <- tibble::tibble()
  source_eligible_counts <- tibble::tibble()
  acr_summary <- tibble::tibble()
}

usethis::use_data(anztox_data, overwrite = TRUE)
