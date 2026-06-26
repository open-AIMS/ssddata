# Stage 6 Phase 2: Integration with curated sources, exclusion rules, and integrated output
#
# Pre-conditions:
#   - scripts/stage6-phase1-cas-lookup-draft.R has been run and all unresolved
#     rows in data-raw/alldata/curated_cas_lookup.csv have been manually populated.
#   - data-raw/alldata/uncurated_raw_aggregated.csv exists (Stage 4e output).
#   - data-raw/alldata/species_resolution_v2.csv exists (Stage 4d Part 2 output).
#   - alldata_integrated.csv is in .gitignore (checked in Task 9).
#
# Environment: WSL or Windows Positron (no live DB required)
# Output: data-raw/alldata/alldata_integrated.csv (UNTRACKED — large, do not commit)
#         data-raw/alldata/species_resolution_curated.csv (tracked)
#         data-raw/alldata/stage6-integration-report.md (tracked)

library(dplyr)
library(readr)
library(worrms)

# ============================================================
# Pre-condition check: curated_cas_lookup.csv
# ============================================================

cas_curated_path <- "data-raw/alldata/curated_cas_lookup.csv"
if (!file.exists(cas_curated_path)) {
  stop("ERROR: ", cas_curated_path, " not found. Run Phase 1 first.")
}

curated_cas <- read_csv(cas_curated_path, show_col_types = FALSE)

na_casnumber <- sum(is.na(curated_cas$casnumber_grouped))
na_chemname <- sum(is.na(curated_cas$chemicalname_grouped))

if (na_casnumber > 0 || na_chemname > 0) {
  missing_rows <- curated_cas |>
    filter(is.na(casnumber_grouped) | is.na(chemicalname_grouped))
  cat("ERROR: curated_cas_lookup.csv contains rows with missing values.\n")
  cat("Missing rows (", nrow(missing_rows), "):\n")
  print(missing_rows |> as.data.frame())
  stop(
    na_casnumber, " rows with missing casnumber_grouped; ",
    na_chemname, " rows with missing chemicalname_grouped.\n",
    "Phase 2 cannot proceed until all chemicals have CAS numbers assigned."
  )
}

cat("Pre-condition check PASSED: curated_cas_lookup.csv complete (", nrow(curated_cas),
  "rows, no NA CAS or chemical names).\n\n")

# Compute resolution method counts for use in the audit report
n_master     <- sum(curated_cas$resolution_method == "master_lookup", na.rm = TRUE)
n_webchem    <- sum(curated_cas$resolution_method == "webchem_cir", na.rm = TRUE)
n_manual     <- sum(curated_cas$resolution_method == "manual", na.rm = TRUE)
n_unresolved <- sum(curated_cas$resolution_method == "unresolved", na.rm = TRUE)

# ============================================================
# TASK 1: Load inputs
# ============================================================

cat("====================================================\n")
cat("TASK 1: Load inputs\n")
cat("====================================================\n\n")

# Uncurated aggregated output (Stage 4e)
uncurated_path <- "data-raw/alldata/uncurated_raw_aggregated.csv"
if (!file.exists(uncurated_path)) {
  stop("ERROR: ", uncurated_path, " not found. Check that Stage 4e has been run.")
}
uncurated <- read_csv(uncurated_path, guess_max = Inf, show_col_types = FALSE)
cat("uncurated_raw_aggregated.csv:", nrow(uncurated), "rows,", ncol(uncurated), "cols\n")
if (nrow(uncurated) != 62410) {
  warning(
    "Expected 62,410 rows in uncurated_raw_aggregated.csv but found ", nrow(uncurated),
    ". Continuing with actual count — verify Stage 4e output."
  )
}

# Master CAS lookup (with excluded column from Phase 1)
cas_master_path <- "data-raw/cas_parent_lookup_all.csv"
if (!file.exists(cas_master_path)) {
  stop("ERROR: Master CAS lookup not found at ", cas_master_path)
}
cas_master <- read_csv(cas_master_path, guess_max = Inf, show_col_types = FALSE) |>
  filter(!excluded)
cat("cas_parent_lookup_all.csv (excluded==FALSE):", nrow(cas_master), "rows\n")

# Species resolution cache (Stage 4d Part 2)
sp_res_path <- "data-raw/alldata/species_resolution_v2.csv"
if (!file.exists(sp_res_path)) {
  stop("ERROR: ", sp_res_path, " not found.")
}
species_res_v2 <- read_csv(sp_res_path, guess_max = Inf, show_col_types = FALSE)
cat("species_resolution_v2.csv:", nrow(species_res_v2), "rows\n")

# Curated data objects
library(ssddata)
cat("anzg_data:", nrow(anzg_data), "rows\n")
cat("ccme_data:", nrow(ccme_data), "rows\n")
cat("aims_data:", nrow(aims_data), "rows\n")
cat("csiro_data:", nrow(csiro_data), "rows\n\n")

# ============================================================
# TASK 2: Prepare ANZG and CCME
# ============================================================

cat("====================================================\n")
cat("TASK 2: Prepare ANZG and CCME records\n")
cat("====================================================\n\n")

# ---- ANZG ----

# Construct accepted_name and normalise Medium to Title Case
medium_norm_anzg <- c(
  freshwater = "Freshwater",
  marine = "Marine",
  `soft freshwater` = "Soft freshwater",
  `moderate freshwater` = "Moderate freshwater",
  `hard freshwater` = "Hard freshwater"
)

# Check for unexpected medium values
unexpected_anzg_medium <- unique(anzg_data$Medium)[!unique(anzg_data$Medium) %in% names(medium_norm_anzg)]
if (length(unexpected_anzg_medium) > 0) {
  stop("ERROR: Unexpected ANZG Medium values: ", paste(unexpected_anzg_medium, collapse = ", "))
}

anzg_cas <- curated_cas |> filter(source == "anzg")

# Check all ANZG chemicals are in the CAS lookup
anzg_chems_missing <- setdiff(anzg_data$Chemical, anzg_cas$chemical_name)
if (length(anzg_chems_missing) > 0) {
  stop("ERROR: ANZG chemicals not found in curated_cas_lookup.csv: ",
    paste(anzg_chems_missing, collapse = ", "))
}

anzg_prepped <- anzg_data |>
  mutate(
    accepted_name = paste(Genus, Species),
    medium = medium_norm_anzg[Medium]
  ) |>
  left_join(anzg_cas |> select(chemical_name, casnumber_grouped, chemicalname_grouped),
    by = c("Chemical" = "chemical_name")) |>
  mutate(
    source = "anzg",
    conc_ug_L = Conc,
    majorgroup = NA_character_,
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
    any_conc_flagged = FALSE,
    geomean_flagged = FALSE,
    lifestage_mixed = FALSE,
    duration_mixed = FALSE
  )

# Verify no join failures
if (any(is.na(anzg_prepped$casnumber_grouped))) {
  failed <- anzg_prepped |> filter(is.na(casnumber_grouped)) |> distinct(Chemical)
  stop("ERROR: ANZG rows failed CAS join for chemicals: ",
    paste(failed$Chemical, collapse = ", "))
}

cat("ANZG: prepared", nrow(anzg_prepped), "rows\n")

# ---- CCME ----

# Unit conversion
ccme_units_present <- unique(ccme_data$Units)
cat("CCME Units present:", paste(ccme_units_present, collapse = ", "), "\n")
if (any(ccme_data$Medium == "Freshwater")) {
  cat("NOTE [ccme]: Medium = 'Freshwater' in data (CLAUDE.md describes as 'Unknown').\n")
  cat("  The CCME exclusion rule (Task 7) will apply to the actual medium values.\n")
}

ccme_prepped <- ccme_data |>
  mutate(
    conc_ug_L = case_when(
      Units %in% c("ug/L", "µg/L") ~ Conc,
      Units == "mg/L" ~ Conc * 1000,
      Units == "ng/L" ~ Conc / 1000,
      TRUE ~ NA_real_
    )
  )

# Check for unconvertible units
bad_units <- ccme_prepped |> filter(is.na(conc_ug_L))
if (nrow(bad_units) > 0) {
  cat("ERROR: CCME rows with unrecognised units:\n")
  print(bad_units |> select(Chemical, Species, Units, Conc))
  stop("Unsupported unit(s) in ccme_data: ", paste(unique(bad_units$Units), collapse = ", "))
}
cat("CCME: unit conversion complete — mg/L x1000, ng/L /1000, ug/L unchanged\n")

ccme_cas <- curated_cas |> filter(source == "ccme")
ccme_chems_missing <- setdiff(ccme_data$Chemical, ccme_cas$chemical_name)
if (length(ccme_chems_missing) > 0) {
  stop("ERROR: CCME chemicals not found in curated_cas_lookup.csv: ",
    paste(ccme_chems_missing, collapse = ", "))
}

ccme_prepped <- ccme_prepped |>
  left_join(ccme_cas |> select(chemical_name, casnumber_grouped, chemicalname_grouped),
    by = c("Chemical" = "chemical_name")) |>
  mutate(
    accepted_name = Species,
    medium = Medium,
    source = "ccme",
    majorgroup = as.character(Group),
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
    any_conc_flagged = FALSE,
    geomean_flagged = FALSE,
    lifestage_mixed = FALSE,
    duration_mixed = FALSE
  )

if (any(is.na(ccme_prepped$casnumber_grouped))) {
  failed <- ccme_prepped |> filter(is.na(casnumber_grouped)) |> distinct(Chemical)
  stop("ERROR: CCME rows failed CAS join for chemicals: ",
    paste(failed$Chemical, collapse = ", "))
}

cat("CCME: prepared", nrow(ccme_prepped), "rows\n\n")

# ============================================================
# TASK 3: Prepare AIMS and CSIRO (taxonomy + aggregation)
# ============================================================

cat("====================================================\n")
cat("TASK 3: Prepare AIMS and CSIRO records\n")
cat("====================================================\n\n")

# ---- Step 3a: Unit check ----
aims_conc_range <- range(aims_data$Conc, na.rm = TRUE)
csiro_conc_range <- range(csiro_data$Conc, na.rm = TRUE)
cat("AIMS Conc range:", aims_conc_range[1], "–", aims_conc_range[2], "(µg/L assumed)\n")
cat("CSIRO Conc range:", csiro_conc_range[1], "–", csiro_conc_range[2], "(µg/L assumed)\n")
if ("Units" %in% names(aims_data)) {
  cat("AIMS Units:", paste(unique(aims_data$Units), collapse = ", "), "\n")
}
if ("Units" %in% names(csiro_data)) {
  cat("CSIRO Units:", paste(unique(csiro_data$Units), collapse = ", "), "\n")
}
cat("\n")

# ---- Step 3b: Distinct species for resolution ----
aims_species <- na.omit(unique(aims_data$Species))
csiro_species <- na.omit(unique(csiro_data$Species))
curated_species <- union(aims_species, csiro_species)
cat("Distinct species to resolve (NA excluded):", length(curated_species), "\n")

# ---- Step 3c: Taxonomy resolution ----

# Columns from species_resolution_v2.csv that map to the Stage 4e enriched schema
res_v2_cols <- c(
  "scientificname",
  "accepted_name",
  "resolved_kingdom",
  "resolved_phylum",
  "resolved_class",
  "resolved_order",
  "resolved_family",
  "resolved_genus",
  "taxonomy_provenance"
)

cache <- species_res_v2 |>
  select(all_of(res_v2_cols)) |>
  filter(
    !is.na(accepted_name),
    taxonomy_provenance != "no_taxonomy"
  )

# Match by case-insensitive scientificname
cache_hits_idx <- match(tolower(curated_species), tolower(cache$scientificname))
cache_hit_species <- curated_species[!is.na(cache_hits_idx)]
cache_miss_species <- curated_species[is.na(cache_hits_idx)]

cat("Cache hits:", length(cache_hit_species), "\n")
cat("Cache misses (need fresh WoRMS):", length(cache_miss_species), "\n")
if (length(cache_miss_species) > 0) {
  cat("Miss species:", paste(cache_miss_species, collapse = ", "), "\n")
}
cat("\n")

# Resolve cache hits
resolve_from_cache <- function(sp_name, cache) {
  idx <- which(tolower(cache$scientificname) == tolower(sp_name))
  if (length(idx) == 0) return(NULL)
  row <- cache[idx[1], ]
  tibble(
    query_name = sp_name,
    accepted_name = row$accepted_name,
    kingdom = row$resolved_kingdom,
    phylum = row$resolved_phylum,
    class = row$resolved_class,
    order_taxon = row$resolved_order,
    family = row$resolved_family,
    genus = row$resolved_genus,
    majorgroup = row$resolved_class,
    taxonomy_provenance = row$taxonomy_provenance,
    resolution_source = "cache"
  )
}

# Fresh WoRMS resolution for cache misses
resolve_fresh_worms <- function(sp_name, source_phylum = NA_character_) {
  tryCatch(
    {
      # Try exact match first
      res <- wm_records_names(name = sp_name, fuzzy = FALSE)[[1]]
      if (is.null(res) || nrow(res) == 0) {
        res <- wm_records_names(name = sp_name, fuzzy = TRUE)[[1]]
      }
      if (is.null(res) || nrow(res) == 0) {
        return(NULL)
      }

      # Filter to species rank or finer
      res <- res |> filter(rank %in% c("Species", "Subspecies", "Variety", "Forma"))
      if (nrow(res) == 0) return(NULL)

      # Prefer exact name match if available (guard against fuzzy conflation)
      exact <- res |> filter(tolower(scientificname) == tolower(sp_name))
      if (nrow(exact) == 1) {
        res <- exact
      } else if (nrow(exact) > 1) {
        # Prefer valid/accepted over unaccepted
        valid <- exact |> filter(status == "accepted")
        if (nrow(valid) >= 1) res <- valid[1, ] else res <- exact[1, ]
      } else {
        # No exact match — use first fuzzy result
        res <- res[1, ]
      }

      # Try to get accepted name and classification
      accepted_nm <- if (!is.na(res$valid_name) && res$valid_name != "") res$valid_name else sp_name
      cls_res <- tryCatch(
        wm_classification(id = res$AphiaID),
        error = function(e) NULL
      )

      extract_rank <- function(cls, rank_name) {
        if (is.null(cls)) return(NA_character_)
        row <- cls |> filter(tolower(rank) == tolower(rank_name))
        if (nrow(row) == 0) NA_character_ else row$scientificname[1]
      }

      tibble(
        query_name = sp_name,
        accepted_name = accepted_nm,
        kingdom = extract_rank(cls_res, "Kingdom"),
        phylum = extract_rank(cls_res, "Phylum"),
        class = extract_rank(cls_res, "Class"),
        order_taxon = extract_rank(cls_res, "Order"),
        family = extract_rank(cls_res, "Family"),
        genus = extract_rank(cls_res, "Genus"),
        majorgroup = extract_rank(cls_res, "Class"),
        taxonomy_provenance = "worms_full",
        resolution_source = "worms_fresh"
      )
    },
    error = function(e) {
      message("WoRMS error for '", sp_name, "': ", conditionMessage(e))
      NULL
    }
  )
}

# GBIF fallback for WoRMS failures
resolve_via_gbif <- function(sp_name) {
  if (!requireNamespace("rgbif", quietly = TRUE)) {
    return(NULL)
  }
  tryCatch(
    {
      res <- rgbif::name_suggest(q = sp_name, rank = "SPECIES", limit = 5)
      hits <- res$data
      if (is.null(hits) || nrow(hits) == 0) return(NULL)
      exact <- hits |> filter(tolower(canonicalName) == tolower(sp_name))
      if (nrow(exact) == 0) exact <- hits[1, ]
      row <- exact[1, ]
      tibble(
        query_name = sp_name,
        accepted_name = coalesce(row$canonicalName, sp_name),
        kingdom = coalesce(row$kingdom, NA_character_),
        phylum = coalesce(row$phylum, NA_character_),
        class = coalesce(row$class, NA_character_),
        order_taxon = coalesce(row$order, NA_character_),
        family = coalesce(row$family, NA_character_),
        genus = coalesce(row$genus, NA_character_),
        majorgroup = coalesce(row$class, NA_character_),
        taxonomy_provenance = "gbif_full",
        resolution_source = "gbif_fresh"
      )
    },
    error = function(e) {
      message("GBIF error for '", sp_name, "': ", conditionMessage(e))
      NULL
    }
  )
}

# Run resolution for all cache misses
cat("Running fresh WoRMS resolution for", length(cache_miss_species), "species...\n")
fresh_results <- vector("list", length(cache_miss_species))
n_worms_ok <- 0
n_gbif_ok <- 0
n_unresolved_sp <- 0
unresolved_species <- character(0)

for (i in seq_along(cache_miss_species)) {
  sp <- cache_miss_species[i]
  cat(sprintf("  [%d/%d] %s ...", i, length(cache_miss_species), sp))

  res <- resolve_fresh_worms(sp)
  if (!is.null(res)) {
    fresh_results[[i]] <- res
    n_worms_ok <- n_worms_ok + 1
    cat(" WoRMS OK\n")
    next
  }

  # GBIF fallback
  res_gbif <- resolve_via_gbif(sp)
  if (!is.null(res_gbif)) {
    res_gbif$taxonomy_provenance <- "gbif_full"
    fresh_results[[i]] <- res_gbif
    n_gbif_ok <- n_gbif_ok + 1
    cat(" GBIF OK\n")
    next
  }

  # Unresolved fallback: use raw name, no taxonomy
  fresh_results[[i]] <- tibble(
    query_name = sp,
    accepted_name = sp,
    kingdom = NA_character_,
    phylum = NA_character_,
    class = NA_character_,
    order_taxon = NA_character_,
    family = NA_character_,
    genus = NA_character_,
    majorgroup = NA_character_,
    taxonomy_provenance = "source_native_fallback",
    resolution_source = "unresolved"
  )
  n_unresolved_sp <- n_unresolved_sp + 1
  unresolved_species <- c(unresolved_species, sp)
  cat(" UNRESOLVED\n")
}

# Combine cache hits and fresh results
cache_hit_rows <- lapply(cache_hit_species, resolve_from_cache, cache = cache)
all_resolved <- bind_rows(
  bind_rows(cache_hit_rows),
  bind_rows(fresh_results)
)

cat("\nTaxonomy resolution — curated species (aims + csiro):\n")
cat("  Total distinct species:", length(curated_species), "\n")
cat("  Cache hits:           ", length(cache_hit_species), sprintf("(%.1f%%)", 100 * length(cache_hit_species) / length(curated_species)), "\n")
cat("  Fresh WoRMS:          ", n_worms_ok, "\n")
cat("  GBIF fallbacks:       ", n_gbif_ok, "\n")
cat("  Unresolved:           ", n_unresolved_sp, "\n")
if (n_unresolved_sp > 0) cat("  Unresolved species:   ", paste(unresolved_species, collapse = ", "), "\n")
cat("\n")

# Write curated species resolution file
sp_res_curated_path <- "data-raw/alldata/species_resolution_curated.csv"
# Include all input species (including NA-Species rows which have no entry)
write_csv(all_resolved, sp_res_curated_path)
cat("Written:", sp_res_curated_path, "(", nrow(all_resolved), "rows)\n")
cat("NOTE: This file must be read with guess_max = Inf in any future script.\n\n")

# ---- Step 3d: Join taxonomy onto aims and csiro ----

# Build a lookup from query_name → resolved taxonomy
taxonomy_lookup <- all_resolved |>
  select(query_name, accepted_name, kingdom, phylum, class, order_taxon, family, genus,
    majorgroup, taxonomy_provenance) |>
  distinct(query_name, .keep_all = TRUE)

join_taxonomy <- function(df, taxonomy_lookup, sp_col = "Species") {
  df |>
    left_join(taxonomy_lookup, by = setNames("query_name", sp_col))
}

aims_with_tax <- join_taxonomy(aims_data, taxonomy_lookup)
csiro_with_tax <- join_taxonomy(csiro_data, taxonomy_lookup)

# For NA-Species rows in csiro: accepted_name = NA (treated as distinct group)
csiro_with_tax <- csiro_with_tax |>
  mutate(accepted_name = if_else(is.na(Species), NA_character_, accepted_name))

# Check for unexpected NA accepted_name (non-NA species that failed join)
aims_bad <- aims_with_tax |> filter(!is.na(Species), is.na(accepted_name))
csiro_bad <- csiro_with_tax |> filter(!is.na(Species), is.na(accepted_name))
if (nrow(aims_bad) > 0 || nrow(csiro_bad) > 0) {
  if (nrow(aims_bad) > 0) {
    cat("ERROR: AIMS rows with non-NA Species but missing accepted_name:\n")
    print(aims_bad |> select(Chemical, Medium, Species))
  }
  if (nrow(csiro_bad) > 0) {
    cat("ERROR: CSIRO rows with non-NA Species but missing accepted_name:\n")
    print(csiro_bad |> select(Chemical, Medium, Species))
  }
  stop("Taxonomy join produced unexpected NA accepted_name values — review above.")
}

# ---- Step 3e: CAS join for aims and csiro ----

aims_cas <- curated_cas |> filter(source == "aims")
csiro_cas <- curated_cas |> filter(source == "csiro")

aims_with_tax <- aims_with_tax |>
  left_join(aims_cas |> select(chemical_name, casnumber_grouped, chemicalname_grouped),
    by = c("Chemical" = "chemical_name"))
csiro_with_tax <- csiro_with_tax |>
  left_join(csiro_cas |> select(chemical_name, casnumber_grouped, chemicalname_grouped),
    by = c("Chemical" = "chemical_name"))

# ---- Step 3e-extra: Normalise Medium for aims and csiro ----
# ANZG Medium was already normalised in Task 2; aims and csiro use lowercase
# and/or non-standard values ("fresh") that must map to the schema vocabulary.
normalize_medium <- function(x) {
  dplyr::case_when(
    tolower(x) %in% c("freshwater", "fresh") ~ "Freshwater",
    tolower(x) == "marine"                   ~ "Marine",
    tolower(x) == "soft freshwater"          ~ "Soft freshwater",
    tolower(x) == "moderate freshwater"      ~ "Moderate freshwater",
    tolower(x) == "hard freshwater"          ~ "Hard freshwater",
    TRUE ~ x
  )
}

aims_with_tax  <- aims_with_tax  |> mutate(Medium = normalize_medium(Medium))
csiro_with_tax <- csiro_with_tax |> mutate(Medium = normalize_medium(Medium))

# ---- Step 3f: Within-source Section 3.4.4 aggregation ----

agg_source <- function(df, source_label) {
  # Group by CAS x accepted_name x medium; Domain is NOT part of grouping key
  df |>
    filter(!is.na(Conc)) |>
    group_by(casnumber_grouped, chemicalname_grouped, accepted_name, Medium,
      kingdom, phylum, class, order_taxon, family, genus, majorgroup,
      taxonomy_provenance) |>
    summarise(
      n_records = n(),
      conc_ug_L = if (max(Conc) / min(Conc) > 10) min(Conc) else exp(mean(log(Conc))),
      geomean_flagged = max(Conc) / min(Conc) > 10,
      .groups = "drop"
    ) |>
    mutate(
      source = source_label,
      medium = Medium,
      sources_contributing = source_label,
      any_acr_applied = FALSE,
      any_conc_flagged = FALSE,
      lifestage_mixed = FALSE,
      duration_mixed = FALSE
    ) |>
    select(-Medium)
}

aims_agg <- agg_source(aims_with_tax, "aims")
csiro_agg <- agg_source(csiro_with_tax, "csiro") |>
  # 30 chlorine/marine rows have Species = NA; they aggregate to accepted_name = NA.
  # Fill with a placeholder so downstream joins and validation do not fail.
  mutate(accepted_name = coalesce(accepted_name, "Unknown species (no name in source)"))

cat("Within-source aggregation summary:\n")
cat("  aims:  ", nrow(aims_with_tax), "input rows →", nrow(aims_agg), "output rows\n")
cat("  csiro: ", nrow(csiro_with_tax), "input rows →", nrow(csiro_agg), "output rows\n")
cat("  geomean_flagged = TRUE (total):",
  sum(aims_agg$geomean_flagged) + sum(csiro_agg$geomean_flagged), "\n")

flagged_groups <- bind_rows(
  aims_agg |> filter(geomean_flagged) |>
    mutate(src = "aims") |>
    select(src, accepted_name, chemicalname_grouped, medium, conc_ug_L),
  csiro_agg |> filter(geomean_flagged) |>
    mutate(src = "csiro") |>
    select(src, accepted_name, chemicalname_grouped, medium, conc_ug_L)
)
if (nrow(flagged_groups) > 0) {
  cat("  Flagged groups:\n")
  print(flagged_groups)
}
cat("\n")

# ============================================================
# TASK 4: Concentration plausibility audit (curated records, audit only)
# ============================================================

cat("====================================================\n")
cat("TASK 4: Concentration plausibility audit (curated, audit only)\n")
cat("====================================================\n\n")

LOWER_HARD <- 1e-5
LOWER_SOFT <- 1e-3
UPPER_SOFT <- 1e6
UPPER_HARD <- 1e8

conc_tier <- function(conc) {
  case_when(
    conc < LOWER_HARD ~ "low_hard",
    conc < LOWER_SOFT ~ "low_soft",
    conc > UPPER_HARD ~ "high_hard",
    conc > UPPER_SOFT ~ "high_soft",
    TRUE ~ "ok_range"
  )
}

audit_source <- function(df, name, conc_col = "Conc") {
  tiers <- conc_tier(df[[conc_col]])
  tbl <- table(tiers)
  cat(sprintf(
    "  %s: ok_range=%d, low_soft=%d, low_hard=%d, high_soft=%d, high_hard=%d\n",
    name,
    sum(tiers == "ok_range"), sum(tiers == "low_soft"),
    sum(tiers == "low_hard"), sum(tiers == "high_soft"),
    sum(tiers == "high_hard")
  ))
  hard_rows <- df[tiers %in% c("low_hard", "high_hard"), ]
  if (nrow(hard_rows) > 0) {
    cat("    ADVISORY — hard-range rows in", name, "(no action taken):\n")
    print(hard_rows |> select(any_of(c("Chemical", "Species", conc_col, "Units"))))
  }
  invisible(tbl)
}

cat("Concentration plausibility audit — curated records (audit only; no rows excluded):\n")
audit_source(anzg_data, "anzg")
audit_source(ccme_prepped, "ccme", conc_col = "conc_ug_L")
audit_source(aims_data, "aims")
audit_source(csiro_data, "csiro")
cat("\n")

# ============================================================
# TASK 5: Bind all sources
# ============================================================

cat("====================================================\n")
cat("TASK 5: Bind all sources\n")
cat("====================================================\n\n")

# Define the 20-column Stage 4e schema order
schema_cols <- c(
  "casnumber_grouped", "chemicalname_grouped", "accepted_name", "medium",
  "conc_ug_L", "majorgroup", "kingdom", "phylum", "class", "order_taxon",
  "family", "genus", "taxonomy_provenance", "n_records", "sources_contributing",
  "any_acr_applied", "any_conc_flagged", "geomean_flagged", "lifestage_mixed",
  "duration_mixed"
)

# Uncurated rows: set source from sources_contributing
uncurated_out <- uncurated |>
  mutate(source = "uncurated")

# Ensure schema columns exist and are correctly typed in each source
ensure_schema <- function(df, schema_cols) {
  for (col in schema_cols) {
    if (!col %in% names(df)) df[[col]] <- NA
  }
  df
}

# Aggregate within-ANZG duplicates: same species × chemical × medium with
# different durations → geomean (or min() if spread > 10×). One case known:
# Boron × Freshwater × Navicula sp. (Phase 1 Task 4 flagged this).
anzg_agg <- anzg_prepped |>
  group_by(casnumber_grouped, chemicalname_grouped, accepted_name, medium) |>
  summarise(
    conc_ug_L = if (max(Conc) / min(Conc) > 10) min(Conc) else exp(mean(log(Conc))),
    geomean_flagged = max(Conc) / min(Conc) > 10,
    n_records = n(),
    .groups = "drop"
  ) |>
  mutate(source = "anzg", sources_contributing = "anzg",
    any_acr_applied = FALSE, any_conc_flagged = FALSE,
    lifestage_mixed = FALSE, duration_mixed = FALSE)

# Add back the taxonomy columns from the pre-aggregation frame (use first row per group)
anzg_tax <- anzg_prepped |>
  select(casnumber_grouped, chemicalname_grouped, accepted_name, medium,
    kingdom, phylum, class, order_taxon, family, genus, majorgroup, taxonomy_provenance) |>
  distinct(casnumber_grouped, chemicalname_grouped, accepted_name, medium, .keep_all = TRUE)

anzg_agg <- anzg_agg |>
  left_join(anzg_tax, by = c("casnumber_grouped", "chemicalname_grouped", "accepted_name", "medium"))

cat(sprintf("ANZG: %d rows before within-source agg, %d after\n",
  nrow(anzg_prepped), nrow(anzg_agg)))

anzg_schema <- anzg_agg |>
  ensure_schema(schema_cols) |>
  select(all_of(c(schema_cols, "source")))

ccme_schema <- ccme_prepped |>
  ensure_schema(schema_cols) |>
  select(all_of(c(schema_cols, "source")),
    any_of(c("Group", "Chemical")))

aims_schema <- aims_agg |>
  ensure_schema(schema_cols) |>
  select(all_of(c(schema_cols, "source")),
    any_of(c("Chemical")))

csiro_schema <- csiro_agg |>
  ensure_schema(schema_cols) |>
  select(all_of(c(schema_cols, "source")),
    any_of(c("Chemical")))

uncurated_schema <- uncurated_out |>
  ensure_schema(schema_cols) |>
  select(all_of(c(schema_cols, "source")))

# Bind in priority order (highest first)
combined <- bind_rows(
  anzg_schema,
  ccme_schema,
  aims_schema,
  csiro_schema,
  uncurated_schema
) |>
  mutate(exclusion_flag = NA_character_)

cat("Combined frame row counts by source:\n")
print(count(combined, source))
cat("Total rows:", nrow(combined), "\n\n")

# ============================================================
# TASK 6: ANZG exclusion rule
# ============================================================

cat("====================================================\n")
cat("TASK 6: ANZG exclusion rule\n")
cat("====================================================\n\n")

anzg_freshwater_variants <- c("Freshwater", "Soft freshwater", "Moderate freshwater", "Hard freshwater")
anzg_marine_val <- "Marine"

anzg_rows <- combined |>
  filter(source == "anzg") |>
  select(casnumber_grouped, medium) |>
  distinct()

anzg_fw_cas <- anzg_rows |>
  filter(medium %in% anzg_freshwater_variants) |>
  pull(casnumber_grouped) |>
  unique()

anzg_marine_cas <- anzg_rows |>
  filter(medium == anzg_marine_val) |>
  pull(casnumber_grouped) |>
  unique()

cat("Chemicals with ANZG freshwater coverage:", length(anzg_fw_cas), "\n")
cat("Chemicals with ANZG marine coverage:", length(anzg_marine_cas), "\n")

combined <- combined |>
  mutate(exclusion_flag = case_when(
    !is.na(exclusion_flag) ~ exclusion_flag,
    source != "anzg" & casnumber_grouped %in% anzg_fw_cas & medium == "Freshwater" ~
      "anzg_rule_freshwater",
    source != "anzg" & casnumber_grouped %in% anzg_marine_cas & medium == anzg_marine_val ~
      "anzg_rule_marine",
    TRUE ~ exclusion_flag
  ))

fw_excl <- combined |> filter(exclusion_flag == "anzg_rule_freshwater")
mar_excl <- combined |> filter(exclusion_flag == "anzg_rule_marine")

cat("\nRows excluded by anzg_rule_freshwater:", nrow(fw_excl), "\n")
print(count(fw_excl, source))
cat("Rows excluded by anzg_rule_marine:", nrow(mar_excl), "\n")
print(count(mar_excl, source))
cat("\n")

# ============================================================
# TASK 7: CCME exclusion rule
# ============================================================

cat("====================================================\n")
cat("TASK 7: CCME exclusion rule\n")
cat("====================================================\n\n")

# Apply rule based on actual Medium values in the data.
# CLAUDE.md describes ccme Medium as "Unknown" (Issue #34 pending), but actual
# data shows "Freshwater". The exclusion is applied to matching medium values.
ccme_medium_vals <- unique(ccme_prepped$medium)
cat("CCME medium values in data:", paste(ccme_medium_vals, collapse = ", "), "\n")
cat("(CLAUDE.md describes as 'Unknown'; actual data differs — see Task 2 NOTE)\n")

ccme_excl_cas_by_medium <- combined |>
  filter(source == "ccme") |>
  select(casnumber_grouped, medium) |>
  distinct()

n_ccme_excluded <- 0
for (med_val in ccme_medium_vals) {
  ccme_cas_this_medium <- ccme_excl_cas_by_medium |>
    filter(medium == med_val) |>
    pull(casnumber_grouped) |>
    unique()

  cat("  Chemicals with CCME", med_val, "coverage:", length(ccme_cas_this_medium), "\n")

  flag_label <- paste0("ccme_rule_", tolower(gsub(" ", "_", med_val)))
  # CCME excludes only lower-priority sources — ANZG is higher priority and immune.
  combined <- combined |>
    mutate(exclusion_flag = case_when(
      !is.na(exclusion_flag) ~ exclusion_flag,
      source %in% c("aims", "csiro", "uncurated") &
        casnumber_grouped %in% ccme_cas_this_medium &
        medium == med_val ~
        flag_label,
      TRUE ~ exclusion_flag
    ))

  n_this <- sum(combined$exclusion_flag == flag_label, na.rm = TRUE)
  n_ccme_excluded <- n_ccme_excluded + n_this
  cat("  Rows excluded by", flag_label, ":", n_this, "\n")
  print(count(combined |> filter(exclusion_flag == flag_label), source))
}
cat("\n")

# ============================================================
# TASK 8: Preference hierarchy for remaining overlaps
# ============================================================

cat("====================================================\n")
cat("TASK 8: Preference hierarchy (aims > csiro > uncurated)\n")
cat("====================================================\n\n")

# Find retained rows (not yet excluded) from aims, csiro, uncurated
active <- combined |>
  filter(is.na(exclusion_flag), source %in% c("aims", "csiro", "uncurated"))

# Check for same casnumber_grouped x medium x accepted_name across sources
overlap_key <- c("casnumber_grouped", "medium", "accepted_name")

overlap <- active |>
  group_by(across(all_of(overlap_key))) |>
  filter(n_distinct(source) > 1) |>
  ungroup()

# Priority: aims > csiro > uncurated
priority_order <- c("aims" = 1L, "csiro" = 2L, "uncurated" = 3L)

overlap <- overlap |>
  mutate(priority = priority_order[source])

# Find winning source for each overlapping triplet (lowest priority number wins)
winners <- overlap |>
  group_by(across(all_of(overlap_key))) |>
  slice_min(priority, n = 1, with_ties = FALSE) |>
  ungroup() |>
  select(all_of(overlap_key), winner_source = source)

# Apply exclusion flag to all sources in combined that lose in an overlapping triplet
if (nrow(winners) > 0) {
  combined <- combined |>
    left_join(winners, by = overlap_key) |>
    mutate(
      exclusion_flag = case_when(
        !is.na(exclusion_flag) ~ exclusion_flag,
        # Only apply to the three sources that participate in preference hierarchy
        source %in% c("aims", "csiro", "uncurated") &
          !is.na(winner_source) &
          source != winner_source ~
          paste0("priority_", winner_source, "_over_", source),
        TRUE ~ exclusion_flag
      )
    ) |>
    select(-winner_source)
}

# Summary
aim_over_csiro <- sum(grepl("priority_aims_over_csiro", combined$exclusion_flag), na.rm = TRUE)
aim_over_unc <- sum(grepl("priority_aims_over_uncurated", combined$exclusion_flag), na.rm = TRUE)
csiro_over_unc <- sum(grepl("priority_csiro_over_uncurated", combined$exclusion_flag), na.rm = TRUE)

cat("Preference hierarchy applied:\n")
cat("  aims > csiro:      ", aim_over_csiro, "csiro rows marked\n")
cat("  aims > uncurated:  ", aim_over_unc, "uncurated rows marked\n")
cat("  csiro > uncurated: ", csiro_over_unc, "uncurated rows marked\n\n")

# ============================================================
# TASK 9: Filter to retained rows and write output
# ============================================================

cat("====================================================\n")
cat("TASK 9: Filter and write alldata_integrated.csv\n")
cat("====================================================\n\n")

# Ensure alldata_integrated.csv is in .gitignore before creating the file
gitignore_path <- ".gitignore"
gitignore_entry <- "data-raw/alldata/alldata_integrated.csv"
gi_lines <- if (file.exists(gitignore_path)) readLines(gitignore_path) else character(0)
if (!any(trimws(gi_lines) == gitignore_entry)) {
  cat("Adding", gitignore_entry, "to .gitignore\n")
  write(gitignore_entry, file = gitignore_path, append = TRUE)
} else {
  cat(gitignore_entry, "already in .gitignore\n")
}

retained <- combined |> filter(is.na(exclusion_flag))

cat("Retained rows:", nrow(retained), "\n")
cat("Row counts by source:\n")
print(count(retained, source))
cat("Row counts by medium:\n")
print(count(retained, medium))

# ---- Validation checks ----
cat("\nRunning validation checks...\n")
checks_passed <- TRUE

check <- function(condition, label, detail = NULL) {
  if (condition) {
    cat("  CHECK", label, ": PASS\n")
  } else {
    cat("  CHECK", label, ": FAIL\n")
    if (!is.null(detail)) cat("    Detail:", detail, "\n")
    checks_passed <<- FALSE
  }
}

check(!any(is.na(retained$casnumber_grouped)), "1 — casnumber_grouped no NA",
  paste(sum(is.na(retained$casnumber_grouped)), "NA values"))
check(!any(is.na(retained$accepted_name)), "2 — accepted_name no NA",
  paste(sum(is.na(retained$accepted_name)), "NA values"))
check(!any(is.na(retained$conc_ug_L)) && all(retained$conc_ug_L > 0, na.rm = TRUE),
  "3 — conc_ug_L no NA and all > 0",
  paste("NA:", sum(is.na(retained$conc_ug_L)), "<=0:", sum(retained$conc_ug_L <= 0, na.rm = TRUE)))

valid_mediums <- c("Freshwater", "Soft freshwater", "Moderate freshwater",
  "Hard freshwater", "Marine", "Unknown")
check(all(retained$medium %in% valid_mediums), "4 — medium values valid",
  paste("Unexpected:", paste(setdiff(unique(retained$medium), valid_mediums), collapse = ", ")))
check(!any(is.na(retained$source)), "5 — source no NA",
  paste(sum(is.na(retained$source)), "NA values"))

# Check 6: no same-CAS x medium x accepted_name triplet from two *different* curated sources
# (within-source duplicates are handled by per-source aggregation before binding)
curated_sources <- c("anzg", "ccme", "aims", "csiro")
dup_check <- retained |>
  filter(source %in% curated_sources) |>
  group_by(casnumber_grouped, medium, accepted_name) |>
  filter(n_distinct(source) > 1) |>
  ungroup()
if (nrow(dup_check) > 0) {
  cat("  Duplicate curated rows (for diagnosis):\n")
  print(dup_check |> select(source, casnumber_grouped, chemicalname_grouped, accepted_name, medium, conc_ug_L))
}
check(nrow(dup_check) == 0, "6 — no curated-source duplicates",
  paste(nrow(dup_check), "rows are duplicates"))

max_expected <- nrow(uncurated) + nrow(anzg_data) + nrow(ccme_data) + nrow(aims_data) + nrow(csiro_data)
check(nrow(retained) <= max_expected, "7 — row count plausible",
  paste("Retained:", nrow(retained), "> max expected:", max_expected))

if (!checks_passed) stop("One or more validation checks FAILED — see above.")
cat("All validation checks PASSED.\n\n")

# Write output
out_path_integrated <- "data-raw/alldata/alldata_integrated.csv"
write_csv(retained, out_path_integrated)
file_size_mb <- round(file.size(out_path_integrated) / 1024 / 1024, 1)
cat("Written:", out_path_integrated, "\n")
cat("File size:", file_size_mb, "MB\n")
cat("Rows:", nrow(retained), "| Columns:", ncol(retained), "\n\n")

# ============================================================
# TASK 10: Write audit report
# ============================================================

cat("====================================================\n")
cat("TASK 10: Write stage6-integration-report.md\n")
cat("====================================================\n\n")

report_path <- "data-raw/alldata/stage6-integration-report.md"

retained_by_source_medium <- retained |>
  count(source, medium) |>
  arrange(source, medium)

all_excl <- combined |> filter(!is.na(exclusion_flag))
excl_by_type <- count(all_excl, exclusion_flag) |> arrange(desc(n))

report_lines <- c(
  "# Stage 6 Integration Audit Report",
  "",
  paste("Generated:", format(Sys.Date(), "%Y-%m-%d")),
  "Script: scripts/stage6-phase2-integrate.R",
  "",
  "## 1. Input row counts",
  "",
  "| Source | Input rows |",
  "|--------|-----------|",
  sprintf("| uncurated (Stage 4e) | %d |", nrow(uncurated)),
  sprintf("| anzg_data | %d |", nrow(anzg_data)),
  sprintf("| ccme_data | %d |", nrow(ccme_data)),
  sprintf("| aims_data | %d |", nrow(aims_data)),
  sprintf("| csiro_data | %d |", nrow(csiro_data)),
  sprintf("| **Total pre-exclusion** | **%d** |", nrow(combined)),
  "",
  "## 2. CAS lookup",
  "",
  sprintf("- UNCERTAIN rows excluded from uncurated pipeline: 18 (excluded = TRUE in cas_parent_lookup_all.csv)"),
  sprintf("- Curated source chemicals in curated_cas_lookup.csv: %d distinct chemicals across %d source x chemical rows",
    n_distinct(curated_cas$chemical_name), nrow(curated_cas)),
  sprintf("- master_lookup resolutions: %d | webchem_cir: %d | manual: %d | unresolved: %d",
    n_master, n_webchem, n_manual, n_unresolved),
  "",
  "## 3. Taxonomy resolution — aims and csiro",
  "",
  sprintf("- Total distinct species (non-NA): %d", length(curated_species)),
  sprintf("- Cache hits (species_resolution_v2.csv): %d (%.1f%%)",
    length(cache_hit_species), 100 * length(cache_hit_species) / max(length(curated_species), 1)),
  sprintf("- Fresh WoRMS resolutions: %d", n_worms_ok),
  sprintf("- GBIF fallbacks: %d", n_gbif_ok),
  sprintf("- Unresolved: %d%s", n_unresolved_sp,
    if (n_unresolved_sp > 0) paste0(" — ", paste(unresolved_species, collapse = ", ")) else ""),
  sprintf("- csiro NA-Species rows (chlorine x marine): %d — treated as distinct accepted_name = NA group",
    sum(is.na(csiro_data$Species))),
  "",
  "## 4. Within-source aggregation — aims and csiro",
  "",
  "| Source | Input rows | Output rows | Groups aggregated | geomean_flagged |",
  "|--------|-----------|-------------|-------------------|-----------------|",
  sprintf("| aims  | %d | %d | %d | %d |",
    nrow(aims_data), nrow(aims_agg),
    nrow(aims_data) - nrow(aims_agg), sum(aims_agg$geomean_flagged)),
  sprintf("| csiro | %d | %d | %d | %d |",
    nrow(csiro_data), nrow(csiro_agg),
    nrow(csiro_data) - nrow(csiro_agg), sum(csiro_agg$geomean_flagged)),
  if (nrow(flagged_groups) > 0) {
    c("", "Flagged groups:", paste("-", apply(flagged_groups, 1, paste, collapse = " | ")))
  } else {
    "No geomean-flagged groups."
  },
  "",
  "## 5. Concentration plausibility audit — curated records (audit only)",
  "",
  "No rows excluded from curated sources. Advisory only.",
  "(See console output for tier counts.)",
  "",
  "## 6. Exclusion rule application",
  "",
  "### 6a. ANZG exclusion",
  "",
  sprintf("- Chemicals with ANZG freshwater coverage: %d", length(anzg_fw_cas)),
  sprintf("- Chemicals with ANZG marine coverage: %d", length(anzg_marine_cas)),
  sprintf("- Rows excluded by anzg_rule_freshwater: %d", nrow(fw_excl)),
  sprintf("- Rows excluded by anzg_rule_marine: %d", nrow(mar_excl)),
  "",
  "### 6b. CCME exclusion",
  "",
  sprintf("- CCME medium in data: %s", paste(ccme_medium_vals, collapse = ", ")),
  "- NOTE: CLAUDE.md describes ccme Medium as 'Unknown' (Issue #34); actual data differs.",
  sprintf("- Total rows excluded by CCME rules: %d", n_ccme_excluded),
  "",
  "### 6c. Preference hierarchy",
  "",
  sprintf("- aims > csiro: %d rows excluded", aim_over_csiro),
  sprintf("- aims > uncurated: %d rows excluded", aim_over_unc),
  sprintf("- csiro > uncurated: %d rows excluded", csiro_over_unc),
  "",
  "## 7. Retained row counts by source and medium",
  "",
  "| Source | Medium | Rows |",
  "|--------|--------|------|",
  apply(retained_by_source_medium, 1, function(r) sprintf("| %s | %s | %s |", r[1], r[2], r[3])),
  sprintf("| **Total** | | **%d** |", nrow(retained)),
  "",
  "## 8. Validation checks",
  "",
  if (checks_passed) "All 7 checks PASSED." else "One or more checks FAILED — see console output.",
  "",
  "## 9. Output",
  "",
  sprintf("File: data-raw/alldata/alldata_integrated.csv"),
  sprintf("Size: %s MB", file_size_mb),
  sprintf("Rows: %d", nrow(retained)),
  sprintf("Columns: %d", ncol(retained))
)

writeLines(report_lines, report_path)
cat("Written:", report_path, "\n\n")

# ============================================================
# Session summary
# ============================================================

cat("====================================================\n")
cat("=== Stage 6 Phase 2 session summary ===\n")
cat("====================================================\n\n")

cat("Inputs:\n")
cat(sprintf("  uncurated_raw_aggregated.csv: %d rows\n", nrow(uncurated)))
cat(sprintf("  anzg: %d, ccme: %d, aims: %d (post-agg), csiro: %d (post-agg)\n",
  nrow(anzg_prepped), nrow(ccme_prepped), nrow(aims_agg), nrow(csiro_agg)))

cat("\nExclusions applied:\n")
cat(sprintf("  ANZG rule: %d rows excluded\n", nrow(fw_excl) + nrow(mar_excl)))
cat(sprintf("  CCME rule: %d rows excluded\n", n_ccme_excluded))
cat(sprintf("  Priority hierarchy: %d rows excluded\n",
  aim_over_csiro + aim_over_unc + csiro_over_unc))

cat("\nOutput:\n")
cat(sprintf("  data-raw/alldata/alldata_integrated.csv: %d rows, %s MB\n",
  nrow(retained), file_size_mb))

cat(sprintf("\nValidation: all 7 checks %s\n", if (checks_passed) "PASSED" else "FAILED"))

cat("\n=== Files to commit (user action required) ===\n")
cat("  data-raw/alldata/alldata_integrated.csv          [UNTRACKED — large, do not commit]\n")
cat("  data-raw/alldata/curated_cas_lookup.csv          [modified — user-populated]\n")
cat("  data-raw/alldata/species_resolution_curated.csv  [new — tracked]\n")
cat("  data-raw/alldata/stage6-integration-report.md    [new — tracked]\n")
cat("  scripts/stage6-phase2-integrate.R                [new — tracked]\n")
cat("  .gitignore                                        [modified — alldata_integrated.csv added]\n")
cat("  NOTE: species_resolution_curated.csv must be read with guess_max = Inf\n")
cat("  (update CLAUDE.md Section 5 to add this file to the known list)\n")

cat("\n=== Next step ===\n")
cat("  Stage 7: media sufficiency filtering and wire-up of ssd_data_sets()\n")
