# Stage 4e — Aggregation Audit Report

Generated: 2026-06-25 17:30:09.998793
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

- Rows entering aggregation: 291632

## 4. ACR conversion

- Total rows ACR-converted (÷10): 146786

**By source:**

- anztox:  4265
- envirotox: 46163
- wqbench: 96358

## 5. Geometric mean step (Step 1 of Section 3.4.4)

- Total groups formed: 138174
- Singleton groups (n = 1): 92391 (66.9%)
- Multi-record groups: 45783 (33.1%)
- Groups flagged (max/min > 10): 6708 (4.85%)

### Top 10 flagged groups by spread (max/min ratio)

| casnumber_grouped | accepted_name | effect_category | statistic_type | duration_hours | life_stage | n | conc_min | conc_max | ratio |
|---|---|---|---|---|---|---|---|---|---|
|   121755 | Artemia sp. | MORT | LC50 |   24 | Nauplii | 3 | 0 | 1380400 | 1.896154e+14 |
|   333415 | Artemia sp. | MORT | LC50 |   24 | Nauplii | 3 | 0 | 66000 | 9.065934e+12 |
| 53826134 | Elodea canadensis | GRO | EC10 | 2352 | NA | 5 | 0 | 695 | 4.34375e+12 |
|  2921882 | Artemia sp. | MORT | LC50 |   24 | Nauplii | 7 | 0 | 25100 | 3.447802e+12 |
| 51630581 | Culex quinquefasciatus | MORT | LC50 |   24 | Larva | 8 | 0 | 6600 | 5.5e+09 |
|    72208 | Asellus (Asellus) aquaticus aquaticus | MORT | LC50 |   48 | Juvenile | 9 | 0 | 74.42 | 676545500 |
|    72208 | Asellus (Asellus) aquaticus aquaticus | MORT | LC50 |   24 | Juvenile | 9 | 0 | 185.33 | 639069000 |
|  2921882 | Simocephalus vetulus | POP | NOEC |  336 | NA | 2 | 0 | 0.9 | 9e+07 |
| 53826134 | Elodea canadensis | GRO | EC25 | 2352 | NA | 5 | 0 | 1737 | 56032260 |
|    72208 | Daphnia pulex | MORT | LC50 |   48 | NA | 3 | 0 | 36.8 | 16727270 |

## 6. Groups with NA life_stage or NA duration

- Step 1 groups with NA life_stage: 84756
- Step 1 groups with NA duration_hours: 67
- `lifestage_mixed = TRUE` flags at Step 2: 4186
- `duration_mixed = TRUE` flags at Step 2: 18

## 7. Output summary

- Total rows in `uncurated_raw_aggregated.csv`: 62416
- Distinct chemicals (`casnumber_grouped`): 5700
- Distinct species (`accepted_name`): 3763

**Rows by medium:**

- Freshwater: 31595
- Marine:  8355
- Unknown: 22466

**Source combination breakdown:**

- `wqbench`: 38808
- `envirotox`: 20617
- `anztox,wqbench`:  1662
- `anztox`:   886
- `envirotox,wqbench`:   443

- Rows with `any_acr_applied == TRUE`: 46030 (73.7%)
- Rows with `geomean_flagged == TRUE`: 4285 (6.87%)

**Top 10 majorgroups by row count:**

- Teleostei: 22527
- Malacostraca:  6066
- Branchiopoda:  5864
- Insecta:  4911
- Chlorophyceae:  4501
- Gastropoda:  2096
- Bivalvia:  2066
- Amphibia:  1914
- Bacillariophyceae:  1819
- Cyanophyceae:  1624

## 8. File sizes

- `uncurated_raw_aggregated.csv`: 14 MB

