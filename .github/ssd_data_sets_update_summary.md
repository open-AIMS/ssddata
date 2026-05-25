# `ssd_data_sets()` — Update Summary

## Overview

`ssd_data_sets()` has been significantly extended to support multiple data
sources, flexible dataset grouping, and configurable duplicate-species handling.
All changes are in `R/get_ssddata.R`. The stub file `R/ssd-data-sets.R` now
contains only a comment redirecting to `get_ssddata.R`.

All 25 unit tests pass (`tests/testthat/test-ssd-data-sets.R`).

---

## New Function Signature

```r
ssd_data_sets(
  set        = "v2",
  group      = NULL,
  dedup      = "geomean",
  cas_lookup = TRUE
)
```

---

## New Arguments

### `set`

Controls which collection of datasets is returned.

| Value | Returns |
|---|---|
| `"v2"` (default) | All current individual non-aggregate datasets (equivalent to old behaviour) |
| `"v1"` | Fixed hardcoded list of 20 datasets from ssddata v1 |
| `c("aims", "ccme", ...)` | Prefix filter — returns only v2 datasets matching those prefixes. Valid prefixes: `aims`, `anon`, `anzg`, `ccme`, `csiro` |
| `"wqbench"` | Splits `wqbench_data` by `chemical_name` into a named list |
| `"envirotox_acute"` | Splits `envirotox_acute` by `Chemical` into a named list |
| `"envirotox_chronic"` | Splits `envirotox_chronic` by `Chemical` into a named list |
| `"anztox"` | Splits `anztox_data` by `chemicalname_grouped × mediatype` into a named list |
| `"alldata"` | Combines all `*_data` sources and splits by `Chemical` across all sources |

Dataset counts (current):

| `set` | Length |
|---|---|
| `"v2"` | 53 |
| `"v1"` | 20 |
| `c("ccme","anzg")` | 41 |
| `"anztox"` | 174 |
| `"wqbench"` | 1267 |
| `"envirotox_acute"` | 729 |

Dataset names for split sources are constructed with `make.names()` to ensure
valid R names, e.g. `envirotox_acute_1.2.4.Trichlorobenzene`,
`anztox_Aluminium_Freshwater`.

### `group`

Controls how datasets are **split before being returned** by one or more column
values. Applies after `set` selection. Does **not** control duplicate-species
handling (see `dedup`).

- Default: `NULL` (no additional splitting)
- Accepts a character vector of column names, e.g. `group = "Domain"` or
  `group = c("Domain", "mediatype")`
- Columns **absent** from a dataset are silently skipped — no error
- When present, the column value is **always appended** to the dataset name,
  e.g. `aims_aluminium_marine` → `aims_aluminium_marine_Temperate`,
  `aims_aluminium_marine_Tropical`

Example:
```r
ssd_data_sets(set = "aims", group = "Domain")
# aims_aluminium_marine_Temperate
# aims_aluminium_marine_Mixed
# aims_aluminium_marine_Tropical
# aims_gallium_marine_Tropical
# ...
```

### `dedup`

Controls how **duplicate Species rows** within a chemical are handled after
grouping. Separate from `group`.

| Value | Behaviour |
|---|---|
| `"geomean"` (default) | Applies geometric mean (`gm_mean()`) to collapse duplicate Species rows; emits a `message()` listing affected datasets |
| `"none"` | Returns data as-is; emits a `message()` listing datasets and species with duplicates |

Invalid values throw an informative error:
```
`dedup` must be "geomean" or "none", not "bad".
```

### `cas_lookup`

- Type: logical, default `TRUE`
- Only relevant for `set = "alldata"`
- When `TRUE`, uses `data-raw/anztox/cas_parent_lookup.csv` to align chemical
  names/CAS numbers across datasets before splitting
- Currently a no-op hook if the lookup file is not bundled in the installed
  package; full implementation deferred

---

## Private Helpers Added

| Helper | Purpose |
|---|---|
| `.split_aggregated(set, cas_lookup)` | Loads and splits an aggregated dataset into a named list of per-chemical tibbles |
| `.apply_group_split(datasets, group)` | Splits each dataset in a named list by one or more column values, appending values to names |
| `.apply_dedup(datasets, dedup)` | Applies geometric mean deduplication or reports duplicates across all datasets |

---

## Notes for Collaborators

- `anztox_data` is a **nested tibble** (list-column `data` per
  `chemicalname_grouped × mediatype`). The `"anztox"` split unnests this
  automatically — each element of the returned list is the inner tibble for
  that chemical/medium combination.
- `wqbench_data` uses `chemical_name` (not `Chemical`) as its chemical
  identifier column — handled internally.
- `envirotox_data` is a **named list wrapper**, not a flat tibble. Use
  `"envirotox_acute"` / `"envirotox_chronic"` directly rather than
  `"envirotox_data"` as a `set` value.
- The old `getdata()` helper does not specify `package = "ssddata"` in its
  `utils::data()` call, causing `data set 'x' not found` warnings when called
  with a variable name. All internal loading in `.split_aggregated()` uses
  `utils::data(list = name, package = "ssddata", envir = e)` directly to avoid
  this.

---

## Tests (`tests/testthat/test-ssd-data-sets.R`)

25 tests covering:

- `set = "v1"` returns exactly 20 datasets
- `set = "v2"` returns 53 datasets, all named, all tibbles with `Conc`
- Prefix filter returns only matching datasets
- `set = "anztox"` returns 174 datasets named `anztox_*`
- `set = "wqbench"` returns datasets named `wqbench_*`
- `set = "envirotox_acute"` returns 729 datasets
- `group = "Domain"` splits aims/csiro datasets and appends Domain to names
- `group` silently skips columns absent from a dataset
- `dedup = "geomean"` emits message when duplicates are present
- `dedup = "none"` emits message listing duplicate species
- Invalid `set` value throws informative error
- Invalid `dedup` value throws informative error
- `ccme_boron` dataset structure and value ranges (regression)
