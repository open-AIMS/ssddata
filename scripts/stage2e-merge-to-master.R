# Stage 2e: merge the resolved Stage 2b/2c/2d CAS parent decisions back into
# the master lookup.
#
# Stage 2b populated 587 rows of scripts/stage2b-full-results-combined.csv
# with LLM-assisted + manually reviewed (batch 6, stage2d) proposed parent
# mappings, but the master table at data-raw/cas_parent_lookup_all.csv still
# carries "NEEDS HUMAN REVIEW" placeholders for those same 587 casnumbers.
# This script copies the resolved proposed_* fields onto the matching master
# rows and overwrites the master file in place.
#
# trim_ws = FALSE is used throughout: read_csv()/write_csv() round-trip the
# untouched rows byte-for-byte only with whitespace trimming disabled (the
# default trim_ws = TRUE silently strips trailing spaces inside quoted
# chemicalname fields elsewhere in the file, which would violate the
# "leave all other rows completely unchanged" requirement below).
#
# Idempotent: if no "NEEDS HUMAN REVIEW" rows remain (i.e. this has already
# been run), the script exits cleanly without rewriting the file.
#
# Run with:
#   Rscript scripts/stage2e-merge-to-master.R

library(readr)
library(dplyr)

master_path <- "data-raw/cas_parent_lookup_all.csv"
stage2b_path <- "scripts/stage2b-full-results-combined.csv"
orig40_path <- "data-raw/anztox/cas_parent_lookup.csv"

master <- read_csv(master_path, show_col_types = FALSE, trim_ws = FALSE)
stage2b <- read_csv(stage2b_path, show_col_types = FALSE, trim_ws = FALSE)
orig40 <- read_csv(orig40_path, show_col_types = FALSE, trim_ws = FALSE)

n_before <- nrow(master)
needs_review <- master$match_rationale == "NEEDS HUMAN REVIEW"
n_needs_review <- sum(needs_review)

if (n_needs_review == 0) {
  cat("No rows with match_rationale == \"NEEDS HUMAN REVIEW\" found.\n")
  cat("Master file already merged — exiting without modifying", master_path, "\n")
  quit(save = "no", status = 0)
}

## ---- Pre-merge alignment checks -------------------------------------------
stopifnot("stage2b file has duplicate casnumbers" = anyDuplicated(stage2b$casnumber) == 0)
stopifnot(
  "stage2b casnumbers are not exactly the NEEDS HUMAN REVIEW set in master" =
    setequal(stage2b$casnumber, master$casnumber[needs_review])
)

n_uncertain_before <- sum(grepl("UNCERTAIN", stage2b$proposed_match_rationale, ignore.case = TRUE))

## ---- Snapshot the 40 human-curated rows for the post-write check ----------
orig40_parent_casnumber <- master$parent_casnumber[match(orig40$casnumber, master$casnumber)]

## ---- Add a notes column if the master doesn't already have one ----------
if (!"notes" %in% names(master)) {
  master$notes <- NA_character_
}

## ---- Merge: replace fields on NEEDS HUMAN REVIEW rows ---------------------
match_idx <- match(master$casnumber, stage2b$casnumber)
is_update <- needs_review & !is.na(match_idx)
stopifnot("not every NEEDS HUMAN REVIEW row found a stage2b match" = sum(is_update) == n_needs_review)

new_notes <- stage2b$notes[match_idx]
combined_notes <- ifelse(
  is.na(master$notes) | master$notes == "",
  new_notes,
  ifelse(is.na(new_notes), master$notes, paste(master$notes, new_notes, sep = "; "))
)

merged <- master |>
  mutate(
    parent_cas_dashed = if_else(is_update, stage2b$proposed_parent_cas_dashed[match_idx], parent_cas_dashed),
    parent_casnumber  = if_else(is_update, stage2b$proposed_parent_casnumber[match_idx], parent_casnumber),
    parent_name       = if_else(is_update, stage2b$proposed_parent_name[match_idx], parent_name),
    match_rationale   = if_else(is_update, stage2b$proposed_match_rationale[match_idx], match_rationale),
    human_checked     = if_else(is_update, "n", human_checked),
    notes             = if_else(is_update, combined_notes, notes)
  )

## ---- Validate before writing -----------------------------------------------
stopifnot(nrow(merged) == n_before)
stopifnot(anyDuplicated(merged$casnumber) == 0)

write_csv(merged, master_path)

## ---- Post-write assertions -------------------------------------------------
on_disk <- read_csv(master_path, show_col_types = FALSE, trim_ws = FALSE)

stopifnot("row count changed" = nrow(on_disk) == n_before)
stopifnot(
  "rows with match_rationale == NEEDS HUMAN REVIEW remain" =
    sum(on_disk$match_rationale == "NEEDS HUMAN REVIEW") == 0
)
stopifnot("duplicate casnumbers present" = anyDuplicated(on_disk$casnumber) == 0)

on_disk_orig40_parent_casnumber <- on_disk$parent_casnumber[match(orig40$casnumber, on_disk$casnumber)]
stopifnot(
  "one or more of the 40 human-curated rows changed" =
    identical(on_disk_orig40_parent_casnumber, orig40_parent_casnumber)
)

n_uncertain_after <- sum(grepl("UNCERTAIN", on_disk$match_rationale, ignore.case = TRUE))
stopifnot(
  "post-merge UNCERTAIN row count != 18" = n_uncertain_after == 18
)

## ---- Merge summary ----------------------------------------------------------
cat("Stage 2e merge summary\n")
cat("=======================\n")
cat(sprintf("Rows updated:       %d\n", sum(is_update)))
cat(sprintf("Rows left unchanged: %d\n", n_before - sum(is_update)))

cat("\nFinal match_rationale category counts:\n")
category <- case_when(
  grepl("^direct", on_disk$match_rationale, ignore.case = TRUE) ~ "direct",
  grepl("MIXTURE OR PSEUDO-CAS", on_disk$match_rationale, ignore.case = TRUE) ~ "mixture/pseudo-CAS",
  grepl("UNCERTAIN", on_disk$match_rationale, ignore.case = TRUE) ~ "uncertain",
  TRUE ~ "transform"
)
print(table(category))

cat("\nCount by human_checked value:\n")
print(table(on_disk$human_checked, useNA = "ifany"))
