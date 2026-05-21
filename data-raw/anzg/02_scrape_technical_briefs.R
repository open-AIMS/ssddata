# =============================================================================
# 02_scrape_technical_briefs.R
# This code was written by Claude Sonnet 4.6 on the 2024-06-19 but has been verified as
# correct by the author of the package, and is now ready for review and merging.
#
# PURPOSE:
#   For each candidate chemical identified in 01_identify_new_datasets.R:
#   - Attempt to construct / resolve the technical brief URL and data table URL
#   - Download both to data-raw/anzg/_review/<chemical>_<medium>/
#   - Attempt to extract the species toxicity table from the data table XLSX
#   - Write a per-chemical scaffold CSV (rows to be added to anzg.csv) with
#     as many fields pre-filled as possible, for human review/completion
#   - Generate draft BibTeX entries for inst/REFERENCES.bib
#
# OUTPUTS (all gitignored under data-raw/anzg/_review/):
#   _review/<chem>_<medium>/
#       technical_brief.pdf            raw PDF (if downloadable)
#       data_table.xlsx                raw data table (if downloadable)
#       data_table_raw.csv             first plausible sheet as CSV
#       scaffold.csv                   pre-filled rows for anzg.csv (needs checking)
#   _review/draft_bibtex.bib           draft BibTeX entries for all new chemicals
#   _review/scrape_log.csv             success/failure log for each chemical
#
# RUN FROM: project root
# REQUIRES: 01_identify_new_datasets.R has been run first
# =============================================================================

library(httr)
library(readxl)
library(dplyr)
library(stringr)
library(readr)
library(purrr)
library(fs)
library(glue)

# -----------------------------------------------------------------------------
# 0. Helpers
# -----------------------------------------------------------------------------
review_dir <- "data-raw/anzg/_review"
if (!dir_exists(review_dir)) {
  stop("Review directory not found. Run 01_identify_new_datasets.R first.")
}

candidates_path <- file.path(review_dir, "candidates_to_add.csv")
if (!file_exists(candidates_path)) {
  stop("candidates_to_add.csv not found. Run 01_identify_new_datasets.R first.")
}

candidates <- read_csv(candidates_path, show_col_types = FALSE)

# Browser-like User-Agent — same as 01_identify_new_datasets.R, applied to
# all requests to waterquality.gov.au so the server doesn't reject them.
browser_agent <- paste0(
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) ",
  "AppleWebKit/537.36 (KHTML, like Gecko) ",
  "Chrome/124.0.0.0 Safari/537.36"
)

# Try downloading a URL; returns local path on success, NA on failure
try_download <- function(url, dest, timeout_s = 60) {
  if (is.na(url) || url == "") {
    return(NA_character_)
  }
  resp <- tryCatch(
    GET(
      url,
      add_headers(`User-Agent` = browser_agent),
      write_disk(dest, overwrite = TRUE),
      timeout(timeout_s)
    ),
    error = function(e) NULL
  )
  if (!is.null(resp) && status_code(resp) == 200) {
    dest
  } else {
    if (file_exists(dest)) {
      file_delete(dest)
    }
    NA_character_
  }
}

# Check a URL without downloading (HEAD request)
url_exists <- function(url, timeout_s = 15) {
  if (is.na(url) || url == "") {
    return(FALSE)
  }
  resp <- tryCatch(
    HEAD(url, add_headers(`User-Agent` = browser_agent), timeout(timeout_s)),
    error = function(e) NULL
  )
  !is.null(resp) && status_code(resp) == 200
}

# -----------------------------------------------------------------------------
# 1. URL construction helpers
#
# ANZG uses two URL patterns for technical briefs:
#   Pattern A (newer, since ~2023):
#     .../toxicants-<slug>-dgvs-technical-brief.pdf
#   Pattern B (older):
#     .../toxicants/<slug>-<medium>-<year>   (HTML page)
#     .../documents/<chemical>_<medium>_dgv_technical-brief.pdf
#
# We build candidate slugs from Chemical + Medium + Year and probe them.
# -----------------------------------------------------------------------------
base_pdf_url <- "https://www.waterquality.gov.au/sites/default/files/documents"
base_page_url <- "https://www.waterquality.gov.au/anz-guidelines/guideline-values/default/water-quality-toxicants/toxicants"

# Convert Chemical (underscore form) + Medium to URL slugs
# e.g. Chemical="bisphenol_a", Medium="freshwater" ->
#   chemical_slug = "bisphenol-a"    (underscores back to hyphens for URLs)
#   medium_slug   = "fresh"
chemical_to_slug <- function(chem) str_replace_all(chem, "_", "-")
medium_to_slug <- function(med) {
  if_else(str_detect(med, "fresh"), "fresh", "marine")
}

build_pdf_candidates <- function(chem, med, year) {
  chem_slug <- chemical_to_slug(chem)
  med_slug <- medium_to_slug(med)
  c(
    # Pattern A (most common from ~2023 onwards)
    glue("{base_pdf_url}/{chem_slug}-{med_slug}-dgvs-technical-brief.pdf"),
    # Pattern A variant with "draft"
    glue(
      "{base_pdf_url}/{chem_slug}-{med_slug}-dgvs-draft-technical-brief.pdf"
    ),
    # Pattern B older style (underscores, different suffix)
    glue("{base_pdf_url}/{chem_slug}_{med_slug}_dgv_technical-brief.pdf"),
    glue("{base_pdf_url}/{chem_slug}-{med_slug}-dgv-technical-brief.pdf")
  )
}

build_xlsx_candidates <- function(chem, med, year) {
  chem_slug <- chemical_to_slug(chem)
  med_slug <- medium_to_slug(med)
  c(
    glue("{base_pdf_url}/{chem_slug}-{med_slug}-dgvs-data-table.xlsx"),
    glue("{base_pdf_url}/{chem_slug}-{med_slug}-data-table.xlsx"),
    glue("{base_pdf_url}/{chem_slug}_{med_slug}_dgvs_data_table.xlsx"),
    glue(
      "{base_pdf_url}/{chem_slug}-{med_slug}-dgvs-technical-brief-data-table.xlsx"
    )
  )
}

build_page_candidates <- function(chem, med, year) {
  chem_slug <- chemical_to_slug(chem)
  med_slug <- medium_to_slug(med)
  c(
    glue("{base_page_url}/{chem_slug}-{med_slug}-{year}"),
    glue("{base_page_url}/{chem_slug}-{med_slug}")
  )
}

# Find the first URL from a list that actually resolves
probe_urls <- function(candidates) {
  for (url in candidates) {
    if (url_exists(url)) return(url)
  }
  NA_character_
}

# -----------------------------------------------------------------------------
# 2. Attempt to parse a species table from an ANZG data table XLSX
#
# ANZG data tables are not perfectly standardised but typically have:
#   - A sheet with "data" or "toxicity" in its name, or the first sheet
#   - A header row somewhere in the first ~10 rows
#   - Columns including: Species, Genus, Group/Taxonomic group, Conc/Value,
#     Duration, Toxicity measure / Test endpoint
#
# We find the header row by looking for a row containing "species" or "genus".
# -----------------------------------------------------------------------------

anzg_csv_cols <- c(
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
  "Conc"
)

col_map_patterns <- list(
  Group = c("group", "taxonomic group", "taxon"),
  Phylum = c("phylum"),
  Genus = c("genus"),
  Species = c("species"),
  Notes = c("notes", "note", "comment"),
  `Life stage` = c("life stage", "lifestage", "life_stage"),
  `Duration (d)` = c("duration", "duration \\(d\\)", "days"),
  `Toxicity measure` = c("toxicity measure", "toxicity_measure", "measure"),
  `Test endpoint` = c("test endpoint", "test_endpoint", "endpoint"),
  Conc = c(
    "conc",
    "concentration",
    "value",
    "chronic value",
    "hc",
    "gm.*conc",
    "conc.*ug"
  )
)

find_header_row <- function(df_raw) {
  for (i in seq_len(min(15, nrow(df_raw)))) {
    row_vals <- tolower(as.character(unlist(df_raw[i, ])))
    if (
      any(str_detect(row_vals, "species|genus|group|toxicant"), na.rm = TRUE)
    ) {
      return(i)
    }
  }
  1L # fallback: assume row 1 is header
}

parse_anzg_xlsx <- function(xlsx_path, chem, medium) {
  sheets <- excel_sheets(xlsx_path)
  # Prefer a sheet with "data" or "toxicity" in name; otherwise use sheet 1
  data_sheet <- sheets[str_detect(tolower(sheets), "data|toxicity")]
  use_sheet <- if (length(data_sheet) > 0) data_sheet[[1]] else sheets[[1]]

  # Read without header first to find header row
  raw <- read_excel(
    xlsx_path,
    sheet = use_sheet,
    col_names = FALSE,
    col_types = "text"
  )

  hrow <- find_header_row(raw)

  # Re-read with correct header row
  df <- read_excel(
    xlsx_path,
    sheet = use_sheet,
    skip = hrow - 1,
    col_names = TRUE,
    col_types = "text"
  ) |>
    janitor::clean_names(case = "none") # preserve case but remove bad chars

  # Map columns
  df_cols <- names(df)

  map_col <- function(patterns) {
    for (p in patterns) {
      hit <- df_cols[str_detect(tolower(df_cols), p)]
      if (length(hit) > 0) return(hit[[1]])
    }
    NA_character_
  }

  col_mapping <- map(col_map_patterns, map_col)

  # Build scaffold with mapped columns
  scaffold <- tibble(
    Chemical = chem,
    Medium = medium,
    Group = if (!is.na(col_mapping$Group)) {
      df[[col_mapping$Group]]
    } else {
      NA_character_
    },
    Phylum = if (!is.na(col_mapping$Phylum)) {
      df[[col_mapping$Phylum]]
    } else {
      NA_character_
    },
    Genus = if (!is.na(col_mapping$Genus)) {
      df[[col_mapping$Genus]]
    } else {
      NA_character_
    },
    Species = if (!is.na(col_mapping$Species)) {
      df[[col_mapping$Species]]
    } else {
      NA_character_
    },
    Notes = if (!is.na(col_mapping$Notes)) {
      df[[col_mapping$Notes]]
    } else {
      NA_character_
    },
    `Life stage` = if (!is.na(col_mapping$`Life stage`)) {
      df[[col_mapping$`Life stage`]]
    } else {
      NA_character_
    },
    `Duration (d)` = if (!is.na(col_mapping$`Duration (d)`)) {
      df[[col_mapping$`Duration (d)`]]
    } else {
      NA_character_
    },
    `Toxicity measure` = if (!is.na(col_mapping$`Toxicity measure`)) {
      df[[col_mapping$`Toxicity measure`]]
    } else {
      NA_character_
    },
    `Test endpoint` = if (!is.na(col_mapping$`Test endpoint`)) {
      df[[col_mapping$`Test endpoint`]]
    } else {
      NA_character_
    },
    Conc = if (!is.na(col_mapping$Conc)) {
      df[[col_mapping$Conc]]
    } else {
      NA_character_
    },
    Reference = NA_character_, # filled in phase 3
    .scrape_notes = paste(
      "Mapped from sheet:",
      use_sheet,
      "| header_row:",
      hrow,
      "| unmapped cols:",
      paste(names(col_mapping)[is.na(unlist(col_mapping))], collapse = ",")
    )
  )

  # Remove rows where all key fields are NA (junk rows)
  scaffold <- scaffold |>
    filter(!is.na(Species) | !is.na(Genus) | !is.na(Conc))

  list(scaffold = scaffold, col_mapping = col_mapping, raw_df = df)
}

# -----------------------------------------------------------------------------
# 3. BibTeX entry builder
# -----------------------------------------------------------------------------
# Key convention from dev REFERENCES.bib:  <chemical>-<medium>-<year>
# e.g. "boron-fresh2021", "alpha-cypermethrin-fresh2023"
# (hyphens used in key, consistent with new entries in issue comment example)

make_bib_key <- function(chem, medium, year) {
  med_short <- if_else(str_detect(medium, "fresh"), "fresh", "marine")
  # Use hyphenated form for the key (more readable than underscores)
  chem_hyphens <- str_replace_all(chem, "_", "-")
  glue("{chem_hyphens}-{med_short}{year}")
}

make_bib_entry <- function(
  chem,
  medium,
  year,
  title_toxicant,
  url = NA_character_,
  pages = NA_character_
) {
  key <- make_bib_key(chem, medium, year)
  med_str <- if_else(str_detect(medium, "fresh"), "freshwater", "marine water")
  url_str <- if (!is.na(url) && url != "") {
    url
  } else {
    glue(
      "https://www.waterquality.gov.au/anz-guidelines/guideline-values/default/water-quality-toxicants"
    )
  }
  pages_str <- if (!is.na(pages) && pages != "") pages else "FIXME_check_pdf"

  glue(
    '@techreport{{{key},\n',
    '  address     = {{Canberra, Australia}},\n',
    '  title       = {{Toxicant default guideline values for aquatic ecosystem protection: ',
    '{title_toxicant} in {med_str}.}},\n',
    '  institution = {{Australian and New Zealand Governments and Australian State and Territory Governments}},\n',
    '  author      = {{ANZG}},\n',
    '  year        = {{{year}}},\n',
    '  keywords    = {{ssddata}},\n',
    '  pages       = {{{pages_str}}},\n',
    '  url         = {{{url_str}}}\n',
    '}}'
  )
}

# -----------------------------------------------------------------------------
# 4. Main loop over candidates
# -----------------------------------------------------------------------------
log_rows <- list()
all_bibtex <- character(0)

for (i in seq_len(nrow(candidates))) {
  chem <- candidates$Chemical[[i]]
  medium <- candidates$Medium[[i]]
  year <- as.character(candidates$Year_pub_num[[i]])
  # Use original toxicant name for human-readable BibTeX title
  title_toxicant <- if ("Toxicant_name" %in% names(candidates)) {
    candidates$Toxicant_name[[i]]
  } else {
    str_replace_all(chem, "_", " ")
  }
  detail_url <- if ("Detail_url" %in% names(candidates)) {
    candidates$Detail_url[[i]]
  } else {
    NA
  }

  message(sprintf(
    "\n[%d/%d] Processing: %s %s (%s)",
    i,
    nrow(candidates),
    chem,
    medium,
    year
  ))

  chem_dir <- file.path(review_dir, paste0(chem, "_", medium_to_slug(medium)))
  dir_create(chem_dir)

  # --- 4a. Find PDF URL ---
  pdf_candidates <- build_pdf_candidates(chem, medium, year)
  # Also include the URL from the master table "Read the detail" column if present
  if (!is.na(detail_url) && str_detect(tolower(detail_url), "\\.pdf$")) {
    pdf_candidates <- c(detail_url, pdf_candidates)
  }
  pdf_url_found <- probe_urls(pdf_candidates)
  message(
    "  PDF url: ",
    if (is.na(pdf_url_found)) "NOT FOUND" else pdf_url_found
  )

  # --- 4b. Find XLSX data table URL ---
  xlsx_candidates <- build_xlsx_candidates(chem, medium, year)
  xlsx_url_found <- probe_urls(xlsx_candidates)
  message(
    "  XLSX url: ",
    if (is.na(xlsx_url_found)) "NOT FOUND" else xlsx_url_found
  )

  # --- 4c. Find HTML page URL (for reference) ---
  page_candidates <- build_page_candidates(chem, medium, year)
  page_url_found <- probe_urls(page_candidates)

  # Save discovered URLs
  writeLines(
    c(
      paste0("PDF:  ", pdf_url_found),
      paste0("XLSX: ", xlsx_url_found),
      paste0("PAGE: ", page_url_found),
      paste0("MASTER_DETAIL: ", detail_url)
    ),
    file.path(chem_dir, "urls_found.txt")
  )

  # --- 4d. Download PDF ---
  pdf_local <- NA_character_
  if (!is.na(pdf_url_found)) {
    pdf_local <- try_download(
      pdf_url_found,
      file.path(chem_dir, "technical_brief.pdf")
    )
    message("  PDF download: ", if (is.na(pdf_local)) "FAILED" else "OK")
  }

  # --- 4e. Download XLSX and parse ---
  xlsx_local <- NA_character_
  scaffold_rows <- 0L
  parse_notes <- NA_character_

  if (!is.na(xlsx_url_found)) {
    xlsx_local <- try_download(
      xlsx_url_found,
      file.path(chem_dir, "data_table.xlsx")
    )
    message("  XLSX download: ", if (is.na(xlsx_local)) "FAILED" else "OK")
  }

  if (!is.na(xlsx_local) && file_exists(xlsx_local)) {
    parse_result <- tryCatch(
      {
        # janitor may not be installed; handle gracefully
        if (!requireNamespace("janitor", quietly = TRUE)) {
          message(
            "  NOTE: install.packages('janitor') for better column name cleaning"
          )
          # Fall back: minimal version without janitor
          sheets <- excel_sheets(xlsx_local)
          data_sheet <- sheets[str_detect(tolower(sheets), "data|toxicity")]
          use_sheet <- if (length(data_sheet) > 0) {
            data_sheet[[1]]
          } else {
            sheets[[1]]
          }
          raw <- read_excel(
            xlsx_local,
            sheet = use_sheet,
            col_names = FALSE,
            col_types = "text"
          )
          hrow <- find_header_row(raw)
          df <- read_excel(
            xlsx_local,
            sheet = use_sheet,
            skip = hrow - 1,
            col_names = TRUE,
            col_types = "text"
          )
          # Write raw sheet for human inspection
          write_csv(df, file.path(chem_dir, "data_table_raw.csv"))
          list(
            scaffold = NULL,
            message = "janitor not installed; raw CSV written for manual review"
          )
        } else {
          result <- parse_anzg_xlsx(xlsx_local, chem, medium)
          write_csv(result$raw_df, file.path(chem_dir, "data_table_raw.csv"))
          result
        }
      },
      error = function(e) {
        list(scaffold = NULL, message = conditionMessage(e))
      }
    )

    if (!is.null(parse_result$scaffold) && nrow(parse_result$scaffold) > 0) {
      bib_key <- make_bib_key(chem, medium, year)
      parsed_scaffold <- parse_result$scaffold |>
        mutate(Reference = bib_key)
      write_csv(parsed_scaffold, file.path(chem_dir, "scaffold.csv"))
      scaffold_rows <- nrow(parsed_scaffold)
      parse_notes <- parsed_scaffold$.scrape_notes[[1]]
      message(sprintf("  Parsed %d species rows", scaffold_rows))
    } else {
      parse_notes <- if (!is.null(parse_result$message)) {
        parse_result$message
      } else {
        "parse returned no rows"
      }
      message("  Parse result: ", parse_notes)
    }
  }

  # --- 4f. BibTeX entry ---
  # Use PDF url for the bib entry; fall back to page url
  bib_url <- if (!is.na(pdf_url_found)) {
    pdf_url_found
  } else if (!is.na(page_url_found)) {
    page_url_found
  } else {
    NA_character_
  }

  bib_entry <- make_bib_entry(chem, medium, year, title_toxicant, url = bib_url)
  bib_key <- make_bib_key(chem, medium, year)
  writeLines(bib_entry, file.path(chem_dir, "draft_bibtex.bib"))
  all_bibtex <- c(all_bibtex, bib_entry)

  # --- 4g. Log ---
  log_rows[[i]] <- tibble(
    Chemical = chem,
    Medium = medium,
    Year = year,
    bib_key = bib_key,
    pdf_url = pdf_url_found,
    xlsx_url = xlsx_url_found,
    page_url = page_url_found,
    pdf_downloaded = !is.na(pdf_local),
    xlsx_downloaded = !is.na(xlsx_local),
    scaffold_rows = scaffold_rows,
    parse_notes = parse_notes,
    action_needed = case_when(
      is.na(xlsx_url_found) & is.na(pdf_url_found) ~ "MANUAL: no URLs found",
      is.na(xlsx_url_found) &
        !is.na(pdf_url_found) ~ "MANUAL: extract from PDF",
      scaffold_rows ==
        0 ~ "MANUAL: auto-parse failed, check data_table_raw.csv",
      scaffold_rows >
        0 ~ "REVIEW: scaffold.csv pre-filled, verify before adding to anzg.csv"
    )
  )

  message("  Action needed: ", log_rows[[i]]$action_needed)
}

# -----------------------------------------------------------------------------
# 5. Write combined outputs
# -----------------------------------------------------------------------------
log_df <- bind_rows(log_rows)
write_csv(log_df, file.path(review_dir, "scrape_log.csv"))
message("\nWrote ", file.path(review_dir, "scrape_log.csv"))

writeLines(
  paste(all_bibtex, collapse = "\n\n"),
  file.path(review_dir, "draft_bibtex.bib")
)
message("Wrote ", file.path(review_dir, "draft_bibtex.bib"))

# -----------------------------------------------------------------------------
# 6. Summary
# -----------------------------------------------------------------------------
message("\n=== SCRAPE SUMMARY ===")
summary_tbl <- log_df |>
  count(action_needed) |>
  arrange(desc(n))
print(summary_tbl)

message(
  "\nNext steps:\n",
  "1. Review _review/scrape_log.csv for action_needed per chemical\n",
  "2. For 'REVIEW: scaffold.csv' rows: open each _review/<chem>/scaffold.csv,\n",
  "   verify/complete the data, then copy rows into data-raw/anzg/anzg.csv\n",
  "3. For 'MANUAL' rows: manually extract data from the downloaded PDF or\n",
  "   visit the ANZG website to obtain the data table\n",
  "4. Update page counts (FIXME_check_pdf) in _review/draft_bibtex.bib\n",
  "5. Once anzg.csv is complete, run:\n",
  "   source('data-raw/anzg/03_update_package.R')"
)
