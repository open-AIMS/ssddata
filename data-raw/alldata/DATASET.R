# data-raw/alldata/DATASET.R
#
# THE definitive full-build entry point for the alldata pipeline. Orchestrates
# stages 1-10 in enforced order (see the ORCHESTRATION block below), then runs
# the existing Stage 4e aggregation + Stage 6/7 integration assembly (step 10).
# Run from the repository root, on Windows, end-to-end (step 1 needs the live
# `infogathering` PostgreSQL DB; step 5, when triggered, needs both the DB and
# network access for WoRMS/GBIF -- both Windows-only per CLAUDE.md).
#
# Restart points (see `stage_from` below): "extract" (full 1->10, default),
# "dedup" (2->10, no DB), "assemble" (10 only, fast-iteration path, no DB).
#
# Steps 1-9 (see ORCHESTRATION block for the full table and stage4d_mode
# semantics):
#   1 stage4b-extract.R                       [DB]
#   2 stage4b-effect-category-fixup.R         mandatory, silently skippable
#   3 stage4c-effect-category-fixup.R         mandatory, silently skippable
#   4 stage4c-dedup.R
#   5 stage4d-taxonomy-extract.R              [DB + network]  full_reresolution only
#   6 stage4d-context-aware-resolution.R      [network]       full_reresolution only
#   7 stage4d-part2-source-native-fallback.R  [network]       full_reresolution only
#   8 stage4d-part2-manual-name-corrections.R                 full_reresolution only
#   9 stage4d-part3-apply-resolution.R        (species_resolution_v2.csv, guess_max=Inf)
#
# Step 10 (this file, from the STAGE 4E header below -- always runs):
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

# =============================================================================
# ORCHESTRATION — Steps 1-9 (enforced build order)
# =============================================================================
# DATASET.R is the single definitive full-build entry point -- there is no
# separate orchestrator script. Each prior stage script stays a standalone,
# independently-runnable file under data-raw/alldata/scripts/; this block
# invokes them as ISOLATED Rscript subprocesses, in enforced order, rather
# than source()-ing them into this session -- several of them assume a fresh
# global environment (rm(list = ls())-style scripts) and would collide with
# each other and with the Stage 4e/6/7 assembly below if sourced in-process.
#
# Parameters (may be pre-set as variables before sourcing this script, or via
# environment variables; both fall back to their documented default):
#   stage_from   c("extract", "dedup", "assemble"), default "extract"
#     extract  -- full build, steps 1->10 (needs DB; Windows).
#     dedup    -- steps 2->10, starting from uncurated_raw_combined.csv (no DB).
#     assemble -- step 10 only, starting from uncurated_raw_dedup_enriched.csv
#                 (no DB) -- the fast-iteration path for Stage 4e/6/7 changes.
#   stage4d_mode c("cache_reuse", "full_reresolution"), default "cache_reuse"
#     cache_reuse       -- skip steps 5-8 (network WoRMS/GBIF resolution),
#                           reuse the existing species_resolution_v2.csv.
#     full_reresolution -- run steps 5-8 to rebuild species_resolution_v2.csv
#                           from scratch. cache_reuse silently auto-switches to
#                           this if the species set has drifted (see below).
# A restart always runs the enforced CONTIGUOUS TAIL from stage_from through
# step 10 -- never a free-form skip of individual steps. Per CLAUDE.md Section
# 2, a restart never silently regenerates a missing/stale intermediate; it
# hard-fails naming the earliest stage the operator must re-run.
# =============================================================================

if (!exists("stage_from", inherits = FALSE)) {
  stage_from <- Sys.getenv("SSD_STAGE_FROM", unset = "extract")
}
if (!exists("stage4d_mode", inherits = FALSE)) {
  stage4d_mode <- Sys.getenv("SSD_STAGE4D_MODE", unset = "cache_reuse")
}
stage_from <- match.arg(stage_from, c("extract", "dedup", "assemble"))
stage4d_mode <- match.arg(stage4d_mode, c("cache_reuse", "full_reresolution"))

message(
  "\n=== DATASET.R orchestration: stage_from = '", stage_from,
  "', stage4d_mode = '", stage4d_mode, "' ===\n"
)

scripts_dir <- "data-raw/alldata/scripts"

pipeline_steps <- list(
  list(
    n = 1L,
    script = file.path(scripts_dir, "stage4b-extract.R"),
    db = TRUE,
    network = FALSE,
    desc = "Extract from infogathering DB + wqbench/envirotox sources"
  ),
  list(
    n = 2L,
    script = file.path(scripts_dir, "stage4b-effect-category-fixup.R"),
    db = FALSE,
    network = FALSE,
    desc = "envirotox OTHER-bucket effect_category fixup (mandatory, silently skippable)"
  ),
  list(
    n = 3L,
    script = file.path(scripts_dir, "stage4c-effect-category-fixup.R"),
    db = FALSE,
    network = FALSE,
    desc = "Harmonise effect_category vocabulary across sources (mandatory, silently skippable)"
  ),
  list(
    n = 4L,
    script = file.path(scripts_dir, "stage4c-dedup.R"),
    db = FALSE,
    network = FALSE,
    desc = "Cross-source dedup + ANZG priority selection"
  ),
  list(
    n = 5L,
    script = file.path(scripts_dir, "stage4d-taxonomy-extract.R"),
    db = TRUE,
    network = TRUE,
    desc = "Source-native taxonomy extraction (Part 1.5)"
  ),
  list(
    n = 6L,
    script = file.path(scripts_dir, "stage4d-context-aware-resolution.R"),
    db = FALSE,
    network = TRUE,
    desc = "Context-aware WoRMS/GBIF resolution (Part 2)"
  ),
  list(
    n = 7L,
    script = file.path(scripts_dir, "stage4d-part2-source-native-fallback.R"),
    db = FALSE,
    network = TRUE,
    desc = "Source-native taxonomy fallback (Part 2 fixup U3)"
  ),
  list(
    n = 8L,
    script = file.path(scripts_dir, "stage4d-part2-manual-name-corrections.R"),
    db = FALSE,
    network = FALSE,
    desc = "Manual name corrections (Part 2 fixup)"
  ),
  list(
    n = 9L,
    script = file.path(scripts_dir, "stage4d-part3-apply-resolution.R"),
    db = FALSE,
    network = FALSE,
    desc = "Apply resolution to dedup file -> enriched output"
  )
)
steps_by_n <- setNames(
  pipeline_steps,
  vapply(pipeline_steps, function(s) as.character(s$n), character(1))
)

# Fail loudly if any script in the enforced order is missing -- the order is
# fixed regardless of stage_from, so a missing script is always a hard error.
missing_scripts <- Filter(function(s) !file.exists(s$script), pipeline_steps)
if (length(missing_scripts) > 0) {
  stop(
    "DATASET.R orchestration: missing stage script(s) required by the ",
    "enforced build order: ",
    paste(vapply(missing_scripts, function(s) s$script, character(1)), collapse = ", ")
  )
}

run_stage_script <- function(step) {
  message(sprintf(
    "\n--- Orchestration: step %d/9 -- %s (%s) ---",
    step$n, basename(step$script), step$desc
  ))
  if (isTRUE(step$db)) {
    message("    [DB] requires a live 'infogathering' PostgreSQL connection -- Windows only.")
  }
  if (isTRUE(step$network)) {
    message("    [network] queries WoRMS/GBIF -- may take substantially longer.")
  }
  rscript_bin <- file.path(R.home("bin"), "Rscript")
  status <- system2(rscript_bin, args = shQuote(step$script), wait = TRUE)
  if (!identical(status, 0L)) {
    stop(
      "DATASET.R orchestration: step ", step$n, " (", step$script,
      ") exited with non-zero status ", status, "."
    )
  }
  message(sprintf("--- Orchestration: step %d/9 complete ---", step$n))
}

# Row count via a single always-populated column ("source") -- much cheaper
# than parsing every column of these wide, multi-hundred-MB intermediates
# just to get nrow().
fast_row_count <- function(path) {
  nrow(read_csv(
    path,
    col_types = cols_only(source = col_character()),
    show_col_types = FALSE
  ))
}

# -----------------------------------------------------------------------------
# Restart validation: verify the intermediate stage_from depends on exists AND
# is current, walking the producer chain back to the earliest broken link.
# Never silently regenerates (CLAUDE.md Section 2) -- hard-fails naming the
# stage to re-run, flagging steps 1/5 as DB/Windows-only.
# -----------------------------------------------------------------------------

producer_chain <- list(
  list(
    n = 1L,
    path = "data-raw/alldata/uncurated_raw_combined.csv",
    note = "stage4b-extract.R -- DB/Windows-only",
    exact_rows = 449098L,
    band_rows = NULL
  ),
  list(
    n = 4L,
    path = "data-raw/alldata/uncurated_raw_dedup.csv",
    note = "stage4c-dedup.R",
    exact_rows = 449098L,
    band_rows = NULL
  ),
  list(
    n = 9L,
    path = "data-raw/alldata/uncurated_raw_dedup_enriched.csv",
    note = "stage4d-part3-apply-resolution.R",
    exact_rows = NULL,
    # Loose band around the documented reference (449,860 rows;
    # stage4d-part3-enrichment-report.md) -- generous enough to tolerate small
    # drift from re-resolution, tight enough to catch a genuinely stale file.
    band_rows = c(445000L, 455000L)
  )
)

required_entry <- switch(
  stage_from,
  extract = NULL,
  dedup = producer_chain[[1]],
  assemble = producer_chain[[3]]
)

if (!is.null(required_entry)) {
  chain_upto <- Filter(function(x) x$n <= required_entry$n, producer_chain)
  broken <- NULL
  for (entry in chain_upto) {
    if (!file.exists(entry$path)) {
      broken <- entry
      break
    }
  }
  if (!is.null(broken)) {
    stop(
      "DATASET.R orchestration: stage_from = '", stage_from, "' needs '",
      required_entry$path, "' but its producer chain is broken at step ",
      broken$n, " (", broken$note, ") -- '", broken$path, "' is missing. ",
      "Re-run with an earlier stage_from to regenerate it."
    )
  }
  n_rows_actual <- fast_row_count(required_entry$path)
  currency_ok <- if (!is.null(required_entry$exact_rows)) {
    n_rows_actual == required_entry$exact_rows
  } else {
    n_rows_actual >= required_entry$band_rows[1] &&
      n_rows_actual <= required_entry$band_rows[2]
  }
  if (!currency_ok) {
    expected_desc <- if (!is.null(required_entry$exact_rows)) {
      paste0("exactly ", required_entry$exact_rows)
    } else {
      paste0("between ", required_entry$band_rows[1], " and ", required_entry$band_rows[2])
    }
    stop(
      "DATASET.R orchestration: '", required_entry$path, "' looks stale for ",
      "stage_from = '", stage_from, "' (", n_rows_actual, " rows; expected ",
      expected_desc, "). Re-run from an earlier stage_from to regenerate it -- ",
      "step 1 is DB/Windows-only, step 5 is DB+network/Windows-only."
    )
  }
  message(
    "Restart validation passed for stage_from = '", stage_from, "': '",
    required_entry$path, "' is present and current (", n_rows_actual, " rows)."
  )
}

# -----------------------------------------------------------------------------
# Run steps 1-9 for the enforced contiguous tail implied by stage_from.
# -----------------------------------------------------------------------------

if (stage_from != "assemble") {
  first_n <- if (stage_from == "extract") 1L else 2L
  for (n in first_n:4L) {
    run_stage_script(steps_by_n[[as.character(n)]])
  }

  # --- stage4d_mode cache-currency check (steps 5-8 gate) --------------------
  # Compare distinct scientificname in the freshly-produced
  # uncurated_raw_dedup.csv against species covered by the cached
  # species_resolution_v2.csv (baseline ~4,348 species). If cache_reuse is
  # requested but the species set has drifted, auto-switch to
  # full_reresolution (announced loudly -- network resolution takes
  # substantially longer).
  dedup_path <- "data-raw/alldata/uncurated_raw_dedup.csv"
  v2_path <- "data-raw/alldata/species_resolution_v2.csv"

  dedup_species <- unique(read_csv(
    dedup_path,
    col_types = cols_only(scientificname = col_character()),
    show_col_types = FALSE
  )$scientificname)
  dedup_species <- dedup_species[!is.na(dedup_species)]

  effective_stage4d_mode <- stage4d_mode
  if (stage4d_mode == "cache_reuse") {
    if (!file.exists(v2_path)) {
      effective_stage4d_mode <- "full_reresolution"
      warning(
        "\n*** DATASET.R orchestration: '", v2_path, "' not found -- the ",
        "stage4d cache cannot be reused. Auto-switching to stage4d_mode = ",
        "'full_reresolution'. Network taxonomy resolution (WoRMS/GBIF) will ",
        "run now and take substantially longer than a cached run. ***\n",
        call. = FALSE
      )
    } else {
      v2_species <- unique(read_csv(
        v2_path,
        guess_max = Inf,
        show_col_types = FALSE
      )$scientificname)
      drifted_species <- setdiff(dedup_species, v2_species)
      if (length(drifted_species) > 0) {
        effective_stage4d_mode <- "full_reresolution"
        warning(
          "\n*** DATASET.R orchestration: species set has drifted -- ",
          length(drifted_species), " scientificname value(s) in ",
          "uncurated_raw_dedup.csv are not covered by the cached ",
          "species_resolution_v2.csv (baseline ~4,348 species). ",
          "Auto-switching to stage4d_mode = 'full_reresolution'. Network ",
          "taxonomy resolution (WoRMS/GBIF) will run now and take ",
          "substantially longer than a cached run. ***\n",
          call. = FALSE
        )
      } else {
        message(
          "Cache-currency check: all ", length(dedup_species),
          " distinct species in uncurated_raw_dedup.csv are covered by ",
          "species_resolution_v2.csv -- cache_reuse confirmed current."
        )
      }
    }
  }

  if (effective_stage4d_mode == "full_reresolution") {
    for (n in 5:8) {
      run_stage_script(steps_by_n[[as.character(n)]])
    }
  } else {
    message("stage4d_mode = 'cache_reuse': steps 5-8 (network taxonomy re-resolution) skipped.")
  }

  run_stage_script(steps_by_n[["9"]])

  # ---------------------------------------------------------------------------
  # Warn-band post-conditions (non-blocking) -- Task 1.4. Each check names its
  # report source. Bands are deliberately wide: this is a smoke check that the
  # steps just run produced output in the right ballpark, not a re-derivation
  # of the hard validation already inside each stage script.
  # ---------------------------------------------------------------------------

  warn_band <- function(label, actual, low, high, source_ref) {
    in_band <- actual >= low && actual <= high
    message(sprintf(
      "[%s] %s: actual = %s, expected band = [%s, %s] (source: %s)",
      if (in_band) "OK" else "WARNING -- OUT OF BAND",
      label,
      format(actual, big.mark = ","),
      format(low, big.mark = ","),
      format(high, big.mark = ","),
      source_ref
    ))
    invisible(in_band)
  }

  message("\n=== Orchestration: warn-band post-conditions ===")

  dedup_full <- read_csv(
    dedup_path,
    col_types = cols_only(
      source = col_character(),
      dedup_retained = col_logical(),
      priority_kept = col_logical()
    ),
    show_col_types = FALSE
  )
  n_cross_source_flagged <- sum(!dedup_full$dedup_retained)
  n_clean_post_dedup <- sum(
    dedup_full$dedup_retained & !is.na(dedup_full$priority_kept) & dedup_full$priority_kept
  )
  warn_band(
    "Total cross-source flagged", n_cross_source_flagged, 7300, 7500,
    "stage4c-dedup-report.md"
  )
  warn_band(
    "Clean subset post-dedup", n_clean_post_dedup, 379000, 384000,
    "stage4c-dedup-report.md"
  )

  enriched_path <- "data-raw/alldata/uncurated_raw_dedup_enriched.csv"
  enriched_flags <- read_csv(
    enriched_path,
    col_types = cols_only(
      source = col_character(),
      dedup_retained = col_logical(),
      priority_kept = col_logical()
    ),
    show_col_types = FALSE
  )
  n_enriched_rows <- nrow(enriched_flags)
  n_clean_entering_4e <- sum(
    enriched_flags$dedup_retained &
      !is.na(enriched_flags$priority_kept) &
      enriched_flags$priority_kept
  )
  warn_band(
    "Enriched row count", n_enriched_rows, 447000, 452000,
    "stage4d-part3-enrichment-report.md"
  )
  warn_band(
    "Clean subset entering 4e", n_clean_entering_4e, 379000, 384000,
    "stage4d-part3-enrichment-report.md, stage4e-aggregation-report.md"
  )

  v2_check <- read_csv(v2_path, guess_max = Inf, show_col_types = FALSE)
  n_sparse_nonNA <- sum(!is.na(v2_check$manual_corrected_query_name))
  message(sprintf(
    "[%s] species_resolution_v2.csv sparse-column ('manual_corrected_query_name') non-NA sanity: %d non-NA rows (source: step 9 header note -- guess_max=Inf pitfall)",
    if (n_sparse_nonNA > 0) "OK" else "WARNING -- ALL NA (guess_max may not have been honoured)",
    n_sparse_nonNA
  ))

  combined_ec <- read_csv(
    "data-raw/alldata/uncurated_raw_combined.csv",
    col_types = cols_only(source = col_character(), effect_category = col_character()),
    show_col_types = FALSE
  )
  n_envirotox_na_ec <- sum(combined_ec$source == "envirotox" & is.na(combined_ec$effect_category))
  warn_band(
    "envirotox OTHER/NA effect_category after step 2", n_envirotox_na_ec, 4500, 5000,
    "step 2 output (dominated by raw_effect = 'Intoxication', 4,759 rows, confirmed by human review to remain unmapped)"
  )

  message("=== Orchestration: warn-band post-conditions complete ===\n")
} else {
  message("stage_from = 'assemble': steps 1-9 skipped; proceeding directly to step 10.")
}

message("\n=== Orchestration complete -- proceeding to step 10 (Stage 4e/6/7 assembly) ===\n")
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
stopifnot(n_clean > 380000) # expect ~381,330

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

# ---------------------------------------------------------------------------
# Reviewer-facing chemical-provenance columns (additive)
# ---------------------------------------------------------------------------
# The source file carries native_cas but only the harmonised chemicalname_grouped.
# Join the master parent-CAS lookup to add the native chemical name and the
# CAS-grouping rationale / expert-review flag, so a chemist can review each
# native→parent rollup standalone. Additive only: no change to row count,
# filtering, aggregation, or any existing column value. Species back-tracking
# (original_scientificname → accepted_name) already exists and is untouched.
message("Adding chemical-provenance columns to allchronic_data_source.csv ...")

cas_lookup_display <- read_csv(
  "data-raw/cas_parent_lookup_all.csv",
  guess_max = Inf,
  show_col_types = FALSE
) |>
  # 1:1 on casnumber (asserted below); guard against any future duplicate seed
  distinct(casnumber, .keep_all = TRUE) |>
  select(
    native_cas = casnumber,
    native_chemicalname = chemicalname,
    cas_group_rationale = match_rationale,
    cas_group_human_checked = human_checked
  )

n_source_rows_pre_join <- nrow(allchronic_source)
allchronic_source <- allchronic_source |>
  left_join(cas_lookup_display, by = "native_cas")
# Direct native_cas = casnumber match, no CAS reformatting (Task A confirmed
# exact-match alignment). Assert the join did not fan out rows.
stopifnot(nrow(allchronic_source) == n_source_rows_pre_join)

# Reorder: keep the chemical-identity block together (grouped-CAS then native
# name / rationale / review flag), before the taxonomy columns.
allchronic_source <- allchronic_source |>
  relocate(native_chemicalname, .after = native_cas) |>
  relocate(
    cas_group_rationale,
    cas_group_human_checked,
    .after = chemicalname_grouped
  )

# Validation: every native_cas in the source data now matches a lookup row.
# The 5 anztox synthetic-placeholder CAS and the NA-parent junk CAS are
# curated rows in cas_parent_lookup_all.csv (exclusion_reason set) and are
# dropped upstream in stage4b-extract.R's apply_cas_parent_lookup() before
# this point, so no placeholder backfill is needed here (Task B).
n_na_native_name <- sum(is.na(allchronic_source$native_chemicalname))
n_na_rationale <- sum(is.na(allchronic_source$cas_group_rationale))
n_na_human_checked <- sum(is.na(allchronic_source$cas_group_human_checked))
stopifnot(
  n_na_native_name == 0L,
  n_na_rationale == 0L,
  n_na_human_checked == 0L
)
message(
  "Chemical-provenance join: 0 rows with NA native_chemicalname/",
  "rationale/human_checked."
)

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
# Data dictionary — allchronic_data_source_dictionary.md
# ---------------------------------------------------------------------------
# One row per column (all columns of the exported file), split into
# reviewer-facing and pipeline-internal tables, each carrying a real non-NA
# example drawn from the regenerated CSV. Tracked documentation so the source
# file is reviewable standalone.
message("Writing allchronic_data_source_dictionary.md ...")

source_dictionary <- tibble::tribble(
  ~column,
  ~facing,
  ~group,
  ~description,
  # --- reviewer-facing ---
  "source",
  "review",
  "identity",
  "Originating uncurated database for the record (anztox, wqbench, or envirotox).",
  "native_cas",
  "review",
  "identity",
  "CAS number exactly as reported by the source, in its original format, before parent-CAS grouping.",
  "native_chemicalname",
  "review",
  "identity",
  "Chemical name for native_cas from the master parent lookup; for the five synthetic-placeholder CAS (absent from the lookup) it is the explicit source-native anztox label.",
  "casnumber_grouped",
  "review",
  "identity",
  "Parent CAS after rollup via the master lookup; equals native_cas where no simpler parent exists.",
  "chemicalname_grouped",
  "review",
  "identity",
  "Harmonised parent chemical name for casnumber_grouped.",
  "cas_group_rationale",
  "review",
  "identity",
  "Basis for the native-to-parent CAS mapping (lookup match_rationale); reviewers use this to judge each rollup. Placeholder CAS carry an explicit excluded-from-grouping note.",
  "cas_group_human_checked",
  "review",
  "identity",
  "Whether the CAS mapping was expert-reviewed: `n` = LLM-assisted/heuristic, not yet reviewed; `NA` = synthetic placeholder outside the lookup.",
  "scientificname",
  "review",
  "taxonomy",
  "Species name carried through the pipeline; identical to original_scientificname in this file.",
  "medium",
  "review",
  "endpoint",
  "Test medium: Freshwater, Marine, or Unknown.",
  "test_class",
  "review",
  "endpoint",
  "Exposure-duration classification carried from the source: chronic, subchronic, or acute.",
  "statistic_type",
  "review",
  "endpoint",
  "Toxicity statistic reported for the record (e.g. NOEC, NOEL, LOEC, MATC, EC50, LC50, IC50, EC10, NEC, NSEC).",
  "effect_category",
  "review",
  "endpoint",
  "Harmonised effect category (controlled vocabulary): MORT, GRO, REP, IMM, DVP, HAT, POP, ABD.",
  "duration_hours",
  "review",
  "endpoint",
  "Test exposure duration in hours (NA where not reported).",
  "life_stage",
  "review",
  "endpoint",
  "Organism life stage at test; NA is a distinct level, not missing-at-random.",
  "conc_ug_L",
  "review",
  "endpoint",
  "Per-record toxicity concentration in µg/L, after unit normalisation and any ACR (÷10) or chronic (÷5/÷2.5/÷2) conversion applied to this record; divide back by acr_applied / chronic_conv_factor to recover the raw value.",
  "conc_unit",
  "review",
  "endpoint",
  "Original concentration unit, normalised to ug/L for every row (wqbench mg/L converted in Stage 4e).",
  "study_reference",
  "review",
  "provenance",
  "Source citation / study reference for the record.",
  "original_scientificname",
  "review",
  "taxonomy",
  "Species name exactly as reported by the source (the native back-track key).",
  "accepted_name",
  "review",
  "taxonomy",
  "Resolved / accepted species name after WoRMS/GBIF resolution; the Stage 4e aggregation species key.",
  "synonym_unified",
  "review",
  "taxonomy",
  "TRUE if original_scientificname was a synonym unified to a different accepted_name.",
  "kingdom",
  "review",
  "taxonomy",
  "Resolved kingdom.",
  "phylum",
  "review",
  "taxonomy",
  "Resolved phylum.",
  "class",
  "review",
  "taxonomy",
  "Resolved class; also the sufficiency grouping variable.",
  "order_taxon",
  "review",
  "taxonomy",
  "Resolved order (named order_taxon to avoid clashing with the reserved word order).",
  "family",
  "review",
  "taxonomy",
  "Resolved family.",
  "genus",
  "review",
  "taxonomy",
  "Resolved genus.",
  "majorgroup",
  "review",
  "taxonomy",
  "Major taxonomic group; equals the resolved class in this file.",
  "taxonomy_provenance",
  "review",
  "taxonomy",
  "Resolver route that produced the taxonomy: worms_full, gbif_full, ambiguous_partial, source_native_fallback, or manual_genus_fallback.",
  "conc_plausibility",
  "review",
  "endpoint",
  "Concentration plausibility flag from the D6 filter: ok, low_soft, or high_soft (hard-implausible records are excluded upstream and never exported).",
  "value_tier",
  "review",
  "provenance",
  "Three-tier hierarchy label for the record (uncurated only here): accepted > chronic_converted > acute_acr; NA for records dropped by the per-species tier-preference filter.",
  "final_conc_ug_L",
  "review",
  "endpoint",
  "Final aggregated published concentration (µg/L) for the record's casnumber_grouped × accepted_name × medium group; populated only on is_provenance rows, NA elsewhere.",
  # --- pipeline-internal ---
  "acr_eligible",
  "internal",
  "conversion",
  "TRUE if statistic_type is ACR-eligible (acute EC50/IC50/LC50), i.e. permitted to undergo the acute-to-chronic ratio conversion.",
  "source_id",
  "internal",
  "bookkeeping",
  "Source-native record identifier as issued by the originating database.",
  "acr_applied",
  "internal",
  "conversion",
  "TRUE if the ACR ÷10 acute-to-chronic conversion was applied to conc_ug_L for this record.",
  "within_source_duplicate",
  "internal",
  "dedup",
  "Stage 4c flag: TRUE if the record was identified as a duplicate of another record within the same source.",
  "dedup_retained",
  "internal",
  "dedup",
  "Stage 4c flag: TRUE if the record was retained after within- and cross-source deduplication (all exported rows are TRUE).",
  "priority_kept",
  "internal",
  "dedup",
  "Stage 4c flag: TRUE if the record survived cross-source priority selection (chronic > subchronic > acute; all exported rows are TRUE).",
  "dedup_note",
  "internal",
  "dedup",
  "Stage 4c free-text note recording the deduplication decision for the record.",
  "resolution_status",
  "internal",
  "taxonomy",
  "Stage 4d name-resolution outcome: exact_filtered, exact_unaccepted_filtered, fuzzy_filtered, ambiguous_after_filter, gbif_resolved, or unresolved.",
  "stat_tier",
  "internal",
  "statistic",
  "Warne et al. 2025 statistic tier for statistic_type (e.g. negligible_no_conversion, appropriate_no_conversion, less_pref_no_conversion, low_effect_conv_2.5, low_effect_conv_2, median_effect_conv_5).",
  "stat_action",
  "internal",
  "statistic",
  "Coarse action derived from stat_tier: accepted (used as-is) or convert (chronic conversion). exclude-tier records are dropped before export.",
  "conv_factor",
  "internal",
  "conversion",
  "Chronic-conversion divisor implied by stat_tier for convert-tier records (5, 2.5, or 2); NA otherwise.",
  "chronic_conv_applied",
  "internal",
  "conversion",
  "TRUE if a chronic §3.4.2.1 conversion (÷5/÷2.5/÷2) was applied to conc_ug_L for this record.",
  "chronic_conv_factor",
  "internal",
  "conversion",
  "The chronic-conversion factor actually applied (conv_factor where chronic_conv_applied is TRUE); NA otherwise.",
  "record_uid",
  "internal",
  "bookkeeping",
  "Unique within-file record identifier assigned to the post-filter base frame (row number).",
  "in_geomean_input",
  "internal",
  "provenance",
  "TRUE if the record survived the three-tier preference filter and fed the geometric-mean aggregation input.",
  "step1_group_id",
  "internal",
  "provenance",
  "Identifier of the Stage 4e Step-1 aggregation group (cas × species × medium × effect_category × statistic_type × duration × life_stage) the record belongs to; NA for records not entering aggregation.",
  "is_provenance",
  "internal",
  "provenance",
  "TRUE if the record belongs to the winning Step-1 group whose value equals the final published concentration for its casnumber_grouped × accepted_name × medium.",
  "provenance_tie",
  "internal",
  "provenance",
  "TRUE if more than one Step-1 group tied at the minimum when selecting the published value for the group (provenance is ambiguous)."
)

# Confirm 1:1 coverage of the exported columns, then order to match the CSV.
dict_csv_cols <- names(allchronic_source)
stopifnot(
  setequal(source_dictionary$column, dict_csv_cols),
  nrow(source_dictionary) == length(dict_csv_cols)
)
source_dictionary <- source_dictionary[
  match(dict_csv_cols, source_dictionary$column),
]

# One real non-NA example per column (whitespace-collapsed, pipe-escaped,
# truncated so wide free-text does not break the markdown table).
dict_example_for <- function(col) {
  v <- allchronic_source[[col]]
  v <- v[!is.na(v)]
  if (length(v) == 0L) {
    return(NA_character_)
  }
  x <- as.character(v[[1]])
  x <- gsub("[\r\n]+", " ", x)
  x <- gsub("\\|", "\\\\|", x)
  if (nchar(x) > 80L) {
    x <- paste0(substr(x, 1L, 77L), "...")
  }
  x
}
source_dictionary$example <- vapply(
  source_dictionary$column,
  dict_example_for,
  character(1)
)

n_dict_missing_example <- sum(is.na(source_dictionary$example))
if (n_dict_missing_example > 0L) {
  message(
    "WARNING: ",
    n_dict_missing_example,
    " dictionary column(s) have no non-NA example: ",
    paste(
      source_dictionary$column[is.na(source_dictionary$example)],
      collapse = ", "
    )
  )
}

emit_dict_table <- function(df) {
  c(
    "| Column | Group | Description | Example value |",
    "|---|---|---|---|",
    paste0(
      "| `",
      df$column,
      "` | ",
      df$group,
      " | ",
      df$description,
      " | ",
      ifelse(
        is.na(df$example),
        "_(no non-NA value present)_",
        paste0("`", df$example, "`")
      ),
      " |"
    )
  )
}

dict_review <- source_dictionary[source_dictionary$facing == "review", ]
dict_internal <- source_dictionary[source_dictionary$facing == "internal", ]

dict_lines <- c(
  "# Data dictionary — `allchronic_data_source.csv`",
  "",
  paste(
    "Row-level, uncurated, **pre-aggregation** provenance file for the",
    "`all_chronic` pipeline (uncurated sources only: anztox, wqbench,",
    "envirotox). One row in the aggregated `allchronic_data` object corresponds",
    "to many rows here — this file records the individual endpoint records that",
    "were rolled up under a parent CAS and a resolved species. The CAS-group",
    "columns (`native_chemicalname`, `casnumber_grouped`, `cas_group_rationale`)",
    "are LLM-assisted / heuristic wherever `cas_group_human_checked = n` and are",
    "pending expert review. The five anztox synthetic-placeholder CAS",
    "(`1`, `100000001`–`100000004`) and the NA-parent junk CAS carry a",
    "curated `exclusion_reason` in the master lookup and are dropped before",
    "extraction (Task B); they never appear in this file."
  ),
  "",
  paste0("Columns: ", nrow(source_dictionary), " total."),
  "",
  "## Review-facing columns",
  "",
  emit_dict_table(dict_review),
  "",
  "## Pipeline-internal columns",
  "",
  emit_dict_table(dict_internal),
  ""
)

writeLines(dict_lines, "data-raw/alldata/allchronic_data_source_dictionary.md")
message(
  "Written: data-raw/alldata/allchronic_data_source_dictionary.md (",
  nrow(source_dictionary),
  " columns; ",
  nrow(dict_review),
  " review-facing, ",
  nrow(dict_internal),
  " pipeline-internal)"
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
  "",
  "### Reviewer-facing chemical-provenance columns (added)",
  "",
  paste(
    "Three columns joined from the master parent lookup",
    "(`data-raw/cas_parent_lookup_all.csv`) on `native_cas = casnumber`, so a",
    "chemist can review each native-to-parent CAS rollup standalone:",
    "`native_chemicalname` (from `chemicalname`), `cas_group_rationale` (from",
    "`match_rationale`), and `cas_group_human_checked` (from `human_checked`).",
    "Additive: row count, filtering, aggregation, and existing column values are",
    "unchanged; the file grows from 46 to",
    paste0(ncol(allchronic_source), " columns.")
  ),
  "",
  paste0(
    "- Excluded CAS (Task B): synthetic-placeholder and NA-parent junk ",
    "`native_cas` are curated rows in the lookup with a non-empty ",
    "`exclusion_reason` and are dropped upstream in ",
    "`stage4b-extract.R`'s `apply_cas_parent_lookup()`, so they never ",
    "reach this source export."
  ),
  paste0(
    "- Validation: NA `native_chemicalname` = ",
    n_na_native_name,
    "; NA `cas_group_rationale` = ",
    n_na_rationale,
    "; NA `cas_group_human_checked` = ",
    n_na_human_checked,
    " (all expected to be 0)."
  ),
  paste(
    "- Data dictionary written to",
    "`data-raw/alldata/allchronic_data_source_dictionary.md`",
    paste0("(", nrow(source_dictionary), " columns).")
  ),
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

fw_family <- c(
  "Freshwater",
  "Soft freshwater",
  "Moderate freshwater",
  "Hard freshwater"
)

normalize_medium <- function(x) {
  dplyr::case_when(
    tolower(trimws(x)) %in% c("freshwater", "fresh") ~ "Freshwater",
    tolower(trimws(x)) == "marine" ~ "Marine",
    tolower(trimws(x)) == "soft freshwater" ~ "Soft freshwater",
    tolower(trimws(x)) == "moderate freshwater" ~ "Moderate freshwater",
    tolower(trimws(x)) == "hard freshwater" ~ "Hard freshwater",
    tolower(trimws(x)) == "unknown" ~ "Unknown",
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
if (!file.exists(cas_curated_path)) {
  stop("curated_cas_lookup.csv not found")
}
curated_cas <- read_csv(cas_curated_path, show_col_types = FALSE)

cas_master_path <- "data-raw/cas_parent_lookup_all.csv"
if (!file.exists(cas_master_path)) {
  stop("cas_parent_lookup_all.csv not found")
}
cas_master <- read_csv(
  cas_master_path,
  guess_max = Inf,
  show_col_types = FALSE
)
cat("cas_parent_lookup_all.csv:", nrow(cas_master), "rows\n")

# Stage 4e ran above; use its in-memory output directly.
# uncurated_raw_aggregated.csv was also written as an audit artefact (untracked).
uncurated_raw <- output
cat("Stage 4e output (in-memory):", nrow(uncurated_raw), "rows\n")

sp_res_curated_path <- "data-raw/alldata/species_resolution_curated.csv"
if (!file.exists(sp_res_curated_path)) {
  stop(
    sp_res_curated_path,
    " not found. Run old DATASET.R once to generate it."
  )
}
sp_res_curated <- read_csv(
  sp_res_curated_path,
  guess_max = Inf,
  show_col_types = FALSE
)
taxonomy_lookup <- sp_res_curated |>
  select(
    query_name,
    accepted_name,
    kingdom,
    phylum,
    class,
    order_taxon,
    family,
    genus,
    taxonomy_provenance
  ) |>
  distinct(query_name, .keep_all = TRUE)

# Common column order for the harmonised frame
schema_cols <- c(
  "source",
  "casnumber_grouped",
  "chemicalname_grouped",
  "accepted_name",
  "medium",
  "conc_ug_L",
  "effect_category",
  "kingdom",
  "phylum",
  "class",
  "order_taxon",
  "family",
  "genus",
  "taxonomy_provenance",
  "n_records",
  "sources_contributing",
  "any_acr_applied",
  "any_chronic_conv_applied",
  "any_conc_flagged",
  "geomean_flagged",
  "lifestage_mixed",
  "duration_mixed",
  "value_tier",
  "timeframe"
)

# -- A1: Uncurated (straight from Stage 4e; value_tier already set)
uncurated_layer <- uncurated_raw |>
  mutate(source = "uncurated", timeframe = NA_character_) |>
  select(all_of(schema_cols))
cat("Uncurated layer:", nrow(uncurated_layer), "rows\n")

# -- A2: ANZG
anzg_cas <- curated_cas |> filter(source == "anzg")

unexpected_anzg_medium <- setdiff(
  unique(anzg_data$Medium),
  # "fresh" is a legacy abbreviation for "Freshwater" in ssddata v1.0.0 anzg_data;
  # normalize_medium() already converts it correctly.
  c(
    "freshwater",
    "fresh",
    "marine",
    "soft freshwater",
    "moderate freshwater",
    "hard freshwater"
  )
)
if (length(unexpected_anzg_medium) > 0) {
  stop(
    "Unexpected ANZG Medium values: ",
    paste(unexpected_anzg_medium, collapse = ", ")
  )
}
anzg_chems_missing <- setdiff(anzg_data$Chemical, anzg_cas$chemical_name)
if (length(anzg_chems_missing) > 0) {
  stop(
    "ANZG chemicals not in curated_cas_lookup: ",
    paste(anzg_chems_missing, collapse = ", ")
  )
}

anzg_layer <- anzg_data |>
  left_join(
    anzg_cas |> select(chemical_name, casnumber_grouped, chemicalname_grouped),
    by = c("Chemical" = "chemical_name")
  ) |>
  mutate(
    source = "anzg",
    accepted_name = paste(Genus, Species),
    medium = normalize_medium(Medium),
    conc_ug_L = Conc,
    timeframe = Timeframe,
    effect_category = NA_character_, # C3: curated sources carry no effect_category
    kingdom = NA_character_,
    phylum = as.character(Phylum),
    class = NA_character_,
    order_taxon = NA_character_,
    family = NA_character_,
    genus = as.character(Genus),
    taxonomy_provenance = "curated_source",
    n_records = 1L,
    sources_contributing = "anzg",
    any_acr_applied = FALSE,
    any_chronic_conv_applied = FALSE,
    any_conc_flagged = FALSE,
    geomean_flagged = FALSE,
    lifestage_mixed = FALSE,
    duration_mixed = FALSE,
    value_tier = "curated"
  ) |>
  select(all_of(schema_cols))

if (any(is.na(anzg_layer$casnumber_grouped))) {
  stop(
    "ANZG rows failed CAS join: ",
    paste(
      unique(anzg_layer$chemicalname_grouped[is.na(
        anzg_layer$casnumber_grouped
      )]),
      collapse = ", "
    )
  )
}
cat("ANZG layer:", nrow(anzg_layer), "rows\n")

# -- A3: CCME (unit conversion required)
ccme_cas <- curated_cas |> filter(source == "ccme")
ccme_chems_missing <- setdiff(ccme_data$Chemical, ccme_cas$chemical_name)
if (length(ccme_chems_missing) > 0) {
  stop(
    "CCME chemicals not in curated_cas_lookup: ",
    paste(ccme_chems_missing, collapse = ", ")
  )
}

ccme_layer <- ccme_data |>
  mutate(
    conc_ug_L = case_when(
      Units %in% c("ug/L", "µg/L") ~ Conc,
      Units == "mg/L" ~ Conc * 1000,
      Units == "ng/L" ~ Conc / 1000,
      TRUE ~ NA_real_
    )
  ) |>
  left_join(
    ccme_cas |> select(chemical_name, casnumber_grouped, chemicalname_grouped),
    by = c("Chemical" = "chemical_name")
  ) |>
  mutate(
    source = "ccme",
    accepted_name = Species,
    medium = Medium, # "Freshwater" in source
    timeframe = Timeframe,
    effect_category = NA_character_, # C3: curated sources carry no effect_category
    kingdom = NA_character_,
    phylum = NA_character_,
    class = NA_character_,
    order_taxon = NA_character_,
    family = NA_character_,
    genus = NA_character_,
    taxonomy_provenance = "curated_source",
    n_records = 1L,
    sources_contributing = "ccme",
    any_acr_applied = FALSE,
    any_chronic_conv_applied = FALSE,
    any_conc_flagged = FALSE,
    geomean_flagged = FALSE,
    lifestage_mixed = FALSE,
    duration_mixed = FALSE,
    value_tier = "curated"
  ) |>
  select(all_of(schema_cols))

if (any(is.na(ccme_layer$conc_ug_L))) {
  stop("CCME unit conversion produced NA")
}
if (any(is.na(ccme_layer$casnumber_grouped))) {
  stop(
    "CCME rows failed CAS join: ",
    paste(
      unique(ccme_layer$accepted_name[is.na(ccme_layer$casnumber_grouped)]),
      collapse = ", "
    )
  )
}
cat("CCME layer:", nrow(ccme_layer), "rows\n")

# -- A4: AIMS and CSIRO — taxonomy from species_resolution_curated.csv
# Geomean within-source duplicates at source × casnumber_grouped × medium × accepted_name
prep_curated_source <- function(df, source_label, cas_subset) {
  df_cas <- df |>
    left_join(
      cas_subset |>
        select(chemical_name, casnumber_grouped, chemicalname_grouped),
      by = c("Chemical" = "chemical_name")
    )
  missing_chem <- unique(df_cas$Chemical[is.na(df_cas$casnumber_grouped)])
  if (length(missing_chem) > 0) {
    stop(
      source_label,
      " chemicals not in curated_cas_lookup: ",
      paste(missing_chem, collapse = ", ")
    )
  }

  # Drop rows with no species name before taxonomy join (S6-D4: no taxon assignable;
  # reinstates exclusion of csiro chlorine/marine acute rows which have NA Species).
  n_no_species <- sum(
    is.na(df_cas$Species) | trimws(as.character(df_cas$Species)) == ""
  )
  if (n_no_species > 0) {
    message(sprintf(
      "  %s: dropping %d NA/empty-Species rows (S6-D4)",
      source_label,
      n_no_species
    ))
    df_cas <- df_cas |>
      filter(!is.na(Species), trimws(as.character(Species)) != "")
  }

  df_tax <- df_cas |>
    left_join(taxonomy_lookup, by = c("Species" = "query_name")) |>
    mutate(
      medium = normalize_medium(Medium),
      accepted_name = case_when(
        !is.na(accepted_name) ~ accepted_name,
        TRUE ~ Species # cache miss: keep input name
      ),
      taxonomy_provenance = case_when(
        !is.na(taxonomy_provenance) ~ taxonomy_provenance,
        TRUE ~ "source_native_fallback"
      )
    )

  # Within-source geomean (with flagging if spread > 1 OOM)
  df_agg <- df_tax |>
    filter(!is.na(Conc)) |>
    group_by(
      casnumber_grouped,
      chemicalname_grouped,
      accepted_name,
      medium,
      kingdom,
      phylum,
      class,
      order_taxon,
      family,
      genus,
      taxonomy_provenance,
      Timeframe
    ) |>
    summarise(
      n_records = n(),
      conc_ug_L = if (n() == 1 || max(Conc) / min(Conc) <= 10) {
        exp(mean(log(Conc)))
      } else {
        min(Conc)
      },
      geomean_flagged = n() > 1 && max(Conc) / min(Conc) > 10,
      .groups = "drop"
    ) |>
    mutate(
      source = source_label,
      timeframe = Timeframe,
      effect_category = NA_character_, # C3: curated sources carry no effect_category
      sources_contributing = source_label,
      any_acr_applied = FALSE,
      any_chronic_conv_applied = FALSE,
      any_conc_flagged = FALSE,
      lifestage_mixed = FALSE,
      duration_mixed = FALSE,
      value_tier = "curated"
    ) |>
    select(all_of(schema_cols))

  df_agg
}

aims_cas <- curated_cas |> filter(source == "aims")
csiro_cas <- curated_cas |> filter(source == "csiro")

n_aims_no_species <- sum(
  is.na(aims_data$Species) | trimws(as.character(aims_data$Species)) == ""
)
n_csiro_no_species <- sum(
  is.na(csiro_data$Species) | trimws(as.character(csiro_data$Species)) == ""
)

aims_layer <- prep_curated_source(aims_data, "aims", aims_cas)
csiro_layer <- prep_curated_source(csiro_data, "csiro", csiro_cas)

# Validate within-source dedup
aims_dups <- aims_layer |>
  group_by(source, casnumber_grouped, medium, accepted_name) |>
  filter(n() > 1) |>
  ungroup()
csiro_dups <- csiro_layer |>
  group_by(source, casnumber_grouped, medium, accepted_name) |>
  filter(n() > 1) |>
  ungroup()
if (nrow(aims_dups) > 0 || nrow(csiro_dups) > 0) {
  stop(
    "Within-source geomean dedup FAILED: ",
    nrow(aims_dups),
    " aims, ",
    nrow(csiro_dups),
    " csiro key duplicates remain"
  )
}

cat(
  "AIMS:  ",
  nrow(aims_data),
  "input rows →",
  nrow(aims_layer),
  "aggregated\n"
)
cat(
  "CSIRO: ",
  nrow(csiro_data),
  "input rows →",
  nrow(csiro_layer),
  "aggregated\n"
)
cat("Within-source geomean dedup: PASS\n\n")

# ============================================================
# STEP B — Source-priority exclusion
# ============================================================

cat("== Step B: Curated integration ==\n\n")

all_rows <- bind_rows(
  anzg_layer,
  ccme_layer,
  aims_layer,
  csiro_layer,
  uncurated_layer
) |>
  mutate(excl = NA_character_)

cat("Combined frame:", nrow(all_rows), "rows\n")
cat("By source:\n")
print(count(all_rows, source))

# B1: ANZG exclusion
# Freshwater-family: broad-match at chemical level (any FW variant → exclude all FW-family non-anzg)
# Marine: per casnumber_grouped × medium
anzg_positions <- all_rows |>
  filter(source == "anzg") |>
  select(casnumber_grouped, medium) |>
  distinct()

anzg_fw_cas <- anzg_positions |>
  filter(medium %in% fw_family) |>
  pull(casnumber_grouped) |>
  unique()
anzg_marine_cas <- anzg_positions |>
  filter(medium == "Marine") |>
  pull(casnumber_grouped) |>
  unique()

all_rows <- all_rows |>
  mutate(
    excl = case_when(
      !is.na(excl) ~ excl,
      source != "anzg" &
        casnumber_grouped %in% anzg_fw_cas &
        medium %in% fw_family ~ "anzg_fw",
      source != "anzg" &
        casnumber_grouped %in% anzg_marine_cas &
        medium == "Marine" ~ "anzg_marine",
      TRUE ~ excl
    )
  )

n_anzg_fw_excl <- sum(all_rows$excl == "anzg_fw", na.rm = TRUE)
n_anzg_marine_excl <- sum(all_rows$excl == "anzg_marine", na.rm = TRUE)
cat("ANZG exclusion — freshwater-family rows excluded:", n_anzg_fw_excl, "\n")
cat(
  "ANZG exclusion — marine rows excluded:          ",
  n_anzg_marine_excl,
  "\n"
)

# B2: CCME exclusion (per casnumber_grouped × medium, for aims/csiro/uncurated only)
ccme_chem_medium <- all_rows |>
  filter(source == "ccme") |>
  select(casnumber_grouped, medium) |>
  distinct() |>
  mutate(ccme_covered = TRUE)

all_rows <- all_rows |>
  left_join(ccme_chem_medium, by = c("casnumber_grouped", "medium")) |>
  mutate(
    excl = case_when(
      !is.na(excl) ~ excl,
      source %in% c("aims", "csiro", "uncurated") & !is.na(ccme_covered) ~
        paste0("ccme_", medium_token(medium)),
      TRUE ~ excl
    )
  ) |>
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
    left_join(
      overlap_groups,
      by = c("casnumber_grouped", "medium", "accepted_name")
    ) |>
    mutate(
      excl = case_when(
        !is.na(excl) ~ excl,
        source %in%
          c("aims", "csiro", "uncurated") &
          !is.na(winner_source) &
          source != winner_source ~
          paste0("priority_", winner_source, "_over_", source),
        TRUE ~ excl
      )
    ) |>
    select(-winner_source)
}

n_pref_excl <- sum(grepl("^priority_", all_rows$excl), na.rm = TRUE)
cat("Preference hierarchy:", n_pref_excl, "rows excluded\n\n")

# Save exclusion summary for report
excl_summary <- count(all_rows, excl) |> arrange(desc(n))

retained <- all_rows |> filter(is.na(excl)) |> select(-excl)
cat("Retained rows:", nrow(retained), "\n")

# ============================================================
# STEP B4 — Timeframe scope exclusion (post-priority)
# ============================================================
# Curated records carry a Timeframe attribute ("chronic" / "short_term") set
# by the source curator; short_term records are out of scope for
# allchronic_data. Applied AFTER B1-B3 (not before B1): B1 computes
# anzg_marine_cas from ANZG's own marine rows, so ANZG's chlorine/marine rows
# must still be present when B1 runs, else uncurated marine chlorine leaks in.
timeframe_excl_rows <- retained |> filter(timeframe == "short_term")
n_timeframe_excl <- nrow(timeframe_excl_rows)
timeframe_excl_by_source <- if (n_timeframe_excl > 0) {
  count(timeframe_excl_rows, source)
} else {
  tibble(source = character(), n = integer())
}

cat("Timeframe scope exclusion:\n")
if (n_timeframe_excl > 0) {
  print(timeframe_excl_by_source)
  cat(" ", n_timeframe_excl, "rows marked out-of-scope for allchronic_data\n")
} else {
  cat("  0 rows excluded\n")
}
cat("\n")

# Write audit CSV (tracked; small — only the excluded rows)
timeframe_excl_rows |>
  select(
    source,
    chemical = chemicalname_grouped,
    casnumber_grouped,
    medium,
    accepted_name,
    conc_ug_L,
    value_tier,
    taxonomy_provenance
  ) |>
  write_csv("data-raw/alldata/stage6-timeframe-excluded.csv")
cat("Written: data-raw/alldata/stage6-timeframe-excluded.csv\n\n")

retained <- retained |>
  filter(is.na(timeframe) | timeframe != "short_term") |>
  select(-timeframe)
cat("Retained rows after Timeframe exclusion:", nrow(retained), "\n")

retained_by_source_medium <- count(retained, source, medium) |>
  arrange(source, medium)
cat("By source × medium:\n")
print(retained_by_source_medium, n = 30)

# ============================================================
# STEP C — Medium viability + pooling
# ============================================================

cat("\n== Step C: Medium viability + pooling ==\n\n")

# Separate real-medium and Unknown rows
real_medium_rows <- retained |> filter(medium != "Unknown")
unknown_rows <- retained |> filter(medium == "Unknown")

# C1: Viability per casnumber_grouped × medium
# (each freshwater variant assessed separately)
viability <- real_medium_rows |>
  group_by(casnumber_grouped, medium) |>
  summarise(
    has_curated = any(source %in% c("anzg", "ccme", "aims", "csiro")),
    n_species = n_distinct(accepted_name),
    n_classes = n_distinct(class[!is.na(class)]),
    .groups = "drop"
  ) |>
  mutate(viable = has_curated | (n_species >= 5 & n_classes >= 4))

cat("Real-medium viability:\n")
cat("  Total combinations:    ", nrow(viability), "\n")
cat("  Viable (curated-backed or ≥5sp/≥4cl):", sum(viability$viable), "\n")
cat("  Via curated:           ", sum(viability$has_curated), "\n")
cat(
  "  Via uncurated only:    ",
  sum(!viability$has_curated & viability$viable),
  "\n"
)
cat("  Non-viable:            ", sum(!viability$viable), "\n\n")

# C2: Standalone real-medium sets
standalone_keys <- viability |>
  filter(viable) |>
  select(casnumber_grouped, medium)

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
    marine_viable = any(medium == "Marine"),
    .groups = "drop"
  )

# C4: Non-viable real-medium rows → pool
non_viable_real <- real_medium_rows |>
  anti_join(standalone_keys, by = c("casnumber_grouped", "medium"))

# C5: Unknown rows → pool (dropped if both fw_family and marine are viable for that chemical)
unknown_for_pool <- unknown_rows |>
  left_join(
    chem_fw_marine |>
      select(casnumber_grouped, fw_family_viable, marine_viable),
    by = "casnumber_grouped"
  ) |>
  mutate(
    fw_family_viable = if_else(
      is.na(fw_family_viable),
      FALSE,
      fw_family_viable
    ),
    marine_viable = if_else(is.na(marine_viable), FALSE, marine_viable)
  ) |>
  filter(!(fw_family_viable & marine_viable)) |> # option-a: drop Unknown if both viable
  select(-fw_family_viable, -marine_viable)

n_unknown_dropped <- nrow(unknown_rows) - nrow(unknown_for_pool)
cat(
  "Unknown rows dropped (both FW and Marine viable):",
  n_unknown_dropped,
  "\n"
)
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
    .groups = "drop"
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
  mutate(
    Set = paste0(sanitise_key(chemicalname_grouped), "_", medium_token(medium))
  )

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
  warning(
    "Set key collision(s) detected; falling back to CAS-based keys for: ",
    paste(unique(key_check$Set), collapse = ", ")
  )
  colliding_sets <- unique(key_check$Set)
  # For mixed sets use CAS_mixed; for real-medium sets use CAS_medium_token.
  # medium is consistent within a non-mixed set (per casnumber_grouped × medium),
  # so medium_token(medium) is safe to use per-row for standalone sets.
  all_final <- all_final |>
    mutate(
      Set = case_when(
        !(Set %in% colliding_sets) ~ Set,
        grepl("_mixed$", Set) ~ paste0(
          sanitise_key(as.character(casnumber_grouped)),
          "_mixed"
        ),
        TRUE ~ paste0(
          sanitise_key(as.character(casnumber_grouped)),
          "_",
          medium_token(medium)
        )
      )
    )
}

# Assert Set uniqueness (one Set per casnumber_grouped)
set_uniqueness <- all_final |>
  select(Set, casnumber_grouped) |>
  distinct() |>
  group_by(Set) |>
  filter(n() > 1) |>
  ungroup()
if (nrow(set_uniqueness) > 0) {
  stop("Set key still collides after fallback — review logic.")
}

# D3: Rename to PascalCase and select final columns
allchronic_data <- all_final |>
  select(-any_of("majorgroup")) |>
  rename(
    Species = accepted_name,
    Conc = conc_ug_L,
    Chemical = chemicalname_grouped,
    CAS = casnumber_grouped,
    Medium = medium,
    Source = source,
    ValueTier = value_tier,
    AnyChronicConvApplied = any_chronic_conv_applied,
    EffectCategory = effect_category, # C1: effect_category of selected endpoint (NA for curated)
    Class = class,
    Kingdom = kingdom,
    Phylum = phylum,
    Order = order_taxon,
    Family = family,
    Genus = genus,
    TaxonomyProvenance = taxonomy_provenance,
    NRecords = n_records,
    SourcesContributing = sources_contributing,
    AnyAcrApplied = any_acr_applied,
    AnyConcFlagged = any_conc_flagged,
    GeomeanFlagged = geomean_flagged,
    LifestageMixed = lifestage_mixed,
    DurationMixed = duration_mixed
  ) |>
  select(
    Species,
    Conc,
    Chemical,
    CAS,
    Medium,
    Source,
    ValueTier,
    AnyChronicConvApplied,
    EffectCategory,
    Class,
    Kingdom,
    Phylum,
    Order,
    Family,
    Genus,
    TaxonomyProvenance,
    NRecords,
    SourcesContributing,
    AnyAcrApplied,
    AnyConcFlagged,
    GeomeanFlagged,
    LifestageMixed,
    DurationMixed,
    Set
  ) |>
  as_tibble()

cat(
  "allchronic_data:",
  nrow(allchronic_data),
  "rows,",
  ncol(allchronic_data),
  "cols\n"
)
cat("Distinct Set keys:", n_distinct(allchronic_data$Set), "\n")

# ============================================================
# VALIDATION CHECKS
# ============================================================

cat("\n== Validation checks ==\n")
checks_passed <- TRUE
n_checks_run <- 0L
chk <- function(cond, label, detail = NULL) {
  status <- if (cond) "PASS" else "FAIL"
  cat(" ", status, "--", label, "\n")
  if (!cond && !is.null(detail)) {
    cat("   Detail:", detail, "\n")
  }
  if (!cond) checks_passed <<- FALSE
  n_checks_run <<- n_checks_run + 1L
}

# V1: Curated rows have ValueTier=="curated", AnyChronicConvApplied==FALSE, EffectCategory==NA
curated_vt_ok <- allchronic_data |>
  filter(Source %in% c("anzg", "ccme", "aims", "csiro")) |>
  summarise(
    ok = all(ValueTier == "curated") &&
      all(!AnyChronicConvApplied) &&
      all(is.na(EffectCategory))
  ) |>
  pull(ok)
chk(
  curated_vt_ok,
  "Curated rows: ValueTier=='curated', AnyChronicConvApplied==FALSE, EffectCategory==NA"
)

# V2: No aims/csiro duplicates (per source × CAS × medium × species)
aims_csiro_dups <- allchronic_data |>
  filter(Source %in% c("aims", "csiro")) |>
  group_by(Source, CAS, Medium, Species) |>
  filter(n() > 1) |>
  ungroup()
chk(
  nrow(aims_csiro_dups) == 0,
  "AIMS/CSIRO: one row per source × CAS × medium × species",
  if (nrow(aims_csiro_dups) > 0) {
    paste(nrow(aims_csiro_dups), "duplicate rows")
  } else {
    NULL
  }
)

# V3: No anzg/ccme chemical×medium shared with another source
curated_excl_check <- allchronic_data |>
  filter(Source %in% c("anzg", "ccme")) |>
  select(CAS, Medium) |>
  distinct() |>
  left_join(
    allchronic_data |>
      filter(!Source %in% c("anzg", "ccme")) |>
      select(CAS, Medium) |>
      distinct() |>
      mutate(other_present = TRUE),
    by = c("CAS", "Medium")
  )
curated_leak <- sum(!is.na(curated_excl_check$other_present))
chk(
  curated_leak == 0,
  "ANZG/CCME chemical×medium not shared with other sources",
  if (curated_leak > 0) {
    paste(curated_leak, "chemical×medium combinations leak")
  } else {
    NULL
  }
)

# V4: Every standalone set is viable (curated-backed or ≥5sp/≥4cl)
standalone_viability_check <- allchronic_data |>
  filter(!grepl("_mixed$", Set)) |>
  group_by(Set, CAS, Medium) |>
  summarise(
    has_curated = any(Source %in% c("anzg", "ccme", "aims", "csiro")),
    n_sp = n_distinct(Species),
    n_cl = n_distinct(Class[!is.na(Class)]),
    .groups = "drop"
  ) |>
  filter(!has_curated & (n_sp < 5 | n_cl < 4))
chk(
  nrow(standalone_viability_check) == 0,
  "Every standalone real-medium set is viable (curated-backed or >=5sp/>=4cl)",
  if (nrow(standalone_viability_check) > 0) {
    paste(nrow(standalone_viability_check), "non-viable standalone sets")
  } else {
    NULL
  }
)

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
chk(
  nrow(mixed_viability_check) == 0,
  "Every mixed set passes >=5 species / >=4 classes",
  if (nrow(mixed_viability_check) > 0) {
    paste(nrow(mixed_viability_check), "failing mixed sets")
  } else {
    NULL
  }
)

# V6: No overlap between standalone and mixed sets for same chemical
overlap_check <- allchronic_data |>
  mutate(in_mixed = grepl("_mixed$", Set)) |>
  group_by(CAS, Species) |>
  summarise(
    has_standalone = any(!in_mixed),
    has_mixed = any(in_mixed),
    .groups = "drop"
  ) |>
  filter(has_standalone & has_mixed)
chk(
  nrow(overlap_check) == 0,
  "No species appears in both a standalone set and that chemical's mixed set",
  if (nrow(overlap_check) > 0) {
    paste(nrow(overlap_check), "overlapping chemical×species")
  } else {
    NULL
  }
)

# V7: Unknown-medium rows only in mixed sets
unknown_in_standalone <- allchronic_data |>
  filter(Medium == "Unknown", !grepl("_mixed$", Set))
chk(
  nrow(unknown_in_standalone) == 0,
  "Unknown-medium rows only appear in mixed sets",
  if (nrow(unknown_in_standalone) > 0) {
    paste(nrow(unknown_in_standalone), "rows")
  } else {
    NULL
  }
)

# V8: ANZG freshwater variants appear as distinct Set values (never collapsed)
anzg_fw_sets <- allchronic_data |>
  filter(Source == "anzg", Medium %in% fw_family) |>
  distinct(Chemical, Medium, Set)
all_fw_distinct <- !any(duplicated(anzg_fw_sets$Set))
chk(
  all_fw_distinct,
  "ANZG freshwater variants are distinct Set values (never collapsed)"
)

# V9: Set key uniqueness (each Set maps to exactly one CAS)
set_cas_map <- allchronic_data |>
  distinct(Set, CAS) |>
  group_by(Set) |>
  filter(n() > 1) |>
  ungroup()
chk(
  nrow(set_cas_map) == 0,
  "Set keys are unique (1 CAS per Set)",
  if (nrow(set_cas_map) > 0) {
    paste(nrow(set_cas_map), "conflicting Set keys")
  } else {
    NULL
  }
)

# V10: Mixed sets have one row per species
mixed_sp_dups <- allchronic_data |>
  filter(grepl("_mixed$", Set)) |>
  group_by(Set, Species) |>
  filter(n() > 1) |>
  ungroup()
chk(
  nrow(mixed_sp_dups) == 0,
  "Mixed sets have one row per species",
  if (nrow(mixed_sp_dups) > 0) {
    paste(nrow(mixed_sp_dups), "duplicate species in mixed sets")
  } else {
    NULL
  }
)

# V11: Basic data quality
chk(!anyNA(allchronic_data$Species), "Species: no NA")
chk(!anyNA(allchronic_data$Conc), "Conc: no NA")
chk(all(allchronic_data$Conc > 0), "Conc: all > 0")
chk(!anyNA(allchronic_data$Set), "Set: no NA")

# V12: No placeholder or empty Species values (guards against re-introduction of coined names)
bad_species <- allchronic_data |>
  filter(
    is.na(Species) |
      trimws(Species) == "" |
      grepl("^Unknown", Species) |
      grepl("no name in source", Species, ignore.case = TRUE)
  )
chk(
  nrow(bad_species) == 0,
  "Species: no NA, empty, or placeholder values",
  if (nrow(bad_species) > 0) {
    paste(
      nrow(bad_species),
      "rows:",
      paste(unique(head(bad_species$Species, 5)), collapse = "; ")
    )
  } else {
    NULL
  }
)

# V13: No curated row with Timeframe == "short_term" survives into allchronic_data,
# and no chlorine_marine set is emitted.
timeframe_survivors <- allchronic_data |>
  semi_join(
    timeframe_excl_rows |>
      select(CAS = casnumber_grouped, Medium = medium) |>
      distinct(),
    by = c("CAS", "Medium")
  )
chlorine_marine_present <- "chlorine_marine" %in% unique(allchronic_data$Set)
chk(
  nrow(timeframe_survivors) == 0 && !chlorine_marine_present,
  "No short_term-Timeframe rows or chlorine_marine set in allchronic_data",
  if (nrow(timeframe_survivors) > 0 || chlorine_marine_present) {
    paste0(
      nrow(timeframe_survivors),
      " survivor rows; chlorine_marine present: ",
      chlorine_marine_present
    )
  } else {
    NULL
  }
)

if (!checks_passed) {
  stop("Validation FAILED — see above.")
}
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
  mutate(
    medium_type = case_when(
      grepl("_mixed$", Set) ~ "mixed",
      Medium == "Marine" ~ "marine",
      Medium %in% fw_family ~ "freshwater-family",
      TRUE ~ "other"
    )
  ) |>
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
  paste0(
    "- AIMS:  ",
    nrow(aims_data),
    " input rows → ",
    nrow(aims_layer),
    " aggregated"
  ),
  paste0(
    "- CSIRO: ",
    nrow(csiro_data),
    " input rows → ",
    nrow(csiro_layer),
    " aggregated"
  ),
  paste0(
    "- AIMS NA/empty-Species rows dropped (S6-D4 — no taxon assignable): ",
    n_aims_no_species
  ),
  paste0(
    "- CSIRO NA/empty-Species rows dropped (S6-D4 — no taxon assignable): ",
    n_csiro_no_species
  ),
  "",
  "## 3. Source-priority and scope exclusion",
  "",
  "| Rule | Rows excluded |",
  "|------|--------------|",
  paste0(
    "| ANZG freshwater-family (broad, per chemical) | ",
    n_anzg_fw_excl,
    " |"
  ),
  paste0("| ANZG marine (per chemical × Marine) | ", n_anzg_marine_excl, " |"),
  paste0("| CCME (per chemical × medium) | ", n_ccme_excl, " |"),
  paste0(
    "| Preference hierarchy (aims > csiro > uncurated) | ",
    n_pref_excl,
    " |"
  ),
  paste0(
    "| Timeframe scope (short_term Timeframe attribute; post priority gates) | ",
    n_timeframe_excl,
    " |"
  ),
  "",
  paste0(
    "Timeframe exclusion by source: ",
    if (n_timeframe_excl > 0) {
      paste(
        sprintf(
          "%s=%d",
          timeframe_excl_by_source$source,
          timeframe_excl_by_source$n
        ),
        collapse = ", "
      )
    } else {
      "none"
    }
  ),
  "",
  "## 4. Retained rows by source × medium",
  "",
  "| Source | Medium | Rows |",
  "|--------|--------|------|",
  paste(
    sprintf(
      "| %s | %s | %d |",
      retained_by_source_medium$source,
      retained_by_source_medium$medium,
      retained_by_source_medium$n
    ),
    collapse = "\n"
  ),
  paste0("| **Total** | | **", nrow(retained), "** |"),
  "",
  "## 5. CCME notes",
  "",
  paste0(
    "CCME medium in data: ",
    paste(unique(ccme_layer$medium), collapse = ", ")
  ),
  paste0(
    "CCME input rows: ",
    nrow(ccme_data),
    "; retained after ANZG exclusion: ",
    sum(allchronic_data$Source == "ccme")
  ),
  "NOTE: ccme Medium is 'Freshwater'. Issue #34 RESOLVED 2026-07-06 — supplier",
  "(Angeline, CCME) confirmed all ccme data are chronic exposures in freshwater",
  "media, matching the pipeline's Freshwater + curated-chronic treatment.",
  "",
  "## 6. Validation",
  "",
  if (checks_passed) {
    "All validation checks PASSED."
  } else {
    "VALIDATION FAILED — see console output."
  },
  ""
)
writeLines(report6_lines, "data-raw/alldata/stage6-integration-report.md")
cat("Written: data-raw/alldata/stage6-integration-report.md\n")

# --- Stage 7 eligibility report ---
set_med_counts <- allchronic_data |>
  mutate(
    set_type = case_when(
      grepl("_mixed$", Set) ~ "mixed",
      TRUE ~ medium_token(Medium)
    )
  ) |>
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
  paste0(
    "Columns: ",
    ncol(allchronic_data),
    " (Species, Conc, Chemical, CAS, Medium, Source, ValueTier,"
  ),
  "  AnyChronicConvApplied, EffectCategory, Class, Kingdom, Phylum, Order, Family, Genus,",
  "  TaxonomyProvenance, NRecords, SourcesContributing, AnyAcrApplied, AnyConcFlagged,",
  "  GeomeanFlagged, LifestageMixed, DurationMixed, Set)",
  paste0(
    "  EffectCategory: effect_category of the selected endpoint (traditional only;",
    " NA for curated sources)"
  ),
  "",
  "## 2. Set counts by type",
  "",
  "| Set type | n_sets | n_rows |",
  "|----------|--------|--------|",
  paste(
    sprintf(
      "| %s | %d | %d |",
      set_med_counts$set_type,
      set_med_counts$n_sets,
      set_med_counts$n_rows
    ),
    collapse = "\n"
  ),
  "",
  "## 3. Medium viability summary",
  "",
  paste0("Real-medium combinations assessed: ", nrow(viability)),
  paste0(
    "Viable: ",
    sum(viability$viable),
    " (",
    round(100 * sum(viability$viable) / nrow(viability), 1),
    "%)"
  ),
  paste0("  — curated-backed: ", sum(viability$has_curated)),
  paste0(
    "  — uncurated only (≥5sp/≥4cl): ",
    sum(!viability$has_curated & viability$viable)
  ),
  paste0("  — non-viable: ", sum(!viability$viable)),
  paste0("Mixed sets emitted: ", nrow(mixed_viability)),
  paste0("Unknown rows dropped (FW+Marine both viable): ", n_unknown_dropped),
  "",
  "## 4. ValueTier breakdown",
  "",
  "| ValueTier | Rows |",
  "|-----------|------|",
  paste(
    sprintf("| %s | %d |", vt_counts$ValueTier, vt_counts$n),
    collapse = "\n"
  ),
  "",
  "## 5. Source breakdown",
  "",
  "| Source | Rows |",
  "|--------|------|",
  paste(
    sprintf("| %s | %d |", src_counts$Source, src_counts$n),
    collapse = "\n"
  ),
  "",
  paste0("## 5a. EffectCategory breakdown (C3)"),
  "",
  paste0(
    "EffectCategory is NA for all curated rows (anzg, ccme, aims, csiro); ",
    "uncurated rows carry the traditional endpoint code of the selected value."
  ),
  paste0(
    "- NA EffectCategory (curated rows): ",
    sum(is.na(allchronic_data$EffectCategory))
  ),
  paste0(
    "- Non-NA EffectCategory (uncurated rows): ",
    sum(!is.na(allchronic_data$EffectCategory))
  ),
  "",
  "## 6. Validation",
  "",
  if (checks_passed) {
    paste0("All ", n_checks_run, " validation checks PASSED.")
  } else {
    "VALIDATION FAILED."
  },
  "",
  "## 7. Files produced",
  "",
  paste0(
    "- `data/allchronic_data.rda` — ",
    nrow(allchronic_data),
    " rows × ",
    ncol(allchronic_data),
    " cols, ",
    rda_kb,
    " KB"
  ),
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
cat("  [ ] data-raw/alldata/stage6-timeframe-excluded.csv\n")
cat("  [ ] data-raw/alldata/stage4e-aggregation-report.md\n")
cat("  [ ] data-raw/alldata/stage4e-statistic-type-excluded.csv\n")
cat("  [ ] R/get_ssddata.R\n")
cat("  [ ] R/allchronic_data.R\n")
cat("  [ ] data/allchronic_data.rda\n")
cat("  [ ] man/*.Rd  (after devtools::document())\n")
cat("  [ ] data-raw/alldata/stage6-integration-report.md\n")
cat("  [ ] data-raw/alldata/stage7-eligibility-report.md\n")
cat("  (untracked: uncurated_raw_aggregated.csv, allchronic_data_source.csv)\n")
