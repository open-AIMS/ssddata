# Stage 4e — Aggregation Audit Report

Generated: 2026-06-27 17:07:54.031977
Input file: data-raw/alldata/uncurated_raw_dedup_enriched.csv
Output file: data-raw/alldata/uncurated_raw_aggregated.csv

---

## 1. Input summary

- Rows loaded from enriched file: 449860
- Rows after `dedup_retained & priority_kept` filter: 381382
- 'Not stated' coerced to NA — majorgroup: 4 rows; class: 4 rows

## 2. Unit conversion

- wqbench rows converted from mg/L to µg/L: 312827
- All rows now have `conc_unit == 'ug/L'` (assertion passed)

## 3. Rows dropped before aggregation

### 3a. NA effect_category

- Total dropped: 23567 (6.2% of clean subset)

**By source:**

- anztox:   281
- envirotox:  4622
- wqbench: 18664

### 3b. Acute-non-eligible (acute NOECs/LOECs — cannot be ACR-converted)

- Total dropped: 66183 (17.4% of clean subset)

**By statistic_type:**

- NOEC: 27793
- LOEC: 25398
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

- Total rows excluded: 9638
- Distinct genus-rank names excluded: 721

**By source:**

- anztox:  356
- envirotox: 1235
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

- Rows entering aggregation pipeline: 280716

### 3e. Concentration plausibility filter

Thresholds: LOWER_HARD = 1e-05 µg/L, LOWER_SOFT = 0.001 µg/L, UPPER_SOFT = 1e+06 µg/L, UPPER_HARD = 1e+08 µg/L

Applied after ACR (Step 3) and chronic conversion (Step 3a) so all concentrations are on their final µg/L scale.

**Hard-excluded rows (dropped):** 59 (low_hard: 54; high_hard: 5)

By source / category:

- wqbench / high_hard:  5
- wqbench / low_hard: 54

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
|   121755 | Anodonta cygnea | wqbench | EC50 | 7.500e-06 | low_hard |
|   298000 | Daphnia magna | wqbench | EC50 | 7.500e-06 | low_hard |
|    91203 | Callinectes sapidus | wqbench | EC50 | 8.500e-06 | low_hard |
|   298000 | Daphnia magna | wqbench | EC50 | 8.900e-06 | low_hard |
|   427510 | Lithobates catesbeianus | wqbench | LOEC | 1.000e-05 | low_hard |

**Soft-flagged rows retained:** 2749 (low_soft: 654; high_soft: 2095)

By source / category:

- anztox / high_soft:   18
- anztox / low_soft:    3
- envirotox / high_soft:  422
- envirotox / low_soft:   76
- wqbench / high_soft: 1655
- wqbench / low_soft:  575

**Soft-only fallback groups (Step 1):** 1018
- Rows entering geomean step after plausibility filter: 280657

## 4. ACR conversion (Step 3)

- Total rows ACR-converted (÷10): 142475

**By source:**

- anztox:  3958
- envirotox: 45297
- wqbench: 93220

## 4a. Chronic/subchronic conversion (Step 3a)

Warne et al. 2025 Section 3.4.2.1 factors applied to chronic/subchronic records in the 'convert' tier: EC50/IC50/LC50 ÷ 5; LOEC/LOEL ÷ 2.5; MATC ÷ 2.
Acute EC50/IC50/LC50 are handled by ACR (Step 3) only.

- Total rows chronic/subchronic-converted: 66566

**By statistic_type / factor / source:**

| statistic_type | conv_factor | source | n_converted |
|---|---|---|---|
| LOEC | 2.5 | wqbench | 40300 |
| EC50 | 5.0 | wqbench | 12751 |
| LC50 | 5.0 | wqbench |  6696 |
| LOEL | 2.5 | wqbench |  2468 |
| MATC | 2.0 | wqbench |  2213 |
| IC50 | 5.0 | wqbench |  1388 |
| EC50 | 5.0 | anztox |   449 |
| LOEC | 2.5 | anztox |   188 |
| LC50 | 5.0 | anztox |    84 |
| IC50 | 5.0 | anztox |    19 |
| MATC | 2.0 | anztox |     8 |
| LOEL | 2.5 | anztox |     2 |

## 4b. Three-tier preference filter (Step 3c)

Per species × chemical × medium, records are ranked:
  1. `accepted` — NOEC/NOEL/ECx≤20/preferred negligible, chronic/subchronic
  2. `chronic_converted` — EC50/LOEC/MATC after ÷ factor, chronic/subchronic
  3. `acute_acr` — acute EC50/IC50/LC50 after ACR ÷ 10
Only the lowest rank present in each group is retained.

**Decision note:** preference applied per species × chemical × medium (not per chemical). This is a deliberate operationalisation: in a one-value-per-species dataset, the fallback must be resolved at the species level so that chronic data for one species does not suppress acute data for a different species within the same chemical.

- Records dropped by tier preference filter: 71695
- Records remaining after filter: 208962

**Tier displacement diagnostic:** 2823 groups had both tier-1/2 and tier-3 records (expected ~0 given `priority_kept` upstream).
  See `data-raw/alldata/stage4e-tier-displacement-groups.csv`.

**Record distribution by value_tier before aggregation:**

| value_tier | n_records |
|---|---|
| accepted |  71655 |
| acute_acr | 127088 |
| chronic_converted |  10219 |

## 5. Geometric mean step (Step 1 of Section 3.4.4)

- Total groups formed: 104015
- Singleton groups (n = 1): 70827 (68.1%)
- Multi-record groups: 33188 (31.9%)
- Groups flagged (max/min > 10): 4693 (4.51%)

### Top 10 flagged groups by spread (max/min ratio)

| casnumber_grouped | accepted_name | effect_category | statistic_type | duration_hours | life_stage | n | conc_min | conc_max | ratio |
|---|---|---|---|---|---|---|---|---|---|
|   114261 | Culex quinquefasciatus | MORT | LC50 |  24 | Larva | 112 | 0.0034 | 18050 | 5308823.5 |
| 80844071 | Culex quinquefasciatus | MORT | LC50 |  24 | Larva |   4 | 0.018 | 7080 | 393333.3 |
|    58366 | Lepomis macrochirus | MORT | LC50 |  96 | NA |   5 | 0.8 | 180000 | 225000 |
| 66230044 | Danio rerio | MORT | LC50 |  96 | Embryo |   3 | 0.002 | 350 | 175000 |
|    58366 | Oncorhynchus mykiss | MORT | LC50 |  96 | NA |   4 | 0.35 | 56000 | 160000 |
|    57125 | Daphnia pulex | MORT | LC50 |  48 | NA |  17 | 0.1 | 15911 | 159110 |
|    57125 | Daphnia pulex | MORT | LC50 |  48 | NA |   7 | 0.1 | 15911 | 159110 |
| 30560191 | Culex quinquefasciatus | MORT | LC50 |  24 | Larva |   2 | 0.001 | 158.5 | 158500 |
| 52918635 | Culex pipiens pallens | MORT | LC50 |  24 | Larva |  29 | 0.019 | 2930 | 154210.5 |
| 25812300 | Daphnia magna | BCH | NOEC | 504 | Neonate |   3 | 0.05 | 7500 | 150000 |

## 6. Groups with NA life_stage or NA duration

- Step 1 groups with NA life_stage: 67804
- Step 1 groups with NA duration_hours: 67
- `lifestage_mixed = TRUE` flags at Step 2: 3084
- `duration_mixed = TRUE` flags at Step 2: 18

## 7. Output summary

- Total rows in `uncurated_raw_aggregated.csv`: 59177
- Distinct chemicals (`casnumber_grouped`): 5671
- Distinct species (`accepted_name`): 3041

**Rows by medium:**

- Freshwater: 29604
- Marine:  7935
- Unknown: 21638

**Output rows by value_tier:**

| value_tier | n_rows |
|---|---|
| accepted | 13717 |
| acute_acr | 41236 |
| chronic_converted |  4224 |

**Source combination breakdown:**

- `wqbench`: 36805
- `envirotox`: 19985
- `anztox,wqbench`:  1125
- `anztox`:  1007
- `envirotox,wqbench`:   255

- Rows with `any_acr_applied == TRUE`: 41236 (69.7%)
- Rows with `any_chronic_conv_applied == TRUE`: 4224 (7.1%)
- Rows with `any_conc_flagged == TRUE`: 691 (1.17%)
- Rows with `geomean_flagged == TRUE`: 3455 (5.84%)

**Top 10 majorgroups by row count:**

- Teleostei: 22296
- Malacostraca:  5808
- Branchiopoda:  5531
- Chlorophyceae:  4272
- Insecta:  4104
- Bivalvia:  2029
- Gastropoda:  1999
- Amphibia:  1886
- Bacillariophyceae:  1674
- Cyanophyceae:  1324

## 8. File sizes

- `uncurated_raw_aggregated.csv`: 14.6 MB
- `stage4e-statistic-type-excluded.csv`: 0.1 MB

