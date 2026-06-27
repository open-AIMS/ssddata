# Stage 3 Deferred Decisions

Date: 2026-06-23

This file tracks decisions affecting `alldata` media assignment (Issue #33,
Stage 3) that are intentionally incomplete or contingent on something
outside this branch. Each item must be checked, and this file updated,
before Stage 6 (`ssd_data_sets(set = "alldata")`) ships.

## 1. ccme medium assignment — deferred

**Status:** Deferred, pending response to GitHub issue #34.

`data-raw/ccme/CCME data.csv` has no media/medium column at all (columns
are `Chemical`, `Species`, `Conc`, `Reference`). Whether ccme records are
freshwater, marine, or a mix is unknown without the source clarification
requested in issue #34.

**Interim value:** `Medium = "Unknown"` for all 145 ccme rows.

**Action required before Stage 6:** once issue #34 is answered, update this
file with the resolution and amend `data-raw/ccme/DATASET.R` to assign the
correct medium (or confirm "Unknown" is in fact correct) before ccme is
included in `alldata`.

## 2. envirotox medium assignment — confirmed final

**Status:** Final decision, not deferred.

`data-raw/envirotox/envirotox.xlsx` (sheet `test`) has no usable media
field. Columns are `CAS`, `Chemical name`, `Latin name`, `Trophic Level`
(Algae/Amphibian/Fish/Invertebrate — taxonomic, not media), `Effect`,
`Effect value`, `Unit`, `Test type` (Acute/Chronic), `Test statistic`,
`Duration`, `Duration (days)`, `Duration (hours)`, `Effect is 5X above
water solubility` (a 0/1 data-quality flag, not a habitat indicator),
`Source`, `version`, `Reported chemical name`, `original CAS`. None of
these distinguish freshwater from marine.

**Value:** `Medium = "Unknown"` for all 80,912 envirotox rows. This is a
confirmed final decision, not contingent on any further input — there is
no source data to recover a better value from.

## 3. PR #43 (add_media_wqbench) — merge dependency

**Status:** Open dependency; this branch assumes PR #43 is already merged
into its base.

`data/wqbench_data.rda` already reflects PR #43's output: it carries a
`Medium` field with values `Freshwater` (26,688), `Marine` (8,401), and
`Unknown` (1,540) across 36,629 rows. This branch's Stage 3 work did not
add that field — it was already present when this audit was performed.

**Action required before this branch is merged to main:** confirm PR #43
has been merged into main first. If PR #43 is rebased, reworked, or its
output changes the `Medium` field's values or row count, re-run the Stage
3 wqbench check in `scripts/alldata/stage3-media-audit.md` against the updated
`wqbench_data.rda` before proceeding.

## 4. 18 UNCERTAIN CAS parent rows — human review required

**Status:** Deferred, pending human domain expert review.

18 rows in `scripts/cas-lookup/stage2b-full-results-combined.csv` (CAS parent
mappings, now merged into `data-raw/cas_parent_lookup_all.csv` as of Stage
2e) carry `match_rationale` containing `UNCERTAIN`. These are unrelated to
media assignment but are listed here because, like the ccme decision
above, they are an open item that must close before Stage 6 treats the
chemical-alignment and media-assignment inputs to `alldata` as complete.

Full list and rationale: `prompts/cas-lookup/stage2b-full-run.md` and
`prompts/cas-lookup/stage2d-corrections.md`.

**Action required before Stage 6:** human domain expert sign-off on all 18
rows; update `data-raw/cas_parent_lookup_all.csv` accordingly (`notes`,
`match_rationale`, `human_checked`) if any are resolved or changed.
