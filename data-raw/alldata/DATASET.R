# data-raw/alldata/DATASET.R
#
# Complete alldata pipeline: Stage 4e aggregation + Stage 6/7 integration.
# Run from the repository root (WSL or Windows Positron; no DB connection required).
#
# Stage 4e:
#   Input:  data-raw/alldata/uncurated_raw_dedup_enriched.csv  [UNTRACKED]
#   Output: data-raw/alldata/uncurated_raw_aggregated.csv      [UNTRACKED — intermediate]
#           data-raw/alldata/allchronic_data_source.csv        [UNTRACKED — source export]
#           data-raw/alldata/stage4e-aggregation-report.md     [tracked]
#           data-raw/alldata/stage4e-statistic-type-excluded.csv [tracked, audit]
#
# Stage 6/7:
#   Inputs: uncurated aggregated output (in-memory from Stage 4e above)
#           curated .rda objects; data-raw/alldata/curated_cas_lookup.csv
#           data-raw/alldata/species_resolution_curated.csv
#           data-raw/cas_parent_lookup_all.csv
#   Output: data/allchronic_data.rda                             [tracked — package data]
#           data-raw/alldata/stage6-integration-report.md        [tracked]
#           data-raw/alldata/stage7-eligibility-report.md        [tracked]

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
# STAGE 4E — Aggregation: one value per species × chemical × medium
# ============================================================
# Implements Section 3.4.4 of Warne et al. 2025 (ANZG technical guidance),
# with an explicit three-tier statistic-type preference per Sections 3.4.2.1/3.4.2.2.
# Input:  data-raw/alldata/uncurated_raw_dedup_enriched.csv  (~228 MB, untracked)
# Output: data-raw/alldata/uncurated_raw_aggregated.csv      (untracked — written below,
#         then passed in-memory to Stage 6/7 without re-reading)
#         data-raw/alldata/allchronic_data_source.csv        (untracked — source export)
#         data-raw/alldata/stage4e-aggregation-report.md     (tracked)
#         data-raw/alldata/stage4e-statistic-type-excluded.csv (tracked, audit)
#
# Read with guess_max = Inf per project-wide convention (CLAUDE.md Section 5).

# Concentration plausibility thresholds (µg/L)
LOWER_HARD <- 1e-5 # hard exclude
LOWER_SOFT <- 1e-3 # soft flag, retain
UPPER_SOFT <- 1e6 # soft flag, retain
UPPER_HARD <- 1e8 # hard exclude

# Detect genus-rank accepted_name entries (bare genus, or qualified with
# sp./spp./cf./aff./nr., or name == genus field exactly).
flag_genus_rank <- function(name, genus = NULL) {
  nm <- trimws(name)
  core <- trimws(sub(
    "\\s+(spp|sp|cf|aff|nr|gen)\\.?(\\s.*)?$",
    "",
    nm,
    ignore.case = TRUE
  ))
  no_epithet <- !grepl("\\s", core)
  had_qualifier <- grepl(
    "\\b(spp|sp|cf|aff|nr)\\.?(\\s|$)",
    nm,
    ignore.case = TRUE
  )
  out <- no_epithet | had_qualifier
  if (!is.null(genus)) {
    out <- out | (!is.na(genus) & nm == trimws(genus))
  }
  out
}

# Map statistic_type to a Warne et al. 2025 tier.
# Accepts decimal ECx/ICx/LCx suffixes (e.g. EC2.52, EC6.99) — those with
# x <= 10 resolve as appropriate_no_conversion rather than UNCLASSIFIED.
classify_tier <- function(st) {
  s <- trimws(toupper(as.character(st)))
  is_x_pat <- grepl("^(EC|IC|LC)(\\d+(?:\\.\\d+)?)$", s, perl = TRUE)
  x_val <- suppressWarnings(
    as.numeric(sub("^(?:EC|IC|LC)(\\d+(?:\\.\\d+)?)$", "\\1", s, perl = TRUE))
  )
  x_val[!is_x_pat] <- NA_real_
  dplyr::case_when(
    is.na(st) ~ "UNCLASSIFIED (NA)",
    s %in% c("NEC", "NSEC", "BEC10") ~ "preferred_negligible",
    s %in% c("NOEC", "NOEL") ~ "negligible_no_conversion",
    s %in% c("LOEC", "LOEL") ~ "low_effect_conv_2.5",
    s == "MATC" ~ "low_effect_conv_2",
    is_x_pat & !is.na(x_val) & x_val <= 10 ~ "appropriate_no_conversion",
    is_x_pat &
      !is.na(x_val) &
      x_val > 10 &
      x_val <= 20 ~ "less_pref_no_conversion",
    is_x_pat & !is.na(x_val) & x_val == 50 ~ "median_effect_conv_5",
    is_x_pat & !is.na(x_val) ~ "undefined_x_needs_ruling",
    TRUE ~ "UNCLASSIFIED"
  )
}

# Coarse action derived from tier: accepted / convert / exclude.
stat_action_for_tier <- function(stat_tier) {
  dplyr::case_when(
    stat_tier %in%
      c(
        "preferred_negligible",
        "negligible_no_conversion",
        "appropriate_no_conversion",
        "less_pref_no_conversion"
      ) ~ "accepted",
    stat_tier %in%
      c(
        "low_effect_conv_2.5",
        "low_effect_conv_2",
        "median_effect_conv_5"
      ) ~ "convert",
    TRUE ~ "exclude"
  )
}

# Conversion factor for chronic/subchronic 'convert' records; NA otherwise.
conv_factor_for_tier <- function(stat_tier) {
  dplyr::case_when(
    stat_tier == "median_effect_conv_5" ~ 5,
    stat_tier == "low_effect_conv_2.5" ~ 2.5,
    stat_tier == "low_effect_conv_2" ~ 2,
    TRUE ~ NA_real_
  )
}

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
stopifnot(n_clean > 380000) # expect ~381,382

# Coerce literal "Not stated" in majorgroup / class to NA (4 rows)
n_not_stated_majorgroup <- sum(clean$majorgroup == "Not stated", na.rm = TRUE)
n_not_stated_class <- sum(clean$class == "Not stated", na.rm = TRUE)
clean <- clean |>
  mutate(
    majorgroup = if_else(majorgroup == "Not stated", NA_character_, majorgroup),
    class = if_else(class == "Not stated", NA_character_, class)
  )
message(
  "Coerced 'Not stated' → NA: ",
  n_not_stated_majorgroup,
  " majorgroup rows, ",
  n_not_stated_class,
  " class rows"
)

# ---------------------------------------------------------------------------
# Step 1 — Unit conversion: wqbench mg/L → µg/L
# ---------------------------------------------------------------------------

n_mgL <- sum(clean$conc_unit == "mg/L", na.rm = TRUE)
clean <- clean |>
  mutate(
    conc_value = if_else(conc_unit == "mg/L", conc_value * 1000, conc_value),
    conc_unit = if_else(conc_unit == "mg/L", "ug/L", conc_unit)
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
  filter(
    !(test_class == "acute" & (is.na(acr_eligible) | acr_eligible != TRUE))
  )
n_dropped_acute_non_eligible <- n_before_acute_drop - nrow(clean)
message("Dropped acute-non-eligible: ", n_dropped_acute_non_eligible, " rows")

# 2c. Drop genus-rank accepted_name entries (uncurated pipeline only)
n_before_genus_drop <- nrow(clean)
genus_rank_excluded <- clean |>
  filter(flag_genus_rank(accepted_name, genus))
genus_drop_by_source <- genus_rank_excluded |>
  count(source, name = "n_dropped")
n_distinct_genus_rank <- n_distinct(genus_rank_excluded$accepted_name)
clean <- clean |>
  filter(!flag_genus_rank(accepted_name, genus))
n_dropped_genus <- n_before_genus_drop - nrow(clean)
message(
  "Dropped genus-rank species: ",
  n_dropped_genus,
  " rows (",
  n_distinct_genus_rank,
  " distinct names)"
)
write_csv(
  genus_rank_excluded,
  "data-raw/alldata/stage4e-genus-rank-excluded.csv"
)

# 2d. Classify statistic types; exclude records with no defined Warne 2025 treatment.
# Records with undefined ECx percentiles (20 < x < 50 or x > 50), regulatory
# summary endpoints (NOAEL, LOAEL, NOAEC, LOAEC), or unrecognised types are
# excluded — no conservative conversion exists to place them on the NOEC/EC50 scale.
n_before_stat_drop <- nrow(clean)
clean <- clean |>
  mutate(
    stat_tier = classify_tier(statistic_type),
    stat_action = stat_action_for_tier(stat_tier),
    conv_factor = conv_factor_for_tier(stat_tier)
  )

stat_excluded <- clean |> filter(stat_action == "exclude")
stat_excl_by_type_source <- stat_excluded |>
  count(statistic_type, stat_tier, source, name = "n_excluded") |>
  arrange(desc(n_excluded))
write_csv(
  stat_excluded |>
    select(
      casnumber_grouped,
      accepted_name,
      source,
      statistic_type,
      stat_tier,
      test_class,
      conc_ug_L
    ),
  "data-raw/alldata/stage4e-statistic-type-excluded.csv"
)

clean <- clean |> filter(stat_action != "exclude")
n_dropped_stat_excl <- n_before_stat_drop - nrow(clean)
message("Step 2d — stat_action='exclude' rows dropped: ", n_dropped_stat_excl)

n_aggregation_input <- nrow(clean)
message("Rows entering aggregation pipeline: ", n_aggregation_input)

# ---------------------------------------------------------------------------
# Step 2e — Non-traditional endpoint filter (Warne et al. 2025 §3.2.1)
# ---------------------------------------------------------------------------
# Excludes endpoints classified as non-traditional (PSE, BCH, BEH, LUM, MOR)
# from aggregation. Rows are flagged with an excluded_reason and removed; they
# cannot win the within-group minimum. Traditional endpoints (MORT, IMM, GRO,
# DVP, POP, REP, HAT, ABD) proceed to aggregation.

traditional_endpoints <- c(
  "MORT",
  "IMM",
  "GRO",
  "DVP",
  "POP",
  "REP",
  "HAT",
  "ABD"
)
non_traditional_endpoints <- c("PSE", "BCH", "BEH", "LUM", "MOR")

n_before_nontrad <- nrow(clean)

nontrad_excl_by_code_source <- clean |>
  filter(effect_category %in% non_traditional_endpoints) |>
  count(effect_category, source, name = "n_excluded") |>
  arrange(effect_category, source)

# Species/chemicals that lose their only remaining value (all rows non-traditional)
before_nontrad_groups <- clean |>
  distinct(casnumber_grouped, accepted_name, medium)

nontrad_excluded_groups <- clean |>
  filter(effect_category %in% non_traditional_endpoints) |>
  distinct(casnumber_grouped, accepted_name, medium)

# B2 metrics: how many groups survive at all after filter?
post_nontrad_groups <- clean |>
  filter(!effect_category %in% non_traditional_endpoints) |>
  distinct(casnumber_grouped, accepted_name, medium)

# Groups that had ANY non-traditional rows (some or all)
had_nontrad <- nontrad_excluded_groups
# Groups that lose ALL values (present before B1, absent after)
lost_all_groups <- anti_join(
  before_nontrad_groups,
  post_nontrad_groups,
  by = c("casnumber_grouped", "accepted_name", "medium")
)

n_lost_all_species_chem_med <- nrow(lost_all_groups)
n_lost_all_species <- n_distinct(lost_all_groups$accepted_name)
n_lost_all_chemicals <- n_distinct(lost_all_groups$casnumber_grouped)
n_had_some_nontrad <- nrow(had_nontrad) - n_lost_all_species_chem_med

clean <- clean |>
  filter(!effect_category %in% non_traditional_endpoints)

n_dropped_nontrad <- n_before_nontrad - nrow(clean)
message(
  "Step 2e — non-traditional endpoint exclusion: ",
  n_dropped_nontrad,
  " rows removed"
)
message(
  "  Groups losing ALL values (dropped entirely): ",
  n_lost_all_species_chem_med,
  " (",
  n_lost_all_species,
  " species × ",
  n_lost_all_chemicals,
  " chemicals)"
)
message("  Groups losing SOME values: ", n_had_some_nontrad)

# Confirm all remaining effect_category values are traditional
surviving_ec <- unique(clean$effect_category[!is.na(clean$effect_category)])
non_trad_still_present <- setdiff(surviving_ec, traditional_endpoints)
if (length(non_trad_still_present) > 0) {
  stop(
    "Post-B1 validation: non-traditional codes still present: ",
    paste(non_trad_still_present, collapse = ", ")
  )
}
message(
  "Post-B1 validation: all surviving effect_category values are traditional or NA."
)

# ---------------------------------------------------------------------------
# Step 3 — ACR conversion for retained acute records
# ---------------------------------------------------------------------------

acr_by_source <- clean |>
  filter(test_class == "acute", acr_eligible == TRUE) |>
  count(source, name = "n_converted")
clean <- clean |>
  mutate(
    conc_ug_L = if_else(
      test_class == "acute" & acr_eligible == TRUE,
      conc_ug_L / 10,
      conc_ug_L
    ),
    acr_applied = if_else(
      test_class == "acute" & acr_eligible == TRUE,
      TRUE,
      acr_applied
    )
  )
n_acr_converted <- sum(acr_by_source$n_converted)
message("ACR conversion applied to ", n_acr_converted, " acute-eligible rows")

# ---------------------------------------------------------------------------
# Step 3a — Chronic/subchronic median and low-effect conversion
# ---------------------------------------------------------------------------
# Applies Warne et al. 2025 Section 3.4.2.1 factors to chronic/subchronic records
# in the 'convert' tier, placing them on a NOEC-equivalent scale:
#   EC50/IC50/LC50 (chronic/subchronic) ÷ 5
#   LOEC/LOEL                           ÷ 2.5
#   MATC                                ÷ 2
# Acute EC50/IC50/LC50 are handled by ACR (Step 3) only — not chronic-converted.
# Applied before the plausibility filter so thresholds act on final converted values.

clean <- clean |>
  mutate(
    chronic_conv_applied = test_class %in%
      c("chronic", "subchronic") &
      stat_action == "convert",
    chronic_conv_factor = if_else(chronic_conv_applied, conv_factor, NA_real_),
    conc_ug_L = if_else(
      chronic_conv_applied,
      conc_ug_L / conv_factor,
      conc_ug_L
    )
  )

n_chronic_conv_total <- sum(clean$chronic_conv_applied, na.rm = TRUE)
chronic_conv_by_type <- clean |>
  filter(chronic_conv_applied) |>
  count(statistic_type, chronic_conv_factor, source, name = "n_converted") |>
  arrange(desc(n_converted))
message(
  "Step 3a — chronic/subchronic conversions applied: ",
  n_chronic_conv_total,
  " rows"
)

# Validate: every surviving chronic/subchronic 'convert' record was converted
n_conv_not_applied <- clean |>
  filter(
    test_class %in% c("chronic", "subchronic"),
    stat_action == "convert"
  ) |>
  filter(!chronic_conv_applied | is.na(chronic_conv_factor)) |>
  nrow()
stopifnot(n_conv_not_applied == 0)

# ---------------------------------------------------------------------------
# Step 3b — Concentration plausibility filter
# ---------------------------------------------------------------------------
# Applied after both ACR and chronic conversions so all concentrations are
# in µg/L and on their final scale. Hard-excluded rows are physically
# implausible and dropped. Soft-flagged rows are retained but used only as a
# fallback in Step 4 when no ok-range records exist in a group.

clean <- clean |>
  mutate(
    conc_plausibility = case_when(
      conc_ug_L < LOWER_HARD ~ "low_hard",
      conc_ug_L < LOWER_SOFT ~ "low_soft",
      conc_ug_L > UPPER_HARD ~ "high_hard",
      conc_ug_L > UPPER_SOFT ~ "high_soft",
      TRUE ~ "ok"
    )
  )

hard_excluded <- clean |>
  filter(conc_plausibility %in% c("low_hard", "high_hard"))
clean <- clean |>
  filter(!conc_plausibility %in% c("low_hard", "high_hard"))

n_hard_excluded <- nrow(hard_excluded)
n_hard_low <- sum(hard_excluded$conc_plausibility == "low_hard")
n_hard_high <- sum(hard_excluded$conc_plausibility == "high_hard")
n_soft_flagged <- sum(clean$conc_plausibility %in% c("low_soft", "high_soft"))
n_soft_low <- sum(clean$conc_plausibility == "low_soft")
n_soft_high <- sum(clean$conc_plausibility == "high_soft")

hard_by_source <- hard_excluded |>
  count(source, conc_plausibility, name = "n")
soft_by_source <- clean |>
  filter(conc_plausibility %in% c("low_soft", "high_soft")) |>
  count(source, conc_plausibility, name = "n")

hard_excluded_listing <- hard_excluded |>
  select(
    casnumber_grouped,
    accepted_name,
    source,
    statistic_type,
    conc_ug_L,
    conc_plausibility
  ) |>
  arrange(conc_plausibility, conc_ug_L)

n_after_plaus <- nrow(clean)
message(
  "Concentration plausibility: hard-excluded ",
  n_hard_excluded,
  " rows (low_hard: ",
  n_hard_low,
  "; high_hard: ",
  n_hard_high,
  ")"
)
message(
  "Soft-flagged rows retained: ",
  n_soft_flagged,
  " (low_soft: ",
  n_soft_low,
  "; high_soft: ",
  n_soft_high,
  ")"
)
message("Rows after plausibility filter: ", n_after_plaus)

# ---------------------------------------------------------------------------
# Base-frame capture for allchronic_data_source.csv export
# ---------------------------------------------------------------------------
# UIDs assigned here: after all per-record drops (Steps 2a–2e) and all
# conversions (ACR ÷10, chronic ÷factor, Step 3b hard-exclude), but before
# the three-tier preference filter and aggregation.
# Scope: uncurated sources only (anztox, wqbench, envirotox).
clean <- clean |> mutate(record_uid = row_number())
base_frame <- clean

# ---------------------------------------------------------------------------
# Step 3c — Three-tier preference filter
# ---------------------------------------------------------------------------
# Enforces: accepted (NOEC/NOEL/ECx≤20, chronic/subchronic) > chronic_converted
# (EC50/LOEC/MATC ÷ factor, chronic/subchronic) > acute_acr, evaluated per
# species × chemical × medium group. Where chronic data exist for a species,
# all acute fallback records for that species are discarded before aggregation.
#
# Operationalisation note (documented deviation): the preference is applied
# per casnumber_grouped × accepted_name × medium rather than per-chemical as
# implied by the literal Warne 2025 text. A one-value-per-species dataset
# requires per-species resolution: a chemical may have chronic NOEC data for
# some species and only acute LC50 for others, and the fallback should not
# affect those species independently.

clean <- clean |>
  mutate(
    record_tier_rank = case_when(
      stat_action == "accepted" &
        test_class %in% c("chronic", "subchronic") ~ 1L,
      chronic_conv_applied == TRUE ~ 2L,
      test_class == "acute" ~ 3L,
      TRUE ~ NA_integer_
    )
  )

# Assert: every surviving record maps to exactly one rank
unranked <- filter(clean, is.na(record_tier_rank))
if (nrow(unranked) > 0) {
  write_csv(
    unranked |>
      select(
        casnumber_grouped,
        accepted_name,
        source,
        statistic_type,
        test_class,
        stat_action,
        chronic_conv_applied
      ),
    "data-raw/alldata/stage4e-unranked-rows.csv"
  )
  stop(paste(
    nrow(unranked),
    "records have no tier rank — see stage4e-unranked-rows.csv"
  ))
}

# Tier displacement diagnostic: groups where acute records coexist with tier-1/2
# records. Because priority_kept already applies chronic > acute at the source
# level, this count is expected to be ~0; > 0 indicates the priority_kept
# granularity differs from casnumber_grouped × accepted_name × medium.
group_tier_stats <- clean |>
  group_by(casnumber_grouped, accepted_name, medium) |>
  summarise(
    min_tier_rank = min(record_tier_rank),
    max_tier_rank = max(record_tier_rank),
    n_distinct_tiers = n_distinct(record_tier_rank),
    .groups = "drop"
  )
displaced_groups <- group_tier_stats |>
  filter(min_tier_rank < 3L, max_tier_rank == 3L)
n_tier_displacement <- nrow(displaced_groups)
if (n_tier_displacement > 0) {
  write_csv(
    displaced_groups,
    "data-raw/alldata/stage4e-tier-displacement-groups.csv"
  )
  message(
    "Tier displacement diagnostic: ",
    n_tier_displacement,
    " groups — see stage4e-tier-displacement-groups.csv"
  )
} else {
  message("Tier displacement diagnostic: 0 mixed-tier groups")
}

# Count records that will be dropped by tier preference (for report)
n_records_dropped_tier <- clean |>
  group_by(casnumber_grouped, accepted_name, medium) |>
  filter(record_tier_rank > min(record_tier_rank)) |>
  ungroup() |>
  nrow()

# Apply filter: keep only minimum-rank records per group
clean <- clean |>
  group_by(casnumber_grouped, accepted_name, medium) |>
  filter(record_tier_rank == min(record_tier_rank)) |>
  ungroup() |>
  mutate(
    value_tier = case_when(
      record_tier_rank == 1L ~ "accepted",
      record_tier_rank == 2L ~ "chronic_converted",
      record_tier_rank == 3L ~ "acute_acr"
    )
  )

n_after_tier_filter <- nrow(clean)
message(
  "Step 3c tier filter: ",
  n_records_dropped_tier,
  " records dropped; ",
  n_after_tier_filter,
  " remain"
)

# Distribution of surviving records by value_tier
tier_record_counts_pre_agg <- clean |> count(value_tier, name = "n_records")

# Check 5: accepted-tier groups must not contain any converted or ACR-applied records
check5_violations <- filter(
  clean,
  value_tier == "accepted" &
    (acr_applied == TRUE | chronic_conv_applied == TRUE)
)
stopifnot(nrow(check5_violations) == 0)

# Record UIDs that survive into the geomean step; back-fill value_tier for
# these records into base_frame (NA for rows dropped by tier preference).
geomean_input_uids <- clean$record_uid
base_frame <- base_frame |>
  left_join(clean |> select(record_uid, value_tier), by = "record_uid")

# ---------------------------------------------------------------------------
# Step 4 — Step 1 of Section 3.4.4: geometric mean within grouping key
# ---------------------------------------------------------------------------
# Key: casnumber_grouped × accepted_name × medium × effect_category ×
#      statistic_type × duration_hours × life_stage
# NA treated as a distinct level (Decisions D1, D5).
# If max/min > 10 within a group, use min() and set geomean_flagged (Decision D2).
# Two-pass approach: geomean over ok-range records only; soft-flagged records
# used as fallback for groups with no ok records (any_conc_flagged = TRUE).
# value_tier is constant within each group after Step 3c — carried forward.

message("Computing geometric means within Step 1 grouping key ...")

clean_ok <- clean |> filter(conc_plausibility == "ok")
clean_soft <- clean |> filter(conc_plausibility %in% c("low_soft", "high_soft"))

geomean_ok <- clean_ok |>
  group_by(
    casnumber_grouped,
    accepted_name,
    medium,
    effect_category,
    statistic_type,
    duration_hours,
    life_stage
  ) |>
  summarise(
    conc_geomean = exp(mean(log(conc_ug_L))),
    conc_min = min(conc_ug_L),
    conc_max = max(conc_ug_L),
    n_in_group = n(),
    any_acr = any(acr_applied == TRUE, na.rm = TRUE),
    sources_raw = paste(sort(unique(source)), collapse = ","),
    any_conc_flagged = FALSE,
    value_tier = first(value_tier),
    .groups = "drop"
  ) |>
  mutate(
    geomean_flagged = (conc_max / conc_min) > 10,
    conc_step1 = if_else(geomean_flagged, conc_min, conc_geomean)
  )

# Identify grouping-key combinations already covered by ok records
covered_keys <- geomean_ok |>
  distinct(
    casnumber_grouped,
    accepted_name,
    medium,
    effect_category,
    statistic_type,
    duration_hours,
    life_stage
  )

# Soft records NOT covered by ok records: they contribute their own Step-1 groups.
# Captured here so contributing_record_keys can be built for provenance flagging.
soft_contributing <- clean_soft |>
  anti_join(
    covered_keys,
    by = c(
      "casnumber_grouped",
      "accepted_name",
      "medium",
      "effect_category",
      "statistic_type",
      "duration_hours",
      "life_stage"
    )
  )

# Full set of records that feed the geomean step (ok records + non-covered soft).
# Used later to map records back to their Step-1 group for provenance flagging.
contributing_record_keys <- bind_rows(
  clean_ok |>
    select(
      record_uid,
      casnumber_grouped,
      accepted_name,
      medium,
      effect_category,
      statistic_type,
      duration_hours,
      life_stage
    ),
  soft_contributing |>
    select(
      record_uid,
      casnumber_grouped,
      accepted_name,
      medium,
      effect_category,
      statistic_type,
      duration_hours,
      life_stage
    )
)

geomean_soft <- soft_contributing |>
  group_by(
    casnumber_grouped,
    accepted_name,
    medium,
    effect_category,
    statistic_type,
    duration_hours,
    life_stage
  ) |>
  summarise(
    conc_geomean = exp(mean(log(conc_ug_L))),
    conc_min = min(conc_ug_L),
    conc_max = max(conc_ug_L),
    n_in_group = n(),
    any_acr = any(acr_applied == TRUE, na.rm = TRUE),
    sources_raw = paste(sort(unique(source)), collapse = ","),
    any_conc_flagged = TRUE,
    value_tier = first(value_tier),
    .groups = "drop"
  ) |>
  mutate(
    geomean_flagged = (conc_max / conc_min) > 10,
    conc_step1 = if_else(geomean_flagged, conc_min, conc_geomean)
  )

geomean_step <- bind_rows(geomean_ok, geomean_soft) |>
  mutate(step1_group_id = row_number())
n_soft_only_groups <- nrow(geomean_soft)

n_step1_groups <- nrow(geomean_step)
n_singleton_groups <- sum(geomean_step$n_in_group == 1)
n_multi_groups <- n_step1_groups - n_singleton_groups
n_groups_flagged <- sum(geomean_step$geomean_flagged, na.rm = TRUE)
message(
  "Step 1 groups: ",
  n_step1_groups,
  " total; ",
  n_singleton_groups,
  " singletons; ",
  n_multi_groups,
  " multi-record; ",
  n_groups_flagged,
  " geomean_flagged"
)
message("Soft-only fallback groups (Step 1): ", n_soft_only_groups)

top_flagged <- geomean_step |>
  filter(geomean_flagged) |>
  mutate(spread_ratio = conc_max / conc_min) |>
  arrange(desc(spread_ratio)) |>
  slice_head(n = 10) |>
  select(
    casnumber_grouped,
    accepted_name,
    effect_category,
    statistic_type,
    duration_hours,
    life_stage,
    n_in_group,
    conc_min,
    conc_max,
    spread_ratio
  )

# ---------------------------------------------------------------------------
# Step 5 — Step 2 of Section 3.4.4: lowest value within each endpoint
# ---------------------------------------------------------------------------

message("Computing within-endpoint minimum (Step 2) ...")
# effect_category is part of the group key here — retained for C1 carry-through.
endpoint_step <- geomean_step |>
  group_by(casnumber_grouped, accepted_name, medium, effect_category) |>
  summarise(
    conc_step2 = min(conc_step1),
    n_combinations = n(),
    any_acr = any(any_acr, na.rm = TRUE),
    geomean_flagged = any(geomean_flagged, na.rm = TRUE),
    any_conc_flagged = any(any_conc_flagged, na.rm = TRUE),
    # lifestage_mixed: has both NA and non-NA life_stage in this endpoint group
    lifestage_mixed = any(!is.na(life_stage)) & any(is.na(life_stage)),
    # duration_mixed: has both NA and non-NA duration_hours in this endpoint group
    duration_mixed = any(!is.na(duration_hours)) & any(is.na(duration_hours)),
    sources_raw = paste(
      sort(unique(unlist(strsplit(sources_raw, ",")))),
      collapse = ","
    ),
    n_records = sum(n_in_group),
    value_tier = first(value_tier),
    .groups = "drop"
  )

n_step2_groups <- nrow(endpoint_step)
message(
  "Step 2 groups (casnumber × species × medium × effect_category): ",
  n_step2_groups
)

# Counts for audit
n_na_lifestage_groups <- sum(is.na(geomean_step$life_stage))
n_na_duration_groups <- sum(is.na(geomean_step$duration_hours))
n_lifestage_mixed <- sum(endpoint_step$lifestage_mixed, na.rm = TRUE)
n_duration_mixed <- sum(endpoint_step$duration_mixed, na.rm = TRUE)

# ---------------------------------------------------------------------------
# Step 6 — Step 3 of Section 3.4.4: lowest value across endpoints
# ---------------------------------------------------------------------------

message("Computing across-endpoint minimum (Step 3) ...")

# C2: Count groups with tied minimum conc_step2 across endpoints.
# Alphabetical tiebreak on effect_category is applied below (arrange + first()).
n_groups_with_ties <- endpoint_step |>
  group_by(casnumber_grouped, accepted_name, medium) |>
  summarise(
    min_conc = min(conc_step2),
    n_at_min = sum(conc_step2 == min(conc_step2)),
    .groups = "drop"
  ) |>
  filter(n_at_min > 1) |>
  nrow()
message(
  "Step 6 tie count (groups with multiple endpoints sharing the minimum): ",
  n_groups_with_ties
)

# C1: Retain the effect_category of the selected (minimum-conc) endpoint.
# Tiebreak rule: alphabetical order of effect_category (deterministic).
# arrange() before group_by so first() picks the alphabetically earliest code.
species_step <- endpoint_step |>
  arrange(
    casnumber_grouped,
    accepted_name,
    medium,
    conc_step2,
    effect_category
  ) |>
  group_by(casnumber_grouped, accepted_name, medium) |>
  summarise(
    conc_ug_L = first(conc_step2),
    effect_category = first(effect_category), # C1: from the winning endpoint
    n_records = sum(n_records),
    any_acr_applied = any(any_acr, na.rm = TRUE),
    geomean_flagged = any(geomean_flagged, na.rm = TRUE),
    any_conc_flagged = any(any_conc_flagged, na.rm = TRUE),
    lifestage_mixed = any(lifestage_mixed, na.rm = TRUE),
    duration_mixed = any(duration_mixed, na.rm = TRUE),
    sources_contributing = paste(
      sort(unique(unlist(strsplit(sources_raw, ",")))),
      collapse = ","
    ),
    value_tier = first(value_tier),
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
  select(
    accepted_name,
    kingdom,
    phylum,
    class,
    order_taxon,
    family,
    genus,
    majorgroup,
    taxonomy_provenance
  ) |>
  mutate(
    majorgroup = if_else(majorgroup == "Not stated", NA_character_, majorgroup),
    class = if_else(class == "Not stated", NA_character_, class)
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
  warning(paste(
    "More missing taxonomy rows than expected:",
    n_missing_taxonomy
  ))
}
message(
  "Missing kingdom (expected ≤5 from Sialis genus-only): ",
  n_missing_taxonomy
)

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
  warning(
    n_cas_multi_name,
    " casnumber_grouped values have multiple chemicalname_grouped entries — taking first"
  )
}
chemical_names <- chemical_names |>
  group_by(casnumber_grouped) |>
  slice(1) |>
  ungroup()

output <- aggregated |>
  left_join(chemical_names, by = "casnumber_grouped") |>
  mutate(any_chronic_conv_applied = (value_tier == "chronic_converted")) |>
  select(
    casnumber_grouped,
    chemicalname_grouped,
    accepted_name,
    medium,
    conc_ug_L,
    effect_category, # C1: retained effect_category of selected endpoint
    majorgroup,
    kingdom,
    phylum,
    class,
    order_taxon,
    family,
    genus,
    taxonomy_provenance,
    n_records,
    sources_contributing,
    any_acr_applied,
    any_chronic_conv_applied,
    any_conc_flagged,
    geomean_flagged,
    lifestage_mixed,
    duration_mixed,
    value_tier
  )

# ---------------------------------------------------------------------------
# Validation checks
# ---------------------------------------------------------------------------

message("Running validation checks ...")

# 1. No duplicate rows on the output key
stopifnot(
  nrow(output) ==
    nrow(distinct(output, casnumber_grouped, accepted_name, medium))
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
  is.logical(output$duration_mixed),
  is.logical(output$any_chronic_conv_applied)
)

# 6. No hard-excluded concentrations in output
# Tiny relative tolerance handles exp(log(x)) ≈ x FP rounding at LOWER_HARD.
stopifnot(all(output$conc_ug_L >= LOWER_HARD * (1 - 1e-9)))
stopifnot(all(output$conc_ug_L <= UPPER_HARD * (1 + 1e-9)))

# 7. any_conc_flagged is logical with no NAs
stopifnot(is.logical(output$any_conc_flagged))
stopifnot(!any(is.na(output$any_conc_flagged)))

# 8. No stat_action == "exclude" records in clean (redundant guard)
stopifnot(!any(clean$stat_action == "exclude"))

# 9. value_tier is non-NA and valid for all output rows
stopifnot(all(!is.na(output$value_tier)))
stopifnot(all(
  output$value_tier %in% c("accepted", "chronic_converted", "acute_acr")
))

# 10. value_tier is unique per casnumber × species × medium (constant per group)
stopifnot(
  nrow(output) ==
    nrow(distinct(output, casnumber_grouped, accepted_name, medium, value_tier))
)

# 11. any_acr_applied is consistent with value_tier:
#     non-acute_acr groups must have any_acr_applied == FALSE;
#     acute_acr groups must have any_acr_applied == TRUE
stopifnot(!any(output$any_acr_applied[output$value_tier != "acute_acr"]))
stopifnot(all(output$any_acr_applied[output$value_tier == "acute_acr"]))

# 12. any_chronic_conv_applied is TRUE exactly when value_tier == "chronic_converted"
stopifnot(
  all(
    output$any_chronic_conv_applied ==
      (output$value_tier == "chronic_converted")
  )
)

# 13. effect_category is never NA in output (B1 excluded all rows with NA or non-traditional
#     effect_category, so any surviving row must have a non-NA traditional code — unless the
#     species×chemical×medium group had ONLY NA effect_category rows, which step 2a already dropped)
stopifnot(!anyNA(output$effect_category))

# 14. All output effect_category values are in the traditional set
stopifnot(all(output$effect_category %in% traditional_endpoints))

message("All validation checks passed.")

# ---------------------------------------------------------------------------
# Provenance computation and allchronic_data_source.csv export
# ---------------------------------------------------------------------------
# Scope: uncurated sources only (anztox, wqbench, envirotox). Curated sources
# are handled separately via their .rda objects and do not appear here.
# Capture point: after all per-record filters and conversions but before
# aggregation. Non-traditional endpoints are excluded (PSE/BCH/BEH/LUM/MOR),
# matching the SSD scope of the published values.
message("Computing provenance flags for allchronic_data_source.csv ...")

# For each casnumber_grouped × accepted_name × medium, the winning Step-1 group
# is the one whose conc_step1 equals the final published value.  The nested
# minima (Step 1 → Step 2 → Step 3) reduce to a global min, so argmin of
# conc_step1 is exact.  Effect-category tiebreak mirrors the pipeline's
# arrange-then-first() logic used in Step 6.

# Step-2 level: min conc_step1 per (cas × species × medium × effect_cat)
provenance_step2 <- geomean_step |>
  group_by(casnumber_grouped, accepted_name, medium, effect_category) |>
  summarise(conc_step2_prov = min(conc_step1), .groups = "drop")

# Step-3 level: winning effect_cat per (cas × species × medium)
provenance_step3 <- provenance_step2 |>
  arrange(
    casnumber_grouped,
    accepted_name,
    medium,
    conc_step2_prov,
    effect_category
  ) |>
  group_by(casnumber_grouped, accepted_name, medium) |>
  summarise(
    final_conc_ug_L = first(conc_step2_prov),
    winning_ec = first(effect_category),
    .groups = "drop"
  )

# Winning Step-1 groups: those in the winning effect_cat whose conc_step1
# equals the final published value (floating-point tolerance 1e-9 relative).
# If multiple groups tie at the minimum, all are marked (provenance_tie = TRUE).
winning_step1_groups <- geomean_step |>
  inner_join(
    provenance_step3,
    by = c("casnumber_grouped", "accepted_name", "medium")
  ) |>
  filter(
    effect_category == winning_ec,
    conc_step1 >= final_conc_ug_L * (1 - 1e-9),
    conc_step1 <= final_conc_ug_L * (1 + 1e-9)
  ) |>
  group_by(casnumber_grouped, accepted_name, medium) |>
  mutate(provenance_tie = n() > 1) |>
  ungroup() |>
  select(step1_group_id, final_conc_ug_L, provenance_tie)

# Map each contributing record to its Step-1 group, then to winning-group status.
step1_group_key_lookup <- geomean_step |>
  select(
    casnumber_grouped,
    accepted_name,
    medium,
    effect_category,
    statistic_type,
    duration_hours,
    life_stage,
    step1_group_id
  )

record_provenance_flags <- contributing_record_keys |>
  left_join(
    step1_group_key_lookup,
    by = c(
      "casnumber_grouped",
      "accepted_name",
      "medium",
      "effect_category",
      "statistic_type",
      "duration_hours",
      "life_stage"
    )
  ) |>
  left_join(winning_step1_groups, by = "step1_group_id") |>
  mutate(is_provenance = !is.na(final_conc_ug_L)) |>
  select(
    record_uid,
    step1_group_id,
    is_provenance,
    final_conc_ug_L,
    provenance_tie
  )

# Build the full flagged source frame from the pre-preference base frame.
allchronic_source <- base_frame |>
  mutate(in_geomean_input = record_uid %in% geomean_input_uids) |>
  left_join(record_provenance_flags, by = "record_uid") |>
  mutate(
    is_provenance = coalesce(is_provenance, FALSE),
    provenance_tie = coalesce(provenance_tie, FALSE)
  )

n_source_rows <- nrow(allchronic_source)
n_in_geomean_input <- sum(allchronic_source$in_geomean_input)
n_is_provenance <- sum(allchronic_source$is_provenance)
n_output_n_records <- sum(output$n_records)

# Source-file validation checks
# V1: total rows == post-plausibility frame size
stopifnot(n_source_rows == n_after_plaus)

# V2: in_geomean_input count == records surviving tier filter
stopifnot(n_in_geomean_input == n_after_tier_filter)

# V3: every output row has >= 1 is_provenance row on cas × species × medium
provenance_coverage <- allchronic_source |>
  filter(is_provenance) |>
  distinct(casnumber_grouped, accepted_name, medium)
missing_provenance <- anti_join(
  output |> select(casnumber_grouped, accepted_name, medium),
  provenance_coverage,
  by = c("casnumber_grouped", "accepted_name", "medium")
)
stopifnot(nrow(missing_provenance) == 0)

# V4: for is_provenance rows, final_conc_ug_L == output conc_ug_L and
#     effect_category == output effect_category (C1 carry-through)
prov_consistency <- allchronic_source |>
  filter(is_provenance) |>
  inner_join(
    output |>
      select(
        casnumber_grouped,
        accepted_name,
        medium,
        conc_ug_L_out = conc_ug_L,
        ec_out = effect_category
      ),
    by = c("casnumber_grouped", "accepted_name", "medium")
  )
stopifnot(all(
  abs(prov_consistency$final_conc_ug_L - prov_consistency$conc_ug_L_out) /
    prov_consistency$conc_ug_L_out <
    1e-9
))
stopifnot(all(prov_consistency$effect_category == prov_consistency$ec_out))

# V5: report n_is_provenance vs sum(n_records); difference is expected
source_prov_note <- if (n_is_provenance != n_output_n_records) {
  paste0(
    "n_is_provenance (",
    n_is_provenance,
    ") differs from sum(n_records) (",
    n_output_n_records,
    ") — n_records counts geomean inputs; ",
    "is_provenance marks contributing inputs to winning groups only."
  )
} else {
  paste0("n_is_provenance == sum(n_records) == ", n_is_provenance, ".")
}
message(source_prov_note)
message("allchronic_data_source.csv validation checks passed.")

write_csv(allchronic_source, "data-raw/alldata/allchronic_data_source.csv")
source_file_size_mb <- file.size(
  "data-raw/alldata/allchronic_data_source.csv"
) /
  1e6
message(
  "Written: data-raw/alldata/allchronic_data_source.csv (",
  round(source_file_size_mb, 1),
  " MB) [untracked]"
)

# ---------------------------------------------------------------------------
# Step 9 — Write output CSV
# ---------------------------------------------------------------------------

write_csv(output, "data-raw/alldata/uncurated_raw_aggregated.csv")
file_size_mb <- file.size("data-raw/alldata/uncurated_raw_aggregated.csv") / 1e6
message(
  "Written: data-raw/alldata/uncurated_raw_aggregated.csv (",
  round(file_size_mb, 1),
  " MB)"
)

# ---------------------------------------------------------------------------
# Audit report statistics
# ---------------------------------------------------------------------------

n_distinct_cas <- n_distinct(output$casnumber_grouped)
n_distinct_species <- n_distinct(output$accepted_name)
medium_counts <- count(output, medium, name = "n_rows")
source_combos <- count(output, sources_contributing, name = "n_rows") |>
  arrange(desc(n_rows))
n_acr_rows <- sum(output$any_acr_applied, na.rm = TRUE)
n_chronic_conv_rows <- sum(output$any_chronic_conv_applied, na.rm = TRUE)
n_geomean_rows <- sum(output$geomean_flagged, na.rm = TRUE)
n_conc_flagged_rows <- sum(output$any_conc_flagged, na.rm = TRUE)
top_majorgroups <- count(output, majorgroup, name = "n_rows") |>
  arrange(desc(n_rows)) |>
  slice_head(n = 10)
value_tier_output_counts <- count(output, value_tier, name = "n_rows") |>
  arrange(value_tier)
effect_cat_output_counts <- count(output, effect_category, name = "n_rows") |>
  arrange(desc(n_rows))

# B2 table lines
nontrad_excl_lines <- if (nrow(nontrad_excl_by_code_source) > 0) {
  c(
    "| effect_category | source | n_excluded |",
    "|---|---|---|",
    apply(nontrad_excl_by_code_source, 1, function(r) {
      paste0(
        "| ",
        r["effect_category"],
        " | ",
        r["source"],
        " | ",
        r["n_excluded"],
        " |"
      )
    })
  )
} else {
  "None."
}

# C1/C2 effect_category output table
ec_output_lines <- if (nrow(effect_cat_output_counts) > 0) {
  c(
    "| effect_category | n_rows |",
    "|---|---|",
    apply(effect_cat_output_counts, 1, function(r) {
      paste0("| ", r["effect_category"], " | ", r["n_rows"], " |")
    })
  )
} else {
  "None."
}

# Stat-exclusion table lines
stat_excl_lines <- if (nrow(stat_excl_by_type_source) > 0) {
  c(
    "| statistic_type | stat_tier | source | n_excluded |",
    "|---|---|---|---|",
    apply(stat_excl_by_type_source, 1, function(r) {
      paste0(
        "| ",
        r["statistic_type"],
        " | ",
        r["stat_tier"],
        " | ",
        r["source"],
        " | ",
        r["n_excluded"],
        " |"
      )
    })
  )
} else {
  "None."
}

# Chronic conversion table lines
chronic_conv_lines <- if (nrow(chronic_conv_by_type) > 0) {
  c(
    "| statistic_type | conv_factor | source | n_converted |",
    "|---|---|---|---|",
    apply(chronic_conv_by_type, 1, function(r) {
      paste0(
        "| ",
        r["statistic_type"],
        " | ",
        r["chronic_conv_factor"],
        " | ",
        r["source"],
        " | ",
        r["n_converted"],
        " |"
      )
    })
  )
} else {
  "None."
}

# Value tier pre-aggregation table
tier_pre_lines <- if (nrow(tier_record_counts_pre_agg) > 0) {
  c(
    "| value_tier | n_records |",
    "|---|---|",
    apply(tier_record_counts_pre_agg, 1, function(r) {
      paste0("| ", r["value_tier"], " | ", r["n_records"], " |")
    })
  )
} else {
  "None."
}

# Value tier output table
tier_output_lines <- if (nrow(value_tier_output_counts) > 0) {
  c(
    "| value_tier | n_rows |",
    "|---|---|",
    apply(value_tier_output_counts, 1, function(r) {
      paste0("| ", r["value_tier"], " | ", r["n_rows"], " |")
    })
  )
} else {
  "None."
}

# Format hard-excluded listing as markdown table
if (nrow(hard_excluded_listing) > 0) {
  hard_listing_header <- "| casnumber_grouped | accepted_name | source | statistic_type | conc_ug_L | conc_plausibility |"
  hard_listing_sep <- "|---|---|---|---|---|---|"
  hard_listing_rows <- apply(hard_excluded_listing, 1, function(r) {
    paste0(
      "| ",
      r["casnumber_grouped"],
      " | ",
      r["accepted_name"],
      " | ",
      r["source"],
      " | ",
      r["statistic_type"],
      " | ",
      formatC(as.numeric(r["conc_ug_L"]), format = "e", digits = 3),
      " | ",
      r["conc_plausibility"],
      " |"
    )
  })
  hard_listing_lines <- c(
    hard_listing_header,
    hard_listing_sep,
    hard_listing_rows
  )
} else {
  hard_listing_lines <- "None."
}

hard_breakdown_lines <- if (nrow(hard_by_source) > 0) {
  apply(hard_by_source, 1, function(r) {
    paste0("- ", r["source"], " / ", r["conc_plausibility"], ": ", r["n"])
  })
} else {
  "- None."
}

soft_breakdown_lines <- if (nrow(soft_by_source) > 0) {
  apply(soft_by_source, 1, function(r) {
    paste0("- ", r["source"], " / ", r["conc_plausibility"], ": ", r["n"])
  })
} else {
  "- None."
}

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
  paste(
    "- 'Not stated' coerced to NA — majorgroup:",
    n_not_stated_majorgroup,
    "rows; class:",
    n_not_stated_class,
    "rows"
  ),
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
  paste(
    "- Total dropped:",
    n_dropped_ec,
    sprintf("(%.1f%% of clean subset)", 100 * n_dropped_ec / n_clean)
  ),
  "",
  "**By source:**",
  "",
  paste(
    apply(ec_drop_by_source, 1, function(r) {
      paste0("- ", r["source"], ": ", r["n_dropped"])
    }),
    collapse = "\n"
  ),
  "",
  "### 3b. Acute-non-eligible (acute NOECs/LOECs — cannot be ACR-converted)",
  "",
  paste(
    "- Total dropped:",
    n_dropped_acute_non_eligible,
    sprintf(
      "(%.1f%% of clean subset)",
      100 * n_dropped_acute_non_eligible / n_clean
    )
  ),
  "",
  "**By statistic_type:**",
  "",
  paste(
    apply(acute_drop_by_stattype, 1, function(r) {
      paste0("- ", r["statistic_type"], ": ", r["n_dropped"])
    }),
    collapse = "\n"
  ),
  "",
  "### 3c. Genus-rank species exclusion (uncurated only)",
  "",
  paste(
    "Genus-rank `accepted_name` entries excluded before aggregation.",
    "See `data-raw/alldata/stage4e-genus-rank-decisions.md` for floored-binomial triage rationale."
  ),
  "",
  paste("- Total rows excluded:", n_dropped_genus),
  paste("- Distinct genus-rank names excluded:", n_distinct_genus_rank),
  "",
  "**By source:**",
  "",
  paste(
    apply(genus_drop_by_source, 1, function(r) {
      paste0("- ", r["source"], ": ", r["n_dropped"])
    }),
    collapse = "\n"
  ),
  "",
  "### 3d. Statistic-type exclusion (no defined Warne 2025 treatment)",
  "",
  paste(
    "Records with undefined ECx percentiles (20 < x < 50 or x > 50),",
    "regulatory summary endpoints (NOAEL, LOAEL, NOAEC, LOAEC), and",
    "unrecognised types are excluded. Full listing in",
    "`data-raw/alldata/stage4e-statistic-type-excluded.csv`."
  ),
  "",
  paste("- Total rows excluded:", n_dropped_stat_excl),
  "",
  "**By statistic_type / tier / source:**",
  "",
  paste(stat_excl_lines, collapse = "\n"),
  "",
  paste("- Rows entering aggregation pipeline:", n_aggregation_input),
  "",
  "### 3e. Non-traditional endpoint filter (Warne et al. 2025 §3.2.1)",
  "",
  paste(
    "Endpoints classified as non-traditional (PSE, BCH, BEH, LUM, MOR) are excluded.",
    "Traditional endpoints retained: MORT, IMM, GRO, DVP, POP, REP, HAT, ABD."
  ),
  "",
  paste(
    "- Total rows excluded:",
    n_dropped_nontrad,
    sprintf(
      "(%.1f%% of rows entering this step)",
      100 * n_dropped_nontrad / n_aggregation_input
    )
  ),
  "",
  "**By effect_category and source:**",
  "",
  paste(nontrad_excl_lines, collapse = "\n"),
  "",
  paste(
    "**B2 impact — groups (casnumber × species × medium) losing ALL values:**"
  ),
  paste(
    "- Groups dropped entirely (had only non-traditional rows):",
    n_lost_all_species_chem_med
  ),
  paste("  - Distinct species dropped:", n_lost_all_species),
  paste(
    "  - Distinct chemicals with complete species loss:",
    n_lost_all_chemicals
  ),
  paste(
    "- Groups losing SOME rows (retain at least one traditional row):",
    n_had_some_nontrad
  ),
  paste(
    "- Post-filter validation: all surviving effect_category values are traditional (PASS)."
  ),
  "",
  "### 3f. Concentration plausibility filter (applied after ACR + chronic conversion)",
  "",
  paste0(
    "Thresholds: LOWER_HARD = ",
    LOWER_HARD,
    " µg/L",
    ", LOWER_SOFT = ",
    LOWER_SOFT,
    " µg/L",
    ", UPPER_SOFT = ",
    UPPER_SOFT,
    " µg/L",
    ", UPPER_HARD = ",
    UPPER_HARD,
    " µg/L"
  ),
  "",
  paste0(
    "Applied after ACR (Step 3) and chronic conversion (Step 3a) so all",
    " concentrations are on their final µg/L scale."
  ),
  "",
  paste0(
    "**Hard-excluded rows (dropped):** ",
    n_hard_excluded,
    " (low_hard: ",
    n_hard_low,
    "; high_hard: ",
    n_hard_high,
    ")"
  ),
  "",
  "By source / category:",
  "",
  paste(hard_breakdown_lines, collapse = "\n"),
  "",
  "Complete listing of hard-excluded rows:",
  "",
  paste(hard_listing_lines, collapse = "\n"),
  "",
  paste0(
    "**Soft-flagged rows retained:** ",
    n_soft_flagged,
    " (low_soft: ",
    n_soft_low,
    "; high_soft: ",
    n_soft_high,
    ")"
  ),
  "",
  "By source / category:",
  "",
  paste(soft_breakdown_lines, collapse = "\n"),
  "",
  paste("**Soft-only fallback groups (Step 1):**", n_soft_only_groups),
  paste(
    "- Rows entering geomean step after plausibility filter:",
    n_after_plaus
  ),
  "",
  "## 4. ACR conversion (Step 3)",
  "",
  paste("- Total rows ACR-converted (÷10):", n_acr_converted),
  "",
  "**By source:**",
  "",
  paste(
    apply(acr_by_source, 1, function(r) {
      paste0("- ", r["source"], ": ", r["n_converted"])
    }),
    collapse = "\n"
  ),
  "",
  "## 4a. Chronic/subchronic conversion (Step 3a)",
  "",
  paste(
    "Warne et al. 2025 Section 3.4.2.1 factors applied to chronic/subchronic",
    "records in the 'convert' tier: EC50/IC50/LC50 ÷ 5; LOEC/LOEL ÷ 2.5; MATC ÷ 2."
  ),
  paste("Acute EC50/IC50/LC50 are handled by ACR (Step 3) only."),
  "",
  paste("- Total rows chronic/subchronic-converted:", n_chronic_conv_total),
  "",
  "**By statistic_type / factor / source:**",
  "",
  paste(chronic_conv_lines, collapse = "\n"),
  "",
  "## 4b. Three-tier preference filter (Step 3c)",
  "",
  paste("Per species × chemical × medium, records are ranked:"),
  paste(
    "  1. `accepted` — NOEC/NOEL/ECx≤20/preferred negligible, chronic/subchronic"
  ),
  paste(
    "  2. `chronic_converted` — EC50/LOEC/MATC after ÷ factor, chronic/subchronic"
  ),
  paste("  3. `acute_acr` — acute EC50/IC50/LC50 after ACR ÷ 10"),
  paste("Only the lowest rank present in each group is retained."),
  "",
  paste(
    "**Decision note:** preference applied per species × chemical × medium",
    "(not per chemical). This is a deliberate operationalisation: in a",
    "one-value-per-species dataset, the fallback must be resolved at the",
    "species level so that chronic data for one species does not suppress",
    "acute data for a different species within the same chemical."
  ),
  "",
  paste("- Records dropped by tier preference filter:", n_records_dropped_tier),
  paste("- Records remaining after filter:", n_after_tier_filter),
  "",
  paste0(
    "**Tier displacement diagnostic:** ",
    n_tier_displacement,
    " groups had both tier-1/2 and tier-3 records (expected ~0 given",
    " `priority_kept` upstream)."
  ),
  if (n_tier_displacement > 0) {
    paste("  See `data-raw/alldata/stage4e-tier-displacement-groups.csv`.")
  } else {
    character(0)
  },
  "",
  "**Record distribution by value_tier before aggregation:**",
  "",
  paste(tier_pre_lines, collapse = "\n"),
  "",
  "## 5. Geometric mean step (Step 1 of Section 3.4.4)",
  "",
  paste("- Total groups formed:", n_step1_groups),
  paste(
    "- Singleton groups (n = 1):",
    n_singleton_groups,
    sprintf("(%.1f%%)", 100 * n_singleton_groups / n_step1_groups)
  ),
  paste(
    "- Multi-record groups:",
    n_multi_groups,
    sprintf("(%.1f%%)", 100 * n_multi_groups / n_step1_groups)
  ),
  paste(
    "- Groups flagged (max/min > 10):",
    n_groups_flagged,
    sprintf("(%.2f%%)", 100 * n_groups_flagged / n_step1_groups)
  ),
  "",
  "### Top 10 flagged groups by spread (max/min ratio)",
  "",
  "| casnumber_grouped | accepted_name | effect_category | statistic_type | duration_hours | life_stage | n | conc_min | conc_max | ratio |",
  "|---|---|---|---|---|---|---|---|---|---|",
  paste(
    apply(top_flagged, 1, function(r) {
      paste0(
        "| ",
        r["casnumber_grouped"],
        " | ",
        r["accepted_name"],
        " | ",
        r["effect_category"],
        " | ",
        r["statistic_type"],
        " | ",
        r["duration_hours"],
        " | ",
        r["life_stage"],
        " | ",
        r["n_in_group"],
        " | ",
        round(as.numeric(r["conc_min"]), 4),
        " | ",
        round(as.numeric(r["conc_max"]), 4),
        " | ",
        round(as.numeric(r["spread_ratio"]), 1),
        " |"
      )
    }),
    collapse = "\n"
  ),
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
  paste(
    apply(medium_counts, 1, function(r) {
      paste0("- ", r["medium"], ": ", r["n_rows"])
    }),
    collapse = "\n"
  ),
  "",
  "**Output rows by value_tier:**",
  "",
  paste(tier_output_lines, collapse = "\n"),
  "",
  paste(
    "**C1/C2 — effect_category of selected endpoint (Warne §3.2.1 traditional only):**"
  ),
  paste(
    "Tie-break rule: alphabetical order of effect_category when multiple endpoints",
    "share the same minimum concentration within a casnumber × species × medium group."
  ),
  paste("- Groups with tied minimum (C2):", n_groups_with_ties),
  "",
  paste(ec_output_lines, collapse = "\n"),
  "",
  "**Source combination breakdown:**",
  "",
  paste(
    apply(head(source_combos, 20), 1, function(r) {
      paste0("- `", r["sources_contributing"], "`: ", r["n_rows"])
    }),
    collapse = "\n"
  ),
  "",
  paste(
    "- Rows with `any_acr_applied == TRUE`:",
    n_acr_rows,
    sprintf("(%.1f%%)", 100 * n_acr_rows / n_output_rows)
  ),
  paste(
    "- Rows with `any_chronic_conv_applied == TRUE`:",
    n_chronic_conv_rows,
    sprintf("(%.1f%%)", 100 * n_chronic_conv_rows / n_output_rows)
  ),
  paste(
    "- Rows with `any_conc_flagged == TRUE`:",
    n_conc_flagged_rows,
    sprintf("(%.2f%%)", 100 * n_conc_flagged_rows / n_output_rows)
  ),
  paste(
    "- Rows with `geomean_flagged == TRUE`:",
    n_geomean_rows,
    sprintf("(%.2f%%)", 100 * n_geomean_rows / n_output_rows)
  ),
  "",
  "**Top 10 majorgroups by row count:**",
  "",
  paste(
    apply(top_majorgroups, 1, function(r) {
      paste0("- ", r["majorgroup"], ": ", r["n_rows"])
    }),
    collapse = "\n"
  ),
  "",
  "## 8. File sizes",
  "",
  paste("- `uncurated_raw_aggregated.csv`:", round(file_size_mb, 1), "MB"),
  paste(
    "- `stage4e-statistic-type-excluded.csv`:",
    round(
      file.size("data-raw/alldata/stage4e-statistic-type-excluded.csv") / 1e6,
      2
    ),
    "MB"
  ),
  paste(
    "- `allchronic_data_source.csv`:",
    round(source_file_size_mb, 1),
    "MB (untracked)"
  ),
  "",
  "## 9. Source export — allchronic_data_source.csv",
  "",
  "File: `data-raw/alldata/allchronic_data_source.csv` (untracked — large intermediate)",
  "",
  paste(
    "**Scope:** uncurated sources only (anztox, wqbench, envirotox). Curated sources",
    "(anzg, ccme, aims, csiro) are handled separately via their source `.rda` objects",
    "and do not appear here. This file therefore does NOT represent the full source",
    "of the `allchronic_data` object."
  ),
  "",
  paste(
    "**Capture point:** after all per-record filters (Steps 2a–2e) and conversions",
    "(ACR ÷10, chronic ÷factor, Step 3b hard-exclude), before the three-tier preference",
    "filter. Non-traditional endpoints (PSE/BCH/BEH/LUM/MOR) are excluded, matching",
    "the SSD scope of the published values. Fully unfiltered records are in",
    "`uncurated_raw_dedup_enriched.csv`."
  ),
  "",
  paste(
    "Concentrations are on their final µg/L scale (`conc_ug_L` has ACR ÷10 and chronic",
    "÷5/÷2.5/÷2 factors applied). `acr_applied`, `chronic_conv_applied`, and",
    "`chronic_conv_factor` are retained so the raw value is recoverable."
  ),
  "",
  paste("- Total rows (post-plausibility base frame):", n_source_rows),
  paste(
    "- `in_geomean_input == TRUE` (survived three-tier preference filter):",
    n_in_geomean_input
  ),
  paste(
    "- `is_provenance == TRUE` (in winning Step-1 group per species × chemical × medium):",
    n_is_provenance
  ),
  paste("- `sum(output$n_records)` for comparison:", n_output_n_records),
  source_prov_note,
  ""
)

writeLines(report_lines, "data-raw/alldata/stage4e-aggregation-report.md")
message("Audit report written: data-raw/alldata/stage4e-aggregation-report.md")
message("Stage 4e complete.")

# ============================================================
# STAGE 6/7 — Integration with curated sources and final build
# ============================================================

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

# Stage 4e ran above; use its in-memory output directly.
# uncurated_raw_aggregated.csv was also written as an audit artefact (untracked).
uncurated_raw <- output
cat("Stage 4e output (in-memory):", nrow(uncurated_raw), "rows\n")

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
cat("  [ ] data-raw/alldata/stage4e-aggregation-report.md\n")
cat("  [ ] data-raw/alldata/stage4e-statistic-type-excluded.csv\n")
cat("  [ ] R/get_ssddata.R\n")
cat("  [ ] R/allchronic_data.R\n")
cat("  [ ] data/allchronic_data.rda\n")
cat("  [ ] man/*.Rd  (after devtools::document())\n")
cat("  [ ] data-raw/alldata/stage6-integration-report.md\n")
cat("  [ ] data-raw/alldata/stage7-eligibility-report.md\n")
cat("  (untracked: uncurated_raw_aggregated.csv, allchronic_data_source.csv)\n")
