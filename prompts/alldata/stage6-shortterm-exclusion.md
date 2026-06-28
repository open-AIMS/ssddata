## Session: Stage 6 short-term chlorine × marine exclusion
Date: 2026-06-28
Model: claude-sonnet-4-6

### Prompts and Responses

**User:** Implement an explicit, source-agnostic short-term scope exclusion for `allchronic_data`. The chlorine × Marine combination is the only current entry: the 2026 ANZG marine DGV is acute/short-term, out of scope for a chronic negligible-effect dataset. Scope: exclude from chronic only — do not route excluded rows anywhere, just exclude with full audit trail.

Tasks:
1. Create `data-raw/alldata/short_term_curated_sets.csv` (registry)
2. Add Step B0 in DATASET.R (before B1/B2/B3, source-agnostic, using left_join on casnumber_grouped × medium)
3. Add V13 validation check (no registry chemical × medium in allchronic_data)
4. Rebuild allchronic_data and verify regression

**Claude:** Completed. Key implementation details:

- `short_term_curated_sets.csv`: 1 row (chlorine, 7782505, Marine, exclude_from_chronic)
- `DATASET.R` B0 step (inserted between `all_rows` creation and B1):
  - Reads registry, filters to `scope == "exclude_from_chronic"`, left-joins on `casnumber_grouped + medium`
  - Uses `!is.na(.shortterm_flag)` in `case_when` (not `isTRUE()` which is not vectorized — this was the initial bug)
  - Marks matched rows `excl = "shortterm_chronic_scope"` in the existing `excl` column
  - Writes `stage6-shortterm-excluded.csv` (127 rows: anzg=29, csiro=30, uncurated=68)
- V13 check added after V12: asserts `semi_join` against registry returns 0 rows in allchronic_data
- Stage 6 report updated with B0 exclusion row; Stage 7 report updated to 13 checks

**Bug encountered:** `isTRUE(.shortterm_flag)` inside `case_when(mutate())` always returns `FALSE` because `isTRUE()` is a scalar predicate. Fixed to `!is.na(.shortterm_flag)`.

**Regression results:**

| Metric | Baseline | New | Delta |
|--------|----------|-----|-------|
| Rows | 26,533 | 26,536 | +3 |
| Sets | 1,525 | 1,525 | 0 |
| CAS/chemicals | 1,173 | 1,173 | 0 |
| Species | 2,801 | 2,796 | −5 |
| Chlorine × Marine | 29 | 0 | −29 |
| CSIRO chlorine leak | 0 | 0 | 0 |

Net +3 rows: chlorine_marine removed (−29 ANZG), chlorine_mixed added (+32 uncurated Unknown). Removing Marine viability lifted option-a suppression of chlorine × Unknown rows, which now form a valid mixed set. All delta rows are CAS 7782505.

Non-chlorine delta: 2,846 rows differ in Conc at ≤8e-15 relative (floating-point recomputation artifact) and 2 rows differ in Medium/Source (tie-breaking in `slice_min` shifted by csiro_data.rda row order change). All pre-existing from the stale committed baseline, not from B0.

All 13 validation checks PASS.

**R/get_ssddata.R:** No changes needed. The `all_chronic` branch only splits the prebuilt `allchronic_data` object by `Set`.

---

**Files to commit:**
- [ ] `data-raw/alldata/DATASET.R`
- [ ] `data-raw/alldata/short_term_curated_sets.csv`
- [ ] `data-raw/alldata/stage6-shortterm-excluded.csv`
- [ ] `data-raw/alldata/stage6-shortterm-exclusion-report.md`
- [ ] `data/allchronic_data.rda`
- [ ] `data-raw/alldata/stage6-integration-report.md`
- [ ] `data-raw/alldata/stage7-eligibility-report.md`
- [ ] `data-raw/alldata/stage4e-aggregation-report.md`

**Untracked (do NOT commit):** uncurated_raw_aggregated.csv (14.5 MB), allchronic_data_source.csv (137.3 MB)
