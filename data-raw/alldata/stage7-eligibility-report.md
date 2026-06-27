# Stage 7 Eligibility Report

Generated: 2026-06-26 (updated after Stage 4e genus-rank exclusion patch)
Script: data-raw/alldata/DATASET.R (Stage 7 section)

---

## 1. Input Summary

| Item | Value |
|------|-------|
| Input file | `data-raw/alldata/alldata_integrated.csv` |
| Rows | 57,058 |
| Columns | 22 |
| File size | ~13.2 MB (untracked) |

Column list (all 22):
`casnumber_grouped`, `chemicalname_grouped`, `accepted_name`, `medium`, `conc_ug_L`,
`majorgroup`, `kingdom`, `phylum`, `class`, `order_taxon`, `family`, `genus`,
`taxonomy_provenance`, `n_records`, `sources_contributing`, `any_acr_applied`,
`any_conc_flagged`, `geomean_flagged`, `lifestage_mixed`, `duration_mixed`,
`source`, `exclusion_flag`

The final column (`exclusion_flag`) is a pipeline-only column retained from Stage 6
processing; it is dropped at the Stage 7 select step. `majorgroup` is also dropped
(redundant with `class`).

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
| uncurated | 56,288 | ~1.4% | ~1.4% | ~0.0% | ~0.0% | ~2.1% | ~0.1% | ~0.4% | 0.0% |

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
  no_taxonomy-adjacent cases). Genus-rank entries are now excluded at Stage 4e
  (Step 2c); this residual reflects only genuinely unresolvable species that
  returned partial taxonomy.

---

## 3. Sufficiency Filter Results (uncurated rows only)

The sufficiency filter applies only to rows where `source == "uncurated"`.
Curated source rows (ANZG, CCME, AIMS, CSIRO) bypass this filter entirely.

### casnumber_grouped × medium combinations assessed (uncurated only)

| Category | n combinations | % |
|----------|---------------|---|
| **Total combinations** | **10,033** | 100% |
| Pass both (≥5 species AND ≥4 classes) | 1,839 | 18.3% |
| Failing (any criterion) | 8,194 | 81.7% |

### Uncurated row retention

| Category | Rows | % of uncurated total |
|----------|------|---------------------|
| Uncurated rows in passing combinations (retained) | 38,523 | 68.4% |
| Uncurated rows in failing combinations (dropped) | 17,765 | 31.6% |
| **Total uncurated rows in input** | **56,288** | 100% |

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
| Total rows | 39,293 |
| Distinct chemicals | 1,056 |
| Distinct species | 2,978 |
| Columns | 20 |
| File: `data/allchronic_data.rda` | ~435.5 KB (compressed bzip2) |

### Medium breakdown

| Medium | Rows |
|--------|------|
| Freshwater | 19,597 |
| Unknown | 15,112 |
| Marine | 4,547 |
| Soft freshwater | 14 |
| Hard freshwater | 12 |
| Moderate freshwater | 11 |
| **Total** | **39,293** |

### Source breakdown

| Source | Rows |
|--------|------|
| uncurated | 38,523 |
| anzg | 592 |
| ccme | 98 |
| csiro | 60 |
| aims | 20 |
| **Total** | **39,293** |

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
selected into `allchronic_data`): `majorgroup`, `exclusion_flag`.

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

### New / updated files (tracked)
- `data/allchronic_data.rda` — package data object (39,293 rows × 20 cols, ~435.5 KB)
- `data-raw/alldata/DATASET.R` — Stage 6 + Stage 7 pipeline; expected row count updated to 59,200
- `data-raw/alldata/stage6-integration-report.md` — updated with new counts
- `data-raw/alldata/stage7-eligibility-report.md` — this file (updated)
- `data-raw/alldata/stage4e-aggregation-report.md` — regenerated by stage4e-aggregate.R
- `data-raw/alldata/stage4e-genus-rank-decisions.md` — new triage decisions file
- `scripts/alldata/stage4d-part2-manual-name-corrections.R` — 8 genus-rank corrections appended
- `scripts/alldata/stage4e-aggregate.R` — genus-rank exclusion filter (Step 2c) added

### Untracked files (do NOT commit)
- `data-raw/alldata/alldata_integrated.csv` — large intermediate file (~13.2 MB);
  regenerate by running `data-raw/alldata/DATASET.R` from scratch (delete CSV first).
- `data-raw/alldata/uncurated_raw_aggregated.csv` — Stage 4e output (59,200 rows, ~13.7 MB)
- `data-raw/alldata/stage4e-genus-rank-excluded.csv` — genus-rank excluded rows (~untracked)

### Note on row count changes from previous run

The genus-rank exclusion (Stage 4e Step 2c) removed entries whose `accepted_name`
was resolved at genus rank rather than species rank. Effect on final counts:

| Metric | Before | After |
|--------|--------|-------|
| Stage 4e output rows | 62,410 | 59,200 |
| Stage 6 retained rows | 59,986 | 57,058 |
| Stage 7 total rows | 42,252 | 39,293 |
| Distinct chemicals | 1,073 | 1,056 |
| Distinct species | 3,647 | 2,978 |
| allchronic_data.rda | ~473 KB | ~435.5 KB |
