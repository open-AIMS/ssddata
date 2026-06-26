# Stage 6 Integration Audit Report

Generated: 2026-06-26
Script: scripts/stage6-phase2-integrate.R

## 1. Input row counts

| Source | Input rows |
|--------|-----------|
| uncurated (Stage 4e) | 62410 |
| anzg_data | 592 |
| ccme_data | 144 |
| aims_data | 40 |
| csiro_data | 91 |
| **Total pre-exclusion** | **63244** |

## 2. CAS lookup

- UNCERTAIN rows excluded from uncurated pipeline: 18 (excluded = TRUE in cas_parent_lookup_all.csv)
- Curated source chemicals in curated_cas_lookup.csv: 39 distinct chemicals across 42 source x chemical rows
- master_lookup resolutions: 26 | webchem_cir: 0 | manual: 16 | unresolved: 0

## 3. Taxonomy resolution — aims and csiro

- Total distinct species (non-NA): 77
- Cache hits (species_resolution_v2.csv): 50 (64.9%)
- Fresh WoRMS resolutions: 4
- GBIF fallbacks: 6
- Unresolved: 17 — Heliocardis tuberculata, Saccrostrea echinata, Tisochrysis lutea (Isochrysis galbana), Scenedesmus accuminatus, Melanotaenia splendida splendida, Chlorella sp. (Swedish Isolate), Chlorella sp (Kakadu NT isolate), Chaetoceros curvesitus, Platymonus subcordiforus, Cyprinodon variegates, Dunalliella tertiolecta, Strongylocentrus pupuratus, Heliocidarus tuberculata, Amercamysis bahia, Mytilus gallprovincialis, Mytilus trossolus, Neanthes arenoceodantata
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
(See console output for tier counts.)

## 6. Exclusion rule application

### 6a. ANZG exclusion

- Chemicals with ANZG freshwater coverage: 22
- Chemicals with ANZG marine coverage: 10
- Rows excluded by anzg_rule_freshwater: 1300
- Rows excluded by anzg_rule_marine: 1039

### 6b. CCME exclusion

- CCME medium in data: Freshwater
- NOTE: CLAUDE.md describes ccme Medium as 'Unknown' (Issue #34); actual data differs.
- Total rows excluded by CCME rules: 890

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
| uncurated | Freshwater | 29426 |
| uncurated | Marine |  7324 |
| uncurated | Unknown | 22466 |
| **Total** | | **59986** |

## 8. Validation checks

All 7 checks PASSED.

## 9. Output

File: data-raw/alldata/alldata_integrated.csv
Size: 14.2 MB
Rows: 59986
Columns: 24
