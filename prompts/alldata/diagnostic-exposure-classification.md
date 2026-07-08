## Session: diagnostic-exposure-classification
Date: 2026-06-28
Model: Claude Sonnet 4.6

### Prompts and Responses

**User:** Read-only diagnostic — how does the pipeline classify acute vs chronic?

Context: scoping an `all_short` (acute) sibling to `allchronic_data`. Tasks:
(1) locate where `test_class` is assigned per source; (2) compare to Warne Table 1;
(3) report test_class distribution in `uncurated_raw_dedup_enriched.csv`; (4) explain
subchronic; (5) characterise the acute statistic landscape; (6) confirm duration field.
Deliverable: `data-raw/alldata/diagnostic-exposure-classification.md`. Read-only.

**Claude:** Traced `test_class` derivation in `data-raw/alldata/scripts/stage4b-extract.R`
(all three sources) and `data-raw/alldata/DATASET.R` (Step 2b acute-non-eligible drop,
Step 3 ACR, Step 3a chronic/subchronic conversion, Step 3c tier ranking). Ran a
read-only R diagnostic against the enriched CSV (449,860 rows). Wrote
`data-raw/alldata/diagnostic-exposure-classification.md` with complete findings.

Key finding: `test_class` is a **passthrough** from each source's own label — it is
NOT a Warne Table 1 computation. A dedicated Table 1 classifier would be needed for
`all_short`. The diagnostic report gives full detail.

---

## Session: wqbench acute classification reliability diagnostic
Date: 2026-06-28
Model: Claude Sonnet 4.6

### Prompts and Responses

**User:** Read-only diagnostic on wqbench `test_class` (acute/chronic) reliability for
the planned `all_short` pipeline. The prior exposure-classification diagnostic showed
drift concentrated in wqbench — some "chronic" rows at ~24.5 h and some "acute" rows
out to ~500 h. The hypothesis is that wqbench's `duration_class` is a coarse label and
`duration_hours` is the more trustworthy primitive. Tasks: (1) confirm what wqbench
carries at our access point (completeness of `duration_hours`, contents of
`duration_class`); (2) cross-tabulate `test_class` vs `duration_hours` with quantiles
and disagreement counts at 48/96/120 h thresholds; (3) reclassification impact on
"acute" candidates by statistic type; (4) spot-check 10 worst-disagreeing rows; (5) note
other resolving fields. Deliverable: `data-raw/alldata/diagnostic-wqbench-acute.md`.
Hard constraints: read-only; no DATASET.R; `read_csv(..., guess_max=Inf)`.

**Claude:** Ran R diagnostic script on `uncurated_raw_dedup_enriched.csv` (wqbench
subset: 361,782 rows). Key findings:

1. **`duration_class` is not in the enriched CSV** — it was consumed at extraction
   (stage4b-extract.R lines 857–861) and only `test_class` passes through.
   `duration_hours` is 100% complete (0 NAs) for wqbench rows.

2. **Distribution:** Acute rows (224,374): min=0, p25=48h, median=p75=96h, max=500h.
   Chronic rows (137,408): min=24.5h, median=504h, max=26,280h. The 500h max for "acute"
   appears to be a truncation cap in the wqbench source data.

3. **Disagreement at thresholds:**
   - 48h: 4,175 "chronic" rows ≤48h; 126,637 "acute" rows >48h (56.4%)
   - 96h: 18,118 "chronic" rows ≤96h; 33,506 "acute" rows >96h (14.9%)
   - 120h: 21,182 "chronic" rows ≤120h; 24,479 "acute" rows >120h (10.9%)

4. **Reclassification at 96h** (the recommended threshold): 33,506 rows removed from
   acute pool — 5,258 LC50/EC50/IC50, 14,205 NOEC-type, 12,888 other, 1,155 ECx.

5. **Spot-checks:** Long "acute" rows (480–500h fish NOEC/LC50) are unambiguously
   chronic mislabels. Short "chronic" rows (24.5h) are all algal/cyanobacterial
   tests — these are conventionally classified as chronic (full life-cycle for
   unicellular organisms) and should NOT be reclassified by a duration threshold.

6. **Implication:** Passthrough alone is not sufficient. Recommended: filter wqbench
   to `test_class == "acute" AND duration_hours <= 96h` for `all_short`. The 96h
   cut retains 190,868 (85.1%) of current acute rows while removing the long-duration
   contamination. The chronic algal rows are already excluded (labeled chronic), so
   the intersection approach is safe.

Full results in `data-raw/alldata/diagnostic-wqbench-acute.md`.

---
