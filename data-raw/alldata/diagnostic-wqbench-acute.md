# Diagnostic: wqbench acute classification reliability

**Date:** 2026-06-28  
**Model:** Claude Sonnet 4.6  
**Purpose:** Read-only investigation of whether wqbench's `test_class` (acute/chronic)
is reliable enough for `all_short`, or whether `duration_hours` should be used instead.  
**Scope:** wqbench rows in `uncurated_raw_dedup_enriched.csv` only.

---

## 1. What wqbench carries at our access point

### Extraction code (stage4b-extract.R, lines 857–861)
```r
test_class = case_when(
  duration_class == "chronic" ~ "chronic",
  duration_class == "acute"   ~ "acute",
  TRUE                        ~ duration_class
),
```
`test_class` is a direct passthrough of wqbench's `duration_class` field. No
reclassification is applied; any string other than `"chronic"` or `"acute"` passes
through verbatim (the TRUE branch is a safety net, not a catch-all for NAs).

### Fields in the enriched CSV
`duration_class` **is NOT present** in `uncurated_raw_dedup_enriched.csv`. It was
consumed at extraction and never written to the intermediate. Only `test_class` and
`duration_hours` survive.

### duration_hours completeness
| Source | Rows | NA count | NA rate |
|--------|------|----------|---------|
| wqbench | 361,782 | 0 | 0% |

`duration_hours` is 100% complete for wqbench rows (derived from wqbench's numeric
`duration_hrs` column via `as.numeric(duration_hrs)` at line 847).

### test_class distribution (wqbench, all rows)
| test_class | n |
|------------|---|
| acute | 224,374 |
| chronic | 137,408 |

No other values; the TRUE catch-all in the extraction never fires.

---

## 2. test_class × duration_hours cross-tabulation

### Duration quantiles by test_class

| test_class | n | min | p5 | p25 | median | p75 | p95 | max |
|------------|---|-----|----|-----|--------|-----|-----|-----|
| acute | 224,374 | 0 | 6 | 48 | 96 | 96 | 192 | 500 |
| chronic | 137,408 | 24.5 | 72 | 192 | 504 | 768 | 2,880 | 26,280 |

The acute distribution clusters tightly: p25 = 48 h (48 h Daphnia test), median = p75 = 96 h
(standard OECD fish acute test). The max of 500 h is a sharp ceiling — likely a
truncation or cap in the source data, not an observed test duration. The chronic
distribution is plausible: 24 h minimum (algal life-cycle tests; see §4), median 504 h
(~21 days).

### Disagreement counts at candidate thresholds

| Threshold | "chronic" rows ≤ threshold | "acute" rows > threshold |
|-----------|--------------------------|-------------------------|
| 48 h | 4,175 | 126,637 (56.4% of acute) |
| 96 h | 18,118 | 33,506 (14.9% of acute) |
| 120 h | 21,182 | 24,479 (10.9% of acute) |

The 96 h threshold is the natural cut: it is the standard OECD acute fish/crustacean test
duration, which explains why the acute distribution piles up at median = p75 = 96 h. Using
96 h as the boundary correctly retains these tests as acute.

At 48 h the "acute" side loses 56 % of rows — far too restrictive, as 96 h fish tests are
genuine acute tests. At 120 h the gain over 96 h is modest (8 k rows) and the threshold
has no standard-method grounding.

---

## 3. Reclassification impact on wqbench "acute" candidates by statistic type

Total wqbench acute rows: **224,374**

Statistic-type groups in wqbench acute rows (top):

| stat_group | n | note |
|---|---|---|
| LC50/EC50/IC50 | 129,475 | ACR-eligible; may go to chronic via ACR |
| NOEC-type (NOEC/NOEL) | 47,562 | would be "accepted" negligible-effect |
| other (LOEC/LOEL/MATC/LOAEC…) | ~40,000 | excludes from chronic (no Warne treatment for acute LOEC) |
| ECx (LC10/EC10/…) | ~7,000 | depends on x |

**Rows reclassified as "not-acute" at each threshold** (duration_hours > threshold):

| Threshold | Total reclassified | LC50/EC50/IC50 | NOEC-type | Other | ECx |
|-----------|-------------------|----------------|-----------|-------|-----|
| 48 h | 126,637 (56.4%) | 61,550 | 32,755 | 27,921 | 4,411 |
| 96 h | 33,506 (14.9%) | 5,258 | 14,205 | 12,888 | 1,155 |
| 120 h | 24,479 (10.9%) | 4,000 | 10,148 | 9,258 | 1,073 |

At the 96 h threshold, **5,258 LC50/EC50/IC50 rows** currently labeled "acute" would
be reclassified — these are the rows that would otherwise enter `all_short` as ACR-eligible
or as direct acute median-effect values. Removing them reduces the ACR-eligible "acute"
pool by ~4 % (5,258 of ~129,475). The large NOEC-type and "other" reclassified rows are
relevant for `all_short` if that pipeline includes any chronic-converted or negligible-effect
acute endpoints (NOEC from a 20-day test would not belong there regardless).

---

## 4. Spot-check: worst-disagreeing rows

### "Acute" rows with longest duration_hours (top 5)

| duration_hours | statistic_type | effect_category | species | majorgroup | conc_value | conc_unit | life_stage | medium |
|---|---|---|---|---|---|---|---|---|
| 500 | LC50 | MORT | Geophagus brasiliensis | Actinopterygii | 0.304 | mg/L | NA | Freshwater |
| 480 | NOEC | BCH | Oreochromis niloticus | Teleostei | 0.00145 | mg/L | Fingerling | Freshwater |
| 480 | NOEC | REP | Barbus ticto | Teleostei | 0.033 | mg/L | NA | Freshwater |
| 480 | NOEL | BCH | Sparus aurata | Teleostei | 0.1 | mg/L | NA | Marine |
| 480 | NOEC | MOR | Clarias gariepinus | Teleostei | 2.15 | mg/L | Juvenile | Freshwater |

These are unambiguously chronic tests mislabeled as acute. A 500 h or 480 h NOEC/LC50 on
fish is a subchronic-to-chronic exposure by any definition. The 500 h ceiling for "acute"
is particularly suspicious — this may be a data entry artifact or a cap in the wqbench
source data.

### "Chronic" rows with shortest duration_hours (top 5)

| duration_hours | statistic_type | effect_category | species | majorgroup | life_stage |
|---|---|---|---|---|---|
| 24.5 | LOEC | BCH | Karenia brevis | Dinophyceae | Exponential growth |
| 24.5 | LOEC | POP | Scenedesmus quadricauda | Chlorophyceae | NA |
| 24.5 | LOEC | POP | Microcystis aeruginosa | Cyanophyceae | NA |
| 24.5 | NOEC | POP | Oscillatoria sp. | Cyanophyceae | NA |
| 24.5 | LOEC | POP | Selenastrum capricornutum | Chlorophyceae | NA |

These are 24 h algal/cyanobacterial growth inhibition tests. For unicellular algae, a 24 h
exposure can span multiple generations and is conventionally classified as "chronic" in
ecotox databases. The "chronic" label here is **arguably correct** and should not be
reclassified by a duration threshold. A blanket <96h = acute rule would falsely reclassify
these short-generation organisms.

### Data quality markers for duration_hours

| Issue | Count | Assessment |
|---|---|---|
| duration_hours == 0 | 41 | Probable data errors or unit confusion (sub-minute?) |
| duration_hours < 1 h | 2,526 | Appear genuine: fertilization/embryo tests at ~10–40 min; all labeled acute |

Sub-hour rows are real short-duration ecotoxicity tests (sperm motility, embryo development),
not placeholders. The 41 zero-duration rows are suspect but a negligible fraction.
`duration_hours` shows no widespread encoding artifacts — it is a clean numeric field.

---

## 5. Other fields that might help

The enriched CSV contains only the 33 columns in the stage 4 schema. Potentially useful
fields for resolving the acute/chronic call:

- **`duration_hours`** — 100% complete, clean, primary candidate (see §§2–4).
- **`statistic_type`** — partially informative: NOEC/NOEL/LOEC from a short test could
  still be a chronic result (algae). LC50 at 480 h is clearly chronic. Does not resolve
  ambiguous cases on its own.
- **`study_reference`** — free-text bibliographic string; could in principle be parsed for
  "chronic" / "acute" cues, but this is fragile and not worth the effort.
- **`life_stage`** — relevant (early-life-stage tests are sometimes classified differently),
  but sparse (~high NA rate in wqbench rows) and not sufficient alone.

`duration_class` — the upstream wqbench label that feeds `test_class` — **is not available**
in the enriched CSV. Recovering it would require re-running stage4b-extract.R from the raw
wqbench SQLite data (Windows Positron / live DB). Nothing in the enriched CSV can reconstruct
it beyond `test_class` itself.

---

## Implications for all_short

### Bottom line

The `test_class` passthrough is **not good enough** on its own for `all_short`. The "acute"
pool contains a material contamination of chronic-duration rows:

- **14.9 %** of wqbench acute rows (33,506) have `duration_hours > 96 h`.
- Among ACR-eligible rows (LC50/EC50/IC50), the contamination is ~4 % (5,258 rows), smaller
  but not negligible.
- The worst cases (480–500 h tests labeled "acute") are unambiguously chronic exposures.

### Recommended approach for wqbench in all_short

**Apply `duration_hours <= 96 h` as a post-filter on top of `test_class == "acute"`** for
wqbench. Do not apply it to anztox or envirotox (those flags are terminal and their
`duration_hours` fields have different provenance).

Rationale for 96 h:
- Aligns with the most common OECD acute test durations (96 h fish, 48 h Daphnia — both
  pass).
- The acute distribution's p75 = 96 h; a 96 h cap leaves the core acute data intact.
- Short algal "chronic" tests (24 h) are already labeled chronic and are not in scope.
- The 41 zero-duration rows (0.02 % of wqbench) would be excluded by `duration_hours > 0`
  if added; this is optional.

What the 96 h filter removes (relative to passthrough-only):
- 33,506 acute-labeled rows with long duration, of which 5,258 are LC50/EC50/IC50
  (ACR-eligible) and the remainder are NOEC/LOEC/MATC types that would likely be
  treated differently in any acute pipeline anyway.
- No "chronic" rows are affected (the 18,118 short-chronic rows remain labeled chronic
  and are simply not in the acute pool).

### What the passthrough gets right

Despite the contamination, `test_class` carries real information. The 24.5 h algal "chronic"
rows are correctly labeled and would be incorrectly reclassified if a pure duration filter
were used without reference to `test_class`. The recommended approach — intersection of
`test_class == "acute"` AND `duration_hours <= 96 h` — preserves this: those chronic algal
rows are already excluded by `test_class`.

### Threshold sensitivity

| Threshold | Acute rows retained | Notes |
|---|---|---|
| No filter (passthrough) | 224,374 | 14.9 % are long-duration; not recommended |
| ≤ 120 h | 199,895 (89.1%) | Some genuine >96 h tests excluded |
| ≤ 96 h (recommended) | 190,868 (85.1%) | Aligns with OECD standard; cleanest cut |
| ≤ 48 h | 97,737 (43.6%) | Over-excludes; drops 96 h fish tests |

---

*Files to commit:* `data-raw/alldata/diagnostic-wqbench-acute.md` (this report)
