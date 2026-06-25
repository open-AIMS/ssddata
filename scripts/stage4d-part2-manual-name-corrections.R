# =============================================================================
# scripts/stage4d-part2-manual-name-corrections.R
# =============================================================================
# Purpose:
#   Stage 4d Part 2 fixup -- manual name corrections for 3 of the 15 species
#   left in the `no_taxonomy` residual by
#   stage4d-part2-source-native-fallback.R. A human domain review of that
#   residual identified that 2 of the 3 are anztox data-entry errors (a
#   misspelled genus; a genus/species pair stored reversed and miscapitalised)
#   masking species that DO resolve cleanly once queried under their correct
#   spelling/order. The third is not a data-entry error at all -- it is a
#   real, recognised (if obscure) name absent from both WoRMS and the GBIF
#   backbone at species rank.
#
#   Small standalone fixup, run AFTER stage4d-part2-source-native-fallback.R.
#   Does NOT touch Stage 4d Part 3 (majorgroup derivation, not yet started).
#
# Corrections applied (raw scientificname -> corrected query -> outcome):
#
#   1. "Illybius augustior" -> "Ilybius augustior"
#      Genus misspelled with a doubled "l" (Ilybius, one "l", is the accepted
#      diving-beetle genus). WoRMS has no record at all (Ilybius is a
#      freshwater genus, outside WoRMS's marine-focused coverage -- confirmed
#      204 No Content even after the spelling fix). GBIF's backbone resolves
#      the corrected genus via a VARIANT fuzzy match that *also* corrects a
#      second typo in the species epithet ("augustior" -> "angustior") at
#      SPECIES rank, confidence 95, full Animalia/Arthropoda/Insecta/
#      Coleoptera/Dytiscidae hierarchy. Resolved as `gbif_resolved`.
#
#   2. "Salmoides micropterus" -> "Micropterus salmoides"
#      Genus and species epithet are stored in reversed order and
#      miscapitalised (the species epithet "salmoides" was capitalised and
#      placed first, as if it were the genus). The correctly-ordered binomial
#      "Micropterus salmoides" (largemouth bass) is unambiguous in WoRMS: of
#      3 candidate records, exactly one has a `scientificname` that verbatim-
#      matches the query (the accepted Species-rank record; the other two are
#      unaccepted Subspecies-rank records with longer names) -- the same
#      `exact_name_priority` rule already used throughout Part 2. Resolved as
#      `exact_filtered`.
#
#   3. "Sialis flavilatera" (no spelling correction -- the raw name itself is
#      the query)
#      Confirmed via a multi-source Global Names Verifier check
#      (`taxize::gna_verifier()`) that this is a real, exactly-matched name
#      (editDistance 0) in EOL's bare-name index -- it is NOT a typo of a
#      more common congener (the closest lexical neighbour among all 40 GBIF-
#      backbone Sialis species, "Sialis flavicollis", is a different,
#      separately valid epithet, not an OCR/typo variant). It has no
#      species-level record in WoRMS (204 No Content) or the GBIF backbone
#      (`name_backbone()` only resolves the bare query to kinggom-rank
#      Animalia at HIGHERRANK/92-95% confidence -- a quirk of GBIF's fuzzy
#      matcher on this specific short genus string, reproduced even when
#      querying the bare genus "Sialis" alone with no species epithet at
#      all). The GENUS itself, however, is unambiguous and fully resolvable:
#      `rgbif::name_usage(name = "Sialis", rank = "genus")` returns 64
#      candidate genus-rank records across many checklist datasets; filtering
#      to the canonical GBIF Backbone Taxonomy dataset
#      (datasetKey "d7dddbf4-2cf0-4f39-9b2a-bb099caae36c") with
#      taxonomicStatus == "ACCEPTED" narrows this to exactly one record
#      (usageKey 1730333, Animalia/Arthropoda/Insecta/Megaloptera/Sialidae),
#      cross-confirmed independently via `name_backbone("Sialis lutaria")`
#      (a different, cleanly EXACT-matched congener) returning the identical
#      genusKey.
#
#      Per this project's explicit no-fabrication rule, the SPECIES-level
#      identity is NOT manufactured from this: `status` stays "unresolved"
#      and `accepted_name`/`aphia_id`/`gbif_key`/`rank_resolved` stay NA. Only
#      the genus-level hierarchy fields (kingdom/phylum/class/order/family/
#      genus) are populated, tagged with a NEW, distinct
#      `taxonomy_provenance` value ("manual_genus_fallback") so this is never
#      confused with `source_native_fallback` (which specifically means the
#      hierarchy came from the SAME data source's own DB fields -- not true
#      here; this came from an external GBIF cross-reference to a different,
#      congeneric species).
#
# ORDERING CAVEAT (flagged prominently, not silently worked around):
#   `stage4d-part2-source-native-fallback.R`'s own idempotency check
#   recomputes `taxonomy_provenance` from `status` + whether any
#   `resolved_*` field is non-NA. For "Sialis flavilatera" specifically
#   (status stays "unresolved" but now has a non-NA hierarchy), that
#   recompute would relabel it "source_native_fallback" -- a harmless
#   relabelling (it would NOT touch the hierarchy values themselves, since
#   `apply_source_native_fallback()` never overwrites an already-non-NA
#   `resolved_<field>`), but it WOULD overwrite the more accurate
#   "manual_genus_fallback" label and regenerate the other two output files.
#   Re-run THIS script again afterward if that ever happens. The other two
#   corrected species (status changes away from the problem set entirely)
#   have no such conflict.
#
# Inputs:
#   data-raw/alldata/species_resolution_v2.csv (must already have
#     `taxonomy_provenance` from stage4d-part2-source-native-fallback.R)
#   data-raw/alldata/species_resolution_v2_problem_species.csv (read to carry
#     forward `pre_resolved_*` audit values for unaffected problem species)
#   Live WoRMS and GBIF queries for the 3 corrected names (network required).
#
# Outputs (data-raw/alldata/, all overwritten/regenerated):
#   species_resolution_v2.csv (3 rows updated; 3 new audit columns appended:
#     manual_correction_applied, manual_corrected_query_name,
#     manual_correction_note -- FALSE/NA for all other rows)
#   species_resolution_v2_problem_species.csv (regenerated: the 2 species
#     that left the problem set are dropped; Sialis flavilatera's row is
#     updated in place)
#   stage4d-part2-manual-corrections-report.md (new, short)
#
# Idempotency: if `manual_correction_applied` is already TRUE for all 3 raw
# names with field values matching a fresh live recompute, the script reports
# and exits without writing any output (network calls still happen, since
# the only way to confirm "matches a fresh recompute" is to redo the query --
# 3 species is cheap).
#
# Runs from WSL or Windows Positron. No DB connection required.
# =============================================================================

library(dplyr)
library(readr)

v2_path <- "data-raw/alldata/species_resolution_v2.csv"
problem_species_path <- "data-raw/alldata/species_resolution_v2_problem_species.csv"
report_path <- "data-raw/alldata/stage4d-part2-manual-corrections-report.md"

# guess_max = Inf (not the readr default of 1000): the new audit columns
# this script adds (manual_corrected_query_name, manual_correction_note) are
# NA for all but 3 of 4,348 rows, all past row 1000 -- readr's default
# sample-based type guesser sees an all-NA sample, infers `logical`, and then
# silently NA-s out the real string values it meets later (confirmed by
# re-reading the first run's own output: 6 parsing-mismatch warnings, exactly
# the 3 rows x 2 columns affected). Scanning the whole file avoids this trap.
# Any FUTURE script reading this CSV with default read_csv() settings would
# hit the same trap -- flagged in this script's header and in the report.
species_resolution_v2 <- read_csv(v2_path, show_col_types = FALSE, guess_max = Inf)
if (!"taxonomy_provenance" %in% names(species_resolution_v2)) {
  stop("species_resolution_v2.csv has no taxonomy_provenance column -- run ",
       "scripts/stage4d-part2-source-native-fallback.R first.")
}
old_problem_species <- read_csv(problem_species_path, show_col_types = FALSE, guess_max = Inf)

# =============================================================================
# Manual correction lookup -- human-diagnosed, not algorithmically discovered
# =============================================================================

manual_corrections <- tribble(
  ~raw_scientificname,      ~method,              ~corrected_query_name,
  "Illybius augustior",     "gbif_bare",          "Ilybius augustior",
  "Salmoides micropterus",  "worms_bare",         "Micropterus salmoides",
  "Sialis flavilatera",     "manual_genus_gbif",  "Sialis"
)

missing_raw <- setdiff(manual_corrections$raw_scientificname, species_resolution_v2$scientificname)
if (length(missing_raw) > 0) {
  stop("Raw scientificname(s) not found in species_resolution_v2.csv: ",
       paste(missing_raw, collapse = ", "))
}

# =============================================================================
# Shared helpers (mirrors stage4d-context-aware-resolution.R's conventions --
# duplicated rather than sourced, consistent with this project's existing
# pattern of self-contained per-stage scripts)
# =============================================================================

field_chr <- function(rec, field) {
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

is_meaningful_gbif_rank <- function(rec) {
  rank_val <- field_chr(rec, "rank")
  !is.na(rank_val) && toupper(rank_val) %in% c("GENUS", "SPECIES", "SUBSPECIES", "VARIETY", "FORM")
}

# WoRMS bare-name query classified the same way as Part 2's
# outcome_from_worms_record() + resolve_exact_name_priority(): a single
# candidate is used directly; >1 candidates are resolved only if exactly one
# has a scientificname verbatim-matching the query.
resolve_via_worms_bare <- function(query_name) {
  recs <- tryCatch(
    worrms::wm_records_name(query_name, fuzzy = TRUE, marine_only = FALSE),
    error = function(e) e
  )
  if (inherits(recs, "error")) {
    if (grepl("204|404", conditionMessage(recs))) return(list(outcome = "no_match", record = NULL))
    return(list(outcome = "api_error", record = NULL))
  }
  recs <- as.data.frame(recs)
  if (nrow(recs) == 0) return(list(outcome = "no_match", record = NULL))
  if (nrow(recs) == 1) return(list(outcome = "single", record = recs[1, ], filter_level_used = "none"))
  exact_idx <- which(trimws(as.character(recs$scientificname)) == trimws(query_name))
  if (length(exact_idx) == 1) {
    return(list(outcome = "resolved", record = recs[exact_idx, ], filter_level_used = "exact_name_priority"))
  }
  list(outcome = "ambiguous", record = NULL)
}

worms_outcome_fields <- function(query_name, rec, filter_level_used) {
  is_exact_name <- identical(trimws(as.character(rec$scientificname)), trimws(query_name))
  if (is_exact_name && identical(rec$status, "accepted")) {
    status <- "exact_filtered"
    accepted_name <- rec$scientificname
  } else if (is_exact_name) {
    status <- "exact_unaccepted_filtered"
    accepted_name <- rec$valid_name
  } else {
    status <- "fuzzy_filtered"
    accepted_name <- if (identical(rec$status, "accepted")) rec$scientificname else rec$valid_name
  }
  list(
    status = status, filter_level_used = filter_level_used, rank_resolved = rec$rank,
    accepted_name = accepted_name, aphia_id = as.integer(rec$AphiaID), gbif_key = NA_character_,
    resolved_kingdom = rec$kingdom, resolved_phylum = rec$phylum, resolved_class = rec$class,
    resolved_order = rec$order, resolved_family = rec$family, resolved_genus = rec$genus,
    habitat = extract_habitat(rec), taxonomy_provenance = "worms_full"
  )
}

resolve_via_gbif_bare <- function(query_name) {
  rec <- tryCatch(rgbif::name_backbone(name = query_name, verbose = FALSE), error = function(e) e)
  if (inherits(rec, "error")) return(list(outcome = "api_error", record = NULL))
  rec <- as.data.frame(rec)
  if (nrow(rec) == 0) return(list(outcome = "no_match", record = NULL))
  rec1 <- rec[1, ]
  if (!is_meaningful_gbif_rank(rec1)) return(list(outcome = "not_meaningful", record = rec1))
  list(outcome = "resolved", record = rec1)
}

gbif_outcome_fields <- function(rec) {
  list(
    status = "gbif_resolved", filter_level_used = "none", rank_resolved = field_chr(rec, "rank"),
    accepted_name = field_chr(rec, "canonicalName"), aphia_id = NA_integer_,
    gbif_key = field_chr(rec, "usageKey"),
    resolved_kingdom = field_chr(rec, "kingdom"), resolved_phylum = field_chr(rec, "phylum"),
    resolved_class = field_chr(rec, "class"), resolved_order = field_chr(rec, "order"),
    resolved_family = field_chr(rec, "family"), resolved_genus = field_chr(rec, "genus"),
    habitat = NA_character_, taxonomy_provenance = "gbif_full"
  )
}

# GBIF backbone dataset UUID (stable, documented GBIF constant) -- used to
# pick the single canonical backbone genus record out of the many checklist
# datasets `name_usage()` searches across. Needed because `name_backbone()`'s
# fuzzy matcher fails on the bare genus string "Sialis" (returns a kingdom-
# rank HIGHERRANK match instead, reproduced with and without a kingdom hint
# and with strict = TRUE -- see header note); querying name + rank against
# the full checklist index and filtering to this dataset sidesteps that
# fuzzy-matcher quirk entirely.
GBIF_BACKBONE_DATASET_KEY <- "d7dddbf4-2cf0-4f39-9b2a-bb099caae36c"

resolve_genus_only_gbif <- function(genus_token) {
  d <- tryCatch(rgbif::name_usage(name = genus_token, rank = "genus")$data, error = function(e) e)
  if (inherits(d, "error") || is.null(d) || nrow(d) == 0) return(NULL)
  backbone <- d[d$datasetKey == GBIF_BACKBONE_DATASET_KEY & d$taxonomicStatus == "ACCEPTED", ]
  if (nrow(backbone) != 1) return(NULL)
  backbone[1, ]
}

manual_genus_outcome_fields <- function(rec) {
  list(
    # status is hardcoded "unresolved" (not preserved dynamically from the
    # current row) because this method only ever applies to a species that
    # is ALREADY "unresolved" -- the whole point of this fallback is to keep
    # it that way (no species-level identity fabricated) while still
    # attaching genus-level hierarchy.
    status = "unresolved", filter_level_used = "manual_genus_fallback", rank_resolved = NA_character_,
    accepted_name = NA_character_, aphia_id = NA_integer_, gbif_key = NA_character_,
    resolved_kingdom = field_chr(rec, "kingdom"), resolved_phylum = field_chr(rec, "phylum"),
    resolved_class = field_chr(rec, "class"), resolved_order = field_chr(rec, "order"),
    resolved_family = field_chr(rec, "family"), resolved_genus = field_chr(rec, "genus"),
    habitat = NA_character_, taxonomy_provenance = "manual_genus_fallback"
  )
}

# =============================================================================
# Resolve each correction live
# =============================================================================

resolved_fields <- vector("list", nrow(manual_corrections))
query_notes <- character(nrow(manual_corrections))

for (i in seq_len(nrow(manual_corrections))) {
  raw_name <- manual_corrections$raw_scientificname[i]
  method <- manual_corrections$method[i]
  query_name <- manual_corrections$corrected_query_name[i]
  cat("\n===", raw_name, "-> [", method, "] ->", query_name, "===\n")

  if (method == "worms_bare") {
    res <- resolve_via_worms_bare(query_name)
    if (res$outcome %in% c("single", "resolved")) {
      fields <- worms_outcome_fields(query_name, res$record, res$filter_level_used)
      cat("WoRMS:", fields$status, "accepted_name =", fields$accepted_name,
          "aphia_id =", fields$aphia_id, "habitat =", fields$habitat, "\n")
    } else {
      stop("Expected a clean WoRMS resolution for '", query_name, "', got: ", res$outcome,
           " -- re-check manually before re-running.")
    }
  } else if (method == "gbif_bare") {
    res <- resolve_via_gbif_bare(query_name)
    if (res$outcome == "resolved") {
      fields <- gbif_outcome_fields(res$record)
      cat("GBIF:", fields$status, "accepted_name =", fields$accepted_name,
          "gbif_key =", fields$gbif_key, "rank =", fields$rank_resolved, "\n")
    } else {
      stop("Expected a meaningful-rank GBIF resolution for '", query_name, "', got: ", res$outcome,
           " -- re-check manually before re-running.")
    }
  } else if (method == "manual_genus_gbif") {
    genus_token <- strsplit(query_name, "\\s+")[[1]][1]
    rec <- resolve_genus_only_gbif(genus_token)
    if (is.null(rec)) {
      stop("Expected exactly one GBIF backbone genus record for '", genus_token,
           "' -- re-check manually before re-running.")
    }
    fields <- manual_genus_outcome_fields(rec)
    cat("Manual genus fallback: kingdom =", fields$resolved_kingdom,
        "phylum =", fields$resolved_phylum, "class =", fields$resolved_class,
        "order =", fields$resolved_order, "family =", fields$resolved_family,
        "genus =", fields$resolved_genus, "\n")
    cat("status left as-is (\"unresolved\") -- no species-level identity fabricated.\n")
  } else {
    stop("Unknown method: ", method)
  }

  resolved_fields[[i]] <- fields
  query_notes[i] <- sprintf("queried as \"%s\" via %s", query_name, method)
}

manual_corrections$resolved_fields <- resolved_fields
manual_corrections$query_note <- query_notes

# =============================================================================
# Idempotency check
# =============================================================================

current_rows <- species_resolution_v2 |>
  filter(scientificname %in% manual_corrections$raw_scientificname) |>
  arrange(match(scientificname, manual_corrections$raw_scientificname))

already_applied <- "manual_correction_applied" %in% names(species_resolution_v2) &&
  all(current_rows$manual_correction_applied %in% TRUE)

if (already_applied) {
  fields_match <- vapply(seq_len(nrow(manual_corrections)), function(i) {
    f <- manual_corrections$resolved_fields[[i]]
    row <- current_rows[i, ]
    checks <- c(
      identical(row$status, f$status) || (is.na(row$status) && is.na(f$status)),
      identical(row$taxonomy_provenance, f$taxonomy_provenance),
      identical(row$resolved_kingdom, f$resolved_kingdom) || (is.na(row$resolved_kingdom) && is.na(f$resolved_kingdom)),
      identical(row$resolved_genus, f$resolved_genus) || (is.na(row$resolved_genus) && is.na(f$resolved_genus))
    )
    all(checks)
  }, logical(1))

  if (all(fields_match)) {
    cat("\nAll 3 manual corrections already applied and consistent with a fresh",
        "live recompute -- exiting without modifying any output file.\n")
    quit(save = "no", status = 0)
  }
  cat("\nmanual_correction_applied is set but does not match a fresh recompute --",
      "re-applying and overwriting.\n")
}

# =============================================================================
# Apply corrections to species_resolution_v2.csv
# =============================================================================

if (!"manual_correction_applied" %in% names(species_resolution_v2)) {
  species_resolution_v2$manual_correction_applied <- FALSE
  species_resolution_v2$manual_corrected_query_name <- NA_character_
  species_resolution_v2$manual_correction_note <- NA_character_
}

for (i in seq_len(nrow(manual_corrections))) {
  raw_name <- manual_corrections$raw_scientificname[i]
  f <- manual_corrections$resolved_fields[[i]]
  idx <- which(species_resolution_v2$scientificname == raw_name)

  species_resolution_v2$status[idx] <- f$status
  species_resolution_v2$filter_level_used[idx] <- f$filter_level_used
  species_resolution_v2$rank_resolved[idx] <- f$rank_resolved
  species_resolution_v2$accepted_name[idx] <- f$accepted_name
  species_resolution_v2$aphia_id[idx] <- f$aphia_id
  species_resolution_v2$gbif_key[idx] <- f$gbif_key
  species_resolution_v2$resolved_kingdom[idx] <- f$resolved_kingdom
  species_resolution_v2$resolved_phylum[idx] <- f$resolved_phylum
  species_resolution_v2$resolved_class[idx] <- f$resolved_class
  species_resolution_v2$resolved_order[idx] <- f$resolved_order
  species_resolution_v2$resolved_family[idx] <- f$resolved_family
  species_resolution_v2$resolved_genus[idx] <- f$resolved_genus
  species_resolution_v2$habitat[idx] <- f$habitat
  species_resolution_v2$taxonomy_provenance[idx] <- f$taxonomy_provenance
  species_resolution_v2$manual_correction_applied[idx] <- TRUE
  species_resolution_v2$manual_corrected_query_name[idx] <- manual_corrections$corrected_query_name[i]
  species_resolution_v2$manual_correction_note[idx] <- manual_corrections$query_note[i]
}

write_csv(species_resolution_v2, v2_path, na = "NA")
cat("\nWrote", nrow(species_resolution_v2), "rows to", v2_path, "\n")

# =============================================================================
# Regenerate species_resolution_v2_problem_species.csv
# =============================================================================

problem_statuses <- c("ambiguous_after_filter", "unresolved", "api_error")

new_problem_species <- species_resolution_v2 |>
  filter(status %in% problem_statuses) |>
  select(
    scientificname, sources, n_rows, status, taxonomy_provenance,
    resolved_kingdom, resolved_phylum, resolved_class, resolved_order,
    resolved_family, resolved_genus, starts_with("source_taxonomy_")
  ) |>
  left_join(
    old_problem_species |> select(scientificname, starts_with("pre_resolved_")),
    by = "scientificname"
  ) |>
  select(
    scientificname, sources, n_rows, status, taxonomy_provenance,
    pre_resolved_kingdom, resolved_kingdom,
    pre_resolved_phylum, resolved_phylum,
    pre_resolved_class, resolved_class,
    pre_resolved_order, resolved_order,
    pre_resolved_family, resolved_family,
    pre_resolved_genus, resolved_genus,
    starts_with("source_taxonomy_")
  ) |>
  arrange(status, desc(n_rows))

write_csv(new_problem_species, problem_species_path, na = "NA")
cat("Wrote", nrow(new_problem_species), "rows to", problem_species_path,
    "(", nrow(old_problem_species) - nrow(new_problem_species), "fewer than before)\n")

# =============================================================================
# Short report
# =============================================================================

md_table <- function(df) {
  df <- as.data.frame(df)
  df[] <- lapply(df, function(col) {
    col <- as.character(col)
    col[is.na(col)] <- "NA"
    col
  })
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|")
  rows <- apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |"))
  paste(c(header, sep, rows), collapse = "\n")
}

lines <- character(0)
add <- function(...) lines <<- c(lines, ...)

add(
  "# Stage 4d Part 2 Fixup -- Manual Name Corrections Report",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "Human domain review of the `no_taxonomy` residual (15 species, see",
  "`stage4d-part2-fallback-report.md` Section 3) identified 3 species worth",
  "a manual correction pass: 2 anztox data-entry errors (misspelling; reversed",
  "genus/species order) and 1 genuinely valid-but-backbone-absent name.",
  ""
)

add("## Corrections applied", "")
summary_tbl <- species_resolution_v2 |>
  filter(scientificname %in% manual_corrections$raw_scientificname) |>
  select(scientificname, manual_corrected_query_name, status, taxonomy_provenance,
         accepted_name, resolved_kingdom, resolved_phylum, resolved_class,
         resolved_order, resolved_family, resolved_genus)
add(md_table(summary_tbl))
add("")

add(
  "## Notes",
  "",
  "- `Illybius augustior` and `Salmoides micropterus` are now fully resolved",
  "  (`gbif_resolved` / `exact_filtered`) and have dropped out of the problem-",
  "  species set entirely.",
  "- `Sialis flavilatera` keeps `status = \"unresolved\"` deliberately -- no",
  "  species-level identity (`accepted_name`/`aphia_id`/`gbif_key`/",
  "  `rank_resolved`) was fabricated, per this stage's no-fabrication rule.",
  "  Only genus-level hierarchy was attached, from GBIF's own backbone genus",
  "  record cross-confirmed via two independent queries. Tagged with a NEW",
  "  `taxonomy_provenance` value, `manual_genus_fallback`, kept distinct from",
  "  `source_native_fallback` (which specifically means the hierarchy came",
  "  from the species' OWN data source, not an external cross-genus",
  "  reference).",
  "- **Ordering caveat:** re-running `stage4d-part2-source-native-fallback.R`",
  "  after this script would relabel `Sialis flavilatera`'s",
  "  `taxonomy_provenance` from `manual_genus_fallback` back to",
  "  `source_native_fallback` (its idempotency check does not know about this",
  "  new category) -- harmless to the hierarchy values themselves, but",
  "  re-run this script again afterward to restore the more accurate label.",
  "- **`read_csv()` trap for future readers:** the two new audit columns this",
  "  script adds (`manual_corrected_query_name`, `manual_correction_note`) are",
  "  NA for all but 3 of 4,348 rows, and those 3 rows fall past row 1000.",
  "  `readr::read_csv()`'s default type-guesser only samples the first 1000",
  "  rows, sees an all-NA sample for these columns, infers `logical`, and then",
  "  silently turns the real string values it meets later into NA (with a",
  "  parsing-mismatch warning easy to miss). Confirmed and fixed in this",
  "  script's own reads via `guess_max = Inf`. Any future script (Stage 4d",
  "  Part 3 included) that reads `species_resolution_v2.csv` with default",
  "  `read_csv()` settings and then writes it back out would silently destroy",
  "  this audit trail -- use `guess_max = Inf` (or explicit `col_types`) when",
  "  reading this file going forward.",
  ""
)

writeLines(lines, report_path)
cat("\nWrote report to", report_path, "\n")
cat("\nDone.\n")
