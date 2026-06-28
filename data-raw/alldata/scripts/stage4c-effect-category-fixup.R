# =============================================================================
# scripts/stage4c-effect-category-fixup.R
# =============================================================================
# Purpose:
#   Stage 4c Part 3 -- harmonise `effect_category` to a single controlled
#   vocabulary (MORT, GRO, REP, IMM, DVP, HAT, PSE, POP, LUM, ABD, BEH, BCH,
#   MOR) across all three uncurated sources in
#   `uncurated_raw_combined.csv`. Corrects three issues found and documented
#   in `data-raw/alldata/stage4c-dedup-report.md` (Anomalies, Stage 4c Part
#   2): (1) wqbench retained its own literal English-word vocabulary instead
#   of the shared codes; (2) anztox carries a free-text fallback tail for
#   some rows not covered by the documented ~24-value controlled subset; (3)
#   envirotox has both MOR and MORT as distinct values, requiring a check
#   that they are not mutually misassigned.
#
#   This script is the prerequisite for restoring `effect_category` to the
#   cross-source dedup key in `data-raw/alldata/scripts/stage4c-dedup.R` (J-DEVIATION,
#   resolved this session -- see that script's header).
#
# Inputs:
#   data-raw/alldata/uncurated_raw_combined.csv (449,888 rows x 17 cols)
#   data-raw/alldata/envirotox_effect_category_map.csv (read-only reference
#     for Step 1d; corrected in place only if a misassignment is found)
#
# Outputs:
#   data-raw/alldata/uncurated_raw_combined.csv (overwritten in place;
#     449,888 rows x 17 cols, unchanged column set -- only `effect_category`
#     values are corrected)
#   data-raw/alldata/anztox_2016_effect_category_map.csv (audit trail for
#     Step 1c -- written only if outside-vocabulary anztox values are found)
#   data-raw/alldata/envirotox_effect_category_map.csv (overwritten in place
#     only if Step 1d finds and corrects a MOR/MORT misassignment)
#
# Idempotency:
#   Re-running this script against an already-harmonised file is a no-op.
#   Step 1a checks whether any wqbench row's `effect_category` already holds
#   a controlled-vocabulary code (only possible post-fixup, since none of
#   the source English words collide with a code) and, if so, prints a
#   message and stops without modifying anything. Steps 1c/1d are naturally
#   idempotent: if no outside-vocabulary anztox values or MOR/MORT
#   misassignments remain, each step finds nothing to change.
#
# No DB connection required -- reads only the Stage 4b combined CSV and the
# existing envirotox map CSV.
#
# CRITICAL PATH NOTE: the master CAS lookup lives at
# data-raw/cas_parent_lookup_all.csv (NOT
# data-raw/anztox/cas_parent_lookup_all.csv). This script does not touch CAS
# mapping at all -- it only corrects `effect_category`.
# =============================================================================

library(dplyr)
library(readr)
library(stringr)
library(tibble)

input_path <- "data-raw/alldata/uncurated_raw_combined.csv"
envirotox_map_path <- "data-raw/alldata/envirotox_effect_category_map.csv"
anztox_map_path <- "data-raw/alldata/anztox_2016_effect_category_map.csv"

controlled_vocab <- c(
  "MORT", "GRO", "REP", "IMM", "DVP", "HAT", "PSE", "POP", "LUM", "ABD",
  "BEH", "BCH", "MOR"
)

# Same explicit col_types as data-raw/alldata/scripts/stage4c-dedup.R -- readr's default
# guess_max would otherwise mis-infer life_stage/source_id from the leading
# NA-heavy/anztox-numeric block.
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

combined <- read_csv(input_path, col_types = input_col_types)

if (nrow(combined) != 449888) {
  stop("Expected 449888 rows on load, got ", nrow(combined))
}
n_rows_start <- nrow(combined)

# =============================================================================
# STEP 1a -- PRE-FIX DIAGNOSTIC
# =============================================================================

message("=== Step 1a: pre-fix effect_category diagnostic ===")
pre_fix_dist <- combined |>
  count(source, effect_category, name = "n_rows") |>
  arrange(source, desc(n_rows))
print(pre_fix_dist, n = Inf)

wqbench_values <- combined |>
  filter(source == "wqbench") |>
  distinct(effect_category) |>
  pull(effect_category)

wqbench_already_coded <- any(
  !is.na(wqbench_values) & wqbench_values %in% controlled_vocab
)

if (wqbench_already_coded) {
  message(
    "\nwqbench effect_category values already include controlled-vocabulary ",
    "codes (", paste(intersect(wqbench_values, controlled_vocab), collapse = ", "),
    "). The fixup has likely already been applied -- stopping without ",
    "modifying ", input_path, "."
  )
} else {
  message(
    "\nConfirmed: wqbench effect_category values are literal English words ",
    "(e.g. Mortality, Growth), not controlled-vocabulary codes. Proceeding ",
    "with harmonisation."
  )
}

if (!wqbench_already_coded) {

  # ===========================================================================
  # STEP 1b -- WQBENCH ENGLISH -> CONTROLLED CODE MAPPING
  # ===========================================================================

  message("\n=== Step 1b: wqbench English -> controlled code mapping ===")

  wqbench_map <- c(
    "Mortality"          = "MORT",
    "Growth"              = "GRO",
    "Reproduction"        = "REP",
    "Immobilization"      = "IMM",
    "Development"         = "DVP",
    "Behavior"            = "BEH",
    "Avoidance"           = "BEH",
    "Feeding behavior"    = "BEH",
    "Population"         = "POP",
    "Cell(s)"             = "POP",
    "Photosynthesis"      = "PSE",
    "Physiology"          = "PSE",
    "Morphology"          = "MOR",
    "Biochemistry"        = "BCH",
    "Histology"           = "BCH",
    "Genetics"            = "BCH",
    "Enzyme(s)"           = "BCH",
    "Hormone(s)"          = "BCH",
    "Intoxication"        = NA_character_,
    "Multiple"            = NA_character_,
    "General"             = NA_character_,
    "Accumulation"        = NA_character_,
    "Ecosystem Process"   = NA_character_
  )

  wqbench_idx <- which(combined$source == "wqbench")
  wqbench_trimmed <- trimws(combined$effect_category[wqbench_idx])
  wqbench_in_table <- wqbench_trimmed %in% names(wqbench_map)

  # Diagnostic: "Ecosystem Process" specifically, per task brief. The actual
  # stored value is "Ecosystem process" (lower-case "p"), which does not
  # exact-case-match the brief's "Ecosystem Process" table entry -- so it
  # falls through to the not-in-table catch-all below, with the same NA
  # outcome either way. Reported here explicitly so the case mismatch is
  # visible rather than silently absorbed into the generic unmapped report.
  n_ecosystem_process_ci <- sum(str_to_lower(wqbench_trimmed) == "ecosystem process")
  message(
    "\n'Ecosystem Process' diagnostic (case-insensitive count): ",
    n_ecosystem_process_ci, " rows."
  )
  if (n_ecosystem_process_ci > 0) {
    actual_case <- unique(wqbench_trimmed[str_to_lower(wqbench_trimmed) == "ecosystem process"])
    message(
      "  Actual stored value: \"", paste(actual_case, collapse = "\", \""),
      "\" -- does not case-match the brief's \"Ecosystem Process\" table key, ",
      "so these rows are handled via the not-in-table catch-all below (same ",
      "NA outcome)."
    )
  }
  if (n_ecosystem_process_ci > 0 && n_ecosystem_process_ci < 100) {
    message("  Count < 100 -- proceeding with NA mapping.")
  } else if (n_ecosystem_process_ci > 1000) {
    message(
      "  WARNING: count > 1000 -- recommend human review before accepting ",
      "NA mapping. Proceeding with NA mapping per task brief regardless."
    )
  }

  # Not-in-table values: report with counts (catches both "Ecosystem process"
  # above and any value never anticipated by the brief's table, e.g. future
  # wqbench RDS updates introducing new vocabulary).
  unmapped_report <- tibble(raw_value = wqbench_trimmed[!wqbench_in_table]) |>
    count(raw_value, name = "n_rows") |>
    arrange(desc(n_rows))
  message("\nwqbench effect_category values NOT in the mapping table (set to NA):")
  print(unmapped_report, n = Inf)

  new_wqbench_values <- rep(NA_character_, length(wqbench_idx))
  new_wqbench_values[wqbench_in_table] <- unname(wqbench_map[wqbench_trimmed[wqbench_in_table]])

  before_after <- tibble(
    raw_value = wqbench_trimmed,
    mapped_to = if_else(wqbench_in_table, new_wqbench_values, NA_character_)
  ) |>
    count(raw_value, mapped_to, name = "n_rows") |>
    arrange(desc(n_rows))
  message("\nwqbench mapping applied (before value -> after code, n_rows):")
  print(before_after, n = Inf)

  combined$effect_category[wqbench_idx] <- new_wqbench_values

  if (nrow(combined) != n_rows_start) {
    stop("Row count drifted during Step 1b: ", nrow(combined))
  }
  message(
    "\nStep 1b complete: ", sum(!is.na(new_wqbench_values)), " of ",
    length(wqbench_idx), " wqbench rows mapped to a controlled code; ",
    sum(is.na(new_wqbench_values)), " set to NA."
  )

  # ===========================================================================
  # STEP 1c -- ANZTOX FREE-TEXT -> CONTROLLED CODE MAPPING
  # ===========================================================================

  message("\n=== Step 1c: anztox outside-vocabulary effect_category mapping ===")

  anztox_idx_all <- which(combined$source == "anztox")
  anztox_outside_idx <- anztox_idx_all[
    !is.na(combined$effect_category[anztox_idx_all]) &
      !(combined$effect_category[anztox_idx_all] %in% controlled_vocab)
  ]

  if (length(anztox_outside_idx) == 0) {
    message(
      "No anztox effect_category values found outside the controlled ",
      "vocabulary set -- nothing to do (already harmonised, or none present)."
    )
  } else {
    outside_values <- combined$effect_category[anztox_outside_idx]
    outside_summary <- tibble(raw_effect_category = outside_values) |>
      count(raw_effect_category, name = "n_rows") |>
      arrange(desc(n_rows))

    # Keyword rules, applied in order (first match wins) -- same style as the
    # envirotox classifier in data-raw/alldata/scripts/stage4b-extract.R (normalise_effect_text
    # / classify_envirotox_effect_one), reusing its lowercase + punctuation-
    # to-space normalisation so multi-word phrases like "disc area" and
    # "cumulative egg" match regardless of surrounding punctuation/case.
    anztox_rules <- tribble(
      ~proposed_mapping, ~mapping_rule,
      "MORT", "mortal|surviv|lethal|death",
      # A1: added proliferat, size, height, head capsule, dry mass (moved from POP)
      "GRO",  "growth|biomass|yield|length|weight|area|disc|proliferat|\\bsize\\b|\\bheight\\b|head capsule|dry mass",
      # A1: added progeny, young per
      "REP",  "reproduc|fertil|offspring|fecund|brood|egg|spawn|cumulative egg|progeny|young per",
      "IMM",  "immobil|mobil",
      # A1: added germinat (Germination/Germination inhibition), moulted (moulted individuals)
      "DVP",  "develop|metamorph|differentiat|emerg|germinat|moulted",
      "HAT",  "hatch",
      # A1: added 14co2 (14CO2 UPTAKE = photosynthesis assay)
      "PSE",  "photosyn|chlorophyll|pigment|physiol|14co2",
      # A1: added final number; removed dry mass (moved to GRO); added pgr (Population Growth Rate)
      "POP",  "populat|abundance|densit|final number|\\bpgr\\b",
      "LUM",  "lumines",
      # A1: added prp (PRP = Prey capture/predation, from endpoint_2016_to_2000_lookup_build_v2.md)
      "BEH",  "behaviour|behavior|avoidance|locomot|\\bprp\\b",
      # A1: added glucose (GLUCOSEUTILISATION = biochemistry); psr (PSR = physiological stress response)
      "BCH",  "biochem|enzyme|protein|lipid|hormone|oxidat|genet|glucose|\\bpsr\\b",
      "MOR",  "morphol|deform|malform|teratogen"
    )

    normalise_text <- function(x) {
      x |>
        str_to_lower() |>
        str_replace_all("[^a-z0-9]+", " ") |>
        str_squish()
    }

    classify_one <- function(text) {
      for (i in seq_len(nrow(anztox_rules))) {
        if (str_detect(text, anztox_rules$mapping_rule[i])) {
          return(anztox_rules$proposed_mapping[i])
        }
      }
      NA_character_
    }

    outside_summary <- outside_summary |>
      mutate(
        normalised = normalise_text(raw_effect_category),
        proposed_mapping = vapply(normalised, classify_one, character(1))
      ) |>
      select(raw_effect_category, n_rows, proposed_mapping)

    message("\nanztox outside-vocabulary values and proposed mapping:")
    print(outside_summary, n = Inf)

    write_csv(outside_summary, anztox_map_path)
    message("\nWrote: ", anztox_map_path)

    mapping_lookup <- setNames(
      outside_summary$proposed_mapping, outside_summary$raw_effect_category
    )
    new_anztox_values <- unname(mapping_lookup[outside_values])
    combined$effect_category[anztox_outside_idx] <- new_anztox_values

    if (nrow(combined) != n_rows_start) {
      stop("Row count drifted during Step 1c: ", nrow(combined))
    }
    message(
      "\nStep 1c complete: ", sum(!is.na(new_anztox_values)),
      " of ", length(anztox_outside_idx),
      " outside-vocabulary anztox rows mapped to a controlled code; ",
      sum(is.na(new_anztox_values)),
      " left as NA (unmappable by the first-pass keyword rules -- see ",
      anztox_map_path, " for human review)."
    )
  }

  # ===========================================================================
  # STEP 1d -- ENVIROTOX MOR vs MORT RECONCILIATION
  # ===========================================================================

  message("\n=== Step 1d: envirotox MOR vs MORT reconciliation ===")

  envirotox_map <- read_csv(
    envirotox_map_path,
    col_types = cols(
      raw_effect = col_character(),
      normalised_effect_lower = col_character(),
      effect_category_mapped = col_character(),
      n_rows = col_double(),
      mapping_rule = col_character()
    )
  )

  mor_rows <- envirotox_map |> filter(effect_category_mapped == "MOR")
  mort_rows <- envirotox_map |> filter(effect_category_mapped == "MORT")

  mor_should_be_mort <- mor_rows |>
    filter(str_detect(str_to_lower(raw_effect), "mortal|death"))
  mort_should_be_mor <- mort_rows |>
    filter(str_detect(str_to_lower(raw_effect), "morphol|deform"))

  message("MOR-mapped raw_effect values:")
  print(mor_rows |> select(raw_effect, n_rows), n = Inf)
  message("MORT-mapped raw_effect values:")
  print(mort_rows |> select(raw_effect, n_rows), n = Inf)

  if (nrow(mor_should_be_mort) == 0 && nrow(mort_should_be_mor) == 0) {
    message(
      "\nNo misassignments found: MOR and MORT correctly distinguish ",
      "morphology endpoints from mortality endpoints. Leaving both as-is."
    )
  } else {
    message(
      "\nMisassignment(s) found -- correcting ", nrow(mor_should_be_mort),
      " MOR->MORT and ", nrow(mort_should_be_mor), " MORT->MOR row(s)."
    )

    corrected_envirotox_map <- envirotox_map |>
      mutate(
        effect_category_mapped = case_when(
          raw_effect %in% mor_should_be_mort$raw_effect ~ "MORT",
          raw_effect %in% mort_should_be_mor$raw_effect ~ "MOR",
          TRUE ~ effect_category_mapped
        )
      )
    write_csv(corrected_envirotox_map, envirotox_map_path)
    message("Wrote corrected: ", envirotox_map_path)

    # envirotox's raw `Effect` text is not retained in the common 17-column
    # schema (only the mapped effect_category is), so a map correction here
    # cannot be back-applied to uncurated_raw_combined.csv by raw-value
    # lookup -- it would require re-deriving effect_category from raw Effect
    # via data-raw/alldata/scripts/stage4b-extract.R. Flagging this rather than silently
    # leaving uncurated_raw_combined.csv inconsistent with the corrected map.
    message(
      "\nWARNING: the corrected map above changes ",
      nrow(mor_should_be_mort) + nrow(mort_should_be_mor),
      " row(s) worth of envirotox effect_category assignment, but this ",
      "cannot be back-applied to uncurated_raw_combined.csv from this script ",
      "-- the raw `Effect` text is not retained in the common schema. Re-run ",
      "data-raw/alldata/scripts/stage4b-extract.R's envirotox section (or a targeted fixup ",
      "keyed on study_reference + duration_hours + conc_value, if unique ",
      "enough) to propagate this correction."
    )
  }

  # ===========================================================================
  # STEP 1e -- POST-FIX VALIDATION
  # ===========================================================================

  message("\n=== Step 1e: post-fix validation ===")

  bad_values <- combined |>
    filter(!is.na(effect_category), !(effect_category %in% controlled_vocab))
  if (nrow(bad_values) > 0) {
    stop(
      "Post-fix validation failed: ", nrow(bad_values), " rows have an ",
      "effect_category value outside NA/controlled vocabulary. Examples: ",
      paste(head(unique(bad_values$effect_category), 10), collapse = ", ")
    )
  }
  message("Confirmed: every effect_category value is NA or in the controlled vocabulary set.")

  post_fix_dist <- combined |>
    count(source, effect_category, name = "n_rows") |>
    arrange(source, desc(n_rows))
  message("\nFinal distinct effect_category values by source:")
  print(post_fix_dist, n = Inf)

  if (nrow(combined) != 449888) {
    stop("Final row count check failed: ", nrow(combined), " (expected 449888).")
  }
  message("\nConfirmed: total row count unchanged at ", nrow(combined), ".")

  # ===========================================================================
  # STEP 1f -- WRITE CORRECTED FILE
  # ===========================================================================

  write_csv(combined, input_path)
  message("\nWrote corrected: ", input_path)
  message("\n=== Stage 4c Part 3 effect_category fixup complete ===")
}
