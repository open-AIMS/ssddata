# data-raw/anzg/

This folder contains the source data and scripts for the ANZG (Australian and
New Zealand Guidelines) datasets in the `ssddata` package.

## Tracked files (committed to git)

| File | Description |
|---|---|
| `anzg.csv` | Master species sensitivity data — **the only file you manually edit** |
| `anzg-dgvs-mastertable-<date>.xlsx` | ANZG DGV master table downloaded from waterquality.gov.au |
| `DATASET.R` | Reads `anzg.csv` and regenerates all package data objects and R docs |
| `01_identify_new_datasets.R` | Downloads latest master table, identifies new chemicals |
| `02_scrape_technical_briefs.R` | Attempts to find/download PDFs and data tables, builds scaffolds |
| `03_update_package.R` | Validates, appends BibTeX, sources `DATASET.R`, runs package check |
| `README.md` | This file |

## Gitignored folder: `_review/`

All intermediate outputs from the update workflow are written to `_review/`
and are not committed to git. This folder is created automatically when you
run `01_identify_new_datasets.R`.

```
_review/
│
├── mastertable_source_url.txt      # URL and timestamp of downloaded master table
│
├── candidates_to_add.csv           # Chemicals with year > 2020 not yet in package
├── already_have.csv                # Chemicals currently in anzg_data
├── naming_check.csv                # Chemical/Medium name cleaning diagnostics
│
├── draft_bibtex.bib                # Draft BibTeX entries for all new chemicals
│                                   # Review and fix FIXME fields before running 03
│
├── scrape_log.csv                  # Per-chemical: URLs found, download success,
│                                   # parse status, action needed
│
├── validation_report.txt           # Written by 03_update_package.R
│
└── <chemical>_<medium>/            # One subfolder per candidate chemical, e.g.:
    ├── urls_found.txt              #   All candidate URLs tried and resolved
    ├── technical_brief.pdf         #   Downloaded PDF (if found)
    ├── data_table.xlsx             #   Downloaded data table (if found)
    ├── data_table_raw.csv          #   First data sheet as CSV (for inspection)
    ├── scaffold.csv                #   Pre-filled rows ready to paste into anzg.csv
    │                               #   (needs human review/completion)
    └── draft_bibtex.bib            #   BibTeX entry for this chemical only
```

## Workflow for adding new ANZG datasets

### Step 1 — Identify new chemicals

```r
source("data-raw/anzg/01_identify_new_datasets.R")
```

- Downloads the latest ANZG DGV master table from waterquality.gov.au and saves
  it to `data-raw/anzg/` with its original filename (tracked in git)
- Identifies chemicals with publication year > 2020 not yet in `anzg.csv`
- Writes `_review/candidates_to_add.csv`

To update to a newer master table in future, add the new URL at the top of the
`master_urls` vector in this script — no other changes needed.

### Step 2 — Scrape technical briefs

```r
source("data-raw/anzg/02_scrape_technical_briefs.R")
```

For each candidate chemical:
- Probes multiple URL patterns on waterquality.gov.au for the technical brief
  PDF and data table XLSX
- Downloads both to `_review/<chem>_<medium>/`
- Attempts to auto-parse the species toxicity table into a `scaffold.csv`
- Generates a draft BibTeX entry

Check `_review/scrape_log.csv` — the `action_needed` column tells you what
human input is required per chemical.

### Step 3 — Human review (required)

1. Open `_review/scrape_log.csv` and work through each chemical by `action_needed`:
   - **`REVIEW: scaffold.csv`** — open `_review/<chem>_<medium>/scaffold.csv`,
     verify/complete the data, then append rows to `data-raw/anzg/anzg.csv`
   - **`MANUAL: extract from PDF`** — open `_review/<chem>_<medium>/technical_brief.pdf`,
     manually extract the species table, then append to `anzg.csv`
   - **`MANUAL: no URLs found`** — visit waterquality.gov.au manually, download
     the data table, and append to `anzg.csv`

2. Open `_review/draft_bibtex.bib` and fix all `FIXME_check_pdf` entries
   (page counts, verify PDF URLs resolve correctly)

3. Ensure the `Reference` key in each new `anzg.csv` row matches the
   corresponding key in `draft_bibtex.bib`

### Step 4 — Rebuild and validate

```r
source("data-raw/anzg/03_update_package.R")
```

- Validates `anzg.csv` (column names, Medium values, Conc units, BibTeX keys)
- Appends new BibTeX entries from `_review/draft_bibtex.bib` to `inst/REFERENCES.bib`
- Sources `DATASET.R` to regenerate all `data/*.rda` and `R/anzg_*.R` files
- Runs `devtools::document()` and `devtools::check()`
- Writes `_review/validation_report.txt`

### Step 5 — Commit

When `devtools::check()` passes with 0 errors and 0 warnings:

```bash
git add data-raw/anzg/anzg.csv \
        data-raw/anzg/anzg-dgvs-mastertable-*.xlsx \
        inst/REFERENCES.bib \
        data/ R/ man/
git commit -m "Add remaining ANZG datasets (publication year > 2020), closes #9"
git push origin dev
```

## Key conventions

- **`Conc` is always in µg/L.** ANZG source files sometimes use mg/L — multiply
  by 1000 before adding to `anzg.csv`.
- **`Medium`** must be exactly `"freshwater"` or `"marine water"`.
- **`Chemical`** must be lowercase with underscores only: `[a-z0-9_]`.
- **`Duration (d)`** is stored as character (allows ranges like `"4–14"`).
- **BibTeX key convention:** `<chemical-with-hyphens>-<fresh|marine><year>`,
  e.g. `chlorine-marine2021`, `bisphenol-a-fresh2023`.
- **Do not manually edit** any file under `R/` — `DATASET.R` regenerates them.
