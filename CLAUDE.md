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
- `data-raw/alldata/anztox_extracted.csv` (~16k rows × 19 cols)
- Any future similar large intermediate CSV produced by Stage 4 scripts
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

### Note on stripped history

The remote may still contain copies of the large files in older history
(pushed before the filter-branch operation). A full `git filter-repo` purge
across the entire remote history can be done later if repo size becomes an
issue. This is not currently blocking work.

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

Files likely to require `guess_max = Inf` going forward:
- Any Stage 4d Part 3+ outputs that augment existing files with sparse
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
| `data-raw/alldata/anztox_extracted.csv` | **untracked** | anztox filtered unaggregated records; ~15,667 rows × 19 columns (17 common schema + `source_dataset` + `majorgroup`). Produced by `scripts/stage4b-extract.R` (requires Windows Positron + live DB). |
| `data-raw/alldata/uncurated_raw_combined.csv` | **untracked** | Three-source combined unaggregated records; ~449,888 rows × 17 columns. Produced by `scripts/stage4b-extract.R`, `scripts/stage4b-effect-category-fixup.R`, and `scripts/stage4c-effect-category-fixup.R`. |
| `data-raw/alldata/uncurated_raw_dedup.csv` | **untracked** | ~449,888 rows × 21 cols (17 common schema + 4 dedup flag columns). Produced by `scripts/stage4c-dedup.R`. |
| `data-raw/alldata/species_resolution_cache.rds` | **untracked** | Part 1 WoRMS/GBIF resolver cache (Stage 4d). |
| `data-raw/alldata/species_resolution_v2_cache.rds` | **untracked** | Part 2 context-aware resolver cache (Stage 4d). |
| `data-raw/alldata/envirotox_effect_category_map.csv` | tracked | Mapping of 110 envirotox raw Effect values to the controlled effect_category vocabulary. |
| `data-raw/alldata/anztox_2016_effect_category_map.csv` | tracked | Mapping of 240 anztox 2016 free-text/non-standard effect_category values. |
| `data-raw/alldata/species_source_taxonomy.csv` | tracked | Per-source taxonomy for in-scope species (Stage 4d Part 1.5). |
| `data-raw/alldata/species_resolution_summary.csv` | tracked | Part 1 resolution outcomes (one row per unique species). |
| `data-raw/alldata/species_resolution_v2.csv` | tracked | Part 2 context-aware resolution outcomes (4,348 rows × 30 cols including taxonomy_provenance and manual-correction audit columns). Always read with `guess_max = Inf` — see Section 5. |
| `data-raw/alldata/species_resolution_v2_problem_species.csv` | tracked | Per-species detail for the 146 problem species remaining after manual corrections. Always read with `guess_max = Inf`. |
| `data-raw/alldata/species_synonym_audit.csv` | tracked | Synonym groups identified by Part 2 resolution (254 groups affecting 130,124 rows). |
| `data-raw/alldata/stage4c-dedup-report.md` | tracked | Stage 4c dedup audit report. |
| `data-raw/alldata/stage4d-species-resolution-report.md` | tracked | Stage 4d Part 1 diagnostic report. |
| `data-raw/alldata/stage4d-taxonomy-inventory.md` | tracked | Stage 4d Part 1.5 taxonomy inventory report. |
| `data-raw/alldata/stage4d-part2-report.md` | tracked | Stage 4d Part 2 resolution report. |
| `data-raw/alldata/stage4d-part2-fallback-report.md` | tracked | Stage 4d Part 2 U3 fallback report. |
| `data-raw/alldata/stage4d-part2-manual-corrections-report.md` | tracked | Stage 4d Part 2 manual corrections report. |

### Common schema (17 columns, `uncurated_raw_combined.csv`)

| # | Column | Description |
|---|---|---|
| 1 | source | "anztox", "wqbench", or "envirotox" |
| 2 | native_cas | CAS number as stored in the source, format-normalised only (no parent mapping) |
| 3 | casnumber_grouped | Parent CAS from master lookup, else native_cas |
| 4 | chemicalname_grouped | Parent name where mapped, else source chemical name |
| 5 | scientificname | Species scientific name as it appears in the source |
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

### Key reference documents

- `vignettes/ANZTOX_data_processing.qmd` — documents the anztox data processing
  workflow. Read before working on anztox, the CAS lookup, or aggregation logic.
- `vignettes/cas_parent_lookup_build.qmd` — documents the full Stage 2 CAS parent
  lookup build process including LLM enrichment, conventions, and known limitations.
- `vignettes/endpoint_2016_to_2000_lookup_build.qmd` — documents the endpoint
  lookup build. Read if working on endpoint harmonisation.
- `README.Rmd` — general package overview.
- `data-raw/anztox/speciation_convention.md` — speciation rules (arsenic oxyanions
  → element; nutrient ions → retain as ion).
- `scripts/speciation_policy_extensions.md` — extended speciation policy decisions
  D1–D4 (halides, alkaline earth metals, strontium, trace metal precedence rule).
- `scripts/stage3-deferred-decisions.md` — deferred decisions that must be resolved
  before Stage 6: ccme medium (pending Issue #34), PR #43 merge dependency,
  18 UNCERTAIN CAS rows.
- `scripts/stage4a-pipeline-audit.md` — full pipeline audit for anztox, wqbench,
  envirotox including supplementary DB query findings.
- `scripts/stage4c-schema-inventory.md` — targeted schema inventory across all
  three sources scoped to duplicate-detection fields.
- `scripts/stage4c-deferred-decisions.md` — deferred decision log for Stage 4c.
  All open items now closed (Option 1 resolution: 50% within-source duplicate
  threshold).

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
  sufficiency threshold.

### Environment note

The anztox pipeline requires a live connection to the `infogathering` PostgreSQL
instance, which is only available from Windows Positron (not WSL).
`scripts/stage4b-extract.R` and the anztox parts of Stage 4d Part 1.5 must be
run from Windows Positron. All other Stage 4+ scripts can run from WSL or
Windows. This split is documented in each script's header comment block.

---

## 7. Active Development — Issue #33

**Issue:** Allow `ssd_data_sets(set = "alldata")` to return an aggregated,
deduplicated dataset across all sources.

**GitHub context:**
- PR #43 (`add_media_wqbench`) is not yet merged but the current working branch
  is based off it. `data/wqbench_data.rda` already reflects PR #43's output.
  PR #43 must be merged before this branch merges to main.
- Issue #34 (ccme medium assignment) is pending an email response. ccme medium
  is interim "Unknown" for all 145 rows.

### Staged plan

Stages 1–4c are complete. Stage 4d is in progress (Parts 1, 1.5, 2 and the
manual-corrections fixup complete; Part 3 next).

**Note on Stage 4d/4e re-ordering:** In an earlier version of the plan, Stage 4d
was aggregation and Stage 4e was species synonym resolution. This was reversed
during Stage 4d planning (2026-06-24): species name harmonisation must happen
*before* aggregation, because the geomean groups by species — if `Daphnia magna`
appears under a synonym in one source and the accepted name in another, they
will be treated as two distinct species. The taxize/WoRMS/GBIF resolution work
also yields a full taxonomic hierarchy, which is used in the same stage to
support a project-defined `majorgroup` field. Stage 4d is now species
resolution + majorgroup derivation; Stage 4e is aggregation.

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
- LLM enrichment (550 rows): `prompts/stage2b-full-run.md`
- Manual review batch 6 (37 rows): `scripts/stage2b-batch6-manual.R`
- Consistency audit: `scripts/stage2c-consistency-report.md`
- Corrections: `scripts/stage2d-corrections.R` — Strontium reclassified
  as trace metal (D3); 12 unanchored rows re-flagged UNCERTAIN (D5);
  Phenethylamine CAS corrected to 64-04-0 (D6); two nodash truncation
  errors fixed. Total UNCERTAIN rows: 18.
- Vignette: `vignettes/cas_parent_lookup_build.qmd`

---

**Stage 3 — Media assignment audit**
Complete.

- `scripts/stage3-media-audit.md`, `scripts/stage3-deferred-decisions.md`
- All sources have a documented medium value. ccme is interim "Unknown"
  (pending Issue #34). envirotox is final "Unknown" (confirmed decision).

---

**Stage 4a — Pipeline audit (uncurated sources)**
Complete.

- `scripts/stage4a-pipeline-audit.md` — full audit including supplementary
  DB query section. Key findings:
  - `concentrationused` confirmed µg/L for toxicityvalue2000 (86% of anztox);
    unconfirmed for toxicityvalue2016 (~14%).
  - "Chronic QSAR" is a real DB-level testtype category — 632 rows were
    being silently dropped by the pipeline.
  - `majorgroup` inconsistency (2-letter codes vs full taxonomic names) is
    internal to the shared `species` table, not a 2000-vs-2016 artefact.
- `scripts/stage4a-supplementary-db-audit.R` — read-only DB query script
  for reproducibility.

---

**Stage 4b — Extract filtered unaggregated records (uncurated sources)**
Complete. Revised after Stage 4c Part 1 schema inventory.

The original Stage 4b (11-column schema, two separate scripts) was superseded
after the schema inventory revealed that statistic_type, duration_hours,
effect_category, life_stage, and study_reference are required by the Section
3.4.4 aggregation procedure. See `scripts/stage4c-schema-inventory.md` and the
revision note in `prompts/stage4b-extract.md`.

- `scripts/stage4b-extract.R` — single script covering all three sources
  (replaces the previous stage4b-anztox-extract.R and stage4b-combine.R,
  which were removed). Requires Windows Positron + live infogathering DB.
  Outputs both `anztox_extracted.csv` and `uncurated_raw_combined.csv`
  (both UNTRACKED per Section 4 policy).
- `scripts/stage4b-effect-category-fixup.R` — post-hoc correction applying
  human-reviewed effect_category mappings for 10 of 13 unmapped envirotox
  Effect values (52 rows updated). No DB connection required.
- `data-raw/alldata/anztox_extracted.csv`: 15,667 rows × 19 columns (untracked).
- `data-raw/alldata/uncurated_raw_combined.csv`: 449,888 rows × 17 columns
  (untracked). Source counts: anztox 15,667 / wqbench 361,782 / envirotox 72,439.
- `data-raw/alldata/envirotox_effect_category_map.csv`: 110 Effect values
  mapped; 3 confirmed NA after human review (tracked).
- wqbench source RDS: `ecotox_ascii_12_11_2025.rds`. A newer
  `ecotox_ascii_06_11_2026.rds` exists and will be adopted in a future update.
- Prompt log: `prompts/stage4b-extract.md`

Decisions implemented:

- **A1**: anztox `concentrationused` treated as µg/L for all rows. Confirmed
  for toxicityvalue2000 majority; assumed for toxicityvalue2016 minority
  (~14%). Flagged via `source_dataset` column in `anztox_extracted.csv`.
- **B1**: 632 "Chronic QSAR" anztox rows dropped explicitly. QSAR-predicted
  values are not appropriate for SSD fitting alongside measured data.
- **C1**: anztox DATASET.R `=>` parse error fixed on line 431. anztox
  intercept replicated in standalone script; DATASET.R not sourced.
- **D-E**: anztox statistic_type uses `effectused_id` for 2000 rows
  (curator-selected, 11-value vocabulary) and `effect_id` for 2016 rows
  (raw value). These may not be directly comparable — noted in script.
- **D-F**: `acr_eligible` derived from
  `statistic_type %in% c("EC50","LC50","IC50")`. Replaces the MORT/IMM
  endpoint-code proxy used in the original Stage 4b.

---

**Stage 4c Part 1 — Schema inventory for duplicate detection**
Complete.

- `scripts/stage4c-schema-inventory.md` — cross-source field comparison
  covering test statistic type, effect/endpoint category, numeric duration,
  life stage, and study/reference identifier for all three sources.
- Companion read-only scripts: `scripts/stage4c-anztox-db-inventory.R`,
  `scripts/stage4c-wqbench-inventory.R`, `scripts/stage4c-envirotox-inventory.R`.
- Key findings:
  - anztox has a usable statistic-type field (`effect`/`effectused`) that was
    being silently dropped before `core_cols` — directly overturned Stage 4a's
    assumption that anztox permanently lacks this distinction.
  - Numeric duration is recoverable and harmonisable to hours across all three
    sources with modest cleanup.
  - Life stage is not viable cross-source (envirotox has no such field; anztox
    coverage is ~7% of rows, 2016 only).
  - envirotox `Source` field is empirically the single strongest distinguishing
    field for within-envirotox duplicate detection — was being discarded entirely
    before Stage 4b revision.
  - Study/reference identifiers exist in all three sources but in structurally
    incompatible forms — usable within-source only.
- Prompt log: `prompts/stage4c-dedup.md`

---

**Stage 4c Part 2 — Cross-source duplicate detection and ANZG priority selection**
Complete.

- `scripts/stage4c-dedup.R` — four-phase pipeline:
  - **Phase 1**: within-source duplicate diagnostic (flag-and-retain; hard
    stop only if >50% of any source's rows are involved, per
    `scripts/stage4c-deferred-decisions.md` resolution).
  - **Phase 2**: cross-source duplicate detection (exact match pass plus
    0.1% relative tolerance pass on conc_value). Preference order:
    wqbench > anztox > envirotox.
  - **Phase 3**: ANZG priority selection (chronic > subchronic > acute)
    applied to cross-source-deduplicated rows only.
  - **Phase 4**: write augmented CSV (449,888 rows × 21 cols, untracked)
    and report (tracked).
- During Phase 1 investigation, fixed wqbench source_id in
  `scripts/stage4b-extract.R` from (species, cas) pair identifier to
  `row_number()` (matching anztox/envirotox convention).
- Deferred decision resolved: see `scripts/stage4c-deferred-decisions.md`.
  The 1% Phase 1 threshold was downgraded to 50% (Option 1). Empirical
  within-source duplicate rates (anztox 9.2%, wqbench 25.1%, envirotox 0.56%)
  are intrinsic to each source's data granularity, not data-quality defects.
- Prompt log: `prompts/stage4c-dedup.md`

Decisions implemented:

- **G2**: within-source duplicates flag-and-retain (not hard-drop).
  Hard-stop threshold at 50% (originally 1%, downgraded per resolved
  deferred decision).
- **H2**: ANZG priority-selection grouping key uses `native_cas`, not
  `casnumber_grouped`. Parent-CAS grouping is deferred to Stage 4e.
- **I2**: ANZG priority selection applied AFTER cross-source dedup, not
  before. Ensures chronic data from a lower-priority source is not
  discarded in favour of acute data from a higher-priority source.
- **J1**: cross-source key uses exact match on duration_hours;
  conc_value uses 0.1% relative tolerance.
- **J2b**: rows with NA in any cross-source or within-source key field are
  excluded from that specific check (strict) and pass through unflagged.
- **J3a**: medium is matched strictly in the cross-source key. "Unknown"
  rows (envirotox; some wqbench) only match other "Unknown" rows.
- **D1b/D2b/D3b/D4b/D5b**: 0.1% tolerance; normalised species names;
  flag-and-filter; within-source diagnostic first; harmonised
  statistic_type and effect_category in cross-source key.

---

**Stage 4c Part 3 — effect_category harmonisation**
Complete.

- `scripts/stage4c-effect-category-fixup.R` — three-part fixup applied to
  `uncurated_raw_combined.csv` in place (idempotent):
  - wqbench English words → controlled codes: 339,811 of 361,782 mapped;
    21,971 → NA (including Intoxication, Multiple, General, Accumulation,
    Ecosystem Process, and three unanticipated values Unspecified,
    Immunological, Injury).
  - anztox 2016 free-text → controlled codes via keyword rules: 240
    outside-vocab rows; 65 mapped, 175 left NA (dominated by "PGR",
    147 rows — left NA per explicit user decision, no domain mapping
    available).
  - envirotox MOR/MORT split: cross-checked and confirmed correct
    (MOR = 4 morphology rows, MORT = 52,432 mortality rows). No change.
- `scripts/stage4c-dedup.R` — effect_category restored to cross-source
  key. J-DEVIATION marked resolved.
- Result delta vs Part 2:

  | Metric | Part 2 | Part 3 | Δ |
  |---|---|---|---|
  | Cross-source duplicates flagged | 8,082 | 7,366 | −716 |
  | Priority displaced | 54,662 | 61,112 | +6,450 |
  | Final clean subset | 387,144 | 381,410 | −5,734 |

- Prompt log: `prompts/stage4c-dedup.md`

---

**Stage 4d Part 1 — Species name resolution diagnostic**
Complete.

Submitted each of the 4,348 unique species names (from the final clean
subset of `uncurated_raw_dedup.csv`) to taxize/WoRMS as primary source
with GBIF fallback, with NO pre-normalisation, to baseline resolver
performance against raw data.

- `scripts/stage4d-species-resolution-diagnostic.R` — runs from WSL.
- Outcome counts:

  | Outcome | Species | Rows |
  |---|---|---|
  | WoRMS exact | 1,191 | 166,676 |
  | WoRMS exact (unaccepted, synonym) | 472 | 20,893 |
  | WoRMS fuzzy | 52 | 1,281 |
  | WoRMS ambiguous | 1,079 | 156,131 |
  | GBIF exact (fallback) | 725 | 23,683 |
  | GBIF fuzzy (fallback) | 716 | 10,668 |
  | Genuinely unresolved | 113 | 2,078 |
  | API errors | 0 | 0 |

- The large WoRMS ambiguous bucket (1,079 species, 40.9% of rows) drove
  the decision to proceed to context-aware querying with source-native
  taxonomic filters (Part 1.5 + Part 2).
- Outputs: `data-raw/alldata/species_resolution_cache.rds` (untracked),
  `data-raw/alldata/species_resolution_summary.csv` (tracked),
  `data-raw/alldata/stage4d-species-resolution-report.md` (tracked).
- Prompt log: `prompts/stage4d.md`

---

**Stage 4d Part 1.5 — Source-native taxonomy extraction**
Complete.

Extracted source-native taxonomy for all 6,198 (source, scientificname)
combinations in the final clean subset, from each source's own data:
- anztox: from `species`, `speciesclass`, `speciesphylum`, `animaltype`,
  `animalcategory` tables via the live DB (Windows Positron).
- wqbench: from the `species` table in
  `data-raw/wqbench/ecotox_ascii_12_11_2025.sqlite`.
- envirotox: from the "taxonomy" sheet of
  `data-raw/envirotox/envirotox.xlsx`.

- `scripts/stage4d-taxonomy-extract.R` — read-only against all three
  sources; produces a 19-column harmonised taxonomy table.
- Two bugs caught and fixed during the run:
  1. Sequencing bug that under-reported anztox kingdom coverage as 0
     instead of 94/804.
  2. The Part 1 `resolved_by == "none"` filter conflates genuinely-
     unresolved species with WoRMS-ambiguous ones (1,192 vs the
     documented 113). Fixed by using `gbif_status == "gbif_no_match"`
     and documented as a trap in both the script and report.
- Key findings:
  - wqbench/envirotox: well populated through family level (~100%).
  - anztox: class-level coverage is only 11.7% — most anztox taxonomic
    signal lives in `source_majorgroup` (82.7%), `source_animaltype`
    (85.4%), and `source_animalcategory` (93.9%).
  - 40 species show kingdom/phylum disagreement across sources, mostly
    classification-scheme variants rather than real conflicts.
  - Source-native taxonomy covers 100 of the 113 Part 1 genuinely-
    unresolved species (mostly "Genus sp." placeholders).
- Outputs: `data-raw/alldata/species_source_taxonomy.csv` (6,198 rows,
  tracked), `data-raw/alldata/stage4d-taxonomy-inventory.md` (tracked).
- Prompt log: `prompts/stage4d.md`

---

**Stage 4d Part 2 — Context-aware WoRMS resolution**
Complete.

Queried WoRMS for each species with the source-native taxonomic context
as a filter (class → phylum → genus → no filter, per Decision C),
disambiguating the 1,079 Part 1 ambiguous cases.

- `scripts/stage4d-context-aware-resolution.R` — runs from WSL.
- Two important bug fixes during the run, both kept and documented:
  1. **Exact-name-priority pre-filter** added. WoRMS `fuzzy=TRUE` pulls
     in subspecies records that share identical taxonomy with the true
     match (no context filter can separate them), but 951/1,079 (88%)
     of Part 1's ambiguous species have a unique verbatim name match
     buried in the noise. This is a deliberate deviation from the
     literal spec, flagged in the script header and prompt log.
  2. **GBIF kingdom-rank floor**. A GBIF "fuzzy" match can be as coarse
     as KINGDOM rank (e.g. guessing "Animalia") with missing hierarchy
     columns — Part 1 had silently accepted 62 of these as "resolved"
     dataset-wide. Now requires genus-or-finer rank to count as
     resolved.
- Results: 99.22% of rows (4,200 of 4,348 species) meet the
  "resolved enough to use" bar. 148 species (2,959 rows, 0.78%)
  remained problematic before the fallback and manual-corrections
  fixups.
- 254 synonym groups identified, affecting 130,124 rows (34% of final
  clean subset). The top synonym groups are standard ecotox species
  like *Danio rerio*, *Oncorhynchus mykiss*, *Cyprinus carpio*,
  *Raphidocelis subcapitata* — confirming the critical importance of
  synonym resolution before aggregation.
- Outputs: `species_resolution_v2.csv` (tracked),
  `species_synonym_audit.csv` (tracked),
  `species_kingdom_phylum_disagreements.csv` (tracked),
  `stage4d-part2-report.md` (tracked),
  `species_resolution_v2_cache.rds` (untracked).
- Prompt log: `prompts/stage4d.md`

Decisions implemented:

- **P3**: per-species taxonomy pooling uses the most-populated single
  source, with wqbench > envirotox > anztox as tiebreaker. Fields are
  NOT mixed across sources for a single species (avoids internally
  inconsistent hierarchies).
- **C tiered fallback**: WoRMS filter by class → phylum → genus → no
  filter.
- **R1**: "Genus sp." entries resolved at GENUS level rather than
  species. Applies to UNCURATED sources only — curated sources
  (Stage 6/7) retain "Genus sp." entries as distinct species per
  curators' domain judgement.

---

**Stage 4d Part 2 fixup — U3 source-native fallback**
Complete.

Applied source-native taxonomy fallback to the 148 problem species
remaining from Part 2.

- `scripts/stage4d-part2-source-native-fallback.R` — idempotent fixup.
- Result: 130 of 148 problem species had ≥1 hierarchy field recovered
  from source-native taxonomy. Class-level coverage dataset-wide rose
  from 94.9% to 97.9%.
- Added `taxonomy_provenance` column to `species_resolution_v2.csv`
  with values: `worms_full` (3,227), `gbif_full` (973),
  `ambiguous_partial` (84), `source_native_fallback` (49),
  `no_taxonomy` (15).
- The 15 no_taxonomy species (33 rows total — 0.01% of final clean)
  are placeholder/category labels (e.g. "-", "Algae", "Periphyton",
  "Invertebrates") plus a few un-resolvable misspellings.
- Outputs: `species_resolution_v2.csv` updated in place,
  `species_resolution_v2_problem_species.csv` (tracked),
  `stage4d-part2-fallback-report.md` (tracked).
- Prompt log: `prompts/stage4d.md`

Decision implemented:

- **U3**: partial use with source-native fallback. Problem species
  use Part 1.5 source-native taxonomy where available;
  `accepted_name` is NOT fabricated for unresolved species (only
  hierarchy fields are populated). The provenance flag carries
  through to downstream stages.

---

**Stage 4d Part 2 fixup — manual name corrections**
Complete.

Manual review of the 15 no_taxonomy species identified three with
data-entry errors that masked valid species. The remaining 12 are
genuine non-species placeholders or unresolvable misspellings.

- `scripts/stage4d-part2-manual-name-corrections.R` — idempotent,
  applies three targeted corrections to `species_resolution_v2.csv`:
  - "Illybius augustior" → "Ilybius augustior" (genus typo, resolved
    via GBIF: Insecta/Coleoptera/Dytiscidae).
  - "Salmoides micropterus" → "Micropterus salmoides" (genus/species
    reversed, resolved via WoRMS: Actinopterygii/Perciformes/
    Centrarchidae).
  - "Sialis flavilatera" → resolved at genus level via GBIF (Sialis,
    Insecta/Megaloptera/Sialidae). Species-level identity not
    fabricated — `accepted_name` left NA, `status` remains
    `unresolved`, with `taxonomy_provenance == "manual_genus_fallback"`.
- During this run, a `readr::read_csv()` trap was identified and
  documented in Section 5 — sparse audit columns near the end of the
  schema can be silently nulled out unless `guess_max = Inf` is used.
- Result: no_taxonomy bucket reduced from 15 to 12 species. Genuine
  hard-exclude residual for Stage 4d Part 3 is 12 species (~30 rows).
- Outputs: `species_resolution_v2.csv` and
  `species_resolution_v2_problem_species.csv` updated in place,
  `stage4d-part2-manual-corrections-report.md` (tracked).
- Prompt log: `prompts/stage4d.md`

New `taxonomy_provenance` value added: `manual_genus_fallback` (for
the Sialis case).

---

#### In progress

**Stage 4d Part 3 — Apply resolution, derive majorgroup, prepare for aggregation**
Next stage. Not yet started.

Apply the resolved species names and hierarchy back to
`uncurated_raw_dedup.csv`. Specifically:

1. Apply synonym unification (254 synonym groups, 130,124 rows
   affected) — each raw scientificname is replaced by its
   `accepted_name` where one exists, with the original name preserved
   in an audit column.
2. Join the resolved taxonomy fields (kingdom, phylum, class, order,
   family, genus) and the `taxonomy_provenance` flag.
3. **Derive `majorgroup` directly from `resolved_class`** (no
   controlled lookup — using the column directly, consistent with
   wqbench's `filter(n_distinct(class) >= 4)` convention).
4. Hard-exclude the 12 no_taxonomy residual species (~30 rows).
5. Output an augmented version of the dedup file ready for Stage 4e
   aggregation.

Decision: `majorgroup = resolved_class` directly. Confirmed by user.
This is a simpler, more reproducible alternative to deriving a
controlled majorgroup vocabulary, with the tradeoff that majorgroup
categories are finer-grained than Warne et al. Table 5 would produce.
Acceptable because this dataset is for methodology testing, not for
producing official guideline values.

---

#### Pending

**Stage 4e — Aggregation (Section 3.4.4)**
Apply Section 3.4.4 (Warne et al. 2025) to the deduplicated, species-
resolved combined dataset. Grouping key for the geometric mean:

  `casnumber_grouped × accepted_name × medium × effect_category ×
   statistic_type × duration_hours × life_stage (where non-NA)`

Apply within-group geomean (Step 1 of Section 3.4.4), then lowest within
each effect_category per species (Step 2), then lowest across effect
categories per species (Step 3). Notes:

- Apply ACR = 10 conversion for retained acute records where
  `acr_eligible == TRUE` (LC/EC/IC50 only — per Section 3.4.2.2). Acute
  NOECs must not be converted. Set `acr_applied = TRUE` for converted rows.
- Drop retained acute records that are NOT acr_eligible (acute NOECs,
  LOECs etc.) — these cannot be ACR-converted and cannot be aggregated
  alongside chronic data per ANZG.
- Apply wqbench mg/L → µg/L unit conversion (×1000) before aggregation.
- Switch from `native_cas` to `casnumber_grouped` for the aggregation key —
  this is the stage where parent-CAS grouping is applied.
- Use Stage 4d-derived `majorgroup` (= `resolved_class`) for any
  eligibility checks if performed at this stage.
- Eligibility check (≥5 species / ≥4 majorgroups) may be applied here or
  deferred to Stage 7 — to be decided when planning Stage 4e.

---

**Stage 5 — Units audit and normalisation**
wqbench mg/L → µg/L conversion (×1000) is the outstanding item. Applied in
Stage 4e before aggregation.

**Stage 6 — Deduplication and anzg exclusion rule**
- anzg exclusion: any anzg freshwater variant for a chemical excludes ALL
  other sources' freshwater data for that chemical (Interpretation B).
- Preference order: `anzg > ccme > aims > csiro > anztox > wqbench > envirotox`
- 18 UNCERTAIN CAS rows must be resolved before this stage.
- ccme medium (Issue #34) must be resolved before this stage.
- **Genus sp. handling for curated sources**: per the R1 caveat, "Genus sp."
  entries from aims/csiro/ccme/anzg are retained as distinct species per
  the curators' domain judgement (in contrast to the uncurated pipeline
  where they are resolved at genus level).

**Stage 7 — Media sufficiency filtering and wire up `ssd_data_sets()`**
- Sufficiency rule: ≥5 species from ≥4 taxonomic groups (using the
  Stage 4d-derived `majorgroup` = `resolved_class`).
- Medium precedence rules as previously documented.
- Backward compatibility handling for existing `ssd_data_sets()` calls.

**Stage 8 (optional) — Species name cleaning vignette**

---

### Key design decisions

- `anon_` datasets are excluded from `alldata` (no chemical name).
- Curated sources (aims, csiro, ccme, anzg) are treated separately from
  uncurated sources (anztox, wqbench, envirotox), which are first
  consolidated before merging with curated sources.
- Cross-source deduplication occurs before aggregation. Each uncurated
  source is intercepted at the filtered-but-unaggregated state;
  `wqb_aggregate()` is not called in the Stage 4 pipeline.
- Cross-source deduplication occurs BEFORE ANZG priority selection
  (Decision I2). This ensures chronic data from a lower-priority source
  is not discarded in favour of acute data from a higher-priority source.
- Species taxonomy resolution happens BEFORE aggregation (Stage 4d before
  Stage 4e). Aggregation groups by species — if synonyms exist across
  sources, they must be resolved first or the geomean will be applied
  to incomplete groups.
- `majorgroup = resolved_class` directly (no controlled-vocabulary
  lookup). Simpler, more reproducible, consistent with wqbench's
  `filter(n_distinct(class) >= 4)` convention. Acceptable deviation
  from ANZG Table 5 because this dataset is for methodology testing,
  not official guideline values.
- "Genus sp." handling is asymmetric between uncurated and curated
  pipelines. Uncurated (Stage 4d): resolve at genus level, treat as
  effectively a genus-level record. Curated (Stage 6/7): retain as a
  distinct species per the curators' domain judgement.
- The existing `anztox_data` `.rda` and its `DATASET.R` are not modified
  in this branch beyond the `=>` parse-error fix. Any deeper issues found
  in anztox's aggregation logic are filed as GitHub issues and handled
  separately.
- anzg Medium field has five variants (freshwater, hard freshwater, marine,
  moderate freshwater, soft freshwater) — do NOT collapse these.
- envirotox medium is final "Unknown" (no medium field in source data).
- ccme medium is interim "Unknown" pending Issue #34 response.
- Concentration units target: µg/L. wqbench is in mg/L; conversion applied
  in Stage 4e before aggregation. All other uncurated sources are µg/L.
- anztox `concentrationused` units: confirmed µg/L for toxicityvalue2000
  (86% of rows); assumed µg/L for toxicityvalue2016 (~14%). Flagged via
  `source_dataset` in `anztox_extracted.csv`.
- "Chronic QSAR" anztox rows (632): dropped deliberately (Decision B1).
- `acr_eligible` derived from `statistic_type %in% c("EC50","LC50","IC50")`.
- Acute records that are not acr_eligible (acute NOECs, LOECs) will be
  dropped at Stage 4e — they cannot be ACR-converted and cannot enter
  the chronic-equivalent aggregation per Warne et al. 2025 Section 3.4.2.2.
- anztox statistic_type: `effectused_id` for 2000 rows, `effect_id` for
  2016 rows. May not be directly comparable — noted in script.
- wqbench intercept: `ecotox_ascii_12_11_2025.rds` loaded before
  `wqb_aggregate()`. wqbench's within-source duplicate rate (25.1%) reflects
  the wqbench package's own prepared-dataset structure (test_id/result_id
  discarded upstream by `wqb_create_data_set()`), not a pipeline defect.
  Bypassing this would mean re-deriving from raw ECOTOX — at that point
  the source would no longer be wqbench. Out of scope for this branch.
- envirotox intercept: statistic/type/solubility filter reproduced from
  DATASET.R. `original.CAS` used as join key (not substance sheet's internal
  grouped CAS). Effect field retained and mapped to `effect_category`.
- `native_cas` retained in schema for within-source and cross-source
  deduplication — each source's own CAS number before parent mapping.
  `casnumber_grouped` retained alongside for Stage 4e aggregation.
- Within-source dedup key uses each source's own richest available fields,
  including conc_value (necessary for distinguishing dose-response rows
  with otherwise-identical metadata).
- Cross-source dedup key (Phase 2): `native_cas × scientificname_norm ×
  medium × statistic_type_norm × effect_category × duration_hours (exact)
  × conc_ug_L (0.1% tolerance)`.
- Life stage retained in schema where available (wqbench; anztox 2016
  subset) but excluded from cross-source dedup key (envirotox has no life
  stage field). Included in Stage 4e grouping key where non-NA.
- study_reference retained per-source as audit trail; not used as a
  cross-source join key.
- True duplicate preference order: wqbench > anztox > envirotox.
- Deduplication preference order (cross-source, Stage 6):
  `anzg > ccme > aims > csiro > anztox > wqbench > envirotox`
- Media sufficiency threshold: ≥5 species from ≥4 taxonomic groups
  (using `majorgroup = resolved_class`).
- effect_category controlled vocabulary across all sources: MORT, GRO, REP,
  IMM, DVP, HAT, PSE, POP, LUM, ABD, BEH, BCH, MOR.
- Stage 4d Part 2 taxonomy pooling (Decision P3): single-source pooling
  with wqbench > envirotox > anztox as tiebreaker, fields NOT mixed
  across sources for a single species.
- Stage 4d Part 2 exact-name-priority pre-filter (deviation from literal
  spec): when WoRMS returns multiple candidates with identical taxonomy
  (typically species + subspecies records), promote the unique exact
  species name match. Recovered 951 of 1,079 Part 1 ambiguous species.
- Stage 4d Part 2 GBIF rank floor: GBIF "fuzzy" matches at KINGDOM rank
  do not count as resolved. Genus-or-finer rank required.
- Stage 4d Part 2 fixup (U3 fallback): problem species use Part 1.5
  source-native taxonomy where available. `accepted_name` is NEVER
  fabricated for unresolved species — only hierarchy fields are populated.
- `taxonomy_provenance` column values: `worms_full`, `gbif_full`,
  `ambiguous_partial`, `source_native_fallback`, `manual_genus_fallback`,
  `no_taxonomy`.

### Deferred decisions (must resolve before Stage 6)

- 18 UNCERTAIN rows in `data-raw/cas_parent_lookup_all.csv` — require
  human domain expert review.
- ccme medium assignment — pending Issue #34 email response.
- PR #43 (`add_media_wqbench`) must be merged before this branch merges
  to main.

### Future enhancements (deferred, not blocking current branch)

- wqbench SQLite database (`ecotox_ascii_*.sqlite`, shipped alongside the
  RDS) may retain per-row identifiers recoverable via a join on
  `species_number × cas × endpoint × effect_conc_mg.L`. Could improve
  wqbench within-source duplicate detection in a future stage.
- 175 anztox 2016 effect_category NA rows (mostly "PGR") could be resolved
  with domain expertise if it becomes available.
- 40 species with cross-source kingdom/phylum disagreement (identified in
  Stage 4d Part 1.5) — most are classification-scheme variants but could
  benefit from human review for any genuine taxonomic conflicts.
- Full `git filter-repo` purge of large intermediate CSVs from remote
  history (only stripped from local history so far) — defer until repo
  size becomes a problem.
- 12 no_taxonomy residual species (~30 rows) from Stage 4d Part 2 manual-
  corrections fixup — these are placeholder/category labels and
  unresolvable misspellings, hard-excluded in Stage 4d Part 3. A future
  pass could attempt domain-expert review of any salvageable entries.

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
