# Stage 6 Integration Audit Report

Generated: 2026-07-28 (Stage 6/7 redesign)
Script: data-raw/alldata/DATASET.R

## 1. Input row counts

| Source | Input rows |
|--------|-----------|
| uncurated (Stage 4e) | 57425 |
| anzg_data | 592 |
| ccme_data | 144 |
| aims_data | 40 |
| csiro_data | 91 |
| **Total pre-exclusion** | **58288** |

## 2. Aims/CSIRO within-source aggregation

- AIMS:  40 input rows → 37 aggregated
- CSIRO: 91 input rows → 90 aggregated
- AIMS NA/empty-Species rows dropped (S6-D4 — no taxon assignable): 0
- CSIRO NA/empty-Species rows dropped (S6-D4 — no taxon assignable): 0

## 3. Source-priority and scope exclusion

| Rule | Rows excluded |
|------|--------------|
| ANZG freshwater-family (broad, per chemical) | 1144 |
| ANZG marine (per chemical × Marine) | 919 |
| CCME (per chemical × medium) | 774 |
| Preference hierarchy (aims > csiro > uncurated) | 28 |
| Timeframe scope (short_term Timeframe attribute; post priority gates) | 29 |

Timeframe exclusion by source: anzg=29

## 4. Retained rows by source × medium

| Source | Medium | Rows |
|--------|--------|------|
| aims | Marine | 20 |
| anzg | Freshwater | 348 |
| anzg | Hard freshwater | 12 |
| anzg | Marine | 178 |
| anzg | Moderate freshwater | 11 |
| anzg | Soft freshwater | 14 |
| ccme | Freshwater | 98 |
| csiro | Freshwater | 30 |
| csiro | Marine | 30 |
| uncurated | Freshwater | 26640 |
| uncurated | Marine | 6583 |
| uncurated | Unknown | 21430 |
| **Total** | | **55394** |

## 5. CCME notes

CCME medium in data: Freshwater
CCME input rows: 144; retained after ANZG exclusion: 98
NOTE: ccme Medium is 'Freshwater'. Issue #34 RESOLVED 2026-07-06 — supplier
(Angeline, CCME) confirmed all ccme data are chronic exposures in freshwater
media, matching the pipeline's Freshwater + curated-chronic treatment.

## 6. Validation

All validation checks PASSED.

