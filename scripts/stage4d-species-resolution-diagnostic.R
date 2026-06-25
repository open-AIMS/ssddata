# =============================================================================
# scripts/stage4d-species-resolution-diagnostic.R
# =============================================================================
# Purpose:
#   Stage 4d Part 1 -- species name resolution diagnostic. Extracts the
#   distinct `scientificname` values from the final clean subset of
#   `uncurated_raw_dedup.csv` (dedup_retained & priority_kept both TRUE) and
#   submits each name, exactly as it appears in the source data (no
#   normalisation), to WoRMS (primary), falling back to GBIF only for WoRMS
#   no_match / api_error cases. Reports resolution status, taxonomic
#   hierarchy, and habitat flags per species.
#
#   This is diagnostic only -- it does NOT modify uncurated_raw_dedup.csv or
#   any other existing file. Normalisation strategy, manual review queue,
#   hard exclusions, and majorgroup derivation are Part 2 decisions, made
#   after reviewing this script's report.
#
# Inputs:
#   data-raw/alldata/uncurated_raw_dedup.csv (449,888 rows x 21 cols).
#   Filtered here to dedup_retained == TRUE & priority_kept == TRUE
#   (381,410 rows; 4,348 distinct scientificname values as of 2026-06-24).
#
# Outputs:
#   data-raw/alldata/species_resolution_cache.rds
#     Raw resolver responses, named list keyed by the raw species string.
#   data-raw/alldata/species_resolution_summary.csv
#     One row per unique species with resolution status and key hierarchy
#     fields.
#   data-raw/alldata/stage4d-species-resolution-report.md
#     Markdown diagnostic report (see script footer for section list).
#
# Resolver parameters (and why):
#   - worrms::wm_records_name(fuzzy = TRUE, marine_only = FALSE).
#     `marine_only` defaults to TRUE in worrms, which filters the match set
#     to taxa flagged isMarine -- the package's own documentation
#     recommends marine_only = FALSE for non-marine genera (e.g.
#     Platanista). This dataset spans Freshwater, Marine, and Unknown
#     media, so marine_only = TRUE would systematically bias resolution
#     against freshwater/terrestrial species. fuzzy = TRUE is used so
#     spelling variants are returned as candidates rather than dropped by
#     the API; this script does its own classification (exact /
#     exact_unaccepted / fuzzy / ambiguous / no_match) from the returned
#     candidate set rather than relying on the API's fuzzy flag alone.
#   - rgbif::name_backbone() always returns one row (matchType "NONE" for
#     no match) rather than erroring, so no_match and api_error are
#     distinguished directly from matchType / caught exceptions.
#
# Resumability:
#   Results are cached to species_resolution_cache.rds keyed by the raw
#   species string. Re-running this script loads the existing cache and
#   only queries species not already present, so an interrupted run can be
#   resumed without re-querying already-resolved species. The cache is
#   checkpointed to disk every 100 species processed in this run, and saved
#   again at the end regardless.
#
# Runs from WSL or Windows Positron. No DB connection required -- reads
# only the Stage 4c dedup CSV.
#
# CRITICAL PATH NOTE: the master CAS lookup lives at
# data-raw/cas_parent_lookup_all.csv (NOT
# data-raw/anztox/cas_parent_lookup_all.csv). Not used in this script --
# preserved per project convention.
# =============================================================================

required_pkgs <- c("taxize", "worrms", "rgbif", "dplyr", "readr", "purrr", "tibble")
missing_pkgs <- required_pkgs[!required_pkgs %in% rownames(installed.packages())]
if (length(missing_pkgs) > 0) {
  stop(
    "Missing required package(s): ", paste(missing_pkgs, collapse = ", "), "\n",
    "Install with:\n",
    "  install.packages(c(", paste0('"', missing_pkgs, '"', collapse = ", "), "))",
    call. = FALSE
  )
}

library(dplyr)
library(readr)
library(purrr)
library(tibble)
library(worrms)
library(rgbif)

input_path <- "data-raw/alldata/uncurated_raw_dedup.csv"
cache_path <- "data-raw/alldata/species_resolution_cache.rds"
summary_path <- "data-raw/alldata/species_resolution_summary.csv"
report_path <- "data-raw/alldata/stage4d-species-resolution-report.md"

# ---- Step 2: extract unique species from the final clean subset -----------

dedup <- read_csv(input_path, show_col_types = FALSE)

clean <- dedup |>
  filter(dedup_retained %in% TRUE, priority_kept %in% TRUE)

n_clean_rows <- nrow(clean)
cat("Final clean subset rows:", n_clean_rows, "\n")

species_summary <- clean |>
  group_by(raw_species = scientificname) |>
  summarise(
    n_rows = n(),
    sources = paste(sort(unique(source)), collapse = ","),
    example_cas = dplyr::first(native_cas),
    .groups = "drop"
  ) |>
  arrange(desc(n_rows))

n_unique_species <- nrow(species_summary)
cat("Distinct scientificname values:", n_unique_species, "\n")

# ---- Step 3: load or initialise cache --------------------------------------

if (file.exists(cache_path)) {
  cache <- readRDS(cache_path)
  cat("Loaded existing cache with", length(cache), "entries.\n")
} else {
  cache <- list()
  cat("No existing cache found -- starting fresh.\n")
}

save_checkpoint <- function() {
  saveRDS(cache, cache_path)
}

# ---- Step 4/5: resolve each species (WoRMS primary, GBIF fallback) --------

classify_worms <- function(name, records) {
  if (is.null(records) || nrow(records) == 0) {
    return(list(status = "no_match", record = NULL))
  }
  if (nrow(records) > 1) {
    return(list(status = "ambiguous", record = records))
  }
  rec <- records[1, ]
  if (identical(rec$scientificname, name)) {
    if (identical(rec$status, "accepted")) {
      return(list(status = "exact", record = rec))
    }
    return(list(status = "exact_unaccepted", record = rec))
  }
  list(status = "fuzzy", record = rec)
}

query_worms <- function(name) {
  result <- tryCatch(
    worrms::wm_records_name(name, fuzzy = TRUE, marine_only = FALSE),
    error = function(e) e
  )
  if (inherits(result, "error")) {
    # WoRMS returns HTTP 204 (No Content) for most zero-result searches, but
    # 404 (Not Found) for some queries containing punctuation (e.g. "Genus
    # sp." -- confirmed empirically during development). Both mean "no
    # taxon found", not a connectivity/server problem, so both are
    # classified as no_match rather than api_error.
    if (grepl("204|404", conditionMessage(result))) {
      return(list(status = "no_match", record = NULL, error = NULL))
    }
    return(list(status = "api_error", record = NULL, error = conditionMessage(result)))
  }
  c(classify_worms(name, result), list(error = NULL))
}

classify_gbif_match_type <- function(match_type) {
  switch(
    match_type,
    EXACT = "gbif_exact",
    FUZZY = "gbif_fuzzy",
    HIGHERRANK = "gbif_fuzzy",
    VARIANT = "gbif_fuzzy",
    NONE = "gbif_no_match",
    "gbif_fuzzy"
  )
}

query_gbif <- function(name) {
  result <- tryCatch(
    rgbif::name_backbone(name = name, verbose = FALSE),
    error = function(e) e
  )
  if (inherits(result, "error")) {
    return(list(status = "gbif_api_error", record = NULL, error = conditionMessage(result)))
  }
  rec <- result[1, ]
  status <- classify_gbif_match_type(rec$matchType)
  if (status == "gbif_no_match") rec <- NULL
  list(status = status, record = rec, error = NULL)
}

species_names <- species_summary$raw_species
n_total <- length(species_names)
n_processed <- 0

for (nm in species_names) {
  if (!is.null(cache[[nm]])) next

  worms_res <- query_worms(nm)
  Sys.sleep(0.2)

  gbif_res <- NULL
  if (worms_res$status %in% c("no_match", "api_error")) {
    gbif_res <- query_gbif(nm)
    Sys.sleep(0.1)
  }

  cache[[nm]] <- list(worms = worms_res, gbif = gbif_res)

  n_processed <- n_processed + 1
  if (n_processed %% 100 == 0) {
    cat(sprintf("Processed %d new species (cache has %d / %d total)...\n", n_processed, length(cache), n_total))
    save_checkpoint()
  }
}

save_checkpoint()
cat("Resolution complete. Cache has", length(cache), "/", n_total, "entries.\n")

# ---- Step 6: build summary CSV ---------------------------------------------

worms_single_record_status <- c("exact", "exact_unaccepted", "fuzzy")

gbif_chr <- function(rec, field) {
  if (is.null(rec) || !field %in% names(rec)) return(NA_character_)
  val <- rec[[field]]
  if (length(val) == 0 || is.na(val)) return(NA_character_)
  as.character(val)
}

extract_habitat <- function(rec) {
  flags <- c(
    marine = isTRUE(rec$isMarine == 1),
    brackish = isTRUE(rec$isBrackish == 1),
    freshwater = isTRUE(rec$isFreshwater == 1),
    terrestrial = isTRUE(rec$isTerrestrial == 1)
  )
  if (!any(flags)) return(NA_character_)
  paste(names(flags)[flags], collapse = "|")
}

build_summary_row <- function(raw_species, entry) {
  worms_status <- entry$worms$status
  gbif_entry <- entry$gbif
  gbif_status <- if (!is.null(gbif_entry)) gbif_entry$status else NA_character_

  if (worms_status %in% worms_single_record_status) {
    rec <- entry$worms$record
    resolved_by <- "worms"
    accepted_name <- if (identical(rec$status, "accepted")) rec$scientificname else rec$valid_name
    rank <- rec$rank
    kingdom <- rec$kingdom
    phylum <- rec$phylum
    class <- rec$class
    order <- rec$order
    family <- rec$family
    genus <- rec$genus
    habitat <- extract_habitat(rec)
  } else if (!is.null(gbif_entry) && gbif_entry$status %in% c("gbif_exact", "gbif_fuzzy")) {
    rec <- gbif_entry$record
    resolved_by <- "gbif"
    accepted_name <- gbif_chr(rec, "canonicalName")
    rank <- gbif_chr(rec, "rank")
    kingdom <- gbif_chr(rec, "kingdom")
    phylum <- gbif_chr(rec, "phylum")
    class <- gbif_chr(rec, "class")
    order <- gbif_chr(rec, "order")
    family <- gbif_chr(rec, "family")
    genus <- gbif_chr(rec, "genus")
    habitat <- NA_character_
  } else {
    resolved_by <- "none"
    accepted_name <- NA_character_
    rank <- NA_character_
    kingdom <- NA_character_
    phylum <- NA_character_
    class <- NA_character_
    order <- NA_character_
    family <- NA_character_
    genus <- NA_character_
    habitat <- NA_character_
  }

  tibble(
    raw_species = raw_species,
    worms_status = worms_status,
    gbif_status = gbif_status,
    resolved_by = resolved_by,
    accepted_name = accepted_name,
    rank = rank,
    kingdom = kingdom,
    phylum = phylum,
    class = class,
    order = order,
    family = family,
    genus = genus,
    habitat = habitat
  )
}

summary_details <- map_dfr(species_summary$raw_species, function(nm) build_summary_row(nm, cache[[nm]]))

final_summary <- species_summary |>
  left_join(summary_details, by = "raw_species") |>
  arrange(desc(n_rows))

write_csv(final_summary, summary_path)
cat("Wrote summary CSV:", summary_path, "\n")

# ---- Step 7: diagnostic report ---------------------------------------------

# Mutually exclusive combined status, assigned in the priority order used
# for the resolution-status-overview table (Section 2 of the report).
combined_status <- case_when(
  final_summary$worms_status == "exact" ~ "WoRMS exact",
  final_summary$worms_status == "exact_unaccepted" ~ "WoRMS exact (unaccepted, has synonym)",
  final_summary$worms_status == "fuzzy" ~ "WoRMS fuzzy",
  final_summary$worms_status == "ambiguous" ~ "WoRMS ambiguous",
  final_summary$gbif_status == "gbif_exact" ~ "GBIF exact (WoRMS fallback)",
  final_summary$gbif_status == "gbif_fuzzy" ~ "GBIF fuzzy (WoRMS fallback)",
  final_summary$gbif_status == "gbif_no_match" ~ "Unresolved (both failed)",
  TRUE ~ "API errors"
)
final_summary$combined_status <- combined_status

status_levels <- c(
  "WoRMS exact", "WoRMS exact (unaccepted, has synonym)", "WoRMS fuzzy",
  "WoRMS ambiguous", "GBIF exact (WoRMS fallback)", "GBIF fuzzy (WoRMS fallback)",
  "Unresolved (both failed)", "API errors"
)

status_overview <- final_summary |>
  mutate(combined_status = factor(combined_status, levels = status_levels)) |>
  group_by(combined_status) |>
  summarise(n_species = n(), n_rows = sum(n_rows), .groups = "drop") |>
  arrange(combined_status) |>
  tidyr::complete(combined_status = status_levels, fill = list(n_species = 0, n_rows = 0))

md_table <- function(df) {
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|")
  rows <- apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

lines <- character(0)
add <- function(...) lines <<- c(lines, ...)

add(
  "# Stage 4d Part 1 -- Species Resolution Diagnostic Report",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  ""
)

# --- Section 1: input summary ---
add("## 1. Input summary", "")
add(paste0("- Total final clean rows (`dedup_retained` & `priority_kept`): ", format(n_clean_rows, big.mark = ",")))
add(paste0("- Unique `scientificname` values: ", format(n_unique_species, big.mark = ",")))
add("")

row_bucket <- cut(
  final_summary$n_rows,
  breaks = c(-Inf, 9, 99, 999, Inf),
  labels = c("<10", "10-99", "100-999", ">=1000")
)
bucket_tbl <- final_summary |>
  mutate(row_bucket = row_bucket) |>
  group_by(row_bucket) |>
  summarise(n_species = n(), n_rows = sum(n_rows), .groups = "drop") |>
  arrange(match(row_bucket, c("<10", "10-99", "100-999", ">=1000")))

add("Row-count distribution of species:", "")
add(md_table(bucket_tbl))
add("")

# --- Section 2: resolution status overview ---
add("## 2. Resolution status overview", "")
add(
  "Parenthetical \"(WoRMS fallback)\" / \"(both failed)\" rows include cases",
  "where WoRMS returned no_match OR api_error before GBIF was queried --",
  "GBIF was only ever queried for those two WoRMS outcomes (see script",
  "header). Categories are mutually exclusive and sum to all species.",
  ""
)
add(md_table(status_overview))
add("")

# --- Section 3: taxonomic hierarchy distribution ---
add("## 3. Taxonomic hierarchy distribution", "")
add("Restricted to species with `resolved_by %in% c(\"worms\", \"gbif\")` (a single accepted/candidate record was assigned).", "")

resolved <- final_summary |> filter(resolved_by %in% c("worms", "gbif"))

kingdom_tbl <- resolved |>
  group_by(kingdom) |>
  summarise(n_species = n(), n_rows = sum(n_rows), .groups = "drop") |>
  arrange(desc(n_species))
add("### Kingdoms", "")
add(md_table(kingdom_tbl))
add("")

phylum_tbl <- resolved |>
  group_by(phylum) |>
  summarise(n_species = n(), n_rows = sum(n_rows), .groups = "drop") |>
  arrange(desc(n_species))
add("### Phyla", "")
add(md_table(phylum_tbl))
add("")

class_tbl <- resolved |>
  group_by(class) |>
  summarise(n_species = n(), n_rows = sum(n_rows), .groups = "drop") |>
  arrange(desc(n_rows))

n_class_total <- nrow(class_tbl)
class_top30 <- head(class_tbl, 30)
class_rest <- class_tbl[-seq_len(min(30, n_class_total)), , drop = FALSE]
add("### Classes (top 30 by row count)", "")
add(md_table(class_top30))
if (nrow(class_rest) > 0) {
  add(
    "",
    sprintf(
      "All other classes (%d distinct, %s species, %s rows combined):",
      nrow(class_rest), format(sum(class_rest$n_species), big.mark = ","), format(sum(class_rest$n_rows), big.mark = ",")
    )
  )
}
add("")

# --- Section 4: sample unresolved species (no_match/api_error path only; ambiguous covered in Section 6) ---
add("## 4. Sample unresolved species (top 30 by row count)", "")
add("Excludes `WoRMS ambiguous` (see Section 6).", "")
unresolved <- final_summary |>
  filter(combined_status %in% c("Unresolved (both failed)", "API errors")) |>
  arrange(desc(n_rows)) |>
  select(raw_species, n_rows, sources, example_cas, worms_status, gbif_status) |>
  head(30)
add(md_table(unresolved))
add("")

# --- Section 5: sample fuzzy/unaccepted matches ---
add("## 5. Sample fuzzy / unaccepted matches (top 30 by row count)", "")
fuzzy_matches <- final_summary |>
  filter(
    worms_status %in% c("fuzzy", "exact_unaccepted") |
      (resolved_by == "gbif" & gbif_status == "gbif_fuzzy")
  ) |>
  arrange(desc(n_rows)) |>
  select(raw_species, n_rows, worms_status, gbif_status, accepted_name) |>
  head(30)
add(md_table(fuzzy_matches))
add("")

# --- Section 6: sample ambiguous matches ---
add("## 6. Ambiguous matches (WoRMS returned multiple records)", "")
ambiguous_summary <- final_summary |>
  filter(worms_status == "ambiguous") |>
  arrange(desc(n_rows))

ambiguous_rows <- map_dfr(ambiguous_summary$raw_species, function(nm) {
  rec <- cache[[nm]]$worms$record
  n_records <- nrow(rec)
  # Distinct *valid* names the candidate set resolves to once unaccepted
  # synonyms/subspecies are traced to their accepted parent -- this can be 1
  # even when n_records > 1 (e.g. an accepted species plus its own
  # unaccepted subspecies), which is a false-alarm ambiguity, vs n_records >
  # n_unique_names > 1, which is genuine taxonomic ambiguity.
  names_vec <- unique(ifelse(rec$status == "accepted", rec$scientificname, rec$valid_name))
  n_unique_names <- length(names_vec)
  shown <- names_vec[seq_len(min(10, n_unique_names))]
  suffix <- if (n_unique_names > 10) sprintf(" (+%d more)", n_unique_names - 10) else ""
  tibble(
    raw_species = nm,
    n_rows = ambiguous_summary$n_rows[ambiguous_summary$raw_species == nm],
    n_records = n_records,
    n_unique_names = n_unique_names,
    candidate_accepted_names = paste0(paste(shown, collapse = "; "), suffix)
  )
})
add(md_table(ambiguous_rows))
add("")

# --- Section 7: API error summary ---
add("## 7. API error summary", "")
api_error_species <- final_summary |>
  filter(worms_status == "api_error" | gbif_status == "gbif_api_error") |>
  arrange(desc(n_rows))

if (nrow(api_error_species) == 0) {
  add("No API errors encountered.", "")
} else {
  transient_pattern <- "timeout|Timeout|Could not resolve host|Recv failure|Connection|connection|reset by peer|SSL"
  error_rows <- map_dfr(api_error_species$raw_species, function(nm) {
    entry <- cache[[nm]]
    worms_err <- entry$worms$error
    gbif_err <- if (!is.null(entry$gbif)) entry$gbif$error else NA_character_
    err_msg <- worms_err %||% gbif_err %||% NA_character_
    nature <- if (!is.na(err_msg) && grepl(transient_pattern, err_msg)) "transient (network)" else "persistent"
    tibble(
      raw_species = nm,
      n_rows = api_error_species$n_rows[api_error_species$raw_species == nm],
      error_message = err_msg,
      likely_nature = nature
    )
  })
  add(md_table(error_rows))
  add("")
}

# --- Section 8: habitat coverage check ---
add("## 8. Habitat coverage check", "")
add("Restricted to `resolved_by == \"worms\"` -- GBIF does not provide habitat flags.", "")
worms_resolved <- final_summary |> filter(resolved_by == "worms")
habitat_freshwater <- sum(grepl("freshwater", worms_resolved$habitat))
habitat_marine_only <- sum(grepl("marine", worms_resolved$habitat) & !grepl("freshwater", worms_resolved$habitat))
habitat_marine_and_freshwater <- sum(grepl("marine", worms_resolved$habitat) & grepl("freshwater", worms_resolved$habitat))
habitat_none <- sum(is.na(worms_resolved$habitat))
add(sprintf("- WoRMS-resolved species: %d", nrow(worms_resolved)))
add(sprintf("- With a freshwater habitat flag: %d", habitat_freshwater))
add(sprintf("- Marine only (no freshwater flag): %d", habitat_marine_only))
add(sprintf("- Marine + freshwater (both flags): %d", habitat_marine_and_freshwater))
add(sprintf("- No habitat data (no flags set): %d", habitat_none))
add("")

# --- Section 9: recommendations for Part 2 ---
add("## 9. Recommendations for Part 2", "")

# Matches Section 4's definition of "unresolved" (excludes WoRMS ambiguous,
# which is covered by its own recommendation below) -- resolved_by == "none"
# alone would also catch the 1,079 ambiguous species and inflate this count.
unresolved_all <- final_summary |> filter(combined_status %in% c("Unresolved (both failed)", "API errors"))
n_unresolved_species <- nrow(unresolved_all)
n_unresolved_rows <- sum(unresolved_all$n_rows)

# Heuristic: does a case/whitespace-insensitive match of an unresolved name
# exist among names that DID resolve? If so, normalisation could rescue it.
resolved_names_norm <- tolower(trimws(gsub("\\s+", " ", final_summary$raw_species[final_summary$resolved_by != "none"])))
unresolved_norm <- tolower(trimws(gsub("\\s+", " ", unresolved_all$raw_species)))
n_rescuable_by_norm <- sum(unresolved_norm %in% resolved_names_norm & unresolved_norm != tolower(unresolved_all$raw_species))

add(sprintf(
  "- **Normalisation:** of %d unresolved species, %d have a case/whitespace-only variant that already resolved under a different casing/spacing. %s",
  n_unresolved_species, n_rescuable_by_norm,
  if (n_unresolved_species > 0 && n_rescuable_by_norm / n_unresolved_species > 0.1) {
    "This is a large enough fraction to justify a case/whitespace normalisation pass before re-resolving in Part 2."
  } else {
    "This is a small fraction -- normalisation alone is unlikely to meaningfully reduce the unresolved set; most failures look like genuine non-matches (placeholders, strain IDs, subfamily/family-level names) rather than casing issues."
  }
))

add(sprintf(
  "- **Manual review feasibility:** %d unresolved species account for %s rows (%.2f%% of the %s final clean rows). %s",
  n_unresolved_species, format(n_unresolved_rows, big.mark = ","),
  100 * n_unresolved_rows / n_clean_rows, format(n_clean_rows, big.mark = ","),
  if (n_unresolved_species <= 100) {
    "An absolute count this small is feasible for a manual review queue in Part 2."
  } else if (n_unresolved_species <= 500) {
    "A queue of this size is borderline for full manual review -- consider triaging by row count (review the high-row-count tail individually; hard-exclude or bulk-flag the long low-row-count tail)."
  } else {
    "A queue of this size is not practical for full manual review -- favour hard exclusion of the low-row-count tail combined with normalisation/re-resolution, reserving manual review for the highest-row-count unresolved names only."
  }
))

ambiguous_all <- final_summary |> filter(worms_status == "ambiguous")
n_ambiguous <- nrow(ambiguous_all)
n_ambiguous_false_alarm <- sum(map_dbl(ambiguous_all$raw_species, function(nm) {
  rec <- cache[[nm]]$worms$record
  names_vec <- unique(ifelse(rec$status == "accepted", rec$scientificname, rec$valid_name))
  as.numeric(length(names_vec) == 1)
}))
add(sprintf(
  "- **Ambiguous matches (%d species):** %d of these (see Section 6's `n_unique_names` column) have multiple raw WoRMS records that all trace back to a single accepted name (an accepted species plus its own unaccepted subspecies, picked up by `fuzzy = TRUE` matching on the shared binomial prefix) -- these are false-alarm ambiguity, not genuine taxonomic uncertainty. The remaining %d have more than one distinct candidate name and need real human judgement. Part 2 should re-classify the former as resolved (using the single unique name) and only carry the latter into manual review.",
  n_ambiguous, n_ambiguous_false_alarm, n_ambiguous - n_ambiguous_false_alarm
))

class_na_rows <- sum(resolved$n_rows[is.na(resolved$class)])
class_na_frac <- if (nrow(resolved) > 0) class_na_rows / sum(resolved$n_rows) else NA
add(sprintf(
  "- **Majorgroup derivation level:** %d distinct classes observed across resolved species (top 30 shown in Section 3), covering %.2f%% of resolved rows with a non-NA class. %s",
  n_class_total, 100 * (1 - class_na_frac),
  if (n_class_total <= 30 && class_na_frac < 0.1) {
    "Class-level looks suitable for majorgroup derivation -- the distinct-class count is small enough for a controlled lookup and coverage of resolved rows is high."
  } else {
    "Class-level coverage or cardinality is less clean than hoped -- consider falling back to phylum for unmappable classes, or reviewing whether order-level mapping is needed for specific taxa."
  }
))

add("")

writeLines(lines, report_path)
cat("Wrote report:", report_path, "\n")
