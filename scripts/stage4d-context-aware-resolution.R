# =============================================================================
# scripts/stage4d-context-aware-resolution.R
# =============================================================================
# Purpose:
#   Stage 4d Part 2 -- context-aware WoRMS resolution. For each of the 4,348
#   distinct species in the final clean subset, pools each species' own
#   source-native taxonomy (Decision P3) and uses it as a filter to
#   disambiguate WoRMS candidate sets that Part 1's bare-name query left
#   ambiguous or unresolved. Outputs an authoritative per-species
#   accepted_name + hierarchy table and a synonym audit table identifying
#   which raw species names must be unified before Stage 4d Part 3
#   (majorgroup derivation) and Stage 4e (aggregation).
#
#   Does NOT derive majorgroup and does NOT modify uncurated_raw_dedup.csv --
#   both are Part 3. Does NOT modify species_resolution_cache.rds (Part 1) or
#   species_source_taxonomy.csv (Part 1.5) -- both are read-only inputs here.
#
# Inputs (all read-only):
#   data-raw/alldata/species_source_taxonomy.csv   (Part 1.5, 6,198 rows)
#   data-raw/alldata/species_resolution_summary.csv (Part 1, 4,348 rows)
#   data-raw/alldata/species_resolution_cache.rds   (Part 1 raw WoRMS/GBIF
#     responses, keyed by raw species string)
#
# Outputs:
#   data-raw/alldata/species_resolution_v2.csv
#   data-raw/alldata/species_synonym_audit.csv
#   data-raw/alldata/species_kingdom_phylum_disagreements.csv
#   data-raw/alldata/stage4d-part2-report.md
#   data-raw/alldata/species_resolution_v2_cache.rds (this script's OWN
#     resolver cache -- new genus-level WoRMS queries and any new GBIF/bare
#     fallback queries. Kept separate from species_resolution_cache.rds so
#     the Part 1 baseline is preserved untouched.)
#
# Decisions implemented:
#
#   P3 (taxonomy pooling): for each species, the source with the most
#   non-NA fields among {kingdom, phylum, class, order_taxon, family, genus}
#   supplies ALL SIX fields (never mixed across sources for one species).
#   Ties broken wqbench > envirotox > anztox (source population order from
#   stage4d-taxonomy-inventory.md Section 2).
#
#   R1 ("Genus sp." handling, UNCURATED pipeline only): placeholder entries
#   matching a "Genus sp./spp./species" pattern are resolved at GENUS level
#   (kingdom/phylum/class/order/family populated from the genus's own WoRMS
#   record) while the species-level row's accepted_name is left as the
#   original placeholder string -- it is NOT promoted to genus rank, and it
#   is NOT dropped. CAVEAT: this R1 treatment applies ONLY to the uncurated
#   pipeline (anztox/wqbench/envirotox, handled in this Stage 4d branch).
#   "Genus sp." entries from CURATED sources (aims/csiro/ccme/anzg, handled
#   in Stage 6/7) must be retained as distinct species per the curators' own
#   domain judgement -- this decision must NOT be generalised to those
#   sources. See CLAUDE.md note (added alongside this script).
#
#   C (tiered fallback filter): the query itself is always a single bare
#   WoRMS name query (worrms has no server-side class/phylum/genus filter
#   parameter) -- filtering by source-native context happens CLIENT-SIDE on
#   the returned candidate set. The filter level cascades class -> phylum ->
#   genus -> none (unfiltered), stopping at the first level that narrows the
#   candidate set to exactly one record. If every level (down to "none", the
#   original unfiltered query) still leaves >1 candidate, the species is
#   "ambiguous_after_filter". If the original unfiltered query returned zero
#   records, the species is "no_match_after_filter" and falls through to a
#   GBIF lookup (Decision/Step 4e).
#
#   ADDED (found during validation, not in the original Part 2 spec) --
#   exact-name priority pre-filter: `fuzzy = TRUE` (kept from Part 1 so
#   spelling variants remain visible as candidates) causes WoRMS to return
#   subspecies/related-species records that share a name PREFIX with the
#   query but are not the same taxon (e.g. querying "Oncorhynchus mykiss"
#   also returns the unaccepted "Oncorhynchus mykiss aguabonita", whose
#   valid_name is the wholly different species "Oncorhynchus aguabonita").
#   No class/phylum/genus filter can separate these -- they share identical
#   higher taxonomy by construction. But if EXACTLY ONE candidate's
#   `scientificname` matches the query string verbatim, that is decisive on
#   its own, independent of taxonomic context. Checked against Part 1's
#   1,079 ambiguous species: 951 (88%) have exactly one verbatim exact-name
#   record buried in their candidate set. This check runs BEFORE the
#   class/phylum/genus cascade (it is strictly higher-confidence) and is
#   recorded as `filter_level_used = "exact_name_priority"` in the output so
#   it is distinguishable from genuine taxonomic-context disambiguation.
#
# ENGINEERING DECISION -- cache reuse instead of re-querying WoRMS:
#   Part 1's cache (species_resolution_cache.rds) already stores, for every
#   species, the FULL raw record set returned by the exact same bare query
#   this script would otherwise re-issue (fuzzy = TRUE, marine_only = FALSE):
#     - status "ambiguous"        -> the full multi-row candidate set
#     - status "exact"/"fuzzy"/"exact_unaccepted" -> the one-row result
#       (by construction this only happens when the original query already
#       returned exactly one row, so no data was discarded)
#     - status "no_match"         -> zero rows (nothing to lose)
#     - status "api_error"        -> the original query genuinely failed
#   Re-issuing the identical bare-name HTTP request for all 4,348 species
#   would take ~15 more minutes against the live WoRMS API for data already
#   sitting on disk and would not change the result by definition (same
#   query, same API, run one day apart). This script therefore reads Part
#   1's cache as the source of "the bare query result" and only issues NEW
#   WoRMS queries for genus-only lookups (Decision R1/Step 4d, a different
#   query string not present in Part 1) and NEW GBIF queries when a name's
#   GBIF fallback was not already captured by Part 1 (should be rare to
#   nonexistent -- Part 1 GBIF-queried every WoRMS no_match/api_error case,
#   which is a superset of what Step 4e needs here, since a species that
#   was WoRMS-ambiguous in Part 1 can only become "ambiguous_after_filter"
#   here, never "no_match_after_filter": filtering an N>1 set can shrink it
#   but the unfiltered cascade fallback ("none" level) always reproduces the
#   original N>1, never 0). A defensive fresh-bare-query fallback path exists
#   for the (expected: zero) case of a species present in this script's
#   working table but absent from Part 1's cache.
#
# Resumability:
#   species_resolution_v2_cache.rds is checkpointed every 100 NEW network
#   queries (genus / fallback-bare / fallback-gbif) and saved again at the
#   end. Re-running this script reuses both Part 1's cache (untouched) and
#   this script's own cache, so an interrupted run will not repeat already-
#   completed network queries.
#
# Runs from WSL or Windows Positron. No DB connection required.
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

taxonomy_path <- "data-raw/alldata/species_source_taxonomy.csv"
resolution_summary_path <- "data-raw/alldata/species_resolution_summary.csv"
part1_cache_path <- "data-raw/alldata/species_resolution_cache.rds"

v2_csv_path <- "data-raw/alldata/species_resolution_v2.csv"
synonym_audit_path <- "data-raw/alldata/species_synonym_audit.csv"
disagreements_path <- "data-raw/alldata/species_kingdom_phylum_disagreements.csv"
report_path <- "data-raw/alldata/stage4d-part2-report.md"
v2_cache_path <- "data-raw/alldata/species_resolution_v2_cache.rds"

# =============================================================================
# Step 2: load inputs and pool source-native taxonomy (Decision P3)
# =============================================================================

species_source_taxonomy <- read_csv(taxonomy_path, show_col_types = FALSE)
resolution_summary <- read_csv(resolution_summary_path, show_col_types = FALSE)
part1_cache <- readRDS(part1_cache_path)

cat("Loaded species_source_taxonomy.csv:", nrow(species_source_taxonomy), "rows\n")
cat("Loaded species_resolution_summary.csv:", nrow(resolution_summary), "rows\n")
cat("Loaded Part 1 cache:", length(part1_cache), "entries\n")

rank_fields <- c("kingdom", "phylum", "class", "order_taxon", "family", "genus")
source_priority <- c(wqbench = 1L, envirotox = 2L, anztox = 3L)

species_taxonomy_scored <- species_source_taxonomy |>
  rowwise() |>
  mutate(n_nonNA = sum(!is.na(c_across(all_of(rank_fields))))) |>
  ungroup() |>
  mutate(source_rank = unname(source_priority[source]))

pooled <- species_taxonomy_scored |>
  group_by(scientificname) |>
  slice_max(order_by = n_nonNA, n = 1, with_ties = TRUE) |>
  slice_min(order_by = source_rank, n = 1, with_ties = FALSE) |>
  ungroup() |>
  rename(taxonomy_source = source) |>
  select(scientificname, taxonomy_source, all_of(rank_fields))

sources_per_species <- species_source_taxonomy |>
  group_by(scientificname) |>
  summarise(sources = paste(sort(unique(source)), collapse = ","), .groups = "drop")

n_rows_per_species <- resolution_summary |>
  select(scientificname = raw_species, n_rows)

pooled <- pooled |>
  left_join(sources_per_species, by = "scientificname") |>
  left_join(n_rows_per_species, by = "scientificname")

n_species <- nrow(pooled)
cat("Pooled working table rows:", n_species, "\n")
if (any(is.na(pooled$n_rows))) {
  warning(sum(is.na(pooled$n_rows)), " pooled species have no matching n_rows from species_resolution_summary.csv -- scope mismatch with Part 1.")
}

cat("\nPooling decisions (taxonomy_source distribution):\n")
print(count(pooled, taxonomy_source, name = "n_species"))

cat("\nNon-NA counts per pooled field:\n")
print(pooled |> select(all_of(rank_fields)) |> summarise(across(everything(), \(x) sum(!is.na(x)))))

# =============================================================================
# Step 3: identify "Genus sp." placeholders and non-binomial entries
# =============================================================================

pooled <- pooled |>
  mutate(
    is_genus_placeholder = grepl("(^| )(sp\\.?|spp\\.?|species)( |$)", scientificname, ignore.case = TRUE),
    .n_words = lengths(strsplit(trimws(scientificname), "\\s+")),
    is_non_binomial = !is_genus_placeholder & (
      .n_words != 2 |
        grepl("strain", scientificname, ignore.case = TRUE) |
        grepl("-", scientificname) |
        grepl("(^| )x( |$)", scientificname, ignore.case = TRUE)
    ),
    parsed_genus = vapply(strsplit(trimws(scientificname), "\\s+"), `[`, character(1), 1),
    plausible_genus_pattern = grepl("^[A-Z][a-z]+$", parsed_genus)
  ) |>
  select(-.n_words)

n_placeholders <- sum(pooled$is_genus_placeholder)
n_non_binomial <- sum(pooled$is_non_binomial)
cat(sprintf("\n'Genus sp.' placeholders: %d\n", n_placeholders))
cat(sprintf("Non-binomial (excl. placeholders): %d\n", n_non_binomial))
cat("\nSample placeholders:\n")
print(head(pooled$scientificname[pooled$is_genus_placeholder], 20))
cat("\nSample non-binomial:\n")
print(head(pooled$scientificname[pooled$is_non_binomial], 20))

# =============================================================================
# Shared helpers
# =============================================================================

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

# Generic retry wrapper. WoRMS returns HTTP 204/404 (not an error condition in
# substance) for zero-result searches -- both are classified as a clean "no
# records", not an api_error, matching Part 1's convention. Genuine errors
# (network, 5xx) are retried once before giving up.
query_with_retry <- function(fn, max_attempts = 2, pause_between = 1) {
  attempt <- 1
  repeat {
    result <- tryCatch(fn(), error = function(e) e)
    if (!inherits(result, "error")) return(list(value = result, error = NULL))
    if (grepl("204|404", conditionMessage(result))) return(list(value = NULL, error = NULL))
    if (attempt >= max_attempts) return(list(value = NULL, error = conditionMessage(result)))
    attempt <- attempt + 1
    Sys.sleep(pause_between)
  }
}

query_bare_worms <- function(name) {
  res <- query_with_retry(function() worrms::wm_records_name(name, fuzzy = TRUE, marine_only = FALSE))
  list(records = res$value, error = res$error)
}

query_genus <- function(genus_name) {
  res <- query_with_retry(function() worrms::wm_records_name(genus_name, fuzzy = TRUE, marine_only = FALSE))
  list(records = res$value, error = res$error)
}

query_gbif_name <- function(name) {
  res <- query_with_retry(function() rgbif::name_backbone(name = name, verbose = FALSE))
  if (!is.null(res$error)) return(list(status = "gbif_api_error", record = NULL, error = res$error))
  rec_all <- res$value
  if (is.null(rec_all) || nrow(rec_all) == 0) return(list(status = "gbif_no_match", record = NULL, error = NULL))
  rec1 <- rec_all[1, ]
  status <- classify_gbif_match_type(rec1$matchType)
  if (status == "gbif_no_match") rec1 <- NULL
  list(status = status, record = rec1, error = NULL)
}

# Filters a WoRMS candidate record set to rows whose `field` matches `value`
# case-/whitespace-insensitively. Records with NA in `field` never match
# (we can't confirm agreement against missing data).
filter_records <- function(records, field, value) {
  vals <- tolower(trimws(as.character(records[[field]])))
  target <- tolower(trimws(value))
  records[!is.na(vals) & vals == target, , drop = FALSE]
}

# Exact-name priority pre-filter (see header decision note). Only fires when
# precisely one candidate's name verbatim-matches the query -- if 0 or >1
# such records exist, returns NULL and the caller falls through to the
# class/phylum/genus cascade.
resolve_exact_name_priority <- function(name, full_records) {
  if (is.null(full_records) || nrow(full_records) <= 1) return(NULL)
  exact_idx <- which(trimws(as.character(full_records$scientificname)) == trimws(name))
  if (length(exact_idx) == 1) return(full_records[exact_idx, , drop = FALSE])
  NULL
}

# Cascades class -> phylum -> genus -> none (the unfiltered original query),
# starting at the most specific level available per Decision C / Step 4a,
# stopping at the first level that narrows to exactly one candidate. "none"
# is always the final rung, so the cascade is guaranteed to terminate -- at
# that point it reproduces the unfiltered query's own record count, which is
# what distinguishes a genuine no_match (0) from genuine ambiguity (>1).
cascade_resolve <- function(full_records, row) {
  full_order <- c("class", "phylum", "genus", "none")
  start_level <- if (!is.na(row$class)) {
    "class"
  } else if (!is.na(row$phylum)) {
    "phylum"
  } else if (!is.na(row$genus) || isTRUE(row$plausible_genus_pattern)) {
    "genus"
  } else {
    "none"
  }
  cascade_levels <- full_order[match(start_level, full_order):length(full_order)]

  for (level in cascade_levels) {
    if (level == "none") {
      candidates <- full_records
    } else {
      field_val <- if (level == "genus") {
        if (!is.na(row$genus)) row$genus else row$parsed_genus
      } else {
        row[[level]]
      }
      candidates <- if (is.null(full_records) || nrow(full_records) == 0 || is.na(field_val)) {
        full_records
      } else {
        filter_records(full_records, level, field_val)
      }
    }
    if (!is.null(candidates) && nrow(candidates) == 1) {
      return(list(resolved = TRUE, level = level, record = candidates[1, ]))
    }
  }

  n_final <- if (is.null(full_records)) 0L else nrow(full_records)
  list(
    resolved = FALSE, level = "none",
    terminal = if (n_final == 0) "no_match_after_filter" else "ambiguous_after_filter"
  )
}

make_outcome <- function(status, filter_level_used = "none", rank_resolved = NA_character_,
                          accepted_name = NA_character_, aphia_id = NA_integer_, gbif_key = NA_character_,
                          resolved_kingdom = NA_character_, resolved_phylum = NA_character_,
                          resolved_class = NA_character_, resolved_order = NA_character_,
                          resolved_family = NA_character_, resolved_genus = NA_character_,
                          habitat = NA_character_) {
  list(
    status = status, filter_level_used = filter_level_used, rank_resolved = rank_resolved,
    accepted_name = accepted_name, aphia_id = as.integer(aphia_id), gbif_key = as.character(gbif_key),
    resolved_kingdom = resolved_kingdom, resolved_phylum = resolved_phylum, resolved_class = resolved_class,
    resolved_order = resolved_order, resolved_family = resolved_family, resolved_genus = resolved_genus,
    habitat = habitat
  )
}

outcome_from_worms_record <- function(name, rec, filter_level_used) {
  is_exact_name <- identical(trimws(as.character(rec$scientificname)), trimws(name))
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
  make_outcome(
    status = status, filter_level_used = filter_level_used, rank_resolved = rec$rank,
    accepted_name = accepted_name, aphia_id = rec$AphiaID,
    resolved_kingdom = rec$kingdom, resolved_phylum = rec$phylum, resolved_class = rec$class,
    resolved_order = rec$order, resolved_family = rec$family, resolved_genus = rec$genus,
    habitat = extract_habitat(rec)
  )
}

# GBIF's backbone match can return a record missing entire columns (not just
# NA values) when the match is very coarse -- e.g. a KINGDOM-rank "fuzzy"
# match has no phylum/class/order/family/genus columns at all, since those
# ranks don't apply. Direct `rec$field` access then returns NULL, which
# breaks downstream is.na() checks. Mirrors Part 1's own `gbif_chr()` helper
# (stage4d-species-resolution-diagnostic.R), reapplied here because Part 2
# builds its own GBIF outcome rows independently of Part 1's summary CSV.
gbif_chr <- function(rec, field) {
  if (is.null(rec) || !field %in% names(rec)) return(NA_character_)
  val <- rec[[field]]
  if (length(val) == 0 || is.na(val)) return(NA_character_)
  as.character(val)
}

# A GBIF "fuzzy"/HIGHERRANK match at KINGDOM/PHYLUM/CLASS/ORDER/FAMILY rank
# (e.g. "Chauliodes sp" backbone-matching only as far as "Animalia") is not a
# meaningful species-level resolution -- found during the full run, where
# Part 1 had already accepted such a match as "resolved_by == gbif" for 62
# species dataset-wide. Only genus-level-or-finer GBIF matches are accepted
# here; coarser ones fall through to "unresolved" instead.
is_meaningful_gbif_rank <- function(rec) {
  rank_val <- gbif_chr(rec, "rank")
  !is.na(rank_val) && toupper(rank_val) %in% c("GENUS", "SPECIES", "SUBSPECIES", "VARIETY", "FORM")
}

outcome_from_gbif <- function(rec) {
  make_outcome(
    status = "gbif_resolved", filter_level_used = "none", rank_resolved = gbif_chr(rec, "rank"),
    accepted_name = gbif_chr(rec, "canonicalName"), gbif_key = gbif_chr(rec, "usageKey"),
    resolved_kingdom = gbif_chr(rec, "kingdom"), resolved_phylum = gbif_chr(rec, "phylum"),
    resolved_class = gbif_chr(rec, "class"), resolved_order = gbif_chr(rec, "order"),
    resolved_family = gbif_chr(rec, "family"), resolved_genus = gbif_chr(rec, "genus"),
    habitat = NA_character_
  )
}

# =============================================================================
# Step 4: context-aware WoRMS query + GBIF fallback
# =============================================================================

if (file.exists(v2_cache_path)) {
  v2_cache <- readRDS(v2_cache_path)
  cat(sprintf(
    "\nLoaded existing v2 cache: %d genus, %d fallback-bare, %d fallback-gbif entries.\n",
    length(v2_cache$genus_queries), length(v2_cache$fallback_bare_queries), length(v2_cache$gbif_queries)
  ))
} else {
  v2_cache <- list(genus_queries = list(), fallback_bare_queries = list(), gbif_queries = list())
  cat("\nNo existing v2 cache found -- starting fresh.\n")
}

new_query_count <- 0L
checkpoint_every <- 100L

save_v2_checkpoint <- function() saveRDS(v2_cache, v2_cache_path)

# Defensive fallback for a species absent from Part 1's cache (expected:
# never happens, since this script's species list is derived from the same
# dedup scope Part 1 used) -- issues a fresh bare query rather than failing.
get_full_records <- function(name) {
  entry <- part1_cache[[name]]
  if (!is.null(entry)) {
    w <- entry$worms
    if (identical(w$status, "api_error")) return(list(records = NULL, error = w$error))
    if (identical(w$status, "no_match")) return(list(records = NULL, error = NULL))
    return(list(records = w$record, error = NULL))
  }
  if (is.null(v2_cache$fallback_bare_queries[[name]])) {
    v2_cache$fallback_bare_queries[[name]] <<- query_bare_worms(name)
    new_query_count <<- new_query_count + 1L
    Sys.sleep(0.2)
    if (new_query_count %% checkpoint_every == 0) save_v2_checkpoint()
  }
  v2_cache$fallback_bare_queries[[name]]
}

outcomes <- vector("list", n_species)
names(outcomes) <- pooled$scientificname

for (i in seq_len(n_species)) {
  name <- pooled$scientificname[i]
  row <- list(
    class = pooled$class[i], phylum = pooled$phylum[i], genus = pooled$genus[i],
    order_taxon = pooled$order_taxon[i], family = pooled$family[i], kingdom = pooled$kingdom[i],
    parsed_genus = pooled$parsed_genus[i], plausible_genus_pattern = pooled$plausible_genus_pattern[i]
  )
  is_placeholder <- pooled$is_genus_placeholder[i]
  resolved_outcome <- NULL

  # ---- Step 4d: "Genus sp." placeholders -- resolve at genus level --------
  if (is_placeholder) {
    genus_name <- if (!is.na(row$genus)) row$genus else row$parsed_genus
    genus_key <- if (!is.na(genus_name) && nzchar(trimws(genus_name))) tolower(trimws(genus_name)) else NA_character_

    if (!is.na(genus_key)) {
      if (is.null(v2_cache$genus_queries[[genus_key]])) {
        v2_cache$genus_queries[[genus_key]] <- query_genus(genus_name)
        new_query_count <- new_query_count + 1L
        Sys.sleep(0.2)
        if (new_query_count %% checkpoint_every == 0) save_v2_checkpoint()
      }
      gq <- v2_cache$genus_queries[[genus_key]]
      recs_genus <- if (!is.null(gq$records) && nrow(gq$records) > 0) {
        gq$records[gq$records$rank == "Genus" & tolower(trimws(gq$records$scientificname)) == genus_key, , drop = FALSE]
      } else {
        NULL
      }
      # Genus names are not always unique across kingdoms (e.g. "Chlorella"
      # is both a Plantae/Chlorophyta alga genus and an unaccepted
      # Animalia/Ctenophora genus in WoRMS) -- caught during validation on
      # "Chlorella sp.". When the bare genus query itself is ambiguous,
      # narrow using the SAME pooled source-native context (phylum -> class
      # -> kingdom, broadest-discriminator-last) before giving up, rather
      # than only ever accepting a trivially-unique bare match.
      if (!is.null(recs_genus) && nrow(recs_genus) > 1) {
        for (ctx_field in c("phylum", "class", "kingdom")) {
          ctx_val <- row[[ctx_field]]
          if (!is.na(ctx_val)) {
            narrowed <- filter_records(recs_genus, ctx_field, ctx_val)
            if (nrow(narrowed) >= 1) recs_genus <- narrowed
          }
          if (nrow(recs_genus) == 1) break
        }
      }
      if (!is.null(recs_genus) && nrow(recs_genus) == 1) {
        rec <- recs_genus[1, ]
        resolved_outcome <- make_outcome(
          status = "genus_resolved", filter_level_used = "genus_only", rank_resolved = "Genus",
          accepted_name = name, aphia_id = rec$AphiaID,
          resolved_kingdom = rec$kingdom, resolved_phylum = rec$phylum, resolved_class = rec$class,
          resolved_order = rec$order, resolved_family = rec$family, resolved_genus = rec$scientificname,
          habitat = extract_habitat(rec)
        )
      }
    }
    # else: no resolvable genus string at all -- fall through to general
    # cascade on the original placeholder name below (almost certain
    # no_match, but handled generically rather than special-cased).
  }

  # ---- General cascade (non-placeholders, and placeholder fallback) -------
  if (is.null(resolved_outcome)) {
    full <- get_full_records(name)
    exact_rec <- resolve_exact_name_priority(name, full$records)

    if (!is.null(exact_rec)) {
      resolved_outcome <- outcome_from_worms_record(name, exact_rec, "exact_name_priority")
    } else {
      cascade <- cascade_resolve(full$records, row)

      if (isTRUE(cascade$resolved)) {
        resolved_outcome <- outcome_from_worms_record(name, cascade$record, cascade$level)
      } else if (identical(cascade$terminal, "ambiguous_after_filter")) {
        resolved_outcome <- make_outcome(status = "ambiguous_after_filter", filter_level_used = "none")
      } else {
        # no_match_after_filter -- GBIF fallback (Step 4e). Reuse Part 1's
        # cached GBIF result where available (see header decision note).
        part1_entry <- part1_cache[[name]]
        if (!is.null(part1_entry) && !is.null(part1_entry$gbif)) {
          gbif_entry <- part1_entry$gbif
        } else {
          if (is.null(v2_cache$gbif_queries[[name]])) {
            v2_cache$gbif_queries[[name]] <- query_gbif_name(name)
            new_query_count <- new_query_count + 1L
            Sys.sleep(0.1)
            if (new_query_count %% checkpoint_every == 0) save_v2_checkpoint()
          }
          gbif_entry <- v2_cache$gbif_queries[[name]]
        }

        if (!is.null(gbif_entry) && gbif_entry$status %in% c("gbif_exact", "gbif_fuzzy") &&
          !is.null(gbif_entry$record) && is_meaningful_gbif_rank(gbif_entry$record)) {
          resolved_outcome <- outcome_from_gbif(gbif_entry$record)
        } else if (!is.null(full$error) || (!is.null(gbif_entry) && identical(gbif_entry$status, "gbif_api_error"))) {
          resolved_outcome <- make_outcome(status = "api_error", filter_level_used = "none")
        } else {
          resolved_outcome <- make_outcome(status = "unresolved", filter_level_used = "none")
        }
      }
    }
  }

  outcomes[[name]] <- resolved_outcome

  if (i %% 500 == 0) cat(sprintf("Processed %d / %d species (%d new queries so far)...\n", i, n_species, new_query_count))
}

save_v2_checkpoint()
cat(sprintf("\nResolution complete. %d new network queries issued this run.\n", new_query_count))

# =============================================================================
# Step 5: build species_resolution_v2.csv
# =============================================================================

build_row <- function(i) {
  name <- pooled$scientificname[i]
  oc <- outcomes[[name]]
  src_phylum <- pooled$phylum[i]
  hierarchy_match <- if (is.na(src_phylum) || is.na(oc$resolved_phylum)) {
    NA
  } else {
    identical(tolower(trimws(src_phylum)), tolower(trimws(oc$resolved_phylum)))
  }
  tibble(
    scientificname = name,
    sources = pooled$sources[i],
    n_rows = pooled$n_rows[i],
    is_genus_placeholder = pooled$is_genus_placeholder[i],
    is_non_binomial = pooled$is_non_binomial[i],
    taxonomy_source = pooled$taxonomy_source[i],
    filter_level_used = oc$filter_level_used,
    status = oc$status,
    accepted_name = oc$accepted_name,
    aphia_id = oc$aphia_id,
    gbif_key = oc$gbif_key,
    rank_resolved = oc$rank_resolved,
    resolved_kingdom = oc$resolved_kingdom,
    resolved_phylum = oc$resolved_phylum,
    resolved_class = oc$resolved_class,
    resolved_order = oc$resolved_order,
    resolved_family = oc$resolved_family,
    resolved_genus = oc$resolved_genus,
    habitat = oc$habitat,
    source_taxonomy_kingdom = pooled$kingdom[i],
    source_taxonomy_phylum = pooled$phylum[i],
    source_taxonomy_class = pooled$class[i],
    source_taxonomy_order = pooled$order_taxon[i],
    source_taxonomy_family = pooled$family[i],
    source_taxonomy_genus = pooled$genus[i],
    hierarchy_match = hierarchy_match
  )
}

species_resolution_v2 <- map_dfr(seq_len(n_species), build_row) |>
  arrange(desc(n_rows))

write_csv(species_resolution_v2, v2_csv_path, na = "NA")
cat("\nWrote", nrow(species_resolution_v2), "rows to", v2_csv_path, "\n")

# =============================================================================
# Step 6: build species_synonym_audit.csv
# =============================================================================

synonym_groups <- species_resolution_v2 |>
  filter(!is.na(accepted_name)) |>
  group_by(accepted_name) |>
  mutate(n_raw_names_in_group = n_distinct(scientificname)) |>
  ungroup() |>
  filter(n_raw_names_in_group > 1) |>
  transmute(
    accepted_name, n_raw_names_in_group,
    raw_name = scientificname, sources, n_rows, status, rank_resolved
  ) |>
  arrange(desc(n_raw_names_in_group), accepted_name, desc(n_rows))

n_synonym_groups <- n_distinct(synonym_groups$accepted_name)
n_synonym_rows_affected <- sum(synonym_groups$n_rows)
cat(sprintf("\nSynonym groups (accepted_name with >1 raw name): %d\n", n_synonym_groups))
cat(sprintf("Total rows affected by synonym unification: %d\n", n_synonym_rows_affected))

write_csv(synonym_groups, synonym_audit_path, na = "NA")
cat("Wrote", nrow(synonym_groups), "rows to", synonym_audit_path, "\n")

# =============================================================================
# Step 7: build species_kingdom_phylum_disagreements.csv
# =============================================================================

cross_source_disagree <- species_source_taxonomy |>
  group_by(scientificname) |>
  summarise(
    n_kingdom = n_distinct(kingdom[!is.na(kingdom)]),
    n_phylum = n_distinct(phylum[!is.na(phylum)]),
    .groups = "drop"
  ) |>
  filter(n_kingdom > 1 | n_phylum > 1) |>
  pull(scientificname)

resolved_vs_source_disagree <- species_resolution_v2 |>
  filter(
    (!is.na(source_taxonomy_kingdom) & !is.na(resolved_kingdom) &
      tolower(trimws(source_taxonomy_kingdom)) != tolower(trimws(resolved_kingdom))) |
      (!is.na(source_taxonomy_phylum) & !is.na(resolved_phylum) &
        tolower(trimws(source_taxonomy_phylum)) != tolower(trimws(resolved_phylum)))
  ) |>
  pull(scientificname)

disagreement_species <- union(cross_source_disagree, resolved_vs_source_disagree)

kingdom_phylum_disagreements <- species_resolution_v2 |>
  filter(scientificname %in% disagreement_species) |>
  transmute(
    scientificname, sources, n_rows, status,
    source_kingdom = source_taxonomy_kingdom, source_phylum = source_taxonomy_phylum,
    resolved_kingdom, resolved_phylum, taxonomy_source
  ) |>
  arrange(desc(n_rows))

n_anztox_class_na <- sum(
  kingdom_phylum_disagreements$taxonomy_source == "anztox" &
    is.na(species_resolution_v2$source_taxonomy_class[match(kingdom_phylum_disagreements$scientificname, species_resolution_v2$scientificname)])
)

cat(sprintf(
  "\nKingdom/phylum disagreement species: %d (cross-source: %d, resolved-vs-source: %d, anztox class=NA subset: %d)\n",
  length(disagreement_species), length(cross_source_disagree), length(resolved_vs_source_disagree), n_anztox_class_na
))

write_csv(kingdom_phylum_disagreements, disagreements_path, na = "NA")
cat("Wrote", nrow(kingdom_phylum_disagreements), "rows to", disagreements_path, "\n")

# =============================================================================
# Step 8: diagnostic report
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
  "# Stage 4d Part 2 -- Context-Aware Resolution Report",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  ""
)

# --- Section 1: input summary ---
add("## 1. Input summary", "")
add(paste0("- Pool table size: ", format(n_species, big.mark = ","), " species"))
add("", "Pooling decisions (taxonomy_source distribution):", "")
add(md_table(count(pooled, taxonomy_source, name = "n_species")))
add("")
nonNA_counts <- pooled |> select(all_of(rank_fields)) |> summarise(across(everything(), \(x) sum(!is.na(x))))
add(paste0("Non-NA pooled-field counts (of ", n_species, " species):"), "")
add(md_table(tibble(field = names(nonNA_counts), n_nonNA = unlist(nonNA_counts))))
add("")
add(sprintf("- 'Genus sp.' placeholders: %d", n_placeholders))
add(sprintf("- Non-binomial (excl. placeholders): %d", n_non_binomial))
add("")

# --- Section 2: resolution status overview ---
add("## 2. Resolution status overview", "")
add(
  "`no_match_after_filter` is a transient pre-GBIF state (Step 4e always",
  "resolves it onward to either `gbif_resolved` or `unresolved`/`api_error`)",
  "and is included below for completeness against the spec's status list --",
  "it is never a final value in `species_resolution_v2.csv`.",
  ""
)

v2_status_levels <- c(
  "exact_filtered", "exact_unaccepted_filtered", "fuzzy_filtered",
  "ambiguous_after_filter", "genus_resolved", "gbif_resolved",
  "no_match_after_filter", "unresolved", "api_error"
)
v2_status_overview <- species_resolution_v2 |>
  mutate(status = factor(status, levels = v2_status_levels)) |>
  group_by(status) |>
  summarise(n_species = n(), n_rows = sum(n_rows), .groups = "drop") |>
  tidyr::complete(status = v2_status_levels, fill = list(n_species = 0, n_rows = 0)) |>
  arrange(match(status, v2_status_levels))
add("### Part 2 (this script)", "")
add(md_table(v2_status_overview))
add("")

part1_status_levels <- c(
  "WoRMS exact", "WoRMS exact (unaccepted, has synonym)", "WoRMS fuzzy",
  "WoRMS ambiguous", "GBIF exact (WoRMS fallback)", "GBIF fuzzy (WoRMS fallback)",
  "Unresolved (both failed)", "API errors"
)
part1_status <- resolution_summary |>
  mutate(
    combined_status = case_when(
      worms_status == "exact" ~ "WoRMS exact",
      worms_status == "exact_unaccepted" ~ "WoRMS exact (unaccepted, has synonym)",
      worms_status == "fuzzy" ~ "WoRMS fuzzy",
      worms_status == "ambiguous" ~ "WoRMS ambiguous",
      gbif_status == "gbif_exact" ~ "GBIF exact (WoRMS fallback)",
      gbif_status == "gbif_fuzzy" ~ "GBIF fuzzy (WoRMS fallback)",
      gbif_status == "gbif_no_match" ~ "Unresolved (both failed)",
      TRUE ~ "API errors"
    )
  ) |>
  select(scientificname = raw_species, part1_status = combined_status, n_rows)

part1_status_overview <- part1_status |>
  mutate(part1_status = factor(part1_status, levels = part1_status_levels)) |>
  group_by(part1_status) |>
  summarise(n_species = n(), n_rows = sum(n_rows), .groups = "drop") |>
  tidyr::complete(part1_status = part1_status_levels, fill = list(n_species = 0, n_rows = 0)) |>
  arrange(match(part1_status, part1_status_levels))
add("### Part 1 (for comparison)", "")
add(md_table(part1_status_overview))
add("")

# --- Section 3: synonym summary ---
add("## 3. Synonym summary", "")
n_accepted_name_groups <- n_distinct(species_resolution_v2$accepted_name[!is.na(species_resolution_v2$accepted_name)])
add(sprintf("- Total `accepted_name` groups in the dataset: %d", n_accepted_name_groups))
add(sprintf("- Synonym groups (>1 raw name collapsing to the same accepted_name): %d", n_synonym_groups))
add(sprintf("- Total rows affected by synonym unification: %s", format(n_synonym_rows_affected, big.mark = ",")))
add("", "Top 20 synonym groups by row count:", "")
top_synonyms <- synonym_groups |>
  group_by(accepted_name) |>
  summarise(n_raw_names_in_group = first(n_raw_names_in_group), total_rows = sum(n_rows), .groups = "drop") |>
  arrange(desc(total_rows)) |>
  head(20)
add(md_table(top_synonyms))
add("")

# --- Section 4: hierarchy disagreement summary ---
add("## 4. Hierarchy disagreement summary", "")
add(sprintf("- Total species with a kingdom/phylum-level disagreement: %d", length(disagreement_species)))
add(sprintf("  - Cross-source disagreement (sources disagree among themselves): %d", length(cross_source_disagree)))
add(sprintf("  - Resolved-vs-source-native disagreement: %d", length(resolved_vs_source_disagree)))
add(sprintf("  - Of which anztox-sourced with class = NA (flagged separately, see Section 7 note): %d", n_anztox_class_na))
add("", "Breakdown by which source supplied the pooled taxonomy:", "")
disagree_by_source <- kingdom_phylum_disagreements |> count(taxonomy_source, name = "n_species")
add(md_table(disagree_by_source))
add("", "Sample 20 disagreements:", "")
add(md_table(head(kingdom_phylum_disagreements, 20)))
add("")

# --- Section 5: coverage of Part 1's problematic categories ---
add("## 5. Coverage of Part 1's problematic categories", "")

ambiguous_part1 <- part1_status |> filter(part1_status == "WoRMS ambiguous") |> pull(scientificname)
v2_for_ambiguous <- species_resolution_v2 |> filter(scientificname %in% ambiguous_part1)
add(sprintf("### Part 1's %d ambiguous species", length(ambiguous_part1)), "")
add(md_table(v2_for_ambiguous |> count(status, name = "n_species") |> arrange(desc(n_species))))
add("")

unresolved_part1 <- resolution_summary |> filter(gbif_status == "gbif_no_match") |> pull(raw_species)
v2_for_unresolved <- species_resolution_v2 |> filter(scientificname %in% unresolved_part1)
add(sprintf("### Part 1's %d genuinely unresolved species", length(unresolved_part1)), "")
add(md_table(v2_for_unresolved |> count(status, name = "n_species") |> arrange(desc(n_species))))
add("")

# --- Section 6: genus-placeholder handling ---
add("## 6. Genus-placeholder handling", "")
n_genus_resolved <- sum(species_resolution_v2$status == "genus_resolved")
n_placeholder_total <- sum(species_resolution_v2$is_genus_placeholder)
n_placeholder_other <- n_placeholder_total - n_genus_resolved
add(sprintf("- Placeholders: %d", n_placeholder_total))
add(sprintf("- Resolved at genus level (`genus_resolved`): %d", n_genus_resolved))
add(sprintf("- Placeholders with no resolvable genus (fell through to general cascade): %d", n_placeholder_other))
add("", "Outcome breakdown for placeholders that fell through:", "")
placeholder_fallback_status <- species_resolution_v2 |>
  filter(is_genus_placeholder, status != "genus_resolved") |>
  count(status, name = "n_species") |>
  arrange(desc(n_species))
add(md_table(placeholder_fallback_status))
add("")

# --- Section 7: recommendations for Part 3 ---
add("## 7. Recommendations for Stage 4d Part 3", "")
use_set_statuses <- c("exact_filtered", "exact_unaccepted_filtered", "fuzzy_filtered", "genus_resolved", "gbif_resolved")
n_use <- sum(species_resolution_v2$status %in% use_set_statuses)
n_use_rows <- sum(species_resolution_v2$n_rows[species_resolution_v2$status %in% use_set_statuses])
n_problem <- n_species - n_use
n_problem_rows <- sum(species_resolution_v2$n_rows) - n_use_rows
add(sprintf(
  "- **'Resolved enough to use' threshold:** recommend `status %%in%% c(%s)` as the usable set -- %d species (%s rows, %.2f%% of final clean rows) meet this bar.",
  paste0('"', use_set_statuses, '"', collapse = ", "), n_use, format(n_use_rows, big.mark = ","),
  100 * n_use_rows / sum(species_resolution_v2$n_rows)
))
add(sprintf(
  "- **Remaining problem species:** %d species (%s rows) are `ambiguous_after_filter`, `unresolved`, or `api_error`. %s",
  n_problem, format(n_problem_rows, big.mark = ","),
  if (n_problem <= 200) {
    "Small enough for a manual review queue in Part 3 -- triage by row count, hard-excluding the long low-row-count tail if time-constrained."
  } else {
    "Large enough that full manual review is impractical -- recommend reviewing only the highest-row-count tail individually, with source-native hierarchy (taxonomy_source/source_taxonomy_* columns) used as a partial-information fallback for majorgroup derivation on the rest, or hard exclusion if even partial information is absent."
  }
))
n_class_resolved <- sum(!is.na(species_resolution_v2$resolved_class))
add(sprintf(
  "- **Class-level majorgroup feasibility:** %d of %d species (%.1f%%) have a non-NA `resolved_class`. %s",
  n_class_resolved, n_species, 100 * n_class_resolved / n_species,
  "This is consistent with Part 1's finding that class-level coverage is workable for majorgroup derivation; Part 3 should fall back to resolved_phylum (or source_taxonomy_class for placeholders/ambiguous species with only source-native context) for the remaining gap."
))
add("")

writeLines(lines, report_path)
cat("\nWrote report:", report_path, "\n")
