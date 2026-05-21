# =============================================================================
# 03_update_package.R
# This code was written by Claude Sonnet 4.6 on the 2024-06-19 but has been verified as
# correct by the author of the package, and is now ready for review and merging.
#
# PURPOSE:
#   After the human has reviewed and completed the scaffold CSVs from
#   02_scrape_technical_briefs.R and added rows to anzg.csv, this script:
#
#   1. Validates the new rows in anzg.csv (column names, required fields,
#      unit plausibility, BibTeX key cross-references)
#   2. Appends the draft BibTeX entries from _review/draft_bibtex.bib into
#      inst/REFERENCES.bib (skipping any keys already present)
#   3. Sources data-raw/anzg/DATASET.R to regenerate all package data objects
#      and R documentation files
#   4. Runs devtools::document() and devtools::check() and reports the result
#   5. Writes a validation report to data-raw/anzg/_review/validation_report.txt
#
# RUN FROM: project root
# REQUIRES:
#   - 01_identify_new_datasets.R and 02_scrape_technical_briefs.R have been run
#   - Human has reviewed scaffold CSVs and updated data-raw/anzg/anzg.csv
#   - Human has reviewed _review/draft_bibtex.bib and fixed any FIXME fields
# =============================================================================

library(readr)
library(dplyr)
library(stringr)
library(fs)
library(purrr)

# -----------------------------------------------------------------------------
# 0. Paths
# -----------------------------------------------------------------------------
review_dir <- "data-raw/anzg/_review"
anzg_csv <- "data-raw/anzg/anzg.csv"
references_bib <- "inst/REFERENCES.bib"
draft_bib <- file.path(review_dir, "draft_bibtex.bib")
dataset_r <- "data-raw/anzg/DATASET.R"
report_path <- file.path(review_dir, "validation_report.txt")

stopifnot(
  "anzg.csv not found - run from project root" = file_exists(anzg_csv),
  "inst/REFERENCES.bib not found" = file_exists(references_bib),
  "draft_bibtex.bib not found - run 02 first" = file_exists(draft_bib),
  "DATASET.R not found" = file_exists(dataset_r)
)

report_lines <- character(0)
log <- function(...) {
  msg <- paste0(...)
  message(msg)
  report_lines <<- c(report_lines, msg)
}

log("=== ANZG Package Update Validation Report ===")
log("Run at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
log("")

# -----------------------------------------------------------------------------
# 1. Load anzg.csv and identify new rows
# -----------------------------------------------------------------------------
anzg <- read_csv(anzg_csv, show_col_types = FALSE)

# Required columns (must match DATASET.R expectations)
required_cols <- c(
  "Chemical",
  "Medium",
  "Group",
  "Phylum",
  "Genus",
  "Species",
  "Notes",
  "Life stage",
  "Duration (d)",
  "Toxicity measure",
  "Test endpoint",
  "Conc",
  "Reference"
)

missing_cols <- setdiff(required_cols, names(anzg))
if (length(missing_cols) > 0) {
  log(
    "ERROR: anzg.csv is missing required columns: ",
    paste(missing_cols, collapse = ", ")
  )
  stop("Fix anzg.csv column names before proceeding.")
}
log("Column check: PASS (all required columns present)")

# What chemicals are new vs what was in the package before?
candidates_path <- file.path(review_dir, "candidates_to_add.csv")
if (file_exists(candidates_path)) {
  candidates <- read_csv(candidates_path, show_col_types = FALSE)
  already_had <- read_csv(
    file.path(review_dir, "already_have.csv"),
    show_col_types = FALSE
  )

  new_chem_med <- anzg |>
    distinct(Chemical, Medium) |>
    anti_join(already_had, by = c("Chemical", "Medium"))

  log(sprintf(
    "New Chemical/Medium combinations now in anzg.csv: %d",
    nrow(new_chem_med)
  ))
  walk(seq_len(nrow(new_chem_med)), function(i) {
    log(sprintf(
      "  + %s / %s",
      new_chem_med$Chemical[[i]],
      new_chem_med$Medium[[i]]
    ))
  })

  expected_new <- candidates |> distinct(Chemical, Medium)
  still_missing <- expected_new |>
    anti_join(new_chem_med, by = c("Chemical", "Medium"))
  if (nrow(still_missing) > 0) {
    log("")
    log(
      "WARNING: These candidates were identified but are NOT YET in anzg.csv:"
    )
    walk(seq_len(nrow(still_missing)), function(i) {
      log(sprintf(
        "  ! %s / %s",
        still_missing$Chemical[[i]],
        still_missing$Medium[[i]]
      ))
    })
    log("  -> Add them manually or re-run 02_scrape_technical_briefs.R")
  } else {
    log("Candidate coverage: PASS (all identified candidates now present)")
  }
  log("")
}

# -----------------------------------------------------------------------------
# 2. Validate data quality of all rows
# -----------------------------------------------------------------------------
log("--- Data Quality Checks ---")
errors <- 0L
warnings <- 0L

# 2a. Medium values
bad_medium <- anzg |> filter(!Medium %in% c("freshwater", "marine"))
if (nrow(bad_medium) > 0) {
  log(sprintf(
    "ERROR: %d rows have invalid Medium values (must be 'freshwater' or 'marine'):",
    nrow(bad_medium)
  ))
  log("  ", paste(unique(bad_medium$Medium), collapse = ", "))
  errors <- errors + 1L
} else {
  log("Medium values: PASS")
}

# 2b. Conc must be numeric and positive
conc_num <- suppressWarnings(as.numeric(anzg$Conc))
bad_conc <- anzg[is.na(conc_num) | conc_num <= 0, ]
if (nrow(bad_conc) > 0) {
  log(sprintf(
    "ERROR: %d rows have non-numeric or non-positive Conc values",
    nrow(bad_conc)
  ))
  log(
    "  Sample rows: ",
    paste(head(paste(bad_conc$Chemical, bad_conc$Species), 5), collapse = "; ")
  )
  errors <- errors + 1L
} else {
  log("Conc values: PASS (all numeric and positive)")
}

# 2c. Concentration plausibility check — flag likely mg/L (very high values)
# ANZG values are in µg/L; values > 1e6 are almost certainly unit errors
high_conc <- anzg[!is.na(conc_num) & conc_num > 1e6, ]
if (nrow(high_conc) > 0) {
  log(sprintf(
    "WARNING: %d rows have Conc > 1,000,000 µg/L — possible mg/L conversion error (× 1000):",
    nrow(high_conc)
  ))
  log(
    "  ",
    paste(head(paste(high_conc$Chemical, high_conc$Conc), 5), collapse = "; ")
  )
  warnings <- warnings + 1L
}

# 2d. Required text fields not NA in key columns
key_text_cols <- c("Genus", "Species", "Group", "Toxicity measure")
for (col in key_text_cols) {
  n_na <- sum(is.na(anzg[[col]]) | anzg[[col]] == "")
  if (n_na > 0) {
    log(sprintf("WARNING: %d rows have missing '%s' values", n_na, col))
    warnings <- warnings + 1L
  }
}
log("Key text field check: done (see warnings above if any)")

# 2f. Reference column — collect all unique keys used
ref_keys_in_csv <- unique(na.omit(anzg$Reference))
log(sprintf("\nUnique Reference keys in anzg.csv: %d", length(ref_keys_in_csv)))

# -----------------------------------------------------------------------------
# 3. Cross-reference BibTeX keys
# -----------------------------------------------------------------------------
log("")
log("--- BibTeX Cross-Reference Check ---")

existing_bib_text <- read_file(references_bib)
# Extract all existing keys (@type{key, ...)
existing_keys <- str_match_all(existing_bib_text, "@\\w+\\{([^,]+),")[[1]][, 2]
existing_keys <- str_trim(existing_keys)

draft_bib_text <- read_file(draft_bib)
draft_keys <- str_match_all(draft_bib_text, "@\\w+\\{([^,]+),")[[1]][, 2]
draft_keys <- str_trim(draft_keys)

# Keys referenced in anzg.csv but not in REFERENCES.bib
missing_from_bib <- setdiff(ref_keys_in_csv, existing_keys)
if (length(missing_from_bib) > 0) {
  # Check which of these ARE in the draft
  in_draft <- intersect(missing_from_bib, draft_keys)
  not_in_draft <- setdiff(missing_from_bib, draft_keys)

  if (length(in_draft) > 0) {
    log(sprintf(
      "INFO: %d keys are missing from REFERENCES.bib but present in draft_bibtex.bib (will be appended):",
      length(in_draft)
    ))
    log("  ", paste(in_draft, collapse = "\n  "))
  }
  if (length(not_in_draft) > 0) {
    log(sprintf(
      "ERROR: %d keys are referenced in anzg.csv but NOT in REFERENCES.bib or draft_bibtex.bib:",
      length(not_in_draft)
    ))
    log("  ", paste(not_in_draft, collapse = "\n  "))
    log(
      "  -> Add missing BibTeX entries to _review/draft_bibtex.bib before proceeding"
    )
    errors <- errors + 1L
  }
} else {
  log("BibTeX key cross-reference: PASS (all keys already in REFERENCES.bib)")
}

# Check for FIXME markers in draft bib
fixme_count <- str_count(draft_bib_text, "FIXME")
if (fixme_count > 0) {
  log(sprintf(
    "WARNING: %d FIXME marker(s) in draft_bibtex.bib — resolve before final commit",
    fixme_count
  ))
  warnings <- warnings + 1L
}

# Halt if there are errors
if (errors > 0) {
  log(sprintf("\n%d ERROR(s) detected. Fix before proceeding.", errors))
  writeLines(report_lines, report_path)
  stop(sprintf(
    "%d validation error(s). See %s for details.",
    errors,
    report_path
  ))
}

log(sprintf("\nValidation complete: 0 errors, %d warning(s)", warnings))
log("Proceeding to update REFERENCES.bib and rebuild package.")

# -----------------------------------------------------------------------------
# 4. Append new BibTeX entries to inst/REFERENCES.bib
# -----------------------------------------------------------------------------
log("")
log("--- Updating inst/REFERENCES.bib ---")

keys_to_append <- setdiff(draft_keys, existing_keys)

if (length(keys_to_append) == 0) {
  log("No new BibTeX entries to append (all keys already present).")
} else {
  # Parse individual entries from draft bib
  # Split on blank lines preceding @
  draft_entries <- str_split(draft_bib_text, "\n(?=@)")[[1]]
  draft_entries <- str_trim(draft_entries)
  draft_entries <- draft_entries[nchar(draft_entries) > 0]

  entries_to_add <- keep(draft_entries, function(entry) {
    key <- str_match(entry, "@\\w+\\{([^,]+),")[, 2]
    !is.na(key) && str_trim(key) %in% keys_to_append
  })

  existing_bib_trimmed <- str_trim(existing_bib_text)
  new_bib_text <- paste(
    c(existing_bib_trimmed, "", entries_to_add),
    collapse = "\n\n"
  )
  # Ensure single trailing newline
  new_bib_text <- paste0(str_trim(new_bib_text), "\n")

  write_file(new_bib_text, references_bib)
  log(sprintf(
    "Appended %d new BibTeX entries to %s:",
    length(entries_to_add),
    references_bib
  ))
  walk(keys_to_append, function(k) log("  + ", k))
}

# -----------------------------------------------------------------------------
# 5. Source DATASET.R to regenerate package data and R docs
# -----------------------------------------------------------------------------
log("")
log("--- Sourcing DATASET.R ---")
log("(This regenerates data/*.rda and R/anzg_*.R files)")

tryCatch(
  {
    source(dataset_r, local = new.env())
    log("DATASET.R: PASS")
  },
  error = function(e) {
    log("DATASET.R ERROR: ", conditionMessage(e))
    writeLines(report_lines, report_path)
    stop("DATASET.R failed. See report at ", report_path)
  }
)

# -----------------------------------------------------------------------------
# 6. devtools::document()
# -----------------------------------------------------------------------------
log("")
log("--- Running devtools::document() ---")

if (!requireNamespace("devtools", quietly = TRUE)) {
  log("WARNING: devtools not installed; skipping document() and check()")
  log("Run manually: devtools::document(); devtools::check()")
} else {
  tryCatch(
    {
      devtools::document(quiet = TRUE)
      log("devtools::document(): PASS")
    },
    error = function(e) {
      log("devtools::document() ERROR: ", conditionMessage(e))
      writeLines(report_lines, report_path)
      stop("devtools::document() failed.")
    }
  )

  # -----------------------------------------------------------------------------
  # 7. devtools::check()
  # -----------------------------------------------------------------------------
  log("")
  log("--- Running devtools::check() ---")
  log("(This may take several minutes)")

  check_result <- tryCatch(
    {
      devtools::check(quiet = FALSE, error_on = "never")
    },
    error = function(e) {
      log("devtools::check() crashed: ", conditionMessage(e))
      NULL
    }
  )

  if (!is.null(check_result)) {
    n_errors <- length(check_result$errors)
    n_warnings <- length(check_result$warnings)
    n_notes <- length(check_result$notes)

    log(sprintf(
      "devtools::check() result: %d error(s), %d warning(s), %d note(s)",
      n_errors,
      n_warnings,
      n_notes
    ))

    if (n_errors > 0) {
      log("ERRORS:")
      walk(check_result$errors, function(e) log("  ", e))
    }
    if (n_warnings > 0) {
      log("WARNINGS:")
      walk(check_result$warnings, function(w) log("  ", w))
    }
    if (n_notes > 0) {
      log("NOTES:")
      walk(check_result$notes, function(n) log("  ", n))
    }

    if (n_errors == 0 && n_warnings == 0) {
      log("CHECK: PASS (0 errors, 0 warnings)")
    } else {
      log(
        "CHECK: action required before committing — fix errors/warnings above"
      )
    }
  }
}

# -----------------------------------------------------------------------------
# 8. Final summary and commit instructions
# -----------------------------------------------------------------------------
log("")
log("--- Final Summary ---")
final_chem_med <- read_csv(anzg_csv, show_col_types = FALSE) |>
  distinct(Chemical, Medium)
log(sprintf(
  "anzg_data now contains %d unique Chemical/Medium combinations",
  nrow(final_chem_med)
))

log("")
log("When devtools::check() passes with 0 errors and 0 warnings, commit with:")
log("")
log("  git add data-raw/anzg/anzg.csv \\")
log("          data-raw/anzg/anzg-dgvs-mastertable-april2026.xlsx \\")
log("          inst/REFERENCES.bib \\")
log("          data/ R/ man/")
log(
  "  git commit -m 'Add remaining ANZG datasets (publication year > 2020), closes #9'"
)
log("  git push origin dev")
log("")
log(
  "Also open a new issue for the anztox workflow mastertable update (per issue #9 comment)."
)

# Write report
writeLines(report_lines, report_path)
message("\nFull validation report written to: ", report_path)
