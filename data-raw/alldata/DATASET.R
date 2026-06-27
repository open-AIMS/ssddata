# data-raw/alldata/DATASET.R
#
# Purpose: Produce data/allchronic_data.rda from all pipeline sources.
#
# This script consolidates:
#   - Stage 6 Phase 2: integrate curated sources (anzg, ccme, aims, csiro) with
#     the consolidated uncurated output and apply the source-priority exclusion
#     hierarchy. Produces alldata_integrated.csv (UNTRACKED — large, ~14 MB).
#   - Stage 7: apply the media sufficiency filter (≥5 species, ≥4 classes from
#     uncurated rows) and build the allchronic_data package data object.
#
# Upstream dependencies (must be run first if starting from scratch):
#   scripts/alldata/stage6-phase1-cas-lookup-draft.R  → data-raw/alldata/curated_cas_lookup.csv
#   scripts/alldata/stage4e-aggregate.R              → data-raw/alldata/uncurated_raw_aggregated.csv
#   scripts/alldata/stage4d-part3-apply-resolution.R → data-raw/alldata/species_resolution_v2.csv
#
# If data-raw/alldata/alldata_integrated.csv already exists on disk, Stage 6
# is skipped automatically and Stage 7 runs against the existing file.
# alldata_integrated.csv is UNTRACKED (large file, listed in .gitignore).
# To regenerate it, delete the file and rerun this script.
#
# Environment: WSL or Windows Positron (no live DB required for Stage 6/7).
# Outputs:
#   data-raw/alldata/alldata_integrated.csv  [UNTRACKED — large, do not commit]
#   data-raw/alldata/species_resolution_curated.csv  [tracked]
#   data/allchronic_data.rda                 [tracked — package data object]

library(dplyr)
library(readr)

integrated_path <- "data-raw/alldata/alldata_integrated.csv"

# ============================================================
# STAGE 6: Produce alldata_integrated.csv
# ============================================================

if (!file.exists(integrated_path)) {
  message("alldata_integrated.csv not found — running Stage 6 Phase 2 integration...")
  library(worrms)
  library(ssddata)

  # ----------------------------------------------------------
  # Pre-condition checks
  # ----------------------------------------------------------

  cas_curated_path <- "data-raw/alldata/curated_cas_lookup.csv"
  if (!file.exists(cas_curated_path)) {
    stop("ERROR: ", cas_curated_path, " not found. Run stage6-phase1-cas-lookup-draft.R first.")
  }
  curated_cas <- read_csv(cas_curated_path, show_col_types = FALSE)

  na_casnumber <- sum(is.na(curated_cas$casnumber_grouped))
  na_chemname  <- sum(is.na(curated_cas$chemicalname_grouped))
  if (na_casnumber > 0 || na_chemname > 0) {
    missing_rows <- curated_cas |> filter(is.na(casnumber_grouped) | is.na(chemicalname_grouped))
    cat("ERROR: curated_cas_lookup.csv has missing values in", nrow(missing_rows), "rows.\n")
    print(missing_rows |> as.data.frame())
    stop(na_casnumber, " rows NA casnumber_grouped; ", na_chemname, " rows NA chemicalname_grouped.")
  }
  cat("Pre-condition PASSED: curated_cas_lookup.csv complete (", nrow(curated_cas), "rows).\n\n")

  n_master    <- sum(curated_cas$resolution_method == "master_lookup", na.rm = TRUE)
  n_webchem   <- sum(curated_cas$resolution_method == "webchem_cir",  na.rm = TRUE)
  n_manual    <- sum(curated_cas$resolution_method == "manual",        na.rm = TRUE)
  n_unresolved_cas <- sum(curated_cas$resolution_method == "unresolved", na.rm = TRUE)

  # ----------------------------------------------------------
  # TASK 1: Load inputs
  # ----------------------------------------------------------

  uncurated_path <- "data-raw/alldata/uncurated_raw_aggregated.csv"
  if (!file.exists(uncurated_path)) {
    stop("ERROR: ", uncurated_path, " not found. Run stage4e-aggregate.R first.")
  }
  uncurated <- read_csv(uncurated_path, guess_max = Inf, show_col_types = FALSE)
  cat("uncurated_raw_aggregated.csv:", nrow(uncurated), "rows,", ncol(uncurated), "cols\n")
  if (nrow(uncurated) != 59200) {
    warning("Expected 59,200 rows in uncurated_raw_aggregated.csv but found ", nrow(uncurated), ".")
  }

  cas_master_path <- "data-raw/cas_parent_lookup_all.csv"
  if (!file.exists(cas_master_path)) stop("ERROR: Master CAS lookup not found at ", cas_master_path)
  cas_master <- read_csv(cas_master_path, guess_max = Inf, show_col_types = FALSE) |>
    filter(!excluded)
  cat("cas_parent_lookup_all.csv (excluded==FALSE):", nrow(cas_master), "rows\n")

  sp_res_path <- "data-raw/alldata/species_resolution_v2.csv"
  if (!file.exists(sp_res_path)) stop("ERROR: ", sp_res_path, " not found.")
  species_res_v2 <- read_csv(sp_res_path, guess_max = Inf, show_col_types = FALSE)
  cat("species_resolution_v2.csv:", nrow(species_res_v2), "rows\n")

  cat("anzg_data:", nrow(anzg_data), "rows\n")
  cat("ccme_data:", nrow(ccme_data), "rows\n")
  cat("aims_data:", nrow(aims_data), "rows\n")
  cat("csiro_data:", nrow(csiro_data), "rows\n\n")

  # ----------------------------------------------------------
  # TASK 2: Prepare ANZG and CCME
  # ----------------------------------------------------------

  medium_norm_anzg <- c(
    freshwater           = "Freshwater",
    marine               = "Marine",
    `soft freshwater`    = "Soft freshwater",
    `moderate freshwater` = "Moderate freshwater",
    `hard freshwater`    = "Hard freshwater"
  )
  unexpected_anzg_medium <- unique(anzg_data$Medium)[!unique(anzg_data$Medium) %in% names(medium_norm_anzg)]
  if (length(unexpected_anzg_medium) > 0) {
    stop("ERROR: Unexpected ANZG Medium values: ", paste(unexpected_anzg_medium, collapse = ", "))
  }

  anzg_cas <- curated_cas |> filter(source == "anzg")
  anzg_chems_missing <- setdiff(anzg_data$Chemical, anzg_cas$chemical_name)
  if (length(anzg_chems_missing) > 0) {
    stop("ERROR: ANZG chemicals not in curated_cas_lookup: ", paste(anzg_chems_missing, collapse = ", "))
  }

  anzg_prepped <- anzg_data |>
    mutate(
      accepted_name = paste(Genus, Species),
      medium        = medium_norm_anzg[Medium]
    ) |>
    left_join(
      anzg_cas |> select(chemical_name, casnumber_grouped, chemicalname_grouped),
      by = c("Chemical" = "chemical_name")
    ) |>
    mutate(
      source              = "anzg",
      conc_ug_L           = Conc,
      majorgroup          = NA_character_,
      kingdom             = NA_character_,
      phylum              = as.character(Phylum),
      class               = NA_character_,
      order_taxon         = NA_character_,
      family              = NA_character_,
      genus               = as.character(Genus),
      taxonomy_provenance = "curated_source",
      n_records           = 1L,
      sources_contributing = "anzg",
      any_acr_applied     = FALSE,
      any_conc_flagged    = FALSE,
      geomean_flagged     = FALSE,
      lifestage_mixed     = FALSE,
      duration_mixed      = FALSE
    )
  if (any(is.na(anzg_prepped$casnumber_grouped))) {
    stop("ERROR: ANZG rows failed CAS join: ",
      paste(unique(anzg_prepped$Chemical[is.na(anzg_prepped$casnumber_grouped)]), collapse=", "))
  }
  cat("ANZG: prepared", nrow(anzg_prepped), "rows\n")

  ccme_units_present <- unique(ccme_data$Units)
  ccme_prepped <- ccme_data |>
    mutate(conc_ug_L = case_when(
      Units %in% c("ug/L", "µg/L") ~ Conc,
      Units == "mg/L"               ~ Conc * 1000,
      Units == "ng/L"               ~ Conc / 1000,
      TRUE                          ~ NA_real_
    ))
  bad_units <- ccme_prepped |> filter(is.na(conc_ug_L))
  if (nrow(bad_units) > 0) {
    stop("Unsupported unit(s) in ccme_data: ", paste(unique(bad_units$Units), collapse=", "))
  }

  ccme_cas <- curated_cas |> filter(source == "ccme")
  ccme_chems_missing <- setdiff(ccme_data$Chemical, ccme_cas$chemical_name)
  if (length(ccme_chems_missing) > 0) {
    stop("ERROR: CCME chemicals not in curated_cas_lookup: ", paste(ccme_chems_missing, collapse=", "))
  }

  ccme_prepped <- ccme_prepped |>
    left_join(
      ccme_cas |> select(chemical_name, casnumber_grouped, chemicalname_grouped),
      by = c("Chemical" = "chemical_name")
    ) |>
    mutate(
      accepted_name        = Species,
      medium               = Medium,
      source               = "ccme",
      majorgroup           = as.character(Group),
      kingdom              = NA_character_,
      phylum               = NA_character_,
      class                = NA_character_,
      order_taxon          = NA_character_,
      family               = NA_character_,
      genus                = NA_character_,
      taxonomy_provenance  = "curated_source",
      n_records            = 1L,
      sources_contributing = "ccme",
      any_acr_applied      = FALSE,
      any_conc_flagged     = FALSE,
      geomean_flagged      = FALSE,
      lifestage_mixed      = FALSE,
      duration_mixed       = FALSE
    )
  if (any(is.na(ccme_prepped$casnumber_grouped))) {
    stop("ERROR: CCME rows failed CAS join: ",
      paste(unique(ccme_prepped$Chemical[is.na(ccme_prepped$casnumber_grouped)]), collapse=", "))
  }
  cat("CCME: prepared", nrow(ccme_prepped), "rows\n\n")

  # ----------------------------------------------------------
  # TASK 3: Prepare AIMS and CSIRO (taxonomy + aggregation)
  # ----------------------------------------------------------

  aims_species  <- na.omit(unique(aims_data$Species))
  csiro_species <- na.omit(unique(csiro_data$Species))
  curated_species <- union(aims_species, csiro_species)
  cat("Distinct species to resolve (NA excluded):", length(curated_species), "\n")

  res_v2_cols <- c("scientificname","accepted_name","resolved_kingdom","resolved_phylum",
                   "resolved_class","resolved_order","resolved_family","resolved_genus","taxonomy_provenance")
  cache <- species_res_v2 |>
    select(all_of(res_v2_cols)) |>
    filter(!is.na(accepted_name), taxonomy_provenance != "no_taxonomy")

  cache_hits_idx    <- match(tolower(curated_species), tolower(cache$scientificname))
  cache_hit_species <- curated_species[!is.na(cache_hits_idx)]
  cache_miss_species <- curated_species[is.na(cache_hits_idx)]
  cat("Cache hits:", length(cache_hit_species), "\n")
  cat("Cache misses (need fresh WoRMS):", length(cache_miss_species), "\n")
  if (length(cache_miss_species) > 0) cat("Miss species:", paste(cache_miss_species, collapse=", "), "\n")

  resolve_from_cache <- function(sp_name, cache) {
    idx <- which(tolower(cache$scientificname) == tolower(sp_name))
    if (length(idx) == 0) return(NULL)
    row <- cache[idx[1], ]
    tibble(
      query_name = sp_name, accepted_name = row$accepted_name,
      kingdom = row$resolved_kingdom, phylum = row$resolved_phylum,
      class = row$resolved_class, order_taxon = row$resolved_order,
      family = row$resolved_family, genus = row$resolved_genus,
      majorgroup = row$resolved_class, taxonomy_provenance = row$taxonomy_provenance,
      resolution_source = "cache"
    )
  }

  resolve_fresh_worms <- function(sp_name) {
    tryCatch({
      res <- wm_records_names(name = sp_name, fuzzy = FALSE)[[1]]
      if (is.null(res) || nrow(res) == 0) res <- wm_records_names(name = sp_name, fuzzy = TRUE)[[1]]
      if (is.null(res) || nrow(res) == 0) return(NULL)
      res <- res |> filter(rank %in% c("Species","Subspecies","Variety","Forma"))
      if (nrow(res) == 0) return(NULL)
      exact <- res |> filter(tolower(scientificname) == tolower(sp_name))
      if (nrow(exact) == 1) {
        res <- exact
      } else if (nrow(exact) > 1) {
        valid <- exact |> filter(status == "accepted")
        res <- if (nrow(valid) >= 1) valid[1, ] else exact[1, ]
      } else {
        res <- res[1, ]
      }
      accepted_nm <- if (!is.na(res$valid_name) && res$valid_name != "") res$valid_name else sp_name
      cls_res <- tryCatch(wm_classification(id = res$AphiaID), error = function(e) NULL)
      extract_rank <- function(cls, rank_name) {
        if (is.null(cls)) return(NA_character_)
        row <- cls |> filter(tolower(rank) == tolower(rank_name))
        if (nrow(row) == 0) NA_character_ else row$scientificname[1]
      }
      tibble(
        query_name = sp_name, accepted_name = accepted_nm,
        kingdom = extract_rank(cls_res,"Kingdom"), phylum = extract_rank(cls_res,"Phylum"),
        class = extract_rank(cls_res,"Class"),     order_taxon = extract_rank(cls_res,"Order"),
        family = extract_rank(cls_res,"Family"),   genus = extract_rank(cls_res,"Genus"),
        majorgroup = extract_rank(cls_res,"Class"),
        taxonomy_provenance = "worms_full", resolution_source = "worms_fresh"
      )
    }, error = function(e) { message("WoRMS error for '", sp_name, "': ", conditionMessage(e)); NULL })
  }

  resolve_via_gbif <- function(sp_name) {
    if (!requireNamespace("rgbif", quietly = TRUE)) return(NULL)
    tryCatch({
      res <- rgbif::name_suggest(q = sp_name, rank = "SPECIES", limit = 5)
      hits <- res$data
      if (is.null(hits) || nrow(hits) == 0) return(NULL)
      exact <- hits |> filter(tolower(canonicalName) == tolower(sp_name))
      if (nrow(exact) == 0) exact <- hits[1, ]
      row <- exact[1, ]
      tibble(
        query_name = sp_name, accepted_name = coalesce(row$canonicalName, sp_name),
        kingdom = coalesce(row$kingdom, NA_character_), phylum = coalesce(row$phylum, NA_character_),
        class = coalesce(row$class, NA_character_),    order_taxon = coalesce(row$order, NA_character_),
        family = coalesce(row$family, NA_character_),  genus = coalesce(row$genus, NA_character_),
        majorgroup = coalesce(row$class, NA_character_),
        taxonomy_provenance = "gbif_full", resolution_source = "gbif_fresh"
      )
    }, error = function(e) { message("GBIF error for '", sp_name, "': ", conditionMessage(e)); NULL })
  }

  cat("Running fresh WoRMS resolution for", length(cache_miss_species), "species...\n")
  fresh_results <- vector("list", length(cache_miss_species))
  n_worms_ok <- 0; n_gbif_ok <- 0; n_unresolved_sp <- 0; unresolved_species <- character(0)

  for (i in seq_along(cache_miss_species)) {
    sp <- cache_miss_species[i]
    cat(sprintf("  [%d/%d] %s ...", i, length(cache_miss_species), sp))
    res <- resolve_fresh_worms(sp)
    if (!is.null(res)) {
      fresh_results[[i]] <- res; n_worms_ok <- n_worms_ok + 1; cat(" WoRMS OK\n"); next
    }
    res_gbif <- resolve_via_gbif(sp)
    if (!is.null(res_gbif)) {
      res_gbif$taxonomy_provenance <- "gbif_full"
      fresh_results[[i]] <- res_gbif; n_gbif_ok <- n_gbif_ok + 1; cat(" GBIF OK\n"); next
    }
    fresh_results[[i]] <- tibble(
      query_name = sp, accepted_name = sp,
      kingdom = NA_character_, phylum = NA_character_, class = NA_character_,
      order_taxon = NA_character_, family = NA_character_, genus = NA_character_,
      majorgroup = NA_character_, taxonomy_provenance = "source_native_fallback",
      resolution_source = "unresolved"
    )
    n_unresolved_sp <- n_unresolved_sp + 1; unresolved_species <- c(unresolved_species, sp)
    cat(" UNRESOLVED\n")
  }

  cache_hit_rows <- lapply(cache_hit_species, resolve_from_cache, cache = cache)
  all_resolved <- bind_rows(bind_rows(cache_hit_rows), bind_rows(fresh_results))

  sp_res_curated_path <- "data-raw/alldata/species_resolution_curated.csv"
  write_csv(all_resolved, sp_res_curated_path)
  cat("Written:", sp_res_curated_path, "(", nrow(all_resolved), "rows)\n")
  cat("NOTE: read this file with guess_max = Inf in future scripts.\n\n")

  taxonomy_lookup <- all_resolved |>
    select(query_name, accepted_name, kingdom, phylum, class, order_taxon, family, genus,
           majorgroup, taxonomy_provenance) |>
    distinct(query_name, .keep_all = TRUE)

  join_taxonomy <- function(df, taxonomy_lookup, sp_col = "Species") {
    df |> left_join(taxonomy_lookup, by = setNames("query_name", sp_col))
  }

  aims_with_tax  <- join_taxonomy(aims_data,  taxonomy_lookup)
  csiro_with_tax <- join_taxonomy(csiro_data, taxonomy_lookup) |>
    mutate(accepted_name = if_else(is.na(Species), NA_character_, accepted_name))

  aims_bad  <- aims_with_tax  |> filter(!is.na(Species), is.na(accepted_name))
  csiro_bad <- csiro_with_tax |> filter(!is.na(Species), is.na(accepted_name))
  if (nrow(aims_bad) > 0 || nrow(csiro_bad) > 0) {
    if (nrow(aims_bad)  > 0) { cat("ERROR: AIMS rows with missing accepted_name:\n"); print(aims_bad  |> select(Chemical, Medium, Species)) }
    if (nrow(csiro_bad) > 0) { cat("ERROR: CSIRO rows with missing accepted_name:\n"); print(csiro_bad |> select(Chemical, Medium, Species)) }
    stop("Taxonomy join produced unexpected NA accepted_name values — review above.")
  }

  aims_cas  <- curated_cas |> filter(source == "aims")
  csiro_cas <- curated_cas |> filter(source == "csiro")
  aims_with_tax  <- aims_with_tax  |> left_join(aims_cas  |> select(chemical_name, casnumber_grouped, chemicalname_grouped), by = c("Chemical"="chemical_name"))
  csiro_with_tax <- csiro_with_tax |> left_join(csiro_cas |> select(chemical_name, casnumber_grouped, chemicalname_grouped), by = c("Chemical"="chemical_name"))

  normalize_medium <- function(x) {
    dplyr::case_when(
      tolower(x) %in% c("freshwater","fresh") ~ "Freshwater",
      tolower(x) == "marine"                  ~ "Marine",
      tolower(x) == "soft freshwater"         ~ "Soft freshwater",
      tolower(x) == "moderate freshwater"     ~ "Moderate freshwater",
      tolower(x) == "hard freshwater"         ~ "Hard freshwater",
      TRUE ~ x
    )
  }
  aims_with_tax  <- aims_with_tax  |> mutate(Medium = normalize_medium(Medium))
  csiro_with_tax <- csiro_with_tax |> mutate(Medium = normalize_medium(Medium))

  agg_source <- function(df, source_label) {
    df |>
      filter(!is.na(Conc)) |>
      group_by(casnumber_grouped, chemicalname_grouped, accepted_name, Medium,
               kingdom, phylum, class, order_taxon, family, genus, majorgroup, taxonomy_provenance) |>
      summarise(
        n_records    = n(),
        conc_ug_L    = if (max(Conc) / min(Conc) > 10) min(Conc) else exp(mean(log(Conc))),
        geomean_flagged = max(Conc) / min(Conc) > 10,
        .groups = "drop"
      ) |>
      mutate(
        source               = source_label,
        medium               = Medium,
        sources_contributing = source_label,
        any_acr_applied      = FALSE,
        any_conc_flagged     = FALSE,
        lifestage_mixed      = FALSE,
        duration_mixed       = FALSE
      ) |>
      select(-Medium)
  }

  aims_agg  <- agg_source(aims_with_tax,  "aims")
  csiro_agg <- agg_source(csiro_with_tax, "csiro") |>
    mutate(accepted_name = coalesce(accepted_name, "Unknown species (no name in source)"))

  cat("Within-source aggregation: aims", nrow(aims_with_tax), "→", nrow(aims_agg),
      "| csiro", nrow(csiro_with_tax), "→", nrow(csiro_agg), "\n\n")

  # ----------------------------------------------------------
  # TASK 4: Concentration plausibility audit (curated — no exclusions)
  # ----------------------------------------------------------

  LOWER_HARD <- 1e-5; LOWER_SOFT <- 1e-3; UPPER_SOFT <- 1e6; UPPER_HARD <- 1e8
  conc_tier <- function(conc) case_when(
    conc < LOWER_HARD ~ "low_hard", conc < LOWER_SOFT ~ "low_soft",
    conc > UPPER_HARD ~ "high_hard", conc > UPPER_SOFT ~ "high_soft", TRUE ~ "ok_range"
  )
  audit_source_conc <- function(df, name, conc_col = "Conc") {
    tiers <- conc_tier(df[[conc_col]])
    cat(sprintf("  %s: ok_range=%d, low_soft=%d, low_hard=%d, high_soft=%d, high_hard=%d\n",
      name, sum(tiers=="ok_range"), sum(tiers=="low_soft"), sum(tiers=="low_hard"),
      sum(tiers=="high_soft"), sum(tiers=="high_hard")))
  }
  cat("Concentration plausibility audit (curated, audit-only — no exclusions):\n")
  audit_source_conc(anzg_data,   "anzg")
  audit_source_conc(ccme_prepped,"ccme", conc_col="conc_ug_L")
  audit_source_conc(aims_data,   "aims")
  audit_source_conc(csiro_data,  "csiro")
  cat("\n")

  # ----------------------------------------------------------
  # TASK 5: Bind all sources
  # ----------------------------------------------------------

  schema_cols <- c(
    "casnumber_grouped","chemicalname_grouped","accepted_name","medium","conc_ug_L",
    "majorgroup","kingdom","phylum","class","order_taxon","family","genus",
    "taxonomy_provenance","n_records","sources_contributing",
    "any_acr_applied","any_conc_flagged","geomean_flagged","lifestage_mixed","duration_mixed"
  )
  ensure_schema <- function(df, schema_cols) {
    for (col in schema_cols) if (!col %in% names(df)) df[[col]] <- NA
    df
  }

  uncurated_out <- uncurated |> mutate(source = "uncurated")

  combined <- bind_rows(
    anzg_prepped   |> ensure_schema(schema_cols) |> select(all_of(c(schema_cols,"source"))),
    ccme_prepped   |> ensure_schema(schema_cols) |> select(all_of(c(schema_cols,"source"))),
    aims_agg       |> ensure_schema(schema_cols) |> select(all_of(c(schema_cols,"source"))),
    csiro_agg      |> ensure_schema(schema_cols) |> select(all_of(c(schema_cols,"source"))),
    uncurated_out  |> ensure_schema(schema_cols) |> select(all_of(c(schema_cols,"source")))
  ) |>
    mutate(exclusion_flag = NA_character_)

  cat("Combined frame by source:\n"); print(count(combined, source))
  cat("Total:", nrow(combined), "\n\n")

  # ----------------------------------------------------------
  # TASK 6: ANZG exclusion rule
  # ----------------------------------------------------------

  anzg_freshwater_variants <- c("Freshwater","Soft freshwater","Moderate freshwater","Hard freshwater")
  anzg_rows    <- combined |> filter(source == "anzg") |> select(casnumber_grouped, medium) |> distinct()
  anzg_fw_cas  <- anzg_rows |> filter(medium %in% anzg_freshwater_variants) |> pull(casnumber_grouped) |> unique()
  anzg_marine_cas <- anzg_rows |> filter(medium == "Marine") |> pull(casnumber_grouped) |> unique()

  combined <- combined |> mutate(exclusion_flag = case_when(
    !is.na(exclusion_flag) ~ exclusion_flag,
    source != "anzg" & casnumber_grouped %in% anzg_fw_cas    & medium == "Freshwater" ~ "anzg_rule_freshwater",
    source != "anzg" & casnumber_grouped %in% anzg_marine_cas & medium == "Marine"    ~ "anzg_rule_marine",
    TRUE ~ exclusion_flag
  ))

  fw_excl  <- combined |> filter(exclusion_flag == "anzg_rule_freshwater")
  mar_excl <- combined |> filter(exclusion_flag == "anzg_rule_marine")
  cat("ANZG exclusion: freshwater =", nrow(fw_excl), "| marine =", nrow(mar_excl), "\n")

  # ----------------------------------------------------------
  # TASK 7: CCME exclusion rule
  # ----------------------------------------------------------

  ccme_medium_vals <- unique(ccme_prepped$medium)
  ccme_excl_cas_by_medium <- combined |> filter(source == "ccme") |>
    select(casnumber_grouped, medium) |> distinct()
  n_ccme_excluded <- 0

  for (med_val in ccme_medium_vals) {
    ccme_cas_this_medium <- ccme_excl_cas_by_medium |>
      filter(medium == med_val) |> pull(casnumber_grouped) |> unique()
    flag_label <- paste0("ccme_rule_", tolower(gsub(" ","_", med_val)))
    combined <- combined |> mutate(exclusion_flag = case_when(
      !is.na(exclusion_flag) ~ exclusion_flag,
      source %in% c("aims","csiro","uncurated") &
        casnumber_grouped %in% ccme_cas_this_medium & medium == med_val ~ flag_label,
      TRUE ~ exclusion_flag
    ))
    n_this <- sum(combined$exclusion_flag == flag_label, na.rm = TRUE)
    n_ccme_excluded <- n_ccme_excluded + n_this
    cat("CCME exclusion", flag_label, ":", n_this, "\n")
  }

  # ----------------------------------------------------------
  # TASK 8: Preference hierarchy (aims > csiro > uncurated)
  # ----------------------------------------------------------

  active <- combined |> filter(is.na(exclusion_flag), source %in% c("aims","csiro","uncurated"))
  overlap_key    <- c("casnumber_grouped","medium","accepted_name")
  priority_order <- c(aims=1L, csiro=2L, uncurated=3L)

  overlap <- active |>
    group_by(across(all_of(overlap_key))) |>
    filter(n_distinct(source) > 1) |>
    ungroup() |>
    mutate(priority = priority_order[source])

  winners <- overlap |>
    group_by(across(all_of(overlap_key))) |>
    slice_min(priority, n = 1, with_ties = FALSE) |>
    ungroup() |>
    select(all_of(overlap_key), winner_source = source)

  if (nrow(winners) > 0) {
    combined <- combined |>
      left_join(winners, by = overlap_key) |>
      mutate(exclusion_flag = case_when(
        !is.na(exclusion_flag) ~ exclusion_flag,
        source %in% c("aims","csiro","uncurated") & !is.na(winner_source) & source != winner_source ~
          paste0("priority_", winner_source, "_over_", source),
        TRUE ~ exclusion_flag
      )) |>
      select(-winner_source)
  }
  cat("Preference hierarchy applied.\n\n")

  # ----------------------------------------------------------
  # TASK 9: Filter retained rows and write alldata_integrated.csv
  # ----------------------------------------------------------

  gitignore_path  <- ".gitignore"
  gitignore_entry <- "data-raw/alldata/alldata_integrated.csv"
  gi_lines <- if (file.exists(gitignore_path)) readLines(gitignore_path) else character(0)
  if (!any(trimws(gi_lines) == gitignore_entry)) {
    cat("Adding", gitignore_entry, "to .gitignore\n")
    write(gitignore_entry, file = gitignore_path, append = TRUE)
  }

  retained <- combined |> filter(is.na(exclusion_flag))
  cat("Retained rows:", nrow(retained), "\n")
  cat("Row counts by source:\n"); print(count(retained, source))
  cat("Row counts by medium:\n"); print(count(retained, medium))

  # Validation
  checks_passed <- TRUE
  check <- function(cond, label, detail=NULL) {
    cat(" ", if(cond) "PASS" else "FAIL", "—", label, "\n")
    if (!cond && !is.null(detail)) cat("   Detail:", detail, "\n")
    if (!cond) checks_passed <<- FALSE
  }
  cat("\nStage 6 validation checks:\n")
  check(!any(is.na(retained$casnumber_grouped)), "casnumber_grouped no NA")
  check(!any(is.na(retained$accepted_name)),     "accepted_name no NA")
  check(!any(is.na(retained$conc_ug_L)) && all(retained$conc_ug_L > 0, na.rm=TRUE), "conc_ug_L valid")
  valid_mediums <- c("Freshwater","Soft freshwater","Moderate freshwater","Hard freshwater","Marine","Unknown")
  check(all(retained$medium %in% valid_mediums), "medium values valid")
  check(!any(is.na(retained$source)), "source no NA")
  dup_c <- retained |> filter(source %in% c("anzg","ccme","aims","csiro")) |>
    group_by(casnumber_grouped, medium, accepted_name) |> filter(n_distinct(source)>1) |> ungroup()
  check(nrow(dup_c) == 0, "no curated-source duplicates")
  max_exp <- nrow(uncurated) + nrow(anzg_data) + nrow(ccme_data) + nrow(aims_data) + nrow(csiro_data)
  check(nrow(retained) <= max_exp, "row count plausible")
  if (!checks_passed) stop("Stage 6 validation FAILED — see above.")
  cat("All Stage 6 validation checks PASSED.\n\n")

  write_csv(retained, integrated_path)
  file_size_mb <- round(file.size(integrated_path) / 1024^2, 1)
  cat("Written:", integrated_path, "—", nrow(retained), "rows,", file_size_mb, "MB\n\n")

} else {
  message("alldata_integrated.csv found on disk — skipping Stage 6 integration. Loading...")
}

# ============================================================
# STAGE 7: Sufficiency filter → allchronic_data.rda
# ============================================================

cat("====================================================\n")
cat("STAGE 7: Sufficiency filter and allchronic_data build\n")
cat("====================================================\n\n")

integrated <- read_csv(integrated_path, guess_max = Inf, show_col_types = FALSE)
cat("Input:", nrow(integrated), "rows ×", ncol(integrated), "cols\n\n")

# Step 7.1: Identify passing uncurated combinations
uncurated_eligible <- integrated |>
  filter(source == "uncurated") |>
  group_by(casnumber_grouped, medium) |>
  summarise(
    n_species = n_distinct(accepted_name),
    n_classes = n_distinct(class[!is.na(class)]),
    .groups   = "drop"
  ) |>
  filter(n_species >= 5, n_classes >= 4) |>
  select(casnumber_grouped, medium)

cat("Uncurated combinations assessed:       ", integrated |> filter(source=="uncurated") |>
  distinct(casnumber_grouped, medium) |> nrow(), "\n")
cat("Uncurated combinations passing filter: ", nrow(uncurated_eligible), "\n\n")

# Step 7.2: Filter
allchronic_filtered <- integrated |>
  filter(
    source %in% c("anzg", "ccme", "aims", "csiro") |
    (source == "uncurated" &
       paste(casnumber_grouped, medium) %in%
       paste(uncurated_eligible$casnumber_grouped, uncurated_eligible$medium))
  )

n_uncurated_before <- sum(integrated$source == "uncurated")
n_uncurated_after  <- sum(allchronic_filtered$source == "uncurated")
cat("Uncurated rows before filter:", n_uncurated_before, "\n")
cat("Uncurated rows after filter: ", n_uncurated_after, "(", round(100*n_uncurated_after/n_uncurated_before,1), "%)\n")
cat("Uncurated rows dropped:      ", n_uncurated_before - n_uncurated_after, "\n")
cat("Curated rows (unchanged):    ", sum(allchronic_filtered$source %in% c("anzg","ccme","aims","csiro")), "\n")
cat("Total rows after filter:     ", nrow(allchronic_filtered), "\n\n")

# Step 7.3: Rename and select 20 columns (PascalCase, package convention)
allchronic_data <- allchronic_filtered |>
  select(-any_of(c("majorgroup", "Group", "Chemical", "exclusion_flag"))) |>
  rename(
    Species             = accepted_name,
    Conc                = conc_ug_L,
    Chemical            = chemicalname_grouped,
    CAS                 = casnumber_grouped,
    Medium              = medium,
    Source              = source,
    Class               = class,
    Kingdom             = kingdom,
    Phylum              = phylum,
    Order               = order_taxon,
    Family              = family,
    Genus               = genus,
    TaxonomyProvenance  = taxonomy_provenance,
    NRecords            = n_records,
    SourcesContributing = sources_contributing,
    AnyAcrApplied       = any_acr_applied,
    AnyConcFlagged      = any_conc_flagged,
    GeomeanFlagged      = geomean_flagged,
    LifestageMixed      = lifestage_mixed,
    DurationMixed       = duration_mixed
  ) |>
  select(
    Species, Conc, Chemical, CAS, Medium, Source,
    Class, Kingdom, Phylum, Order, Family, Genus,
    TaxonomyProvenance, NRecords, SourcesContributing,
    AnyAcrApplied, AnyConcFlagged, GeomeanFlagged,
    LifestageMixed, DurationMixed
  ) |>
  tibble::as_tibble()

# Step 7.4: Validation
cat("Stage 7 validation checks:\n")
checks_passed_7 <- TRUE
check7 <- function(cond, label, detail=NULL) {
  cat(" ", if(cond) "PASS" else "FAIL", "—", label, "\n")
  if (!cond && !is.null(detail)) cat("   Detail:", detail, "\n")
  if (!cond) checks_passed_7 <<- FALSE
}

dup_check <- allchronic_data |>
  group_by(Chemical, CAS, Medium) |>
  summarise(n=n(), nd=n_distinct(Species), .groups="drop") |>
  filter(n != nd)
check7(nrow(dup_check)==0, "no duplicate Species within Chemical×Medium",
  if(nrow(dup_check)>0) paste(nrow(dup_check),"groups have dups") else NULL)
check7(!anyNA(allchronic_data$Species),  "Species no NA")
check7(!anyNA(allchronic_data$Conc),     "Conc no NA")
check7(all(allchronic_data$Conc > 0),    "Conc all > 0")

valid_src <- c("anzg","ccme","aims","csiro","uncurated")
bad_src   <- setdiff(unique(allchronic_data$Source), valid_src)
check7(length(bad_src)==0, paste("Source values valid (uncurated=aggregated uncurated pipeline)"),
  if(length(bad_src)>0) paste("Unexpected:", paste(bad_src,collapse=",")) else NULL)

expected_curated <- c(aims=20L, anzg=592L, ccme=98L, csiro=60L)
actual_curated   <- allchronic_data |> filter(Source %in% c("anzg","ccme","aims","csiro")) |>
  count(Source) |> (\(x) setNames(x$n, x$Source))()
check7(all(actual_curated[names(expected_curated)] == expected_curated),
  "curated row counts unchanged (anzg=592, ccme=98, aims=20, csiro=60)")

if (!checks_passed_7) stop("Stage 7 validation FAILED — see above.")
cat("All Stage 7 validation checks PASSED.\n\n")

cat("allchronic_data summary:\n")
cat("  Rows:              ", nrow(allchronic_data), "\n")
cat("  Distinct chemicals:", n_distinct(allchronic_data$Chemical), "\n")
cat("  Distinct species:  ", n_distinct(allchronic_data$Species), "\n")
cat("  Medium breakdown:\n"); print(count(allchronic_data, Medium) |> arrange(desc(n)))
cat("  Source breakdown:\n"); print(count(allchronic_data, Source) |> arrange(desc(n)))

# Step 7.5: Save
save(allchronic_data, file = "data/allchronic_data.rda", compress = "bzip2")
file_size_bytes <- file.size("data/allchronic_data.rda")
cat(sprintf("\nSaved: data/allchronic_data.rda (%.1f KB)\n", file_size_bytes/1024))

cat("\n=== Files to commit (user action required) ===\n")
cat("  data/allchronic_data.rda                        [new — tracked]\n")
cat("  data-raw/alldata/DATASET.R                      [new — tracked]\n")
cat("  data-raw/alldata/species_resolution_curated.csv [updated — tracked]\n")
cat("  R/allchronic_data.R                             [new — tracked]\n")
cat("  R/get_ssddata.R                                 [modified — tracked]\n")
cat("  data-raw/alldata/stage7-eligibility-report.md   [new — tracked]\n")
cat("  [deleted] scripts/alldata/stage6-phase2-integrate.R\n")
cat("  DO NOT commit: data-raw/alldata/alldata_integrated.csv (untracked, large)\n")
