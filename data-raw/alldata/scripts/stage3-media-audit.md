# Stage 3 Media Assignment Audit
Date: 2026-06-23

Audit and documentation only — no `DATASET.R` files, `.rda` files, or
source CSVs were modified to produce this report.

## Source-by-source media field status

| Source | Field name | Distinct values | Row counts | Stage 4 ready |
|---|---|---|---|---|
| aims | `Medium` (`data-raw/aims/aims.csv`) | marine | marine: 40 | Yes |
| csiro | `Medium` (`data-raw/csiro/csiro.csv`) | freshwater, marine | freshwater: 31; marine: 60 | Yes |
| ccme | *(absent — no media column in `data-raw/ccme/CCME data.csv`)* | Unknown (interim) | Unknown: 145 | Yes, with documented Unknown placeholder — **deferred**, pending issue #34 |
| anzg | `Medium` (`data-raw/anzg/anzg.csv`) | freshwater, hard freshwater, marine, moderate freshwater, soft freshwater | freshwater: 348; hard freshwater: 12; marine: 207; moderate freshwater: 11; soft freshwater: 14 | Yes |
| anztox | `mediatype` (`data/anztox_data.rda`) | Freshwater, Marine | Freshwater: 128; Marine: 46 | Yes |
| wqbench | `Medium` (`data/wqbench_data.rda`) | Freshwater, Marine, Unknown | Freshwater: 26,688; Marine: 8,401; Unknown: 1,540 | Yes, content-ready — contingent on PR #43 being merged into the base before this branch merges to main |
| envirotox | *(absent — no usable media field in `data-raw/envirotox/envirotox.xlsx`, sheet `test`)* | Unknown (to be assigned at Stage 4) | Unknown: 80,912 | Yes, with documented Unknown placeholder — **confirmed final**, no outstanding item |
| anon | — | — | — | N/A — excluded from `alldata` by design |

Notes on fields with no usable media data:

- **ccme** (`data-raw/ccme/CCME data.csv`): columns are `Chemical`, `Species`,
  `Conc`, `Reference` — no media/medium column of any kind. There is no
  basis in the current raw input to assign anything other than `Unknown`.
- **envirotox** (`data-raw/envirotox/envirotox.xlsx`, sheet `test`):
  columns are `CAS`, `Chemical name`, `Latin name`, `Trophic Level`
  (Algae/Amphibian/Fish/Invertebrate — a taxonomic group, not a habitat),
  `Effect`, `Effect value`, `Unit`, `Test type` (Acute/Chronic), `Test
  statistic`, `Duration`, `Duration (days)`, `Duration (hours)`, `Effect is
  5X above water solubility` (a 0/1 data-quality flag about whether the
  effect concentration exceeds water solubility — not a freshwater/marine
  indicator), `Source`, `version`, `Reported chemical name`, `original
  CAS`. None of these distinguish freshwater from marine test conditions.

## Deferred decisions

Full detail in `data-raw/alldata/scripts/stage3-deferred-decisions.md`. Summary:

1. **ccme medium** — deferred pending GitHub issue #34; interim `Unknown`
   for all 145 rows; revisit and amend `data-raw/ccme/DATASET.R` before
   Stage 6.
2. **envirotox medium** — confirmed final `Unknown` for all 80,912 rows;
   no usable media metadata exists in the raw input; no further action.
3. **PR #43 (`add_media_wqbench`)** — must be merged into main before this
   branch merges; `data/wqbench_data.rda` already reflects its output.
4. **18 UNCERTAIN CAS parent rows** (`scripts/cas-lookup/stage2b-full-results-combined.csv`,
   merged into `data-raw/cas_parent_lookup_all.csv` at Stage 2e) — unrelated
   to media, but require human domain expert sign-off before Stage 6.

## Readiness for Stage 4

Every source in scope for `alldata` (aims, csiro, ccme, anzg, anztox,
wqbench, envirotox) has a usable, queryable media value today — either a
populated `Medium`/`mediatype` field (aims, csiro, anzg, anztox, wqbench)
or a documented `Unknown` placeholder (ccme, envirotox). **Stage 4 can
proceed with `Unknown` values where they are documented** — neither ccme
nor envirotox blocks the consolidated `chemical × media × species`
dataset; "Unknown" is itself a valid media category for that aggregation.
`anon` is excluded from `alldata` and requires no media work.

Two items are genuinely outstanding and must be resolved before **Stage
6** (wiring up `ssd_data_sets(set = "alldata")`), not before Stage 4:

- **ccme**: issue #34 response, followed by a `data-raw/ccme/DATASET.R`
  amendment if the answer changes the interim `Unknown` value.
- **PR #43**: must be merged into main before this branch is merged,
  since the wqbench media field this audit relies on depends on it.

The 18 UNCERTAIN CAS parent rows (deferred decision #4) are an Issue #33
blocker but are independent of media assignment specifically — they block
chemical alignment, not the Stage 4 media-aggregation step itself.
