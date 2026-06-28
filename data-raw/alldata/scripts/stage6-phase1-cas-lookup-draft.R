# Stage 6 Phase 1: Schema inventory, CAS lookup update, curated_cas_lookup.csv generation
#
# Tasks:
#   1. Schema inventory of anzg_data, ccme_data, aims_data, csiro_data
#   2. Add `excluded` column to data-raw/cas_parent_lookup_all.csv
#   3. Generate data-raw/alldata/curated_cas_lookup.csv (auto-resolution)
#   4. Within-source duplicate check for all four curated sources
#
# Environment: WSL or Windows Positron (no live DB required)
# Run before scripts/stage6-phase2-integrate.R

library(dplyr)
library(readr)
library(ssddata)

# ============================================================
# TASK 1: Schema inventory
# ============================================================

cat("\n====================================================\n")
cat("TASK 1: Schema inventory\n")
cat("====================================================\n\n")

print_schema <- function(df, name, species_col = "Species", has_genus = FALSE) {
  cat(paste0("--- ", name, " ---\n"))
  cat("Column names:", paste(names(df), collapse = ", "), "\n")
  cat("Dimensions:", nrow(df), "rows x", ncol(df), "cols\n")
  cat("Distinct chemicals:", n_distinct(df$Chemical),
    " —", paste(sort(unique(df$Chemical)), collapse = ", "), "\n")
  cat("Medium (unique):", paste(sort(unique(df$Medium)), collapse = ", "), "\n")
  if (has_genus) {
    sp_vec <- paste(df$Genus, df[[species_col]])
  } else {
    sp_vec <- df[[species_col]]
  }
  cat("Distinct species:", n_distinct(sp_vec, na.rm = TRUE), "\n")
  cat("Conc range (NA excluded):", paste(range(df$Conc, na.rm = TRUE), collapse = " – "), "\n")
  if ("Units" %in% names(df)) {
    cat("Units (by row count):\n")
    print(table(df$Units, useNA = "always"))
  }
  na_conc <- sum(is.na(df$Conc))
  na_sp <- sum(is.na(df[[species_col]]))
  na_chem <- sum(is.na(df$Chemical))
  cat(sprintf("NA counts — Conc: %d | %s: %d | Chemical: %d\n",
    na_conc, species_col, na_sp, na_chem))
  cat("Head (3 rows):\n")
  print(head(df, 3))
  cat("\n")
}

print_schema(anzg_data, "anzg_data", species_col = "Species", has_genus = TRUE)
print_schema(ccme_data, "ccme_data")
print_schema(aims_data, "aims_data")
print_schema(csiro_data, "csiro_data")

# ccme medium note: actual data is "Freshwater", not "Unknown" as described in
# CLAUDE.md (Issue #34). Flag this discrepancy — it affects the Phase 2 exclusion rule.
if (all(ccme_data$Medium == "Freshwater")) {
  cat("NOTE [ccme_data]: Medium is 'Freshwater' for all rows — CLAUDE.md describes it\n")
  cat("  as interim 'Unknown' (Issue #34 pending). Confirm with user which value is\n")
  cat("  authoritative before Phase 2, as this affects the CCME exclusion rule.\n\n")
}

# csiro NA Species note
n_na_sp_csiro <- sum(is.na(csiro_data$Species))
if (n_na_sp_csiro > 0) {
  cat(sprintf(
    "NOTE [csiro_data]: %d rows have Species = NA (all chlorine x marine).\n",
    n_na_sp_csiro
  ))
  cat("  Phase 2 will treat NA as a distinct accepted_name group.\n\n")
}

cat("=== Schema inventory complete ===\n")
cat(sprintf("anzg_data:  %d rows, %d chemicals, %d distinct species, medium: %s\n",
  nrow(anzg_data), n_distinct(anzg_data$Chemical),
  n_distinct(paste(anzg_data$Genus, anzg_data$Species)),
  paste(sort(unique(anzg_data$Medium)), collapse = ", ")))
cat(sprintf("ccme_data:  %d rows, %d chemicals, %d distinct species, medium: %s\n",
  nrow(ccme_data), n_distinct(ccme_data$Chemical),
  n_distinct(ccme_data$Species), paste(sort(unique(ccme_data$Medium)), collapse = ", ")))
cat(sprintf("aims_data:   %d rows, %d chemicals, %d distinct species, medium: %s\n",
  nrow(aims_data), n_distinct(aims_data$Chemical),
  n_distinct(aims_data$Species), paste(sort(unique(aims_data$Medium)), collapse = ", ")))
cat(sprintf("csiro_data:  %d rows, %d chemicals, %d distinct non-NA species, medium: %s\n",
  nrow(csiro_data), n_distinct(csiro_data$Chemical),
  n_distinct(csiro_data$Species, na.rm = TRUE),
  paste(sort(unique(csiro_data$Medium)), collapse = ", ")))
cat("NOTE: None of the four curated sources have a CAS number column — expected.\n")

# ============================================================
# TASK 2: Add `excluded` column to master CAS lookup
# ============================================================

cat("\n====================================================\n")
cat("TASK 2: Add `excluded` column to master CAS lookup\n")
cat("====================================================\n\n")

cas_path <- "data-raw/cas_parent_lookup_all.csv"

if (!file.exists(cas_path)) {
  stop(
    "ERROR: Master CAS lookup not found at data-raw/cas_parent_lookup_all.csv.\n",
    "Do NOT look in data-raw/anztox/ — that is a different file."
  )
}

cas_lookup <- read_csv(cas_path, guess_max = Inf, show_col_types = FALSE)
cat("Loaded master CAS lookup:", nrow(cas_lookup), "rows,", ncol(cas_lookup), "cols\n")
cat("Columns:", paste(names(cas_lookup), collapse = ", "), "\n\n")

if ("excluded" %in% names(cas_lookup)) {
  cat("NOTE: `excluded` column already present — overwriting.\n")
}

cas_lookup <- cas_lookup |>
  mutate(excluded = (human_checked == "n") &
    grepl("UNCERTAIN", match_rationale, ignore.case = FALSE))

n_excluded <- sum(cas_lookup$excluded, na.rm = TRUE)
cat("excluded = TRUE:", n_excluded, "rows\n")

if (n_excluded != 18) {
  cat("WARNING: Expected 18 UNCERTAIN rows; found", n_excluded, ". Review rows below:\n")
  print(cas_lookup |> filter(excluded) |> select(casnumber, chemicalname, match_rationale))
  stop("Unexpected excluded count — user review required before proceeding.")
}

cat("Confirmed 18 UNCERTAIN rows.\n")
cat("Excluded rows (casnumber and match_rationale):\n")
print(cas_lookup |>
  filter(excluded) |>
  select(casnumber, chemicalname, parent_casnumber, match_rationale) |>
  as.data.frame())

write_csv(cas_lookup, cas_path)
cat("\nWritten to:", cas_path, "\n")

# ============================================================
# TASK 3: Generate curated_cas_lookup.csv
# ============================================================

cat("\n====================================================\n")
cat("TASK 3: Generate curated_cas_lookup.csv\n")
cat("====================================================\n\n")

# Helper: normalise chemical name for case-insensitive matching
clean_chem <- function(x) tolower(trimws(gsub("_", " ", x, fixed = TRUE)))

# Master lookup subset (exclude UNCERTAIN rows)
lookup_active <- cas_lookup |>
  filter(!excluded)

# Resolve one chemical name against the master lookup.
# Returns a named list with casnumber_grouped, chemicalname_grouped,
# resolution_method, notes.
resolve_via_master_lookup <- function(chem_name, lookup) {
  cleaned <- clean_chem(chem_name)

  # Step 1 — match via parent_name (filter out NA parent_name to avoid ghost rows)
  match1 <- lookup |>
    filter(!is.na(parent_name), !is.na(parent_casnumber)) |>
    filter(tolower(trimws(parent_name)) == cleaned)

  if (nrow(match1) > 0) {
    return(list(
      casnumber_grouped = as.character(match1$parent_casnumber[1]),
      chemicalname_grouped = match1$parent_name[1],
      resolution_method = "master_lookup",
      notes = paste0("Matched parent_name='", match1$parent_name[1], "'")
    ))
  }

  # Step 2 — match via chemicalname (self-referential entries or direct lookup)
  match2 <- lookup |>
    filter(!is.na(chemicalname), !is.na(parent_casnumber)) |>
    filter(tolower(trimws(chemicalname)) == cleaned)

  if (nrow(match2) > 0) {
    return(list(
      casnumber_grouped = as.character(match2$parent_casnumber[1]),
      chemicalname_grouped = coalesce(match2$parent_name[1], match2$chemicalname[1]),
      resolution_method = "master_lookup",
      notes = paste0("Matched chemicalname='", match2$chemicalname[1], "'")
    ))
  }

  list(
    casnumber_grouped = NA_character_,
    chemicalname_grouped = NA_character_,
    resolution_method = "unresolved",
    notes = "No match in master lookup"
  )
}

# Resolve via webchem CIR if available
resolve_via_webchem <- function(chem_name) {
  if (!requireNamespace("webchem", quietly = TRUE)) {
    return(list(
      casnumber_grouped = NA_character_,
      chemicalname_grouped = NA_character_,
      resolution_method = "unresolved",
      notes = "webchem not installed; manual entry required"
    ))
  }
  cleaned_name <- gsub("_", " ", trimws(chem_name), fixed = TRUE)
  tryCatch(
    {
      result <- webchem::cir_query(cleaned_name, representation = "cas")
      if (!is.null(result) && length(result) > 0 && !is.na(result[[1]][1])) {
        cas_raw <- result[[1]][1]
        # Remove dashes for consistency with master lookup format
        cas_nodash <- gsub("-", "", cas_raw, fixed = TRUE)
        return(list(
          casnumber_grouped = cas_nodash,
          chemicalname_grouped = tools::toTitleCase(cleaned_name),
          resolution_method = "webchem_cir",
          notes = paste0("CIR returned CAS ", cas_raw, "; stored without dashes")
        ))
      }
      list(
        casnumber_grouped = NA_character_,
        chemicalname_grouped = NA_character_,
        resolution_method = "unresolved",
        notes = "webchem CIR returned no result"
      )
    },
    error = function(e) {
      list(
        casnumber_grouped = NA_character_,
        chemicalname_grouped = NA_character_,
        resolution_method = "unresolved",
        notes = paste("webchem CIR error:", conditionMessage(e))
      )
    }
  )
}

# Extract distinct chemicals per source
chems_anzg <- tibble(source = "anzg", chemical_name = sort(unique(anzg_data$Chemical)))
chems_ccme <- tibble(source = "ccme", chemical_name = sort(unique(ccme_data$Chemical)))
chems_aims <- tibble(source = "aims", chemical_name = sort(unique(aims_data$Chemical)))
chems_csiro <- tibble(source = "csiro", chemical_name = sort(unique(csiro_data$Chemical)))

all_chems <- bind_rows(chems_anzg, chems_ccme, chems_aims, chems_csiro) |>
  arrange(source, chemical_name)

cat("Total chemical × source rows to resolve:", nrow(all_chems), "\n\n")

# Resolve each chemical
results <- vector("list", nrow(all_chems))
for (i in seq_len(nrow(all_chems))) {
  src <- all_chems$source[i]
  chem <- all_chems$chemical_name[i]

  # Try master lookup first
  res <- resolve_via_master_lookup(chem, lookup_active)

  # If unresolved, try webchem
  if (res$resolution_method == "unresolved") {
    res <- resolve_via_webchem(chem)
  }

  results[[i]] <- tibble(
    source = src,
    chemical_name = chem,
    casnumber_grouped = res$casnumber_grouped,
    chemicalname_grouped = res$chemicalname_grouped,
    resolution_method = res$resolution_method,
    notes = res$notes
  )
}

curated_cas <- bind_rows(results)

# Print full resolution table for user review
cat("=== Full resolution table for user review ===\n")
print(curated_cas |> select(source, chemical_name, casnumber_grouped, chemicalname_grouped, resolution_method) |> as.data.frame(),
  row.names = FALSE)

n_master <- sum(curated_cas$resolution_method == "master_lookup")
n_webchem <- sum(curated_cas$resolution_method == "webchem_cir")
n_unresolved <- sum(curated_cas$resolution_method == "unresolved")

cat(sprintf("\nResolution summary:\n  master_lookup: %d\n  webchem_cir:   %d\n  unresolved:    %d\n",
  n_master, n_webchem, n_unresolved))

out_path <- "data-raw/alldata/curated_cas_lookup.csv"
write_csv(curated_cas, out_path)
cat("\nWritten to:", out_path, "\n")

if (n_unresolved > 0) {
  unresolved_rows <- curated_cas |> filter(resolution_method == "unresolved")
  cat(sprintf(
    "\nWARNING: %d chemical(s) could not be auto-resolved. Phase 2 will fail\n",
    n_unresolved
  ))
  cat("until these are manually populated in curated_cas_lookup.csv:\n")
  print(unresolved_rows |> select(source, chemical_name, notes) |> as.data.frame(),
    row.names = FALSE)
  cat("\nFor each unresolved row, populate casnumber_grouped (no dashes, e.g. '7440508')\n")
  cat("and chemicalname_grouped, then set resolution_method = 'manual'.\n")
  cat("Common CAS references: https://commonchemistry.cas.org/\n")
} else {
  cat("All chemicals resolved. Spot-check webchem_cir resolutions before running Phase 2.\n")
}

# ============================================================
# TASK 4: Within-source duplicate check
# ============================================================

cat("\n====================================================\n")
cat("TASK 4: Within-source duplicate check\n")
cat("====================================================\n\n")

check_dups <- function(df, name, chem_col = "Chemical", medium_col = "Medium",
                       species_col = "Species", extra_cols = character()) {
  key_cols <- c(chem_col, medium_col, species_col)
  grp <- df |> group_by(across(all_of(key_cols)))
  non_unique <- grp |>
    filter(n() > 1) |>
    ungroup()
  n_combos <- df |> distinct(across(all_of(key_cols))) |> nrow()
  n_non_unique_combos <- non_unique |>
    distinct(across(all_of(key_cols))) |>
    nrow()
  cat(sprintf(
    "%s: %d %s combinations; %d are non-unique (%d rows affected)\n",
    name, n_combos,
    paste(key_cols, collapse = " x "),
    n_non_unique_combos, nrow(non_unique)
  ))
  if (nrow(non_unique) > 0) {
    show_cols <- c(key_cols, extra_cols, "Conc")
    show_cols <- intersect(show_cols, names(df))
    cat("  Non-unique rows:\n")
    print(non_unique |> select(all_of(show_cols)) |> arrange(across(all_of(key_cols))),
      n = 50)
    if (n_non_unique_combos > 0) {
      cat("  → Phase 2 will aggregate these using the Section 3.4.4 geomean rule.\n")
    }
  }
  cat("\n")
  invisible(non_unique)
}

# ANZG: species is paste(Genus, Species)
anzg_dup <- anzg_data |>
  mutate(accepted_name_full = paste(Genus, Species)) |>
  check_dups("anzg_data", species_col = "accepted_name_full",
    extra_cols = c("Duration", "Group"))

aims_dup <- check_dups(aims_data, "aims_data", extra_cols = c("Domain"))

csiro_dup <- check_dups(csiro_data, "csiro_data", extra_cols = c("Domain"))

ccme_dup <- check_dups(ccme_data, "ccme_data")

# ============================================================
# Session summary
# ============================================================

cat("\n====================================================\n")
cat("=== Stage 6 Phase 1 session summary ===\n")
cat("====================================================\n\n")

cat("Task 1 — Schema inventory: complete\n")
cat(sprintf("  anzg_data:  %d rows, %d chemicals, %d species, medium: %s\n",
  nrow(anzg_data), n_distinct(anzg_data$Chemical),
  n_distinct(paste(anzg_data$Genus, anzg_data$Species)),
  paste(sort(unique(anzg_data$Medium)), collapse = ", ")))
cat(sprintf("  ccme_data:  %d rows, %d chemicals, %d species, medium: %s (Units: %s)\n",
  nrow(ccme_data), n_distinct(ccme_data$Chemical),
  n_distinct(ccme_data$Species),
  paste(sort(unique(ccme_data$Medium)), collapse = ", "),
  paste(sort(unique(ccme_data$Units)), collapse = ", ")))
cat(sprintf("  aims_data:   %d rows, %d chemicals, %d species, medium: %s\n",
  nrow(aims_data), n_distinct(aims_data$Chemical),
  n_distinct(aims_data$Species),
  paste(sort(unique(aims_data$Medium)), collapse = ", ")))
cat(sprintf("  csiro_data:  %d rows, %d chemicals, %d non-NA species, medium: %s\n",
  nrow(csiro_data), n_distinct(csiro_data$Chemical),
  n_distinct(csiro_data$Species, na.rm = TRUE),
  paste(sort(unique(csiro_data$Medium)), collapse = ", ")))
if (all(ccme_data$Medium == "Freshwater")) {
  cat("  DISCREPANCY: ccme Medium = 'Freshwater' in data vs 'Unknown' in CLAUDE.md.\n")
  cat("  Confirm with user which is authoritative before Phase 2.\n")
}
if (n_na_sp_csiro > 0) {
  cat(sprintf("  ALERT: csiro has %d NA-Species rows (chlorine x marine) — needs Phase 2 decision.\n",
    n_na_sp_csiro))
}
cat("\n")

cat("Task 2 — CAS lookup excluded column: complete\n")
cat(sprintf("  excluded = TRUE: %d rows (expected 18)\n", n_excluded))
cat(sprintf("  Written to: %s\n\n", cas_path))

cat("Task 3 — curated_cas_lookup.csv: written\n")
cat(sprintf("  Path: %s\n", out_path))
cat(sprintf("  Rows: %d (%d sources x %d distinct chemicals)\n",
  nrow(curated_cas), n_distinct(curated_cas$source),
  n_distinct(curated_cas$chemical_name)))
cat(sprintf("  master_lookup:   %d\n  webchem_cir:     %d\n  unresolved:      %d\n\n",
  n_master, n_webchem, n_unresolved))

cat("Task 4 — Within-source duplicate check: complete\n")
anzg_n_dup <- anzg_data |>
  mutate(accepted_name_full = paste(Genus, Species)) |>
  group_by(Chemical, Medium, accepted_name_full) |>
  filter(n() > 1) |>
  ungroup() |>
  distinct(Chemical, Medium, accepted_name_full) |>
  nrow()
aims_n_dup <- aims_data |>
  group_by(Chemical, Medium, Species) |>
  filter(n() > 1) |>
  ungroup() |>
  distinct(Chemical, Medium, Species) |>
  nrow()
csiro_n_dup <- csiro_data |>
  group_by(Chemical, Medium, Species) |>
  filter(n() > 1) |>
  ungroup() |>
  distinct(Chemical, Medium, Species) |>
  nrow()
ccme_n_dup <- ccme_data |>
  group_by(Chemical, Medium, Species) |>
  filter(n() > 1) |>
  ungroup() |>
  distinct(Chemical, Medium, Species) |>
  nrow()
cat(sprintf("  anzg_data:  %d non-unique Chemical x Medium x accepted_name triplets\n", anzg_n_dup))
cat(sprintf("  aims_data:  %d non-unique Chemical x Medium x Species triplets\n", aims_n_dup))
cat(sprintf("  csiro_data: %d non-unique Chemical x Medium x Species triplets\n", csiro_n_dup))
cat(sprintf("  ccme_data:  %d non-unique Chemical x Medium x Species triplets\n", ccme_n_dup))
cat("\n")

cat("=== Files to commit (user action required) ===\n")
cat("  data-raw/cas_parent_lookup_all.csv              [modified — excluded column added]\n")
cat("  data-raw/alldata/curated_cas_lookup.csv         [new — review and correct unresolved rows]\n")
cat("  scripts/stage6-phase1-cas-lookup-draft.R        [new]\n")
cat("  prompts/stage6.md                               [new]\n\n")

cat("=== User action required before Phase 2 ===\n")
cat("  1. Review data-raw/alldata/curated_cas_lookup.csv.\n")
cat("  2. Correct any rows with resolution_method = 'unresolved':\n")
cat("       - populate casnumber_grouped (no dashes, e.g. '52315078' for alpha-cypermethrin)\n")
cat("       - populate chemicalname_grouped (the canonical parent name)\n")
cat("       - set resolution_method = 'manual'\n")
cat("  3. Spot-check webchem_cir resolutions for accuracy.\n")
cat("  4. Confirm ccme Medium discrepancy ('Freshwater' in data vs 'Unknown' in CLAUDE.md).\n")
cat("  5. Confirm how to handle csiro NA-Species rows (chlorine x marine, 30 rows).\n")
cat("  6. Commit tracked files, then run scripts/stage6-phase2-integrate.R.\n")
