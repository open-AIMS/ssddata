# =============================================================================
# 01_identify_new_datasets.R
#
# PURPOSE:
#   - Dynamically download the latest ANZG DGV master table from waterquality.gov.au
#   - Identify chemicals published after 2020 that are not yet in anzg.csv
#   - Write checking outputs to data-raw/anzg/_review/ (gitignored) for human review
#
# OUTPUTS:
#   data-raw/anzg/ (tracked in git):
#     anzg-dgvs-mastertable-<date>.xlsx  downloaded master table (filename from URL)
#
#   data-raw/anzg/_review/ (gitignored):
#     mastertable_source_url.txt         which URL was successfully used
#     candidates_to_add.csv              filtered list: year > 2020, not yet in package
#     already_have.csv                   what is currently in the package (for reference)
#     naming_check.csv                   Chemical/Medium name cleaning diagnostics
#
# RUN FROM: project root  (i.e. source("data-raw/anzg/01_identify_new_datasets.R"))
# =============================================================================

library(httr)
library(readxl)
library(dplyr)
library(stringr)
library(readr)
library(fs)

# -----------------------------------------------------------------------------
# 0. Ensure review folder exists (gitignored)
# -----------------------------------------------------------------------------
review_dir <- "data-raw/anzg/_review"
dir_create(review_dir)

# Remind the user to gitignore this folder if not already done
gitignore_path <- ".gitignore"
if (file_exists(gitignore_path)) {
  gi <- read_lines(gitignore_path)
  if (!any(str_detect(gi, fixed("data-raw/anzg/_review")))) {
    message(
      "NOTE: Add 'data-raw/anzg/_review/' to .gitignore to keep scraped ",
      "files untracked."
    )
  }
}

# -----------------------------------------------------------------------------
# 1. Download latest master table dynamically
# -----------------------------------------------------------------------------
# The ANZG master table is a publicly accessible XLSX served directly from
# waterquality.gov.au. We use a browser-like User-Agent header so the server
# does not reject the request as a bot.
#
# The file is saved to data-raw/anzg/ using the original filename from the URL
# so it is self-documenting and tracked in git alongside anzg.csv.
#
# URL list — most recent first. When ANZG publishes a new master table, add
# its URL at the top of this vector; no other changes are needed.

master_urls <- c(
  "https://www.waterquality.gov.au/sites/default/files/documents/toxicants-dgvs-mastertable-april2026.xlsx",
  "https://www.waterquality.gov.au/sites/default/files/documents/anzg-dgvs-mastertable-feb-2026.xlsx"
  # Add newer URLs here as ANZG publishes updates
)

browser_agent <- paste0(
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) ",
  "AppleWebKit/537.36 (KHTML, like Gecko) ",
  "Chrome/124.0.0.0 Safari/537.36"
)

local_master <- NULL # set inside loop once URL resolves
downloaded <- FALSE

for (url in master_urls) {
  message("Trying: ", url)

  # Derive filename from URL so it is self-documenting in git
  # e.g. "toxicants-dgvs-mastertable-april2026.xlsx"
  filename <- basename(url)
  local_path <- file.path("data-raw/anzg", filename) # tracked in git

  resp <- tryCatch(
    GET(
      url,
      add_headers(`User-Agent` = browser_agent),
      write_disk(local_path, overwrite = TRUE),
      timeout(60)
    ),
    error = function(e) NULL
  )

  if (!is.null(resp) && status_code(resp) == 200) {
    local_master <- local_path
    message("Downloaded master table to: ", local_master)
    # Record source URL in review folder for traceability
    writeLines(
      c(
        paste("URL:        ", url),
        paste("Local file: ", local_master),
        paste("Downloaded: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
      ),
      file.path(review_dir, "mastertable_source_url.txt")
    )
    downloaded <- TRUE
    break
  } else {
    # Clean up any partial download
    if (file_exists(local_path)) {
      file_delete(local_path)
    }
    message(
      "  Failed (status ",
      if (!is.null(resp)) status_code(resp) else "error",
      ")"
    )
  }
}

if (!downloaded) {
  stop(
    "Could not download master table from any known URL.\n",
    "Check for a newer URL at:\n",
    "  https://www.waterquality.gov.au/anz-guidelines/guideline-values/",
    "default/water-quality-toxicants/search/master-table\n",
    "and add it to the master_urls vector at the top of this script."
  )
}

# -----------------------------------------------------------------------------
# 2. Read and inspect master table
# -----------------------------------------------------------------------------
# Excel files from ANZG sometimes have multiple sheets; read the first sheet.
sheets <- excel_sheets(local_master)
message("Sheets found: ", paste(sheets, collapse = ", "))

master_raw <- read_excel(local_master, sheet = 1, col_types = "text")
message(
  "Columns in master table:\n  ",
  paste(names(master_raw), collapse = "\n  ")
)

# -----------------------------------------------------------------------------
# 3. Standardise column names
#
# Column names in the master table have varied across ANZG releases.
# We detect them by pattern matching so the script is robust to minor changes.
# -----------------------------------------------------------------------------
cols <- names(master_raw)

find_col <- function(patterns, cols) {
  for (p in patterns) {
    hit <- cols[str_detect(tolower(cols), p)]
    if (length(hit) > 0) return(hit[[1]])
  }
  NA_character_
}

col_toxicant <- find_col(
  c("toxicant name", "toxicant", "chemical name", "chemical"),
  cols
)
col_medium <- find_col(c("tox medium", "medium", "water type"), cols)
col_year <- find_col(
  c(
    "year published",
    "publication year",
    "pub year",
    "publish date",
    "published date",
    "year"
  ),
  cols
)
col_url <- find_col(c("read the detail", "detail url", "url", "link"), cols)
col_title <- find_col(c("guideline title", "title"), cols)

message(sprintf(
  "Column mapping:\n  toxicant='%s'\n  medium='%s'\n  year='%s'\n  url='%s'\n  title='%s'",
  col_toxicant,
  col_medium,
  col_year,
  col_url,
  col_title
))

if (is.na(col_toxicant) || is.na(col_medium) || is.na(col_year)) {
  stop(
    "Could not auto-detect key columns. Please inspect the master table columns above ",
    "and update the find_col() patterns in this script."
  )
}

# -----------------------------------------------------------------------------
# 4. Normalise chemical and medium names to match anzg.csv conventions
#
# Rules (per issue comment):
#   - Replace spaces and hyphens with underscores
#   - Remove any non-alphanumeric characters (brackets, commas, etc.)
#   - Lowercase everything EXCEPT roman numerals in brackets e.g. (CrIII) -> _III
#   - Collapse multiple underscores
#
# Medium convention in anzg.csv: "freshwater" and "marine" (not "marine water")
# -----------------------------------------------------------------------------

# Roman numeral handler: converts bracketed valence/speciation suffixes like
# "(CrIII)", "(CuII)", "(FeIII)" into "_III", "_II", "_III" etc., preserving
# the uppercase roman numeral before the rest of the string is lowercased.
# Covers I through VIII which encompasses all realistic oxidation states.
extract_roman <- function(x) {
  str_replace_all(x, "\\(([A-Za-z]*?)(VIII|VII|VI|IV|V|III|II|I)\\)", "_\\2")
}

clean_chemical <- function(x) {
  x |>
    extract_roman() |>
    str_replace_all("[\\s\\-]+", "_") |>
    tolower() |>
    str_replace_all("_(viii|vii|vi|iv|v|iii|ii|i)\\b", toupper) |>
    str_replace_all("[^a-zA-Z0-9_]", "") |>
    str_replace_all("_+", "_") |>
    str_trim()
}

clean_medium <- function(x) {
  x_lower <- tolower(str_trim(x))
  dplyr::case_when(
    str_detect(x_lower, "fresh") ~ "freshwater",
    str_detect(x_lower, "marine") ~ "marine", # matches anzg.csv convention
    TRUE ~ x_lower # keep as-is; flagged below
  )
}

master <- master_raw |>
  rename(
    Toxicant_name = all_of(col_toxicant),
    Tox_medium = all_of(col_medium),
    Year_pub = all_of(col_year)
  ) |>
  mutate(
    Year_pub_num = suppressWarnings(as.integer(Year_pub)),
    # "Publish date" may contain a full date string (e.g. "2023-04-01", "April 2023")
    # rather than a bare integer year — extract the 4-digit year as fallback
    Year_pub_num = dplyr::if_else(
      is.na(Year_pub_num),
      suppressWarnings(as.integer(str_extract(Year_pub, "\\d{4}"))),
      Year_pub_num
    ),
    Chemical = clean_chemical(Toxicant_name),
    Medium = clean_medium(Tox_medium),
    medium_flagged = !(Medium %in% c("freshwater", "marine"))
  )

# Carry the URL column if present
if (!is.na(col_url)) {
  master <- master |> rename(Detail_url = all_of(col_url))
} else {
  master <- master |> mutate(Detail_url = NA_character_)
}

# -----------------------------------------------------------------------------
# 4b. Manual corrections for known master-table naming errors/divergences
#
# The master table occasionally contains typos or uses different naming
# conventions to anzg.csv. Add rows here as new cases are discovered.
# Format: tibble with columns Chemical_raw, Medium_raw, Chemical_fix, Medium_fix
# where *_raw are the values produced by clean_chemical/clean_medium above,
# and *_fix are the correct values matching anzg.csv convention.
# -----------------------------------------------------------------------------
name_corrections <- tribble(
  ~Chemical_raw  , ~Medium_raw  , ~Chemical_fix , ~Medium_fix  ,
  # Master table typo: "Bishphenol A" should be "Bisphenol A"
  "bishphenol_a" , "freshwater" , "bisphenol_a" , "freshwater" ,
  "bishphenol_a" , "marine"     , "bisphenol_a" , "marine"
  # Chromium (CrIII) -> chromium_III is now handled automatically by
  # extract_roman() in clean_chemical(); no manual override needed.
  # Add further rows here if new master-table naming divergences are found.
)

master <- master |>
  left_join(
    name_corrections,
    by = c("Chemical" = "Chemical_raw", "Medium" = "Medium_raw")
  ) |>
  mutate(
    Chemical = if_else(!is.na(Chemical_fix), Chemical_fix, Chemical),
    Medium = if_else(!is.na(Medium_fix), Medium_fix, Medium)
  ) |>
  select(-Chemical_fix, -Medium_fix)

# Warn about any medium values that didn't map cleanly
if (any(master$medium_flagged, na.rm = TRUE)) {
  message(
    "WARNING: Some 'Tox_medium' values did not map to 'freshwater' or 'marine':\n  ",
    paste(unique(master$Tox_medium[master$medium_flagged]), collapse = "\n  "),
    "\nCheck 'naming_check.csv' in the review folder."
  )
}

# -----------------------------------------------------------------------------
# 5. Filter to candidates: year > 2020
# -----------------------------------------------------------------------------
candidates <- master |>
  filter(!is.na(Year_pub_num), Year_pub_num > 2020)

message(sprintf(
  "%d records in master table; %d with publication year > 2020",
  nrow(master),
  nrow(candidates)
))

# -----------------------------------------------------------------------------
# 6. Load existing anzg.csv and anti-join
# -----------------------------------------------------------------------------
existing_csv <- "data-raw/anzg/anzg.csv"
if (!file_exists(existing_csv)) {
  stop(
    "Cannot find ",
    existing_csv,
    " - are you running from the project root?"
  )
}

existing <- read_csv(existing_csv, show_col_types = FALSE)
message("anzg.csv columns: ", paste(names(existing), collapse = ", "))

already_have <- existing |>
  distinct(Chemical, Medium) |>
  mutate(in_package = TRUE)

write_csv(already_have, file.path(review_dir, "already_have.csv"))

# Anti-join to find what needs adding
to_add <- candidates |>
  anti_join(already_have, by = c("Chemical", "Medium")) |>
  arrange(Chemical, Medium)

message(sprintf(
  "%d candidate chemicals already in package; %d need to be added",
  nrow(candidates) - nrow(to_add),
  nrow(to_add)
))

# -----------------------------------------------------------------------------
# 7. Write candidates CSV to review folder
# -----------------------------------------------------------------------------
candidates_out <- to_add |>
  select(
    Chemical,
    Medium,
    Toxicant_name,
    Tox_medium,
    Year_pub,
    Year_pub_num,
    Detail_url,
    medium_flagged,
    any_of(na.omit(c("Guideline_title", col_title)))
  )

write_csv(candidates_out, file.path(review_dir, "candidates_to_add.csv"))
message("Wrote ", file.path(review_dir, "candidates_to_add.csv"))

# -----------------------------------------------------------------------------
# 8. Write naming diagnostics (candidates only — year > 2020)
# -----------------------------------------------------------------------------
naming_check <- candidates |>
  select(
    Toxicant_name,
    Tox_medium,
    Chemical,
    Medium,
    medium_flagged,
    Year_pub_num
  ) |>
  mutate(
    chemical_has_issue = str_detect(Chemical, "[^a-zA-Z0-9_]") |
      Chemical == "" |
      is.na(Chemical)
  )

write_csv(naming_check, file.path(review_dir, "naming_check.csv"))
message("Wrote ", file.path(review_dir, "naming_check.csv"))

# -----------------------------------------------------------------------------
# 9. Summary to console
# -----------------------------------------------------------------------------
message("\n=== CHEMICALS TO ADD ===")
print(candidates_out |> select(Chemical, Medium, Year_pub, Detail_url))
message(
  "\nNext step: review ",
  file.path(review_dir, "candidates_to_add.csv"),
  "\nthen run: source('data-raw/anzg/02_scrape_technical_briefs.R')"
)
