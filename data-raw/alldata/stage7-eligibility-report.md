# Stage 7 Eligibility Report

Generated: 2026-06-27 (Stage 6/7 redesign)
Script: data-raw/alldata/DATASET.R

---

## 1. Output structure

Total rows in allchronic_data: 27699
Distinct Set keys: 1582
Distinct chemicals: 1222
Distinct species: 2885
Columns: 23 (Species, Conc, Chemical, CAS, Medium, Source, ValueTier,
  AnyChronicConvApplied, Class, Kingdom, Phylum, Order, Family, Genus, TaxonomyProvenance,
  NRecords, SourcesContributing, AnyAcrApplied, AnyConcFlagged, GeomeanFlagged,
  LifestageMixed, DurationMixed, Set)

## 2. Set counts by type

| Set type | n_sets | n_rows |
|----------|--------|--------|
| freshwater | 887 | 19577 |
| marine | 254 | 4547 |
| mixed | 438 | 3538 |
| soft_freshwater | 1 | 14 |
| hard_freshwater | 1 | 12 |
| moderate_freshwater | 1 | 11 |

## 3. Medium viability summary

Real-medium combinations assessed: 6431
Viable: 1144 (17.8%)
  — curated-backed: 44
  — uncurated only (≥5sp/≥4cl): 1100
  — non-viable: 5287
Mixed sets emitted: 438
Unknown rows dropped (FW+Marine both viable): 9221

## 4. ValueTier breakdown

| ValueTier | Rows |
|-----------|------|
| acute_acr | 17091 |
| accepted | 7074 |
| chronic_converted | 2764 |
| curated | 770 |

## 5. Source breakdown

| Source | Rows |
|--------|------|
| uncurated | 26929 |
| anzg | 592 |
| ccme | 98 |
| csiro | 60 |
| aims | 20 |

## 6. Validation

All 12 validation checks PASSED.

## 7. Files produced

- `data/allchronic_data.rda` — 27699 rows × 23 cols, 408.9 KB
- `data-raw/alldata/stage6-integration-report.md`
- `data-raw/alldata/stage7-eligibility-report.md` (this file)

**Untracked (do NOT commit):**
- `data-raw/alldata/uncurated_raw_aggregated.csv`

