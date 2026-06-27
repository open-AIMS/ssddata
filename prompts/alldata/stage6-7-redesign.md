## Session: Stage 6/7 redesign — named-list output with Set column
Date: 2026-06-27
Model: Claude Sonnet 4.6

### Prompts and Responses

**User:** Full Stage 6/7 redesign prompt (see session). Scope: rewrite
`data-raw/alldata/DATASET.R` and `R/get_ssddata.R` to implement the new
named-list design for `all_chronic`. Key decisions confirmed in prompt:
1. Curated mediums never enter the mixed pool.
2. `allchronic_data` stays flat with a `Set` column;
   `ssd_data_sets(set="all_chronic")` returns `split(allchronic_data, Set)`.
3. Set key format: `sanitise(chemicalname_grouped)_medium_token` with
   CAS fallback on collision.
4. Mixed-pool species collapse: one row per species, lowest `conc_ug_L`.

**Claude:** Rewrote `data-raw/alldata/DATASET.R` (Steps A–E), updated
`R/get_ssddata.R` (`all_chronic` branch), and updated `R/allchronic_data.R`
docs. Ran `devtools::document()` to regenerate `man/`.

Key implementation decisions:
- No `alldata_integrated.csv` intermediate — all processing is in-memory.
- CCME exclusion: per `casnumber_grouped × medium` (joins to find CCME-covered
  combinations; uses `!is.na(ccme_covered)` not `isTRUE()`).
- ANZG freshwater broad-matching: any ANZG fw-family presence for a chemical
  excludes ALL non-ANZG fw-family rows for that chemical (chemical-level, not
  per-variant).
- Pool species dedup: after collapsing the pool to one row per species, remove
  any species already present in a standalone set for the same chemical
  (`anti_join` on `casnumber_grouped × accepted_name`). This enforces the
  no-overlap invariant.
- Collision fallback: for Set key collisions, use
  `sanitise(casnumber_grouped)_medium_token` for standalone sets and
  `sanitise(casnumber_grouped)_mixed` for mixed sets.
- `allchronic_data` gains 3 new columns vs. old design: `ValueTier`,
  `AnyChronicConvApplied`, `Set` (23 columns total, up from 20).

Bugs found and fixed during run:
1. `replace_na()` not available (tidyr not loaded) → replaced with `if_else(is.na(...), FALSE, ...)`.
2. CCME exclusion used `isTRUE(ccme_covered)` on a column vector → changed to `!is.na(ccme_covered)`.
3. Collision fallback generated inconsistent Set keys for mixed set rows (different
   per-row `medium` values) → fixed to detect mixed vs. standalone from existing Set suffix.
4. Pool overlap: species in standalone sets also appeared in pool → added
   `anti_join` step to enforce no-overlap.

Output (all 14 validation checks PASSED):
- `allchronic_data`: 27,699 rows × 23 cols, 1,582 Set keys
- `data/allchronic_data.rda`: ~409 KB
- Standalone sets: 1,144; Mixed sets: 438
- ValueTier: accepted 7,074 / acute_acr 17,091 / chronic_converted 2,764 / curated 770
- Source: uncurated 26,929 / anzg 592 / ccme 98 / csiro 60 / aims 20

`ssd_data_sets(set="all_chronic")` returns a named list of 1,582 tibbles,
each with Set column dropped. `copper_marine` → 45 rows (ANZG source).

---

## Session: Patch — curated NA-species exclusion (S6-D4 reinstatement)
Date: 2026-06-27
Model: Claude Sonnet 4.6

### Prompts and Responses

**User:** `prep_curated_source()` was coining an `"Unknown species (no name in source)"` placeholder
for rows with `is.na(Species)`, creating a non-existent taxon in the SSD data and re-admitting
csiro's chlorine/marine acute rows (30 NA-species marine rows) which S6-D4 excludes. Fix: drop
`is.na(Species)` rows before taxonomy join and geomean; update Stage 6 report; add V12 validation
check to assert no placeholder Species in the final dataset.

**Claude:** Four changes to `data-raw/alldata/DATASET.R`:

1. **`prep_curated_source()` — drop NA/empty Species before taxonomy join** (after CAS join, before
   `left_join(taxonomy_lookup)`). Filter out `is.na(Species) | trimws(Species) == ""`. Removed the
   `is.na(Species) ~ "Unknown species (no name in source)"` case_when branch and the
   `"no_species"` `taxonomy_provenance` branch. Emits `message()` with source + count for audit.

2. **Pre-compute NA counts** (`n_aims_no_species`, `n_csiro_no_species`) before calling the
   function, so the report section can reference them.

3. **Stage 6 integration report** (section 2): replaced "grouped as 'Unknown species'" note with
   per-source dropped-row counts labelled S6-D4.

4. **V12 validation check**: asserts no `Species` in the final `allchronic_data` is NA, empty, or
   matches `^Unknown` / contains "no name in source". Fails loudly if found. Report updated to
   "All 12 validation checks PASSED."

Run result (all 15 `chk()` calls PASSED):
- `csiro: dropping 30 NA/empty-Species rows (S6-D4)` — expected
- CSIRO: 91 input rows → 60 aggregated (was 61, but the placeholder was excluded by ANZG priority
  anyway — the fix matters to prevent sneak-through if ANZG coverage changes)
- Total `allchronic_data` unchanged: 27,699 rows × 23 cols, 1,582 Set keys
- `data/allchronic_data.rda`: 408.9 KB

---
