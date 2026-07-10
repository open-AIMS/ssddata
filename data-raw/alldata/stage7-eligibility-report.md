# Stage 7 Eligibility Report

Generated: 2026-07-10 (Stage 6/7 redesign)
Script: data-raw/alldata/DATASET.R

---

## 1. Output structure

Total rows in allchronic_data: 26542
Distinct Set keys: 1526
Distinct chemicals: 1180
Distinct species: 2796
Columns: 24 (Species, Conc, Chemical, CAS, Medium, Source, ValueTier,
  AnyChronicConvApplied, EffectCategory, Class, Kingdom, Phylum, Order, Family, Genus,
  TaxonomyProvenance, NRecords, SourcesContributing, AnyAcrApplied, AnyConcFlagged,
  GeomeanFlagged, LifestageMixed, DurationMixed, Set)
  EffectCategory: effect_category of the selected endpoint (traditional only; NA for curated sources)

## 2. Set counts by type

| Set type | n_sets | n_rows |
|----------|--------|--------|
| freshwater | 860 | 18812 |
| marine | 235 | 4158 |
| mixed | 428 | 3535 |
| soft_freshwater | 1 | 14 |
| hard_freshwater | 1 | 12 |
| moderate_freshwater | 1 | 11 |

## 3. Medium viability summary

Real-medium combinations assessed: 6301
Viable: 1098 (17.4%)
  — curated-backed: 43
  — uncurated only (≥5sp/≥4cl): 1055
  — non-viable: 5203
Mixed sets emitted: 428
Unknown rows dropped (FW+Marine both viable): 8763

## 4. ValueTier breakdown

| ValueTier | Rows |
|-----------|------|
| acute_acr | 16729 |
| accepted | 6372 |
| chronic_converted | 2700 |
| curated | 741 |

## 5. Source breakdown

| Source | Rows |
|--------|------|
| uncurated | 25801 |
| anzg | 563 |
| ccme | 98 |
| csiro | 60 |
| aims | 20 |

## 5a. EffectCategory breakdown (C3)

EffectCategory is NA for all curated rows (anzg, ccme, aims, csiro); uncurated rows carry the traditional endpoint code of the selected value.
- NA EffectCategory (curated rows): 741
- Non-NA EffectCategory (uncurated rows): 25801

## 6. Validation

All 13 validation checks PASSED.

## 7. Files produced

- `data/allchronic_data.rda` — 26542 rows × 24 cols, 397 KB
- `data-raw/alldata/stage6-integration-report.md`
- `data-raw/alldata/stage7-eligibility-report.md` (this file)

**Untracked (do NOT commit):**
- `data-raw/alldata/uncurated_raw_aggregated.csv`

