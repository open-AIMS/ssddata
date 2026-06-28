# Stage 4e — Aggregation Audit Report

Generated: 2026-06-28 14:54:35.315305
Input file: data-raw/alldata/uncurated_raw_dedup_enriched.csv
Output file: data-raw/alldata/uncurated_raw_aggregated.csv

---

## 1. Input summary

- Rows loaded from enriched file: 449860
- Rows after `dedup_retained & priority_kept` filter: 381333
- 'Not stated' coerced to NA — majorgroup: 4 rows; class: 4 rows

## 2. Unit conversion

- wqbench rows converted from mg/L to µg/L: 312804
- All rows now have `conc_unit == 'ug/L'` (assertion passed)

## 3. Rows dropped before aggregation

### 3a. NA effect_category

- Total dropped: 23452 (6.2% of clean subset)

**By source:**

- anztox:   115
- envirotox:  4672
- wqbench: 18665

### 3b. Acute-non-eligible (acute NOECs/LOECs — cannot be ACR-converted)

- Total dropped: 66187 (17.4% of clean subset)

**By statistic_type:**

- NOEC: 27802
- LOEC: 25393
- NOEL:  4577
- LOEL:  2396
- LC10:  1628
- EC10:  1101
- EC20:   550
- MATC:   477
- LC05:   380
- EC25:   287
- LC20:   252
- LC16:   163
- IC25:   151
- LC15:   144
- IC10:   142
- LC30:   133
- EC15:   125
- LC25:   109
- IC20:    88
- LC40:    86
- EC05:    63
- MCIG:    33
- IC05:    21
- EC16:    15
- EC40:    11
- LD50:     9
- IC15:     6
- IC40:     6
- LC07:     4
- LC34:     4
- BEC10:     3
- LT50:     3
- MDEC:     3
- NO:     2
- NOAEL:     2
- EC18:     1
- EC22:     1
- EC30:     1
- EC35:     1
- EC41:     1
- EC45:     1
- EC55:     1
- EC58:     1
- LC06:     1
- LC08:     1
- LC09:     1
- LC13:     1
- LC32:     1
- LC33:     1
- LC35:     1
- LC38:     1
- LC45:     1
- LC55:     1

### 3c. Genus-rank species exclusion (uncurated only)

Genus-rank `accepted_name` entries excluded before aggregation. See `data-raw/alldata/stage4e-genus-rank-decisions.md` for floored-binomial triage rationale.

- Total rows excluded: 9643
- Distinct genus-rank names excluded: 723

**By source:**

- anztox:  363
- envirotox: 1233
- wqbench: 8047

### 3d. Statistic-type exclusion (no defined Warne 2025 treatment)

Records with undefined ECx percentiles (20 < x < 50 or x > 50), regulatory summary endpoints (NOAEL, LOAEL, NOAEC, LOAEC), and unrecognised types are excluded. Full listing in `data-raw/alldata/stage4e-statistic-type-excluded.csv`.

- Total rows excluded: 1278

**By statistic_type / tier / source:**

| statistic_type | stat_tier | source | n_excluded |
|---|---|---|---|
| IC25 | undefined_x_needs_ruling | wqbench | 629 |
| EC25 | undefined_x_needs_ruling | wqbench | 346 |
| LC25 | undefined_x_needs_ruling | wqbench | 177 |
| LC30 | undefined_x_needs_ruling | wqbench |  26 |
| LC40 | undefined_x_needs_ruling | wqbench |  26 |
| EC30 | undefined_x_needs_ruling | wqbench |  19 |
| EC40 | undefined_x_needs_ruling | wqbench |  13 |
| IC40 | undefined_x_needs_ruling | wqbench |  11 |
| IC25 | undefined_x_needs_ruling | anztox |   9 |
| NOAEL | UNCLASSIFIED | anztox |   6 |
| LOAEL | UNCLASSIFIED | anztox |   4 |
| LC31 | undefined_x_needs_ruling | wqbench |   3 |
| LOAEC | UNCLASSIFIED | anztox |   3 |
| NOAEC | UNCLASSIFIED | anztox |   3 |
| MCIG | UNCLASSIFIED | wqbench |   2 |
| EC25 | undefined_x_needs_ruling | anztox |   1 |

- Rows entering aggregation pipeline: 280773

### 3e. Non-traditional endpoint filter (Warne et al. 2025 §3.2.1)

Endpoints classified as non-traditional (PSE, BCH, BEH, LUM, MOR) are excluded. Traditional endpoints retained: MORT, IMM, GRO, DVP, POP, REP, HAT, ABD.

- Total rows excluded: 54709 (19.5% of rows entering this step)

**By effect_category and source:**

| effect_category | source | n_excluded |
|---|---|---|
| BCH | anztox |     2 |
| BCH | wqbench | 41372 |
| BEH | anztox |     3 |
| BEH | wqbench |  5349 |
| LUM | anztox |     1 |
| MOR | envirotox |     3 |
| MOR | wqbench |  3821 |
| PSE | anztox |    16 |
| PSE | envirotox |   150 |
| PSE | wqbench |  3992 |

**B2 impact — groups (casnumber × species × medium) losing ALL values:**
- Groups dropped entirely (had only non-traditional rows): 1628
  - Distinct species dropped: 428
  - Distinct chemicals with complete species loss: 759
- Groups losing SOME rows (retain at least one traditional row): 3986
- Post-filter validation: all surviving effect_category values are traditional (PASS).

### 3f. Concentration plausibility filter (applied after ACR + chronic conversion)

Thresholds: LOWER_HARD = 1e-05 µg/L, LOWER_SOFT = 0.001 µg/L, UPPER_SOFT = 1e+06 µg/L, UPPER_HARD = 1e+08 µg/L

Applied after ACR (Step 3) and chronic conversion (Step 3a) so all concentrations are on their final µg/L scale.

**Hard-excluded rows (dropped):** 54 (low_hard: 49; high_hard: 5)

By source / category:

- wqbench / high_hard:  5
- wqbench / low_hard: 49

Complete listing of hard-excluded rows:

| casnumber_grouped | accepted_name | source | statistic_type | conc_ug_L | conc_plausibility |
|---|---|---|---|---|---|
|    67630 | Pacifastacus leniusculus | wqbench | NOEC | 1.500e+08 | high_hard |
|   569642 | Penaeus (Litopenaeus) schmitti | wqbench | LC50 | 2.073e+08 | high_hard |
| 13464385 | Microcystis aeruginosa | wqbench | EC50 | 3.200e+08 | high_hard |
|  5796178 | Tetrahymena thermophila | wqbench | EC50 | 3.260e+08 | high_hard |
| 13464385 | Microcystis aeruginosa | wqbench | EC50 | 1.016e+09 | high_hard |
| 53826134 | Elodea canadensis | wqbench | EC10 | 1.600e-10 | low_hard |
|  1912249 | Elodea canadensis | wqbench | EC10 | 4.800e-10 | low_hard |
|  2921882 | Chydorus sphaericus | wqbench | NOEC | 1.000e-08 | low_hard |
|  2921882 | Simocephalus vetulus | wqbench | NOEC | 1.000e-08 | low_hard |
|  2921882 | Cephalodella gibba | wqbench | NOEC | 1.000e-08 | low_hard |
|    72208 | Asellus (Asellus) aquaticus aquaticus | wqbench | LC50 | 6.100e-08 | low_hard |
|    72208 | Asellus (Asellus) aquaticus aquaticus | wqbench | LC50 | 1.100e-07 | low_hard |
| 52315078 | Daphnia magna | wqbench | NOEC | 2.000e-07 | low_hard |
|    72208 | Asellus (Asellus) aquaticus aquaticus | wqbench | LC50 | 2.900e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | NOEC | 3.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | NOEC | 3.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | NOEC | 3.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | NOEC | 3.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | NOEC | 3.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | NOEC | 3.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | NOEC | 3.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | NOEC | 3.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 4.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 4.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 4.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 4.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 4.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 4.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 4.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 4.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 4.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 4.000e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 4.000e-07 | low_hard |
| 52315078 | Daphnia magna | wqbench | LOEC | 8.000e-07 | low_hard |
|    72208 | Daphnia pulex | wqbench | LC50 | 8.800e-07 | low_hard |
|   122145 | Daphnia magna | wqbench | MATC | 9.000e-07 | low_hard |
| 70288867 | Ceriodaphnia dubia | wqbench | NOEC | 1.000e-06 | low_hard |
| 70288867 | Daphnia magna | wqbench | NOEC | 1.000e-06 | low_hard |
| 70288867 | Ceriodaphnia dubia | wqbench | NOEC | 1.000e-06 | low_hard |
| 70288867 | Ceriodaphnia dubia | wqbench | NOEC | 1.000e-06 | low_hard |
| 51630581 | Culex quinquefasciatus | wqbench | LC50 | 1.200e-06 | low_hard |
|    72208 | Cloeon dipterum | wqbench | LC50 | 1.300e-06 | low_hard |
|    72208 | Daphnia pulex | wqbench | LC50 | 2.200e-06 | low_hard |
|  7775113 | Palaemon varians | wqbench | LOEC | 2.400e-06 | low_hard |
| 52918635 | Chironomus riparius | wqbench | LOEC | 2.400e-06 | low_hard |
|  7775113 | Palaemon varians | wqbench | NOEC | 3.000e-06 | low_hard |
| 52918635 | Chironomus riparius | wqbench | LC50 | 3.200e-06 | low_hard |
| 70288867 | Ceriodaphnia dubia | wqbench | LOEC | 4.000e-06 | low_hard |
| 70288867 | Ceriodaphnia dubia | wqbench | LOEC | 4.000e-06 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 4.000e-06 | low_hard |
| 70288867 | Ceriodaphnia dubia | wqbench | LOEC | 4.000e-06 | low_hard |
|    96231 | Xenopus laevis | wqbench | LC50 | 4.500e-06 | low_hard |
|    72208 | Daphnia pulex | wqbench | LC50 | 5.700e-06 | low_hard |
|    72208 | Megacyclops viridis viridis | wqbench | LC50 | 7.100e-06 | low_hard |

**Soft-flagged rows retained:** 2340 (low_soft: 509; high_soft: 1831)

By source / category:

- anztox / high_soft:   19
- anztox / low_soft:    3
- envirotox / high_soft:  422
- envirotox / low_soft:   76
- wqbench / high_soft: 1390
- wqbench / low_soft:  430

**Soft-only fallback groups (Step 1):** 930
- Rows entering geomean step after plausibility filter: 226010

## 4. ACR conversion (Step 3)

- Total rows ACR-converted (÷10): 137836

**By source:**

- anztox:  3976
- envirotox: 45142
- wqbench: 88718

## 4a. Chronic/subchronic conversion (Step 3a)

Warne et al. 2025 Section 3.4.2.1 factors applied to chronic/subchronic records in the 'convert' tier: EC50/IC50/LC50 ÷ 5; LOEC/LOEL ÷ 2.5; MATC ÷ 2.
Acute EC50/IC50/LC50 are handled by ACR (Step 3) only.

- Total rows chronic/subchronic-converted: 41460

**By statistic_type / factor / source:**

| statistic_type | conv_factor | source | n_converted |
|---|---|---|---|
| LOEC | 2.5 | wqbench | 17809 |
| EC50 | 5.0 | wqbench | 11403 |
| LC50 | 5.0 | wqbench |  6696 |
| MATC | 2.0 | wqbench |  2154 |
| LOEL | 2.5 | wqbench |  1446 |
| IC50 | 5.0 | wqbench |  1186 |
| EC50 | 5.0 | anztox |   455 |
| LOEC | 2.5 | anztox |   197 |
| LC50 | 5.0 | anztox |    84 |
| IC50 | 5.0 | anztox |    20 |
| MATC | 2.0 | anztox |     8 |
| LOEL | 2.5 | anztox |     2 |

## 4b. Three-tier preference filter (Step 3c)

Per species × chemical × medium, records are ranked:
  1. `accepted` — NOEC/NOEL/ECx≤20/preferred negligible, chronic/subchronic
  2. `chronic_converted` — EC50/LOEC/MATC after ÷ factor, chronic/subchronic
  3. `acute_acr` — acute EC50/IC50/LC50 after ACR ÷ 10
Only the lowest rank present in each group is retained.

**Decision note:** preference applied per species × chemical × medium (not per chemical). This is a deliberate operationalisation: in a one-value-per-species dataset, the fallback must be resolved at the species level so that chronic data for one species does not suppress acute data for a different species within the same chemical.

- Records dropped by tier preference filter: 44901
- Records remaining after filter: 181109

**Tier displacement diagnostic:** 2130 groups had both tier-1/2 and tier-3 records (expected ~0 given `priority_kept` upstream).
  See `data-raw/alldata/stage4e-tier-displacement-groups.csv`.

**Record distribution by value_tier before aggregation:**

| value_tier | n_records |
|---|---|
| accepted |  46748 |
| acute_acr | 125700 |
| chronic_converted |   8661 |

## 5. Geometric mean step (Step 1 of Section 3.4.4)

- Total groups formed: 97373
- Singleton groups (n = 1): 67390 (69.2%)
- Multi-record groups: 29983 (30.8%)
- Groups flagged (max/min > 10): 4229 (4.34%)

### Top 10 flagged groups by spread (max/min ratio)

| casnumber_grouped | accepted_name | effect_category | statistic_type | duration_hours | life_stage | n | conc_min | conc_max | ratio |
|---|---|---|---|---|---|---|---|---|---|
|   114261 | Culex quinquefasciatus | MORT | LC50 | 24 | Larva | 112 | 0.0034 | 18050 | 5308823.5 |
|   121755 | Heteropneustes fossilis | MORT | LC50 | 96 | NA |  13 | 0.0012 | 4500 | 3854059.6 |
| 80844071 | Culex quinquefasciatus | MORT | LC50 | 24 | Larva |   4 | 0.018 | 7080 | 393333.3 |
| 14797650 | Ictalurus punctatus | MORT | LC50 | 96 | Fingerling |   4 | 0.016 | 4300 | 268750 |
|    58366 | Lepomis macrochirus | MORT | LC50 | 96 | NA |   5 | 0.8 | 180000 | 225000 |
| 66230044 | Danio rerio | MORT | LC50 | 96 | Embryo |   3 | 0.002 | 350 | 175000 |
|    58366 | Oncorhynchus mykiss | MORT | LC50 | 96 | NA |   4 | 0.35 | 56000 | 160000 |
|    57125 | Daphnia pulex | MORT | LC50 | 48 | NA |  17 | 0.1 | 15911 | 159110 |
|    57125 | Daphnia pulex | MORT | LC50 | 48 | NA |   7 | 0.1 | 15911 | 159110 |
| 30560191 | Culex quinquefasciatus | MORT | LC50 | 24 | Larva |   2 | 0.001 | 158.5 | 158500 |

## 6. Groups with NA life_stage or NA duration

- Step 1 groups with NA life_stage: 64965
- Step 1 groups with NA duration_hours: 66
- `lifestage_mixed = TRUE` flags at Step 2: 2991
- `duration_mixed = TRUE` flags at Step 2: 17

## 7. Output summary

- Total rows in `uncurated_raw_aggregated.csv`: 57553
- Distinct chemicals (`casnumber_grouped`): 5585
- Distinct species (`accepted_name`): 2936

**Rows by medium:**

- Freshwater: 28627
- Marine:  7486
- Unknown: 21440

**Output rows by value_tier:**

| value_tier | n_rows |
|---|---|
| accepted | 12730 |
| acute_acr | 40677 |
| chronic_converted |  4146 |

**C1/C2 — effect_category of selected endpoint (Warne §3.2.1 traditional only):**
Tie-break rule: alphabetical order of effect_category when multiple endpoints share the same minimum concentration within a casnumber × species × medium group.
- Groups with tied minimum (C2): 1802

| effect_category | n_rows |
|---|---|
| MORT | 40399 |
| POP |  8598 |
| GRO |  4551 |
| REP |  1839 |
| DVP |  1360 |
| IMM |   762 |
| ABD |    34 |
| HAT |    10 |

**Source combination breakdown:**

- `wqbench`: 35235
- `envirotox`: 19883
- `anztox,wqbench`:  1121
- `anztox`:  1069
- `envirotox,wqbench`:   245

- Rows with `any_acr_applied == TRUE`: 40677 (70.7%)
- Rows with `any_chronic_conv_applied == TRUE`: 4146 (7.2%)
- Rows with `any_conc_flagged == TRUE`: 644 (1.12%)
- Rows with `geomean_flagged == TRUE`: 3191 (5.54%)

**Top 10 majorgroups by row count:**

- Teleostei: 21993
- Malacostraca:  5677
- Branchiopoda:  5406
- Chlorophyceae:  4183
- Insecta:  4049
- Gastropoda:  1950
- Amphibia:  1823
- Bivalvia:  1756
- Bacillariophyceae:  1572
- Cyanophyceae:  1254

## 8. File sizes

- `uncurated_raw_aggregated.csv`: 14.5 MB
- `stage4e-statistic-type-excluded.csv`: 0.1 MB
- `allchronic_data_source.csv`: 137.3 MB (untracked)

## 9. Source export — allchronic_data_source.csv

File: `data-raw/alldata/allchronic_data_source.csv` (untracked — large intermediate)

**Scope:** uncurated sources only (anztox, wqbench, envirotox). Curated sources (anzg, ccme, aims, csiro) are handled separately via their source `.rda` objects and do not appear here. This file therefore does NOT represent the full source of the `allchronic_data` object.

**Capture point:** after all per-record filters (Steps 2a–2e) and conversions (ACR ÷10, chronic ÷factor, Step 3b hard-exclude), before the three-tier preference filter. Non-traditional endpoints (PSE/BCH/BEH/LUM/MOR) are excluded, matching the SSD scope of the published values. Fully unfiltered records are in `uncurated_raw_dedup_enriched.csv`.

Concentrations are on their final µg/L scale (`conc_ug_L` has ACR ÷10 and chronic ÷5/÷2.5/÷2 factors applied). `acr_applied`, `chronic_conv_applied`, and `chronic_conv_factor` are retained so the raw value is recoverable.

- Total rows (post-plausibility base frame): 226010
- `in_geomean_input == TRUE` (survived three-tier preference filter): 181109
- `is_provenance == TRUE` (in winning Step-1 group per species × chemical × medium): 108634
- `sum(output$n_records)` for comparison: 180583
n_is_provenance (108634) differs from sum(n_records) (180583) — n_records counts geomean inputs; is_provenance marks contributing inputs to winning groups only.

