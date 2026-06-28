# =============================================================================
# scripts/stage4d-taxonomy-extract.R
# =============================================================================
# Purpose:
#   Stage 4d Part 1.5 -- extract each source's OWN (source-native) taxonomy
#   for every distinct species in the final clean subset of
#   uncurated_raw_dedup.csv, and harmonise the three per-source taxonomic
#   vocabularies into a single controlled schema. This is a read-only
#   intermediate artefact: Part 2 will consume it for context-aware WoRMS
#   querying (e.g. restricting candidate matches by source-native class/
#   phylum to resolve WoRMS-ambiguous species). It does NOT replace or
#   modify the Part 1 WoRMS/GBIF cache (species_resolution_cache.rds),
#   which is preserved as a diagnostic baseline.
#
#   This script does not query WoRMS or GBIF, and does not modify
#   uncurated_raw_dedup.csv, anztox_extracted.csv, or any other existing
#   file.
#
# Inputs:
#   data-raw/alldata/uncurated_raw_dedup.csv
#     449,888 rows x 21 cols. Filtered here to dedup_retained == TRUE &
#     priority_kept == TRUE (the final clean subset) to identify the
#     (source, scientificname) combinations in scope.
#   data-raw/alldata/species_resolution_summary.csv
#     Part 1 output -- used only for the Step 9 cross-check against
#     genuinely unresolved (resolved_by == "none") species.
#   anztox: live `infogathering` PostgreSQL connection -- species,
#     animaltype, animalcategory, speciesclass, speciesphylum tables.
#   wqbench: data-raw/wqbench/ecotox_ascii_12_11_2025.sqlite (falls back to
#     any other single .sqlite present in data-raw/wqbench/ if that exact
#     file is absent) -- species table.
#   envirotox: data-raw/envirotox/envirotox.xlsx, sheet "taxonomy".
#
# Outputs:
#   data-raw/alldata/species_source_taxonomy.csv
#     One row per (source, scientificname) combination, harmonised schema
#     (see Step 7 below).
#   data-raw/alldata/stage4d-taxonomy-inventory.md
#     Markdown diagnostic report (see script footer for section list).
#
# Environment:
#   The anztox section (Step 3) requires a live connection to the
#   `infogathering` PostgreSQL instance, which per project convention is
#   only reachable from Windows (not WSL). This script must be run from
#   Windows Positron. The wqbench (sqlite) and envirotox (xlsx) sections
#   have no DB dependency and could run anywhere the files are present,
#   but the script is run as a single pass for simplicity.
#
# CRITICAL PATH NOTE: the master CAS lookup lives at
# data-raw/cas_parent_lookup_all.csv (NOT
# data-raw/anztox/cas_parent_lookup_all.csv). Not used in this script
# (species name is the join key here, not CAS) -- preserved per project
# convention.
#
# Decisions made while writing this script (see stage4d-taxonomy-inventory.md
# Section 7 for the full rationale):
#   - anztox `source_trophic` is left NA. anztox's `animaltype`
#     (Fish/Invertebrate/Plant/Others) and `animalcategory` (finer, but a
#     mix of taxonomic and functional labels) are already preserved
#     losslessly as their own `source_animaltype` / `source_animalcategory`
#     columns; mapping either of them onto `source_trophic` as well would
#     just duplicate one of those columns under a different name with no
#     added information.
#   - anztox `kingdom` is derived from the harmonised `phylum` field via a
#     small controlled phylum -> kingdom lookup (see Step 6), built to be
#     internally consistent with the 6-kingdom scheme (Animalia, Plantae,
#     Chromista, Bacteria, Protozoa, Fungi) already produced by the Part 1
#     WoRMS/GBIF resolution, rather than inventing a separate scheme.
#   - Source DB/sheet rows are collapsed to one row per (source,
#     scientificname) by coalescing the first non-NA value per field
#     across any duplicate raw rows for that name; genuine conflicts
#     (multiple distinct non-NA values for the same field) are counted
#     and reported, not silently dropped.
# =============================================================================

required_pkgs <- c(
  "dplyr", "readr", "stringr", "tidyr", "purrr", "tibble",
  "DBI", "RPostgres", "RSQLite", "readxl"
)
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
library(stringr)
library(tidyr)
library(purrr)
library(tibble)

dedup_path <- "data-raw/alldata/uncurated_raw_dedup.csv"
resolution_summary_path <- "data-raw/alldata/species_resolution_summary.csv"
taxonomy_out_path <- "data-raw/alldata/species_source_taxonomy.csv"
report_path <- "data-raw/alldata/stage4d-taxonomy-inventory.md"
wqbench_dir <- "data-raw/wqbench"
envirotox_path <- "data-raw/envirotox/envirotox.xlsx"

# ---- Step 2: species in scope -----------------------------------------------

dedup <- read_csv(dedup_path, show_col_types = FALSE)

clean <- dedup |> filter(dedup_retained %in% TRUE, priority_kept %in% TRUE)
n_clean_rows <- nrow(clean)
cat("Final clean subset rows:", n_clean_rows, "\n")

species_by_source <- clean |>
  distinct(source, scientificname) |>
  arrange(source, scientificname)
n_species_by_source <- nrow(species_by_source)
cat("Distinct (source, scientificname) combinations:", n_species_by_source, "\n")

species_overall <- clean |> distinct(scientificname)
n_species_overall <- nrow(species_overall)
cat("Distinct scientificname values overall:", n_species_overall, "\n")

source_counts_scope <- species_by_source |> count(source, name = "n_species_in_scope")

# ---- shared helpers ----------------------------------------------------------

# Collapses a source's raw lookup rows to one row per `key_col`, coalescing the
# first non-NA value per output column across duplicate raw rows for the same
# key, and counting genuine conflicts (>1 distinct non-NA value for a field
# within the same key) for the report -- duplicates are common in source
# species tables (e.g. anztox's `species` table has 60 duplicated
# scientificname values out of 6,078 rows) and silently picking an arbitrary
# row would hide real data-quality signal.
collapse_by_key <- function(df, key_col, value_cols) {
  df |>
    mutate(across(all_of(value_cols), as.character)) |>
    group_by(.data[[key_col]]) |>
    summarise(
      n_raw_rows = n(),
      across(
        all_of(value_cols),
        list(
          value = \(x) {
            nonna <- x[!is.na(x) & x != ""]
            if (length(nonna) == 0) NA_character_ else nonna[[1]]
          },
          conflict = \(x) {
            nonna <- unique(x[!is.na(x) & x != ""])
            length(nonna) > 1
          }
        ),
        .names = "{.col}__{.fn}"
      ),
      .groups = "drop"
    )
}

normalise_taxon <- function(x) {
  x <- str_squish(as.character(x))
  x <- str_remove(x, "[.,;:]+$")
  x <- str_to_lower(x)
  x <- str_replace(x, "^(\\p{L})", \(m) str_to_upper(m))
  na_if(x, "")
}

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

harmonised_cols <- c(
  "source", "scientificname", "kingdom", "phylum", "subphylum", "superclass",
  "class", "order_taxon", "family", "genus", "common_name", "source_majorgroup",
  "source_minorgroup", "source_trophic", "source_ecological",
  "source_animaltype", "source_animalcategory", "isheterotroph", "ncbi_taxid"
)
rank_cols <- c("kingdom", "phylum", "subphylum", "superclass", "class", "order_taxon", "family", "genus")

# =============================================================================
# Step 3: anztox taxonomy extraction (DB)
# =============================================================================

anztox_species_in_scope <- species_by_source |>
  filter(source == "anztox") |>
  pull(scientificname)
cat("\nanztox species in scope:", length(anztox_species_in_scope), "\n")

get_db_password <- function() {
  pw <- Sys.getenv("ANZTOX_DB_PASSWORD", unset = "")
  if (nzchar(pw)) return(pw)
  if (requireNamespace("keyring", quietly = TRUE)) {
    return(keyring::key_get("infogathering_postgres", username = "postgres"))
  }
  stop("No DB password found. Set ANZTOX_DB_PASSWORD or keyring credential.")
}

con <- DBI::dbConnect(
  RPostgres::Postgres(),
  dbname = "infogathering",
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = get_db_password()
)
on.exit(DBI::dbDisconnect(con), add = TRUE)

species_db <- DBI::dbReadTable(con, "species")
animaltype_db <- DBI::dbReadTable(con, "animaltype") |> rename(animaltype = name)
animalcategory_db <- DBI::dbReadTable(con, "animalcategory") |> rename(animalcategory = name)
speciesclass_db <- DBI::dbReadTable(con, "speciesclass") |> rename(class = name)
speciesphylum_db <- DBI::dbReadTable(con, "speciesphylum") |> rename(phylum = name)

# 3a: build the join (3a spec: species -> animaltype, animalcategory,
# speciesclass -> speciesphylum)
anztox_joined_all <- species_db |>
  left_join(animaltype_db |> select(id, animaltype), by = c("animaltype_id" = "id")) |>
  left_join(animalcategory_db |> select(id, animalcategory), by = c("animalcategory_id" = "id")) |>
  left_join(speciesclass_db |> select(id, class, phylum_id), by = c("class_id" = "id")) |>
  left_join(speciesphylum_db |> select(id, phylum), by = c("phylum_id" = "id"))

# 3b: filter to anztox species in scope, completeness check
anztox_in_scope_raw <- anztox_joined_all |>
  filter(scientificname %in% anztox_species_in_scope)

anztox_missing_from_species_table <- setdiff(
  anztox_species_in_scope,
  anztox_joined_all$scientificname
)
cat("anztox in-scope species missing from `species` table join:", length(anztox_missing_from_species_table), "\n")

anztox_dup_value_cols <- c(
  "commonname", "majorgroup", "minorgroup", "isheterotroph",
  "animaltype", "animalcategory", "class", "phylum"
)
anztox_collapsed <- collapse_by_key(anztox_in_scope_raw, "scientificname", anztox_dup_value_cols)
anztox_n_duplicate_keys <- sum(anztox_collapsed$n_raw_rows > 1)
anztox_conflict_counts <- anztox_collapsed |>
  select(scientificname, ends_with("__conflict")) |>
  pivot_longer(-scientificname, names_to = "field", values_to = "conflict") |>
  mutate(field = str_remove(field, "__conflict$")) |>
  filter(conflict) |>
  count(field, name = "n_conflicting_species")
cat("anztox in-scope species with duplicate raw `species` rows:", anztox_n_duplicate_keys, "\n")

anztox_taxonomy <- tibble(
  source = "anztox",
  scientificname = anztox_collapsed$scientificname,
  kingdom = NA_character_, # filled from phylum via lookup, Step 6
  phylum = normalise_taxon(anztox_collapsed$phylum__value),
  subphylum = NA_character_,
  superclass = NA_character_,
  class = normalise_taxon(anztox_collapsed$class__value),
  order_taxon = NA_character_,
  family = NA_character_,
  genus = NA_character_,
  common_name = str_squish(anztox_collapsed$commonname__value),
  source_majorgroup = str_squish(anztox_collapsed$majorgroup__value),
  source_minorgroup = str_squish(anztox_collapsed$minorgroup__value),
  source_trophic = NA_character_,
  source_ecological = NA_character_,
  source_animaltype = normalise_taxon(anztox_collapsed$animaltype__value),
  source_animalcategory = str_squish(anztox_collapsed$animalcategory__value),
  isheterotroph = as.logical(anztox_collapsed$isheterotroph__value),
  ncbi_taxid = NA_character_
)

anztox_field_nonNA <- anztox_taxonomy |>
  select(-source, -scientificname) |>
  summarise(across(everything(), \(x) sum(!is.na(x))))
cat("anztox non-NA field counts (of", nrow(anztox_taxonomy), "in-scope species):\n")
print(anztox_field_nonNA)
cat("anztox sample rows:\n")
print(head(anztox_taxonomy, 5))

# =============================================================================
# Step 4: wqbench taxonomy extraction (SQLite)
# =============================================================================

wqbench_species_in_scope <- species_by_source |>
  filter(source == "wqbench") |>
  pull(scientificname)
cat("\nwqbench species in scope:", length(wqbench_species_in_scope), "\n")

preferred_sqlite <- file.path(wqbench_dir, "ecotox_ascii_12_11_2025.sqlite")
if (file.exists(preferred_sqlite)) {
  wqbench_sqlite_path <- preferred_sqlite
} else {
  candidates <- list.files(wqbench_dir, pattern = "\\.sqlite$", full.names = TRUE)
  if (length(candidates) == 0) {
    stop("No .sqlite file found in ", wqbench_dir)
  }
  wqbench_sqlite_path <- candidates[1]
  warning("Preferred file ecotox_ascii_12_11_2025.sqlite not found; falling back to ", basename(wqbench_sqlite_path))
}
cat("Using wqbench sqlite file:", basename(wqbench_sqlite_path), "\n")

con_wq <- DBI::dbConnect(RSQLite::SQLite(), wqbench_sqlite_path)
wqbench_species_db <- DBI::dbReadTable(con_wq, "species")
DBI::dbDisconnect(con_wq)

expected_wqbench_cols <- c(
  "species_number", "common_name", "latin_name", "kingdom", "phylum_division",
  "subphylum_div", "superclass", "class", "tax_order", "family", "genus",
  "species", "subspecies", "variety", "ecotox_group", "ncbi_taxid",
  "species_present_in_bc", "ecological_group", "trophic_group"
)
wqbench_missing_cols <- setdiff(expected_wqbench_cols, names(wqbench_species_db))
if (length(wqbench_missing_cols) > 0) {
  cat("WARNING: wqbench species table is missing expected columns:", paste(wqbench_missing_cols, collapse = ", "), "\n")
}

wqbench_in_scope_raw <- wqbench_species_db |>
  filter(latin_name %in% wqbench_species_in_scope)

wqbench_match_count <- length(intersect(wqbench_species_in_scope, wqbench_species_db$latin_name))
cat("wqbench in-scope species found in species table:", wqbench_match_count, "/", length(wqbench_species_in_scope), "\n")

wqbench_dup_value_cols <- intersect(
  c(
    "common_name", "kingdom", "phylum_division", "subphylum_div", "superclass",
    "class", "tax_order", "family", "genus", "ecological_group",
    "trophic_group", "ncbi_taxid"
  ),
  names(wqbench_in_scope_raw)
)
wqbench_collapsed <- collapse_by_key(wqbench_in_scope_raw, "latin_name", wqbench_dup_value_cols)
wqbench_n_duplicate_keys <- sum(wqbench_collapsed$n_raw_rows > 1)
cat("wqbench in-scope species with duplicate raw `species` rows (same latin_name):", wqbench_n_duplicate_keys, "\n")

col_or_na <- function(df, col) if (col %in% names(df)) df[[col]] else NA_character_

wqbench_taxonomy <- tibble(
  source = "wqbench",
  scientificname = wqbench_collapsed$latin_name,
  kingdom = normalise_taxon(col_or_na(wqbench_collapsed, "kingdom__value")),
  phylum = normalise_taxon(col_or_na(wqbench_collapsed, "phylum_division__value")),
  subphylum = normalise_taxon(col_or_na(wqbench_collapsed, "subphylum_div__value")),
  superclass = normalise_taxon(col_or_na(wqbench_collapsed, "superclass__value")),
  class = normalise_taxon(col_or_na(wqbench_collapsed, "class__value")),
  order_taxon = normalise_taxon(col_or_na(wqbench_collapsed, "tax_order__value")),
  family = normalise_taxon(col_or_na(wqbench_collapsed, "family__value")),
  genus = normalise_taxon(col_or_na(wqbench_collapsed, "genus__value")),
  common_name = str_squish(col_or_na(wqbench_collapsed, "common_name__value")),
  source_majorgroup = NA_character_,
  source_minorgroup = NA_character_,
  source_trophic = str_squish(col_or_na(wqbench_collapsed, "trophic_group__value")),
  source_ecological = str_squish(col_or_na(wqbench_collapsed, "ecological_group__value")),
  source_animaltype = NA_character_,
  source_animalcategory = NA_character_,
  isheterotroph = NA,
  ncbi_taxid = col_or_na(wqbench_collapsed, "ncbi_taxid__value")
)

wqbench_field_nonNA <- wqbench_taxonomy |>
  select(-source, -scientificname) |>
  summarise(across(everything(), \(x) sum(!is.na(x))))
cat("wqbench non-NA field counts (of", nrow(wqbench_taxonomy), "matched in-scope species):\n")
print(wqbench_field_nonNA)
cat("wqbench sample rows:\n")
print(head(wqbench_taxonomy, 5))

# =============================================================================
# Step 5: envirotox taxonomy extraction (xlsx)
# =============================================================================

envirotox_species_in_scope <- species_by_source |>
  filter(source == "envirotox") |>
  pull(scientificname)
cat("\nenvirotox species in scope:", length(envirotox_species_in_scope), "\n")

envirotox_taxonomy_sheet <- readxl::read_excel(envirotox_path, sheet = "taxonomy")

expected_envirotox_cols <- c(
  "Latin name", "Trophic Level", "Medium", "Taxonomic kingdom",
  "Taxonomic phylum or division", "Taxonomic subphylum", "Taxonomic superclass",
  "Taxonomic class", "Taxonomic order", "Taxonomic family"
)
envirotox_missing_cols <- setdiff(expected_envirotox_cols, names(envirotox_taxonomy_sheet))
if (length(envirotox_missing_cols) > 0) {
  cat("WARNING: envirotox taxonomy sheet is missing expected columns:", paste(envirotox_missing_cols, collapse = ", "), "\n")
}

envirotox_in_scope_raw <- envirotox_taxonomy_sheet |>
  filter(`Latin name` %in% envirotox_species_in_scope)

envirotox_match_count <- length(intersect(envirotox_species_in_scope, envirotox_taxonomy_sheet$`Latin name`))
cat("envirotox in-scope species found in taxonomy sheet:", envirotox_match_count, "/", length(envirotox_species_in_scope), "\n")

envirotox_dup_value_cols <- intersect(
  c(
    "Trophic Level", "Taxonomic kingdom", "Taxonomic phylum or division",
    "Taxonomic subphylum", "Taxonomic superclass", "Taxonomic class",
    "Taxonomic order", "Taxonomic family"
  ),
  names(envirotox_in_scope_raw)
)
envirotox_collapsed <- collapse_by_key(envirotox_in_scope_raw, "Latin name", envirotox_dup_value_cols)
envirotox_n_duplicate_keys <- sum(envirotox_collapsed$n_raw_rows > 1)
cat("envirotox in-scope species with duplicate raw taxonomy-sheet rows (same Latin name):", envirotox_n_duplicate_keys, "\n")

envirotox_taxonomy <- tibble(
  source = "envirotox",
  scientificname = envirotox_collapsed$`Latin name`,
  kingdom = normalise_taxon(col_or_na(envirotox_collapsed, "Taxonomic kingdom__value")),
  phylum = normalise_taxon(col_or_na(envirotox_collapsed, "Taxonomic phylum or division__value")),
  subphylum = normalise_taxon(col_or_na(envirotox_collapsed, "Taxonomic subphylum__value")),
  superclass = normalise_taxon(col_or_na(envirotox_collapsed, "Taxonomic superclass__value")),
  class = normalise_taxon(col_or_na(envirotox_collapsed, "Taxonomic class__value")),
  order_taxon = normalise_taxon(col_or_na(envirotox_collapsed, "Taxonomic order__value")),
  family = normalise_taxon(col_or_na(envirotox_collapsed, "Taxonomic family__value")),
  genus = NA_character_,
  common_name = NA_character_,
  source_majorgroup = NA_character_,
  source_minorgroup = NA_character_,
  source_trophic = str_squish(col_or_na(envirotox_collapsed, "Trophic Level__value")),
  source_ecological = NA_character_,
  source_animaltype = NA_character_,
  source_animalcategory = NA_character_,
  isheterotroph = NA,
  ncbi_taxid = NA_character_
)

envirotox_field_nonNA <- envirotox_taxonomy |>
  select(-source, -scientificname) |>
  summarise(across(everything(), \(x) sum(!is.na(x))))
cat("envirotox non-NA field counts (of", nrow(envirotox_taxonomy), "matched in-scope species):\n")
print(envirotox_field_nonNA)
cat("envirotox sample rows:\n")
print(head(envirotox_taxonomy, 5))

# =============================================================================
# Step 6: phylum -> kingdom lookup for anztox (controlled, observed phyla)
# =============================================================================
# Built to align with the 6-kingdom scheme (Animalia, Plantae, Chromista,
# Bacteria, Protozoa, Fungi) already produced by the Part 1 WoRMS/GBIF
# resolution (stage4d-species-resolution-report.md Section 3), rather than
# introducing a second, inconsistent kingdom scheme. Coverage was confirmed
# against the 19 distinct phyla actually present in anztox's `speciesphylum`
# lookup table; phyla outside this list are left NA and flagged in the report
# for manual extension if they turn out to matter.
phylum_to_kingdom <- c(
  "Cyanobacteria" = "Bacteria",
  "Proteobacteria" = "Bacteria",
  "Firmicutes" = "Bacteria",
  "Firmicutes_a" = "Bacteria",
  "Arthropoda" = "Animalia",
  "Chordata" = "Animalia",
  "Mollusca" = "Animalia",
  "Annelida" = "Animalia",
  "Cnidaria" = "Animalia",
  "Echinodermata" = "Animalia",
  "Nematoda" = "Animalia",
  "Platyhelminthes" = "Animalia",
  "Rotifera" = "Animalia",
  "Bryozoa" = "Animalia",
  "Porifera" = "Animalia",
  "Ctenophora" = "Animalia",
  "Chaetognatha" = "Animalia",
  "Gastrotricha" = "Animalia",
  "Sipuncula" = "Animalia",
  "Chlorophyta" = "Plantae",
  "Tracheophyta" = "Plantae",
  "Charophyta" = "Plantae",
  "Rhodophyta" = "Plantae",
  "Magnoliophyta" = "Plantae",
  "Ochrophyta" = "Chromista",
  "Heterokontophyta" = "Chromista",
  "Haptophyta" = "Chromista",
  "Cryptophyta" = "Chromista",
  "Myzozoa" = "Chromista",
  "Ciliophora" = "Chromista",
  "Bacillariophyta" = "Chromista",
  "Chytridiomycota" = "Fungi",
  "Ascomycota" = "Fungi",
  "Microsporidia" = "Fungi",
  "Amoebozoa" = "Protozoa",
  "Euglenozoa" = "Protozoa",
  "Mycetozoa" = "Protozoa"
)

anztox_taxonomy <- anztox_taxonomy |>
  mutate(kingdom = unname(phylum_to_kingdom[phylum]))

anztox_phylum_unmapped <- anztox_taxonomy |>
  filter(!is.na(phylum), is.na(kingdom)) |>
  distinct(phylum)
cat("\nanztox observed phyla not covered by phylum_to_kingdom lookup:", nrow(anztox_phylum_unmapped), "\n")
if (nrow(anztox_phylum_unmapped) > 0) print(anztox_phylum_unmapped)

# Recompute now that `kingdom` has been filled in -- the earlier computation
# (Step 3, before this lookup ran) would otherwise under-report anztox's
# kingdom coverage as 0 in the Section 2 report table.
anztox_field_nonNA <- anztox_taxonomy |>
  select(-source, -scientificname) |>
  summarise(across(everything(), \(x) sum(!is.na(x))))

# =============================================================================
# Step 7: combine and write species_source_taxonomy.csv
# =============================================================================
# The per-source tables built above (anztox_taxonomy / wqbench_taxonomy /
# envirotox_taxonomy) only contain species that were actually FOUND in that
# source's own taxonomy table/sheet (used for the Step 3b/4b/5b match-rate and
# field-availability diagnostics, which are explicitly denominated on
# "matched" species). The output CSV must instead cover every in-scope
# (source, scientificname) combination from Step 2 -- left-joining against
# the full scope here pads in explicit NA rows for species that were in
# scope but not found in their own source's taxonomy table, so Part 2 can
# rely on one CSV row existing per scope combination, and so Section 8's
# cross-source comparison below doesn't mistake "missing data" for
# "agreement" (a species nominally in 2 sources but matched in only 1 would
# otherwise look like a single non-NA value with no conflict).

species_source_taxonomy <- species_by_source |>
  left_join(bind_rows(anztox_taxonomy, wqbench_taxonomy, envirotox_taxonomy), by = c("source", "scientificname")) |>
  select(all_of(harmonised_cols)) |>
  arrange(source, scientificname)

write_csv(species_source_taxonomy, taxonomy_out_path, na = "NA")
cat("\nWrote", nrow(species_source_taxonomy), "rows to", taxonomy_out_path, "\n")

# =============================================================================
# Step 8: cross-source consistency diagnostic
# =============================================================================

species_n_sources <- species_by_source |>
  count(scientificname, name = "n_sources")

multi_source_species <- species_n_sources |> filter(n_sources > 1) |> pull(scientificname)
single_source_species_n <- sum(species_n_sources$n_sources == 1)
cat("\nSpecies present in only one source:", single_source_species_n, "\n")
cat("Species present in more than one source:", length(multi_source_species), "\n")

consistency_field <- function(field) {
  vals <- species_source_taxonomy |>
    filter(scientificname %in% multi_source_species) |>
    select(scientificname, value = all_of(field))

  vals |>
    group_by(scientificname) |>
    summarise(
      any_na = any(is.na(value)),
      n_distinct_nonNA = n_distinct(value[!is.na(value)]),
      .groups = "drop"
    ) |>
    summarise(
      field = field,
      n_multi_source_species = n(),
      n_one_or_more_NA = sum(any_na),
      n_agreeing = sum(!any_na & n_distinct_nonNA == 1),
      n_disagreeing = sum(!any_na & n_distinct_nonNA > 1)
    )
}

consistency_summary <- map_dfr(c("kingdom", "phylum", "class", "order_taxon", "family"), consistency_field) |>
  select(field, n_multi_source_species, n_agreeing, n_disagreeing, n_one_or_more_NA)
cat("\nCross-source consistency summary:\n")
print(consistency_summary)

disagreeing_kingdom_or_phylum <- species_source_taxonomy |>
  filter(scientificname %in% multi_source_species) |>
  group_by(scientificname) |>
  filter(
    n_distinct(kingdom[!is.na(kingdom)]) > 1 |
      n_distinct(phylum[!is.na(phylum)]) > 1
  ) |>
  ungroup() |>
  arrange(scientificname, source)

sample_disagreeing <- species_source_taxonomy |>
  filter(scientificname %in% multi_source_species) |>
  group_by(scientificname) |>
  filter(n_distinct(class[!is.na(class)]) > 1 | n_distinct(order_taxon[!is.na(order_taxon)]) > 1 | n_distinct(family[!is.na(family)]) > 1) |>
  ungroup() |>
  distinct(scientificname) |>
  slice_head(n = 20) |>
  pull(scientificname)

sample_disagreeing_rows <- species_source_taxonomy |>
  filter(scientificname %in% sample_disagreeing) |>
  select(scientificname, source, kingdom, phylum, class, order_taxon, family) |>
  arrange(scientificname, source)

# =============================================================================
# Step 9: cross-check against Part 1 unresolved species
# =============================================================================

resolution_summary <- read_csv(resolution_summary_path, show_col_types = FALSE)
# NOTE: `resolved_by == "none"` alone is NOT the correct filter for
# "genuinely unresolved" -- it also catches every WoRMS-ambiguous species,
# since ambiguous matches never reach a single-record GBIF fallback query
# and so also end up with resolved_by == "none" (1,192 rows: 113 genuinely
# unresolved + 1,079 ambiguous). This exact conflation was identified and
# corrected in the Part 1 script's own report-generation code (Section 9 of
# stage4d-species-resolution-diagnostic.R; see prompts/stage4d.md), but the
# fix lives there, not in the `resolved_by` column itself, so it must be
# re-applied here. The correct filter (matching the Part 1 report's "113
# species, 2,078 rows" figure, also cited in the project CLAUDE.md) isolates
# rows where GBIF was actually queried (i.e. WoRMS returned no_match or
# api_error, not ambiguous) and GBIF also failed.
unresolved_part1 <- resolution_summary |> filter(gbif_status == "gbif_no_match")
cat("\nPart 1 genuinely unresolved species (gbif_status == 'gbif_no_match'):", nrow(unresolved_part1), "\n")

unresolved_taxonomy_check <- unresolved_part1 |>
  select(raw_species, n_rows, sources) |>
  left_join(
    species_source_taxonomy |>
      select(scientificname, source, kingdom, phylum, class) |>
      nest(.by = scientificname) |>
      rename(source_taxonomy = data),
    by = c("raw_species" = "scientificname")
  )

n_unresolved_with_any_taxonomy <- unresolved_taxonomy_check |>
  filter(map_lgl(source_taxonomy, ~ !is.null(.x) && any(!is.na(.x$kingdom) | !is.na(.x$phylum) | !is.na(.x$class)))) |>
  nrow()
n_unresolved_with_no_source_row <- sum(map_lgl(unresolved_taxonomy_check$source_taxonomy, is.null))

cat("Of these, with >=1 non-NA kingdom/phylum/class from source-native taxonomy:", n_unresolved_with_any_taxonomy, "\n")
cat("Of these, with no matching row at all in species_source_taxonomy.csv:", n_unresolved_with_no_source_row, "\n")

# =============================================================================
# Step 10: write the inventory report
# =============================================================================

lines <- character(0)
add <- function(...) lines <<- c(lines, ...)

add(
  "# Stage 4d Part 1.5 -- Source-Native Taxonomy Extraction Inventory",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  ""
)

# --- Section 1: input summary ---
add("## 1. Input summary", "")
add(paste0("- Final clean rows (`dedup_retained` & `priority_kept`): ", format(n_clean_rows, big.mark = ",")))
add(paste0("- Distinct `(source, scientificname)` combinations: ", format(n_species_by_source, big.mark = ",")))
add(paste0("- Distinct `scientificname` values overall (collapsed across sources): ", format(n_species_overall, big.mark = ",")))
add("")
add("Species in scope per source:", "")
add(md_table(source_counts_scope))
add("")
add("Match rates against each source's own taxonomy table/sheet:", "")
match_rate_tbl <- tibble(
  source = c("anztox", "wqbench", "envirotox"),
  n_in_scope = c(length(anztox_species_in_scope), length(wqbench_species_in_scope), length(envirotox_species_in_scope)),
  n_matched = c(length(anztox_species_in_scope) - length(anztox_missing_from_species_table), wqbench_match_count, envirotox_match_count),
  pct_matched = round(100 * n_matched / n_in_scope, 2)
)
add(md_table(match_rate_tbl))
add("")
if (length(anztox_missing_from_species_table) > 0) {
  add(sprintf("anztox species in scope missing from the `species` table join (unexpected -- anztox_extracted.csv is itself derived via this table): %d", length(anztox_missing_from_species_table)))
  add(paste(head(anztox_missing_from_species_table, 20), collapse = ", "))
  add("")
}
add(sprintf("- anztox in-scope species with duplicate raw `species` rows (same `scientificname`): %d", anztox_n_duplicate_keys))
add(sprintf("- wqbench in-scope species with duplicate raw `species` rows (same `latin_name`): %d", wqbench_n_duplicate_keys))
add(sprintf("- envirotox in-scope species with duplicate raw taxonomy-sheet rows (same `Latin name`): %d", envirotox_n_duplicate_keys))
add("")
if (nrow(anztox_conflict_counts) > 0) {
  add("anztox fields with genuine value conflicts across duplicate raw rows for the same species (first non-NA value was used in the output; conflicting alternatives were discarded):", "")
  add(md_table(anztox_conflict_counts))
  add("")
}

# --- Section 2: field availability per source ---
add("## 2. Field availability per source", "")
field_avail <- bind_rows(
  tibble(source = "anztox", field = names(anztox_field_nonNA), n_nonNA = unlist(anztox_field_nonNA), n_total = nrow(anztox_taxonomy)),
  tibble(source = "wqbench", field = names(wqbench_field_nonNA), n_nonNA = unlist(wqbench_field_nonNA), n_total = nrow(wqbench_taxonomy)),
  tibble(source = "envirotox", field = names(envirotox_field_nonNA), n_nonNA = unlist(envirotox_field_nonNA), n_total = nrow(envirotox_taxonomy))
) |>
  mutate(pct_nonNA = round(100 * n_nonNA / n_total, 1)) |>
  select(field, source, n_nonNA, n_total, pct_nonNA) |>
  pivot_wider(names_from = source, values_from = c(n_nonNA, n_total, pct_nonNA))
add(md_table(field_avail))
add("")

# --- Section 3: vocabulary distinct values ---
add("## 3. Vocabulary distinct values per harmonised field", "")
add("Distinct non-NA values across all three sources combined, with row counts (capped at top 40 per field; full set available by re-running the script's intermediate objects).", "")
for (f in rank_cols) {
  vals_tbl <- species_source_taxonomy |>
    filter(!is.na(.data[[f]])) |>
    count(.data[[f]], name = "n_species") |>
    arrange(desc(n_species))
  names(vals_tbl)[1] <- f
  add(paste0("### `", f, "` (", nrow(vals_tbl), " distinct values)"), "")
  add(md_table(head(vals_tbl, 40)))
  add("")
}

# --- Section 4: cross-source consistency ---
add("## 4. Cross-source consistency", "")
add(sprintf("- Species present in only one source: %d (trivially consistent)", single_source_species_n))
add(sprintf("- Species present in more than one source: %d", length(multi_source_species)))
add("")
add(md_table(consistency_summary))
add("")
add("Sample of species where `class`, `order_taxon`, or `family` disagree across sources (up to 20 species shown):", "")
if (nrow(sample_disagreeing_rows) > 0) {
  add(md_table(sample_disagreeing_rows))
} else {
  add("None found.")
}
add("")
add(sprintf("Species where `kingdom` or `phylum` (the highest-level fields) disagree across sources: %d", n_distinct(disagreeing_kingdom_or_phylum$scientificname)))
if (nrow(disagreeing_kingdom_or_phylum) > 0) {
  add(md_table(disagreeing_kingdom_or_phylum |> select(scientificname, source, kingdom, phylum)))
}
add("")

# --- Section 5: Part 1 unresolved species cross-check ---
add("## 5. Part 1 unresolved species cross-check", "")
add(
  "Note: `resolved_by == \"none\"` in `species_resolution_summary.csv` also",
  "includes the 1,079 WoRMS-ambiguous species (they never reach a",
  "single-record GBIF fallback query either), so it is NOT used directly here.",
  "The filter below (`gbif_status == \"gbif_no_match\"`) isolates species",
  "where GBIF was actually queried -- i.e. WoRMS returned no_match/api_error,",
  "not ambiguous -- and GBIF also failed; this matches the Part 1 report's",
  "\"113 species, 2,078 rows\" figure.",
  ""
)
add(sprintf("- Part 1 genuinely unresolved species (`gbif_status == \"gbif_no_match\"`): %d", nrow(unresolved_part1)))
add(sprintf("- Of these, with no matching row at all in `species_source_taxonomy.csv`: %d", n_unresolved_with_no_source_row))
add(sprintf("- Of these, with at least one non-NA kingdom/phylum/class value from source-native taxonomy: %d", n_unresolved_with_any_taxonomy))
add(sprintf(
  "- Conclusion: source-native taxonomy %s the Part 1 unresolved set.",
  if (n_unresolved_with_any_taxonomy == 0) {
    "does NOT cover any of"
  } else if (n_unresolved_with_any_taxonomy == nrow(unresolved_part1)) {
    "FULLY covers"
  } else {
    sprintf("PARTIALLY covers (%d of %d)", n_unresolved_with_any_taxonomy, nrow(unresolved_part1))
  }
))
add("")
unresolved_detail <- unresolved_taxonomy_check |>
  mutate(
    has_any_taxonomy = map_lgl(source_taxonomy, ~ !is.null(.x) && any(!is.na(.x$kingdom) | !is.na(.x$phylum) | !is.na(.x$class))),
    kingdom = map_chr(source_taxonomy, ~ if (is.null(.x)) NA_character_ else paste(unique(na.omit(.x$kingdom)), collapse = ";")),
    phylum = map_chr(source_taxonomy, ~ if (is.null(.x)) NA_character_ else paste(unique(na.omit(.x$phylum)), collapse = ";")),
    class = map_chr(source_taxonomy, ~ if (is.null(.x)) NA_character_ else paste(unique(na.omit(.x$class)), collapse = ";"))
  ) |>
  select(raw_species, n_rows, sources, has_any_taxonomy, kingdom, phylum, class) |>
  arrange(desc(n_rows))
add("Full detail (one row per Part 1 unresolved species):", "")
add(md_table(unresolved_detail))
add("")

# --- Section 6: phylum -> kingdom lookup used ---
add("## 6. Phylum -> kingdom lookup used (anztox kingdom derivation)", "")
add("Built to align with the 6-kingdom scheme (Animalia, Plantae, Chromista, Bacteria, Protozoa, Fungi) already produced by the Part 1 WoRMS/GBIF resolution -- see script header for derivation rationale.", "")
lookup_tbl <- tibble(phylum = names(phylum_to_kingdom), kingdom = unname(phylum_to_kingdom)) |> arrange(kingdom, phylum)
add(md_table(lookup_tbl))
add("")
if (nrow(anztox_phylum_unmapped) > 0) {
  add(sprintf("Observed anztox phyla NOT covered by this lookup (kingdom left NA): %s", paste(anztox_phylum_unmapped$phylum, collapse = ", ")))
} else {
  add("All anztox phyla observed among in-scope species were covered by this lookup.")
}
add("")

# --- Section 7: recommendations for Part 2 ---
add("## 7. Recommendations for Part 2", "")

add(sprintf(
  "- **WoRMS query filter level:** class-level source-native taxonomy is well populated for wqbench and envirotox but very sparse for anztox (anztox's `species` table only carries `class_id` for a small minority of rows; most anztox taxonomic signal lives in the coarser `majorgroup`/`minorgroup`/`animalcategory` fields instead). Recommend Decision C's class-first approach for wqbench/envirotox-only species, but fall back to phylum (derived for anztox via the Step 6 lookup) or to `source_majorgroup`/`source_animalcategory` as a coarse filter for anztox-only species where class is NA."
))
add(sprintf(
  "- **Cross-source disagreements:** %d species disagree on kingdom or phylum across sources -- these are the highest-priority candidates for human review before Part 2 treats source-native taxonomy as ground truth for query filtering.",
  n_distinct(disagreeing_kingdom_or_phylum$scientificname)
))
add(sprintf(
  "- **Part 1 unresolved species:** source-native taxonomy %s the 113 genuinely-unresolved species from Part 1 (%d/%d have at least a kingdom/phylum/class value). %s",
  if (n_unresolved_with_any_taxonomy > 0) "partially or fully covers" else "does not cover",
  n_unresolved_with_any_taxonomy, nrow(unresolved_part1),
  if (n_unresolved_with_any_taxonomy > 0) {
    "Part 2 should use this source-native context to construct a narrower WoRMS query (e.g. genus + class) for these species rather than retrying the same bare-name query that already failed."
  } else {
    "Part 2 will need a different strategy for these species (manual review or hard exclusion), since neither WoRMS/GBIF nor source-native taxonomy can resolve them."
  }
))
add(
  "- **Future enhancement:** anztox's `species` table has very low fill rates for `class_id`/`isheterotroph` (a small fraction of rows) and 60 duplicate `scientificname` entries with potentially conflicting `majorgroup`/`minorgroup` values -- both are data-quality characteristics of the source `infogathering` database itself, not of this extraction script, and are out of scope to fix here."
)
add("")

writeLines(lines, report_path)
cat("\nWrote report:", report_path, "\n")
