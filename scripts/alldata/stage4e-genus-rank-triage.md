# Stage 4e — Genus-rank triage: raw_genus_level vs floored_binomial

Date: 2026-06-26

Classifies the 11,199 genus-rank flagged rows from the Stage 4e diagnostic into two buckets:

- **raw_genus_level**: raw source name was already at genus level (expected)
- **floored_binomial**: raw name was a binomial but the resolver floored it to genus

---

## Row counts by bucket

| bucket | n_rows | pct |
| --- | --- | --- |
| floored_binomial |   242 | 2.16% |
| raw_genus_level | 10957 | 97.84% |

## Distinct name counts by bucket

| bucket | n_distinct_accepted | n_distinct_original |
| --- | --- | --- |
| floored_binomial |  24 |  24 |
| raw_genus_level | 743 | 771 |

---

## Cross-tab: bucket x resolution_status (row level)

| bucket | resolution_status | n_rows |
| --- | --- | --- |
| floored_binomial | exact_unaccepted_filtered |   62 |
| floored_binomial | gbif_resolved |  180 |
| raw_genus_level | ambiguous_after_filter |    7 |
| raw_genus_level | exact_filtered |  171 |
| raw_genus_level | exact_unaccepted_filtered |    6 |
| raw_genus_level | gbif_resolved | 1208 |
| raw_genus_level | genus_resolved | 9266 |
| raw_genus_level | unresolved |  299 |

---

## Cross-tab: bucket x source (row level)

| bucket | source | n_rows |
| --- | --- | --- |
| floored_binomial | anztox |    9 |
| floored_binomial | envirotox |   13 |
| floored_binomial | wqbench |  220 |
| raw_genus_level | anztox |  362 |
| raw_genus_level | envirotox | 1279 |
| raw_genus_level | wqbench | 9316 |

---

## Triage CSV summary

File: `data-raw/alldata/stage4e-genus-rank-triage.csv`

One row per distinct `original_scientificname` among the 11,199 flagged rows.

| Bucket | Distinct original_scientificname |
| --- | --- |
| floored_binomial | 24 |
| raw_genus_level | 771 |
| **Total** | **795** |

Filter to `bucket == "floored_binomial"` for the review-candidate set.

---

## Files to commit

- `scripts/alldata/stage4e-genus-rank-triage.R` — this script
- `scripts/alldata/stage4e-genus-rank-triage.md` — this report
- `data-raw/alldata/stage4e-genus-rank-triage.csv` — per-original-name triage table

