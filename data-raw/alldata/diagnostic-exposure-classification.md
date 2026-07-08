# Diagnostic: Exposure Classification (acute vs chronic) in the Uncurated Pipeline

Generated: 2026-06-28  
Basis: Read-only investigation of `data-raw/alldata/scripts/stage4b-extract.R`,
`data-raw/alldata/DATASET.R`, and `data-raw/alldata/uncurated_raw_dedup_enriched.csv`
(449,860 rows × 33 cols). R diagnostic script run on the clean subset
(dedup_retained == TRUE & priority_kept == TRUE; 381,333 rows).

---

## 1. How `test_class` is derived — per source

`test_class` is a **passthrough from each source's own classification field**. It is
NOT computed from Warne et al. 2025 Table 1 rules (organism type × life stage ×
endpoint × exposure duration). The derivation differs by source:

### 1a. anztox

**Code location:** `stage4b-extract.R`, lines 678–701 (Section 3e).

```r
# stage4b-extract.R lines 678-701
anztox_classified <- anztox_filtered |>
  mutate(
    testtype_norm = str_to_lower(str_squish(testtype)),
    test_class = case_when(
      testtype_norm == "chronic"                     ~ "chronic",
      str_detect(testtype_norm, "^sub[ -]?chronic$") ~ "subchronic",
      testtype_norm == "acute"                       ~ "acute",
      testtype_norm == "chronic qsar"                ~ "QSAR_DROP",
      TRUE                                           ~ "OTHER_DROP"
    )
  )
```

**Source of `testtype`:**
- anztox 2000: `testtype_id` FK → `lu_testtype` lookup table in the `infogathering`
  PostgreSQL database. The curator selects the test type at data entry.
- anztox 2016: hardcoded `if_else(ischronic %in% TRUE, "Chronic", "Acute")` using the
  `ischronic` boolean column on `toxicityvalue2016` (line 595).

**Mapping outcome:** "Chronic QSAR" rows and unclassified "OTHER" rows are dropped before
writing `anztox_extracted.csv`. Only "chronic", "subchronic", and "acute" survive.

**Nature:** Curator-assigned classification from the database. Not duration-computed.

### 1b. wqbench

**Code location:** `stage4b-extract.R`, lines 856–862 (Section 4g).

```r
# stage4b-extract.R lines 856-862
test_class = case_when(
  duration_class == "chronic" ~ "chronic",
  duration_class == "acute"   ~ "acute",
  TRUE                        ~ duration_class
)
```

**Source of `duration_class`:** The `ecotox_ascii_12_11_2025.rds` file produced by
`wqb_create_data_set()` (wqbench package). The `duration_class` column has exactly 2
distinct values — "acute" and "chronic" — 100% populated across all 361,782 rows.
wqbench derives this internally via `wqb_classify_duration()`, which implements a
duration-threshold rule applied to ECOTOX exposure durations combined with
`trophic_group`. However, that rule operates inside the wqbench package (not
reproduced here); the pipeline receives it as a pre-computed label.

**Nature:** wqbench's own threshold-based classification (source-internal). Not
independently validated against Warne Table 1 in this pipeline.

### 1c. envirotox

**Code location:** `stage4b-extract.R`, lines 1073–1080 (Section 5h).

```r
# stage4b-extract.R lines 1073-1080
envirotox_selected <- envirotox_selected |>
  mutate(
    test_class = case_when(
      Test.type == "A" ~ "acute",
      Test.type == "C" ~ "chronic"
    )
  )
```

**Source of `Test.type`:** Native `Test type` column in `envirotox.xlsx`, sheet `test`
(2 values: "A" = acute, "C" = chronic, 100% populated). This is EnviroTox-DB's own
classification.

**Critical constraint:** The upstream filter (lines 970–977) restricts envirotox to
**only 4 statistic × test-type combinations before** `test_class` is assigned:

```r
filter(
  (Test.statistic == "EC50" & Test.type == "A") |
  (Test.statistic == "LC50" & Test.type == "A") |
  (Test.statistic == "NOEC" & Test.type == "C") |
  (Test.statistic == "NOEL" & Test.type == "C")
)
```

Consequence: envirotox contributes **only** acute EC50/LC50 and chronic NOEC/NOEL to
the pipeline. No envirotox subchronic exists. Confirmed from enriched CSV: 4 distinct
(test_class × statistic_type) combinations for envirotox only.

---

## 2. Comparison to Warne et al. 2025 Table 1

**Warne Table 1** classifies acute vs chronic by: organism type × life stage ×
endpoint × exposure duration. Key thresholds (summary; see Warne et al. 2025 §3.2.1):

| Organism group | Acute (duration) | Chronic (duration) |
|---|---|---|
| Fish, amphibians | < 21 d (unless early life stage) | ≥ 28 d |
| Crustaceans/insects/invertebrates | < 14 d | ≥ 21 d |
| Algae, aquatic plants | ≤ 24 h (or ≤ 96 h by some definitions) | ≥ 10 d |
| Bacteria/microorganisms | ≤ 24 h | ≥ 10 d |

**This pipeline implements none of this.** All three sources use their own labels:

- **anztox:** curator-assigned at data entry (no duration rule visible in the pipeline).
- **wqbench:** threshold rule inside wqbench package (not verified against Warne here;
  the pipeline receives a pre-computed label).
- **envirotox:** EnviroTox-DB's own `Test type` field.

**Evidence of classification drift:** The `duration_hours` field shows substantial
overlap between source-labelled "acute" and "chronic" within wqbench and anztox:

| source | test_class | n (clean) | median dur (h) | min dur (h) | max dur (h) |
|---|---|---|---|---|---|
| wqbench | acute | 175,396 | 72 | 0 | 500 |
| wqbench | chronic | 137,408 | 504 | 24.5 | 26,280 |
| anztox | acute | 4,583 | 72 | 0.25 | 1,152 |
| anztox | chronic | 3,105 | 240 | 48 | 43,800 |
| envirotox | acute | 50,754 | 96 | 24 | 2,304 |
| envirotox | chronic | 10,083 | 360 | 24 | 26,400 |

Notable: wqbench "chronic" minimum = 24.5 h; wqbench "acute" maximum = 500 h. These
durations would likely be reclassified under a strict Warne Table 1 rule, depending on
organism type. The existing `test_class` is not a Warne-consistent label.

---

## 3. Distribution of `test_class` in `uncurated_raw_dedup_enriched.csv`

All counts below are from the **clean subset** (dedup_retained == TRUE &
priority_kept == TRUE; 381,333 rows). NA test_class: 0 in all sources.

### 3a. By source

| source | chronic | subchronic | acute | total |
|---|---|---|---|---|
| anztox | 3,105 | 4 | 4,583 | 7,692 |
| wqbench | 137,408 | 0 | 175,396 | 312,804 |
| envirotox | 10,083 | 0 | 50,754 | 60,837 |
| **Total** | **150,596** | **4** | **230,733** | **381,333** |

### 3b. By source × medium

| source | medium | chronic | subchronic | acute |
|---|---|---|---|---|
| anztox | Freshwater | 2,153 | 4 | 3,564 |
| anztox | Marine | 952 | 0 | 1,019 |
| envirotox | Unknown | 10,083 | 0 | 50,754 |
| wqbench | Freshwater | 105,098 | 0 | 133,681 |
| wqbench | Marine | 21,977 | 0 | 32,198 |
| wqbench | Unknown | 10,333 | 0 | 9,517 |

### 3c. Among acute rows: acr_eligible split

Total acute (clean): **230,733 rows**

| source | acr_eligible FALSE | acr_eligible TRUE |
|---|---|---|
| anztox | 276 | 4,307 |
| envirotox | 0 | 50,754 |
| wqbench | 69,861 | 105,535 |
| **Total** | **70,137** | **160,596** |

- **160,596 acute acr_eligible rows** enter DATASET.R Step 3 (ACR ÷10) and become
  tier-3 (`acute_acr`) candidates in `allchronic_data`.
- **70,137 acute non-eligible rows** are dropped at DATASET.R Step 2b (filter:
  `!(test_class == "acute" & (is.na(acr_eligible) | acr_eligible != TRUE))`).

---

## 4. Subchronic: meaning and fate

Subchronic exists in **anztox only** (4 rows in the clean subset; all Freshwater).

| source | statistic_type | stat_action | acr_eligible | n |
|---|---|---|---|---|
| anztox | NOEC | accepted | FALSE | 3 |
| anztox | EC50 | convert | TRUE | 1 |

**Code governing subchronic in DATASET.R:**

```r
# Step 3a: chronic/subchronic conversion (DATASET.R ~line 390)
chronic_conv_applied = test_class %in% c("chronic", "subchronic") & stat_action == "convert"

# Step 3c: tier ranking (DATASET.R ~line 519)
record_tier_rank = case_when(
  stat_action == "accepted" & test_class %in% c("chronic", "subchronic") ~ 1L,
  chronic_conv_applied == TRUE                                            ~ 2L,
  test_class == "acute"                                                   ~ 3L,
  TRUE                                                                    ~ NA_integer_
)
```

Subchronic rows are treated identically to chronic:
- Subchronic + accepted statistic (NOEC) → tier 1 (same as chronic accepted).
- Subchronic + convert statistic (EC50) → Warne §3.4.2.1 chronic conversion applied
  (÷5) → tier 2.
- The Step 2b filter does NOT drop subchronic rows (it only drops
  `test_class == "acute" & !acr_eligible`).

With only 4 rows in the clean subset, subchronic has negligible practical impact on
the current pipeline.

---

## 5. Acute statistic landscape

Among **230,733 acute rows** (clean subset):

### 5a. By stat_action and source

| source | accepted | convert | exclude | total |
|---|---|---|---|---|
| anztox | 228 | 4,329 | 26 | 4,583 |
| wqbench | 39,529 | 134,970 | 897 | 175,396 |
| envirotox | 0 | 50,754 | 0 | 50,754 |
| **Total** | **39,757** | **190,053** | **923** | **230,733** |

- **accepted (39,757):** Acute NOEC, NOEL, ECx≤20. These have `acr_eligible == FALSE`
  → dropped at DATASET.R Step 2b (cannot be ACR-converted). These are genuine acute
  negligible-effect data that are **completely absent from `allchronic_data`**.
- **convert (190,053):** Acute EC50/LC50/IC50 (acr_eligible TRUE; 160,596 rows → ACR
  ÷10, tier 3 in chronic pipeline) plus acute LOEC/LOEL/MATC (acr_eligible FALSE;
  dropped at Step 2b — ACR applies only to median-effect LC50/EC50/IC50 per
  Warne §3.4.2.2).
- **exclude (923):** Undefined ECx percentiles or unrecognised types → dropped at
  Step 2d.

### 5b. Key statistic types among acute rows (top values by source)

**anztox:** LC50 (3,329), EC50 (965), NOEC (146), NOEL (48), LOEC (22), EC10 (14),
IC50 (13), LC10 (9), LD50 (9 — excluded), EC25 (6 — excluded)

**wqbench:** LC50 (84,434), NOEC (28,790), LOEC (26,379), EC50 (19,591), NOEL (5,699),
LOEL (2,528), LC10 (1,623), IC50 (1,510), EC10 (1,372), EC20 (572), MATC (528),
LC05 (380), EC25 (293 — excluded), and many more ECx variants

**envirotox:** LC50 (44,780) + EC50 (17,194) only (all others pre-filtered out upstream)

### 5c. Acute negligible-effect data pool (currently excluded from chronic pipeline)

The "accepted" acute rows represent data that:
- Is labelled as acute by the source
- Has a negligible-effect statistic (NOEC, NOEL, ECx≤20)
- Cannot be used in `allchronic_data` (not acr_eligible → dropped at Step 2b)
- Could be directly usable as-is in an `all_short` pipeline

Major contributors: wqbench NOEC (28,790), wqbench NOEL (5,699), wqbench LC10 (1,623),
wqbench EC10 (1,372), wqbench EC20 (572), wqbench LC05 (380), anztox NOEC (146).

### 5d. Effect-category mix among acute rows (top by source)

**anztox acute:** MORT (3,527), IMM (651), GRO (260), POP (43), HAT (32)  
**wqbench acute:** (distributed across all traditional + non-traditional categories — not
tabulated separately here but mirrors the full common schema vocabulary)  
**envirotox acute:** All EC50/LC50; effect_category mapped via
`envirotox_effect_category_rules` — dominated by MORT

---

## 6. Duration field: name, units, completeness

**Field name:** `duration_hours` (numeric, floating-point)  
**Units:** Hours — normalised to hours for all sources prior to writing
`uncurated_raw_combined.csv`.

**Derivation by source:**
- anztox: `convert_duration_to_hours(duration_value_raw, durationunit_name)` helper
  in `stage4b-extract.R` (lines 148–160). Converts Minutes (÷60), Days (×24), Weeks
  (×168), Months (×730), Years (×8760). Unrecognised units → NA.
- wqbench: `as.numeric(duration_hrs)` from the RDS (already in hours, 100% populated).
- envirotox: `suppressWarnings(as.numeric(Duration.(hours)))` — literal text "NA"
  strings coerced to NA; otherwise numeric hours.

**NA rate (clean subset):**

| source | n_total | n_na_duration | pct_na |
|---|---|---|---|
| anztox | 7,692 | 123 | 1.6% |
| wqbench | 312,804 | 0 | 0.0% |
| envirotox | 60,837 | 76 | 0.1% |

The field is well-populated (>98.4% complete in all sources). anztox NAs arise from
unrecognised duration unit strings or non-numeric duration values (e.g. free-text
ranges like "7-14" under a "Days" unit, documented in
`report_duration_na_causes()`).

---

## 7. Implications for `all_short`

### Can the existing `test_class` be reused as-is for acute selection?

**Short answer:** Yes as a first approximation, but with known limitations. A dedicated
Warne Table 1 classifier would be more rigorous.

**Reuse case:**
- `test_class == "acute"` cleanly selects 230,733 rows from the clean subset.
- The field is fully populated (0 NAs in all sources).
- No further lookup or computation needed.
- wqbench's `duration_class` is itself derived from a threshold rule on duration ×
  trophic group (inside the wqbench package); it is not arbitrary.

**Limitations:**
- Not Warne Table 1-compliant: organism type, life stage, and endpoint-specific
  thresholds are not applied. A wqbench "chronic" row at 24.5 h exposure would likely
  be classified as acute under Warne Table 1 for most organism types.
- The pool of source-labelled "acute" data includes a mix of negligible-effect (NOEC,
  ECx≤20), median-effect (LC50, EC50), and low-effect (LOEC) statistics — each
  appropriate for different treatment in an acute SSD.
- envirotox acute is restricted to only LC50 and EC50 (pre-filtered upstream); other
  acute statistic types from envirotox are unavailable.

### What a dedicated Table 1 classifier would need

If a Warne Table 1-accurate classifier is required for `all_short`:
- **Duration:** `duration_hours` is available and well-populated — the primary input.
- **Organism group:** Available via the resolved `class` / `kingdom` / `phylum` columns
  in the enriched file; mapping from taxonomy to Warne Table 1 groups would need to be
  built (fish = Actinopterygii etc.; crustacean/insect/invertebrate; algae/plant;
  bacteria/microorganism).
- **Life stage:** Partially available (`life_stage` in the enriched file from anztox
  2016 and wqbench; absent for anztox 2000 and envirotox).
- **Endpoint type:** Not needed at the classifier stage — endpoints are part of the
  statistic-type vocabulary already classified.

A dedicated classifier would reclassify records currently labelled "chronic" by source
but below the Warne duration threshold (e.g. some wqbench "chronic" rows with
duration_hours < 336 h for fish). It would also reclassify some source-labelled "acute"
rows with atypically long durations.

### Data volume available for `all_short`

Using the existing `test_class == "acute"` label, the pre-aggregation acute pool is
230,733 rows. Of these:

| category | n | usable in all_short? |
|---|---|---|
| Acute accepted (NOEC/NOEL/ECx≤20), acr_eligible FALSE | ~39,757 | Yes — direct (no conversion needed) |
| Acute convert (LC50/EC50/IC50), acr_eligible TRUE | ~160,596 | Yes — these are the primary acute median-effect values |
| Acute convert (LOEC/LOEL/MATC), acr_eligible FALSE | ~29,700 | Potentially — via acute-specific conversion (not ACR) |
| Acute excluded (NOAEL, undefined ECx) | ~923 | No — no defined Warne treatment |

Additionally, the existing `all_short` seed in `short_term_curated_sets.csv` (chlorine ×
Marine, from Batley & Simpson 2020) provides the curated anchor for the short-term
pipeline.

### Files to commit

- `data-raw/alldata/diagnostic-exposure-classification.md` (this file — new, tracked)
- `prompts/alldata/diagnostic-exposure-classification.md` (new prompt log entry)
