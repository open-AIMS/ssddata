## Session: stage4a-pipeline-audit
Date: 2026-06-23
Model: Claude Sonnet 4.6

### Prompts and Responses

**User:** Requested a pure audit (Stage 4a) of the three uncurated sources'
data-raw pipelines (anztox, wqbench, envirotox) ahead of the Stage 4b
cross-source consolidation work for Issue #33. Asked for: (1) a structured
read-through of each source's `DATASET.R` covering inputs, filtering, CAS
lookup application, Section 3.4.4-equivalent aggregation, pre-aggregation
fields, and final output fields/units; (2) a concentration-units audit
across all seven sources including reproducing and verifying ccme's
`str_replace` unit-assignment block; (3) documentation of the
filtered-but-unaggregated "intercept point" for each uncurated source,
including which of a specified field checklist is present, named, or
missing; (4) a consolidated gap list covering unit standardisation, schema
alignment, statistical-estimate alignment, effect-category alignment, and
any other issues. Explicit instruction: audit only, no files modified, no
scripts run end-to-end, no aggregation or transformed data produced.
Required reading first: the global and project `CLAUDE.md` files, the
ANZTOX_data_processing and cas_parent_lookup_build vignettes, and the
Stage 3 media audit. Output requested at
`scripts/stage4a-pipeline-audit.md` with a specific section structure, and
a prompt log appended to `prompts/stage4a-pipeline-audit.md` following the
format in `CLAUDE.md`.

**Claude:** Read both `CLAUDE.md` files, both named vignettes, and
`scripts/stage3-media-audit.md` first. Then read all three `DATASET.R`
files in full (`data-raw/anztox/DATASET.R`, `data-raw/wqbench/DATASET.R`,
`data-raw/envirotox/DATASET.R`) without executing any of them end-to-end.

For wqbench, since the script itself only calls two `wqbench` package
functions directly and most filtering logic lives inside the package
(already baked into the pre-built RDS), inspected the installed `wqbench`
package's source for `wqb_create_data_set`, `wqb_aggregate`,
`wqb_filter_chemical`, `wqb_standardize_effect`, `wqb_classify_duration`,
and the unexported `wqb_join_data`/`wqb_clean_data` via `wqbench:::`, to
document what filtering/classification/unit-standardisation actually
happens upstream of ssddata's own script.

Verified field lists and row/distinct-value counts directly against the
real artefacts wherever possible (read-only): loaded `data/anztox_data.rda`
and `data/wqbench_data.rda`, read
`data-raw/anztox/raw/toxicityvalue_combined_clean.csv`, loaded
`data-raw/wqbench/ecotox_ascii_12_11_2025.rds` directly, and read
`data-raw/envirotox/envirotox.xlsx` (`test` and `substance` sheets) with
`openxlsx` to confirm raw `Test.statistic`/`Test.type`/`Effect`/`Unit`
distributions and the effect of envirotox's filter step on the `Effect`
field specifically (confirmed effectively no effect-category filtering
occurs — 110 of 113 distinct `Effect` values survive the existing filter
untouched).

Verified ccme's unit `str_replace` chain by running it against the actual
`CCME data.csv` (confirmed all 144 current rows / 7 chemicals are covered
exactly, but the mechanism would silently mis-assign a chemical's own name
as its "unit" for any future unmapped chemical, rather than producing
`NA` or erroring). Checked aims/csiro/anzg CSVs and Rd templates for units
conventions, finding aims hardcodes `Units = "ug/L"` for every row, while
csiro and anzg have no machine-readable units field at all (documented
only in Rd-template prose).

Discovered and confirmed via `parse("data-raw/anztox/DATASET.R")` that
line 431 uses the disabled `=>` pipebind operator instead of `=`
(`by = c("species_id" => "id")`), meaning the script as committed cannot
be parsed/sourced under default R settings. Also found and documented: 632
`"Chronic QSAR"` anztox rows silently dropped entirely by the test-type
priority filter (falls into an unhandled `"other"` class); an internal
2-letter-code/full-taxonomic-name inconsistency within anztox's own
`majorgroup` field (e.g. `"OS"` and `"Osteichthyes"` both present and
counted as distinct groups); and that envirotox's final `envirotox_acute`/
`envirotox_chronic` objects drop their chemical identifier (`OriginalCAS`),
effect category (`Effect`), and statistic type (`Test.statistic`) entirely
before output — none of the three survive past `EnviroTox_test_selected2`.

Wrote the consolidated findings to `scripts/stage4a-pipeline-audit.md`
following the requested section structure (pipeline summaries for each of
the three uncurated sources, a seven-source units audit table, an
intercept-points table, and a five-part gap list covering unit
standardisation, schema alignment, statistical-estimate alignment, effect
category alignment, and other findings). No files other than this report
and this log were created; no existing file was modified; no `.rda`/data
outputs were regenerated or run.

---
