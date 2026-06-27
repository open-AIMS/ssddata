# Stage 6 Integration Audit Report

Generated: 2026-06-27 (Stage 6/7 redesign)
Script: data-raw/alldata/DATASET.R

## 1. Input row counts

| Source | Input rows |
|--------|-----------|
| uncurated (Stage 4e) | 59177 |
| anzg_data | 592 |
| ccme_data | 144 |
| aims_data | 40 |
| csiro_data | 91 |
| **Total pre-exclusion** | **60010** |

## 2. Aims/CSIRO within-source aggregation

- AIMS:  40 input rows → 37 aggregated
- CSIRO: 91 input rows → 60 aggregated
- AIMS NA/empty-Species rows dropped (S6-D4 — no taxon assignable): 0
- CSIRO NA/empty-Species rows dropped (S6-D4 — no taxon assignable): 30

## 3. Source-priority exclusion

| Rule | Rows excluded |
|------|--------------|
| ANZG freshwater-family (broad, per chemical) | 1192 |
| ANZG marine (per chemical × Marine) | 947 |
| CCME (per chemical × medium) | 807 |
| Preference hierarchy (aims > csiro > uncurated) | 29 |

## 4. Retained rows by source × medium

| Source | Medium | Rows |
|--------|--------|------|
| aims | Marine | 20 |
| anzg | Freshwater | 348 |
| anzg | Hard freshwater | 12 |
| anzg | Marine | 207 |
| anzg | Moderate freshwater | 11 |
| anzg | Soft freshwater | 14 |
| ccme | Freshwater | 98 |
| csiro | Freshwater | 30 |
| csiro | Marine | 30 |
| uncurated | Freshwater | 27632 |
| uncurated | Marine | 6995 |
| uncurated | Unknown | 21638 |
| **Total** | | **57035** |

## 5. CCME notes

CCME medium in data: Freshwater
CCME input rows: 144; retained after ANZG exclusion: 98
NOTE: ccme Medium is 'Freshwater' in source data. Issue #34 pending.

## 6. Validation

All validation checks PASSED.

