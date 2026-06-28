# Stage 4e — Aggregate uncurated sources to one value per species × chemical × medium
#
# Implements Section 3.4.4 of Warne et al. 2025 (ANZG technical guidance),
# with an explicit three-tier statistic-type preference per Sections 3.4.2.1/3.4.2.2.
# Input:  data-raw/alldata/uncurated_raw_dedup_enriched.csv  (~228 MB, untracked)
# Output: data-raw/alldata/uncurated_raw_aggregated.csv      (untracked)
#         data-raw/alldata/stage4e-aggregation-report.md     (tracked)
#         data-raw/alldata/stage4e-statistic-type-excluded.csv (tracked, audit)
#
# Can be run from WSL or Windows Positron — no DB connection required.
# Read with guess_max = Inf per project-wide convention (CLAUDE.md Section 5).

library(readr)
library(dplyr)

# Concentration plausibility thresholds (µg/L)
LOWER_HARD <- 1e-5   # hard exclude
LOWER_SOFT <- 1e-3   # soft flag, retain
UPPER_SOFT <- 1e6    # soft flag, retain
UPPER_HARD <- 1e8    # hard exclude

# Detect genus-rank accepted_name entries (bare genus, or qualified with
# sp./spp./cf./aff./nr., or name == genus field exactly).
flag_genus_rank <- function(name, genus = NULL) {
  nm   <- trimws(name)
  core <- trimws(sub("\\s+(spp|sp|cf|aff|nr|gen)\\.?(\\s.*)?$", "", nm,
                     ignore.case = TRUE))
  no_epithet    <- !grepl("\\s", core)
  had_qualifier <- grepl("\\b(spp|sp|cf|aff|nr)\\.?(\\s|$)", nm,
                         ignore.case = TRUE)
  out <- no_epithet | had_qualifier
  if (!is.null(genus)) out <- out | (!is.na(genus) & nm == trimws(genus))
  out
}

# Map statistic_type to a Warne et al. 2025 tier.
# Accepts decimal ECx/ICx/LCx suffixes (e.g. EC2.52, EC6.99) — those with
# x <= 10 resolve as appropriate_no_conversion rather than UNCLASSIFIED.
classify_tier <- function(st) {
  s <- trimws(toupper(as.character(st)))
  is_x_pat <- grepl("^(EC|IC|LC)(\\d+(?:\\.\\d+)?)$", s, perl = TRUE)
  x_val    <- suppressWarnings(
    as.numeric(sub("^(?:EC|IC|LC)(\\d+(?:\\.\\d+)?)$", "\\1", s, perl = TRUE))
  )
  x_val[!is_x_pat] <- NA_real_
  dplyr::case_when(
    is.na(st)                                              ~ "UNCLASSIFIED (NA)",
    s %in% c("NEC", "NSEC", "BEC10")                      ~ "preferred_negligible",
    s %in% c("NOEC", "NOEL")                              ~ "negligible_no_conversion",
    s %in% c("LOEC", "LOEL")                              ~ "low_effect_conv_2.5",
    s == "MATC"                                            ~ "low_effect_conv_2",
    is_x_pat & !is.na(x_val) & x_val <= 10               ~ "appropriate_no_conversion",
    is_x_pat & !is.na(x_val) & x_val > 10 & x_val <= 20  ~ "less_pref_no_conversion",
    is_x_pat & !is.na(x_val) & x_val == 50               ~ "median_effect_conv_5",
    is_x_pat & !is.na(x_val)                              ~ "undefined_x_needs_ruling",
    TRUE                                                    ~ "UNCLASSIFIED"
  )
}

# Coarse action derived from tier: accepted / convert / exclude.
stat_action_for_tier <- function(stat_tier) {
  dplyr::case_when(
    stat_tier %in% c("preferred_negligible", "negligible_no_conversion",
                     "appropriate_no_conversion", "less_pref_no_conversion") ~ "accepted",
    stat_tier %in% c("low_effect_conv_2.5", "low_effect_conv_2",
                     "median_effect_conv_5")                                  ~ "convert",
    TRUE                                                                       ~ "exclude"
  )
}

# Conversion factor for chronic/subchronic 'convert' records; NA otherwise.
conv_factor_for_tier <- function(stat_tier) {
  dplyr::case_when(
    stat_tier == "median_effect_conv_5" ~ 5,
    stat_tier == "low_effect_conv_2.5"  ~ 2.5,
    stat_tier == "low_effect_conv_2"    ~ 2,
    TRUE                                ~ NA_real_
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
message("Dropped genus-rank species: ", n_dropped_genus, " rows (",
        n_distinct_genus_rank, " distinct names)")
write_csv(genus_rank_excluded,
          "data-raw/alldata/stage4e-genus-rank-excluded.csv")

# 2d. Classify statistic types; exclude records with no defined Warne 2025 treatment.
# Records with undefined ECx percentiles (20 < x < 50 or x > 50), regulatory
# summary endpoints (NOAEL, LOAEL, NOAEC, LOAEC), or unrecognised types are
# excluded — no conservative conversion exists to place them on the NOEC/EC50 scale.
n_before_stat_drop <- nrow(clean)
clean <- clean |>
  mutate(
    stat_tier   = classify_tier(statistic_type),
    stat_action = stat_action_for_tier(stat_tier),
    conv_factor = conv_factor_for_tier(stat_tier)
  )

stat_excluded <- clean |> filter(stat_action == "exclude")
stat_excl_by_type_source <- stat_excluded |>
  count(statistic_type, stat_tier, source, name = "n_excluded") |>
  arrange(desc(n_excluded))
write_csv(
  stat_excluded |>
    select(casnumber_grouped, accepted_name, source, statistic_type,
           stat_tier, test_class, conc_ug_L),
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

traditional_endpoints    <- c("MORT", "IMM", "GRO", "DVP", "POP", "REP", "HAT", "ABD")
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
n_lost_all_species           <- n_distinct(lost_all_groups$accepted_name)
n_lost_all_chemicals         <- n_distinct(lost_all_groups$casnumber_grouped)
n_had_some_nontrad           <- nrow(had_nontrad) - n_lost_all_species_chem_med

clean <- clean |>
  filter(!effect_category %in% non_traditional_endpoints)

n_dropped_nontrad <- n_before_nontrad - nrow(clean)
message("Step 2e — non-traditional endpoint exclusion: ", n_dropped_nontrad, " rows removed")
message("  Groups losing ALL values (dropped entirely): ", n_lost_all_species_chem_med,
        " (", n_lost_all_species, " species × ", n_lost_all_chemicals, " chemicals)")
message("  Groups losing SOME values: ", n_had_some_nontrad)

# Confirm all remaining effect_category values are traditional
surviving_ec <- unique(clean$effect_category[!is.na(clean$effect_category)])
non_trad_still_present <- setdiff(surviving_ec, traditional_endpoints)
if (length(non_trad_still_present) > 0) {
  stop("Post-B1 validation: non-traditional codes still present: ",
       paste(non_trad_still_present, collapse = ", "))
}
message("Post-B1 validation: all surviving effect_category values are traditional or NA.")

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
    chronic_conv_applied = test_class %in% c("chronic", "subchronic") &
                           stat_action == "convert",
    chronic_conv_factor  = if_else(chronic_conv_applied, conv_factor, NA_real_),
    conc_ug_L            = if_else(chronic_conv_applied,
                                   conc_ug_L / conv_factor,
                                   conc_ug_L)
  )

n_chronic_conv_total <- sum(clean$chronic_conv_applied, na.rm = TRUE)
chronic_conv_by_type <- clean |>
  filter(chronic_conv_applied) |>
  count(statistic_type, chronic_conv_factor, source, name = "n_converted") |>
  arrange(desc(n_converted))
message("Step 3a — chronic/subchronic conversions applied: ", n_chronic_conv_total, " rows")

# Validate: every surviving chronic/subchronic 'convert' record was converted
n_conv_not_applied <- clean |>
  filter(test_class %in% c("chronic", "subchronic"), stat_action == "convert") |>
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
      TRUE                    ~ "ok"
    )
  )

hard_excluded <- clean |>
  filter(conc_plausibility %in% c("low_hard", "high_hard"))
clean <- clean |>
  filter(!conc_plausibility %in% c("low_hard", "high_hard"))

n_hard_excluded <- nrow(hard_excluded)
n_hard_low      <- sum(hard_excluded$conc_plausibility == "low_hard")
n_hard_high     <- sum(hard_excluded$conc_plausibility == "high_hard")
n_soft_flagged  <- sum(clean$conc_plausibility %in% c("low_soft", "high_soft"))
n_soft_low      <- sum(clean$conc_plausibility == "low_soft")
n_soft_high     <- sum(clean$conc_plausibility == "high_soft")

hard_by_source <- hard_excluded |>
  count(source, conc_plausibility, name = "n")
soft_by_source <- clean |>
  filter(conc_plausibility %in% c("low_soft", "high_soft")) |>
  count(source, conc_plausibility, name = "n")

hard_excluded_listing <- hard_excluded |>
  select(casnumber_grouped, accepted_name, source, statistic_type,
         conc_ug_L, conc_plausibility) |>
  arrange(conc_plausibility, conc_ug_L)

n_after_plaus <- nrow(clean)
message("Concentration plausibility: hard-excluded ", n_hard_excluded,
        " rows (low_hard: ", n_hard_low, "; high_hard: ", n_hard_high, ")")
message("Soft-flagged rows retained: ", n_soft_flagged,
        " (low_soft: ", n_soft_low, "; high_soft: ", n_soft_high, ")")
message("Rows after plausibility filter: ", n_after_plaus)

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
      stat_action == "accepted" & test_class %in% c("chronic", "subchronic") ~ 1L,
      chronic_conv_applied == TRUE                                             ~ 2L,
      test_class == "acute"                                                    ~ 3L,
      TRUE                                                                     ~ NA_integer_
    )
  )

# Assert: every surviving record maps to exactly one rank
unranked <- filter(clean, is.na(record_tier_rank))
if (nrow(unranked) > 0) {
  write_csv(
    unranked |> select(casnumber_grouped, accepted_name, source,
                       statistic_type, test_class, stat_action, chronic_conv_applied),
    "data-raw/alldata/stage4e-unranked-rows.csv"
  )
  stop(paste(nrow(unranked),
             "records have no tier rank — see stage4e-unranked-rows.csv"))
}

# Tier displacement diagnostic: groups where acute records coexist with tier-1/2
# records. Because priority_kept already applies chronic > acute at the source
# level, this count is expected to be ~0; > 0 indicates the priority_kept
# granularity differs from casnumber_grouped × accepted_name × medium.
group_tier_stats <- clean |>
  group_by(casnumber_grouped, accepted_name, medium) |>
  summarise(
    min_tier_rank    = min(record_tier_rank),
    max_tier_rank    = max(record_tier_rank),
    n_distinct_tiers = n_distinct(record_tier_rank),
    .groups = "drop"
  )
displaced_groups <- group_tier_stats |>
  filter(min_tier_rank < 3L, max_tier_rank == 3L)
n_tier_displacement <- nrow(displaced_groups)
if (n_tier_displacement > 0) {
  write_csv(displaced_groups,
            "data-raw/alldata/stage4e-tier-displacement-groups.csv")
  message("Tier displacement diagnostic: ", n_tier_displacement,
          " groups — see stage4e-tier-displacement-groups.csv")
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
message("Step 3c tier filter: ", n_records_dropped_tier, " records dropped; ",
        n_after_tier_filter, " remain")

# Distribution of surviving records by value_tier
tier_record_counts_pre_agg <- clean |> count(value_tier, name = "n_records")

# Check 5: accepted-tier groups must not contain any converted or ACR-applied records
check5_violations <- filter(clean,
  value_tier == "accepted" &
  (acr_applied == TRUE | chronic_conv_applied == TRUE)
)
stopifnot(nrow(check5_violations) == 0)

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

clean_ok   <- clean |> filter(conc_plausibility == "ok")
clean_soft <- clean |> filter(conc_plausibility %in% c("low_soft", "high_soft"))

geomean_ok <- clean_ok |>
  group_by(
    casnumber_grouped, accepted_name, medium,
    effect_category, statistic_type, duration_hours, life_stage
  ) |>
  summarise(
    conc_geomean     = exp(mean(log(conc_ug_L))),
    conc_min         = min(conc_ug_L),
    conc_max         = max(conc_ug_L),
    n_in_group       = n(),
    any_acr          = any(acr_applied == TRUE, na.rm = TRUE),
    sources_raw      = paste(sort(unique(source)), collapse = ","),
    any_conc_flagged = FALSE,
    value_tier       = first(value_tier),
    .groups          = "drop"
  ) |>
  mutate(
    geomean_flagged = (conc_max / conc_min) > 10,
    conc_step1      = if_else(geomean_flagged, conc_min, conc_geomean)
  )

# Identify grouping-key combinations already covered by ok records
covered_keys <- geomean_ok |>
  distinct(casnumber_grouped, accepted_name, medium,
           effect_category, statistic_type, duration_hours, life_stage)

geomean_soft <- clean_soft |>
  anti_join(
    covered_keys,
    by = c("casnumber_grouped", "accepted_name", "medium",
           "effect_category", "statistic_type", "duration_hours", "life_stage")
  ) |>
  group_by(
    casnumber_grouped, accepted_name, medium,
    effect_category, statistic_type, duration_hours, life_stage
  ) |>
  summarise(
    conc_geomean     = exp(mean(log(conc_ug_L))),
    conc_min         = min(conc_ug_L),
    conc_max         = max(conc_ug_L),
    n_in_group       = n(),
    any_acr          = any(acr_applied == TRUE, na.rm = TRUE),
    sources_raw      = paste(sort(unique(source)), collapse = ","),
    any_conc_flagged = TRUE,
    value_tier       = first(value_tier),
    .groups          = "drop"
  ) |>
  mutate(
    geomean_flagged = (conc_max / conc_min) > 10,
    conc_step1      = if_else(geomean_flagged, conc_min, conc_geomean)
  )

geomean_step       <- bind_rows(geomean_ok, geomean_soft)
n_soft_only_groups <- nrow(geomean_soft)

n_step1_groups     <- nrow(geomean_step)
n_singleton_groups <- sum(geomean_step$n_in_group == 1)
n_multi_groups     <- n_step1_groups - n_singleton_groups
n_groups_flagged   <- sum(geomean_step$geomean_flagged, na.rm = TRUE)
message("Step 1 groups: ", n_step1_groups, " total; ",
        n_singleton_groups, " singletons; ",
        n_multi_groups, " multi-record; ",
        n_groups_flagged, " geomean_flagged")
message("Soft-only fallback groups (Step 1): ", n_soft_only_groups)

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
# effect_category is part of the group key here — retained for C1 carry-through.
endpoint_step <- geomean_step |>
  group_by(casnumber_grouped, accepted_name, medium, effect_category) |>
  summarise(
    conc_step2       = min(conc_step1),
    n_combinations   = n(),
    any_acr          = any(any_acr, na.rm = TRUE),
    geomean_flagged  = any(geomean_flagged, na.rm = TRUE),
    any_conc_flagged = any(any_conc_flagged, na.rm = TRUE),
    # lifestage_mixed: has both NA and non-NA life_stage in this endpoint group
    lifestage_mixed  = any(!is.na(life_stage)) & any(is.na(life_stage)),
    # duration_mixed: has both NA and non-NA duration_hours in this endpoint group
    duration_mixed   = any(!is.na(duration_hours)) & any(is.na(duration_hours)),
    sources_raw      = paste(
      sort(unique(unlist(strsplit(sources_raw, ",")))),
      collapse = ","
    ),
    n_records        = sum(n_in_group),
    value_tier       = first(value_tier),
    .groups          = "drop"
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

# C2: Count groups with tied minimum conc_step2 across endpoints.
# Alphabetical tiebreak on effect_category is applied below (arrange + first()).
n_groups_with_ties <- endpoint_step |>
  group_by(casnumber_grouped, accepted_name, medium) |>
  summarise(
    min_conc  = min(conc_step2),
    n_at_min  = sum(conc_step2 == min(conc_step2)),
    .groups   = "drop"
  ) |>
  filter(n_at_min > 1) |>
  nrow()
message("Step 6 tie count (groups with multiple endpoints sharing the minimum): ",
        n_groups_with_ties)

# C1: Retain the effect_category of the selected (minimum-conc) endpoint.
# Tiebreak rule: alphabetical order of effect_category (deterministic).
# arrange() before group_by so first() picks the alphabetically earliest code.
species_step <- endpoint_step |>
  arrange(casnumber_grouped, accepted_name, medium, conc_step2, effect_category) |>
  group_by(casnumber_grouped, accepted_name, medium) |>
  summarise(
    conc_ug_L            = first(conc_step2),
    effect_category      = first(effect_category),   # C1: from the winning endpoint
    n_records            = sum(n_records),
    any_acr_applied      = any(any_acr, na.rm = TRUE),
    geomean_flagged      = any(geomean_flagged, na.rm = TRUE),
    any_conc_flagged     = any(any_conc_flagged, na.rm = TRUE),
    lifestage_mixed      = any(lifestage_mixed, na.rm = TRUE),
    duration_mixed       = any(duration_mixed, na.rm = TRUE),
    sources_contributing = paste(
      sort(unique(unlist(strsplit(sources_raw, ",")))),
      collapse = ","
    ),
    value_tier           = first(value_tier),
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
  warning(n_cas_multi_name,
          " casnumber_grouped values have multiple chemicalname_grouped entries — taking first")
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
    effect_category,       # C1: retained effect_category of selected endpoint
    majorgroup,
    kingdom, phylum, class, order_taxon, family, genus,
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
stopifnot(all(output$value_tier %in% c("accepted", "chronic_converted", "acute_acr")))

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
  all(output$any_chronic_conv_applied == (output$value_tier == "chronic_converted"))
)

# 13. effect_category is never NA in output (B1 excluded all rows with NA or non-traditional
#     effect_category, so any surviving row must have a non-NA traditional code — unless the
#     species×chemical×medium group had ONLY NA effect_category rows, which step 2a already dropped)
stopifnot(!anyNA(output$effect_category))

# 14. All output effect_category values are in the traditional set
stopifnot(all(output$effect_category %in% traditional_endpoints))

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

n_distinct_cas          <- n_distinct(output$casnumber_grouped)
n_distinct_species      <- n_distinct(output$accepted_name)
medium_counts           <- count(output, medium, name = "n_rows")
source_combos           <- count(output, sources_contributing, name = "n_rows") |>
  arrange(desc(n_rows))
n_acr_rows              <- sum(output$any_acr_applied, na.rm = TRUE)
n_chronic_conv_rows     <- sum(output$any_chronic_conv_applied, na.rm = TRUE)
n_geomean_rows          <- sum(output$geomean_flagged, na.rm = TRUE)
n_conc_flagged_rows     <- sum(output$any_conc_flagged, na.rm = TRUE)
top_majorgroups         <- count(output, majorgroup, name = "n_rows") |>
  arrange(desc(n_rows)) |>
  slice_head(n = 10)
value_tier_output_counts <- count(output, value_tier, name = "n_rows") |>
  arrange(value_tier)
effect_cat_output_counts <- count(output, effect_category, name = "n_rows") |>
  arrange(desc(n_rows))

# B2 table lines
nontrad_excl_lines <- if (nrow(nontrad_excl_by_code_source) > 0) {
  c("| effect_category | source | n_excluded |",
    "|---|---|---|",
    apply(nontrad_excl_by_code_source, 1, function(r) {
      paste0("| ", r["effect_category"], " | ", r["source"], " | ", r["n_excluded"], " |")
    }))
} else {
  "None."
}

# C1/C2 effect_category output table
ec_output_lines <- if (nrow(effect_cat_output_counts) > 0) {
  c("| effect_category | n_rows |",
    "|---|---|",
    apply(effect_cat_output_counts, 1, function(r) {
      paste0("| ", r["effect_category"], " | ", r["n_rows"], " |")
    }))
} else {
  "None."
}

# Stat-exclusion table lines
stat_excl_lines <- if (nrow(stat_excl_by_type_source) > 0) {
  c("| statistic_type | stat_tier | source | n_excluded |",
    "|---|---|---|---|",
    apply(stat_excl_by_type_source, 1, function(r) {
      paste0("| ", r["statistic_type"], " | ", r["stat_tier"], " | ",
             r["source"], " | ", r["n_excluded"], " |")
    }))
} else {
  "None."
}

# Chronic conversion table lines
chronic_conv_lines <- if (nrow(chronic_conv_by_type) > 0) {
  c("| statistic_type | conv_factor | source | n_converted |",
    "|---|---|---|---|",
    apply(chronic_conv_by_type, 1, function(r) {
      paste0("| ", r["statistic_type"], " | ", r["chronic_conv_factor"], " | ",
             r["source"], " | ", r["n_converted"], " |")
    }))
} else {
  "None."
}

# Value tier pre-aggregation table
tier_pre_lines <- if (nrow(tier_record_counts_pre_agg) > 0) {
  c("| value_tier | n_records |",
    "|---|---|",
    apply(tier_record_counts_pre_agg, 1, function(r) {
      paste0("| ", r["value_tier"], " | ", r["n_records"], " |")
    }))
} else {
  "None."
}

# Value tier output table
tier_output_lines <- if (nrow(value_tier_output_counts) > 0) {
  c("| value_tier | n_rows |",
    "|---|---|",
    apply(value_tier_output_counts, 1, function(r) {
      paste0("| ", r["value_tier"], " | ", r["n_rows"], " |")
    }))
} else {
  "None."
}

# Format hard-excluded listing as markdown table
if (nrow(hard_excluded_listing) > 0) {
  hard_listing_header <- "| casnumber_grouped | accepted_name | source | statistic_type | conc_ug_L | conc_plausibility |"
  hard_listing_sep    <- "|---|---|---|---|---|---|"
  hard_listing_rows   <- apply(hard_excluded_listing, 1, function(r) {
    paste0("| ", r["casnumber_grouped"], " | ", r["accepted_name"], " | ",
           r["source"], " | ", r["statistic_type"], " | ",
           formatC(as.numeric(r["conc_ug_L"]), format = "e", digits = 3), " | ",
           r["conc_plausibility"], " |")
  })
  hard_listing_lines <- c(hard_listing_header, hard_listing_sep, hard_listing_rows)
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
  "### 3c. Genus-rank species exclusion (uncurated only)",
  "",
  paste("Genus-rank `accepted_name` entries excluded before aggregation.",
        "See `data-raw/alldata/stage4e-genus-rank-decisions.md` for floored-binomial triage rationale."),
  "",
  paste("- Total rows excluded:", n_dropped_genus),
  paste("- Distinct genus-rank names excluded:", n_distinct_genus_rank),
  "",
  "**By source:**",
  "",
  paste(apply(genus_drop_by_source, 1,
              function(r) paste0("- ", r["source"], ": ", r["n_dropped"])),
        collapse = "\n"),
  "",
  "### 3d. Statistic-type exclusion (no defined Warne 2025 treatment)",
  "",
  paste("Records with undefined ECx percentiles (20 < x < 50 or x > 50),",
        "regulatory summary endpoints (NOAEL, LOAEL, NOAEC, LOAEC), and",
        "unrecognised types are excluded. Full listing in",
        "`data-raw/alldata/stage4e-statistic-type-excluded.csv`."),
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
  paste("Endpoints classified as non-traditional (PSE, BCH, BEH, LUM, MOR) are excluded.",
        "Traditional endpoints retained: MORT, IMM, GRO, DVP, POP, REP, HAT, ABD."),
  "",
  paste("- Total rows excluded:", n_dropped_nontrad,
        sprintf("(%.1f%% of rows entering this step)", 100 * n_dropped_nontrad / n_aggregation_input)),
  "",
  "**By effect_category and source:**",
  "",
  paste(nontrad_excl_lines, collapse = "\n"),
  "",
  paste("**B2 impact — groups (casnumber × species × medium) losing ALL values:**"),
  paste("- Groups dropped entirely (had only non-traditional rows):", n_lost_all_species_chem_med),
  paste("  - Distinct species dropped:", n_lost_all_species),
  paste("  - Distinct chemicals with complete species loss:", n_lost_all_chemicals),
  paste("- Groups losing SOME rows (retain at least one traditional row):", n_had_some_nontrad),
  paste("- Post-filter validation: all surviving effect_category values are traditional (PASS)."),
  "",
  "### 3f. Concentration plausibility filter (applied after ACR + chronic conversion)",
  "",
  paste0("Thresholds: LOWER_HARD = ", LOWER_HARD, " µg/L",
         ", LOWER_SOFT = ", LOWER_SOFT, " µg/L",
         ", UPPER_SOFT = ", UPPER_SOFT, " µg/L",
         ", UPPER_HARD = ", UPPER_HARD, " µg/L"),
  "",
  paste0("Applied after ACR (Step 3) and chronic conversion (Step 3a) so all",
         " concentrations are on their final µg/L scale."),
  "",
  paste0("**Hard-excluded rows (dropped):** ", n_hard_excluded,
         " (low_hard: ", n_hard_low, "; high_hard: ", n_hard_high, ")"),
  "",
  "By source / category:",
  "",
  paste(hard_breakdown_lines, collapse = "\n"),
  "",
  "Complete listing of hard-excluded rows:",
  "",
  paste(hard_listing_lines, collapse = "\n"),
  "",
  paste0("**Soft-flagged rows retained:** ", n_soft_flagged,
         " (low_soft: ", n_soft_low, "; high_soft: ", n_soft_high, ")"),
  "",
  "By source / category:",
  "",
  paste(soft_breakdown_lines, collapse = "\n"),
  "",
  paste("**Soft-only fallback groups (Step 1):**", n_soft_only_groups),
  paste("- Rows entering geomean step after plausibility filter:", n_after_plaus),
  "",
  "## 4. ACR conversion (Step 3)",
  "",
  paste("- Total rows ACR-converted (÷10):", n_acr_converted),
  "",
  "**By source:**",
  "",
  paste(apply(acr_by_source, 1,
              function(r) paste0("- ", r["source"], ": ", r["n_converted"])),
        collapse = "\n"),
  "",
  "## 4a. Chronic/subchronic conversion (Step 3a)",
  "",
  paste("Warne et al. 2025 Section 3.4.2.1 factors applied to chronic/subchronic",
        "records in the 'convert' tier: EC50/IC50/LC50 ÷ 5; LOEC/LOEL ÷ 2.5; MATC ÷ 2."),
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
  paste("  1. `accepted` — NOEC/NOEL/ECx≤20/preferred negligible, chronic/subchronic"),
  paste("  2. `chronic_converted` — EC50/LOEC/MATC after ÷ factor, chronic/subchronic"),
  paste("  3. `acute_acr` — acute EC50/IC50/LC50 after ACR ÷ 10"),
  paste("Only the lowest rank present in each group is retained."),
  "",
  paste("**Decision note:** preference applied per species × chemical × medium",
        "(not per chemical). This is a deliberate operationalisation: in a",
        "one-value-per-species dataset, the fallback must be resolved at the",
        "species level so that chronic data for one species does not suppress",
        "acute data for a different species within the same chemical."),
  "",
  paste("- Records dropped by tier preference filter:", n_records_dropped_tier),
  paste("- Records remaining after filter:", n_after_tier_filter),
  "",
  paste0("**Tier displacement diagnostic:** ", n_tier_displacement,
         " groups had both tier-1/2 and tier-3 records (expected ~0 given",
         " `priority_kept` upstream)."),
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
  "**Output rows by value_tier:**",
  "",
  paste(tier_output_lines, collapse = "\n"),
  "",
  paste("**C1/C2 — effect_category of selected endpoint (Warne §3.2.1 traditional only):**"),
  paste("Tie-break rule: alphabetical order of effect_category when multiple endpoints",
        "share the same minimum concentration within a casnumber × species × medium group."),
  paste("- Groups with tied minimum (C2):", n_groups_with_ties),
  "",
  paste(ec_output_lines, collapse = "\n"),
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
  paste("- Rows with `any_chronic_conv_applied == TRUE`:", n_chronic_conv_rows,
        sprintf("(%.1f%%)", 100 * n_chronic_conv_rows / n_output_rows)),
  paste("- Rows with `any_conc_flagged == TRUE`:", n_conc_flagged_rows,
        sprintf("(%.2f%%)", 100 * n_conc_flagged_rows / n_output_rows)),
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
  paste("- `stage4e-statistic-type-excluded.csv`:",
        round(file.size("data-raw/alldata/stage4e-statistic-type-excluded.csv") / 1e6, 2), "MB"),
  ""
)

writeLines(report_lines, "data-raw/alldata/stage4e-aggregation-report.md")
message("Audit report written: data-raw/alldata/stage4e-aggregation-report.md")
message("Stage 4e complete.")
