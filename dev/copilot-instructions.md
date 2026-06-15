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

- **`ssd_data_sets(set, split, summarize, cas_lookup)`** — returns a
  named list of per-chemical tibbles. Supports multiple `set` values:
  - `"v2"` (default) — all 53 current individual non-aggregate datasets

  - `"v1"` — fixed hardcoded list of 20 ssddata v1 datasets

  - prefix vector e.g. `c("aims", "ccme")` — filters v2 datasets by
    prefix; valid prefixes: `aims`, `anon`, `anzg`, `ccme`, `csiro`

  - `"wqbench"` , `"envirotox_acute"` , `"envirotox_chronic"` and
    `"anztox"` — splits corresponding aggregated dataset into
    per-chemical named list

  - `"alldata"` — combines all `*_data` sources and splits by chemical
    across all sources; sources with a `Medium` column (`aims`, `csiro`,
    `anzg`) are split by `Chemical × Medium` to match individual dataset
    naming conventions (e.g. `aims_aluminium_marine`,
    `csiro_nickel_fresh`, `anzg_nitrate_hard_fresh`)

  - `split` (character vector, default `NULL`) — further splits each
    dataset by named column(s), appending values to dataset names;
    absent columns silently skipped

  - `summarize` (`"geomean"` default or `"none"`) — collapses duplicate
    Species rows via geometric mean, or reports them; emits
    [`message()`](https://rdrr.io/r/base/message.html) in both cases

  - `cas_lookup` (logical, default `TRUE`) — for `set = "alldata"`,
    aligns CAS numbers across sources before splitting (currently a
    no-op hook)

  - Private helpers: `.split_aggregated()`, `.apply_group_split()`,
    `.apply_dedup()`, `.harmonise_columns()`

  - **Column guarantee:** every tibble returned by
    [`ssd_data_sets()`](https://open-aims.github.io/ssddata/dev/reference/ssd_data_sets.md)
    (regardless of `set`) is guaranteed to have `Species` as the first
    column and `Conc` as the second column. Column names are
    standardised in the `data-raw/` build scripts, not at runtime.

  - **Standardised column names (enforced in data-raw build scripts):**

    | Source | Species | Conc | Chemical | Medium | Group |
    |----|----|----|----|----|----|
    | `aims_*`, `csiro_*`, `anzg_*` | `Species` | `Conc` | (dataset name) | `Medium` | `Group` |
    | `ccme_*` | `Species` | `Conc` | `Chemical` | `Medium` = `"Freshwater"` | `Group` |
    | `anon_*` | (sequential labels) | `Conc` | `Chemical` | `Medium` = `"Unknown"` | — |
    | `wqbench_data` | `Species` | `Conc` | `Chemical` | `Medium` = `"Unknown"` | `Group` |
    | `envirotox_acute/chronic` | `Species` | `Conc` | `Chemical` | `Medium` = `"Unknown"` | `Group` |
    | `anztox_data` (inner) | `Species` | `Conc` | `Chemical` | `Medium` | `Group` |

  - **`anon_*` exception:** genuinely species-anonymous — sequential
    labels (`"sp. A"`, `"sp. B"`, …) assigned by `.harmonise_columns()`.

  - **Note:** `wqbench` concentration units are mg/L vs µg/L for all
    other sources — **not** resolved by current normalisation.

  - **Note:** aggregated values (`"wqbench"`, `"envirotox_acute"`,
    `"envirotox_chronic"`, `"anztox"`, `"alldata"`) must be passed alone
    — mixing with prefix strings (e.g. `c("wqbench", "ccme")`) is not
    supported and will error. \`\`\`\`
