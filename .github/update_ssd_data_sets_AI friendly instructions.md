Full AI friendly instructions of the desired features:

# Instructions: Updating `ssd_data_sets()`

## Context

`ssd_data_sets()` is defined in `R/get_ssddata.R`. The existing `get_ssddata()`
function (same file) handles retrieval + geomean deduplication for a **single**
named dataset — the new `ssd_data_sets()` behaviour will need to replicate and
extend this logic across **multiple** datasets.

`gm_mean()` (same file) is the geometric mean helper to reuse.

---

## What `ssd_data_sets()` currently does

- Returns all individual (non-aggregate, non-envirotox) datasets as a named list
  of tibbles
- No arguments
- Excludes: `ssd_fits`, `*_data`, `envirotox_*` datasets

Current code:
```r
ssd_data_sets <- function() {
  items <- utils::data(package = "ssddata")$results[, "Item"]
  items <- items[!items %in% c("ssd_fits")]
  items <- items[!grepl("_data$", items)]
  items <- items[!grepl("^envirotox_", items)]
  items <- sort(items)
  datasets <- lapply(items, function(x) {
    eval(parse(text = paste0("ssddata::", x)))
  })
  names(datasets) <- items
  datasets
}
```

---

## Key required changes

### New argument: `set`

Controls which collection of datasets is returned. Valid values:

#### `set = "v1"` (hardcoded list)

Returns the fixed ssddata v1 dataset names:

```r
c("aims_aluminium_marine", "aims_gallium_marine", "aims_molybdenum_marine",
  "anon_a", "anon_b", "anon_c", "anon_d", "anon_e", "anzg_metolachlor_fresh",
  "ccme_boron", "ccme_cadmium", "ccme_chloride", "ccme_endosulfan",
  "ccme_glyphosate", "ccme_silver", "ccme_uranium", "csiro_chlorine_marine",
  "csiro_cobalt_marine", "csiro_lead_marine", "csiro_nickel_fresh")
```

No `group` or `dedup` logic needed — these are fixed, well-known datasets.

#### `set = "v2"` (default, dynamic)

Returns all current individual non-aggregate datasets — equivalent to the
current function logic. This is the default because v2 is the current CRAN
version and will remain so until v3.

The `group` and `dedup` arguments apply here (see below).

#### `set = c("aims", "anon", "anzg", "ccme", "csiro")` (prefix filter)

Accepts one or more prefix strings. Filters the v2 dataset list to only those
matching the given prefix(es). The `group` and `dedup` arguments apply here too.

#### `set = "wqbench"` / `"envirotox_acute"` / `"envirotox_chronic"` / `"anztox"`

Splits the corresponding **aggregated** dataset into a named list of per-chemical
tibbles, mirroring the format of the individual dataset list.

Dataset-specific notes:

- **`wqbench`**: source is `wqbench_data` (flat tibble). Split by `Chemical`.
  No `Medium` column — if `group` includes `"Medium"` and it is absent, warn
  and ignore.
- **`envirotox_acute`** / **`envirotox_chronic`**: source is `envirotox_acute` /
  `envirotox_chronic` (flat tibbles). Split by `Chemical`. No medium column.
- **`anztox`**: source is `anztox_data` (tibble with data nested by
  `chemicalname_grouped` and `mediatype`). Default grouping includes
  `mediatype` — i.e. dataset names will be
  `anztox_{chemicalname_grouped}_{mediatype}` by default.

Dataset names for split datasets should be constructed using `make.names()` to
ensure valid R names, e.g.:
```r
make.names(paste0("envirotox_acute_", chemical_name))
# "envirotox_acute_1.2.4.Trichlorobenzene"
```

#### `set = "alldata"`

Aggregates across **all** data sources using their `*_data` aggregated
equivalents (not the individual datasets). Sources: `aims_data`, `anon_data`,
`anzg_data`, `ccme_data`, `csiro_data`, `wqbench_data`, `envirotox_acute`,
`envirotox_chronic`, `anztox_data`.

> Note: `envirotox_data` is a named list wrapper (not a flat tibble) — use
> `envirotox_acute` and `envirotox_chronic` directly instead.

Default `group = "datasource"` appends the source prefix to dataset names.
The `cas_lookup` argument (see below) applies here.

---

### New argument: `group`

Controls how datasets are **split before being returned** — i.e. which columns
define the grouping keys used to partition a dataset into sub-datasets. Applies
to `set = "v2"`, prefix sets, and aggregated sets. Does **not** control
duplicate-species handling (see `dedup` below).

- Default: `NULL` (no additional splitting beyond what `set` already implies)
- Accepts a **character vector** of column names, e.g. `group = "Domain"` or
  `group = c("Domain", "mediatype")`
- Columns absent from a given dataset are **silently skipped** — no error, no
  warning (some datasets have `Domain`, others do not)
- When a column is present, the dataset is split by that column and the column
  value is **always appended to the dataset name**, regardless of how many
  unique values exist, e.g. `aims_aluminium_marine_Invertebrate`,
  `ccme_boron_Invertebrate`

> **Note for `set = "anztox"`**: `mediatype` splitting is applied by default as
> part of the `set` logic (not via `group`). Passing `group = "mediatype"`
> would double-split — avoid.

---

### New argument: `dedup`

Controls how **duplicate Species rows** within a chemical (after grouping) are
handled. This is separate from `group`, which controls dataset splitting.

| Value | Behaviour |
|---|---|
| `"geomean"` (default) | Apply `gm_mean()` to collapse duplicate Species rows; emit a `message()` listing which datasets had deduplication applied |
| `"none"` | Return data as-is; emit a `message()` listing datasets + species with duplicate rows |

- Type: single string (`chk::chk_string()`)
- Only `"geomean"` and `"none"` are valid; invalid values throw an informative
  error
- The shared deduplication logic should be extracted into a private helper
  `.apply_gm_mean(dat)` (see Relationship to `get_ssddata()` below) and called
  from both `ssd_data_sets()` and `get_ssddata()`

---

### New argument: `cas_lookup`

- Type: logical, default `TRUE`
- Only relevant for `set = "alldata"`
- When `TRUE`, uses `data-raw/anztox/cas_parent_lookup.csv` to align chemical
  names/CAS numbers across datasets before splitting
- When `FALSE`, no CAS harmonisation is applied

---

## Relationship to `get_ssddata()`

`get_ssddata()` currently handles single-dataset retrieval + geomean
deduplication. The new `ssd_data_sets()` will replicate this logic at scale.

**Recommended approach**: Extract the core deduplication logic from
`get_ssddata()` into a private helper (e.g. `.apply_gm_mean(dat, spp_vec,
conc)`) and call it from both functions. This avoids duplication.

`get_ssddata()` itself should **not** be removed — it is a public exported
function that may have downstream dependents. If it becomes redundant, add a
deprecation warning pointing to `ssd_data_sets()` and keep it for at least one
release cycle (use `.Deprecated()` or `lifecycle::deprecate_warn()`).

---

## Column name differences across datasets

Different source datasets use different column names for the same concept.
Column names below were verified directly from the loaded R objects.

| Concept | Individual datasets | `anztox_data` outer | `anztox_data` inner | `wqbench_data` | `envirotox_acute` / `_chronic` |
|---|---|---|---|---|---|
| Species | `Species` | — | `scientificname` | `latin_name` | `Species` |
| Concentration | `Conc` | — | `endpoint_concentration` | `sp_aggre_conc_mg.L` | `Conc` |
| Taxonomic group | `Group` | — | `majorgroup` | `trophic_group` | `Group` |
| Medium | (varies / absent) | `mediatype` | — (implied by nesting) | absent | absent |
| Chemical | (dataset name) | `chemicalname_grouped` | — (implied by nesting) | `chemical_name` | `Chemical` |
| CAS | absent | `casnumber_grouped` | — | `cas` | absent |

**Notes:**
- `dedup` must use the correct Species column per source: `Species` for individual
  datasets and envirotox; `scientificname` for anztox inner tibbles; `latin_name`
  for wqbench.
- `wqbench_data` concentration units are **mg/L** (`sp_aggre_conc_mg.L`),
  whereas all other sources use µg/L (`Conc`). Be aware of unit differences
  when combining across sources.
- After `set = "anztox"` splitting, returned tibbles are the **inner** tibbles —
  chemical/medium context is encoded in the list name, not a column.

---

## Unit tests

Tests should go in `tests/testthat/test-ssd_data_sets.R`. Cover:

- `set = "v1"` returns exactly the 20 hardcoded datasets
- `set = "v2"` returns a named list of tibbles, all with a `Conc` column
- `set = c("ccme", "anzg")` returns only datasets with those prefixes
- `set = "wqbench"` returns a named list split by `Chemical`
- `set = "envirotox_acute"` returns a named list split by `Chemical`
- `set = "anztox"` returns a named list split by `chemicalname_grouped` x
  `mediatype`
- `set = "alldata"` returns something (smoke test; detailed content TBD)
- `dedup = "geomean"` emits a message when deduplication is applied
- `dedup = "none"` emits a message listing duplicates
- `group = "Domain"` splits aims/csiro datasets and appends Domain to all names
- `cas_lookup = TRUE` vs `FALSE` (for `set = "alldata"`)
- Invalid `set` value throws an informative error
- Invalid `dedup` value throws an informative error

