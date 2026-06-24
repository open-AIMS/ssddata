# Stage 4c, Part 1 — wqbench RDS schema inventory, scoped to fields
# relevant for duplicate detection. Read-only: data_set is loaded and
# inspected only; wqb_aggregate() / wqb_filter_chemical() are never
# called, and ecotox_ascii_12_11_2025.rds (the file DATASET.R currently
# uses) is the file loaded -- NOT the newer ecotox_ascii_06_11_2026.rds.

library(dplyr)

data_set <- readRDS(file.path("data-raw", "wqbench", "ecotox_ascii_12_11_2025.rds"))

cat("=== dim(data_set) ===\n")
print(dim(data_set))

# -----------------------------------------------------------------------
# Step 2a — full column list, types, non-NA counts, distinct counts
# -----------------------------------------------------------------------
cat("\n\n========== STEP 2a: FULL COLUMN INVENTORY ==========\n")
col_inventory <- data.frame(
  column = names(data_set),
  type = sapply(data_set, function(x) paste(class(x), collapse = "/")),
  n_non_na = sapply(data_set, function(x) sum(!is.na(x))),
  n_distinct = sapply(data_set, function(x) length(unique(x[!is.na(x)])))
)
print(col_inventory, row.names = FALSE)

# -----------------------------------------------------------------------
# Step 2b — distinct values for duplicate-detection-relevant columns
# -----------------------------------------------------------------------
cat("\n\n========== STEP 2b: CANDIDATE COLUMN DISTINCT VALUES ==========\n")

candidate_cols <- c(
  "endpoint", "effect", "obs_duration_mean", "obs_duration_unit",
  "duration_hrs", "duration_class", "lifestage", "conc1_type",
  "reference_number", "test_id", "result_id", "chemical_grade",
  "acr", "author", "title", "source", "publication_year"
)
candidate_cols <- candidate_cols[candidate_cols %in% names(data_set)]
cat("Candidate columns present in data_set:", paste(candidate_cols, collapse = ", "), "\n")
missing_candidates <- setdiff(
  c(
    "endpoint", "effect", "obs_duration_mean", "obs_duration_unit",
    "duration_hrs", "duration_class", "lifestage", "conc1_type",
    "reference_number", "test_id", "result_id", "chemical_grade"
  ),
  names(data_set)
)
cat("Candidate columns NOT present in data_set:", paste(missing_candidates, collapse = ", "), "\n")

for (col in candidate_cols) {
  n_distinct_vals <- length(unique(data_set[[col]][!is.na(data_set[[col]])]))
  cat("\n--- ", col, " (n_distinct = ", n_distinct_vals, ") ---\n", sep = "")
  if (n_distinct_vals <= 60) {
    print(sort(unique(data_set[[col]])))
  } else {
    cat("(>60 distinct values; showing value counts, top 40)\n")
    print(head(sort(table(data_set[[col]]), decreasing = TRUE), 40))
  }
}

# -----------------------------------------------------------------------
# Step 2c — field-removal duplicate count analysis
# -----------------------------------------------------------------------
cat("\n\n========== STEP 2c: FIELD-REMOVAL DUPLICATE COUNT ANALYSIS ==========\n")

key_fields <- c("cas", "latin_name", "media_type", "endpoint", "effect", "lifestage", "duration_hrs")
key_fields <- key_fields[key_fields %in% names(data_set)]
cat("Full candidate key:", paste(key_fields, collapse = ", "), "\n")

dup_count <- function(df, fields) {
  df |>
    group_by(across(all_of(fields))) |>
    summarise(n = n(), .groups = "drop") |>
    filter(n > 1) |>
    nrow()
}

cat("\n--- duplicate count with FULL key ---\n")
print(dup_count(data_set, key_fields))

cat("\n--- duplicate count dropping one field at a time ---\n")
for (f in key_fields) {
  remaining <- setdiff(key_fields, f)
  cat(sprintf("Drop '%s' -> key = [%s]: n_dup_groups = %d\n",
              f, paste(remaining, collapse = ", "), dup_count(data_set, remaining)))
}

# -----------------------------------------------------------------------
# Additional context: test_id / result_id as candidate study-level keys,
# and reference/author/title/source/publication_year as a literal
# bibliographic reference block.
# -----------------------------------------------------------------------
cat("\n\n========== ADDITIONAL: study/reference-identifier candidates ==========\n")
for (col in c("test_id", "result_id", "reference_number", "author", "title", "source", "publication_year")) {
  if (col %in% names(data_set)) {
    cat(sprintf("\n%s: n_non_na = %d, n_distinct = %d\n",
                col, sum(!is.na(data_set[[col]])), length(unique(data_set[[col]][!is.na(data_set[[col]])]))))
  } else {
    cat(sprintf("\n%s: NOT PRESENT\n", col))
  }
}

cat("\n\n========== DONE ==========\n")
