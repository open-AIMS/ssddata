# ssddata Package Builder Script Research

## Summary
The ssddata package uses a multi-layered builder system located in `data-raw/` that sources raw data from multiple directories, normalizes them, and outputs `.rda` (R data) files to the `data/` directory. The system also generates documentation via roxygen2.

---

## 1. Builder Script Location

### Primary Files
- **Main orchestrator**: `data-raw/source_all.R` - Runs all dataset builders
- **Generic data creation functions**: `data-raw/create_data.R` - Contains helper functions for data and doc generation
- **Dataset-specific builders**: `data-raw/{DATASET_NAME}/DATASET.R` for each dataset
  - `data-raw/anztox/DATASET.R` (largest/most complex)
  - `data-raw/anzg/DATASET.R`
  - `data-raw/csiro/DATASET.R`
  - `data-raw/ccme/DATASET.R`
  - `data-raw/aims/DATASET.R`
  - `data-raw/anon/DATASET.R`

### File Structure
```
data-raw/
├── source_all.R                    # Master coordinator
├── create_data.R                   # Shared utilities (create_data, create_data_subset)
├── anztox/
│   ├── DATASET.R                   # Main builder (connects to PostgreSQL DB)
│   ├── endpoint_2016_to_2000_lookup_build.R
│   ├── endpoint_2016_to_2000_lookup.csv
│   ├── raw/
│   │   ├── cas_parent_lookup.csv
│   │   ├── toxicants-dgvs-mastertable-april2026.csv
│   │   └── (database references via PostgreSQL)
│   └── toxicityvalue_combined_clean.csv  # Intermediate output
├── anzg/
│   ├── DATASET.R
│   ├── anzg.csv (raw input CSV)
│   ├── anzg-dgvs-mastertable-feb-2026.xlsx
│   └── doc_template.Rd, doc_data_template.Rd
├── csiro/
│   ├── DATASET.R
│   └── csiro.csv
├── ccme/
│   ├── DATASET.R
│   └── CCME data.csv
└── ... (other datasets)
```

---

## 2. Output Tables

### Primary Output Structure
All builders ultimately generate `.rda` files in the `/data` directory via `usethis::use_data()`. There are no CSV outputs to the package—only R binary data files.

### ANZTOX (Most Complex Example)

**Main outputs:**
1. **`anztox_data.rda`** - Nested list of eligible species for SSD model fitting
2. **Intermediate CSV (not packaged)**: `data-raw/anztox/toxicityvalue_combined_clean.csv`

### Output Categories (from anztox/DATASET.R lines 755-777)
If `run_diagnostics = TRUE`, the script generates:
- `source_counts` - Count of rows by source dataset (2000 vs 2016)
- `source_eligible_counts` - Count of eligible rows by source dataset
- `acr_summary` - ACR conversion statistics by chemical and media type

---

## 3. Data Structures & Column Names

### ANZTOX Pipeline - Core Columns (Line 501-514)

**Combined Clean Data** (`toxicityvalue_combined_clean.csv`):
```
source_dataset          # "2000" or "2016"
toxicityvalue_id        # Row identifier
casnumber               # Chemical CAS registry number (character)
commonname              # Toxicant common name
mediatype               # "Freshwater" or "Marine" (normalized)
scientificname          # Species genus + species
commonname_species      # Common name of species
majorgroup              # Broad taxonomic group
minorgroup              # More specific taxonomic group
testtype                # "Chronic", "Acute", or "Subchronic" (pre-filtering)
endpoint                # Endpoint code (e.g., LC50, EC10)
concentrationused       # Used toxicity value (μg/L)
concentration           # Copy of concentrationused
reference_bib           # Full citation string
```

**Plus joined fields:**
```
casnumber_grouped       # Parent CAS if available, else original
chemicalname_grouped    # Parent chemical name if available, else common name
```

---

### SSD-Eligible Species Data (`ssd_species_eligible_combined`, Line 548-620)

After filtering and processing steps 1-6:

**Key Columns:**
```
casnumber_grouped                   # Parent CAS number
chemicalname_grouped                # Parent/canonical chemical name
mediatype                           # "Freshwater" or "Marine"
scientificname                      # Species binomial name
commonname_species                  # Species common name
majorgroup                          # Taxonomic major group
minorgroup                          # Taxonomic minor group
endpoint                            # Most sensitive endpoint per species
testtype                            # "Chronic" (includes reclassified subchronic)
endpoint_concentration              # Geometric mean concentration (μg/L)
source_datasets                     # Semicolon-separated source list ("2000;2016")
n_acute_converted                   # Count of acute records converted via ACR
```

### Nested Output (`anztox_data.rda`, Line 631)

```
casnumber_grouped           # Grouping key
chemicalname_grouped        # Grouping key
mediatype                   # Grouping key
data (nested tibble)        # Contains columns listed above for SSD fitting
```

---

## 4. Helper & Normalisation Functions

### Normalisation Functions (Lines 25-76 in anztox/DATASET.R)

**1. `normalize_cas(x)`** - Standardizes CAS numbers
- Strips whitespace, empty strings, dashes
- Removes Excel-style zero-padding: `7783-06-04` → `7783-06-4`
- Removes all non-numeric characters
- Strips leading zeros
- Returns NA for empty results

**2. `normalize_mediatype(x)`** - Standardizes media type values
- Converts to lowercase, strips whitespace
- Recodes:
  - "freshwater" → "Freshwater"
  - "marine" / "marine water" → "Marine"
  - Others → NA

**3. `normalize_name(x)`** - Creates searchable chemical names
- Converts to lowercase
- Replaces non-alphanumeric characters with spaces
- Strips extra whitespace
- Used for name-based matching in lookups

**4. `build_reference_bib()`** - Constructs citation strings
- Concatenates authors, year, title, journal, volume, issue, pages
- Uses `coalesce()` to handle missing fields gracefully
- Produces format: "Author(s) (YYYY). Title. Journal, Vol(Issue): pp-pp."

### Data Processing Helpers

**Database Connections:**
- `get_db_password()` - Retrieves PostgreSQL password from env var or keyring
- `DBI::dbConnect()` / `RPostgres::Postgres()` - Connects to infogathering database
- `dbReadTable()` - Reads lookup and fact tables from PostgreSQL

**Lookup Building (Lines 638-709):**
- `name_cas_lookup` - Combines CAS parent lookup and tox data for name→CAS mapping
- `name_cas_unique` - Filters to unambiguous name→CAS mappings
- Used as fallback when DGV records lack raw CAS

### Data Wrangling Pipeline

**Step 1: Base Filters** (Lines 559-566)
- Remove NA concentrations, zero concentrations
- Require valid scientific names, test type, media type, CAS number

**Step 2: Test Type Classification & Priority** (Lines 568-584)
- Classify as chronic/subchronic/acute
- Select priority: chronic > subchronic > acute within species groups
- Reclassify subchronic as chronic if selected

**Step 3: ACR Conversion** (Lines 587-603)
- Applied only to acute records where no chronic/subchronic data exist
- Converts: `concentration_chronic_equiv = concentrationused / ACR_DEFAULT`
- `ACR_DEFAULT = 10` (Warne et al. 2025 Section 3.4.2.2)
- Flags with `acr_applied = TRUE`

**Step 4: Geometric Mean** (Lines 606-620)
- Within chemical × media × species × endpoint groups
- Formula: `exp(mean(log(concentration_chronic_equiv)))`

**Step 5: Most Sensitive Endpoint** (Lines 623-627)
- Per species (keeps lowest concentration endpoint)

**Step 6: SSD Eligibility Threshold** (Lines 630-634)
- Requires ≥ 5 species from ≥ 4 distinct major taxonomic groups
- Filters `ssd_species_eligible_combined` to qualifying chemical-media combinations

---

## 5. Generic Data Creation Functions (create_data.R)

### `create_data()` - Line 36
**Purpose**: Creates full long-format dataset with all columns + reference info

**Parameters:**
- `data` - Input tibble
- `col_desc_list` - Named list of column descriptions
- `template` - Path to .Rd template file
- `prefix` - Dataset prefix (e.g., "anzg", "csiro")
- `ref_col` - Reference column name (default: "Reference")
- `chem_col` - Chemical/grouping column name
- `ref_dat` - Optional reference data frame

**Outputs:**
- Saves `.rda` file: `R/{prefix}_data.rda` (via `use_data()`)
- Generates documentation `.R` file: `R/{prefix}_data.R`

### `create_data_subset()` - Line 147
**Purpose**: Creates separate `.rda` files for each unique chemical-media combination

**Parameters:** Same as `create_data()` (but loops through unique `chem_col` values)

**Processing:**
- Iterates through unique values in `chem_col` (e.g., "chemical_fresh", "chemical_marine")
- Extracts chemical name and medium from the key
- Filters data for that combination
- Saves as: `R/{prefix}_{item}.rda`
- Generates individual documentation `.R` files

---

## 6. Master Execution (source_all.R)

**Lines 1-6:**
```r
files <- unlist(sapply(list.dirs("data-raw")[-1], FUN = function(x) {
  list.files(x, pattern = "[.][rR]$", full.names = TRUE)
}))

# Remove wqbench (manually documented)
files <- setdiff(files, "data-raw/wqbench/DATASET.R")

invisible(lapply(files, source))
roxygen2md::roxygen2md()
devtools::document()
```

**Execution order:**
1. Finds all `.R` files in `data-raw/` subdirectories
2. Excludes `data-raw/wqbench/DATASET.R` (manual docs only)
3. Sources each `DATASET.R` file in sequence
4. Converts roxygen markdown to Rd format
5. Generates documentation via roxygen2

---

## 7. Key Data Structures Summary

| Dataset | Main Output | Key Grouping Columns | N Output Files |
|---------|-------------|-------------------|-----------------|
| **anztox** | anztox_data.rda | casnumber_grouped, mediatype | 1 nested |
| **anzg** | anzg_data.rda + individual chem files | Chemical, Medium | 1 + N subsets |
| **csiro** | csiro_data.rda + individual chem files | Chemical, Medium | 1 + N subsets |
| **ccme** | ccme_data.rda + individual chem files | Chemical | 1 + N subsets |
| **aims** | aims_data.rda + individual chem files | Chemical, Medium | 1 + N subsets |

---

## 8. Coverage & Unmapped Concepts

Based on the code review, there are **no explicit "coverage" or "unmapped" tables** written as CSV outputs.

However, **diagnostic data** (if `run_diagnostics = TRUE`) includes:

### ANZTOX Diagnostics (Lines 755-768):
- **`source_counts`** - Row count by source (2000 Dataset vs 2016 Dataset)
- **`source_eligible_counts`** - Eligible rows by source after filtering
- **`acr_summary`** - Proportions of records requiring ACR conversion per chemical-media pair
  - Columns: `casnumber_grouped`, `mediatype`, `n_species_rows`, `n_acr_converted`, `pct_acr_converted`

### DGV Matching Summary (Line 697):
- **`summary_2000_dgvs_combined`** - Four-category breakdown:
  1. Total 2000 DGVs
  2. Matched to anztox_data
  3. Unmatched - likely SSD-derived (reliability ≠ "Unknown")
  4. Unmatched - other method (reliability = "Unknown")

These diagnostics are **not automatically written to disk** unless explicitly added to the script.

---

## Key File Paths Quick Reference

| Item | Path |
|------|------|
| Master coordinator | `data-raw/source_all.R` |
| Helper functions | `data-raw/create_data.R` |
| ANZTOX builder | `data-raw/anztox/DATASET.R` |
| ANZTOX CAS lookup | `data-raw/anztox/raw/cas_parent_lookup.csv` |
| ANZTOX DGV input | `data-raw/anztox/raw/toxicants-dgvs-mastertable-april2026.csv` |
| ANZTOX combined clean | `data-raw/anztox/toxicityvalue_combined_clean.csv` |
| Package data output | `data/*.rda` |
| ANZG CSV input | `data-raw/anzg/anzg.csv` |
| CSIRO CSV input | `data-raw/csiro/csiro.csv` |
| CCME CSV input | `data-raw/ccme/CCME data.csv` |
