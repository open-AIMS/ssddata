# =============================================================================
# scripts/stage4c-dedup.R
# =============================================================================
# Purpose:
#   Stage 4c Part 2 -- cross-source duplicate detection and ANZG priority
#   selection. Audit-and-flag stage: no rows are hard-dropped. Adds three
#   permanent flag columns (within_source_duplicate, dedup_retained,
#   priority_kept) plus a character note column (dedup_note) to the Stage 4b
#   combined dataset, and writes a markdown audit report.
#
#   Four phases:
#     Phase 1 -- within-source duplicate diagnostic (flag-and-retain; stop()
#                if any source exceeds 1% of rows involved).
#     Phase 2 -- cross-source duplicate detection (exact pass, then 0.1%
#                tolerance pass), preference order wqbench > anztox >
#                envirotox.
#     Phase 3 -- ANZG priority selection (chronic > subchronic > acute)
#                applied to the cross-source-deduplicated rows only.
#     Phase 4 -- write the augmented CSV and the markdown report.
#
#   Cross-source dedup runs BEFORE priority selection so that chronic data
#   from a lower-priority source is never discarded in favour of acute data
#   from a higher-priority source.
#
# Inputs:
#   data-raw/alldata/uncurated_raw_combined.csv (449,888 rows x 17 cols)
#
# Outputs:
#   data-raw/alldata/uncurated_raw_dedup.csv (449,888 rows x 21 cols)
#   data-raw/alldata/stage4c-dedup-report.md
#
# Decisions implemented:
#   G2   -- within-source duplicate diagnostic: flag-and-retain, no hard
#           drop. stop() if any source exceeds 1% of rows involved in
#           within-source duplicate groups.
#   H2   -- ANZG priority-selection grouping key (Phase 3, Step 6a) uses
#           native_cas, not casnumber_grouped -- parent-CAS grouping is
#           deferred to Stage 4d.
#   I2   -- ANZG priority selection (chronic > subchronic > acute) is
#           applied to dedup_retained == TRUE rows only, after Phase 2.
#   J1   -- cross-source key: native_cas x scientificname_norm x medium x
#           statistic_type_norm x duration_hours (exact) x conc_ug_L (0.1%
#           relative tolerance). See J-DEVIATION below.
#   J2b  -- rows with NA in any within-source or cross-source key field are
#           excluded from that specific check (strict) and pass through
#           unflagged for that phase (within_source_duplicate = FALSE, or
#           dedup_retained = TRUE with an explanatory dedup_note).
#   J3a  -- medium is matched strictly in the cross-source key. "Unknown"
#           rows (envirotox; ~20,743 wqbench rows with unmappable
#           media_type) only match other "Unknown" rows -- no wildcarding
#           against Freshwater/Marine.
#   J-DEVIATION -- effect_category was REMOVED from the cross-source key
#           specified in the original task brief (Step 5b), by explicit
#           user decision taken mid-session (see prompts/stage4c-dedup.md,
#           session "stage4c-part2-dedup", for the full exchange).
#           effect_category is NOT a shared vocabulary across sources in
#           this CSV: wqbench retains its own literal English-word
#           vocabulary (effect_category = effect; see
#           scripts/stage4b-extract.R line ~807), while anztox and
#           envirotox use MORT/GRO/REP-style codes (and anztox additionally
#           falls back to raw free-text endpoint names for some 2016 rows).
#           Verified empirically before writing this script: with
#           effect_category included in the key, *zero* cross-source
#           candidate groups exist anywhere in the 449,888-row file (i.e.
#           Phase 2 would be a complete no-op against wqbench, the largest
#           and highest-priority source). Dropping it from the
#           cross-source key alone recovers 6,218 genuine candidate groups
#           (15,571 rows: 5,907 anztox+wqbench, 311 envirotox+wqbench).
#           effect_category is UNCHANGED in the output schema and is NOT
#           removed from the within-source keys (Phase 1, Step 4) or the
#           Phase 3 priority-selection key (Step 6a) -- those keys were not
#           part of the user's decision, and within a single source the
#           vocabulary is internally self-consistent. The same underlying
#           vocabulary mismatch nonetheless limits Phase 3's ability to
#           group rows across sources too; see the report's Anomalies
#           section.
#   D1b  -- 0.1% relative tolerance on conc_value matching; diagnostic
#           reported at 0% / 0.1% / 1% / 5% thresholds.
#   D2b  -- normalised species-name matching (lowercase + whitespace
#           collapsed).
#   D3b  -- flag-and-filter, not hard-drop, throughout.
#   D4b  -- within-source diagnostic first (Phase 1), then cross-source
#           (Phase 2).
#   D5b  -- cross-source key uses the harmonised statistic_type field added
#           in the revised Stage 4b schema (see J-DEVIATION re
#           effect_category specifically).
#
# STATUS (2026-06-24): this script currently halts after Phase 1 -- Phases
# 2-4 have NOT been run against real output, pending a project-level
# decision recorded in scripts/stage4c-deferred-decisions.md. The
# within-source keys below include `conc_value` (added after investigating
# why the original task-brief keys produced 35-52% within-source duplicate
# rates -- see that file for the full investigation). Even with
# `conc_value` added, wqbench remains at ~25% and anztox at ~9%, for
# reasons confirmed NOT to be data-quality defects (see the deferred
# decisions file). Phases 2-4 are left fully implemented below, ready to
# run once that decision is made; do not delete them.
#
# Run from: WSL Positron (or Windows Positron -- no DB connection required).
#           Reads only data-raw/alldata/uncurated_raw_combined.csv.
#
# CRITICAL PATH NOTE: the master CAS lookup lives at
# data-raw/cas_parent_lookup_all.csv (NOT
# data-raw/anztox/cas_parent_lookup_all.csv). This script does not read it:
# parent-CAS grouping is out of scope for Stage 4c -- native_cas is used
# throughout; casnumber_grouped is reserved for Stage 4d aggregation.
# =============================================================================

library(dplyr)
library(readr)
library(tidyr)
library(purrr)
library(tibble)

input_path <- "data-raw/alldata/uncurated_raw_combined.csv"
output_csv_path <- "data-raw/alldata/uncurated_raw_dedup.csv"
output_report_path <- "data-raw/alldata/stage4c-dedup-report.md"

report_lines <- character(0)
add_report <- function(...) {
  report_lines <<- c(report_lines, paste0(...))
}

# =============================================================================
# STEP 2 -- LOAD AND VALIDATE INPUT
# =============================================================================

expected_cols <- c(
  "source", "native_cas", "casnumber_grouped", "chemicalname_grouped",
  "scientificname", "medium", "test_class", "statistic_type",
  "effect_category", "duration_hours", "life_stage", "conc_value",
  "conc_unit", "acr_eligible", "study_reference", "source_id", "acr_applied"
)

# Explicit col_types: native_cas/casnumber_grouped/source_id must stay
# character (wqbench source_id is a composite string like "494_298000", not
# numeric). life_stage must stay character -- readr's default guess_max
# (1000 rows) would otherwise infer "logical" from anztox's all-NA leading
# block and silently corrupt every later wqbench/anztox-2016 string value.
input_col_types <- cols(
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

raw <- read_csv(input_path, col_types = input_col_types)

if (!identical(names(raw), expected_cols)) {
  stop(
    "Column names/order do not match expected schema.\n",
    "Expected: ", paste(expected_cols, collapse = ", "), "\n",
    "Got:      ", paste(names(raw), collapse = ", ")
  )
}

if (nrow(raw) != 449888) {
  stop("Expected 449888 rows, got ", nrow(raw))
}

if (ncol(raw) != 17) {
  stop("Expected 17 columns, got ", ncol(raw))
}

bad_source <- setdiff(unique(raw$source), c("anztox", "wqbench", "envirotox"))
if (length(bad_source) > 0) {
  stop("Unexpected value(s) in source column: ", paste(bad_source, collapse = ", "))
}

bad_unit <- setdiff(unique(raw$conc_unit), c("ug/L", "mg/L"))
if (length(bad_unit) > 0) {
  stop("Unexpected value(s) in conc_unit column: ", paste(bad_unit, collapse = ", "))
}

if (any(is.na(raw$conc_value))) {
  stop("NA conc_value present: ", sum(is.na(raw$conc_value)), " rows.")
}

if (any(raw$conc_value <= 0)) {
  stop("conc_value <= 0 present: ", sum(raw$conc_value <= 0), " rows.")
}

mg_l_not_wqbench <- raw |> filter(conc_unit == "mg/L", source != "wqbench")
if (nrow(mg_l_not_wqbench) > 0) {
  stop("mg/L conc_unit found outside wqbench: ", nrow(mg_l_not_wqbench), " rows.")
}

message("Step 2: input validated -- ", nrow(raw), " rows x ", ncol(raw), " cols.")

# =============================================================================
# STEP 3 -- PREPARE NORMALISED WORKING COLUMNS
# =============================================================================

work <- raw |>
  mutate(
    row_id = row_number(),
    conc_ug_L = if_else(conc_unit == "mg/L", conc_value * 1000, conc_value),
    scientificname_norm = tolower(trimws(gsub("\\s+", " ", scientificname))),
    statistic_type_norm = toupper(trimws(statistic_type)),
    source_priority = case_when(
      source == "wqbench" ~ 1L,
      source == "anztox" ~ 2L,
      source == "envirotox" ~ 3L
    )
  )

# =============================================================================
# STEP 4 -- PHASE 1: WITHIN-SOURCE DUPLICATE DIAGNOSTIC (Decision G2)
# =============================================================================

# `conc_value` was added to all three keys below, beyond what the original
# task brief specified -- without it, dose-response studies (many
# concentrations under otherwise-identical metadata) inflated all three
# sources' within-source duplicate rates to 35-52%. See
# scripts/stage4c-deferred-decisions.md for the full investigation,
# including why wqbench and anztox still exceed the 1% threshold even with
# this fix.
within_source_keys <- list(
  anztox = c(
    "native_cas", "scientificname_norm", "medium", "statistic_type_norm",
    "effect_category", "duration_hours", "study_reference", "conc_value"
  ),
  wqbench = c(
    "native_cas", "scientificname_norm", "medium", "statistic_type_norm",
    "effect_category", "duration_hours", "life_stage", "study_reference",
    "conc_value"
  ),
  envirotox = c(
    "native_cas", "scientificname_norm", "statistic_type_norm",
    "effect_category", "duration_hours", "study_reference", "conc_value"
  )
)

# Flags within-source duplicate groups (n > 1) using `key_cols`. Rows with NA
# in any key field are excluded from the check (Decision J2b) and always get
# within_source_duplicate = FALSE. Returns df with three working columns
# added: key_complete, within_source_duplicate, .ws_grp_id (group id, NA for
# key-incomplete rows -- used only for sampling).
detect_within_source_duplicates <- function(df, key_cols) {
  df$key_complete <- complete.cases(df[key_cols])
  df$within_source_duplicate <- FALSE
  df$.ws_grp_id <- NA_integer_

  eligible_idx <- which(df$key_complete)
  if (length(eligible_idx) > 0) {
    eligible <- df[eligible_idx, ]
    grp <- eligible |>
      group_by(across(all_of(key_cols))) |>
      mutate(.grp_id = cur_group_id(), .grp_n = n()) |>
      ungroup()
    df$.ws_grp_id[eligible_idx] <- grp$.grp_id
    df$within_source_duplicate[eligible_idx[grp$.grp_n > 1]] <- TRUE
  }
  df
}

work_by_source <- split(work, work$source)
phase1_results <- imap(work_by_source, function(df, src) {
  detect_within_source_duplicates(df, within_source_keys[[src]])
})
work <- bind_rows(phase1_results) |> arrange(row_id)

phase1_summary <- map_dfr(names(within_source_keys), function(src) {
  df <- work |> filter(source == src)
  n_total <- nrow(df)
  n_eligible <- sum(df$key_complete)
  n_dup_rows <- sum(df$within_source_duplicate)
  key_cols <- within_source_keys[[src]]
  n_dup_groups <- df |>
    filter(key_complete) |>
    count(across(all_of(key_cols))) |>
    filter(n > 1) |>
    nrow()
  tibble(
    source = src,
    n_total = n_total,
    n_eligible = n_eligible,
    n_excluded_na_key = n_total - n_eligible,
    n_dup_groups = n_dup_groups,
    n_dup_rows = n_dup_rows,
    pct_dup = 100 * n_dup_rows / n_total
  )
})

message("\n--- Phase 1: within-source duplicate summary ---")
print(phase1_summary)

offending <- phase1_summary |> filter(pct_dup > 1)
if (nrow(offending) > 0) {
  stop(
    "Within-source duplicate threshold exceeded (>1%) for: ",
    paste(
      sprintf(
        "%s (%d/%d rows, %.3f%%)",
        offending$source, offending$n_dup_rows, offending$n_total, offending$pct_dup
      ),
      collapse = "; "
    ),
    ". Stopping before Phase 2, per scripts/stage4c-deferred-decisions.md ",
    "(investigated 2026-06-24: conc_value already added to the key; ",
    "wqbench's excess is an irreducible common-schema granularity ceiling, ",
    "anztox's is genuine multi-lab ring-test replication -- neither is a ",
    "fixable key-design or identifier bug). Do not resume past this point ",
    "without resolving the deferred decision."
  )
}
message("All sources within the 1% within-source duplicate threshold. Proceeding to Phase 2.")

# Up to 5 sample within-source duplicate groups per source (largest first),
# full row contents, for the report.
get_within_source_samples <- function(df, key_cols, n_groups = 5) {
  dup_df <- df |> filter(within_source_duplicate)
  if (nrow(dup_df) == 0) {
    return(list())
  }
  top_ids <- dup_df |>
    count(.ws_grp_id, name = "grp_n") |>
    arrange(desc(grp_n)) |>
    slice_head(n = n_groups) |>
    pull(.ws_grp_id)
  map(top_ids, function(id) {
    dup_df |>
      filter(.ws_grp_id == id) |>
      select(source, all_of(key_cols), conc_value, conc_unit, source_id)
  })
}

phase1_samples <- imap(within_source_keys, function(key_cols, src) {
  get_within_source_samples(work |> filter(source == src), key_cols)
})

# =============================================================================
# STEP 5 -- PHASE 2: CROSS-SOURCE DUPLICATE DETECTION
# =============================================================================

# 5b/J-DEVIATION: cross-source key WITHOUT effect_category (see header note).
cross_key_cols <- c(
  "native_cas", "scientificname_norm", "medium", "statistic_type_norm",
  "duration_hours"
)

# 5c: NA handling -- rows with NA in any cross-source key field (including
# conc_ug_L) are excluded from cross-source dedup (Decision J2b).
work$cs_key_complete <- complete.cases(work[cross_key_cols]) & !is.na(work$conc_ug_L)

n_excluded_cs_na <- work |>
  filter(!cs_key_complete) |>
  count(source, name = "n_excluded_cs_na")
message("\n--- Rows excluded from cross-source dedup (NA in key field) ---")
print(n_excluded_cs_na)

work$match_type <- NA_character_
work$preferred_source <- NA_character_
work$preferred_source_id <- NA_character_
work$pct_diff <- NA_real_

# 5e: exact match pass (conc_ug_L treated as exact for this pass).
exact_groups <- work |>
  filter(cs_key_complete) |>
  group_by(across(all_of(c(cross_key_cols, "conc_ug_L")))) |>
  mutate(
    .cs_grp_id = cur_group_id(),
    .n_sources = n_distinct(source),
    .min_priority = min(source_priority)
  ) |>
  ungroup()

preferred_lookup_exact <- exact_groups |>
  filter(.n_sources > 1, source_priority == .min_priority) |>
  group_by(.cs_grp_id) |>
  slice(1) |>
  ungroup() |>
  select(.cs_grp_id, preferred_source = source, preferred_source_id = source_id)

exact_dup_rows <- exact_groups |>
  filter(.n_sources > 1, source_priority > .min_priority) |>
  select(row_id) |>
  left_join(
    exact_groups |> select(row_id, .cs_grp_id),
    by = "row_id"
  ) |>
  left_join(preferred_lookup_exact, by = ".cs_grp_id")

idx <- match(exact_dup_rows$row_id, work$row_id)
work$match_type[idx] <- "exact"
work$preferred_source[idx] <- exact_dup_rows$preferred_source
work$preferred_source_id[idx] <- exact_dup_rows$preferred_source_id
work$pct_diff[idx] <- 0

n_exact <- length(idx)
message("\nPhase 2, exact pass (5e): ", n_exact, " rows flagged as exact cross-source duplicates.")

# 5f: tolerance match pass on rows not already matched in 5e. Within each
# group defined by cross_key_cols (i.e. ignoring conc_ug_L), find pairs of
# rows from different sources within 0.1% relative tolerance on conc_ug_L,
# and flag the lower-priority row against the closest higher-priority match.
# Implemented as a sort-then-expanding-window scan per group: rows are
# sorted by conc_ug_L, and for each row the search in each direction stops
# as soon as the relative difference first exceeds the tolerance (valid
# because relative difference is monotonic in sorted order on either side).
find_tolerance_matches_in_group <- function(grp) {
  n <- nrow(grp)
  if (n < 2 || n_distinct(grp$source) < 2) {
    return(tibble(
      row_id = grp$row_id, flagged = FALSE,
      preferred_source = NA_character_, preferred_source_id = NA_character_,
      pct_diff = NA_real_
    ))
  }
  ord <- order(grp$conc_ug_L)
  conc <- grp$conc_ug_L[ord]
  priority <- grp$source_priority[ord]
  src <- grp$source[ord]
  sid <- grp$source_id[ord]

  flagged <- rep(FALSE, n)
  pref_src <- rep(NA_character_, n)
  pref_sid <- rep(NA_character_, n)
  pref_pct <- rep(NA_real_, n)

  for (i in seq_len(n)) {
    best_pct <- Inf
    best_j <- NA_integer_

    j <- i - 1L
    while (j >= 1L) {
      pct <- abs(conc[i] - conc[j]) / max(conc[i], conc[j]) * 100
      if (pct > 0.1) break
      if (priority[j] < priority[i] && pct < best_pct) {
        best_pct <- pct
        best_j <- j
      }
      j <- j - 1L
    }
    j <- i + 1L
    while (j <= n) {
      pct <- abs(conc[i] - conc[j]) / max(conc[i], conc[j]) * 100
      if (pct > 0.1) break
      if (priority[j] < priority[i] && pct < best_pct) {
        best_pct <- pct
        best_j <- j
      }
      j <- j + 1L
    }

    if (!is.na(best_j)) {
      flagged[i] <- TRUE
      pref_src[i] <- src[best_j]
      pref_sid[i] <- sid[best_j]
      pref_pct[i] <- best_pct
    }
  }

  tibble(
    row_id = grp$row_id[ord], flagged = flagged,
    preferred_source = pref_src, preferred_source_id = pref_sid, pct_diff = pref_pct
  )
}

tolerance_candidates <- work |> filter(cs_key_complete, is.na(match_type))

max_grp_size <- tolerance_candidates |>
  count(across(all_of(cross_key_cols))) |>
  pull(n) |>
  max()
message(
  "\nPhase 2, tolerance pass (5f): max group size (key minus conc_ug_L) = ",
  max_grp_size, " rows."
)
if (max_grp_size > 5000) {
  message(
    "NOTE: a group exceeds 5000 rows -- the sort-and-scan approach used here ",
    "remains O(n log n) per group as long as matches are sparse, but flag ",
    "this group for review if runtime becomes an issue."
  )
}

tolerance_groups <- tolerance_candidates |>
  group_by(across(all_of(cross_key_cols))) |>
  group_split()

tolerance_results <- map_dfr(tolerance_groups, find_tolerance_matches_in_group)
tolerance_flagged <- tolerance_results |> filter(flagged)

idx2 <- match(tolerance_flagged$row_id, work$row_id)
work$match_type[idx2] <- "tolerance"
work$preferred_source[idx2] <- tolerance_flagged$preferred_source
work$preferred_source_id[idx2] <- tolerance_flagged$preferred_source_id
work$pct_diff[idx2] <- tolerance_flagged$pct_diff

n_tolerance <- nrow(tolerance_flagged)
message("Phase 2, tolerance pass (5f): ", n_tolerance, " additional rows flagged.")

# 5g: diagnostic match counts at alternative tolerance thresholds (report
# only; does not affect dedup_retained). Re-derived independently of the
# sort-and-scan logic above as a cross-check.
diagnostic_threshold_counts <- function(threshold_pct) {
  candidates <- work |> filter(cs_key_complete)
  total_flagged <- 0L
  groups <- candidates |>
    group_by(across(all_of(cross_key_cols))) |>
    group_split()
  for (grp in groups) {
    if (nrow(grp) < 2 || n_distinct(grp$source) < 2) next
    ord <- order(grp$conc_ug_L)
    conc <- grp$conc_ug_L[ord]
    priority <- grp$source_priority[ord]
    n <- length(conc)
    row_flagged <- rep(FALSE, n)
    for (i in seq_len(n)) {
      j <- i - 1L
      while (j >= 1L) {
        pct <- abs(conc[i] - conc[j]) / max(conc[i], conc[j]) * 100
        if (pct > threshold_pct) break
        if (priority[j] < priority[i]) row_flagged[i] <- TRUE
        j <- j - 1L
      }
      j <- i + 1L
      while (j <= n) {
        pct <- abs(conc[i] - conc[j]) / max(conc[i], conc[j]) * 100
        if (pct > threshold_pct) break
        if (priority[j] < priority[i]) row_flagged[i] <- TRUE
        j <- j + 1L
      }
    }
    total_flagged <- total_flagged + sum(row_flagged)
  }
  total_flagged
}

threshold_levels <- c(0, 0.1, 1, 5)
threshold_diagnostic <- tibble(
  threshold_pct = threshold_levels,
  n_rows_flagged = map_dbl(threshold_levels, diagnostic_threshold_counts)
)
message("\n--- Phase 2 diagnostic: match counts at alternative thresholds ---")
print(threshold_diagnostic)
if (threshold_diagnostic$n_rows_flagged[threshold_diagnostic$threshold_pct == 0] != n_exact) {
  stop(
    "Diagnostic 0% threshold count (", threshold_diagnostic$n_rows_flagged[1],
    ") does not match Step 5e exact-pass count (", n_exact, ")."
  )
}
message("Confirmed: 0% threshold diagnostic count matches the Step 5e exact-pass count.")

# 5h: populate dedup_retained and dedup_note.
work <- work |>
  mutate(
    dedup_retained = case_when(
      !cs_key_complete ~ TRUE,
      is.na(match_type) ~ TRUE,
      match_type %in% c("exact", "tolerance") ~ FALSE
    ),
    dedup_note = case_when(
      !cs_key_complete ~ "excluded from cross-source dedup -- NA in key field(s)",
      match_type == "exact" ~ paste0(
        "exact duplicate of ", preferred_source, " (source_id ", preferred_source_id, ")"
      ),
      match_type == "tolerance" ~ paste0(
        "tolerance duplicate (~", round(pct_diff, 4), "%) of ", preferred_source,
        " (source_id ", preferred_source_id, ")"
      ),
      TRUE ~ NA_character_
    )
  )

# 5i: sanity check -- no retained record should be from a lower-priority
# source than a dropped record in the same group.
sanity_check_df <- work |>
  filter(cs_key_complete) |>
  group_by(across(all_of(c(cross_key_cols, "conc_ug_L")))) |>
  filter(n_distinct(source) > 1) |>
  summarise(
    min_priority_retained = suppressWarnings(min(source_priority[dedup_retained], na.rm = TRUE)),
    min_priority_dropped = suppressWarnings(min(source_priority[!dedup_retained], na.rm = TRUE)),
    .groups = "drop"
  ) |>
  filter(is.finite(min_priority_dropped), min_priority_retained > min_priority_dropped)

if (nrow(sanity_check_df) > 0) {
  stop(
    "Logic error: ", nrow(sanity_check_df), " exact-match group(s) retained a ",
    "record from a lower-priority source than a dropped record."
  )
}
message("\nPhase 2 sanity check (5i) passed: no group retains a lower-priority record over a dropped higher-priority one.")

# =============================================================================
# STEP 6 -- PHASE 3: ANZG PRIORITY SELECTION (Decision I2)
# =============================================================================

priority_rank <- c(chronic = 1L, subchronic = 2L, acute = 3L)

priority_key_cols <- c("native_cas", "scientificname_norm", "medium", "effect_category")

retained <- work |> filter(dedup_retained)

retained_for_priority <- retained |> filter(!is.na(test_class))
retained_na_test_class <- retained |> filter(is.na(test_class))

priority_groups <- retained_for_priority |>
  group_by(across(all_of(priority_key_cols))) |>
  mutate(
    .best_rank = min(priority_rank[test_class]),
    priority_kept = priority_rank[test_class] == .best_rank
  ) |>
  ungroup() |>
  select(-.best_rank)

priority_kept_result <- bind_rows(
  priority_groups,
  retained_na_test_class |> mutate(priority_kept = NA)
)

not_retained <- work |> filter(!dedup_retained) |> mutate(priority_kept = NA)

work <- bind_rows(priority_kept_result, not_retained) |> arrange(row_id)

# 6d: sanity checks.
message("\n--- Phase 3: priority_kept summary ---")
print(work |> count(priority_kept))
print(work |> filter(dedup_retained) |> count(source, priority_kept))

displaced <- work |> filter(dedup_retained, !is.na(priority_kept), !priority_kept)
message("\n--- Phase 3: rows displaced by priority selection, by source and test_class displaced ---")
print(displaced |> count(source, test_class))

# Confirm all priority_kept == TRUE rows within a group share the same
# test_class.
group_test_class_check <- work |>
  filter(dedup_retained, !is.na(priority_kept), priority_kept) |>
  group_by(across(all_of(priority_key_cols))) |>
  summarise(n_test_class = n_distinct(test_class), .groups = "drop") |>
  filter(n_test_class > 1)

if (nrow(group_test_class_check) > 0) {
  stop(
    "Logic error: ", nrow(group_test_class_check), " priority-selection group(s) ",
    "have priority_kept == TRUE rows spanning more than one test_class."
  )
}
message("Phase 3 sanity check (6d) passed: every priority_kept group is internally single-test_class.")

# =============================================================================
# STEP 7 -- PHASE 4: WRITE OUTPUTS
# =============================================================================

final_output_cols <- c(expected_cols, "within_source_duplicate", "dedup_retained", "priority_kept", "dedup_note")

output <- work |> select(all_of(final_output_cols))

if (nrow(output) != 449888) {
  stop("Row count drifted before writing output: ", nrow(output), " (expected 449888).")
}

# 7b: sanity checks before writing.
final_clean <- output |> filter(dedup_retained, priority_kept)
message("\n--- 7b: final clean subset (dedup_retained & priority_kept) ---")
message("Total: ", nrow(final_clean))
print(final_clean |> count(source))

message("\n--- 7b: dedup_retained == FALSE, by source and match_type ---")
print(work |> filter(!dedup_retained) |> count(source, match_type))

message("\n--- 7b: dedup_retained == TRUE but priority_kept == FALSE (displaced), by source/test_class ---")
print(work |> filter(dedup_retained, !is.na(priority_kept), !priority_kept) |> count(source, test_class))

message("\n--- 7b: dedup_retained == TRUE but priority_kept == NA (NA test_class) ---")
print(work |> filter(dedup_retained, is.na(priority_kept)) |> count(source))

message("\n--- 7b: within_source_duplicate == TRUE, by source ---")
print(output |> filter(within_source_duplicate) |> count(source))

# 7c: write CSV.
write_csv(output, output_csv_path)
message("\nWrote: ", output_csv_path, " (", nrow(output), " rows x ", ncol(output), " cols).")

# =============================================================================
# STEP 7d -- WRITE MARKDOWN REPORT
# =============================================================================

fmt_pct <- function(x) sprintf("%.3f%%", x)

add_report("# Stage 4c Part 2 -- Cross-Source Duplicate Detection and ANZG Priority Selection")
add_report("Date: 2026-06-24")
add_report("")
add_report(
  "Audit-and-flag stage only -- no rows were hard-dropped from ",
  "`uncurated_raw_combined.csv`. All 449,888 rows appear in ",
  "`uncurated_raw_dedup.csv` with four new columns: `within_source_duplicate`, ",
  "`dedup_retained`, `priority_kept`, `dedup_note`."
)
add_report("")
add_report("---")
add_report("")

add_report("## 1. Input summary")
add_report("")
add_report("- Input: `data-raw/alldata/uncurated_raw_combined.csv`")
add_report("- Rows: ", nrow(raw), " | Columns: ", ncol(raw))
add_report("- Source counts: ", paste(
  sprintf("%s = %d", names(table(raw$source)), table(raw$source)), collapse = ", "
))
add_report("- All input validation checks (Step 2) passed: source/conc_unit vocabulary, ",
  "no NA/non-positive `conc_value`, `mg/L` confined to wqbench.")
add_report("")

add_report("## 2. Phase 1 -- within-source duplicate findings")
add_report("")
add_report("Within-source keys used (Decision G2; NA in any key field excludes a row ",
  "from the check, per Decision J2b):")
add_report("")
for (src in names(within_source_keys)) {
  add_report("- **", src, "**: `", paste(within_source_keys[[src]], collapse = " x "), "`")
}
add_report("")
add_report("| source | n_total | n_eligible | n_excluded_na_key | n_dup_groups | n_dup_rows | pct_dup |")
add_report("|---|---|---|---|---|---|---|")
for (i in seq_len(nrow(phase1_summary))) {
  r <- phase1_summary[i, ]
  add_report(
    "| ", r$source, " | ", r$n_total, " | ", r$n_eligible, " | ", r$n_excluded_na_key,
    " | ", r$n_dup_groups, " | ", r$n_dup_rows, " | ", fmt_pct(r$pct_dup), " |"
  )
}
add_report("")
add_report("All sources are within the 1% within-source duplicate threshold -- pipeline proceeded to Phase 2.")
add_report("")

add_report("### Sample within-source duplicate groups (largest first, up to 5 per source)")
add_report("")
for (src in names(phase1_samples)) {
  groups <- phase1_samples[[src]]
  add_report("**", src, "** (", length(groups), " sample group(s) shown):")
  add_report("")
  if (length(groups) == 0) {
    add_report("_No within-source duplicate groups found._")
    add_report("")
    next
  }
  for (g in groups) {
    add_report("```")
    add_report(paste(capture.output(print(as.data.frame(g), row.names = FALSE)), collapse = "\n"))
    add_report("```")
    add_report("")
  }
}
add_report("---")
add_report("")

add_report("## 3. Phase 2 -- cross-source duplicate detection")
add_report("")
add_report(
  "**Deviation from the original task brief (Step 5b):** `effect_category` was ",
  "removed from the cross-source key by explicit user decision taken mid-session. ",
  "`effect_category` is not a shared vocabulary across sources in this CSV -- ",
  "wqbench retains its own literal English-word vocabulary (`effect_category = ",
  "effect`), while anztox and envirotox use MORT/GRO/REP-style codes. With ",
  "`effect_category` included in the key, *zero* cross-source candidate groups ",
  "exist anywhere in the file (verified before writing the script). The key used ",
  "in this run is:"
)
add_report("")
add_report("`", paste(cross_key_cols, collapse = " x "), " x conc_ug_L (0.1% relative tolerance)`")
add_report("")
add_report("### NA exclusions from cross-source dedup (Decision J2b)")
add_report("")
add_report("| source | n_excluded_cs_na |")
add_report("|---|---|")
for (i in seq_len(nrow(n_excluded_cs_na))) {
  r <- n_excluded_cs_na[i, ]
  add_report("| ", r$source, " | ", r$n_excluded_cs_na, " |")
}
add_report("")

add_report("### Source-pair breakdown (exact + tolerance matches)")
add_report("")
pair_breakdown <- work |>
  filter(match_type %in% c("exact", "tolerance")) |>
  count(source, preferred_source, match_type, name = "n_rows")
add_report("| dropped source | preferred (retained) source | match_type | n_rows |")
add_report("|---|---|---|---|")
for (i in seq_len(nrow(pair_breakdown))) {
  r <- pair_breakdown[i, ]
  add_report("| ", r$source, " | ", r$preferred_source, " | ", r$match_type, " | ", r$n_rows, " |")
}
add_report("")
add_report("- Exact-pass rows flagged (Step 5e): ", n_exact)
add_report("- Tolerance-pass rows flagged (Step 5f): ", n_tolerance)
add_report("- Total cross-source duplicate rows flagged (dedup_retained = FALSE): ", n_exact + n_tolerance)
add_report("")

add_report("### Match counts at alternative tolerance thresholds (diagnostic only)")
add_report("")
add_report("| threshold | n_rows_flagged |")
add_report("|---|---|")
for (i in seq_len(nrow(threshold_diagnostic))) {
  r <- threshold_diagnostic[i, ]
  add_report("| ", fmt_pct(r$threshold_pct), " | ", r$n_rows_flagged, " |")
}
add_report("")
add_report("Confirmed: the 0% threshold diagnostic count matches the Step 5e exact-pass count exactly.")
add_report("")
add_report("Max group size for the tolerance pass (key minus conc_ug_L): ", max_grp_size, " rows.")
add_report("")
add_report("Sanity check (5i) passed: no cross-source group retains a record from a ",
  "lower-priority source than a record it drops.")
add_report("")
add_report("---")
add_report("")

add_report("## 4. Phase 3 -- ANZG priority selection")
add_report("")
add_report(
  "Applied to `dedup_retained == TRUE` rows only, grouped by `", paste(priority_key_cols, collapse = " x "),
  "` (Decision H2: `native_cas`, not `casnumber_grouped`). Within each group, ",
  "chronic > subchronic > acute priority is applied; only the highest-priority ",
  "test_class present in the group is kept (`priority_kept = TRUE`)."
)
add_report("")
add_report("### priority_kept counts, total and by source")
add_report("")
add_report("Total:")
add_report("```")
add_report(paste(capture.output(print(work |> count(priority_kept))), collapse = "\n"))
add_report("```")
add_report("")
add_report("By source (retained rows only):")
add_report("```")
add_report(paste(capture.output(print(work |> filter(dedup_retained) |> count(source, priority_kept))), collapse = "\n"))
add_report("```")
add_report("")
add_report("### Rows displaced by priority selection (priority_kept == FALSE), by source and displaced test_class")
add_report("")
add_report("```")
add_report(paste(capture.output(print(displaced |> count(source, test_class))), collapse = "\n"))
add_report("```")
add_report("")
add_report(
  "Sanity check (6d) passed: every `(native_cas, scientificname_norm, medium, ",
  "effect_category)` group with `priority_kept == TRUE` rows is internally ",
  "single-`test_class`."
)
add_report("")
add_report("---")
add_report("")

add_report("## 5. Final retention summary")
add_report("")
add_report("### \"Final clean\" subset (dedup_retained AND priority_kept), by source")
add_report("")
add_report("```")
add_report(paste(capture.output(print(final_clean |> count(source))), collapse = "\n"))
add_report("```")
add_report("")
add_report("Total final-clean rows: ", nrow(final_clean))
add_report("Distinct `casnumber_grouped` values in the final clean subset: ", n_distinct(final_clean$casnumber_grouped))
add_report("")
add_report("### dedup_retained == FALSE, by source and match_type")
add_report("")
add_report("```")
add_report(paste(capture.output(print(work |> filter(!dedup_retained) |> count(source, match_type))), collapse = "\n"))
add_report("```")
add_report("")
add_report("### within_source_duplicate == TRUE, by source")
add_report("")
add_report("```")
add_report(paste(capture.output(print(output |> filter(within_source_duplicate) |> count(source))), collapse = "\n"))
add_report("```")
add_report("")
add_report("---")
add_report("")

add_report("## 6. Anomalies and findings requiring human attention")
add_report("")
add_report(
  "1. **`effect_category` is not a shared cross-source vocabulary** (see Section ",
  "3 deviation note). This was discovered empirically before writing the dedup ",
  "script: wqbench's `effect_category` is its own literal English-word field ",
  "(`Mortality`, `Growth`, ...), never translated to the MORT/GRO/REP-style codes ",
  "used by anztox and envirotox. Dropping `effect_category` from the cross-source ",
  "key (this run) recovered 6,218 candidate groups (15,571 rows: 5,907 ",
  "anztox+wqbench, 311 envirotox+wqbench) that would otherwise have been entirely ",
  "missed. **This same mismatch also limits Phase 3** (`priority_kept` is grouped ",
  "by `effect_category`, per the unmodified Step 6a key): cross-source priority ",
  "comparisons against wqbench will rarely group with anztox/envirotox records of ",
  "the same underlying endpoint, because the literal `effect_category` strings ",
  "differ. A proper fix requires a cross-source `effect_category` translation ",
  "table (similar in spirit to `envirotox_effect_category_map.csv`) mapping ",
  "wqbench's word vocabulary and anztox's free-text 2016 fallback values onto a ",
  "single shared scheme -- recommended as a prerequisite before Stage 4d ",
  "aggregation, since the same field is used there too."
)
add_report("")
add_report(
  "2. **anztox `effect_category` includes raw free-text fallback values for some ",
  "2016 rows** (e.g. \"Disc area\", \"Dry mass\", \"Cumulative eggs layed/female\"), ",
  "not just the documented ~24-value MORT/GRO/REP-style controlled subset. This ",
  "compounds finding #1 -- even an anztox-to-envirotox translation table would ",
  "need to account for this free-text tail."
)
add_report("")
add_report(
  "3. **envirotox `effect_category` contains both `MOR` and `MORT`** as distinct ",
  "values, which most likely represent the same underlying category (a residual ",
  "inconsistency from the Stage 4b keyword classifier / human-review fixup). ",
  "Worth a quick reconciliation pass before Stage 4d."
)
add_report("")

writeLines(report_lines, output_report_path)
message("\nWrote: ", output_report_path)

message("\n=== Stage 4c Part 2 complete ===")
