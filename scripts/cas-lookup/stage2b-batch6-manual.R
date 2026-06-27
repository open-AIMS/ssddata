# Stage 2b batch 6: manual expert review.
#
# 37 rows in scripts/stage2b-batch6-failed.csv could not be processed by the
# LLM pipeline used for the rest of stage 2b. Parent-compound decisions for
# these rows were made by manual expert review (not an LLM call) and are
# encoded directly below. This script joins those decisions onto the failed
# batch and appends the result to scripts/stage2b-full-results-combined.csv,
# bringing it from 550 to 587 rows.
#
# Note: the source instructions assigned casnumber 112143825 to both
# "Chelerythrine chloride mixture with sanguinarine chloride" (mixture) and
# "Triazamate" (registered active ingredient) -- a transcription error.
# 112143825 is actually Triazamate; the mixture's real casnumber is
# 112025602, which was otherwise unaccounted for. Confirmed with user and
# corrected here.
#
# Note: the source instructions also gave 188589-32-4 as the parent CAS for
# Flufenpyr (parent of Flufenpyr-ethyl, casnumber 188489078), but that
# number is also the literal input casnumber of an unrelated substance in
# this same batch (3-Decyl-1-methylimidazolium bromide, casnumber
# 188589324) -- CAS numbers are never reused for two substances, so this
# was a typo. User confirmed the correct Flufenpyr parent CAS is
# 128639-02-1.
#
# Run with:
#   Rscript scripts/stage2b-batch6-manual.R

library(readr)
library(dplyr)
library(tibble)

failed <- read_csv("scripts/cas-lookup/stage2b-batch6-failed.csv", show_col_types = FALSE)
combined <- read_csv("scripts/cas-lookup/stage2b-full-results-combined.csv", show_col_types = FALSE)

# --- 1. Decision lookup, keyed on casnumber -----------------------------------
# parent_mode controls how the proposed_parent_* fields are derived below:
#   "na"     - cannot resolve / needs human review -> parent fields all NA
#   "given"  - manual decision supplies an explicit parent CAS + name
#   "direct" - chemical is already its own parent -> copy input CAS + name
decisions <- tribble(
  ~casnumber, ~parent_mode, ~given_parent_cas_dashed, ~given_parent_name, ~proposed_match_rationale, ~confidence, ~notes,

  # MIXTURE OR PSEUDO-CAS - cannot resolve
  96300957,  "na", NA, NA, "MIXTURE OR PSEUDO-CAS - cannot resolve", "high", "manual review — batch 6",
  96300979,  "na", NA, NA, "MIXTURE OR PSEUDO-CAS - cannot resolve", "high", "manual review — batch 6",
  93334157,  "na", NA, NA, "MIXTURE OR PSEUDO-CAS - cannot resolve", "high", "manual review — batch 6",
  112025602, "na", NA, NA, "MIXTURE OR PSEUDO-CAS - cannot resolve", "high", "manual review — batch 6",
  145607530, "na", NA, NA, "MIXTURE OR PSEUDO-CAS - cannot resolve", "high", "manual review — batch 6",
  850804443, "na", NA, NA, "MIXTURE OR PSEUDO-CAS - cannot resolve", "high", "manual review — batch 6",
  95144244,  "na", NA, NA, "MIXTURE OR PSEUDO-CAS - cannot resolve", "high", "manual review — batch 6",
  138003562, "na", NA, NA, "MIXTURE OR PSEUDO-CAS - cannot resolve", "high", "manual review — batch 6",

  # HCl / HBr / tartrate salts of organic bases -> parent free base
  86393320,  "given", "85721-33-1",  "Ciprofloxacin", "HCl/salt → free base parent", "high", "manual review — batch 6",
  91296876,  "given", "98105-99-8",  "Sarafloxacin",  "HCl/salt → free base parent", "high", "manual review — batch 6",
  99300784,  "given", "93413-69-5",  "Venlafaxine",   "HCl/salt → free base parent", "high", "manual review — batch 6",
  138982679, "given", "146939-27-7", "Ziprasidone",   "HCl/salt → free base parent", "high", "manual review — batch 6",
  82640048,  "given", "84449-90-1",  "Raloxifene",    "HCl/salt → free base parent", "high", "manual review — batch 6",
  114247062, "given", "54910-89-3",  "Fluoxetine",    "HCl/salt → free base parent", "high", "manual review — batch 6",
  114247095, "given", "54910-89-3",  "Fluoxetine",    "HCl/salt → free base parent", "high", "manual review — batch 6",
  375815875, "given", "249296-44-4", "Varenicline",   "HCl/salt → free base parent", "high", "manual review — batch 6",

  # Esters -> parent acid
  81406373,  "given", "69377-81-7",  "Fluroxypyr",   "ester → parent acid", "high", "manual review — batch 6",
  87546187,  "given", "87547-04-4",  "Flumiclorac",  "ester → parent acid", "high", "manual review — batch 6",
  129630199, "given", "129630-17-7", "Pyraflufen",   "ester → parent acid", "high", "manual review — batch 6",
  188489078, "given", "128639-02-1", "Flufenpyr",    "ester → parent acid", "high", "manual review — batch 6",

  # Quaternary ammonium / imidazolium salts -> direct, no simpler parent
  79917901,  "direct", NA, NA, "direct - no simpler parent: ionic liquid or quaternary ammonium biocide registered as salt form", "high", "manual review — batch 6",
  85100772,  "direct", NA, NA, "direct - no simpler parent: ionic liquid or quaternary ammonium biocide registered as salt form", "high", "manual review — batch 6",
  81741288,  "direct", NA, NA, "direct - no simpler parent: ionic liquid or quaternary ammonium biocide registered as salt form", "high", "manual review — batch 6",
  114569845, "direct", NA, NA, "direct - no simpler parent: ionic liquid or quaternary ammonium biocide registered as salt form", "high", "manual review — batch 6",
  188589324, "direct", NA, NA, "direct - no simpler parent: ionic liquid or quaternary ammonium biocide registered as salt form", "high", "manual review — batch 6",
  138698369, "direct", NA, NA, "direct - no simpler parent: ionic liquid or quaternary ammonium biocide registered as salt form", "high", "manual review — batch 6",
  148788550, "direct", NA, NA, "direct - no simpler parent: ionic liquid or quaternary ammonium biocide registered as salt form", "high", "manual review — batch 6",

  # Metal salt -> parent element
  158898954, "given", "7440-05-3", "Palladium", "Pd salt -> Pd element", "high", "manual review — batch 6",

  # Registered active ingredients -> direct, no simpler parent
  112143825, "direct", NA, NA, "direct - no simpler parent: registered active ingredient", "high", "manual review — batch 6",
  120067836, "direct", NA, NA, "direct - no simpler parent: registered active ingredient", "high", "manual review — batch 6",
  117337196, "direct", NA, NA, "direct - no simpler parent: registered active ingredient", "high", "manual review — batch 6",
  141517217, "direct", NA, NA, "direct - no simpler parent: registered active ingredient", "high", "manual review — batch 6",
  143390890, "direct", NA, NA, "direct - no simpler parent: registered active ingredient", "high", "manual review — batch 6",
  203313251, "direct", NA, NA, "direct - no simpler parent: registered active ingredient", "high", "manual review — batch 6",
  94201351,  "direct", NA, NA, "direct - no simpler parent: registered active ingredient", "high", "manual review — batch 6",

  # UNCERTAIN - needs human review
  220355668, "na", NA, NA, "UNCERTAIN - needs human review", "low", "manual review — batch 6; complex structure, expert sign-off required",
  103065209, "na", NA, NA, "UNCERTAIN - needs human review", "low", "manual review — batch 6; complex structure, expert sign-off required",
)

stopifnot(nrow(decisions) == 37, !anyDuplicated(decisions$casnumber))

# --- 2. Join decisions onto the failed batch ----------------------------------
joined <- failed |>
  select(casnumber, chemicalname) |>
  left_join(decisions, by = "casnumber")

unmatched <- joined |> filter(is.na(parent_mode))
if (nrow(unmatched) > 0) {
  stop(
    "No manual decision found for ", nrow(unmatched), " casnumber(s): ",
    paste(unmatched$casnumber, collapse = ", ")
  )
}

# --- 3. Derive proposed_parent_* fields ---------------------------------------
# CAS numbers are stored without dashes in `casnumber`; the dashed form
# inserts dashes 1 digit and 2 digits from the right (check digit, then
# group of 2), e.g. 141517217 -> "141517-21-7".
add_cas_dashes <- function(casnumber) {
  x <- as.character(as.integer(casnumber))
  n <- nchar(x)
  paste0(substr(x, 1, n - 3), "-", substr(x, n - 2, n - 1), "-", substr(x, n, n))
}

strip_cas_dashes <- function(dashed) {
  as.numeric(gsub("-", "", dashed))
}

results <- joined |>
  mutate(
    proposed_parent_cas_dashed = case_when(
      parent_mode == "na" ~ NA_character_,
      parent_mode == "given" ~ given_parent_cas_dashed,
      parent_mode == "direct" ~ add_cas_dashes(casnumber)
    ),
    proposed_parent_casnumber = case_when(
      parent_mode == "na" ~ NA_real_,
      parent_mode == "given" ~ strip_cas_dashes(given_parent_cas_dashed),
      parent_mode == "direct" ~ as.numeric(casnumber)
    ),
    proposed_parent_name = case_when(
      parent_mode == "na" ~ NA_character_,
      parent_mode == "given" ~ given_parent_name,
      parent_mode == "direct" ~ chemicalname
    )
  ) |>
  select(
    casnumber, chemicalname, proposed_parent_cas_dashed,
    proposed_parent_casnumber, proposed_parent_name,
    proposed_match_rationale, confidence, notes
  )

stopifnot(nrow(results) == 37)

# --- 4. Append to the combined results file -----------------------------------
final <- bind_rows(combined, results)

if (nrow(final) != 587) {
  stop("Expected 587 rows in the final combined file, got ", nrow(final), ".")
}
if (anyDuplicated(final$casnumber) != 0) {
  dupes <- final$casnumber[duplicated(final$casnumber)]
  stop("Duplicate casnumber value(s) in final combined file: ", paste(unique(dupes), collapse = ", "))
}

write_csv(final, "scripts/cas-lookup/stage2b-full-results-combined.csv")

# Re-read the file on disk and re-verify, since step 7 asks us to check the
# final combined *file*, not just the in-memory object.
on_disk <- read_csv("scripts/cas-lookup/stage2b-full-results-combined.csv", show_col_types = FALSE)
if (nrow(on_disk) != 587) {
  stop("File verification failed: expected 587 rows on disk, found ", nrow(on_disk), ".")
}
if (anyDuplicated(on_disk$casnumber) != 0) {
  stop("File verification failed: duplicate casnumber values found on disk.")
}

# --- 5. Summary ----------------------------------------------------------------
# proposed_match_rationale is free text and almost every row has its own
# sentence (e.g. "Fe sulfate -> Fe element", "Fe oxide -> Fe element" are
# both one-off rows), so grouping on the raw string yields ~200 categories
# of mostly n = 1 -- not a useful summary. Roll up to the handful of
# recognisable top-level categories instead: the three fixed labels used
# throughout stage 2b, plus a catch-all for the many distinct
# salt/ester/oxide -> simpler-parent transformation rules.
summary_tbl <- on_disk |>
  mutate(category = case_when(
    grepl("^MIXTURE", proposed_match_rationale) ~ "MIXTURE OR PSEUDO-CAS - cannot resolve",
    grepl("^UNCERTAIN", proposed_match_rationale) ~ "UNCERTAIN - needs human review",
    grepl("^direct - no simpler parent", proposed_match_rationale) ~ "direct - no simpler parent",
    TRUE ~ "transform -> simpler parent (salt/ester/oxide/etc.)"
  )) |>
  count(category, confidence, name = "n") |>
  arrange(desc(n))

cat("\nFinal combined file: ", nrow(on_disk), " rows, 0 duplicate casnumbers.\n\n", sep = "")
cat("Summary by proposed_match_rationale category and confidence:\n")
print(summary_tbl, n = Inf)
