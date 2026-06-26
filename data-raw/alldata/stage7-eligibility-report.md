# Stage 7 Eligibility Report

Generated: 2026-06-26
Script: data-raw/alldata/DATASET.R (Stage 7 section)

---

## 1. Input Summary

| Item | Value |
|------|-------|
| Input file | `data-raw/alldata/alldata_integrated.csv` |
| Rows | 59,986 |
| Columns | 24 |
| File size | ~14.25 MB (untracked) |

Column list (all 24):
`casnumber_grouped`, `chemicalname_grouped`, `accepted_name`, `medium`, `conc_ug_L`,
`majorgroup`, `kingdom`, `phylum`, `class`, `order_taxon`, `family`, `genus`,
`taxonomy_provenance`, `n_records`, `sources_contributing`, `any_acr_applied`,
`any_conc_flagged`, `geomean_flagged`, `lifestage_mixed`, `duration_mixed`,
`source`, `Group`, `Chemical`, `exclusion_flag`

The final three (`Group`, `Chemical`, `exclusion_flag`) are pipeline-only columns
retained from Stage 6 processing; they are dropped at the Stage 7 select step.

---

## 2. Schema Audit

### class vs majorgroup consistency

For uncurated rows (`source == "uncurated"`):

| Check | Result |
|-------|--------|
| Rows where `class != majorgroup` or NA-parity differs | **0** |

Result: **PASS** — `class` and `majorgroup` are identical for all uncurated rows.

### NA coverage by source and column

| Source | n rows | class % NA | majorgroup % NA | kingdom % NA | phylum % NA | order_taxon % NA | family % NA | genus % NA | taxonomy_provenance % NA |
|--------|--------|-----------|----------------|-------------|------------|-----------------|------------|-----------|------------------------|
| aims | 20 | 5.0% | 5.0% | 5.0% | 5.0% | 5.0% | 5.0% | 5.0% | 0.0% |
| anzg | 592 | 100.0% | 100.0% | 100.0% | 44.8% | 100.0% | 100.0% | 0.0% | 0.0% |
| ccme | 98 | 100.0% | 0.0%* | 100.0% | 100.0% | 100.0% | 100.0% | 100.0% | 0.0% |
| csiro | 60 | 28.3% | 28.3% | 28.3% | 28.3% | 30.0% | 28.3% | 28.3% | 0.0% |
| uncurated | 59,216 | 1.4% | 1.4% | 0.0% | 0.0% | 2.1% | 0.1% | 0.4% | 0.0% |

*CCME `majorgroup` is populated from the source `Group` field (Amphibian, Fish,
Invertebrate, Plant) — a CCME-specific classification that differs from the
WoRMS/GBIF taxonomic class used for the sufficiency threshold. CCME `class`
remains `NA` (no WoRMS resolution applied). CCME rows bypass the sufficiency
filter as a curated source.

**Notes on expected NA patterns:**
- ANZG: no taxonomy resolution applied (curated source, trusted as-is). Genus
  is non-NA because it comes from the `Genus` column in `anzg_data`. Phylum is
  44.8% NA because only some chemicals had phylum populated in the source.
- CCME: no taxonomy resolution applied. majorgroup populated from Group field.
- AIMS (5% NA): 1 species unresolved (misspelling in source — retained with NA
  taxonomy per Stage 6 decision).
- CSIRO (28–30% NA): 17 rows with NA Species (csiro chlorine × marine rows) —
  these were given an accepted_name placeholder ("Unknown species (no name in
  source)") and have no resolvable taxonomy.
- Uncurated (~1.4% NA class): residual unresolved species from Stage 4d (mainly
  no_taxonomy-adjacent cases and genus-only entries).

---

## 3. Sufficiency Filter Results (uncurated rows only)

The sufficiency filter applies only to rows where `source == "uncurated"`.
Curated source rows (ANZG, CCME, AIMS, CSIRO) bypass this filter entirely.

### casnumber_grouped × medium combinations assessed (uncurated only)

| Category | n combinations | % |
|----------|---------------|---|
| **Total combinations** | **10,078** | 100% |
| Pass both (≥5 species AND ≥4 classes) | 1,880 | 18.7% |
| Fail species only (<5 species, ≥4 classes) | 96 | 1.0% |
| Fail classes only (≥5 species, <4 classes) | 691 | 6.9% |
| Fail both (<5 species AND <4 classes) | 7,411 | 73.5% |

The majority of failing combinations (73.5%) have fewer than 5 species and
fewer than 4 classes — most are single-species entries from large chemical
databases like WQBench/EnviroTox with only one or two toxicology records.

### Uncurated row retention

| Category | Rows | % of uncurated total |
|----------|------|---------------------|
| Uncurated rows in passing combinations (retained) | 41,482 | 70.1% |
| Uncurated rows in failing combinations (dropped) | 17,734 | 29.9% |
| **Total uncurated rows in input** | **59,216** | 100% |

---

## 4. Curated Source Rows (bypass filter — confirmed unchanged)

| Source | Input rows | Retained rows |
|--------|-----------|--------------|
| anzg | 592 | 592 |
| ccme | 98 | 98 |
| aims | 20 | 20 |
| csiro | 60 | 60 |
| **Total curated** | **770** | **770** |

All curated row counts match Stage 6 confirmed values. ✓

---

## 5. allchronic_data Summary

| Item | Value |
|------|-------|
| Total rows | 42,252 |
| Distinct chemicals | 1,073 |
| Distinct species | 3,647 |
| Columns | 20 |
| File: `data/allchronic_data.rda` | ~473 KB (compressed bzip2) |

### Medium breakdown

| Medium | Rows |
|--------|------|
| Freshwater | 21,419 |
| Unknown | 15,943 |
| Marine | 4,853 |
| Soft freshwater | 14 |
| Hard freshwater | 12 |
| Moderate freshwater | 11 |
| **Total** | **42,252** |

### Source breakdown

| Source | Rows |
|--------|------|
| uncurated | 41,482 |
| anzg | 592 |
| ccme | 98 |
| csiro | 60 |
| aims | 20 |
| **Total** | **42,252** |

### Column list (all 20, in order)

1. `Species` — accepted species name (PascalCase rename of `accepted_name`)
2. `Conc` — concentration in µg/L (`conc_ug_L`)
3. `Chemical` — parent chemical name (`chemicalname_grouped`)
4. `CAS` — parent CAS number (`casnumber_grouped`)
5. `Medium` — test medium (`medium`)
6. `Source` — pipeline source (`source`; uncurated rows = "uncurated")
7. `Class` — taxonomic class = majorgroup (`class`)
8. `Kingdom` — taxonomic kingdom (`kingdom`)
9. `Phylum` — taxonomic phylum (`phylum`)
10. `Order` — taxonomic order (`order_taxon`)
11. `Family` — taxonomic family (`family`)
12. `Genus` — taxonomic genus (`genus`)
13. `TaxonomyProvenance` — resolution provenance (`taxonomy_provenance`)
14. `NRecords` — contributing record count (`n_records`)
15. `SourcesContributing` — contributing source names (`sources_contributing`)
16. `AnyAcrApplied` — ACR conversion flag (`any_acr_applied`)
17. `AnyConcFlagged` — soft-flag fallback flag (`any_conc_flagged`)
18. `GeomeanFlagged` — geomean min() flag (`geomean_flagged`)
19. `LifestageMixed` — life stage mixing flag (`lifestage_mixed`)
20. `DurationMixed` — duration mixing flag (`duration_mixed`)

**Dropped pipeline-only columns** (present in `alldata_integrated.csv` but not
selected into `allchronic_data`): `majorgroup`, `Group`, `Chemical` (original
source chemical name, superseded by `chemicalname_grouped`), `exclusion_flag`.

---

## 6. Validation Checks

All checks run after building `allchronic_data` from the filtered dataset:

| Check | Description | Result |
|-------|-------------|--------|
| 1 | No duplicate Species within any Chemical × Medium combination | **PASS** |
| 2 | `Species` contains no NA values | **PASS** |
| 3 | `Conc` contains no NA values | **PASS** |
| 4 | All `Conc` values are positive (> 0) | **PASS** |
| 5 | `Source` values all in expected set | **PASS** |
| 6 | Curated row counts unchanged (anzg=592, ccme=98, aims=20, csiro=60) | **PASS** |

All 6 validation checks **PASSED**.

---

## 7. Files Produced / Modified

### New files (tracked)
- `data/allchronic_data.rda` — package data object (42,252 rows × 20 cols, ~473 KB)
- `data-raw/alldata/DATASET.R` — comprehensive pipeline script (Stage 6 + Stage 7); 303 lines
- `R/allchronic_data.R` — roxygen2 documentation for `allchronic_data`
- `data-raw/alldata/stage7-eligibility-report.md` — this file

### Modified files (tracked)
- `R/get_ssddata.R` — replaced `"alldata"` branch with `"all_chronic"` branch in
  `.split_aggregated()`; updated `known_aggregated` vector; updated `@param set`
  roxygen documentation; deprecated `cas_lookup` parameter description.
- `man/allchronic_data.Rd` — generated by `devtools::document()`
- `man/ssd_data_sets.Rd` — regenerated by `devtools::document()`

### Deleted files
- `scripts/stage6-phase2-integrate.R` — superseded by `data-raw/alldata/DATASET.R`
  (Stage 6 logic inlined into DATASET.R)

### Untracked files (do NOT commit)
- `data-raw/alldata/alldata_integrated.csv` — large intermediate file (~14.25 MB);
  regenerate by running `data-raw/alldata/DATASET.R` from scratch (delete CSV first).
