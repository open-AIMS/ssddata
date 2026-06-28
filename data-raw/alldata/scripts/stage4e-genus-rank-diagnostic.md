# Stage 4e — Genus-rank accepted_name diagnostic

Date: 2026-06-26

Detection function: `flag_genus_rank()` — flags accepted_name values that
resolve only to genus level (single-token names, names with sp./spp./cf./aff./nr.
qualifiers, or names that exactly equal the resolved genus field).

---

## PART A — Raw-record level (enriched file)

**Input:** `uncurated_raw_dedup_enriched.csv`

| Metric | Count |
| --- | --- |
| Clean subset rows (dedup_retained & priority_kept) | 381,382 |
| Genus-rank rows in clean subset | 11,199 |
| % of clean subset | 2.94% |
| Distinct genus-rank accepted_name values | 765 |

### Breakdown by source

| source | n_rows |
| --- | --- |
| wqbench | 9536 |
| envirotox | 1292 |
| anztox |  371 |

### Breakdown by resolution_status

| resolution_status | n_rows |
| --- | --- |
| genus_resolved | 9266 |
| gbif_resolved | 1388 |
| unresolved |  299 |
| exact_filtered |  171 |
| exact_unaccepted_filtered |   68 |
| ambiguous_after_filter |    7 |

### Breakdown by taxonomy_provenance

| taxonomy_provenance | n_rows |
| --- | --- |
| worms_full | 9505 |
| gbif_full | 1388 |
| source_native_fallback |  299 |
| ambiguous_partial |    7 |

### Rows reaching aggregation (after Steps 2a/2b filters)

Rows entering aggregation today (all species): 291,632

| Metric | Count |
| --- | --- |
| Genus-rank rows reaching aggregation today | 9,709 |
| % of aggregation-entering rows | 3.33% |

---

## PART B — Output level (aggregated file)

**Input:** `uncurated_raw_aggregated.csv`

| Metric | Count |
| --- | --- |
| Total output rows | 62,410 |
| Genus-rank output rows | 3,220 |
| % of output | 5.16% |
| Distinct genus-rank accepted_name values | 727 |
| Distinct casnumber_grouped affected | 537 |
| CAS × medium combinations with changed species count | 861 |
| Distinct chemicals affected (CAS level) | 537 |

---

## Output files

- `data-raw/alldata/scripts/stage4e-genus-rank-diagnostic.md` — this report
- `data-raw/alldata/stage4e-genus-rank-candidates.csv` — 765 rows, one per distinct flagged accepted_name

