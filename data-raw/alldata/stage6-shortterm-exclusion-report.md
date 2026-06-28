# Stage 6 Short-Term Exclusion Verification Report

Generated: 2026-06-28  
Script: data-raw/alldata/DATASET.R (B0 step + V13 validation)  
Registry: data-raw/alldata/short_term_curated_sets.csv  
Audit CSV: data-raw/alldata/stage6-shortterm-excluded.csv

---

## 1. Change summary

An explicit short-term scope registry was introduced to exclude chemical × medium
combinations derived from acute/short-term guidelines, which are out of scope for
`allchronic_data`. The chlorine × Marine combination is the sole current entry:
the 2026 ANZG marine chlorine DGV is based on a short-term (acute) guideline
(Batley & Simpson 2020); CPO decays within days, making a chronic negligible-effect
assessment inapplicable.

The exclusion (Step B0 in DATASET.R) fires **before** the B1/B2/B3 priority gates
and covers **all sources**, removing every row matching a registry entry regardless
of where it originated.

---

## 2. Baseline vs new counts

| Metric | Baseline (committed HEAD) | New (this run) | Delta |
|--------|--------------------------|----------------|-------|
| Total rows | 26,533 | 26,536 | +3 |
| Distinct Set keys | 1,525 | 1,525 | 0 |
| Distinct chemicals (CAS) | 1,173 | 1,173 | 0 |
| Distinct species | 2,801 | 2,796 | −5 |
| chlorine_marine set | present (29 rows, ANZG) | **absent** | −1 set |
| chlorine_mixed set | absent | present (32 rows, uncurated) | +1 set |
| Chlorine × Marine rows | 29 | **0** | −29 |

**Source breakdown delta:**

| Source | Baseline | New | Delta |
|--------|----------|-----|-------|
| uncurated | 25,763 | 25,795 | +32 |
| anzg | 592 | 563 | −29 |
| ccme | 98 | 98 | 0 |
| csiro | 60 | 60 | 0 |
| aims | 20 | 20 | 0 |

---

## 3. B0 exclusion counts (per source, Chlorine × Marine only)

| Source | Rows excluded by B0 |
|--------|-------------------|
| anzg | 29 |
| csiro | 30 |
| uncurated | 68 |
| **Total** | **127** |

All 127 rows: CAS = 7782505 (Chlorine), medium = Marine.

Written to: `data-raw/alldata/stage6-shortterm-excluded.csv` (tracked).

---

## 4. Chlorine × Marine: zero-survivor confirmation

- **Chlorine × Marine rows in allchronic_data: 0** (from all sources combined)
- **CSIRO chlorine marine leak: 0** — 30 csiro × Marine × Chlorine rows were
  excluded by B0 (before B1 could reach them). The csiro_data.rda now carries
  species for the chlorine rows (HEAD commit `fa7913d`), so S6-D4 no longer fires;
  B0 is the sole gate for these rows. No csiro chlorine marine rows reach
  allchronic_data.
- **V13 validation check: PASS** — the check confirmed zero survivors.

---

## 5. Net row delta (+3) explanation

Removing chlorine_marine triggered the option-a medium pooling rule:

- **Before:** chlorine had both Freshwater (standalone, 89 species) and Marine
  (standalone, 29 species, ANZG) viable → chlorine × Unknown rows were dropped
  by option-a (dropped when both FW and Marine viable for the same chemical).
- **After B0:** chlorine × Marine = 0 → Marine is no longer viable → option-a no
  longer applies → 68 chlorine × Unknown (uncurated) rows now enter the mixed pool.
- These 68 rows collapse to 32 species-level rows in the mixed pool and pass the
  ≥5sp/≥4cl threshold → **chlorine_mixed** set emitted (32 rows, uncurated, Unknown).

Net chlorine delta: −29 (chlorine_marine) + 32 (chlorine_mixed) = **+3 rows**.

This is expected pipeline behaviour. All delta rows have CAS = 7782505 (Chlorine).
Excluding all chlorine rows from the comparison, every other Set is unchanged.

---

## 6. Non-chlorine delta (stale-baseline artefacts, not from B0)

When comparing new vs committed baseline (excluding chlorine rows):

| Difference type | Count | Cause |
|----------------|-------|-------|
| Conc floating-point (relative ≤ 8e-15) | 2,846 rows | Geometric mean recomputation; numerically identical |
| Medium / SourcesContributing change | 2 rows | Tie-breaking in slice_min |

**The 2 Medium/Source changes** (17-Methyltestosterone mixed set, Amines mixed set):
both are tied-Conc rows in mixed sets where `slice_min(conc_ug_L, with_ties=FALSE)`
broke the tie differently. The tie-breaking changed because the updated
`csiro_data.rda` (committed `fa7913d`) adds 30 csiro chlorine rows to `csiro_layer`,
which shifts row ordering in `all_rows` → `retained` → the mixed pool. Both the
Freshwater and Unknown rows for those species have the **same Conc** (0.042 µg/L
and 96 µg/L); the chosen row is equivalent, not a data regression.

**Conclusion:** These differences pre-exist the B0 changes — they are an artefact of
rebuilding after `csiro_data.rda` was updated. They would appear even if B0 were not
present. The data is functionally equivalent.

---

## 7. Validation checks

All **13** validation checks passed (V1–V12 pre-existing + V13 new):

```
PASS -- Curated rows: ValueTier=='curated', AnyChronicConvApplied==FALSE, EffectCategory==NA
PASS -- AIMS/CSIRO: one row per source × CAS × medium × species
PASS -- ANZG/CCME chemical×medium not shared with other sources
PASS -- Every standalone real-medium set is viable (curated-backed or >=5sp/>=4cl)
PASS -- Every mixed set passes >=5 species / >=4 classes
PASS -- No species appears in both a standalone set and that chemical's mixed set
PASS -- Unknown-medium rows only appear in mixed sets
PASS -- ANZG freshwater variants are distinct Set values (never collapsed)
PASS -- Set keys are unique (1 CAS per Set)
PASS -- Mixed sets have one row per species
PASS -- Species: no NA
PASS -- Conc: no NA
PASS -- Conc: all > 0
PASS -- Set: no NA
PASS -- Species: no NA, empty, or placeholder values
PASS -- No short-term-excluded chemical×medium in allchronic_data (short_term_curated_sets.csv)
```

---

## 8. Files produced by this run

**Tracked (commit these):**
- `data-raw/alldata/DATASET.R` — B0 step + V13 validation added
- `data-raw/alldata/short_term_curated_sets.csv` — short-term scope registry (new)
- `data-raw/alldata/stage6-shortterm-excluded.csv` — B0 audit CSV, 127 rows (new)
- `data-raw/alldata/stage6-shortterm-exclusion-report.md` — this file (new)
- `data/allchronic_data.rda` — rebuilt, 26,536 rows × 24 cols, 396.6 KB
- `data-raw/alldata/stage6-integration-report.md` — updated (B0 row added)
- `data-raw/alldata/stage7-eligibility-report.md` — updated (13 checks)

**Untracked (do NOT commit):**
- `data-raw/alldata/uncurated_raw_aggregated.csv` (14.5 MB)
- `data-raw/alldata/allchronic_data_source.csv` (137.3 MB)
