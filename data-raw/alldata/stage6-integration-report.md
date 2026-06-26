# Stage 6 Integration Audit Report

Generated: 2026-06-26 (updated after Stage 4e genus-rank exclusion patch)
Script: data-raw/alldata/DATASET.R (Stage 6 section)

## 1. Input row counts

| Source | Input rows |
|--------|-----------|
| uncurated (Stage 4e) | 59200 |
| anzg_data | 592 |
| ccme_data | 144 |
| aims_data | 40 |
| csiro_data | 91 |
| **Total pre-exclusion (combined frame)** | **60034** |

## 2. CAS lookup

- UNCERTAIN rows excluded from uncurated pipeline: 18 (excluded = TRUE in cas_parent_lookup_all.csv)
- Curated source chemicals in curated_cas_lookup.csv: 39 distinct chemicals across 42 source x chemical rows
- master_lookup resolutions: 26 | webchem_cir: 0 | manual: 16 | unresolved: 0

## 3. Taxonomy resolution — aims and csiro

- Total distinct species (non-NA): 77
- Cache hits (species_resolution_v2.csv): 50 (64.9%)
- Fresh WoRMS resolutions: 4
- GBIF fallbacks: 3
- Unresolved: 17 — Heliocardis tuberculata, Saccrostrea echinata, Tisochrysis lutea (Isochrysis galbana), Scenedesmus accuminatus, Melanotaemia splendida splendida, Chlorella sp. (Swedish Isolate), Chlorella sp (Kakadu NT isolate), Chaetoceros curvesitus, Platymonus subcordiforus, Cyprinodon variegates, Dunalliella tertiolecta, Strongylocentrus pupuratus, Heliocidarus tuberculata, Amercamysis bahia, Mytilus gallprovincialis, Mytilus trossolus, Neanthes arenoceodantata
- csiro NA-Species rows (chlorine x marine): 30 — treated as distinct accepted_name = NA group

## 4. Within-source aggregation — aims and csiro

| Source | Input rows | Output rows | Groups aggregated | geomean_flagged |
|--------|-----------|-------------|-------------------|-----------------|
| aims  | 40 | 37 | 3 | 0 |
| csiro | 91 | 61 | 30 | 1 |

Flagged groups:
- csiro | Unknown species (no name in source) | Chlorine | Marine | 5

## 5. Concentration plausibility audit — curated records (audit only)

No rows excluded from curated sources. Advisory only.

| Source | ok_range | low_soft | low_hard | high_soft | high_hard |
|--------|---------|---------|---------|---------|---------|
| anzg | 586 | 6 | 0 | 0 | 0 |
| ccme | 127 | 5 | 0 | 12 | 0 |
| aims | 39 | 0 | 0 | 1 | 0 |
| csiro | 91 | 0 | 0 | 0 | 0 |

## 6. Exclusion rule application

### 6a. ANZG exclusion

- Chemicals with ANZG freshwater coverage: 22
- Chemicals with ANZG marine coverage: 10
- Rows excluded by anzg_rule_freshwater: 1192
- Rows excluded by anzg_rule_marine: 948

### 6b. CCME exclusion

- CCME medium in data: Freshwater
- NOTE: CLAUDE.md records ccme Medium as previously 'Unknown' (Issue #34 pending); actual data shows 'Freshwater'.
- Total rows excluded by CCME rules (ccme_rule_freshwater): 807

### 6c. Preference hierarchy

- aims > csiro: 0 rows excluded
- aims > uncurated: 1 rows excluded
- csiro > uncurated: 28 rows excluded

## 7. Retained row counts by source and medium

| Source | Medium | Rows |
|--------|--------|------|
| aims | Marine |    20 |
| anzg | Freshwater |   348 |
| anzg | Hard freshwater |    12 |
| anzg | Marine |   207 |
| anzg | Moderate freshwater |    11 |
| anzg | Soft freshwater |    14 |
| ccme | Freshwater |    98 |
| csiro | Freshwater |    30 |
| csiro | Marine |    30 |
| uncurated | Freshwater | 28129 |
| uncurated | Marine |  7252 |
| uncurated | Unknown | 21640 |
| **Total** | | **57058** |

Uncurated reduction from 59,200 → 56,288 retained (after ANZG/CCME/preference exclusions).

## 8. Validation checks

All 7 checks PASSED.

## 9. Output

File: data-raw/alldata/alldata_integrated.csv
Size: 13.2 MB
Rows: 57058
Columns: 22

**Note on column count change from previous run (24 → 22):** The old stage6-phase2-integrate.R
retained two extra pipeline-internal columns (`Group`, `Chemical`) from source data frames.
DATASET.R selects only schema_cols + source + exclusion_flag = 22 columns. Stage 7 further
drops `majorgroup` and `exclusion_flag` to produce the 20-column allchronic_data object.
