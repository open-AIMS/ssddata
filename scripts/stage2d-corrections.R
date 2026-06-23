# Stage 2d: targeted corrections to the 587-row Stage 2b CAS parent lookup.
#
# Implements the human-reviewed decisions from scripts/stage2c-consistency-report.md
# and scripts/speciation_policy_extensions.md:
#   1. D3 (speciation_policy_extensions.md)       -- Strontium chloride (CAS
#      10476854) reclassified Chloride -> elemental Strontium (trace-metal
#      policy, consistent with Barium; see D3/D4).
#   2. D5 (stage2c-consistency-report.md Check 4)  -- 12 rows with an
#      identified parent name but no verifiable parent CAS, re-flagged
#      UNCERTAIN rather than carrying an unanchored "transform" resolution.
#   3. D6 (stage2c-consistency-report.md Check 5a) -- Phenethylamine sulfate
#      (CAS 5471089) malformed parent CAS corrected.
#   4. Check 5b (stage2c-consistency-report.md)    -- two rows where
#      proposed_parent_casnumber had a dropped trailing digit relative to
#      proposed_parent_cas_dashed; mechanical fix.
#
# Task 1 verification note (D6): the stage2d brief asked to confirm 64-04-4
# as the parent CAS for phenethylamine before correcting. Independent
# verification found that value to be wrong:
#   - CAS check-digit algorithm: for registry number "6404-X", the digits
#     preceding the check digit (6,4,0,4) yield a computed check digit of
#     0 (1*4 + 2*0 + 3*4 + 4*6 = 40, mod 10 = 0). 64-04-4 fails this
#     validation; 64-04-0 passes it.
#   - Cross-checked against independent reference sources (Sigma-Aldrich,
#     TCI, ChemBlink, Guidechem, LookChem, LGC Standards, Santa Cruz
#     Biotechnology, ChemicalBook product pages for phenethylamine /
#     2-phenylethylamine), all of which list 64-04-0.
# The chemical identity itself was never ambiguous -- the input
# chemicalname already spells out the free base as "2-phenylethan-1-amine"
# -- only the registry number needed correcting, and the verified-correct
# value (64-04-0 / 64040) is used below instead of the 64-04-4 / 64044
# value hypothesised in stage2c-consistency-report.md.
#
# Run with:
#   Rscript scripts/stage2d-corrections.R

library(readr)
library(dplyr)

path <- "scripts/stage2b-full-results-combined.csv"
combined <- read_csv(path, show_col_types = FALSE)
stopifnot(nrow(combined) == 587)

n_before_uncertain <- sum(grepl("UNCERTAIN", combined$proposed_match_rationale, ignore.case = TRUE))

## ---- Correction 1: D3 -- Strontium chloride (CAS 10476854) ----------------
stopifnot(sum(combined$casnumber == 10476854) == 1)
combined <- combined |>
  mutate(
    proposed_parent_name = if_else(casnumber == 10476854, "Strontium", proposed_parent_name),
    proposed_parent_cas_dashed = if_else(casnumber == 10476854, "7440-24-6", proposed_parent_cas_dashed),
    proposed_parent_casnumber = if_else(casnumber == 10476854, 7440246, proposed_parent_casnumber),
    proposed_match_rationale = if_else(
      casnumber == 10476854,
      "Sr salt -> Sr element (trace metal per speciation_policy_extensions.md D3)",
      proposed_match_rationale
    ),
    confidence = if_else(casnumber == 10476854, "high", confidence),
    notes = if_else(casnumber == 10476854, "stage2d correction — D3 policy decision", notes)
  )
n_d3 <- 1L

## ---- Correction 2: D5 -- re-flag 12 unanchored transform rows -------------
d5_cas <- c(
  2026246, 2051798, 5407045, 7250671, 7745893, 10114586,
  13071119, 16058267, 25646713, 25646779, 29235710, 36362091
)
stopifnot(sum(combined$casnumber %in% d5_cas) == length(d5_cas))
combined <- combined |>
  mutate(
    proposed_match_rationale = if_else(
      casnumber %in% d5_cas, "UNCERTAIN - needs human review", proposed_match_rationale
    ),
    confidence = if_else(casnumber %in% d5_cas, "low", confidence),
    proposed_parent_name = if_else(casnumber %in% d5_cas, NA_character_, proposed_parent_name),
    notes = if_else(
      casnumber %in% d5_cas,
      "stage2d correction — D5: parent name identified but no CAS anchor; re-flagged for human review",
      notes
    )
  )
n_d5 <- length(d5_cas)

## ---- Correction 3: D6 -- Phenethylamine sulfate (CAS 5471089) -------------
stopifnot(sum(combined$casnumber == 5471089) == 1)
combined <- combined |>
  mutate(
    proposed_parent_cas_dashed = if_else(casnumber == 5471089, "64-04-0", proposed_parent_cas_dashed),
    proposed_parent_casnumber = if_else(casnumber == 5471089, 64040, proposed_parent_casnumber),
    proposed_parent_name = if_else(casnumber == 5471089, "Phenethylamine", proposed_parent_name),
    proposed_match_rationale = if_else(
      casnumber == 5471089,
      paste(
        "sulfate salt -> free base parent (CAS corrected from malformed 6-40-4;",
        "verified registry number is 64-04-0, not the 64-04-4 hypothesised in",
        "stage2c-consistency-report.md -- see script header note)"
      ),
      proposed_match_rationale
    ),
    confidence = if_else(casnumber == 5471089, "high", confidence),
    notes = if_else(casnumber == 5471089, "stage2d correction — D6: CAS typo corrected after independent verification", notes)
  )
n_d6 <- 1L

## ---- Correction 4: Check 5b -- programmatic CAS fixes ---------------------
stopifnot(sum(combined$casnumber == 21351393) == 1)
stopifnot(sum(combined$casnumber == 56896685) == 1)
combined <- combined |>
  mutate(
    proposed_parent_casnumber = case_when(
      casnumber == 21351393 ~ 57136,
      casnumber == 56896685 ~ 78900,
      TRUE ~ proposed_parent_casnumber
    )
  )
n_check5b <- 2L

## ---- Validate before writing ----------------------------------------------
stopifnot(nrow(combined) == 587)
stopifnot(anyDuplicated(combined$casnumber) == 0)

write_csv(combined, path)

## ---- Post-write assertions -------------------------------------------------
on_disk <- read_csv(path, show_col_types = FALSE)

stopifnot(nrow(on_disk) == 587)
stopifnot(anyDuplicated(on_disk$casnumber) == 0)

is_direct    <- grepl("^direct", on_disk$proposed_match_rationale, ignore.case = TRUE)
is_mixture   <- grepl("MIXTURE OR PSEUDO-CAS", on_disk$proposed_match_rationale, ignore.case = TRUE)
is_uncertain <- grepl("UNCERTAIN", on_disk$proposed_match_rationale, ignore.case = TRUE)
is_transform <- !is_direct & !is_mixture & !is_uncertain

stopifnot(sum(is_transform & is.na(on_disk$proposed_parent_casnumber)) == 0)

stopifnot(on_disk$proposed_parent_name[on_disk$casnumber == 10476854] == "Strontium")

phen_row <- on_disk[on_disk$casnumber == 5471089, ]
stopifnot(
  !is.na(phen_row$proposed_parent_casnumber) ||
    grepl("UNCERTAIN", phen_row$proposed_match_rationale, ignore.case = TRUE)
)

n_after_uncertain <- sum(is_uncertain)

cat("Stage 2d correction summary\n")
cat("============================\n")
cat(sprintf("Correction 1 (D3 Strontium):              %d row modified\n", n_d3))
cat(sprintf("Correction 2 (D5 unanchored -> UNCERTAIN): %d rows modified\n", n_d5))
cat(sprintf("Correction 3 (D6 Phenethylamine CAS):      %d row modified\n", n_d6))
cat(sprintf("Correction 4 (Check 5b CAS digit fixes):   %d rows modified\n", n_check5b))
cat(sprintf("\nUNCERTAIN rows before: %d\n", n_before_uncertain))
cat(sprintf("UNCERTAIN rows after:  %d\n", n_after_uncertain))
cat(sprintf("Total rows in file:    %d\n", nrow(on_disk)))
