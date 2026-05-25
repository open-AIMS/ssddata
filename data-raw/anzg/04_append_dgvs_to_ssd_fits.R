# =============================================================================
# 04_append_dgvs_to_ssd_fits.R
#
# PURPOSE:
#   Using the long-format master table produced by 01_identify_new_datasets.R,
#   append DGV estimates for all matched ANZG chemicals to ssd-fits.csv.
#
#   For each Chemical/Medium combination that exists in BOTH the master table
#   AND anzg.csv (i.e. is already in the package), one row per PC level
#   (99, 95, 90, 80) is added to ssd-fits.csv following the existing schema.
#
# INPUTS:
#   data-raw/anzg/_review/master_long.csv    long-format master table (from 01)
#   data-raw/anzg/anzg.csv                   to look up Reference keys
#   data-raw/ssd-fits.csv                    existing fits file to append to
#
# OUTPUTS:
#   data-raw/ssd-fits.csv                    updated in place (original backed up)
#   data-raw/anzg/_review/dgvs_appended.csv  just the new rows added (for review)
#   data-raw/anzg/_review/dgvs_skipped.csv   rows already present (not duplicated)
#
# RUN FROM: project root
# REQUIRES: 01_identify_new_datasets.R has been run first (produces master_long.csv)
# =============================================================================

library(dplyr)
library(readr)
library(stringr)
library(fs)

# -----------------------------------------------------------------------------
# 0. Paths
# -----------------------------------------------------------------------------
review_dir <- "data-raw/anzg/_review"
master_long_path <- file.path(review_dir, "master_long.csv")
anzg_csv <- "data-raw/anzg/anzg.csv"
fits_path <- "data-raw/ssd-fits/ssd-fits.csv"

stopifnot(
  "master_long.csv not found — run 01_identify_new_datasets.R first" = file_exists(
    master_long_path
  ),
  "anzg.csv not found — run from project root" = file_exists(anzg_csv),
  "ssd-fits.csv not found — run from project root" = file_exists(fits_path)
)

# -----------------------------------------------------------------------------
# 1. Load inputs
# -----------------------------------------------------------------------------
master_long <- read_csv(master_long_path, show_col_types = FALSE)
anzg <- read_csv(anzg_csv, show_col_types = FALSE)
fits <- read_csv(fits_path, show_col_types = FALSE)

message(sprintf("master_long: %d rows", nrow(master_long)))
message(sprintf(
  "anzg.csv: %d rows across %d Chemical/Medium combinations",
  nrow(anzg),
  n_distinct(paste(anzg$Chemical, anzg$Medium))
))
message(sprintf("ssd-fits.csv: %d existing rows", nrow(fits)))

# -----------------------------------------------------------------------------
# 2. Build Reference lookup from anzg.csv
#    (one Reference key per Chemical/Medium)
# -----------------------------------------------------------------------------
ref_lookup <- anzg |>
  distinct(Chemical, Medium, Reference) |>
  # If multiple references per Chemical/Medium, collapse to semicolon-separated
  group_by(Chemical, Medium) |>
  summarise(
    Reference = paste(unique(na.omit(Reference)), collapse = "; "),
    .groups = "drop"
  )

# -----------------------------------------------------------------------------
# 3. Construct new ssd-fits rows from master_long
# -----------------------------------------------------------------------------
# Dataset naming convention (matching existing anzg_ rows in ssd-fits.csv):
#   "anzg_" + Chemical + "_" + Medium with all spaces removed
# e.g. Chemical="nitrate", Medium="soft freshwater" -> "anzg_nitrate_softfreshwater"

new_rows <- master_long |>
  # Join Reference from anzg.csv
  left_join(ref_lookup, by = c("Chemical", "Medium")) |>
  mutate(
    Dataset = paste0(
      "anzg_",
      Chemical,
      "_",
      case_when(
        Medium == "freshwater" ~ "fresh",
        Medium == "marine" ~ "marine",
        str_detect(Medium, "freshwater") ~ paste0(
          str_replace_all(str_remove(Medium, "freshwater"), "\\s+", "_"),
          "fresh"
        ),
        str_detect(Medium, "marine") ~ paste0(
          str_replace_all(str_remove(Medium, "marine"), "\\s+", "_"),
          "marine"
        ),
        TRUE ~ str_replace_all(Medium, " ", "_")
      )
    ),
    Filter = NA_character_,
    Software = "Burrlioz",
    Version = "v2.0",
    Distribution = NA_character_, # not determinable from master table; review needed
    SE = NA_real_,
    Lower = NA_real_,
    Upper = NA_real_,
    Notes = NA_character_
  ) |>
  # Rename to match ssd-fits.csv schema
  rename(PC = PC_level, Estimate = Estimate_ugL) |>
  select(
    Dataset,
    Filter,
    Software,
    Version,
    Distribution,
    PC,
    Estimate,
    SE,
    Lower,
    Upper,
    Reference,
    Notes
  ) |>
  # Only include rows where we have an Estimate
  filter(!is.na(Estimate)) |>
  # PC as character to match ssd-fits.csv
  mutate(PC = PC)

message(sprintf("New rows to consider adding: %d", nrow(new_rows)))

# -----------------------------------------------------------------------------
# 4. De-duplicate: skip rows already present in ssd-fits.csv
#    Match on Dataset + PC (same chemical, same protection level)
# -----------------------------------------------------------------------------
existing_keys <- fits |>
  distinct(Dataset, PC) |>
  mutate(already_present = TRUE)

new_rows_keyed <- new_rows |>
  left_join(existing_keys, by = c("Dataset", "PC"))

to_append <- new_rows_keyed |>
  filter(is.na(already_present)) |>
  select(-already_present)

skipped <- new_rows_keyed |>
  filter(!is.na(already_present)) |>
  select(-already_present)

message(sprintf(
  "%d rows already present in ssd-fits.csv (skipped); %d new rows to append",
  nrow(skipped),
  nrow(to_append)
))

# -----------------------------------------------------------------------------
# 5. Write review outputs
# -----------------------------------------------------------------------------
write_csv(to_append, file.path(review_dir, "dgvs_appended.csv"))
message("Wrote ", file.path(review_dir, "dgvs_appended.csv"))

if (nrow(skipped) > 0) {
  write_csv(skipped, file.path(review_dir, "dgvs_skipped.csv"))
  message("Wrote ", file.path(review_dir, "dgvs_skipped.csv"))
}

# -----------------------------------------------------------------------------
# 6. Append to ssd-fits.csv (with backup)
# -----------------------------------------------------------------------------
if (nrow(to_append) == 0) {
  message("No new rows to append — ssd-fits.csv unchanged.")
} else {
  # Back up the original
  backup_path <- file.path(
    review_dir,
    paste0("ssd-fits-backup-", format(Sys.time(), "%Y%m%d-%H%M%S"), ".csv")
  )
  file_copy(fits_path, backup_path)
  message("Backed up ssd-fits.csv to: ", backup_path)

  # Append and write
  fits_updated <- bind_rows(fits, to_append) |>
    arrange(Dataset, as.integer(PC))

  write_csv(fits_updated, fits_path, na = "")
  message(sprintf(
    "Updated ssd-fits.csv: %d rows (%d added)",
    nrow(fits_updated),
    nrow(to_append)
  ))

  # Summary of what was added
  message("\n=== ROWS APPENDED ===")
  print(
    to_append |>
      group_by(Dataset) |>
      summarise(
        PC_levels = paste(sort(PC), collapse = ", "),
        Estimate_range = paste0(
          min(Estimate, na.rm = TRUE),
          "–",
          max(Estimate, na.rm = TRUE)
        ),
        .groups = "drop"
      )
  )

  message(
    "\nNOTE: 'Distribution' column is NA for all new rows — ",
    "fill in manually after reviewing the technical briefs.\n",
    "Review the appended rows at:\n  ",
    file.path(review_dir, "dgvs_appended.csv")
  )
}
