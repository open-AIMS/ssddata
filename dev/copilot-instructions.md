# ssddata — Copilot Instructions

## Project Overview

`ssddata` is a data-only R package providing Species Sensitivity
Distribution (SSD) benchmark datasets for evaluating SSD software
(`ssdtools`, `Burrlioz`). It packages chemical toxicity datasets from
CCME, AIMS, CSIRO, ANZG, EnviroTox, and the US EPA ECOTOX database.

## Architecture

- `R/` — Roxygen2 documentation files only; no logic except utility
  functions
  ([`get_ssddata()`](https://open-aims.github.io/ssddata/dev/reference/get_ssddata.md),
  [`gm_mean()`](https://open-aims.github.io/ssddata/dev/reference/gm_mean.md),
  [`ssd_data_sets()`](https://open-aims.github.io/ssddata/dev/reference/ssd_data_sets.md),
  [`envirotox_data_sets()`](https://open-aims.github.io/ssddata/dev/reference/envirotox_data_sets.md),
  [`list_datasets()`](https://open-aims.github.io/ssddata/dev/reference/list_datasets.md))
- `data/` — Pre-built `.rda` files (one per dataset); loaded via
  `LazyData: true`
- `data-raw/` — Source CSVs by org + build scripts; **not part of
  package build**; maintainer-only
- `tests/testthat/` — testthat edition 3 tests
- `vignettes/` — Quarto-based vignettes
- `inst/REFERENCES.bib` — Rdpack bibliography for `\insertRef{}`
  citations in roxygen docs

## Dataset Conventions

- Individual datasets: `{prefix}_{chemical}` (e.g., `ccme_boron`,
  `aims_ddt`)
- Combined datasets: `{prefix}_data` (e.g., `ccme_data`, `aims_data`)
- Prefixes: `aims`, `ccme`, `csiro`, `anzg`, `anon`, `wqbench`,
  `envirotox`
- All datasets stored as `tbl_df` (or named list for `*_data` aggregates
  of incompatible tables)
- Individual dataset `.R` doc files end with `NULL`; aggregate
  `*_data.R` files end with `"dataset_name"`
- Aggregated derived datasets (e.g. `envirotox_acute`, `wqbench_data`)
  end with `"dataset_name"` (not `NULL`) and have manually authored docs

## Code Style

- **Pipe**: `%>%` (magrittr) in `data-raw/` scripts; native `|>` also
  used in newer scripts; no pipe in `R/` package code
- **Imports**: Only `chk`, `dplyr`, `Rdpack`, `utils` — keep imports
  minimal
- **Input validation**: Use `chk` package for all user-facing function
  arguments (e.g.,
  [`chk::chk_string()`](https://poissonconsulting.github.io/chk/reference/chk_string.html),
  [`chk::chk_flag()`](https://poissonconsulting.github.io/chk/reference/chk_flag.html))
- **Side-effects**: Use
  [`message()`](https://rdrr.io/r/base/message.html) only — no
  [`print()`](https://rdrr.io/r/base/print.html) or
  [`cat()`](https://rdrr.io/r/base/cat.html) in exported functions
- **Docs**: Roxygen2 with markdown; use
  [`Rdpack::reprompt()`](https://geobosh.github.io/Rdpack/reference/reprompt.html)
  and `\insertRef{key}{ssddata}` for literature citations

## Build and Test

``` r

devtools::load_all()
devtools::document()   # regenerates roxygen2 + Rdpack docs
devtools::test()       # runs testthat suite
devtools::check()      # full R CMD CHECK

# Rebuild all datasets from source
source("data-raw/source_all.R")

# Rebuild pkgdown reference index
source("data-raw/build_pkgdown_yml.R")
```

CI runs `R-CMD-check` and `pkgdown` via GitHub Actions.

## Testing Conventions

- Use
  [`chk::check_data()`](https://poissonconsulting.github.io/chk/reference/check_data.html)
  to validate dataset structure and value ranges
- Assert [`message()`](https://rdrr.io/r/base/message.html) side-effects
  with `expect_message()`
- Test files mirror `R/` structure: `tests/testthat/test-{function}.R`

## Adding a New Dataset

1.  Add source CSV(s) to `data-raw/{prefix}/`
2.  Add build code to `data-raw/{prefix}/DATASET.R` using
    `usethis::use_data(..., overwrite = TRUE)`
3.  Create `R/{prefix}_{chemical}.R` with roxygen2 docs ending in `NULL`
4.  Update the relevant `{prefix}_data` aggregate and its `.R` doc file
5.  Run `source("data-raw/source_all.R")` then `devtools::document()`

## pkgdown Reference Structure (`build_pkgdown_yml.R`)

`_pkgdown.yml` is **auto-generated** by `data-raw/build_pkgdown_yml.R` —
never edit it by hand.

Section structure: 1. **Individual SSD datasets** — per-chemical
datasets grouped by `source_prefixes` into subtitles (aims, anon, anzg,
ccme, csiro) 2. **Aggregated SSD datasets** — `{prefix}_data` aggregates
per source org 3. **Aggregated derived SSD datasets** — datasets listed
in `derived_topics`: currently `anztox_data`, `envirotox_data`,
`wqbench_data`; `envirotox_data` gets its own subtitle “Species
Sensitivity Data from the EnviroTox Database” 4. **Fitted SSD results**
— `ssd_fits` 5. **Package functions** — remaining exported functions

Key vectors to update when adding datasets: - `source_prefixes` — add
new org prefixes with heading labels - `derived_topics` — add new
Aggregated derived dataset names - `accounted_for` — add topics that
should be silently excluded from the reference page (use
`@keywords internal` on the `.R` doc file as well)

## Utility Functions (R/get_ssddata.R)

- **[`ssd_data_sets()`](https://open-aims.github.io/ssddata/dev/reference/ssd_data_sets.md)**
  — returns named list of all individual per-chemical datasets (28
  datasets); explicitly excludes `ssd_fits`, `*_data` aggregates, and
  `envirotox_*` datasets
- **[`envirotox_data_sets()`](https://open-aims.github.io/ssddata/dev/reference/envirotox_data_sets.md)**
  — returns sorted character vector of all `envirotox_*` dataset names
  (`envirotox_acute`, `envirotox_chemical`, `envirotox_chronic`,
  `envirotox_data`)
- **[`list_datasets()`](https://open-aims.github.io/ssddata/dev/reference/list_datasets.md)**
  — deprecated alias for
  [`envirotox_data_sets()`](https://open-aims.github.io/ssddata/dev/reference/envirotox_data_sets.md);
  fires a [`warning()`](https://rdrr.io/r/base/warning.html) directing
  users to rename; kept for backward compatibility with the standalone
  `envirotox` package workflow; marked `@keywords internal`

------------------------------------------------------------------------

## envirotox Integration

### Overview

The full reproducible build pipeline from
[`poissonconsulting/envirotox`](https://github.com/poissonconsulting/envirotox)
has been subsumed directly into `ssddata`. `ssddata` is self-contained —
no dependency on the non-CRAN `envirotox` package at runtime or build
time. The raw source file `envirotox.xlsx` (EnviroTox database 2.0.0)
must be placed in `data-raw/envirotox/` before running the build script;
it is not committed to the repository.

### Datasets

Four datasets are exported under the `envirotox` prefix:

#### `envirotox_acute` — ~14,949 rows × 6 columns

Acute toxicity records (EC50/LC50) aggregated to one geometric mean
concentration per species per chemical. Doc file ends with
`"envirotox_acute"` (Aggregated derived). Marked `@keywords internal` so
it does not appear as a separate reference page entry — linked via
`@seealso` from `envirotox_data`.

| Column | Type | Description |
|----|----|----|
| `Chemical` | chr | Chemical name |
| `Conc` | dbl | Geometric mean concentration (µg/L) |
| `Species` | chr | Latin species name |
| `Group` | chr | Taxonomic group (sentence case) |
| `Yanagihara24` | lgl | Meets Yanagihara et al. (2024) criteria: ≥10 species, ≥3 trophic groups, BC ≤ 0.555 |
| `Iwasaki25` | lgl | Meets Iwasaki et al. (2025) criteria: \>50 species, ≥3 trophic groups, excludes certain metals |

#### `envirotox_chronic` — ~1,721 rows × 5 columns

Chronic toxicity records (NOEC/NOEL). Same structure as acute minus
`Iwasaki25`. Marked `@keywords internal`.

#### `envirotox_chemical` — 744 rows × 2 columns

Chemical name → CAS Registry Number lookup. Not SSD-ready data. Marked
`@keywords internal`.

| Column        | Type | Description                               |
|---------------|------|-------------------------------------------|
| `Chemical`    | chr  | Chemical name (primary key)               |
| `OriginalCAS` | int  | Original CAS Registry Number (also a key) |

#### `envirotox_data`

Named list wrapper:
`list(acute = envirotox_acute, chronic = envirotox_chronic, chemical = envirotox_chemical)`.
This is the **primary reference page entry** for envirotox — appears
under “Species Sensitivity Data from the EnviroTox Database” subtitle in
Section 3 of the pkgdown reference page.

### Build Pipeline (`data-raw/envirotox/DATASET.R`)

Processes `envirotox.xlsx` (sheets: `test`, `substance`, `taxonomy`): 1.
Filter: acute = EC50/LC50 `Test.type=="A"`; chronic = NOEC/NOEL
`Test.type=="C"`; exclude `Effect.is.5X.above.water.solubility=="1"` 2.
Unit convert: mg/L → µg/L (×1000) 3. Geometric mean per
`original.CAS × Latin.name` using
[`EnvStats::geoMean()`](https://alexkowa.github.io/EnvStats/reference/geoMean.html)
4. Threshold: ≥6 species, ≥2 trophic groups per chemical 5. Bimodality
coefficient via `mousetrap::bimodality_coefficient(log10(Conc))` for
`Yanagihara24` flag 6. Group normalisation: `"Invert"` →
`"Invertebrate"`, `"Amphib"` → `"Amphibian"`, sentence case 7.
`OriginalCAS` retained only in `envirotox_chemical`; dropped from
acute/chronic 8. Integrity checks via
[`chk::check_key()`](https://poissonconsulting.github.io/chk/reference/check_key.html)
before saving

### References (inst/REFERENCES.bib)

- `Connors2019` — EnviroTox database (<doi:10.1002/etc.4382>)
- `Yanagihara2024` — distribution comparison
  (<doi:10.1016/j.ecoenv.2024.116379>)
- `Iwasaki2025` — model-averaging (<doi:10.1093/etojnl/vgae060>)

### Build-time Suggests (DESCRIPTION)

`EnvStats`, `mousetrap`, `openxlsx`, `stringr` — needed only in
`data-raw/`; not required at runtime.

------------------------------------------------------------------------

## Full Build Script (`scripts/build.R`)

A convenience script at `scripts/build.R` runs the full build pipeline
in order:

``` r

devtools::build_readme()
source("data-raw/source_all.R")        # rebuild all datasets
devtools::document()                    # regenerate docs
source("data-raw/build_pkgdown_yml.R") # regenerate _pkgdown.yml
pkgdown::build_site()
devtools::test()
devtools::check()
```

Use this for a full clean rebuild. For incremental work, run individual
steps.

------------------------------------------------------------------------

## anztox Integration (`data-raw/anztox/`)

`anztox_data` is a Aggregated derived dataset built from the **ANZTOX
database** (a PostgreSQL database of Australian/NZ toxicity data). It is
exported as a single aggregate tibble (not a named list) and documented
in `R/anztox_data.R` ending with `"anztox_data"`. It appears under
“Aggregated derived SSD datasets” in `_pkgdown.yml`.

### Build Pipeline (`data-raw/anztox/DATASET.R`)

Connects to a local PostgreSQL instance via `DBI`/`RPostgres`. Key
steps: - **`normalize_cas()`** — standardises CAS numbers (fixes
Excel-style extra zeros, strips non-numeric, removes leading zeros) -
**`normalize_mediatype()`** — maps freetext medium to `"Freshwater"` /
`"Marine"` - **`normalize_name()`** — lowercases and strips special
characters for fuzzy matching - **`ACR_DEFAULT <- 10`** — default
acute-to-chronic ratio (Warne et al. 2025, Section 3.4.2.2); divides
acute concentrations by 10 when no chronic data exist - Uses
`cas_parent_lookup.csv` and `endpoint_2016_to_2000_lookup.csv` to
harmonise endpoints across database versions - `run_diagnostics` and
`write_outputs` flags control optional CSV diagnostic outputs

### Supporting files

- `data-raw/anztox/cas_parent_lookup.csv` — maps child CAS numbers to
  parent CAS
- `data-raw/anztox/endpoint_2016_to_2000_lookup.csv` — maps 2016-style
  endpoints to 2000-style
- `data-raw/anztox/endpoint_2016_to_2000_lookup_build.R` — script that
  built the lookup
- `vignettes/ANZTOX_data_processing.qmd` — vignette explaining the full
  data processing workflow
- `vignettes/endpoint_2016_to_2000_lookup_build.qmd` — vignette
  explaining endpoint harmonisation

------------------------------------------------------------------------

## ANZG Dataset Build Pipeline (`data-raw/anzg/`)

The ANZG pipeline has multiple numbered scripts run in sequence:

1.  **`01_identify_new_datasets.R`** — downloads the master table from
    waterquality.gov.au, identifies candidate chemicals not yet in the
    package, and writes review CSVs to `data-raw/anzg/_review/`. Key
    helper functions:

    - **`extract_roman(x)`** — converts bracketed roman numeral suffixes
      e.g. `"(CrIII)"` → `"_III"` using regex
      `\\(([A-Za-z]*?)(VIII|VII|VI|IV|V|III|II|I)\\)`. **The `*?`
      (non-greedy) quantifier is critical** — greedy `*` causes
      `(CrIII)` to match `CrII` as prefix leaving only `I`, producing
      `_I` instead of `_III`.
    - **`clean_chemical(x)`** — normalises toxicant names to valid R
      dataset name suffixes. Pipeline order matters: `extract_roman()` →
      `str_replace_all("[\\s\\-]+", "_")` →
      [`tolower()`](https://rdrr.io/r/base/chartr.html) → restore roman
      numerals to uppercase via `\\b` word boundary → strip
      non-alphanumeric → collapse `_+` → `str_trim()`.
      **`str_replace_all()` does not accept `perl = TRUE`** (that is a
      base R [`gsub()`](https://rdrr.io/r/base/grep.html) argument);
      `stringr` uses ICU engine which supports lookaheads and word
      boundaries natively.
    - **`clean_medium(x)`** — maps raw medium strings from the master
      table to standardised dataset name suffixes: `"Freshwater"` →
      `"fresh"`, `"Marine"` → `"marine"`, `"Soft freshwater"` →
      `"soft_fresh"`, `"Hard freshwater"` → `"hard_fresh"`,
      `"Moderate freshwater"` → `"moderate_fresh"`. Used when
      constructing dataset names like `anzg_nitrate_hard_fresh`.
    - **`parse_subconditions()`** — expands multi-value rows
      (e.g. `"Nitrate/Freshwater"`) in the master table into separate
      rows before chemical/medium name parsing.

2.  **`02_scrape_technical_briefs.R`** — scrapes SSD data from ANZG
    technical brief pages. Downloads PDF technical briefs and extracts
    species toxicity data, writing per-chemical CSVs to
    `data-raw/anzg/anzg_technical_briefs/{chemical_medium}/`.

3.  **`03_update_package.R`** — convenience wrapper that sources
    `DATASET.R` then runs `devtools::document()` and
    `devtools::load_all()`.

4.  **`DATASET.R`** — builds final `.rda` files from scraped CSVs using
    `usethis::use_data(..., overwrite = TRUE)`.

### Medium Naming Conventions for ANZG Datasets

ANZG datasets support multiple medium suffixes reflecting water
hardness/salinity conditions:

| Master table value      | Dataset suffix    | Example dataset               |
|-------------------------|-------------------|-------------------------------|
| `"Freshwater"`          | `_fresh`          | `anzg_nitrate_fresh`          |
| `"Marine"`              | `_marine`         | `anzg_copper_marine`          |
| `"Soft freshwater"`     | `_soft_fresh`     | `anzg_nitrate_soft_fresh`     |
| `"Hard freshwater"`     | `_hard_fresh`     | `anzg_nitrate_hard_fresh`     |
| `"Moderate freshwater"` | `_moderate_fresh` | `anzg_nitrate_moderate_fresh` |

When a chemical has multiple medium variants, each variant is a
**separate dataset** with its own `.R` doc file ending in `NULL` and its
own `.rda` file. All variants are included in the `anzg_data` aggregate.

### New ANZG Datasets Added (branch `addmoreANGZ`)

The following datasets were added in this branch: - **Freshwater**:
`anzg_diuron_fresh`, `anzg_dioxins_fresh`, `anzg_fipronil_fresh`,
`anzg_fluoride_fresh`, `anzg_glyphosate_fresh`, `anzg_iron_fresh`,
`anzg_mancozeb_fresh`, `anzg_mcpa_fresh`,
`anzg_metsulfuron_methyl_fresh`, `anzg_paraquat_fresh`,
`anzg_perfluorooctane_sulfonate_pfos_fresh`, `anzg_picloram_fresh`,
`anzg_simazine_fresh`, `anzg_sulfometuron_methyl_fresh` - **Marine**:
`anzg_chlorine_marine`, `anzg_copper_marine`, `anzg_diuron_marine`,
`anzg_iron_marine`, `anzg_manganese_marine`, `anzg_nickel_marine`,
`anzg_simazine_marine`, `anzg_zinc_marine` - **Hardness-specific
(nitrate)**: `anzg_nitrate_hard_fresh`, `anzg_nitrate_moderate_fresh`,
`anzg_nitrate_soft_fresh`

### Build Infrastructure Added

- **`scripts/build.R`** — full clean-rebuild convenience script (see
  Full Build Script section).
- **`.Rbuildignore`** updated to exclude `data-raw/` from the CRAN
  `.tar.gz` submission tarball.
- **`data-raw/anzg/README.md`** — documents the ANZG update workflow for
  maintainers.
