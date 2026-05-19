# Endpoint 2016 to 2000 lookup build

## Endpoint 2016 to 2000 lookup build

### Purpose

The ANZTOX database contains two separate toxicity tables —
`toxicityvalue2000` and `toxicityvalue2016` — that use different
endpoint label vocabularies. The 2000 dataset uses a compact set of
standardised codes (e.g. `MORT`, `GRO`, `REP`, `DVP`) defined in the
`endpoint` lookup table. The 2016 dataset uses a richer and less
standardised set of labels, including free-text entries, abbreviations,
and misspellings, resolved via two foreign keys
(`endpointmeasurement_id` and `endpointfrompaper_id`) into the same
`endpoint` table.

This lookup table bridges that gap: it maps every distinct 2016 endpoint
label to its nearest equivalent 2000 endpoint code, enabling the two
datasets to be combined into a single harmonised `endpoint` field in the
consolidated toxicity pipeline (`data_explore2000_2016.R`).

This iteration specifically refines mapping for previously unmapped or
poorly mapped labels, including:

- Fluorescence / chlorophyll variants (`Fluoresence`, `Fluorescence`,
  `Chl-a`, `Chl-a fluorescence`, `ChlA content`)
- Plant-size metrics (`Leaf Area`, `Number of new leaves`)
- Life-history and misspelling variants (`Longevity`, `Fercundity`,
  `Fercunity`, `Young per female`)
- Additional ecological and functional labels (`Cell volume`,
  `Cellular biovolume...`, `Algal cell viability`,
  `Ability to attach to host`)

### Executable source

The reproducible builder is:

``` text
data-raw/anztox/endpoint_2016_to_2000_lookup_build.R
```

Run it to regenerate all output files. The script uses in-session
objects (`raw_2016`, `lu_endpoint`) when present in the R environment
(e.g. after running the main consolidation script); otherwise it opens a
temporary database connection to the `infogathering` PostgreSQL instance
and closes it on exit via
[`on.exit()`](https://rdrr.io/r/base/on.exit.html).

### Inputs

From the ANZTOX PostgreSQL database (`infogathering`):

- `toxicityvalue2016` — the post-2000 toxicity records, used to extract
  distinct endpoint label combinations and their row frequencies
- `endpoint` — the normalised lookup table shared by both the 2000 and
  2016 pipelines, providing both `name` and `abbreviation` columns

No external CSV files are required as inputs; the mapping rules are
embedded in the builder script itself.

### Method

#### Step 1 — Extract distinct 2016 endpoint labels

A distinct frequency table of endpoint labels is built from
`toxicityvalue2016` by resolving both foreign keys:

- `endpointmeasurement_id` → `endpoint.name` (the endpoint as actually
  measured)
- `endpointfrompaper_id` → `endpoint.name` (the endpoint as reported in
  the source paper)

These are collapsed using `coalesce(endpoint_measured, endpoint_paper)`
to produce a single `endpoint_2016_raw` label per row. The paired
abbreviation (from `endpoint.abbreviation`) is also retained where
available as `endpoint_2016_abbrev`. The frequency of each distinct
label across all 2016 rows (`n_rows_2016`) is counted and carried
forward, which allows later prioritisation when deduplication is needed.

#### Step 2 — Normalise labels

Each raw label is normalised to a lowercase, punctuation-stripped form
(`endpoint_2016_norm`) using the same `normalize_name()` helper function
used in the main consolidation pipeline. This ensures that labels
differing only in capitalisation, spacing, or punctuation are treated as
equivalent during mapping.

#### Step 3 — Two-stage mapping to 2000 codes

Mapping is applied in two stages, with the manual stage taking priority:

**Stage A — manual_refined**

A hand-curated lookup handles known problematic cases that cannot be
reliably addressed by regex, including:

- Common misspellings (e.g. `Fercundity` → `REP`, `Fluoresence` → `PSE`)
- Ambiguous abbreviations where the full label is needed for correct
  assignment
- Labels that normalise to the same string but map to different codes
  (resolved case-by-case)
- Newly identified labels from the v2 refinement pass listed in the
  Purpose section above

**Stage B — rule_refined**

A set of ordered regex patterns is applied to the normalised label for
all rows not resolved by the manual stage. Each pattern targets a
specific 2000 code:

| Code | Meaning | Example regex target |
|:---|:---|:---|
| MORT | Mortality / lethality | mortalit, lethality, survival, lc\[0-9\] |
| IMM | Immobilisation | immobili |
| REP | Reproduction | reproduct, fecund, offspring, young per |
| DVP | Development | develop, embryo, larval, hatch |
| HAT | Hatching | hatch |
| GRO | Growth | growth, weight, length, biomass, leaf area |
| PSE | Photosynthesis / fluorescence | photosyn, fluores, chl, chlorophyll |
| POP | Population | populat, abundan |
| LUM | Luminescence | luminesc, biolumines |
| ABD | Avoidance / behaviour | avoid, behaviour, movement |
| FERTILISATION | Fertilisation | fertili |
| 14CO2 UPTAKE | Carbon uptake | co2, carbon uptake |
| GLUCOSEUTILISATION | Glucose utilisation | glucose |
| PRP | Prey capture / predation | predat, prey |
| PSR | Physiological stress response | stress, biomark |

Patterns are applied in order; the first match wins. Labels not matched
by any rule are left with `endpoint_2000_code = NA` and flagged with
`needs_review = TRUE`.

#### Step 4 — Output

The lookup is written as one row per distinct `endpoint_2016_raw` label,
making it suitable for deterministic `left_join()` operations in the
main consolidation pipeline. It is therefore critical that this table
contains no duplicate `endpoint_2016_raw` values — this is validated by
the main script (`data_explore2000_2016.R`) at load time with an
explicit [`stop()`](https://rdrr.io/r/base/stop.html) guard.

### Outputs

| File | Description |
|----|----|
| `endpoint_2016_to_2000_lookup.csv` | Primary lookup table; one row per distinct 2016 endpoint label, columns: `endpoint_2016_raw`, `endpoint_2016_abbrev`, `endpoint_2016_norm`, `n_rows_2016`, `endpoint_2000_code`, `map_method`, `needs_review` |
| `endpoint_2016_to_2000_lookup_coverage.csv` | Summary of mapping coverage: total labels, mapped labels, unmapped labels, total rows, mapped rows, unmapped rows |
| `endpoint_2016_to_2000_lookup_unmapped.csv` | Subset of the lookup restricted to rows where `needs_review == TRUE`; intended as a working list for manual review and extension |

All files are written to `data-raw/anztox/raw/`.

### How the lookup is used in the main pipeline

In `data_explore2000_2016.R`, the lookup is loaded at startup and
validated for uniqueness. Within the `toxicityvalue2016_clean` build
step, it is joined to the 2016 data after `endpoint_raw` is derived:

``` r

mutate(endpoint_raw = coalesce(endpoint_measured, endpoint_paper)) |>
left_join(
  endpoint_2016_to_2000_lookup_dedup |>
    distinct(endpoint_2016_raw, endpoint_2000_code),
  by = c("endpoint_raw" = "endpoint_2016_raw")
) |>
mutate(
  endpoint = coalesce(endpoint_2000_code, endpoint_raw),
  endpoint_mapping_missing = is.na(endpoint_2000_code)
)
```

The `endpoint_mapping_missing` flag is retained in
`toxicityvalue2016_clean` so that downstream analysis can identify which
2016 rows are using unmapped (raw) endpoint labels rather than
harmonised 2000 codes. This does not prevent those rows from reaching
the SSD eligibility workflow, but they will not group correctly with
equivalent 2000 endpoint data unless mapping is added.

The main script also uses `endpoint_2016_to_2000_lookup_dedup`, a
deduplicated version produced at load time that keeps one mapping per
`endpoint_2016_raw` (preferring non-NA `endpoint_2000_code`, then
highest `n_rows_2016`). This guards against any future lookup file that
inadvertently contains duplicate labels.

### Outcomes (v2 refined)

Coverage after this refinement run:

| Metric                   | Value |
|:-------------------------|------:|
| Endpoint labels total    |   197 |
| Endpoint labels mapped   |   172 |
| Endpoint labels unmapped |    25 |
| Rows total (2016)        |  2794 |
| Rows mapped              |  2758 |
| Rows unmapped            |    36 |

Improvement over the prior baseline (v1):

| Metric          |   v1 |   v2 | Change |
|:----------------|-----:|-----:|:-------|
| Labels mapped   |  149 |  172 | +23    |
| Labels unmapped |   48 |   25 | -23    |
| Rows mapped     | 2641 | 2758 | +117   |
| Rows unmapped   |  153 |   36 | -117   |

The 36 remaining unmapped rows span 25 distinct labels. These are
predominantly low-frequency, highly specific reproductive or
morphological metrics (e.g. `Sperm motility`, `Valve movement`,
`Byssus production`) that do not map cleanly to any of the 2000 codes
and are unlikely to materially affect SSD outputs given their low row
counts.

### Remaining unmapped labels

Residual unmapped labels can be reviewed below. Each row includes the
raw label, its normalised form, the number of 2016 rows it affects, and
`needs_review = TRUE`.

| Raw Label | Normalised | Row Count | Needs Review |
|:---|:---|---:|:---|
| Cell size | cell size | 2 | TRUE |
| Disc area | disc area | 2 | TRUE |
| Egg production | egg production | 2 | TRUE |
| Germination | germination | 2 | TRUE |
| Imobilisation | imobilisation | 2 | TRUE |
| Larvae settlement success | larvae settlement success | 2 | TRUE |
| Moulted individuals | moulted individuals | 2 | TRUE |
| Plant area | plant area | 2 | TRUE |
| Progeny | progeny | 2 | TRUE |
| Size | size | 2 | TRUE |
| Young per adult | young per adult | 2 | TRUE |
| Cumulative eggs layed/female | cumulative eggs layed female | 1 | TRUE |
| Dry mass | dry mass | 1 | TRUE |
| Egg extrusion time | egg extrusion time | 1 | TRUE |
| Eggs embryonated | eggs embryonated | 1 | TRUE |
| Final number of individuals | final number of individuals | 1 | TRUE |
| Germination inhibition | germination inhibition | 1 | TRUE |
| Head capsule width | head capsule width | 1 | TRUE |
| Height | height | 1 | TRUE |
| Number eggs/female/day | number eggs female day | 1 | TRUE |
| Proliferation | proliferation | 1 | TRUE |
| Resting egg production | resting egg production | 1 | TRUE |
| Shell area | shell area | 1 | TRUE |
| Surface Area | surface area | 1 | TRUE |
| Zoospore concentration | zoospore concentration | 1 | TRUE |

To extend the mapping:

1.  Open `endpoint_2016_to_2000_lookup_unmapped.csv` and identify labels
    that can be assigned a 2000 code
2.  Add corresponding entries to the `manual_refined` lookup block in
    `endpoint_2016_to_2000_lookup_build.R`
3.  Re-run the builder script to regenerate all three output files
4.  Re-run `data_explore2000_2016.R` to incorporate the updated mapping
    into the consolidated pipeline

Where a 2016 label genuinely has no equivalent in the 2000 vocabulary
(i.e. it represents a measurement type not captured in the 2000
framework), the appropriate action is to assign
`endpoint_2000_code = NA` and document the rationale in a `notes`
column, rather than forcing a misleading mapping.

### Notes

- The lookup table is intentionally one-row-per-raw-label to ensure
  deterministic joins. Duplicates are a load-time error in the main
  script.
- `map_method` records which stage produced each mapping
  (`manual_refined`, `rule_refined`, or `unmapped`), supporting audit of
  how each assignment was made.
- The builder script is idempotent: running it multiple times produces
  identical output files given the same database state.
- Because endpoint labels in the 2016 database are free-text entries in
  the `endpoint.name` field, new labels can appear if the database is
  updated. The lookup should be regenerated and reviewed whenever
  `toxicityvalue2016` is materially updated.
