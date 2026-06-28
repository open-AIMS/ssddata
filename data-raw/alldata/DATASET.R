# data-raw/alldata/DATASET.R
#
# Stage 6/7 integrated pipeline (redesign — Issue #33).
# Produces data/allchronic_data.rda: a flat tibble with a Set column.
# ssd_data_sets(set="all_chronic") returns split(allchronic_data, Set).
#
# Steps:
#   A: Load and harmonise all sources into a common frame
#   B: Source-priority exclusion (anzg > ccme > aims > csiro > uncurated)
#   C: Medium viability + pooling (mixed sets)
#   D: Assemble allchronic_data (PascalCase, +Set, +ValueTier, +AnyChronicConvApplied)
#   E: Save .rda, write reports
#
# Inputs (must exist):
#   data-raw/alldata/uncurated_raw_aggregated.csv        [UNTRACKED — Stage 4e output]
#   data-raw/alldata/curated_cas_lookup.csv
#   data-raw/alldata/species_resolution_curated.csv
#   data-raw/cas_parent_lookup_all.csv
#
# Outputs:
#   data/allchronic_data.rda                             [tracked — package data]
#   data-raw/alldata/stage6-integration-report.md        [tracked]
#   data-raw/alldata/stage7-eligibility-report.md        [tracked]

library(dplyr)
library(readr)
library(tibble)
# Load curated data objects directly from the working-tree data/ directory rather
# than from the installed package, to avoid the installed-version mismatch on
# Windows (installed ssddata v1.0.0 has a different schema and fewer rows than
# the in-development data objects on the create_alldata branch).
load("data/anzg_data.rda")
load("data/ccme_data.rda")
load("data/aims_data.rda")
load("data/csiro_data.rda")

# ============================================================
# HELPERS
# ============================================================

fw_family <- c("Freshwater", "Soft freshwater", "Moderate freshwater", "Hard freshwater")

normalize_medium <- function(x) {
  dplyr::case_when(
    tolower(trimws(x)) %in% c("freshwater", "fresh") ~ "Freshwater",
    tolower(trimws(x)) == "marine"                   ~ "Marine",
    tolower(trimws(x)) == "soft freshwater"          ~ "Soft freshwater",
    tolower(trimws(x)) == "moderate freshwater"      ~ "Moderate freshwater",
    tolower(trimws(x)) == "hard freshwater"          ~ "Hard freshwater",
    tolower(trimws(x)) == "unknown"                  ~ "Unknown",
    TRUE ~ x
  )
}

sanitise_key <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  gsub("^_+|_+$", "", x)
}

medium_token <- function(x) {
  x <- tolower(trimws(x))
  gsub(" +", "_", x)
}

# ============================================================
# STEP A — Load and harmonise sources
# ============================================================

cat("== Step A: Load and harmonise ==\n\n")

# Pre-condition checks
cas_curated_path <- "data-raw/alldata/curated_cas_lookup.csv"
if (!file.exists(cas_curated_path)) stop("curated_cas_lookup.csv not found")
curated_cas <- read_csv(cas_curated_path, show_col_types = FALSE)

cas_master_path <- "data-raw/cas_parent_lookup_all.csv"
if (!file.exists(cas_master_path)) stop("cas_parent_lookup_all.csv not found")
cas_master <- read_csv(cas_master_path, guess_max = Inf, show_col_types = FALSE) |>
  filter(!excluded)
cat("cas_parent_lookup_all.csv (excluded==FALSE):", nrow(cas_master), "rows\n")

uncurated_path <- "data-raw/alldata/uncurated_raw_aggregated.csv"
if (!file.exists(uncurated_path)) stop("uncurated_raw_aggregated.csv not found. Run stage4e-aggregate.R first.")
uncurated_raw <- read_csv(uncurated_path, guess_max = Inf, show_col_types = FALSE)
cat("uncurated_raw_aggregated.csv:", nrow(uncurated_raw), "rows\n")

sp_res_curated_path <- "data-raw/alldata/species_resolution_curated.csv"
if (!file.exists(sp_res_curated_path)) stop(sp_res_curated_path, " not found. Run old DATASET.R once to generate it.")
sp_res_curated <- read_csv(sp_res_curated_path, guess_max = Inf, show_col_types = FALSE)
taxonomy_lookup <- sp_res_curated |>
  select(query_name, accepted_name, kingdom, phylum, class, order_taxon, family, genus,
         taxonomy_provenance) |>
  distinct(query_name, .keep_all = TRUE)

# Common column order for the harmonised frame
schema_cols <- c(
  "source", "casnumber_grouped", "chemicalname_grouped", "accepted_name", "medium",
  "conc_ug_L", "effect_category",
  "kingdom", "phylum", "class", "order_taxon", "family", "genus",
  "taxonomy_provenance", "n_records", "sources_contributing",
  "any_acr_applied", "any_chronic_conv_applied", "any_conc_flagged",
  "geomean_flagged", "lifestage_mixed", "duration_mixed", "value_tier"
)

# -- A1: Uncurated (straight from Stage 4e; value_tier already set)
uncurated_layer <- uncurated_raw |>
  mutate(source = "uncurated") |>
  select(all_of(schema_cols))
cat("Uncurated layer:", nrow(uncurated_layer), "rows\n")

# -- A2: ANZG
anzg_cas <- curated_cas |> filter(source == "anzg")

unexpected_anzg_medium <- setdiff(
  unique(anzg_data$Medium),
  # "fresh" is a legacy abbreviation for "Freshwater" in ssddata v1.0.0 anzg_data;
  # normalize_medium() already converts it correctly.
  c("freshwater", "fresh", "marine", "soft freshwater", "moderate freshwater", "hard freshwater")
)
if (length(unexpected_anzg_medium) > 0) {
  stop("Unexpected ANZG Medium values: ", paste(unexpected_anzg_medium, collapse = ", "))
}
anzg_chems_missing <- setdiff(anzg_data$Chemical, anzg_cas$chemical_name)
if (length(anzg_chems_missing) > 0) {
  stop("ANZG chemicals not in curated_cas_lookup: ", paste(anzg_chems_missing, collapse = ", "))
}

anzg_layer <- anzg_data |>
  left_join(
    anzg_cas |> select(chemical_name, casnumber_grouped, chemicalname_grouped),
    by = c("Chemical" = "chemical_name")
  ) |>
  mutate(
    source                   = "anzg",
    accepted_name            = paste(Genus, Species),
    medium                   = normalize_medium(Medium),
    conc_ug_L                = Conc,
    effect_category          = NA_character_,   # C3: curated sources carry no effect_category
    kingdom                  = NA_character_,
    phylum                   = as.character(Phylum),
    class                    = NA_character_,
    order_taxon              = NA_character_,
    family                   = NA_character_,
    genus                    = as.character(Genus),
    taxonomy_provenance      = "curated_source",
    n_records                = 1L,
    sources_contributing     = "anzg",
    any_acr_applied          = FALSE,
    any_chronic_conv_applied = FALSE,
    any_conc_flagged         = FALSE,
    geomean_flagged          = FALSE,
    lifestage_mixed          = FALSE,
    duration_mixed           = FALSE,
    value_tier               = "curated"
  ) |>
  select(all_of(schema_cols))

if (any(is.na(anzg_layer$casnumber_grouped))) {
  stop("ANZG rows failed CAS join: ",
    paste(unique(anzg_layer$chemicalname_grouped[is.na(anzg_layer$casnumber_grouped)]), collapse = ", "))
}
cat("ANZG layer:", nrow(anzg_layer), "rows\n")

# -- A3: CCME (unit conversion required)
ccme_cas <- curated_cas |> filter(source == "ccme")
ccme_chems_missing <- setdiff(ccme_data$Chemical, ccme_cas$chemical_name)
if (length(ccme_chems_missing) > 0) {
  stop("CCME chemicals not in curated_cas_lookup: ", paste(ccme_chems_missing, collapse = ", "))
}

ccme_layer <- ccme_data |>
  mutate(conc_ug_L = case_when(
    Units %in% c("ug/L", "µg/L") ~ Conc,
    Units == "mg/L"                    ~ Conc * 1000,
    Units == "ng/L"                    ~ Conc / 1000,
    TRUE                               ~ NA_real_
  )) |>
  left_join(
    ccme_cas |> select(chemical_name, casnumber_grouped, chemicalname_grouped),
    by = c("Chemical" = "chemical_name")
  ) |>
  mutate(
    source                   = "ccme",
    accepted_name            = Species,
    medium                   = Medium,  # "Freshwater" in source
    effect_category          = NA_character_,   # C3: curated sources carry no effect_category
    kingdom                  = NA_character_,
    phylum                   = NA_character_,
    class                    = NA_character_,
    order_taxon              = NA_character_,
    family                   = NA_character_,
    genus                    = NA_character_,
    taxonomy_provenance      = "curated_source",
    n_records                = 1L,
    sources_contributing     = "ccme",
    any_acr_applied          = FALSE,
    any_chronic_conv_applied = FALSE,
    any_conc_flagged         = FALSE,
    geomean_flagged          = FALSE,
    lifestage_mixed          = FALSE,
    duration_mixed           = FALSE,
    value_tier               = "curated"
  ) |>
  select(all_of(schema_cols))

if (any(is.na(ccme_layer$conc_ug_L))) stop("CCME unit conversion produced NA")
if (any(is.na(ccme_layer$casnumber_grouped))) {
  stop("CCME rows failed CAS join: ",
    paste(unique(ccme_layer$accepted_name[is.na(ccme_layer$casnumber_grouped)]), collapse = ", "))
}
cat("CCME layer:", nrow(ccme_layer), "rows\n")

# -- A4: AIMS and CSIRO — taxonomy from species_resolution_curated.csv
# Geomean within-source duplicates at source × casnumber_grouped × medium × accepted_name
prep_curated_source <- function(df, source_label, cas_subset) {
  df_cas <- df |>
    left_join(
      cas_subset |> select(chemical_name, casnumber_grouped, chemicalname_grouped),
      by = c("Chemical" = "chemical_name")
    )
  missing_chem <- unique(df_cas$Chemical[is.na(df_cas$casnumber_grouped)])
  if (length(missing_chem) > 0) {
    stop(source_label, " chemicals not in curated_cas_lookup: ", paste(missing_chem, collapse = ", "))
  }

  # Drop rows with no species name before taxonomy join (S6-D4: no taxon assignable;
  # reinstates exclusion of csiro chlorine/marine acute rows which have NA Species).
  n_no_species <- sum(is.na(df_cas$Species) | trimws(as.character(df_cas$Species)) == "")
  if (n_no_species > 0) {
    message(sprintf("  %s: dropping %d NA/empty-Species rows (S6-D4)", source_label, n_no_species))
    df_cas <- df_cas |> filter(!is.na(Species), trimws(as.character(Species)) != "")
  }

  df_tax <- df_cas |>
    left_join(taxonomy_lookup, by = c("Species" = "query_name")) |>
    mutate(
      medium = normalize_medium(Medium),
      accepted_name = case_when(
        !is.na(accepted_name)       ~ accepted_name,
        TRUE                        ~ Species  # cache miss: keep input name
      ),
      taxonomy_provenance = case_when(
        !is.na(taxonomy_provenance) ~ taxonomy_provenance,
        TRUE                        ~ "source_native_fallback"
      )
    )

  # Within-source geomean (with flagging if spread > 1 OOM)
  df_agg <- df_tax |>
    filter(!is.na(Conc)) |>
    group_by(
      casnumber_grouped, chemicalname_grouped, accepted_name, medium,
      kingdom, phylum, class, order_taxon, family, genus, taxonomy_provenance
    ) |>
    summarise(
      n_records       = n(),
      conc_ug_L       = if (n() == 1 || max(Conc) / min(Conc) <= 10) {
                          exp(mean(log(Conc)))
                        } else {
                          min(Conc)
                        },
      geomean_flagged = n() > 1 && max(Conc) / min(Conc) > 10,
      .groups         = "drop"
    ) |>
    mutate(
      source                   = source_label,
      effect_category          = NA_character_,   # C3: curated sources carry no effect_category
      sources_contributing     = source_label,
      any_acr_applied          = FALSE,
      any_chronic_conv_applied = FALSE,
      any_conc_flagged         = FALSE,
      lifestage_mixed          = FALSE,
      duration_mixed           = FALSE,
      value_tier               = "curated"
    ) |>
    select(all_of(schema_cols))

  df_agg
}

aims_cas  <- curated_cas |> filter(source == "aims")
csiro_cas <- curated_cas |> filter(source == "csiro")

n_aims_no_species  <- sum(is.na(aims_data$Species)  | trimws(as.character(aims_data$Species))  == "")
n_csiro_no_species <- sum(is.na(csiro_data$Species) | trimws(as.character(csiro_data$Species)) == "")

aims_layer  <- prep_curated_source(aims_data,  "aims",  aims_cas)
csiro_layer <- prep_curated_source(csiro_data, "csiro", csiro_cas)

# Validate within-source dedup
aims_dups <- aims_layer |>
  group_by(source, casnumber_grouped, medium, accepted_name) |> filter(n() > 1) |> ungroup()
csiro_dups <- csiro_layer |>
  group_by(source, casnumber_grouped, medium, accepted_name) |> filter(n() > 1) |> ungroup()
if (nrow(aims_dups) > 0 || nrow(csiro_dups) > 0) {
  stop("Within-source geomean dedup FAILED: ", nrow(aims_dups), " aims, ", nrow(csiro_dups),
       " csiro key duplicates remain")
}

cat("AIMS:  ", nrow(aims_data), "input rows →", nrow(aims_layer), "aggregated\n")
cat("CSIRO: ", nrow(csiro_data), "input rows →", nrow(csiro_layer), "aggregated\n")
cat("Within-source geomean dedup: PASS\n\n")

# ============================================================
# STEP B — Source-priority exclusion
# ============================================================

cat("== Step B: Curated integration ==\n\n")

all_rows <- bind_rows(anzg_layer, ccme_layer, aims_layer, csiro_layer, uncurated_layer) |>
  mutate(excl = NA_character_)

cat("Combined frame:", nrow(all_rows), "rows\n")
cat("By source:\n"); print(count(all_rows, source))

# B1: ANZG exclusion
# Freshwater-family: broad-match at chemical level (any FW variant → exclude all FW-family non-anzg)
# Marine: per casnumber_grouped × medium
anzg_positions <- all_rows |>
  filter(source == "anzg") |>
  select(casnumber_grouped, medium) |>
  distinct()

anzg_fw_cas     <- anzg_positions |> filter(medium %in% fw_family) |> pull(casnumber_grouped) |> unique()
anzg_marine_cas <- anzg_positions |> filter(medium == "Marine")    |> pull(casnumber_grouped) |> unique()

all_rows <- all_rows |>
  mutate(excl = case_when(
    !is.na(excl)                                                              ~ excl,
    source != "anzg" & casnumber_grouped %in% anzg_fw_cas & medium %in% fw_family ~ "anzg_fw",
    source != "anzg" & casnumber_grouped %in% anzg_marine_cas & medium == "Marine"  ~ "anzg_marine",
    TRUE                                                                       ~ excl
  ))

n_anzg_fw_excl     <- sum(all_rows$excl == "anzg_fw",    na.rm = TRUE)
n_anzg_marine_excl <- sum(all_rows$excl == "anzg_marine", na.rm = TRUE)
cat("ANZG exclusion — freshwater-family rows excluded:", n_anzg_fw_excl, "\n")
cat("ANZG exclusion — marine rows excluded:          ", n_anzg_marine_excl, "\n")

# B2: CCME exclusion (per casnumber_grouped × medium, for aims/csiro/uncurated only)
ccme_chem_medium <- all_rows |>
  filter(source == "ccme") |>
  select(casnumber_grouped, medium) |>
  distinct() |>
  mutate(ccme_covered = TRUE)

all_rows <- all_rows |>
  left_join(ccme_chem_medium, by = c("casnumber_grouped", "medium")) |>
  mutate(excl = case_when(
    !is.na(excl)                                                          ~ excl,
    source %in% c("aims", "csiro", "uncurated") & !is.na(ccme_covered)    ~
      paste0("ccme_", medium_token(medium)),
    TRUE                                                                   ~ excl
  )) |>
  select(-ccme_covered)

n_ccme_excl <- sum(grepl("^ccme_", all_rows$excl), na.rm = TRUE)
cat("CCME exclusion:", n_ccme_excl, "rows excluded\n")

# B3: Preference hierarchy — aims > csiro > uncurated
# Per casnumber_grouped × medium × accepted_name
priority_order <- c(aims = 1L, csiro = 2L, uncurated = 3L)

overlap_groups <- all_rows |>
  filter(is.na(excl), source %in% c("aims", "csiro", "uncurated")) |>
  select(casnumber_grouped, medium, accepted_name, source) |>
  mutate(priority = priority_order[source]) |>
  group_by(casnumber_grouped, medium, accepted_name) |>
  filter(n_distinct(source) > 1) |>
  slice_min(priority, n = 1, with_ties = FALSE) |>
  ungroup() |>
  select(casnumber_grouped, medium, accepted_name, winner_source = source)

if (nrow(overlap_groups) > 0) {
  all_rows <- all_rows |>
    left_join(overlap_groups, by = c("casnumber_grouped", "medium", "accepted_name")) |>
    mutate(excl = case_when(
      !is.na(excl)                                                                ~ excl,
      source %in% c("aims", "csiro", "uncurated") &
        !is.na(winner_source) & source != winner_source                           ~
        paste0("priority_", winner_source, "_over_", source),
      TRUE                                                                        ~ excl
    )) |>
    select(-winner_source)
}

n_pref_excl <- sum(grepl("^priority_", all_rows$excl), na.rm = TRUE)
cat("Preference hierarchy:", n_pref_excl, "rows excluded\n\n")

# Save exclusion summary for report
excl_summary <- count(all_rows, excl) |> arrange(desc(n))

retained <- all_rows |> filter(is.na(excl)) |> select(-excl)
cat("Retained rows:", nrow(retained), "\n")
retained_by_source_medium <- count(retained, source, medium) |> arrange(source, medium)
cat("By source × medium:\n"); print(retained_by_source_medium, n = 30)

# ============================================================
# STEP C — Medium viability + pooling
# ============================================================

cat("\n== Step C: Medium viability + pooling ==\n\n")

# Separate real-medium and Unknown rows
real_medium_rows <- retained |> filter(medium != "Unknown")
unknown_rows     <- retained |> filter(medium == "Unknown")

# C1: Viability per casnumber_grouped × medium
# (each freshwater variant assessed separately)
viability <- real_medium_rows |>
  group_by(casnumber_grouped, medium) |>
  summarise(
    has_curated = any(source %in% c("anzg", "ccme", "aims", "csiro")),
    n_species   = n_distinct(accepted_name),
    n_classes   = n_distinct(class[!is.na(class)]),
    .groups     = "drop"
  ) |>
  mutate(viable = has_curated | (n_species >= 5 & n_classes >= 4))

cat("Real-medium viability:\n")
cat("  Total combinations:    ", nrow(viability), "\n")
cat("  Viable (curated-backed or ≥5sp/≥4cl):", sum(viability$viable), "\n")
cat("  Via curated:           ", sum(viability$has_curated), "\n")
cat("  Via uncurated only:    ", sum(!viability$has_curated & viability$viable), "\n")
cat("  Non-viable:            ", sum(!viability$viable), "\n\n")

# C2: Standalone real-medium sets
standalone_keys <- viability |> filter(viable) |> select(casnumber_grouped, medium)

standalone_rows <- real_medium_rows |>
  semi_join(standalone_keys, by = c("casnumber_grouped", "medium"))

cat("Standalone real-medium sets:", nrow(standalone_keys), "\n")
cat("Rows in standalone sets:", nrow(standalone_rows), "\n")

# C3: Per-chemical fw_family and marine viability flags
chem_fw_marine <- viability |>
  filter(viable) |>
  group_by(casnumber_grouped) |>
  summarise(
    fw_family_viable = any(medium %in% fw_family),
    marine_viable    = any(medium == "Marine"),
    .groups          = "drop"
  )

# C4: Non-viable real-medium rows → pool
non_viable_real <- real_medium_rows |>
  anti_join(standalone_keys, by = c("casnumber_grouped", "medium"))

# C5: Unknown rows → pool (dropped if both fw_family and marine are viable for that chemical)
unknown_for_pool <- unknown_rows |>
  left_join(
    chem_fw_marine |> select(casnumber_grouped, fw_family_viable, marine_viable),
    by = "casnumber_grouped"
  ) |>
  mutate(
    fw_family_viable = if_else(is.na(fw_family_viable), FALSE, fw_family_viable),
    marine_viable    = if_else(is.na(marine_viable),    FALSE, marine_viable)
  ) |>
  filter(!(fw_family_viable & marine_viable)) |>  # option-a: drop Unknown if both viable
  select(-fw_family_viable, -marine_viable)

n_unknown_dropped <- nrow(unknown_rows) - nrow(unknown_for_pool)
cat("Unknown rows dropped (both FW and Marine viable):", n_unknown_dropped, "\n")
cat("Unknown rows entering pool:", nrow(unknown_for_pool), "\n")

pool_rows <- bind_rows(non_viable_real, unknown_for_pool)
cat("Pool rows before collapse:", nrow(pool_rows), "\n")

# C6: Collapse pool to one row per casnumber_grouped × accepted_name (lowest conc_ug_L)
pool_collapsed <- pool_rows |>
  group_by(casnumber_grouped) |>
  mutate(chemicalname_grouped = first(chemicalname_grouped)) |>
  ungroup() |>
  group_by(casnumber_grouped, chemicalname_grouped, accepted_name) |>
  slice_min(conc_ug_L, n = 1, with_ties = FALSE) |>
  ungroup()

cat("Pool rows after species collapse:", nrow(pool_collapsed), "\n")

# C6.5: Remove pool species already present in a standalone set for the same chemical.
# This enforces the no-overlap invariant: a (Chemical, Species) pair appears in at most
# one set — the highest-priority one (standalone wins over mixed).
species_in_standalone <- standalone_rows |>
  select(casnumber_grouped, accepted_name) |>
  distinct()

n_pool_before_dedup <- nrow(pool_collapsed)
pool_collapsed <- pool_collapsed |>
  anti_join(species_in_standalone, by = c("casnumber_grouped", "accepted_name"))
n_pool_dedup_removed <- n_pool_before_dedup - nrow(pool_collapsed)
cat("Pool species removed (already in standalone):", n_pool_dedup_removed, "\n")
cat("Pool rows after no-overlap dedup:", nrow(pool_collapsed), "\n")

# C7: Mixed set viability
mixed_viability <- pool_collapsed |>
  group_by(casnumber_grouped) |>
  summarise(
    n_species = n_distinct(accepted_name),
    n_classes = n_distinct(class[!is.na(class)]),
    .groups   = "drop"
  ) |>
  filter(n_species >= 5, n_classes >= 4) |>
  select(casnumber_grouped)

mixed_rows <- pool_collapsed |>
  semi_join(mixed_viability, by = "casnumber_grouped")

cat("Mixed sets emitted (pool ≥5sp/≥4cl):", nrow(mixed_viability), "\n")
cat("Rows in mixed sets:", nrow(mixed_rows), "\n\n")

# ============================================================
# STEP D — Assemble allchronic_data
# ============================================================

cat("== Step D: Assemble allchronic_data ==\n\n")

# D1: Build Set column
# Standalone: sanitise(chemicalname_grouped)_medium_token(medium)
standalone_final <- standalone_rows |>
  mutate(Set = paste0(sanitise_key(chemicalname_grouped), "_", medium_token(medium)))

# Mixed: sanitise(chemicalname_grouped)_mixed
mixed_final <- mixed_rows |>
  mutate(Set = paste0(sanitise_key(chemicalname_grouped), "_mixed"))

# Combine
all_final <- bind_rows(standalone_final, mixed_final)

# D2: Check Set key collisions (same Set from different CAS numbers → fall back to CAS in key)
key_check <- all_final |>
  select(Set, casnumber_grouped) |>
  distinct() |>
  group_by(Set) |>
  filter(n() > 1) |>
  ungroup()

if (nrow(key_check) > 0) {
  warning("Set key collision(s) detected; falling back to CAS-based keys for: ",
          paste(unique(key_check$Set), collapse = ", "))
  colliding_sets <- unique(key_check$Set)
  # For mixed sets use CAS_mixed; for real-medium sets use CAS_medium_token.
  # medium is consistent within a non-mixed set (per casnumber_grouped × medium),
  # so medium_token(medium) is safe to use per-row for standalone sets.
  all_final <- all_final |>
    mutate(Set = case_when(
      !(Set %in% colliding_sets)   ~ Set,
      grepl("_mixed$", Set)        ~ paste0(sanitise_key(as.character(casnumber_grouped)), "_mixed"),
      TRUE                          ~ paste0(sanitise_key(as.character(casnumber_grouped)),
                                             "_", medium_token(medium))
    ))
}

# Assert Set uniqueness (one Set per casnumber_grouped)
set_uniqueness <- all_final |>
  select(Set, casnumber_grouped) |>
  distinct() |>
  group_by(Set) |>
  filter(n() > 1) |>
  ungroup()
if (nrow(set_uniqueness) > 0) stop("Set key still collides after fallback — review logic.")

# D3: Rename to PascalCase and select final columns
allchronic_data <- all_final |>
  select(-any_of("majorgroup")) |>
  rename(
    Species               = accepted_name,
    Conc                  = conc_ug_L,
    Chemical              = chemicalname_grouped,
    CAS                   = casnumber_grouped,
    Medium                = medium,
    Source                = source,
    ValueTier             = value_tier,
    AnyChronicConvApplied = any_chronic_conv_applied,
    EffectCategory        = effect_category,   # C1: effect_category of selected endpoint (NA for curated)
    Class                 = class,
    Kingdom               = kingdom,
    Phylum                = phylum,
    Order                 = order_taxon,
    Family                = family,
    Genus                 = genus,
    TaxonomyProvenance    = taxonomy_provenance,
    NRecords              = n_records,
    SourcesContributing   = sources_contributing,
    AnyAcrApplied         = any_acr_applied,
    AnyConcFlagged        = any_conc_flagged,
    GeomeanFlagged        = geomean_flagged,
    LifestageMixed        = lifestage_mixed,
    DurationMixed         = duration_mixed
  ) |>
  select(
    Species, Conc, Chemical, CAS, Medium, Source,
    ValueTier, AnyChronicConvApplied, EffectCategory,
    Class, Kingdom, Phylum, Order, Family, Genus,
    TaxonomyProvenance, NRecords, SourcesContributing,
    AnyAcrApplied, AnyConcFlagged, GeomeanFlagged,
    LifestageMixed, DurationMixed, Set
  ) |>
  as_tibble()

cat("allchronic_data:", nrow(allchronic_data), "rows,", ncol(allchronic_data), "cols\n")
cat("Distinct Set keys:", n_distinct(allchronic_data$Set), "\n")

# ============================================================
# VALIDATION CHECKS
# ============================================================

cat("\n== Validation checks ==\n")
checks_passed <- TRUE
chk <- function(cond, label, detail = NULL) {
  status <- if (cond) "PASS" else "FAIL"
  cat(" ", status, "--", label, "\n")
  if (!cond && !is.null(detail)) cat("   Detail:", detail, "\n")
  if (!cond) checks_passed <<- FALSE
}

# V1: Curated rows have ValueTier=="curated", AnyChronicConvApplied==FALSE, EffectCategory==NA
curated_vt_ok <- allchronic_data |>
  filter(Source %in% c("anzg","ccme","aims","csiro")) |>
  summarise(
    ok = all(ValueTier == "curated") &&
         all(!AnyChronicConvApplied) &&
         all(is.na(EffectCategory))
  ) |>
  pull(ok)
chk(curated_vt_ok, "Curated rows: ValueTier=='curated', AnyChronicConvApplied==FALSE, EffectCategory==NA")

# V2: No aims/csiro duplicates (per source × CAS × medium × species)
aims_csiro_dups <- allchronic_data |>
  filter(Source %in% c("aims","csiro")) |>
  group_by(Source, CAS, Medium, Species) |>
  filter(n() > 1) |>
  ungroup()
chk(nrow(aims_csiro_dups) == 0, "AIMS/CSIRO: one row per source × CAS × medium × species",
  if (nrow(aims_csiro_dups) > 0) paste(nrow(aims_csiro_dups), "duplicate rows") else NULL)

# V3: No anzg/ccme chemical×medium shared with another source
curated_excl_check <- allchronic_data |>
  filter(Source %in% c("anzg","ccme")) |>
  select(CAS, Medium) |>
  distinct() |>
  left_join(
    allchronic_data |>
      filter(!Source %in% c("anzg","ccme")) |>
      select(CAS, Medium) |>
      distinct() |>
      mutate(other_present = TRUE),
    by = c("CAS","Medium")
  )
curated_leak <- sum(!is.na(curated_excl_check$other_present))
chk(curated_leak == 0, "ANZG/CCME chemical×medium not shared with other sources",
  if (curated_leak > 0) paste(curated_leak, "chemical×medium combinations leak") else NULL)

# V4: Every standalone set is viable (curated-backed or ≥5sp/≥4cl)
standalone_viability_check <- allchronic_data |>
  filter(!grepl("_mixed$", Set)) |>
  group_by(Set, CAS, Medium) |>
  summarise(
    has_curated = any(Source %in% c("anzg","ccme","aims","csiro")),
    n_sp        = n_distinct(Species),
    n_cl        = n_distinct(Class[!is.na(Class)]),
    .groups     = "drop"
  ) |>
  filter(!has_curated & (n_sp < 5 | n_cl < 4))
chk(nrow(standalone_viability_check) == 0,
  "Every standalone real-medium set is viable (curated-backed or >=5sp/>=4cl)",
  if (nrow(standalone_viability_check) > 0)
    paste(nrow(standalone_viability_check), "non-viable standalone sets") else NULL)

# V5: Every mixed set is viable (≥5sp/≥4cl)
mixed_viability_check <- allchronic_data |>
  filter(grepl("_mixed$", Set)) |>
  group_by(Set, CAS) |>
  summarise(
    n_sp = n_distinct(Species),
    n_cl = n_distinct(Class[!is.na(Class)]),
    .groups = "drop"
  ) |>
  filter(n_sp < 5 | n_cl < 4)
chk(nrow(mixed_viability_check) == 0,
  "Every mixed set passes >=5 species / >=4 classes",
  if (nrow(mixed_viability_check) > 0)
    paste(nrow(mixed_viability_check), "failing mixed sets") else NULL)

# V6: No overlap between standalone and mixed sets for same chemical
overlap_check <- allchronic_data |>
  mutate(in_mixed = grepl("_mixed$", Set)) |>
  group_by(CAS, Species) |>
  summarise(
    has_standalone = any(!in_mixed),
    has_mixed      = any(in_mixed),
    .groups        = "drop"
  ) |>
  filter(has_standalone & has_mixed)
chk(nrow(overlap_check) == 0,
  "No species appears in both a standalone set and that chemical's mixed set",
  if (nrow(overlap_check) > 0) paste(nrow(overlap_check), "overlapping chemical×species") else NULL)

# V7: Unknown-medium rows only in mixed sets
unknown_in_standalone <- allchronic_data |>
  filter(Medium == "Unknown", !grepl("_mixed$", Set))
chk(nrow(unknown_in_standalone) == 0,
  "Unknown-medium rows only appear in mixed sets",
  if (nrow(unknown_in_standalone) > 0) paste(nrow(unknown_in_standalone), "rows") else NULL)

# V8: ANZG freshwater variants appear as distinct Set values (never collapsed)
anzg_fw_sets <- allchronic_data |>
  filter(Source == "anzg", Medium %in% fw_family) |>
  distinct(Chemical, Medium, Set)
all_fw_distinct <- !any(duplicated(anzg_fw_sets$Set))
chk(all_fw_distinct,
  "ANZG freshwater variants are distinct Set values (never collapsed)")

# V9: Set key uniqueness (each Set maps to exactly one CAS)
set_cas_map <- allchronic_data |>
  distinct(Set, CAS) |>
  group_by(Set) |>
  filter(n() > 1) |>
  ungroup()
chk(nrow(set_cas_map) == 0, "Set keys are unique (1 CAS per Set)",
  if (nrow(set_cas_map) > 0) paste(nrow(set_cas_map), "conflicting Set keys") else NULL)

# V10: Mixed sets have one row per species
mixed_sp_dups <- allchronic_data |>
  filter(grepl("_mixed$", Set)) |>
  group_by(Set, Species) |>
  filter(n() > 1) |>
  ungroup()
chk(nrow(mixed_sp_dups) == 0,
  "Mixed sets have one row per species",
  if (nrow(mixed_sp_dups) > 0) paste(nrow(mixed_sp_dups), "duplicate species in mixed sets") else NULL)

# V11: Basic data quality
chk(!anyNA(allchronic_data$Species), "Species: no NA")
chk(!anyNA(allchronic_data$Conc),    "Conc: no NA")
chk(all(allchronic_data$Conc > 0),   "Conc: all > 0")
chk(!anyNA(allchronic_data$Set),     "Set: no NA")

# V12: No placeholder or empty Species values (guards against re-introduction of coined names)
bad_species <- allchronic_data |>
  filter(
    is.na(Species) | trimws(Species) == "" |
    grepl("^Unknown", Species) | grepl("no name in source", Species, ignore.case = TRUE)
  )
chk(nrow(bad_species) == 0,
  "Species: no NA, empty, or placeholder values",
  if (nrow(bad_species) > 0)
    paste(nrow(bad_species), "rows:", paste(unique(head(bad_species$Species, 5)), collapse = "; "))
  else NULL)

if (!checks_passed) stop("Validation FAILED — see above.")
cat("All validation checks PASSED.\n\n")

# ============================================================
# STEP E — Save package data
# ============================================================

cat("== Step E: Save and report ==\n\n")

save(allchronic_data, file = "data/allchronic_data.rda", compress = "bzip2")
rda_kb <- round(file.size("data/allchronic_data.rda") / 1024, 1)
cat(sprintf("Saved: data/allchronic_data.rda (%.1f KB)\n\n", rda_kb))

# ============================================================
# REPORTS
# ============================================================

# --- Stage 6 integration report ---
today <- format(Sys.Date(), "%Y-%m-%d")

set_summary <- allchronic_data |>
  mutate(medium_type = case_when(
    grepl("_mixed$", Set)                              ~ "mixed",
    Medium == "Marine"                                 ~ "marine",
    Medium %in% fw_family                              ~ "freshwater-family",
    TRUE                                               ~ "other"
  )) |>
  group_by(medium_type) |>
  summarise(n_sets = n_distinct(Set), .groups = "drop")

report6_lines <- c(
  "# Stage 6 Integration Audit Report",
  "",
  paste0("Generated: ", today, " (Stage 6/7 redesign)"),
  "Script: data-raw/alldata/DATASET.R",
  "",
  "## 1. Input row counts",
  "",
  "| Source | Input rows |",
  "|--------|-----------|",
  paste0("| uncurated (Stage 4e) | ", nrow(uncurated_raw), " |"),
  paste0("| anzg_data | ", nrow(anzg_data), " |"),
  paste0("| ccme_data | ", nrow(ccme_data), " |"),
  paste0("| aims_data | ", nrow(aims_data), " |"),
  paste0("| csiro_data | ", nrow(csiro_data), " |"),
  paste0("| **Total pre-exclusion** | **", nrow(all_rows), "** |"),
  "",
  "## 2. Aims/CSIRO within-source aggregation",
  "",
  paste0("- AIMS:  ", nrow(aims_data), " input rows → ", nrow(aims_layer), " aggregated"),
  paste0("- CSIRO: ", nrow(csiro_data), " input rows → ", nrow(csiro_layer), " aggregated"),
  paste0("- AIMS NA/empty-Species rows dropped (S6-D4 — no taxon assignable): ", n_aims_no_species),
  paste0("- CSIRO NA/empty-Species rows dropped (S6-D4 — no taxon assignable): ", n_csiro_no_species),
  "",
  "## 3. Source-priority exclusion",
  "",
  "| Rule | Rows excluded |",
  "|------|--------------|",
  paste0("| ANZG freshwater-family (broad, per chemical) | ", n_anzg_fw_excl, " |"),
  paste0("| ANZG marine (per chemical × Marine) | ", n_anzg_marine_excl, " |"),
  paste0("| CCME (per chemical × medium) | ", n_ccme_excl, " |"),
  paste0("| Preference hierarchy (aims > csiro > uncurated) | ", n_pref_excl, " |"),
  "",
  "## 4. Retained rows by source × medium",
  "",
  "| Source | Medium | Rows |",
  "|--------|--------|------|",
  paste(sprintf("| %s | %s | %d |",
    retained_by_source_medium$source,
    retained_by_source_medium$medium,
    retained_by_source_medium$n), collapse = "\n"),
  paste0("| **Total** | | **", nrow(retained), "** |"),
  "",
  "## 5. CCME notes",
  "",
  paste0("CCME medium in data: ", paste(unique(ccme_layer$medium), collapse=", ")),
  paste0("CCME input rows: ", nrow(ccme_data), "; retained after ANZG exclusion: ",
         sum(allchronic_data$Source == "ccme")),
  "NOTE: ccme Medium is 'Freshwater' in source data. Issue #34 pending.",
  "",
  "## 6. Validation",
  "",
  if (checks_passed) "All validation checks PASSED." else "VALIDATION FAILED — see console output.",
  ""
)
writeLines(report6_lines, "data-raw/alldata/stage6-integration-report.md")
cat("Written: data-raw/alldata/stage6-integration-report.md\n")

# --- Stage 7 eligibility report ---
set_med_counts <- allchronic_data |>
  mutate(set_type = case_when(
    grepl("_mixed$", Set) ~ "mixed",
    TRUE                   ~ medium_token(Medium)
  )) |>
  group_by(set_type) |>
  summarise(n_sets = n_distinct(Set), n_rows = n(), .groups = "drop") |>
  arrange(desc(n_rows))

vt_counts <- count(allchronic_data, ValueTier) |> arrange(desc(n))
src_counts <- count(allchronic_data, Source) |> arrange(desc(n))

report7_lines <- c(
  "# Stage 7 Eligibility Report",
  "",
  paste0("Generated: ", today, " (Stage 6/7 redesign)"),
  "Script: data-raw/alldata/DATASET.R",
  "",
  "---",
  "",
  "## 1. Output structure",
  "",
  paste0("Total rows in allchronic_data: ", nrow(allchronic_data)),
  paste0("Distinct Set keys: ", n_distinct(allchronic_data$Set)),
  paste0("Distinct chemicals: ", n_distinct(allchronic_data$Chemical)),
  paste0("Distinct species: ", n_distinct(allchronic_data$Species)),
  paste0("Columns: ", ncol(allchronic_data), " (Species, Conc, Chemical, CAS, Medium, Source, ValueTier,"),
  "  AnyChronicConvApplied, EffectCategory, Class, Kingdom, Phylum, Order, Family, Genus,",
  "  TaxonomyProvenance, NRecords, SourcesContributing, AnyAcrApplied, AnyConcFlagged,",
  "  GeomeanFlagged, LifestageMixed, DurationMixed, Set)",
  paste0("  EffectCategory: effect_category of the selected endpoint (traditional only;",
         " NA for curated sources)"),
  "",
  "## 2. Set counts by type",
  "",
  "| Set type | n_sets | n_rows |",
  "|----------|--------|--------|",
  paste(sprintf("| %s | %d | %d |",
    set_med_counts$set_type, set_med_counts$n_sets, set_med_counts$n_rows), collapse="\n"),
  "",
  "## 3. Medium viability summary",
  "",
  paste0("Real-medium combinations assessed: ", nrow(viability)),
  paste0("Viable: ", sum(viability$viable), " (",
         round(100 * sum(viability$viable)/nrow(viability), 1), "%)"),
  paste0("  — curated-backed: ", sum(viability$has_curated)),
  paste0("  — uncurated only (≥5sp/≥4cl): ", sum(!viability$has_curated & viability$viable)),
  paste0("  — non-viable: ", sum(!viability$viable)),
  paste0("Mixed sets emitted: ", nrow(mixed_viability)),
  paste0("Unknown rows dropped (FW+Marine both viable): ", n_unknown_dropped),
  "",
  "## 4. ValueTier breakdown",
  "",
  "| ValueTier | Rows |",
  "|-----------|------|",
  paste(sprintf("| %s | %d |", vt_counts$ValueTier, vt_counts$n), collapse = "\n"),
  "",
  "## 5. Source breakdown",
  "",
  "| Source | Rows |",
  "|--------|------|",
  paste(sprintf("| %s | %d |", src_counts$Source, src_counts$n), collapse = "\n"),
  "",
  paste0("## 5a. EffectCategory breakdown (C3)"),
  "",
  paste0("EffectCategory is NA for all curated rows (anzg, ccme, aims, csiro); ",
         "uncurated rows carry the traditional endpoint code of the selected value."),
  paste0("- NA EffectCategory (curated rows): ",
         sum(is.na(allchronic_data$EffectCategory))),
  paste0("- Non-NA EffectCategory (uncurated rows): ",
         sum(!is.na(allchronic_data$EffectCategory))),
  "",
  "## 6. Validation",
  "",
  if (checks_passed) "All 12 validation checks PASSED." else "VALIDATION FAILED.",
  "",
  "## 7. Files produced",
  "",
  paste0("- `data/allchronic_data.rda` — ", nrow(allchronic_data), " rows × ", ncol(allchronic_data),
         " cols, ", rda_kb, " KB"),
  "- `data-raw/alldata/stage6-integration-report.md`",
  "- `data-raw/alldata/stage7-eligibility-report.md` (this file)",
  "",
  "**Untracked (do NOT commit):**",
  "- `data-raw/alldata/uncurated_raw_aggregated.csv`",
  ""
)
writeLines(report7_lines, "data-raw/alldata/stage7-eligibility-report.md")
cat("Written: data-raw/alldata/stage7-eligibility-report.md\n\n")

cat("=== Files to commit (user action required) ===\n")
cat("  [ ] data-raw/alldata/DATASET.R\n")
cat("  [ ] R/get_ssddata.R\n")
cat("  [ ] R/allchronic_data.R\n")
cat("  [ ] data/allchronic_data.rda\n")
cat("  [ ] man/*.Rd  (after devtools::document())\n")
cat("  [ ] data-raw/alldata/stage6-integration-report.md\n")
cat("  [ ] data-raw/alldata/stage7-eligibility-report.md\n")
cat("  ( ) data-raw/alldata/alldata_integrated.csv  [NOT produced — not needed]\n")
