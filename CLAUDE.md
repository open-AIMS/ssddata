# Project: ssddata

This file provides **project-specific context only** — repo structure, dependencies,
analysis decisions, and prompt logging. It does not impose personal style preferences
on collaborators.

**For Claude:** If a `CLAUDE.md` exists in the parent directory of this repo,
read it before proceeding — it may contain user-specific environment and style
preferences. If no such file exists, apply sensible R defaults and ask if
anything is unclear. This repo-level file takes precedence over any parent-level
file where they conflict.

---

## 1. Repo Type

**R package** — standard usethis/devtools structure, R CMD check via GitHub
Actions, pkgdown site, testthat, roxygen2.

---

## 2. What This Repo Does

The `ssddata` repository is an R package that provides curated benchmark datasets
of species sensitivity data used to fit and evaluate species sensitivity distribution
(SSD) models. It solves the problem of fragmented and inconsistent ecotoxicological
data by standardising and aggregating datasets from multiple sources into a common,
reproducible reference set for method comparison and testing.

Key inputs are existing toxicity and species sensitivity datasets sourced from
organisations such as AIMS, CSIRO, CCME, ANZG, and others, which are cleaned and
harmonised. The primary outputs are ready-to-use, standardised SSD datasets (and
some derived benchmark/fit data) that can be directly used to fit SSD models and
compare analytical methods.

---

## 3. Package Dependencies in Scope

**For DESCRIPTION-based repos:** Dependencies are defined in `DESCRIPTION`
(Imports + Suggests). Read that file to determine what is available.

---

## 4. Version Control Policy — Large Intermediate Files

**Several Stage 4 intermediate artefacts must remain UNTRACKED in git.**
These files are large (multi-million-row CSVs and similar), and their inclusion
in commits has caused push failures and repo bloat. They have been retroactively
stripped from the commit history via `git filter-branch` (2026-06-25) and are
listed in `.gitignore`.

### Files that must remain untracked

- `data-raw/alldata/uncurated_raw_combined.csv` (~450k rows)
- `data-raw/alldata/uncurated_raw_dedup.csv` (~450k rows × 21 cols)
- `data-raw/alldata/uncurated_raw_dedup_enriched.csv` (~450k rows × 33 cols, ~228 MB)
- `data-raw/alldata/uncurated_raw_aggregated.csv` (Stage 4e output — size TBC at runtime)
- `data-raw/alldata/anztox_extracted.csv` (~16k rows × 19 cols)
- `data-raw/alldata/alldata_integrated.csv` (Stage 6 output — ~14.3 MB, untracked)
- Any future similar large intermediate CSV produced by Stage 4+ scripts
- Resolver caches (`species_resolution_cache.rds`,
  `species_resolution_v2_cache.rds`, etc.) — these are regenerable from
  the scripts and are large binary files

These files are produced by deterministic scripts and can be regenerated
locally. The reproducibility cost of not committing them is accepted in this
branch and will be revisited later if needed (e.g. by producing a smaller
representative test subset for the repo).

### What Claude Code MUST do

- Never run `git add` on the above files or any new large intermediate CSV
- Never modify `.gitignore` to start tracking these files without explicit
  user direction
- If a script produces a file >5 MB in `data-raw/alldata/`, add the
  filename to `.gitignore` BEFORE the file is created if possible, and
  flag the new file in the session summary so the user can confirm
- Report file sizes for newly produced outputs in session summaries so
  the user can see whether anything has crossed the threshold
- Smaller artefacts (reports, mapping CSVs, schema inventories, audit
  files under ~5 MB) remain tracked normally — these are the primary
  reproducibility record

### Commits are made by the user, not Claude Code

**Claude Code must NEVER run `git commit` or `git push`.** The user
commits manually after reviewing session outputs. Stage prompts should
end with a "Files to commit" checklist (listing the tracked artefacts
produced), not with git commands. Claude Code may run `git status` and
`git diff --stat` to confirm what is staged or modified, but must stop
there.

### Note on stripped history

The remote may still contain copies of the large files in older history
(pushed before the filter-branch operation). A full `git filter-repo` purge
across the entire remote history can be done later if repo size becomes an
issue. This is not currently blocking work.

### Note on cross-environment file availability

The user works across Windows Positron (required for the anztox PostgreSQL DB)
and WSL Positron (preferred for most other work). Both environments share the
same filesystem paths via the WSL mount. If a Stage 4 intermediate file is
reported as missing from one environment but present in the other, this is
typically a filesystem-state issue, not an environment-architecture issue.
The user is responsible for keeping the untracked Stage 4 files synced
between environments (or restoring from a backup). If a script reports
"file not found" for `uncurated_raw_dedup.csv` or similar, ASK the user
before assuming the file needs to be regenerated.

---

## 5. Project-Wide Coding Conventions

### `readr::read_csv()` and sparse columns

**Always use `guess_max = Inf` when reading any Stage 4 intermediate CSV
that has audit columns near the end of the schema.** Several files in this
pipeline have new audit columns added by fixup scripts which are NA for
all but a small number of rows, often past row 1000.

`readr::read_csv()`'s default type-guesser only samples the first 1000 rows.
If all sampled values in a column are NA, it infers `logical`, then silently
converts real string values it encounters later to NA — only emitting a
parsing-mismatch warning that is easy to miss. This was identified during
Stage 4d Part 2's manual-corrections fixup, where two audit columns affecting
3 of 4,348 rows tripped the trap.

Files known to require `guess_max = Inf`:
- `data-raw/alldata/species_resolution_v2.csv` (3 audit columns with sparse
  string content past row 1000)
- `data-raw/alldata/species_resolution_v2_problem_species.csv` (same risk)
- `data-raw/alldata/uncurated_raw_dedup_enriched.csv` (sparse synonym audit
  columns and resolution_status values may trigger the trap; use
  `guess_max = Inf` defensively)
- `data-raw/alldata/species_resolution_curated.csv` (Stage 6 taxonomy cache
  for aims/csiro species — 77 rows; same sparse-column risk)
- `data-raw/alldata/alldata_integrated.csv` (Stage 6 output — use
  `guess_max = Inf` defensively)

Files likely to require `guess_max = Inf` going forward:
- Any Stage 4e+ outputs that augment existing files with sparse
  audit columns
- Any fixup script output that adds columns to an existing CSV

Rule: when reading any CSV produced by a fixup script, use
`read_csv(path, guess_max = Inf, ...)` or specify explicit `col_types`.
Same trap exists for `data.table::fread()` and base `read.csv()` with their
defaults — use the analogous full-scan options.

---

## 6. Key Files and Structure

### R package layout

```
R/              # exported functions — one file per logical group
tests/testthat/ # testthat test files (test-<name>.R)
man/            # auto-generated by roxygen2, do not edit manually
data-raw/       # scripts that produce data objects in data/
vignettes/      # long-form documentation
DESCRIPTION     # package metadata, imports, suggests
NEWS.md         # changelog (one entry per version)
prompts/        # session prompt logs (create if absent)
scripts/        # audit and utility scripts (create if absent)
```

### Data sources

All source datasets are stored as `.rda` files under `data/`. They are named
with a source prefix followed by the chemical name (e.g. `ccme_boron`).

Current source prefixes and their data-raw locations:

| Prefix     | Curation status | Primary source for audit        |
|------------|-----------------|---------------------------------|
| aims_      | Curated         | `data-raw/aims/` — use CSV      |
| csiro_     | Curated         | `data-raw/csiro/` — use CSV     |
| ccme_      | Curated         | `data-raw/ccme/` — use CSV      |
| anzg_      | Curated         | `data-raw/anzg/` — use CSV      |
| anon_      | Anonymous       | `data-raw/anon/` — use CSV      |
| anztox_    | Uncurated       | `data-raw/anztox/` — use CSV    |
| wqbench_   | Uncurated       | `data-raw/wqbench/` — use CSV   |
| envirotox_ | Uncurated       | `data-raw/envirotox/` — use CSV |

**Note:** For aims, csiro, ccme, anzg — the `.rda` generation workflow is
complex. Go directly to the `.csv` in the relevant `data-raw/` subfolder
for auditing and data-raw work.

### CAS lookup table

**CRITICAL PATH NOTE:** The master CAS lookup lives at
`data-raw/cas_parent_lookup_all.csv` — NOT `data-raw/anztox/cas_parent_lookup_all.csv`.
This path error has recurred multiple times and must be checked explicitly.

The original 40-row human-curated lookup lives at
`data-raw/anztox/cas_parent_lookup.csv` (this one IS in the anztox subfolder).

As of Stage 2e, the expanded 587-row population has been merged into the master
file. `data-raw/cas_parent_lookup_all.csv` is now the single authoritative source
for all CAS parent mappings. 18 rows remain flagged UNCERTAIN and require human
domain expert review before Stage 6 (deduplication).

### Stage 4 intermediate artefacts

The following intermediate files are produced by the Stage 4 pipeline and live
under `data-raw/alldata/`. Files marked **(untracked)** are in `.gitignore` and
must not be committed (see Section 4 for policy).

| File | Tracked? | Description |
|------|----------|-------------|
| `data-raw/alldata/anztox_extracted.csv` | **untracked** | anztox filtered unaggregated records; ~15,667 rows × 19 columns. |
| `data-raw/alldata/uncurated_raw_combined.csv` | **untracked** | Three-source combined unaggregated records; ~449,888 rows × 17 columns. |
| `data-raw/alldata/uncurated_raw_dedup.csv` | **untracked** | ~449,888 rows × 21 cols (17 common schema + 4 dedup flag columns). |
| `data-raw/alldata/uncurated_raw_dedup_enriched.csv` | **untracked** | ~449,860 rows × 33 cols. The Stage 4d Part 3 output and INPUT FOR STAGE 4e. Includes synonym-unified `accepted_name`, the resolved taxonomic hierarchy (kingdom, phylum, class, order_taxon, family, genus), `majorgroup` (= class), `taxonomy_provenance`, and `resolution_status`. ~228 MB. |
| `data-raw/alldata/uncurated_raw_aggregated.csv` | **untracked** | Stage 4e output (post-patch). 62,410 rows × 20 cols, ~14.4 MB. One row per species × chemical × medium. Schema: see Section 6 below. |
| `data-raw/alldata/alldata_integrated.csv` | **untracked** | Stage 6 output. 59,986 rows × 24 cols, ~14.3 MB. All sources integrated with exclusion hierarchy applied. Contains 3 pipeline-only columns (`Group`, `Chemical`, `exclusion_flag`) dropped at Stage 7. INPUT FOR STAGE 7. |
| `data-raw/alldata/species_resolution_cache.rds` | **untracked** | Part 1 WoRMS/GBIF resolver cache. |
| `data-raw/alldata/species_resolution_v2_cache.rds` | **untracked** | Part 2 context-aware resolver cache. |
| `data-raw/alldata/envirotox_effect_category_map.csv` | tracked | Mapping of 110 envirotox raw Effect values to the controlled effect_category vocabulary. |
| `data-raw/alldata/anztox_2016_effect_category_map.csv` | tracked | Mapping of 240 anztox 2016 free-text/non-standard effect_category values. |
| `data-raw/alldata/species_source_taxonomy.csv` | tracked | Per-source taxonomy for in-scope species (Stage 4d Part 1.5). |
| `data-raw/alldata/species_resolution_summary.csv` | tracked | Part 1 resolution outcomes. |
| `data-raw/alldata/species_resolution_v2.csv` | tracked | Part 2 + fixups: per-species resolution outcomes (4,348 rows × 30 cols). Always read with `guess_max = Inf`. |
| `data-raw/alldata/species_resolution_v2_problem_species.csv` | tracked | Per-species detail for the 146 problem species. Always read with `guess_max = Inf`. |
| `data-raw/alldata/species_synonym_audit.csv` | tracked | Synonym groups identified by Part 2 resolution. |
| `data-raw/alldata/stage4c-dedup-report.md` | tracked | Stage 4c dedup audit report. |
| `data-raw/alldata/stage4d-species-resolution-report.md` | tracked | Stage 4d Part 1 diagnostic report. |
| `data-raw/alldata/stage4d-taxonomy-inventory.md` | tracked | Stage 4d Part 1.5 taxonomy inventory report. |
| `data-raw/alldata/stage4d-part2-report.md` | tracked | Stage 4d Part 2 resolution report. |
| `data-raw/alldata/stage4d-part2-fallback-report.md` | tracked | Stage 4d Part 2 U3 fallback report. |
| `data-raw/alldata/stage4d-part2-manual-corrections-report.md` | tracked | Stage 4d Part 2 manual corrections report. |
| `data-raw/alldata/stage4d-part3-enrichment-report.md` | tracked | Stage 4d Part 3 enrichment report. |
| `data-raw/alldata/stage4d-part3-excluded-rows.csv` | tracked | The 28 hard-excluded rows from Stage 4d Part 3 (12 no_taxonomy species). |
| `data-raw/alldata/stage4e-aggregation-report.md` | tracked | Stage 4e aggregation audit report. |
| `data-raw/alldata/curated_cas_lookup.csv` | tracked | Stage 6 CAS lookup for curated sources (42 rows: anzg, ccme, aims, csiro chemicals mapped to casnumber_grouped). |
| `data-raw/alldata/species_resolution_curated.csv` | tracked | Stage 6 taxonomy cache for aims/csiro species (77 rows). Always read with `guess_max = Inf`. |
| `data-raw/alldata/stage6-integration-report.md` | tracked | Stage 6 integration audit report. |
| `data-raw/alldata/DATASET.R` | tracked | **Stage 7 output.** Authoritative rebuild script for `allchronic_data.rda`. Consolidates Stage 6 Phase 2 + Stage 7 logic inline. Run from repo root to rebuild the package data object from `alldata_integrated.csv`. |
| `data-raw/alldata/stage7-eligibility-report.md` | tracked | Stage 7 eligibility filter and build audit report. |

### Common schema (17 columns, `uncurated_raw_combined.csv`)

| # | Column | Description |
|---|---|---|
| 1 | source | "anztox", "wqbench", or "envirotox" |
| 2 | native_cas | CAS number as stored in the source, format-normalised only (no parent mapping) |
| 3 | casnumber_grouped | Parent CAS from master lookup, else native_cas |
| 4 | chemicalname_grouped | Parent name where mapped, else source chemical name |
| 5 | scientificname | Species scientific name as it appears in the source (the RAW name) |
| 6 | medium | "Freshwater", "Marine", or "Unknown" |
| 7 | test_class | "chronic", "subchronic", or "acute" |
| 8 | statistic_type | EC50, LC50, NOEC, NOEL, IC50 etc. Uppercase trimmed. NA where unavailable. |
| 9 | effect_category | Controlled vocabulary across all three sources: MORT, GRO, REP, IMM, DVP, HAT, PSE, POP, LUM, ABD, BEH, BCH, MOR. NA where unmappable. |
| 10 | duration_hours | Numeric test duration in hours. NA where not recoverable. |
| 11 | life_stage | Organism life stage. NA for envirotox (no field) and anztox 2000 rows. Placeholder values normalised to NA. |
| 12 | conc_value | Numeric concentration, no ACR conversion. |
| 13 | conc_unit | "ug/L" (anztox, envirotox) or "mg/L" (wqbench). |
| 14 | acr_eligible | TRUE where statistic_type %in% c("EC50","LC50","IC50"). NA where statistic_type is NA. |
| 15 | study_reference | Per-source audit trail string. |
| 16 | source_id | Source-specific row identifier (row_number()-based across all three sources). |
| 17 | acr_applied | FALSE for all rows (placeholder; ACR conversion applied in Stage 4e). |

### Additional columns in `uncurated_raw_dedup.csv` (Stage 4c outputs)

| # | Column | Description |
|---|---|---|
| 18 | within_source_duplicate | TRUE if row belongs to a within-source duplicate group on that source's richest available key (diagnostic only — no rows dropped) |
| 19 | dedup_retained | FALSE if row is a cross-source duplicate of a higher-priority source record; TRUE otherwise |
| 20 | priority_kept | TRUE if row is retained after ANZG chronic > subchronic > acute priority selection; FALSE if displaced; NA if not eligible (cross-source duplicate or NA test_class) |
| 21 | dedup_note | Character description of cross-source duplicate match where applicable |

### Additional columns in `uncurated_raw_dedup_enriched.csv` (Stage 4d Part 3 outputs)

| # | Column | Description |
|---|---|---|
| 22 | original_scientificname | The raw scientificname (audit copy; equals scientificname for non-synonym rows) |
| 23 | accepted_name | **The authoritative species identifier for Stage 4e aggregation.** Synonym-unified accepted name from WoRMS/GBIF where available; raw scientificname otherwise. |
| 24 | synonym_unified | Logical; TRUE where accepted_name != original_scientificname (46,826 rows) |
| 25 | kingdom | Resolved taxonomic kingdom |
| 26 | phylum | Resolved taxonomic phylum |
| 27 | class | Resolved taxonomic class (also used as `majorgroup` — see col 30) |
| 28 | order_taxon | Resolved taxonomic order (named order_taxon to avoid clashing with base R `order()`) |
| 29 | family | Resolved taxonomic family |
| 30 | genus | Resolved taxonomic genus |
| 31 | majorgroup | Equals `class`. Used by Stage 4e/Stage 7 eligibility checks. |
| 32 | taxonomy_provenance | One of: worms_full, gbif_full, ambiguous_partial, source_native_fallback, manual_genus_fallback. (no_taxonomy rows hard-excluded.) |
| 33 | resolution_status | Stage 4d Part 2 resolution status (exact_filtered, exact_unaccepted_filtered, fuzzy_filtered, ambiguous_after_filter, genus_resolved, gbif_resolved, unresolved) |

### Schema for `uncurated_raw_aggregated.csv` (Stage 4e output)

One row per `casnumber_grouped × accepted_name × medium` combination. The per-row
dedup audit columns (within_source_duplicate, dedup_retained, priority_kept,
dedup_note, source_id, acr_applied, study_reference) are not meaningful at
the aggregated level and are dropped. Provenance is summarised instead.
20 columns total (19 after initial Stage 4e run; `any_conc_flagged` added
by the Stage 4e concentration plausibility patch).

| # | Column | Description |
|---|---|---|
| 1 | casnumber_grouped | Parent CAS (the aggregation key; replaces native_cas from this stage onward) |
| 2 | chemicalname_grouped | Parent chemical name |
| 3 | accepted_name | Synonym-unified species name (the aggregation key) |
| 4 | medium | "Freshwater", "Marine", or "Unknown" |
| 5 | conc_ug_L | Aggregated concentration in µg/L (the species-level minimum after Steps 1–3) |
| 6 | majorgroup | Resolved taxonomic class (used for eligibility checks in Stage 7) |
| 7 | kingdom | Resolved taxonomic kingdom |
| 8 | phylum | Resolved taxonomic phylum |
| 9 | class | Resolved taxonomic class (= majorgroup) |
| 10 | order_taxon | Resolved taxonomic order |
| 11 | family | Resolved taxonomic family |
| 12 | genus | Resolved taxonomic genus |
| 13 | taxonomy_provenance | Provenance of the taxonomic resolution |
| 14 | n_records | Number of input records that contributed to the aggregated value |
| 15 | sources_contributing | Comma-separated list of source(s) that contributed records |
| 16 | any_acr_applied | TRUE if any contributing record had ACR conversion applied |
| 17 | any_conc_flagged | TRUE if the aggregated value is derived from soft-flagged concentration records only (no ok-range records existed in the contributing group); indicates the species value should be treated with caution |
| 18 | geomean_flagged | TRUE if any geomean step used min() instead of geometric mean due to >1 order of magnitude spread within the group |
| 19 | lifestage_mixed | TRUE if the aggregated value combines both NA and non-NA life_stage records (audit flag) |
| 20 | duration_mixed | TRUE if the aggregated value combines both NA and non-NA duration_hours records (audit flag) |

### Schema for `allchronic_data` (Stage 7 output — the package data object)

One row per `casnumber_grouped × accepted_name × medium` combination, covering
all retained sources (curated and uncurated). Columns use PascalCase per ssddata
package convention. `majorgroup` is dropped (redundant with `Class`).

| # | Column | Source field | Description |
|---|---|---|---|
| 1 | Species | accepted_name | Synonym-unified accepted species name |
| 2 | Conc | conc_ug_L | Aggregated toxicity concentration in µg/L |
| 3 | Chemical | chemicalname_grouped | Parent chemical name |
| 4 | CAS | casnumber_grouped | Parent CAS number |
| 5 | Medium | medium | Test medium; ANZG freshwater variants preserved as-is |
| 6 | Source | source | Pipeline source group: "anzg", "ccme", "aims", "csiro", or "uncurated". The three uncurated sources (anztox, wqbench, envirotox) are collapsed to "uncurated" by the Stage 6 Phase 2 integration step; per-source breakdown is in SourcesContributing |
| 7 | Class | class | Resolved taxonomic class (= majorgroup); used for ≥4-groups sufficiency check; NA for ANZG/CCME rows |
| 8 | Kingdom | kingdom | Resolved taxonomic kingdom; NA for ANZG/CCME rows |
| 9 | Phylum | phylum | Resolved taxonomic phylum; populated where available for ANZG/CCME |
| 10 | Order | order_taxon | Resolved taxonomic order; NA for ANZG/CCME rows |
| 11 | Family | family | Resolved taxonomic family; NA for ANZG/CCME rows |
| 12 | Genus | genus | Resolved taxonomic genus; populated where available for ANZG/CCME |
| 13 | TaxonomyProvenance | taxonomy_provenance | Resolution provenance: worms_full, gbif_full, ambiguous_partial, source_native_fallback, manual_genus_fallback, curated_source |
| 14 | NRecords | n_records | Raw records contributing to aggregated value; 1 for all curated rows |
| 15 | SourcesContributing | sources_contributing | Comma-separated contributing source names |
| 16 | AnyAcrApplied | any_acr_applied | TRUE if ACR conversion applied to any contributing record; FALSE for curated rows |
| 17 | AnyConcFlagged | any_conc_flagged | TRUE if aggregated value derived from soft-flagged records only; FALSE for curated rows |
| 18 | GeomeanFlagged | geomean_flagged | TRUE if min() used instead of geomean due to >1 OOM spread; FALSE for curated rows |
| 19 | LifestageMixed | lifestage_mixed | TRUE if NA and non-NA life_stage combined in aggregation; FALSE for curated rows |
| 20 | DurationMixed | duration_mixed | TRUE if NA and non-NA duration_hours combined in aggregation; FALSE for curated rows |

### Key reference documents

- `vignettes/ANZTOX_data_processing.qmd` — documents the anztox data processing
  workflow.
- `vignettes/cas_parent_lookup_build.qmd` — documents the Stage 2 CAS parent
  lookup build process.
- `vignettes/endpoint_2016_to_2000_lookup_build.qmd` — documents the endpoint
  lookup build.
- `vignettes/alldata_pipeline.qmd` — **the primary methodological vignette for
  the alldata pipeline** (Stages 1–7). This is the living document for the
  pipeline description. See Section 9 for update instructions.
- `README.Rmd` — general package overview.
- `data-raw/anztox/speciation_convention.md` — speciation rules.
- `scripts/speciation_policy_extensions.md` — extended speciation policy decisions.
- `scripts/stage3-deferred-decisions.md` — deferred decisions for Stage 6.
- `scripts/stage4a-pipeline-audit.md` — full pipeline audit including
  supplementary DB query findings.
- `scripts/stage4c-schema-inventory.md` — targeted schema inventory.
- `scripts/stage4c-deferred-decisions.md` — deferred decision log for Stage 4c.

### ANZG method reference

The authoritative method for deriving ANZG guideline values is Warne et al. 2025
(shared as a PDF in the Claude project). Key sections for this workflow:
- Section 3.4.4: procedure for obtaining one toxicity value per species —
  geometric mean within endpoint × statistic type × life stage × duration
  combinations; lowest value within each endpoint; lowest value across endpoints.
  Geometric means must NOT be calculated across different statistic types, life
  stages, or test durations.
- Section 3.4.2.2: ACR = 10 default for acute-to-chronic conversion; only
  LC/EC/IC50 acute values may be converted — acute NOECs/LOECs must NOT be used.
- Table 1: acute vs chronic classification by organism type, life stage, endpoint,
  duration.
- Table 5: taxonomic group assignments for the ≥5 species from ≥4 groups
  sufficiency threshold (NOTE: this pipeline uses `class` directly instead of
  ANZG Table 5 groups — see Key Design Decisions).

### Environment note

The anztox pipeline requires a live connection to the `infogathering` PostgreSQL
instance, which is only available from Windows Positron (not WSL).
`scripts/stage4b-extract.R` and the anztox parts of Stage 4d Part 1.5 must be
run from Windows Positron. All other Stage 4+ scripts can run from WSL or
Windows. This split is documented in each script's header comment block.

---

## 7. Active Development — Issue #33

**Issue:** Allow `ssd_data_sets(set = "all_chronic")` to return an aggregated,
deduplicated dataset across all sources.

**GitHub context:**
- PR #43 (`add_media_wqbench`) is not yet merged but the current working branch
  is based off it. `data/wqbench_data.rda` already reflects PR #43's output.
  PR #43 must be merged before this branch merges to main.
- Issue #34 (ccme medium assignment) — pending confirmation: Phase 1 schema
  inventory found `ccme_data` Medium = `"Freshwater"` for all rows, but it is
  not yet confirmed whether this is correct or a data error. Issue #34 remains
  open. For the alldata pipeline, ccme is treated as Freshwater pending
  confirmation (see Stage 6 design decisions).

### Staged plan

Stages 1–7 are complete. The pipeline is functionally complete.

**Note on Stage 4d/4e re-ordering:** In an earlier version of the plan, Stage 4d
was aggregation and Stage 4e was species synonym resolution. This was reversed
during Stage 4d planning (2026-06-24): species name harmonisation must happen
*before* aggregation, because the geomean groups by species — if `Daphnia magna`
appears under a synonym in one source and the accepted name in another, they
will be treated as two distinct species. Stage 4d is now species resolution +
majorgroup derivation; Stage 4e is aggregation.

**Note on Stage 5:** Stage 5 (units normalisation) was folded into Stage 4e.
The wqbench mg/L → µg/L conversion is applied before aggregation in
`scripts/stage4e-aggregate.R`. Stage 5 as a standalone stage no longer exists.
The Stage 5 section in `vignettes/alldata_pipeline.qmd` documents this and
should eventually be removed or collapsed.

---

#### Complete

**Stage 1 — Schema audit**
Prompt log: `prompts/stage1-schema-audit.md`
Output: `scripts/stage1-schema-audit.md`

---

**Stage 2 — CAS / chemical name alignment**
Complete through Stage 2e.

- `data-raw/cas_parent_lookup_all.csv`: master lookup, 587-row expanded
  population merged in via `scripts/stage2e-merge-to-master.R`.
- Total UNCERTAIN rows: 18 (require human domain expert review before Stage 6).
- Vignette: `vignettes/cas_parent_lookup_build.qmd`

---

**Stage 3 — Media assignment audit**
Complete.

- All sources have a documented medium value. ccme is interim "Unknown"
  (pending Issue #34). envirotox is final "Unknown".

---

**Stage 4a — Pipeline audit (uncurated sources)**
Complete.

- `scripts/stage4a-pipeline-audit.md` — full audit including supplementary
  DB query section.

---

**Stage 4b — Extract filtered unaggregated records (uncurated sources)**
Complete. Revised after Stage 4c Part 1 schema inventory to include richer
fields (statistic_type, duration_hours, effect_category, life_stage,
study_reference) required by the Section 3.4.4 aggregation.

- `scripts/stage4b-extract.R` — single script covering all three sources
  (Windows Positron + live DB required).
- `scripts/stage4b-effect-category-fixup.R` — post-hoc correction for
  envirotox effect_category mappings.
- Source counts: anztox 15,667 / wqbench 361,782 / envirotox 72,439.

Decisions implemented: A1 (anztox concentrationused = µg/L), B1 (632
Chronic QSAR rows dropped), C1 (DATASET.R typo fix; intercept replicated),
D-E (effectused_id for 2000, effect_id for 2016), D-F (acr_eligible from
statistic_type).

---

**Stage 4c Part 1 — Schema inventory for duplicate detection**
Complete. Identified the missing fields that drove Stage 4b's revision.

---

**Stage 4c Part 2 — Cross-source duplicate detection and ANZG priority selection**
Complete.

- `scripts/stage4c-dedup.R` — four-phase pipeline.
- During Phase 1, fixed wqbench source_id from (species, cas) pair to
  row_number().
- Deferred decision resolved: 1% Phase 1 threshold downgraded to 50%
  (Option 1, see `scripts/stage4c-deferred-decisions.md`). Empirical
  within-source rates (anztox 9.2%, wqbench 25.1%, envirotox 0.56%) are
  intrinsic to source data granularity, not data-quality defects.

Decisions implemented: G2 (flag-and-retain), H2 (native_cas grouping key),
I2 (dedup before priority), J1 (0.1% tolerance on conc), J2b (strict NA),
J3a (strict medium).

---

**Stage 4c Part 3 — effect_category harmonisation**
Complete.

- `scripts/stage4c-effect-category-fixup.R` harmonised wqbench English-word
  effect_category values to the controlled vocabulary used by anztox/envirotox.
- `scripts/stage4c-dedup.R` re-run with effect_category restored to the
  cross-source key.
- Final clean subset: 381,410 rows (the input to Stage 4d).

---

**Stage 4d Part 1 — Species name resolution diagnostic**
Complete.

- `scripts/stage4d-species-resolution-diagnostic.R` — baselined WoRMS/GBIF
  resolution on raw species names. Identified 1,079 WoRMS-ambiguous species
  (40.9% of rows), which drove the decision to proceed with context-aware
  querying.

---

**Stage 4d Part 1.5 — Source-native taxonomy extraction**
Complete.

- `scripts/stage4d-taxonomy-extract.R` — extracted source-native taxonomy
  from anztox DB, wqbench SQLite, and envirotox xlsx taxonomy sheet.
- Output: `species_source_taxonomy.csv` (6,198 rows).

---

**Stage 4d Part 2 — Context-aware WoRMS resolution**
Complete.

- `scripts/stage4d-context-aware-resolution.R` — queried WoRMS with
  source-native taxonomic context. 99.22% of rows (4,200 of 4,348 species)
  resolved to a usable level.
- 254 synonym groups identified, affecting 130,124 rows (34% of final
  clean subset).
- Two important deviations from literal spec, both kept and documented:
  1. Exact-name-priority pre-filter (WoRMS fuzzy=TRUE was conflating
     species and subspecies records).
  2. GBIF kingdom-rank floor (genus-or-finer required for "resolved").

Decisions implemented: P3 (single-source taxonomy pooling), C (tiered
filter fallback), R1 (Genus sp. resolved at genus level, uncurated only).

---

**Stage 4d Part 2 fixup — U3 source-native fallback**
Complete.

- `scripts/stage4d-part2-source-native-fallback.R` — applied source-native
  fallback to the 148 problem species. Class-level coverage rose from
  94.9% to 97.9%.
- Added `taxonomy_provenance` column with values: worms_full (3,227),
  gbif_full (973), ambiguous_partial (84), source_native_fallback (49),
  no_taxonomy (15).

Decision implemented: U3 (partial use; accepted_name not fabricated;
hierarchy only).

---

**Stage 4d Part 2 fixup — manual name corrections**
Complete.

- `scripts/stage4d-part2-manual-name-corrections.R` — three corrections
  applied: Illybius → Ilybius augustior (typo), Salmoides micropterus →
  Micropterus salmoides (reversal), Sialis flavilatera resolved at genus
  via GBIF (manual_genus_fallback). no_taxonomy bucket reduced from
  15 to 12 species.
- Identified the readr::read_csv() trap (sparse columns) — documented
  in Section 5 as a project-wide convention.

---

**Stage 4d Part 3 — Apply resolution, derive majorgroup, prepare for aggregation**
Complete.

- `scripts/stage4d-part3-apply-resolution.R` — applied synonym unification,
  joined taxonomy, derived majorgroup = class, hard-excluded the 12
  no_taxonomy species (28 rows).
- Output: `data-raw/alldata/uncurated_raw_dedup_enriched.csv` (449,860 rows
  × 33 cols, ~228 MB, untracked).
- Final clean subset (dedup_retained & priority_kept & not excluded):
  381,382 rows (= 381,410 from Stage 4c Part 3 minus 28).
- Synonym unification: 46,826 rows updated to use accepted_name as the
  species identifier (different from the 130,124 "rows affected" figure
  in Part 2 — Part 2 counted all rows in synonym groups; this counts
  rows where the name actually changed).
- Taxonomy coverage in the enriched file:
  - Kingdom/phylum: ~100% (5 NA rows from the Sialis genus-only case)
  - Class (= majorgroup): 99.07%
  - Family: 99.98%
  - Genus: 99.88%
- 115 distinct majorgroup values present. Top values: Teleostei,
  Branchiopoda, Malacostraca, Insecta, Chlorophyceae.
- Known data quality items carried into Stage 4e:
  - NA effect_category: 23,567 rows in final clean subset
  - NA duration_hours: 199 rows in final clean subset
  - "Not stated" as a class/majorgroup value: 4 rows (literal string,
    not NA — must be coerced to NA at Stage 4e start)
  - "Genus sp." entries at genus rank: treated as legitimate species rows
    per decision R1

Prompt log: `prompts/stage4d.md`

**Stage 4e — Aggregation (Section 3.4.4)**
Complete.

- `scripts/stage4e-aggregate.R` — implements Section 3.4.4 aggregation.
- Input: `uncurated_raw_dedup_enriched.csv` (449,860 rows × 33 cols).
- Output: `uncurated_raw_aggregated.csv` (62,416 rows × 19 cols, ~14 MB,
  untracked).
- Row counts through the pipeline:
  - After dedup/priority filter: 381,382
  - Dropped NA effect_category: 23,567 (6.2%)
  - Dropped acute-non-eligible: 66,183 (17.4%)
  - Entering aggregation: 291,632
  - ACR-converted (÷10): 146,786 (50.3% of entering rows)
  - Step 1 groups (geomean key): 138,174 (66.9% singletons)
  - Step 2 groups (endpoint minimum): 78,164
  - Output rows: 62,416
- Output covers 5,700 distinct chemicals and 3,763 distinct species.
- Medium breakdown: Freshwater 31,595 / Marine 8,355 / Unknown 22,466.
- 73.7% of output rows have `any_acr_applied == TRUE` — driven by
  wqbench's composition (almost entirely acute LC/EC50 data).
- 6.87% of output rows have `geomean_flagged == TRUE`.
- `lifestage_mixed`: 4,186 output rows; `duration_mixed`: 18 output rows.
- Known data quality item: 12 output rows have `conc_ug_L` < 10⁻⁶ µg/L
  (physically implausible, arising from near-zero source concentrations
  passed through the geomean min() rule). **Resolved by Stage 4e
  concentration plausibility patch** — see patch entry below.
- Final output after patch: 62,410 rows × 20 cols, ~14.4 MB.

Decisions implemented: D1 (NA life_stage as distinct level), D2 (geomean
min() when spread >10×), D3 (eligibility check deferred to Stage 7), D4
(provenance summary columns), D5 (NA duration_hours as distinct level).

Prompt log: `prompts/stage4e.md`
Audit report: `data-raw/alldata/stage4e-aggregation-report.md`

---

**Stage 4e patch — Concentration plausibility filter**
Complete (2026-06-26).

Pre-aggregation concentration plausibility check added to
`scripts/stage4e-aggregate.R`. Thresholds:

- `LOWER_HARD = 1e-5 µg/L` — hard exclude
- `LOWER_SOFT = 1e-3 µg/L` — soft flag, retain
- `UPPER_SOFT = 1e6 µg/L` — soft flag, retain
- `UPPER_HARD = 1e8 µg/L` — hard exclude

Logic: geometric mean computed over ok-range records only; soft-flagged
records used as fallback only when no ok-range records exist in a group.
New output column `any_conc_flagged` (logical) — TRUE where the aggregated
value derives from soft-flagged records only.

Results:
- Hard-excluded: 57 rows (51 low_hard, 6 high_hard) — all from wqbench.
  CAS 70288867 (*Daphnia magna* / *Ceriodaphnia dubia* NOEC/LOEC at exactly
  1×10⁻⁶ µg/L) accounts for many of the low_hard rows — likely a systematic
  unit error in the source for that chemical.
- Soft-flagged retained: 3,398 rows (549 low_soft, 2,849 high_soft).
- Soft-only fallback groups: 1,568 — contributing to 899 output rows with
  `any_conc_flagged == TRUE` (1.44% of output).
- Final output: 62,410 rows (reduced from 62,416; 6 species × chemical ×
  medium combinations lost because their only source record was hard-excluded).
- Output schema: 20 columns.
- All 7 validation checks passed.

Implementation note: validation check 6 uses a relative tolerance
`LOWER_HARD * (1 - 1e-9)` due to IEEE 754 rounding in `exp(log(1e-5))` —
documented in the code and inconsequential for downstream use.

---

**Stage 6 — Integration with curated sources and ANZG exclusion rule**
Complete (2026-06-26).

- `scripts/stage6-phase1-cas-lookup-draft.R` — schema inventory, excluded column, curated CAS lookup.
- `scripts/stage6-phase2-integrate.R` — **SUPERSEDED** by `data-raw/alldata/DATASET.R`
  (Stage 7). This file has been deleted from the repo.
- Output: `data-raw/alldata/alldata_integrated.csv` (59,986 rows × 24 cols, ~14.3 MB, untracked).
- Source breakdown (retained): anzg=592 / ccme=98 / aims=20 / csiro=60 / uncurated=59,216.
- Medium breakdown: Freshwater=29,901 / Marine=7,581 / Unknown=22,466 / ANZG variants=37.
- 17 aims/csiro species unresolved (misspellings in source data) — retained with NA taxonomy fields.
- All 7 validation checks PASSED.
- **Post-completion fix**: initial run used stale `anzg_data.rda` (before Navicula sp. 1/2 rename);
  script also incorrectly contained a within-source ANZG aggregation block (design decision is
  no aggregation for anzg/ccme). Both fixed: aggregation block removed; script rerun against
  rebuilt `.rda`. Row count corrected from 59,985 → 59,986.

Prompt log: `prompts/stage6.md`
Audit report: `data-raw/alldata/stage6-integration-report.md`

Key design decisions confirmed for Stage 6 planning:

**Source treatment:**
- **anzg and ccme**: used wholesale as-is — their datasets are the
  authoritative record and replace all other sources' data for the
  chemical × medium combinations they cover. No taxonomy harmonisation,
  no Section 3.4.4 aggregation, no concentration plausibility filter
  applied. Precedent: wqbench shiny app takes the same approach.
- **aims and csiro**: curated but not jurisdictionally authoritative.
  Species names run through WoRMS/GBIF taxonomy harmonisation (same
  approach as Stage 4d) before aggregation. Section 3.4.4 aggregation
  applied where a species appears more than once for a chemical × medium.
  Note: the existing `.apply_dedup()` function in `get_ssddata.R` groups
  by `Species_Genus` concatenated — Stage 6 must be consistent with this
  behaviour (domain field such as temperate/tropical is NOT part of the
  grouping key; same-species records from different domains are averaged).
- **Consolidated uncurated** (`uncurated_raw_aggregated.csv`): lowest
  priority; used where no curated source covers the chemical × medium.

**Deduplication / exclusion hierarchy:**
- anzg: exclude ALL other sources' data for each chemical × anzg medium
  combination (broad matching across all five anzg freshwater variants).
  **ANZG freshwater medium variants must NEVER be collapsed** — the five
  variants (Freshwater, Soft freshwater, Moderate freshwater, Hard freshwater,
  and nitrate variants) are distinct and must be preserved as-is in all outputs.
- ccme: `ccme_data` Medium = `"Freshwater"` for all rows (observed in Phase 1;
  pending Issue #34 confirmation). ccme is treated as Freshwater in the pipeline.
  Exclusion follows the simple priority hierarchy: ccme freshwater data for a
  chemical excludes aims, csiro, and uncurated freshwater data for the same
  chemical.
- Preference order (full): `anzg > ccme > aims > csiro > uncurated`. Applied
  at the `casnumber_grouped × medium` level — if a higher-priority source has
  ANY data for a chemical × medium combination, ALL rows from lower-priority
  sources for that same combination are excluded (not just species-level
  overlaps).
- aims > csiro > consolidated uncurated: standard preference order for
  remaining duplicates after anzg/ccme exclusion.

**CAS lookup pre-processing:**
- Add `excluded` column to `data-raw/cas_parent_lookup_all.csv`:
  `excluded = TRUE` for UNCERTAIN rows (`human_checked == "n"` AND
  UNCERTAIN flag in `match_rationale`); `excluded = FALSE` for all
  others. Stage 6 joins filter to `excluded == FALSE`. This is a tracked
  edit to the lookup file (small; safe to commit).

**Taxonomy:**
- anzg and ccme: trusted as-is, no WoRMS/GBIF resolution.
- aims and csiro: run through the same WoRMS/GBIF resolution pipeline
  as Stage 4d before aggregation.

**Aggregation:**
- aims and csiro: apply Section 3.4.4 aggregation where needed,
  consistent with `.apply_dedup()` grouping by Species × Genus.
- anzg and ccme: no aggregation (used as-is).

**Concentration plausibility filter:**
- NOT applied to curated source records (anzg, ccme, aims, csiro).
- Applied as an audit check only: report how many curated records would
  have been flagged or excluded if the Stage 4e thresholds were applied,
  but do not actually exclude or flag them.

**Output schema:**
- As rich as possible. Provenance flag columns (`any_acr_applied`,
  `any_conc_flagged`, `geomean_flagged`, `lifestage_mixed`,
  `duration_mixed`) are retained. Curated source records receive
  sensible fill values: `any_acr_applied = FALSE`, `any_conc_flagged
  = FALSE`, `geomean_flagged = FALSE`, `lifestage_mixed = FALSE`,
  `duration_mixed = FALSE`, `n_records = 1`,
  `sources_contributing = <source name>`.

---

#### Complete (Stage 7)

**Stage 7 — Sufficiency filtering, DATASET.R consolidation, wire up `ssd_data_sets()`**
Complete (2026-06-26).

- `data-raw/alldata/DATASET.R` — 303 lines. Consolidates Stage 6 Phase 2 + Stage 7 inline.
  Skips Stage 6 Phase 2 if `alldata_integrated.csv` already exists on disk (incremental rebuild).
- `scripts/stage6-phase2-integrate.R` — deleted via `git rm` (superseded by DATASET.R).
- `R/get_ssddata.R` — `"alldata"` branch replaced by `"all_chronic"`; `known_aggregated`
  updated; `cas_lookup` parameter deprecated.
- `R/allchronic_data.R` — full roxygen2 `@format` documentation; `devtools::document()`
  regenerated `man/allchronic_data.Rd` and `man/ssd_data_sets.Rd`.
- `data/allchronic_data.rda` — **42,252 rows × 20 cols, ~473 KB**.
  1,073 distinct chemicals, 3,647 distinct species.
- `data-raw/alldata/stage7-eligibility-report.md` — audit report.

Phase 1 audit findings:
- Input: 59,986 rows × 24 cols. 3 pipeline-only columns (`Group`, `Chemical`,
  `exclusion_flag`) present in `alldata_integrated.csv` and dropped at Stage 7.
- `class` vs `majorgroup`: 0 mismatches — identical for all uncurated rows.
- NA patterns by source (as expected):
  - ANZG: 100% NA for `class`/`kingdom` — curated, no WoRMS resolution applied.
  - CCME: `majorgroup`/`class` populated from source `Group` field (not WoRMS).
  - AIMS: ~5% NA class.
  - CSIRO: ~28% NA class (17 NA-Species chlorine×marine rows retained with NA taxonomy).
  - Uncurated: ~1.4% NA class.

Sufficiency filter results (uncurated rows only):
- 10,078 `casnumber_grouped × medium` combinations assessed.
- 1,880 passing (18.7%) — both ≥5 species AND ≥4 distinct non-NA class values.
- 8,198 failing — 17,734 uncurated rows dropped.
- Curated rows: 770 retained unchanged (anzg=592, ccme=98, aims=20, csiro=60).
- Total rows in `allchronic_data`: 42,252.

**Schema note — `Source` column:** Uncurated rows carry `Source = "uncurated"` (not
individual source names). The Stage 6 Phase 2 integration collapsed anztox, wqbench,
and envirotox into a single "uncurated" label. Per-source breakdown is available in
`SourcesContributing`. The five distinct `Source` values are: anzg, ccme, aims,
csiro, uncurated.

All 6 validation checks PASSED.

Prompt: `prompts/stage7.md`
Audit report: `data-raw/alldata/stage7-eligibility-report.md`

Key design decisions confirmed for Stage 7 (see also Key Design Decisions section):
- `allchronic_data` — package data object name.
- `ssd_data_sets(set = "all_chronic")` — user-facing set name.
- Sufficiency filter: uncurated rows only; ≥5 species AND ≥4 distinct non-NA `class`
  values per `casnumber_grouped × medium` combination.
- ANZG medium variants never collapsed.
- `majorgroup` column dropped from output (redundant with `Class`).
- PascalCase column naming throughout.

---

#### Pending

**Stage 8 (optional) — Species name cleaning vignette**

**Vignette cleanup (deferred):** The Stage 5 section in
`vignettes/alldata_pipeline.qmd` documents a stage that no longer exists as a
standalone step. It should be removed or collapsed in a future editing pass.

---

### Key design decisions

- `anon_` datasets are excluded from `all_chronic` (no chemical name).
- Curated sources (aims, csiro, ccme, anzg) are treated separately from
  uncurated sources, which are consolidated first.
- Cross-source deduplication occurs BEFORE ANZG priority selection
  (Decision I2). This ensures chronic data from a lower-priority source
  is not discarded in favour of acute data from a higher-priority source.
- Species taxonomy resolution happens BEFORE aggregation (Stage 4d before
  Stage 4e). Synonym unification is essential because the geomean groups
  by species.
- **Taxonomic groups for eligibility are defined as `class` (resolved WoRMS/GBIF
  taxonomic class), NOT ANZG Table 5 groups.** This is a deliberate deviation
  from ANZG procedure — simpler, reproducible, consistent with wqbench's
  `filter(n_distinct(class) >= 4)` convention. These data are for methodology
  testing only, not for official ANZG guideline derivation.
- **`majorgroup` = `class` throughout intermediate files.** The `majorgroup`
  column is an alias for `class` in Stages 4–6 intermediate files. It is dropped
  in the final `allchronic_data` object (redundant with `Class`).
- **The authoritative species identifier for Stage 4e aggregation is
  `accepted_name`, NOT `scientificname`.** Stage 4d's synonym unification
  collapses 46,826 rows under `accepted_name` that would have been split
  across multiple species under `scientificname`.
- "Genus sp." handling is asymmetric between uncurated and curated
  pipelines. Uncurated (Stage 4d): resolved at genus level. Curated
  (Stage 6/7): retained as distinct species per curators' judgement.
- The existing `anztox_data` `.rda` and its `DATASET.R` are not modified
  in this branch beyond the `=>` parse-error fix. Any deeper issues are
  filed as GitHub issues.
- **ANZG Medium field has five variants — do NOT collapse these, ever.**
  Variants: Freshwater, Soft freshwater, Moderate freshwater, Hard freshwater,
  and nitrate-specific variants. These are preserved as-is in all intermediate
  files and in the final `allchronic_data` object.
- envirotox medium is final "Unknown".
- ccme medium is "Freshwater" for all rows (observed in Phase 1 schema inventory; pending Issue #34 confirmation).
- Stage 6 preference order: `anzg > ccme > aims > csiro > uncurated`. Exclusion operates at `casnumber_grouped × medium` level — presence of any data from a higher-priority source for a chemical × medium excludes ALL rows from lower-priority sources for that combination.
- Concentration units target: µg/L. wqbench is in mg/L; conversion folded
  into Stage 4e before aggregation.
- anztox `concentrationused` units: confirmed µg/L for toxicityvalue2000
  (86%); assumed µg/L for toxicityvalue2016 (~14%, flagged via
  `source_dataset`).
- "Chronic QSAR" anztox rows (632): dropped deliberately.
- `acr_eligible` derived from `statistic_type %in% c("EC50","LC50","IC50")`.
- Acute records that are not acr_eligible (acute NOECs, LOECs) are
  dropped at Stage 4e — cannot be ACR-converted, cannot enter the
  chronic-equivalent aggregation per Warne et al. 2025 Section 3.4.2.2.
- anztox statistic_type: `effectused_id` for 2000 rows, `effect_id` for
  2016 rows.
- wqbench intercept: `ecotox_ascii_12_11_2025.rds` loaded before
  `wqb_aggregate()`. wqbench's 25.1% within-source duplicate rate is
  intrinsic to the package's output structure, not a defect.
- envirotox intercept: statistic/type/solubility filter reproduced from
  DATASET.R. `original.CAS` used as join key.
- `native_cas` retained for within-source/cross-source dedup;
  `casnumber_grouped` for Stage 4e aggregation.
- Cross-source dedup key: `native_cas × scientificname_norm × medium ×
  statistic_type_norm × effect_category × duration_hours (exact) ×
  conc_ug_L (0.1% tolerance)`.
- Life stage retained where available (wqbench; anztox 2016) but excluded
  from cross-source dedup key. Included in Stage 4e grouping key; NA
  treated as a distinct level (same policy as duration_hours).
- NA `duration_hours` (199 rows in final clean subset): retained as a
  distinct group level in Stage 4e, not dropped. Analogous to NA life_stage
  treatment. `duration_mixed` flag set where NA and non-NA duration combine
  at the within-effect_category minimum step.
- study_reference retained per-source as audit; not a cross-source join key.
- True duplicate preference order: wqbench > anztox > envirotox.
- Stage 6 deduplication preference: `anzg > ccme > aims > csiro > anztox >
  wqbench > envirotox`.
- Media sufficiency threshold: ≥5 species from ≥4 distinct `class` values
  (non-NA). Applied to uncurated rows only at Stage 7. Curated sources bypass.
- effect_category controlled vocabulary: MORT, GRO, REP, IMM, DVP, HAT,
  PSE, POP, LUM, ABD, BEH, BCH, MOR.
- Stage 4d Part 2 taxonomy pooling (P3): single-source pooling with
  wqbench > envirotox > anztox tiebreaker; fields NOT mixed across sources.
- Stage 4d Part 2 exact-name-priority pre-filter (deviation): promote unique
  exact species name match when WoRMS returns species + subspecies records
  with identical taxonomy.
- Stage 4d Part 2 GBIF rank floor: genus-or-finer required for "resolved".
- Stage 4d Part 2 fixup (U3): problem species use Part 1.5 source-native
  taxonomy where available. `accepted_name` NEVER fabricated.
- `taxonomy_provenance` values: worms_full, gbif_full, ambiguous_partial,
  source_native_fallback, manual_genus_fallback, curated_source. (no_taxonomy
  hard-excluded at Stage 4d Part 3.)
- Stage 4e geomean >1 OOM rule: if max/min > 10 within a group, use min()
  and set `geomean_flagged = TRUE` (conservative; preserves audit trail).

### Deferred decisions

- **ccme medium assignment — pending confirmation**: Phase 1 schema inventory
  found `ccme_data` Medium = `"Freshwater"` for all rows. Treated as Freshwater
  in the pipeline pending Issue #34 confirmation.
- **PR #43 (`add_media_wqbench`) — resolved**: Merged to main.
- **csiro chlorine/marine — excluded from alldata**: `csiro_chlorine_marine`
  is an acute dataset and is excluded from the alldata pipeline. The 30
  NA-Species rows identified in Phase 1 reinforced this decision. Rationale
  recorded for future reference: if an `all_acute` pipeline is built,
  `csiro_chlorine_marine` would be a candidate for inclusion.
- **anzg boron Navicula sp. duplicate — resolved**: Phase 1 identified two
  rows for boron/freshwater labelled `"Navicula sp."`. Confirmed from the ANZG
  boron technical brief as two distinct unidentified species. Relabelled as
  `"Navicula sp. 1"` and `"Navicula sp. 2"` in the raw anzg source data;
  `anzg_data.rda` rebuilt. No pipeline change required.
- **UNCERTAIN CAS rows — resolved**: The 18 UNCERTAIN rows in
  `data-raw/cas_parent_lookup_all.csv` (identified by `human_checked == "n"`
  and UNCERTAIN flag in `match_rationale`) are excluded from the pipeline.
  The rows are retained in the lookup file with `excluded = TRUE` (added at
  Stage 6 pre-processing; all other rows get `excluded = FALSE`).
  Stage 6 joins filter to `excluded == FALSE` before applying the parent-CAS
  mapping.

### Future enhancements (deferred, not blocking current branch)

- **Post-pipeline data deposit (after Stage 7 complete)**: Deposit the
  unaggregated enriched dataset (`uncurated_raw_dedup_enriched.csv`) and
  the aggregated output (`uncurated_raw_aggregated.csv`) as citable research
  artefacts. Recommended approach: Zenodo (permanent DOI, 50 GB limit) as
  the primary deposit; `piggyback` GitHub Release asset as a convenience
  download path for R users. Add a `ssd_download_alldata_raw()` helper
  function to the package that fetches the file via `piggyback`. Document
  the Zenodo DOI in the package vignette and README. Pre-conditions: (1)
  confirm redistribution licence terms for anztox, wqbench, and envirotox
  source data; (2) pipeline stable through Stage 7; (3) any institutional
  data governance requirements checked.
- **`all_acute` pipeline**: An acute equivalent of the `all_chronic` pipeline
  is a potential future addition. `csiro_chlorine_marine` would be a candidate
  for inclusion. Would follow the same DATASET.R + `allacute_data` pattern.
- **Pipeline script consolidation (Stages 1–4)**: Stages 1–4 scripts live in
  `scripts/` and are not consolidated into DATASET.R format. A future
  refactoring task would bring these into the `data-raw/` structure. Not
  currently blocking.
- **Vignette Stage 5 section**: The Stage 5 section in
  `vignettes/alldata_pipeline.qmd` documents a stage that no longer exists as
  a standalone step (the mg/L conversion was folded into Stage 4e). Should be
  removed or collapsed in a future editing pass.
- wqbench SQLite database (`ecotox_ascii_*.sqlite`) may retain per-row
  identifiers recoverable via a join. Could improve wqbench within-source
  duplicate detection in a future stage.
- 175 anztox 2016 effect_category NA rows (mostly "PGR") could be resolved
  with domain expertise if it becomes available.
- 40 species with cross-source kingdom/phylum disagreement (identified
  in Stage 4d Part 1.5) — most are classification-scheme variants.
- Full `git filter-repo` purge of large intermediate CSVs from remote
  history.
- 12 no_taxonomy species (28 rows) hard-excluded at Stage 4d Part 3 —
  see `stage4d-part3-excluded-rows.csv` for the audit list.

---

## 8. Prompt Log

Session logs for this project are in `prompts/`. Create the folder if it does
not exist. Use a short kebab-case descriptor as the filename for each session
(e.g. `bayesian-model-refactor.md`). If a file with that name already exists,
append to it.

Log format for each session entry:

```
## Session: <descriptor>
Date: <YYYY-MM-DD>
Model: <model name and version>

### Prompts and Responses

**User:** <prompt text>

**Claude:** <summary of response — full code blocks where relevant, prose summarised>

---
```

---

## 9. Vignette — `vignettes/alldata_pipeline.qmd`

This vignette is the primary methodological reference for the `alldata` pipeline.
It documents what `ssd_data_sets(set = "all_chronic")` does and why, written for an
external reader (e.g. a reviewer or future contributor), not for Claude.

### Who edits what

**The user edits the vignette directly.** It is a human-authored document
requiring scientific judgement — the user writes, restructures, and refines
the prose. Claude (in a planning session) produces draft additions for each
completed stage as a separate deliverable; the user reviews, edits, and pastes
these into the vignette file themselves.

**Claude Code's only vignette role** is replacing confirmed `<!-- STAGEXX: ... -->`
placeholder comments with actual numbers from the audit report. This is a one-liner
task that can be added to the end of a stage prompt once the audit report numbers
have been confirmed in a planning session. Claude Code must not touch any other
part of the vignette.

### Workflow after each stage completes

1. Run the stage in Claude Code; Claude Code produces the audit report.
2. Share the audit report in a planning session here (Claude).
3. Claude interprets the results, updates CLAUDE.md, and produces a draft
   vignette section for that stage as a downloadable `.md` snippet.
4. The user reviews and edits the draft, then pastes it into the vignette
   file directly.
5. The user replaces `<!-- STAGEXX: ... -->` placeholders with confirmed
   numbers (or optionally delegates this narrow task to Claude Code with
   explicit instruction).

### What belongs in each stage update

For each completed stage, add or flesh out:

1. **Stage summary section** — what the stage does, key inputs/outputs with
   confirmed row counts, any deviations from ANZG spec, cross-reference to
   the audit report.
2. **Decisions appendix** (Appendix A) — one row per named decision confirmed
   during planning. Do not modify rows for earlier stages.
3. **Deviations appendix** (Appendix B) — one row if the stage introduced a
   new deviation from strict Warne et al. 2025 spec. Do not modify earlier rows.
4. **Data flow table** — update the row count for the completed stage once
   confirmed from the audit report.

### Placeholder convention

Numbers awaiting confirmation from an audit report are written as HTML comments:

```
<!-- STAGE4E: replace with confirmed output row count -->
<!-- STAGE4E: replace with confirmed n_chemicals -->
<!-- STAGE4E: replace with confirmed n_species -->
```

Once confirmed, replace the comment with the number and remove the tag.
The stage prefix (STAGE4E, STAGE6, etc.) identifies which audit report
confirms the number.
