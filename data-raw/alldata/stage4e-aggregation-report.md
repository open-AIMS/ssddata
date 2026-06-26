# Stage 4e — Aggregation Audit Report

Generated: 2026-06-26 09:23:17.755076
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

- Rows entering aggregation pipeline: 291632

### 3c. Concentration plausibility filter

Thresholds: LOWER_HARD = 1e-05 µg/L, LOWER_SOFT = 0.001 µg/L, UPPER_SOFT = 1e+06 µg/L, UPPER_HARD = 1e+08 µg/L

**Hard-excluded rows (dropped):** 57 (low_hard: 51; high_hard: 6)

By source / category:

- wqbench / high_hard:  6
- wqbench / low_hard: 51

Complete listing of hard-excluded rows:

| casnumber_grouped | accepted_name | source | statistic_type | conc_ug_L | conc_plausibility |
|---|---|---|---|---|---|
|    67630 | Pacifastacus leniusculus | wqbench | NOEC | 1.500e+08 | high_hard |
|   569642 | Penaeus (Litopenaeus) schmitti | wqbench | LC50 | 2.073e+08 | high_hard |
| 68602802 | Skeletonema costatum | wqbench | EC50 | 3.000e+08 | high_hard |
|  5796178 | Tetrahymena thermophila | wqbench | EC50 | 3.260e+08 | high_hard |
| 13464385 | Microcystis aeruginosa | wqbench | EC50 | 1.600e+09 | high_hard |
| 13464385 | Microcystis aeruginosa | wqbench | EC50 | 5.080e+09 | high_hard |
| 53826134 | Elodea canadensis | wqbench | EC10 | 1.600e-10 | low_hard |
|  1912249 | Elodea canadensis | wqbench | EC10 | 4.800e-10 | low_hard |
|   121755 | Artemia sp. | wqbench | LC50 | 7.280e-09 | low_hard |
|   333415 | Artemia sp. | wqbench | LC50 | 7.280e-09 | low_hard |
|  2921882 | Artemia sp. | wqbench | LC50 | 7.280e-09 | low_hard |
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
|    72208 | Daphnia pulex | wqbench | LC50 | 8.800e-07 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 1.000e-06 | low_hard |
| 70288867 | Ceriodaphnia dubia | wqbench | NOEC | 1.000e-06 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 1.000e-06 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 1.000e-06 | low_hard |
| 70288867 | Daphnia magna | wqbench | NOEC | 1.000e-06 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 1.000e-06 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 1.000e-06 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 1.000e-06 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 1.000e-06 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 1.000e-06 | low_hard |
| 70288867 | Ceriodaphnia dubia | wqbench | NOEC | 1.000e-06 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 1.000e-06 | low_hard |
| 70288867 | Ceriodaphnia dubia | wqbench | NOEC | 1.000e-06 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 1.000e-06 | low_hard |
| 70288867 | Daphnia magna | wqbench | LOEC | 1.000e-06 | low_hard |
| 51630581 | Culex quinquefasciatus | wqbench | LC50 | 1.200e-06 | low_hard |
|    72208 | Cloeon dipterum | wqbench | LC50 | 1.300e-06 | low_hard |
|   122145 | Daphnia magna | wqbench | MATC | 1.800e-06 | low_hard |
| 52315078 | Daphnia magna | wqbench | LOEC | 2.000e-06 | low_hard |
|    72208 | Daphnia pulex | wqbench | LC50 | 2.200e-06 | low_hard |
|  7775113 | Palaemon varians | wqbench | NOEC | 3.000e-06 | low_hard |
|    96231 | Xenopus laevis | wqbench | LC50 | 4.500e-06 | low_hard |
|    72208 | Daphnia pulex | wqbench | LC50 | 5.700e-06 | low_hard |
|  7775113 | Palaemon varians | wqbench | LOEC | 6.000e-06 | low_hard |
| 52918635 | Chironomus riparius | wqbench | LOEC | 6.000e-06 | low_hard |
|    72208 | Megacyclops viridis viridis | wqbench | LC50 | 7.100e-06 | low_hard |
|   121755 | Anodonta cygnea | wqbench | EC50 | 7.500e-06 | low_hard |
|   298000 | Daphnia magna | wqbench | EC50 | 7.500e-06 | low_hard |
|    91203 | Callinectes sapidus | wqbench | EC50 | 8.500e-06 | low_hard |
|   298000 | Daphnia magna | wqbench | EC50 | 8.900e-06 | low_hard |

**Soft-flagged rows retained:** 3398 (low_soft: 549; high_soft: 2849)

By source / category:

- anztox / high_soft:   19
- anztox / low_soft:    3
- envirotox / high_soft:  428
- envirotox / low_soft:   77
- wqbench / high_soft: 2402
- wqbench / low_soft:  469

**Soft-only fallback groups (Step 1):** 1568
- Rows entering geomean step after plausibility filter: 291575

## 4. ACR conversion

- Total rows ACR-converted (÷10): 146786

**By source:**

- anztox:  4265
- envirotox: 46163
- wqbench: 96358

## 5. Geometric mean step (Step 1 of Section 3.4.4)

- Total groups formed: 138142
- Singleton groups (n = 1): 92539 (67.0%)
- Multi-record groups: 45603 (33.0%)
- Groups flagged (max/min > 10): 6560 (4.75%)

### Top 10 flagged groups by spread (max/min ratio)

| casnumber_grouped | accepted_name | effect_category | statistic_type | duration_hours | life_stage | n | conc_min | conc_max | ratio |
|---|---|---|---|---|---|---|---|---|---|
|   114261 | Culex quinquefasciatus | MORT | LC50 |  24 | Larva | 112 | 0.0034 | 18050 | 5308823.5 |
|   121755 | Heteropneustes fossilis | MORT | LC50 |  96 | NA |  13 | 0.0012 | 4500 | 3854059.6 |
|   335671 | Microcystis aeruginosa | BCH | LOEC | 360 | NA |   5 | 0.1 | 1e+05 | 1e+06 |
|  4685147 | Scenedesmus quadricauda | POP | EC50 |  96 | NA |   4 | 0.0013 | 1300 | 1e+06 |
|  7677249 | Artemia sp. | MORT | LC50 |  24 | Nauplii |   3 | 0.133 | 86000 | 646616.5 |
| 80844071 | Culex quinquefasciatus | MORT | LC50 |  24 | Larva |   4 | 0.018 | 7080 | 393333.3 |
|  3383968 | Aedes aegypti | MORT | LC50 |  24 | Larva | 136 | 0.027 | 7505 | 277963 |
| 14797650 | Ictalurus punctatus | MORT | LC50 |  96 | Fingerling |   4 | 0.016 | 4300 | 268750 |
|    58366 | Lepomis macrochirus | MORT | LC50 |  96 | NA |   5 | 0.8 | 180000 | 225000 |
| 66230044 | Danio rerio | MORT | LC50 |  96 | Embryo |   3 | 0.002 | 350 | 175000 |

## 6. Groups with NA life_stage or NA duration

- Step 1 groups with NA life_stage: 84736
- Step 1 groups with NA duration_hours: 67
- `lifestage_mixed = TRUE` flags at Step 2: 4182
- `duration_mixed = TRUE` flags at Step 2: 18

## 7. Output summary

- Total rows in `uncurated_raw_aggregated.csv`: 62410
- Distinct chemicals (`casnumber_grouped`): 5700
- Distinct species (`accepted_name`): 3763

**Rows by medium:**

- Freshwater: 31589
- Marine:  8355
- Unknown: 22466

**Source combination breakdown:**

- `wqbench`: 38805
- `envirotox`: 20617
- `anztox,wqbench`:  1659
- `anztox`:   886
- `envirotox,wqbench`:   443

- Rows with `any_acr_applied == TRUE`: 46028 (73.8%)
- Rows with `any_conc_flagged == TRUE`: 899 (1.44%)
- Rows with `geomean_flagged == TRUE`: 4214 (6.75%)

**Top 10 majorgroups by row count:**

- Teleostei: 22527
- Malacostraca:  6064
- Branchiopoda:  5863
- Insecta:  4911
- Chlorophyceae:  4501
- Gastropoda:  2096
- Bivalvia:  2066
- Amphibia:  1913
- Bacillariophyceae:  1819
- Cyanophyceae:  1624

## 8. File sizes

- `uncurated_raw_aggregated.csv`: 14.4 MB

