# ssddata — Copilot Instructions

## Project Overview

`ssddata` is a data-only R package providing Species Sensitivity
Distribution (SSD) benchmark datasets for evaluating SSD software
(`ssdtools`, `Burrlioz`). It packages chemical toxicity datasets from
CCME, AIMS, CSIRO, ANZG, and the US EPA ECOTOX database.

## Architecture

- `R/` — Roxygen2 documentation files only; no logic except three
  utility functions
  ([`get_ssddata()`](https://open-aims.github.io/ssddata/dev/reference/get_ssddata.md),
  [`gm_mean()`](https://open-aims.github.io/ssddata/dev/reference/gm_mean.md),
  [`ssd_data_sets()`](https://open-aims.github.io/ssddata/dev/reference/ssd_data_sets.md))
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
- Prefixes: `aims`, `ccme`, `csiro`, `anzg`, `anon`, `wqbench`
- All datasets stored as `tbl_df`
- Individual dataset `.R` doc files end with `NULL`; aggregate
  `*_data.R` files end with `"dataset_name"`

## Code Style

- **Pipe**: `%>%` (magrittr) in `data-raw/` scripts; no pipe in `R/`
  package code
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
2.  Add build code to `data-raw/create_data.R` using
    `usethis::use_data(..., overwrite = TRUE)`
3.  Create `R/{prefix}_{chemical}.R` with roxygen2 docs ending in `NULL`
4.  Update the relevant `{prefix}_data` aggregate and its `.R` doc file
5.  Run `source("data-raw/source_all.R")` then `devtools::document()`

------------------------------------------------------------------------

## envirotox Integration

### Source Package

[`poissonconsulting/envirotox`](https://github.com/poissonconsulting/envirotox)
(v0.0.0.9003) is a separate data-only R package providing SSD datasets
derived from the **EnviroTox database 2.0.0** (Connors et al. 2019,
<doi:10.1002/etc.4382>). Its data will be integrated into `ssddata`
under the `envirotox` prefix.

### envirotox Datasets

Three datasets are exported from the package:

#### `envirotox_acute` — 14,949 rows × 6 columns

Acute toxicity records (EC50/LC50) aggregated to one geometric mean
concentration per species per chemical.

| Column | Type | Description |
|----|----|----|
| `Chemical` | chr | Chemical name (short name before first `;`) |
| `Conc` | dbl | Geometric mean concentration (µg/L) |
| `Species` | chr | Latin species name |
| `Group` | chr | Taxonomic group (sentence case): `Fish`, `Invertebrate`, `Algae`, `Amphibian`, `Plant`, etc. |
| `Yanagihara24` | lgl | Meets Yanagihara et al. (2024) criteria: ≥10 species, ≥3 trophic groups, bimodality coefficient ≤ 0.555 |
| `Iwasaki25` | lgl | Meets Iwasaki et al. (2025) criteria: \>50 species, ≥3 trophic groups (excludes certain metals) |

Key constraint:
`chk::check_key(envirotox_acute, c("Chemical", "Species"))` — unique per
chemical × species.

#### `envirotox_chronic` — 1,721 rows × 5 columns

Chronic toxicity records (NOEC/NOEL) aggregated similarly.

| Column         | Type | Description                             |
|----------------|------|-----------------------------------------|
| `Chemical`     | chr  | Chemical name                           |
| `Conc`         | dbl  | Geometric mean concentration (µg/L)     |
| `Species`      | chr  | Latin species name                      |
| `Group`        | chr  | Taxonomic group (sentence case)         |
| `Yanagihara24` | lgl  | Meets Yanagihara et al. (2024) criteria |

Key constraint:
`chk::check_key(envirotox_chronic, c("Chemical", "Species"))`.

#### `envirotox_chemical` — 744 rows × 2 columns

Chemical lookup table joining the two datasets above.

| Column        | Type | Description                               |
|---------------|------|-------------------------------------------|
| `Chemical`    | chr  | Chemical name (primary key)               |
| `OriginalCAS` | int  | Original CAS Registry Number (also a key) |

### Data Processing Pipeline (data-raw/envirotox.R)

The build script (modified from Yanagihara et al. 2024 code) processes
`envirotox.xlsx` (three sheets: `test`, `substance`, `taxonomy`):

1.  **Filter** records: acute = EC50/LC50 with `Test.type == "A"`;
    chronic = NOEC/NOEL with `Test.type == "C"`; exclude records where
    `Effect.is.5X.above.water.solubility == "1"`
2.  **Unit conversion**: mg/L → µg/L (× 1000)
3.  **Geometric mean** per `original.CAS × Latin.name` using
    `EnvStats::geoMean()`
4.  **Minimum species/group thresholds**: ≥6 species, ≥2 trophic groups
    per chemical
5.  **Bimodality coefficient** (BC) via
    `mousetrap::bimodality_coefficient(log10(Conc))` — used for
    `Yanagihara24` flag
6.  **Group normalisation**: `"Invert"` → `"Invertebrate"`, `"Amphib"` →
    `"Amphibian"`, all sentence case
7.  **`OriginalCAS` dropped** from acute/chronic before saving; kept
    only in `envirotox_chemical`

### Integration into ssddata

When adding envirotox data to `ssddata`:

- **Prefix**: `envirotox` (e.g., `envirotox_acute`, `envirotox_chronic`,
  `envirotox_chemical`)
- **Column mapping**: `ssddata` uses `Conc` (µg/L), `Species`, `Group` —
  matches envirotox columns directly; no `Chemical` column in individual
  `ssddata` datasets (chemical is encoded in dataset name for
  per-chemical sets)
- **Aggregate datasets**: `envirotox_acute` and `envirotox_chronic` are
  already multi-chemical aggregates; treat like `ccme_data` /
  `aims_data` — doc files end with `"envirotox_acute"` /
  `"envirotox_chronic"`
- **Source file**: place `envirotox.xlsx` in `data-raw/envirotox/` and
  the build script at `data-raw/envirotox/create_envirotox.R`
- **References to add to `inst/REFERENCES.bib`**:
  - `Connors2019` — EnviroTox database paper (<doi:10.1002/etc.4382>)
  - `Yanagihara2024` — distribution comparison paper
    (<doi:10.1016/j.ecoenv.2024.116379>)
  - `Iwasaki2025` — model-averaging paper (<doi:10.1093/etojnl/vgae060>)

### Key Difference from Other ssddata Sources

Unlike CCME/AIMS/CSIRO datasets (one dataset per chemical), envirotox
datasets are pre-aggregated multi-chemical tables with a `Chemical`
column acting as the grouping variable. The `Yanagihara24` and
`Iwasaki25` logical flags allow subsetting to published benchmark
subsets without creating separate datasets.
