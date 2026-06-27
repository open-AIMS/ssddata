# Stage 4e — Statistic Type Inventory

Generated: 2026-06-27 14:30:37
Input file: `data-raw/alldata/uncurated_raw_dedup_enriched.csv`

---

## Entering subset

Rows entering Stage 4e (`dedup_retained == TRUE & priority_kept == TRUE`): **381382**

---

## (a) Raw `statistic_type` values — row counts and Warne 2025 tier

All distinct raw values shown verbatim, sorted by row count descending. `<NA>` = missing statistic_type.

| statistic_type | warne_tier | n_rows |
| --- | --- | --- |
| LC50 | median_effect_conv_5 | 132351 |
| NOEC | negligible_no_conversion | 94918 |
| LOEC | low_effect_conv_2.5 | 70623 |
| EC50 | median_effect_conv_5 | 48132 |
| NOEL | negligible_no_conversion | 11095 |
| LOEL | low_effect_conv_2.5 | 5284 |
| EC10 | appropriate_no_conversion | 4542 |
| IC50 | median_effect_conv_5 | 3089 |
| MATC | low_effect_conv_2 | 2843 |
| LC10 | appropriate_no_conversion | 2092 |
| EC20 | less_pref_no_conversion | 1650 |
| IC25 | undefined_x_needs_ruling | 831 |
| EC25 | undefined_x_needs_ruling | 666 |
| LC20 | less_pref_no_conversion | 558 |
| IC10 | appropriate_no_conversion | 439 |
| LC05 | appropriate_no_conversion | 418 |
| IC20 | less_pref_no_conversion | 305 |
| LC25 | undefined_x_needs_ruling | 292 |
| EC05 | appropriate_no_conversion | 204 |
| LC16 | less_pref_no_conversion | 191 |
| LC30 | undefined_x_needs_ruling | 159 |
| LC15 | less_pref_no_conversion | 144 |
| EC15 | less_pref_no_conversion | 132 |
| LC40 | undefined_x_needs_ruling | 112 |
| IC40 | undefined_x_needs_ruling | 46 |
| MCIG | UNCLASSIFIED | 35 |
| IC30 | undefined_x_needs_ruling | 29 |
| EC40 | undefined_x_needs_ruling | 25 |
| EC30 | undefined_x_needs_ruling | 24 |
| IC05 | appropriate_no_conversion | 21 |
| IC16 | less_pref_no_conversion | 21 |
| EC16 | less_pref_no_conversion | 20 |
| IC15 | less_pref_no_conversion | 16 |
| LD50 | UNCLASSIFIED | 9 |
| NOAEL | UNCLASSIFIED | 9 |
| LOAEL | UNCLASSIFIED | 5 |
| LC07 | appropriate_no_conversion | 4 |
| LC34 | undefined_x_needs_ruling | 4 |
| BEC10 | preferred_negligible | 3 |
| LC31 | undefined_x_needs_ruling | 3 |
| LOAEC | UNCLASSIFIED | 3 |
| LT50 | UNCLASSIFIED | 3 |
| MDEC | UNCLASSIFIED | 3 |
| NOAEC | UNCLASSIFIED | 3 |
| EC31 | undefined_x_needs_ruling | 2 |
| NO | UNCLASSIFIED | 2 |
| EC18 | less_pref_no_conversion | 1 |
| EC2.52 | UNCLASSIFIED | 1 |
| EC2.71 | UNCLASSIFIED | 1 |
| EC22 | undefined_x_needs_ruling | 1 |
| EC35 | undefined_x_needs_ruling | 1 |
| EC41 | undefined_x_needs_ruling | 1 |
| EC45 | undefined_x_needs_ruling | 1 |
| EC55 | undefined_x_needs_ruling | 1 |
| EC58 | undefined_x_needs_ruling | 1 |
| EC6.99 | UNCLASSIFIED | 1 |
| IC07 | appropriate_no_conversion | 1 |
| IC7 | appropriate_no_conversion | 1 |
| LC06 | appropriate_no_conversion | 1 |
| LC08 | appropriate_no_conversion | 1 |
| LC09 | appropriate_no_conversion | 1 |
| LC13 | less_pref_no_conversion | 1 |
| LC32 | undefined_x_needs_ruling | 1 |
| LC33 | undefined_x_needs_ruling | 1 |
| LC35 | undefined_x_needs_ruling | 1 |
| LC38 | undefined_x_needs_ruling | 1 |
| LC45 | undefined_x_needs_ruling | 1 |
| LC55 | undefined_x_needs_ruling | 1 |

---

## (b) Cross-tabulation: `statistic_type` x `test_class`

Column `<NA>` = missing test_class.

| statistic_type | acute | chronic | subchronic | X.NA. |
| --- | --- | --- | --- | --- |
| LC50 | 125393 | 6958 | 0 | 0 |
| NOEC | 28945 | 65970 | 3 | 0 |
| LOEC | 26407 | 44216 | 0 | 0 |
| EC50 | 33687 | 14444 | 1 | 0 |
| NOEL | 5747 | 5348 | 0 | 0 |
| LOEL | 2528 | 2756 | 0 | 0 |
| EC10 | 1386 | 3156 | 0 | 0 |
| IC50 | 1538 | 1551 | 0 | 0 |
| MATC | 528 | 2315 | 0 | 0 |
| LC10 | 1632 | 460 | 0 | 0 |
| EC20 | 575 | 1075 | 0 | 0 |
| IC25 | 151 | 680 | 0 | 0 |
| EC25 | 299 | 367 | 0 | 0 |
| LC20 | 258 | 300 | 0 | 0 |
| IC10 | 171 | 268 | 0 | 0 |
| LC05 | 380 | 38 | 0 | 0 |
| IC20 | 117 | 188 | 0 | 0 |
| LC25 | 109 | 183 | 0 | 0 |
| EC05 | 69 | 135 | 0 | 0 |
| LC16 | 163 | 28 | 0 | 0 |
| LC30 | 133 | 26 | 0 | 0 |
| LC15 | 144 | 0 | 0 | 0 |
| EC15 | 125 | 7 | 0 | 0 |
| LC40 | 86 | 26 | 0 | 0 |
| IC40 | 35 | 11 | 0 | 0 |
| MCIG | 33 | 2 | 0 | 0 |
| IC30 | 29 | 0 | 0 | 0 |
| EC40 | 12 | 13 | 0 | 0 |
| EC30 | 1 | 23 | 0 | 0 |
| IC05 | 21 | 0 | 0 | 0 |
| IC16 | 0 | 21 | 0 | 0 |
| EC16 | 15 | 5 | 0 | 0 |
| IC15 | 6 | 10 | 0 | 0 |
| LD50 | 9 | 0 | 0 | 0 |
| NOAEL | 3 | 6 | 0 | 0 |
| LOAEL | 1 | 4 | 0 | 0 |
| LC07 | 4 | 0 | 0 | 0 |
| LC34 | 4 | 0 | 0 | 0 |
| BEC10 | 3 | 0 | 0 | 0 |
| LC31 | 0 | 3 | 0 | 0 |
| LOAEC | 0 | 3 | 0 | 0 |
| LT50 | 3 | 0 | 0 | 0 |
| MDEC | 3 | 0 | 0 | 0 |
| NOAEC | 0 | 3 | 0 | 0 |
| EC31 | 0 | 2 | 0 | 0 |
| NO | 2 | 0 | 0 | 0 |
| EC18 | 1 | 0 | 0 | 0 |
| EC2.52 | 0 | 1 | 0 | 0 |
| EC2.71 | 0 | 1 | 0 | 0 |
| EC22 | 1 | 0 | 0 | 0 |
| EC35 | 1 | 0 | 0 | 0 |
| EC41 | 1 | 0 | 0 | 0 |
| EC45 | 1 | 0 | 0 | 0 |
| EC55 | 1 | 0 | 0 | 0 |
| EC58 | 1 | 0 | 0 | 0 |
| EC6.99 | 0 | 1 | 0 | 0 |
| IC07 | 0 | 1 | 0 | 0 |
| IC7 | 0 | 1 | 0 | 0 |
| LC06 | 1 | 0 | 0 | 0 |
| LC08 | 1 | 0 | 0 | 0 |
| LC09 | 1 | 0 | 0 | 0 |
| LC13 | 1 | 0 | 0 | 0 |
| LC32 | 1 | 0 | 0 | 0 |
| LC33 | 1 | 0 | 0 | 0 |
| LC35 | 1 | 0 | 0 | 0 |
| LC38 | 1 | 0 | 0 | 0 |
| LC45 | 1 | 0 | 0 | 0 |
| LC55 | 1 | 0 | 0 | 0 |

---

## (c) UNCLASSIFIED statistic_type values

12 statistic_type value(s) not matched by the Warne 2025 tier rules (NA statistic_type excluded from this list — shown in table (a)):

| statistic_type | warne_tier | n_rows |
| --- | --- | --- |
| MCIG | UNCLASSIFIED | 35 |
| LD50 | UNCLASSIFIED | 9 |
| NOAEL | UNCLASSIFIED | 9 |
| LOAEL | UNCLASSIFIED | 5 |
| LOAEC | UNCLASSIFIED | 3 |
| LT50 | UNCLASSIFIED | 3 |
| MDEC | UNCLASSIFIED | 3 |
| NOAEC | UNCLASSIFIED | 3 |
| NO | UNCLASSIFIED | 2 |
| EC2.52 | UNCLASSIFIED | 1 |
| EC2.71 | UNCLASSIFIED | 1 |
| EC6.99 | UNCLASSIFIED | 1 |

---

## (d) Conversion-needed tiers — chronic / subchronic / NA test_class, by source

Tiers: `median_effect_conv_5`, `low_effect_conv_2.5`, `low_effect_conv_2`  (test_class restricted to chronic, subchronic, or NA)

| source | warne_tier | statistic_type | test_class | n_rows |
| --- | --- | --- | --- | --- |
| anztox | low_effect_conv_2 | MATC | chronic | 8 |
| anztox | low_effect_conv_2.5 | LOEC | chronic | 199 |
| anztox | low_effect_conv_2.5 | LOEL | chronic | 2 |
| anztox | median_effect_conv_5 | EC50 | chronic | 474 |
| anztox | median_effect_conv_5 | EC50 | subchronic | 1 |
| anztox | median_effect_conv_5 | IC50 | chronic | 22 |
| anztox | median_effect_conv_5 | LC50 | chronic | 87 |
| wqbench | low_effect_conv_2 | MATC | chronic | 2307 |
| wqbench | low_effect_conv_2.5 | LOEC | chronic | 44017 |
| wqbench | low_effect_conv_2.5 | LOEL | chronic | 2754 |
| wqbench | median_effect_conv_5 | EC50 | chronic | 13970 |
| wqbench | median_effect_conv_5 | IC50 | chronic | 1529 |
| wqbench | median_effect_conv_5 | LC50 | chronic | 6871 |

---

## (e) Summary

**72241 rows (18.94% of the 381382-row entering subset) are chronic/subchronic/NA-class median-or-low-effect estimates currently flowing through Stage 4e without a conversion factor applied.**

Breakdown by tier:

| warne_tier | n_rows |
| --- | --- |
| low_effect_conv_2.5 | 46972 |
| median_effect_conv_5 | 22954 |
| low_effect_conv_2 | 2315 |

