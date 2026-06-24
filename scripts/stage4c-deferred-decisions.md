# Stage 4c Deferred Decisions

Date: 2026-06-24

This file tracks a decision affecting Stage 4c Part 2 (cross-source duplicate
detection and ANZG priority selection, Issue #33) that blocked the pipeline
at Phase 1 and is intentionally left unresolved pending a project-level
decision. It must be checked, and this file updated, before Stage 4c Part 2
(Phases 2-4) is attempted again.

## 1. wqbench within-source duplicate rate cannot be brought under the 1% Phase 1 threshold

**Status:** Deferred. Stage 4c Part 2 stopped after Phase 1 (within-source
duplicate diagnostic) and did not proceed to Phase 2 (cross-source dedup),
Phase 3 (ANZG priority selection), or Phase 4 (write outputs). No
`data-raw/alldata/uncurated_raw_dedup.csv` or
`data-raw/alldata/stage4c-dedup-report.md` was produced this session.

### What was found

The Phase 1 within-source duplicate diagnostic (`scripts/stage4c-dedup.R`)
flags rows whose `native_cas x scientificname_norm x medium x
statistic_type_norm x effect_category x duration_hours x life_stage x
study_reference` (wqbench's key; anztox/envirotox keys omit `life_stage`
and/or `medium` per `scripts/stage4c-schema-inventory.md`) match another row
in the same source. The task brief's stop condition (>1% of a source's rows
involved) tripped for all three sources on the first run:

| source | n_total | n_dup_rows | pct_dup |
|---|---|---|---|
| anztox | 15,667 | 8,155 | 52.1% |
| wqbench | 361,782 | 147,075 | 40.7% |
| envirotox | 72,439 | 25,113 | 34.7% |

Investigation (not just re-running with a higher threshold) traced this to
two distinct, independent causes:

**Cause 1 -- the key omitted `conc_value`.** Dose-response studies report
many concentrations under otherwise-identical metadata (same study, species,
endpoint, duration). Adding `conc_value` to the key dropped envirotox to
**0.56%** (passes) and anztox to **9.2%**, but only dropped wqbench to
**25.1%**.

**Cause 2 -- wqbench's `source_id` was not a row identifier.** Traced to
`scripts/stage4b-extract.R`: `source_id` was constructed as
`paste0(species_number, "_", cas)`, a (species, chemical)-pair identifier,
not a per-record one (unlike anztox's `toxicityvalue_id` or envirotox's
`row_number()`). Confirmed empirically: in every one of 23,022 remaining
wqbench duplicate groups (key + `conc_value`), all member rows shared one
single `source_id`. This was a genuine, fixable defect and **has been
fixed** in this session: `scripts/stage4b-extract.R` now assigns
`source_id = as.character(row_number())` for wqbench, matching the other two
sources' convention. `scripts/stage4b-extract.R` and
`scripts/stage4b-effect-category-fixup.R` were both re-run end-to-end; all
row counts and distributions are unchanged from before except `source_id`
itself, which is now confirmed unique across all 361,782 wqbench rows. See
`prompts/stage4b-extract.md`, session "stage4b-wqbench-source-id-fix", for
the full record.

**The `source_id` fix did not change wqbench's 25.1% rate.** This was
expected once understood: `source_id` is correct now, but it was never part
of the matching *key* (including a row index in a duplicate-matching key
would trivially make every row unique and defeat the check's purpose). The
25.1% reflects groups of wqbench rows that are now *confirmed* to be
genuinely separate records (distinct `source_id` per row) which nonetheless
collapse onto **identical values in every field the common 17-column schema
retains**. The clearest example found: a single paper reporting zebrafish
gene-expression results across ~180 distinct genes, all sharing the same
NOEC, duration, life stage, and study reference, all bucketed under the one
coarse `effect_category` value `"Genetics"` -- there is no field anywhere in
wqbench's contribution to the common schema (confirmed against the full
24-column RDS inventory in `scripts/stage4c-schema-inventory.md` Step 2a)
that identifies *which* gene/biomarker was measured. `test_id`/`result_id`
-style fields, which would resolve this, are confirmed **absent from the
RDS entirely** (`wqb_create_data_set()` consumes and discards them upstream
of the RDS this pipeline reads) -- recovering them would require re-running
`wqb_create_data_set()` from a fresh EPA ECOTOX ASCII download (currently
commented out in `data-raw/wqbench/DATASET.R`), not just adjusting the
existing intercept point.

**anztox's residual 9.2% (1,442 rows, key + `conc_value`) is not a defect.**
`source_id` correctly differs per row in every one of these groups
(confirmed: `n_distinct(source_id) == n_rows` for all 632 groups). The
largest sampled group is a 1987 zebrafish ring test reporting the same NOEC
result from ~10 different participating labs -- genuine, distinct database
records that happen to report an identical value.

### Why this blocks Phase 2/4c Part 2 today

No within-source key built from the fields currently retained in the common
17-column schema can bring wqbench (or, to a lesser extent, anztox) under
the 1% threshold specified in the Stage 4c Part 2 task brief, because the
excess in both cases reflects genuine data, not a key-design or
identifier bug. The user decided (2026-06-24) to stop and escalate this as a
deferred decision rather than have Claude either silently downgrade the
threshold to report-only or pick a different key unilaterally.

### Options for resolution (not yet decided)

1. **Downgrade the >1% rule to a reported finding, not a hard stop**, for
   this stage specifically, with the evidence above carried into the
   report so the elevated rates are never mistaken for a data-quality
   problem.
2. **Extend the wqbench common-schema intercept** to retain an additional
   discriminating field, if one can be recovered by going further upstream
   (re-running `wqb_create_data_set()` against a fresh EPA ECOTOX download
   rather than the cached RDS) -- a substantially larger undertaking than
   anything else done in Stage 4b/4c so far, and would need to be scoped as
   its own stage.
3. **Accept the schema's current resolution as a permanent limit** and
   redesign Phase 1 specifically for wqbench to report duplicate
   groups/rates as a description of the data's intrinsic granularity rather
   than a pass/fail gate.

### Action required before Stage 4c Part 2 resumes

A project-level decision on which of the above (or another option) to take,
then an update to `scripts/stage4c-dedup.R` (currently halts cleanly after
Phase 1 with `conc_value` added to all three within-source keys) and a
re-run of Phases 2-4.
