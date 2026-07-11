# Stage 7 Eligibility Report

Generated: 2026-07-10 (Stage 6/7 redesign)
Script: data-raw/alldata/DATASET.R

---

## 1. Output structure

Total rows in allchronic_data: 26501
Distinct Set keys: 1520
Distinct chemicals: 1175
Distinct species: 2796
Columns: 24 (Species, Conc, Chemical, CAS, Medium, Source, ValueTier,
  AnyChronicConvApplied, EffectCategory, Class, Kingdom, Phylum, Order, Family, Genus,
  TaxonomyProvenance, NRecords, SourcesContributing, AnyAcrApplied, AnyConcFlagged,
  GeomeanFlagged, LifestageMixed, DurationMixed, Set)
  EffectCategory: effect_category of the selected endpoint (traditional only; NA for curated sources)

## 2. Set counts by type

| Set type | n_sets | n_rows |
|----------|--------|--------|
| freshwater | 857 | 18787 |
| marine | 234 | 4153 |
| mixed | 426 | 3524 |
| soft_freshwater | 1 | 14 |
| hard_freshwater | 1 | 12 |
| moderate_freshwater | 1 | 11 |

## 3. Medium viability summary

Real-medium combinations assessed: 6260
Viable: 1094 (17.5%)
  — curated-backed: 43
  — uncurated only (≥5sp/≥4cl): 1051
  — non-viable: 5166
Mixed sets emitted: 426
Unknown rows dropped (FW+Marine both viable): 8763

## 4. ValueTier breakdown

| ValueTier | Rows |
|-----------|------|
| acute_acr | 16703 |
| accepted | 6360 |
| chronic_converted | 2697 |
| curated | 741 |

## 5. Source breakdown

| Source | Rows |
|--------|------|
| uncurated | 25760 |
| anzg | 563 |
| ccme | 98 |
| csiro | 60 |
| aims | 20 |

## 5a. EffectCategory breakdown (C3)

EffectCategory is NA for all curated rows (anzg, ccme, aims, csiro); uncurated rows carry the traditional endpoint code of the selected value.
- NA EffectCategory (curated rows): 741
- Non-NA EffectCategory (uncurated rows): 25760

## 6. Validation

All 16 validation checks PASSED.

## 7. Files produced

- `data/allchronic_data.rda` — 26501 rows × 24 cols, 395.8 KB
- `data-raw/alldata/stage6-integration-report.md`
- `data-raw/alldata/stage7-eligibility-report.md` (this file)

**Untracked (do NOT commit):**
- `data-raw/alldata/uncurated_raw_aggregated.csv`

