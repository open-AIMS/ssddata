# Project: ssddata

Project-specific context for Claude Code: repo structure, conventions, paths,
and current pipeline state. Methodological narrative and rationale live in
`vignettes/alldata_pipeline.qmd` and the per-stage audit reports — this file is
the operational quick-reference, kept deliberately lean.

**For Claude:** If a `CLAUDE.md` exists in the parent directory, read it first —
it may hold user environment/style preferences. This repo-level file takes
precedence where they conflict.

---

## 1. Repo type and purpose

**R package** (usethis/devtools structure: `R/`, `tests/testthat/`, `man/`,
`data-raw/`, `vignettes/`, `DESCRIPTION`, `NEWS.md`; R CMD check via GitHub
Actions; pkgdown site; roxygen2).

`ssddata` provides standardised benchmark species-sensitivity datasets for
fitting and comparing SSD models. It harmonises and aggregates ecotoxicological
data from multiple sources (AIMS, CSIRO, CCME, ANZG, and uncurated databases)
into a common reference set. Dependencies are in `DESCRIPTION`.

---

## 2. Version control policy — large intermediate files

**Several Stage 4+ intermediate artefacts must stay UNTRACKED** (in `.gitignore`;
history was stripped via `git filter-branch` 2026-06-25). They are large,
deterministic, and regenerable.

Untracked (never `git add`):
- `data-raw/alldata/uncurated_raw_combined.csv`, `…_dedup.csv`,
  `…_dedup_enriched.csv` (~228 MB), `…_aggregated.csv` (Stage 4e output)
- `data-raw/alldata/anztox_extracted.csv`, `alldata_integrated.csv` (Stage 6)
- `data-raw/alldata/stage4e-genus-rank-excluded.csv`
- Resolver caches (`species_resolution_*_cache.rds`)
- Any new large intermediate CSV produced by Stage 4+ scripts

Rules for Claude Code:
- Never `git add` the above or any new large intermediate CSV; never edit
  `.gitignore` to track them without explicit direction.
- If a script writes a file >5 MB to `data-raw/alldata/`, add it to `.gitignore`
  first if possible and flag it in the session summary with its size.
- Smaller artefacts (reports, mapping CSVs, audit files <~5 MB) stay tracked —
  these are the primary reproducibility record.
- **Claude Code must NEVER run `git commit` or `git push`.** The user commits
  manually. End stage prompts with a "Files to commit" checklist, not git
  commands. `git status` / `git diff --stat` are fine.

Cross-environment note: the user works on Windows Positron (required for the
anztox PostgreSQL DB) and WSL Positron (everything else); both share the same
WSL filesystem paths. The user keeps untracked Stage 4 files synced. If a script
reports an untracked intermediate (e.g. `uncurated_raw_dedup.csv`) missing, ASK
before regenerating.

---

## 3. Coding conventions

**`read_csv(..., guess_max = Inf, show_col_types = FALSE)` is mandatory** for any
Stage 4+ intermediate CSV. Many have sparse audit columns that are NA past
row 1000; readr's default 1000-row type guesser then infers `logical` and
silently NAs real strings it meets later. Same trap in `data.table::fread()` /
base `read.csv()` — use their full-scan equivalents or explicit `col_types`.
Files known to need it: `species_resolution_v2*.csv`, `…_dedup_enriched.csv`,
`species_resolution_curated.csv`, `alldata_integrated.csv`, and any fixup-script
output that adds columns to an existing CSV.

---

## 4. Key files, paths, and schemas

### Package layout
`R/` exported functions · `tests/testthat/` · `man/` (roxygen-generated, do not
edit) · `data-raw/` data-object scripts · `vignettes/` · `prompts/` session logs
· `scripts/` non-alldata utilities · `data-raw/alldata/scripts/` alldata pipeline scripts.

### Data sources
Source `.rda` objects under `data/`, named `{prefix}_{chemical}` (e.g.
`ccme_boron`). For aims/csiro/ccme/anzg the `.rda` build is complex — for
data-raw work go directly to the CSV in the relevant `data-raw/{source}/`
subfolder.

| Prefix | Curation | data-raw |
|---|---|---|
| aims_, csiro_, ccme_, anzg_ | Curated | `data-raw/{source}/` (use CSV) |
| anztox_, wqbench_, envirotox_ | Uncurated | `data-raw/{source}/` (use CSV) |
| anon_ | Anonymous (excluded from all_chronic — no chemical name) | `data-raw/anon/` |

### CAS lookup — CRITICAL PATH
Master lookup: **`data-raw/cas_parent_lookup_all.csv`** — NOT
`data-raw/anztox/cas_parent_lookup_all.csv` (recurring path error). The original
40-row human seed is `data-raw/anztox/cas_parent_lookup.csv`. The master holds
the merged 587-row population and is the single authoritative source. 18 rows are
flagged UNCERTAIN (`human_checked == "n"` + UNCERTAIN in `match_rationale`) and
are excluded via an `excluded` column; joins filter to `excluded == FALSE`.

### Stage 4 intermediate artefacts (key files)
Under `data-raw/alldata/`. **(U)** = untracked.

| File | Note |
|---|---|
| `uncurated_raw_dedup_enriched.csv` **(U)** | Stage 4d Part 3 output / Stage 4e input. ~449,860 × 33 cols, ~228 MB. accepted_name, resolved taxonomy, majorgroup(=class), taxonomy_provenance, resolution_status. |
| `uncurated_raw_aggregated.csv` **(U)** | Stage 4e output. One row per casnumber_grouped × accepted_name × medium. |
| `alldata_integrated.csv` | **removed** | No longer produced — DATASET.R builds directly from the Stage 4e output + curated `.rda`. |
| `species_resolution_v2.csv` / `…_problem_species.csv` | Stage 4d Part 2 resolution (read with `guess_max=Inf`). |
| `curated_cas_lookup.csv` | Stage 6 CAS lookup for curated sources (42 rows). |
| `species_resolution_curated.csv` | Stage 6 taxonomy cache for aims/csiro (77 rows; `guess_max=Inf`). |
| `stage4e-aggregation-report.md` | Stage 4e audit report. |
| `stage4e-statistic-type-inventory.md` / `…-excluded.csv` | Stage 4e statistic-type inventory + exclusion audit. |
| `stage4e-genus-rank-decisions.md` | Genus-rank triage rationale. |
| `DATASET.R` | **single definitive full-build entry point, steps 1→10** (Stage 4e aggregation + Stage 6/7 integration). Produces `allchronic_data.rda` and all `data-raw/alldata/` artefacts. Run from repo root. |
| `stage6-integration-report.md`, `stage7-eligibility-report.md` | Audit reports. |

Tracked mapping/report files (effect-category maps, resolution summaries, stage
reports) are the reproducibility record and stay committed.

### Build order — `DATASET.R` is the single full-build entry point

There is no separate orchestrator script. `data-raw/alldata/DATASET.R` itself
runs the full pipeline, steps 1→10, in enforced order, invoking each prior
stage script as an isolated `Rscript` subprocess (never `source()`d into the
assembly session — several stage scripts assume a fresh global environment).
Run from the repository root, **on Windows, end-to-end**: step 1 needs the
live `infogathering` PostgreSQL DB; step 5 (when triggered) needs both the DB
and network access for WoRMS/GBIF.

| Step | Script | Notes |
|---|---|---|
| 1 | `stage4b-extract.R` | **[DB]** |
| 2 | `stage4b-effect-category-fixup.R` | mandatory, silently skippable |
| 3 | `stage4c-effect-category-fixup.R` | mandatory, silently skippable |
| 4 | `stage4c-dedup.R` | |
| 5 | `stage4d-taxonomy-extract.R` | **[DB + network]** `full_reresolution` only |
| 6 | `stage4d-context-aware-resolution.R` | **[network]** `full_reresolution` only |
| 7 | `stage4d-part2-source-native-fallback.R` | **[network]** `full_reresolution` only |
| 8 | `stage4d-part2-manual-name-corrections.R` | `full_reresolution` only |
| 9 | `stage4d-part3-apply-resolution.R` | reads `species_resolution_v2.csv`, `guess_max = Inf` |
| 10 | *(existing `DATASET.R` assembly)* | Stage 4e/6/7 + validations + `.rda` |

Both effect-category fixups (steps 2, 3) are baked into the enforced order —
they cannot be skipped. Each is internally idempotent (a no-op if already
applied), so re-running the full sequence against already-fixed data is safe.

**`stage_from`** parameter (`c("extract", "dedup", "assemble")`, default
`"extract"`) selects the restart point — always the enforced contiguous tail
through step 10, never a free-form skip:
- `extract` — full build, 1→10 (needs DB; Windows).
- `dedup` — 2→10, starting from `uncurated_raw_combined.csv` (no DB).
- `assemble` — 10 only, starting from `uncurated_raw_dedup_enriched.csv` (no
  DB) — the fast-iteration path for Stage 4e/6/7 changes.

A restart verifies its required input intermediate exists **and** is current
(row-count sanity against the documented reference); if missing or stale, it
hard-fails naming the earliest stage to re-run rather than silently
regenerating anything (per Section 2's git-awareness policy).

**`stage4d_mode`** parameter (`c("cache_reuse", "full_reresolution")`,
default `"cache_reuse"`) controls whether steps 5–8 (network WoRMS/GBIF
re-resolution) run. `cache_reuse` skips them and reuses the existing
`species_resolution_v2.csv`; it auto-switches to `full_reresolution` (with a
loud runtime warning) if the species set in a freshly-produced
`uncurated_raw_dedup.csv` has drifted beyond what `species_resolution_v2.csv`
covers (baseline ~4,348 species).

Both parameters may be set as variables before sourcing `DATASET.R`, or via
the environment variables `SSD_STAGE_FROM` / `SSD_STAGE4D_MODE`.

**Guards:** `stage4c-dedup.R` hard-fails if zero cross-source duplicates are
flagged (the fixup-skipped bug state — see the script header for the
`stop()` message). `DATASET.R` additionally checks several pipeline
invariants against their documented report values after the relevant stages
run and emits a **non-blocking warning** if any is out of band (row counts,
species-resolution cache sanity, etc.) — see the script's "warn-band
post-conditions" section for the full list and each check's report source.

### Common schema — `uncurated_raw_combined.csv` (17 cols)
source · native_cas · casnumber_grouped · chemicalname_grouped · scientificname ·
medium (Freshwater/Marine/Unknown) · test_class (chronic/subchronic/acute) ·
statistic_type · effect_category (controlled vocab: MORT, GRO, REP, IMM, DVP,
HAT, PSE, POP, LUM, ABD, BEH, BCH, MOR) · duration_hours · life_stage ·
conc_value · conc_unit (ug/L or mg/L) · acr_eligible (statistic_type ∈
{EC50,LC50,IC50}) · study_reference · source_id · acr_applied.

Stage 4c adds: within_source_duplicate, dedup_retained, priority_kept (chronic >
subchronic > acute, applied as cross-source duplicate resolver), dedup_note.
Stage 4d Part 3 adds: original_scientificname, accepted_name (**the Stage 4e
aggregation species key**), synonym_unified, kingdom/phylum/class/order_taxon/
family/genus, majorgroup(=class), taxonomy_provenance, resolution_status.

### Schema — `uncurated_raw_aggregated.csv` (Stage 4e output)
One row per casnumber_grouped × accepted_name × medium. Per-row dedup audit cols
are dropped; provenance is summarised. Columns: casnumber_grouped,
chemicalname_grouped, accepted_name, medium, conc_ug_L (species-level minimum
after Steps 1–3), **effect_category** (traditional code of the selected endpoint;
C1 carry-through), majorgroup, kingdom, phylum, class, order_taxon, family, genus,
taxonomy_provenance, n_records, sources_contributing, any_acr_applied,
any_conc_flagged, geomean_flagged, lifestage_mixed, duration_mixed, **value_tier**
(accepted / chronic_converted / acute_acr), **any_chronic_conv_applied**.

### ANZG method reference
Authoritative method: **Warne et al. 2025** (PDF in the Claude project). Key
sections:
- **§3.2.4 hierarchy of statistical estimates**, "in order of preference":
  (1) accepted negligible-effect — NEC, NSEC, BEC10, NOEC, NOEL, EC/IC/LCx
  x≤20 (used as-is); (2) chronic median/low-effect — EC50/IC50/LC50, LOEC,
  MATC (need conversion, §3.4.2.1); (3) acute EC/IC/LC50 via ACR (§3.4.2.2).
  Chronic-converted ranks **above** acute-converted.
- **§3.4.2.1 chronic conversions**: EC/IC/LC50 ÷5, LOEC ÷2.5, MATC ÷2 → chronic
  negligible-effect. A conditional fallback when preferred data are insufficient,
  not an automatic per-record transform.
- **§3.4.2.2 ACR**: default ACR = 10; only acute EC/IC/LC50 may be converted;
  acute NOEC/LOEC/MATC/non-50 ECx must NOT be used.
- **§3.4.4 one value per species**: geomean within endpoint × statistic_type ×
  life_stage × duration; lowest within endpoint; lowest across endpoints. Never
  geomean across different statistic_type / life_stage / duration.
- **§3.4.5 sufficiency**: this pipeline uses resolved `class` directly (not ANZG
  Table 5 groups) — see Key Design Decisions.

### Environment note
The anztox pipeline needs the live `infogathering` PostgreSQL DB (Windows
Positron only): `data-raw/alldata/scripts/stage4b-extract.R` and the anztox parts of
Stage 4d Part 1.5. All other Stage 4+ scripts run on WSL or Windows.

---

## 5. Pipeline status — Issue #33

**Goal:** `ssd_data_sets(set = "all_chronic")` returns an aggregated,
deduplicated dataset across all sources.

GitHub context: PR #43 (`add_media_wqbench`) merged to main. Issue #34 (ccme
medium/exposure) RESOLVED 2026-07-06 — data supplier (Angeline, CCME)
confirmed "all the data are for chronic exposures in freshwater media", so the
pipeline's Freshwater + curated-chronic treatment of ccme is correct. Remaining
open sub-item from the issue thread: adding the official CCME guideline values
to ssdfits (separate enhancement, not blocking).

Stages 1–7 are complete, including the Stage 6/7 redesign (named-list output;
see §6). The pipeline is functionally complete.

Stage numbering note: Stage 4d = species resolution + majorgroup; Stage 4e =
aggregation (units normalisation, formerly "Stage 5", folded in). Stage 5 no
longer exists as a standalone step (heading retained in the vignette for
reference continuity).

### Stages 1–4d (complete — one-line status)
- **1 Schema audit:** `data-raw/alldata/scripts/stage1-schema-audit.md`.
- **2 CAS/name alignment:** master lookup built through 2e; 18 UNCERTAIN rows.
  Vignette `cas_parent_lookup_build.qmd`.
- **3 Media assignment:** all sources have a medium; ccme Freshwater
  (confirmed by supplier, Issue #34), envirotox final Unknown.
- **4a–4c Extract + dedup:** three-source extract (anztox 15,667 / wqbench
  361,782 / envirotox 72,439); cross-source dedup before priority selection;
  effect_category harmonised. Clean subset entering 4d: 381,361 rows.
- **4d Species resolution:** context-aware WoRMS/GBIF resolution (99.22% of
  species), synonym unification, taxonomy join, majorgroup=class. Enriched
  output 449,860 rows. Clean subset (dedup_retained & priority_kept & not
  excluded): 381,333. Genus-rank entries flagged for Stage 4e exclusion.

### Stage 4e — Aggregation + statistic-type hierarchy (complete)
`data-raw/alldata/DATASET.R` (Stage 4e section, runs first). Implements §3.4.4 plus the §3.2.4/§3.4.2
statistic-type hierarchy. Pipeline:
1. Filter to dedup_retained & priority_kept; coerce "Not stated"→NA; wqbench
   mg/L→µg/L.
2. Drop NA effect_category (~23,567 rows); drop non-traditional effect_category
   (PSE/BCH/BEH/LUM/MOR; 54,709 rows); drop acute-non-eligible (acute non-50);
   drop genus-rank uncurated species (`flag_genus_rank()`).
3. **Statistic-type classification** → `stat_action` (accepted / convert /
   exclude), decimal-x ECx parser. Exclude tier (undefined ECx 20<x<50 or x>50;
   NOAEL/LOAEL/NOAEC/LOAEC/MCIG/MDEC/NO; unmatched) removed → audit CSV.
4. ACR ÷10 for acute EC/IC/LC50 (`acr_applied`).
5. **Chronic conversions** (§3.4.2.1): chronic/subchronic EC50/IC50/LC50 ÷5,
   LOEC/LOEL ÷2.5, MATC ÷2 (`chronic_conv_applied`, `chronic_conv_factor`).
6. Concentration plausibility filter (hard <1e-5 / >1e8 µg/L excluded; soft
   1e-5–1e-3 / 1e6–1e8 flagged, used only as fallback). `any_conc_flagged`.
7. **Three-tier preference** at casnumber_grouped × accepted_name × medium:
   keep only the best tier present — accepted (1) > chronic_converted (2) >
   acute_acr (3) — across all endpoints; `value_tier` per group.
8. §3.4.4 geomean (key includes statistic_type) → within-endpoint min →
   across-endpoint min.

Current output: **57,553 rows**, 5,585 chemicals, 2,936 species. value_tier:
accepted 12,730 / acute_acr 40,677 / chronic_converted 4,146. `effect_category`
of the selected endpoint retained as a column (C1 carry-through). Reports:
`stage4e-aggregation-report.md`, `stage4e-statistic-type-inventory.md`.

---

## 6. Stage 6/7 — Integration, medium logic, named-list build (complete)

Implemented in `data-raw/alldata/DATASET.R` (Stage 4e aggregation runs first,
followed by curated integration + medium viability/pooling + final build) and
`R/get_ssddata.R` (the `all_chronic` branch). The old flat 39,293-row
`allchronic_data` and the `alldata_integrated.csv` intermediate no longer exist;
DATASET.R builds `allchronic_data.rda` from Stage 4e output (in-memory) and the
curated `.rda` objects in a single run.

**Output shape:** `allchronic_data` is a flat tibble (one row per Species ×
Chemical × Medium) with a `Set` key column. `ssd_data_sets(set="all_chronic")`
returns `split(allchronic_data, Set)` — a **named list**, one element per emitted
set, keyed `{chemicalname}_{medium}` (e.g. `copper_marine`, `…_mixed`). 24
columns: Species, Conc, Chemical, CAS, Medium, Source, ValueTier,
AnyChronicConvApplied, EffectCategory, Class, Kingdom, Phylum, Order, Family, Genus,
TaxonomyProvenance, NRecords, SourcesContributing, AnyAcrApplied, AnyConcFlagged,
GeomeanFlagged, LifestageMixed, DurationMixed, Set.

**Step B0 — short-term scope exclusion (runs FIRST, before B1/B2/B3):** rows whose
`casnumber_grouped × medium` matches a `scope == "exclude_from_chronic"` entry in
`data-raw/alldata/short_term_curated_sets.csv` are removed from **all** sources
(source-agnostic). Sole current entry: **chlorine × Marine** — the ANZG 2026 marine
chlorine DGV is a short-term (acute, raw median-effect) guideline (Batley & Simpson
2020); CPO decays within days, so a chronic negligible-effect assessment is
inapplicable. B0 excludes 127 rows (anzg 29, csiro 30, uncurated 68), written to the
tracked audit `data-raw/alldata/stage6-shortterm-excluded.csv`. Scope is **per
medium, not per chemical**: uncurated chlorine Freshwater/Unknown data are retained
and treated as any other uncurated chemical (a `chlorine_mixed` set is emitted). B0
is now the sole gate keeping curated chlorine out of chronic (S6-D4 no longer fires
for csiro chlorine since species are populated).

**Change 1 — curated integration (per chemical × medium):**
- **anzg / ccme:** wholesale, as-is. If anzg present for a chemical × medium it
  IS that set (no screening/aggregation/supplementing); anzg > ccme (ccme dropped
  where both cover the same chemical × medium); everything lower-priority dropped
  for that combination. ANZG freshwater variants (Freshwater, Soft/Moderate/Hard
  freshwater, nitrate variants) are **never collapsed** — each is its own medium.
- **aims / csiro:** kept as-is (no statistic-type hierarchy, no conversions), but
  WoRMS/GBIF taxonomy resolved, and reconciled aims > csiro > uncurated at
  chemical × medium × species — each lower source adds only species the higher
  ones lack. **Within-source species duplicates (tropical/temperate leftovers)
  at chemical × medium × species are GEOMEANED to one value (not dropped, not
  errored);** assert one row per source × chemical × medium × species after.

**Change 2 — medium viability + pooling (per chemical):**
- A real-medium set (Freshwater family, or Marine) is **viable** if curated-backed
  OR its uncurated data meet ≥5 species / ≥4 distinct non-NA classes.
- Emit each viable real-medium set standalone (viable sets are NOT pooled).
- `_mixed` set = rows NOT in any emitted real-medium set (i.e. non-viable
  real-medium rows + Unknown rows). **If BOTH Freshwater and Marine are viable,
  Unknown is dropped and no mixed set is emitted** (option a). The mixed set is
  emitted only if it itself passes ≥5 species / ≥4 classes.
- Consequence: curated mediums are always viable → never pooled; the mixed pool
  is uncurated-only in practice. No overlap between mixed and standalone sets.

**Provenance (Option A):** curated rows carry `ValueTier = "curated"` and
`AnyChronicConvApplied = FALSE`. Uncurated rows keep their Stage 4e value_tier.

**Sufficiency:** uncurated only (curated bypass). Threshold ≥5 species / ≥4
distinct non-NA `class`.

**Curated NA-species (S6-D4):** rows from curated sources with no species name
are dropped at load (never coined into a placeholder taxon), guarded by a validation
check that no final `Species` is NA/empty/placeholder. **Note:** csiro chlorine/marine
now carries species (reconstructed from Batley & Simpson 2020), so S6-D4 no longer
removes it — those rows are excluded by Step B0 (short-term scope) instead.

**Final structure:** `allchronic_data` = **26,536 rows / 1,525 sets / 1,180
chemicals / 2,796 species** (~397 KB). Sets by medium: freshwater 860, marine 235,
mixed 427, plus one each of soft/hard/moderate freshwater. ValueTier: acute_acr
16,724 / accepted 6,371 / chronic_converted 2,700 / curated 741. Source: uncurated
25,795 / anzg 563 / ccme 98 / csiro 60 / aims 20. 13 validation checks pass (V13 =
no short-term-excluded chemical × medium present). Reports:
`stage6-integration-report.md`, `stage7-eligibility-report.md`,
`stage6-shortterm-exclusion-report.md`.

---

## 7. Key design decisions

- `anon_` excluded (no chemical name). Curated sources handled separately from
  the consolidated-first uncurated sources.
- Cross-source dedup BEFORE priority selection (I2): chronic from a lower-priority
  source not displaced by acute from a higher-priority source.
- Taxonomy resolution BEFORE aggregation (4d before 4e); synonym unification is
  essential because the geomean groups by species. The Stage 4e species key is
  **`accepted_name`**, not `scientificname`.
- **Sufficiency groups = resolved `class`, not ANZG Table 5** (deliberate
  deviation; simpler, reproducible, matches wqbench `n_distinct(class) >= 4`;
  these data are for methodology testing, not official GV derivation).
- `majorgroup` = `class` in intermediates; dropped from final output.
- **Genus-rank handling is asymmetric:** uncurated genus-rank entries EXCLUDED at
  Stage 4e (a genus ID may represent several species; R1 reversed 2026-06-26);
  curated retained per curators' judgement (curated never pass through 4e).
- **ANZG Medium has five freshwater variants — never collapse them, ever.**
- envirotox medium = Unknown; ccme = Freshwater and chronic (Issue #34
  RESOLVED 2026-07-06 — supplier confirmed all ccme data are chronic
  exposures in freshwater media).
- **Short-term curated scope (B0):** curated chemical × medium combinations derived
  from short-term (acute) guidelines are out of scope for `allchronic_data` and are
  excluded from all sources via the `short_term_curated_sets.csv` registry, BEFORE
  the source-priority gates. Keyed on `casnumber_grouped × medium` (per medium, not
  per chemical), NOT on the acute/chronic toxicity-measure label (that label is
  unreliable provenance — e.g. ANZG fipronil is a chronic DGV whose values are
  already acute-to-chronic converted yet still labelled "Acute LC50"). Sole entry:
  chlorine × Marine. Registry is extensible.
- Source priority: **anzg > ccme > aims > csiro > uncurated**, exclusion at
  casnumber_grouped × medium (any higher-priority data for a chemical × medium
  excludes ALL lower-priority rows there).
- Statistic-type hierarchy (Stage 4e): accepted (used as-is) > chronic_converted
  (§3.4.2.1 factors) > acute_acr (ACR ÷10), preferred per species × chemical ×
  medium; exclude tier has no defined Warne treatment. Per-species (not
  per-chemical) operationalisation of the §3.4.2.1 fallback — a documented
  deviation suited to a one-value-per-species dataset.
- Units target µg/L (wqbench mg/L converted in Stage 4e). anztox
  `concentrationused` µg/L. "Chronic QSAR" anztox rows (632) dropped.
- ECOTOX true-duplicate preference among uncurated: wqbench > anztox > envirotox.
  wqbench's 25.1% within-source duplicate rate is intrinsic to
  `wqb_create_data_set()` structure, not a defect; wqbench's own endpoint
  hierarchy is bypassed (raw ECOTOX endpoints are intercepted and the hierarchy
  is applied in Stage 4e instead).
- Cross-source dedup key: native_cas × scientificname_norm × medium ×
  statistic_type_norm × effect_category × duration_hours (exact) × conc_ug_L
  (0.1% tol). life_stage retained where available but excluded from the dedup
  key; included in Stage 4e grouping (NA = distinct level, same as duration).
- Stage 4e geomean >1 OOM rule (D2): if max/min > 10 in a group, use min() and
  set `geomean_flagged` (conservative; preserves audit trail).
- csiro_chlorine_marine: species reconstructed from Batley & Simpson 2020 (30 rows);
  excluded from chronic via the B0 short-term registry (not the NA-species drop).
  Short-term (acute) data — destined for a future `all_short` pipeline.

---

## 8. Deferred / future (not blocking)

- Post-pipeline data deposit (after redesign stable): Zenodo DOI primary +
  `piggyback` GitHub Release convenience download + `ssd_download_alldata_raw()`
  helper. Pre-conditions: confirm redistribution licence terms for anztox/
  wqbench/envirotox; institutional data governance.
- `all_short` pipeline (would reuse the DATASET.R + named-list pattern; seeded by
  the short-term curated sets, e.g. chlorine × Marine, per `short_term_curated_sets.csv`).
- Stages 1–4 script consolidation into `data-raw/` structure.
- Full `git filter-repo` purge of large CSVs from remote history.
- Minor open items: 40 species with cross-source kingdom/phylum disagreement;
  wqbench SQLite per-row IDs could improve within-source dedup; 12 no_taxonomy
  species (28 rows) hard-excluded at Stage 4d Part 3.

---

## 9. Prompt log

Session logs in `prompts/alldata/` (create if absent), one kebab-case file per
session; append if the file exists. Format:

```
## Session: <descriptor>
Date: <YYYY-MM-DD>
Model: <model + version>

### Prompts and Responses
**User:** <prompt>
**Claude:** <summary; full code blocks where relevant>
---
```

---

## 10. Vignette — `vignettes/alldata_pipeline.qmd`

Primary methodological reference for the pipeline, written for an external
reader. **The user edits it directly.** Claude (planning sessions) produces draft
stage additions as downloadable `.md` snippets; the user reviews/edits/pastes.
**Claude Code's only vignette role** is replacing confirmed `<!-- STAGEXX: … -->`
numeric placeholders from an audit report — nothing else.

Workflow per stage: run stage → share audit report in planning → Claude
interprets, updates this file, drafts the vignette section → user edits/pastes →
placeholders replaced. Each stage update covers: stage summary (what/why, key
counts, deviations, report cross-ref), Appendix A decisions row(s), Appendix B
deviations row(s) if any, and the data-flow row count. Do not modify earlier
stages' appendix rows.
