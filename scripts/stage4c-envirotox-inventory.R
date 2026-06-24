# Stage 4c, Part 1 -- envirotox xlsx schema inventory, scoped to fields
# relevant for duplicate detection. Read-only: envirotox.xlsx is read
# only; no harmonisation, extraction, or aggregate() calls are run.
#
# Note: readxl::read_excel() (used here, per the task brief) preserves
# the workbook's literal column names, which contain spaces and
# parentheses (e.g. "Test statistic", "Duration (hours)"). DATASET.R
# itself uses openxlsx::read.xlsx(), whose default sep.names = "."
# rewrites those same headers with dots (e.g. "Test.statistic"). Column
# *names* below are readxl's; they are the same underlying data DATASET.R
# reads, just under openxlsx's dot-substituted aliases.

library(dplyr)
library(readxl)

path <- file.path("data-raw", "envirotox", "envirotox.xlsx")
test_sheet <- read_excel(path, sheet = "test")

cat("=== dim(test_sheet) ===\n")
print(dim(test_sheet))

# -----------------------------------------------------------------------
# Step 3a -- full column list, types, non-NA counts, distinct counts
# -----------------------------------------------------------------------
cat("\n\n========== STEP 3a: FULL COLUMN INVENTORY ==========\n")
col_inventory <- data.frame(
  column = names(test_sheet),
  type = sapply(test_sheet, function(x) paste(class(x), collapse = "/")),
  n_non_na = sapply(test_sheet, function(x) sum(!is.na(x))),
  n_distinct = sapply(test_sheet, function(x) length(unique(x[!is.na(x)])))
)
print(col_inventory, row.names = FALSE)

# -----------------------------------------------------------------------
# Step 3b -- distinct values for duplicate-detection-relevant columns
# (readxl's literal, space-preserved column names)
# -----------------------------------------------------------------------
cat("\n\n========== STEP 3b: CANDIDATE COLUMN DISTINCT VALUES ==========\n")

candidate_cols <- c(
  "Test statistic", "Test type", "Effect", "Duration",
  "Duration (days)", "Duration (hours)", "Source", "Unit",
  "Effect is 5X above water solubility", "original CAS"
)
present <- candidate_cols[candidate_cols %in% names(test_sheet)]
missing <- setdiff(candidate_cols, names(test_sheet))
cat("Candidate columns present:", paste(present, collapse = ", "), "\n")
cat("Candidate columns NOT present:", paste(missing, collapse = ", "), "\n")
cat("\nNo Organism.lifestage / life-stage-equivalent column exists anywhere",
    "in the 17-column test sheet (confirmed against the full column list above).\n")
cat("No Chemical.purity.nominal column exists either.\n")
cat("No literal author/year/title 'Reference' column exists; 'Source' (below) is the closest study-identifier field.\n")

for (col in present) {
  vals <- test_sheet[[col]]
  n_distinct_vals <- length(unique(vals[!is.na(vals)]))
  cat("\n--- `", col, "` (n_distinct = ", n_distinct_vals, ", n_non_na = ",
      sum(!is.na(vals)), "/", length(vals), ") ---\n", sep = "")
  if (n_distinct_vals <= 60) {
    print(sort(table(vals), decreasing = TRUE))
  } else {
    cat("(>60 distinct values; showing value counts, top 40)\n")
    print(head(sort(table(vals), decreasing = TRUE), 40))
  }
}

# -----------------------------------------------------------------------
# Step 3c -- field-removal duplicate count analysis (raw, unfiltered
# test sheet)
# -----------------------------------------------------------------------
cat("\n\n========== STEP 3c: FIELD-REMOVAL DUPLICATE COUNT ANALYSIS (raw sheet) ==========\n")

key_candidates <- c("original CAS", "Latin name", "Test statistic", "Effect", "Duration (hours)", "Source")
key_fields <- key_candidates[key_candidates %in% names(test_sheet)]
cat("Full candidate key:", paste(key_fields, collapse = ", "), "\n")

dup_count <- function(df, fields) {
  df |>
    group_by(across(all_of(fields))) |>
    summarise(n = n(), .groups = "drop") |>
    filter(n > 1) |>
    nrow()
}

cat("\n--- duplicate count with FULL available key (raw sheet) ---\n")
print(dup_count(test_sheet, key_fields))

cat("\n--- duplicate count dropping one field at a time (raw sheet) ---\n")
for (f in key_fields) {
  remaining <- setdiff(key_fields, f)
  cat(sprintf("Drop '%s' -> key = [%s]: n_dup_groups = %d\n",
              f, paste(remaining, collapse = ", "), dup_count(test_sheet, remaining)))
}

# -----------------------------------------------------------------------
# Reproduce the DATASET.R filter (Test statistic/Test type/solubility)
# to check whether the candidate dedup fields are still usable/distinct
# after the actual filtering step the pipeline applies.
# -----------------------------------------------------------------------
cat("\n\n========== ADDITIONAL: candidate key, AFTER the DATASET.R statistic/type/solubility filter ==========\n")
test_selected <- test_sheet %>%
  filter(
    (`Test statistic` == "EC50" & `Test type` == "A") |
      (`Test statistic` == "LC50" & `Test type` == "A") |
      (`Test statistic` == "NOEC" & `Test type` == "C") |
      (`Test statistic` == "NOEL" & `Test type` == "C")
  ) %>%
  filter(`Effect is 5X above water solubility` == 0)

cat("rows after filter:", nrow(test_selected), "\n")

cat("\n--- duplicate count with full available key, POST-filter ---\n")
print(dup_count(test_selected, key_fields))
cat("\n--- duplicate count dropping one field at a time, POST-filter ---\n")
for (f in key_fields) {
  remaining <- setdiff(key_fields, f)
  cat(sprintf("Drop '%s' -> key = [%s]: n_dup_groups = %d\n",
              f, paste(remaining, collapse = ", "), dup_count(test_selected, remaining)))
}

cat("\n\n========== DONE ==========\n")
