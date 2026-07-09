# Stage 6 Integration Audit Report

Generated: 2026-07-09 (Stage 6/7 redesign)
Script: data-raw/alldata/DATASET.R

## 1. Input row counts

| Source | Input rows |
|--------|-----------|
| uncurated (Stage 4e) | 57544 |
| anzg_data | 592 |
| ccme_data | 144 |
| aims_data | 40 |
| csiro_data | 91 |
| **Total pre-exclusion** | **58407** |

## 2. Aims/CSIRO within-source aggregation

- AIMS:  40 input rows → 37 aggregated
- CSIRO: 91 input rows → 90 aggregated
- AIMS NA/empty-Species rows dropped (S6-D4 — no taxon assignable): 0
- CSIRO NA/empty-Species rows dropped (S6-D4 — no taxon assignable): 0

## 3. Source-priority and scope exclusion

| Rule | Rows excluded |
|------|--------------|
| Short-term scope (B0; all sources; per short_term_curated_sets.csv) | 127 |
| ANZG freshwater-family (broad, per chemical) | 1144 |
| ANZG marine (per chemical × Marine) | 821 |
| CCME (per chemical × medium) | 774 |
| Preference hierarchy (aims > csiro > uncurated) | 28 |

Short-term exclusion by source: anzg=29, csiro=30, uncurated=68

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
| uncurated | Freshwater | 26736 |
| uncurated | Marine | 6603 |
| uncurated | Unknown | 21433 |
| **Total** | | **55513** |

## 5. CCME notes

CCME medium in data: Freshwater
CCME input rows: 144; retained after ANZG exclusion: 98
NOTE: ccme Medium is 'Freshwater'. Issue #34 RESOLVED 2026-07-06 — supplier
(Angeline, CCME) confirmed all ccme data are chronic exposures in freshwater
media, matching the pipeline's Freshwater + curated-chronic treatment.

## 6. Validation

All validation checks PASSED.

