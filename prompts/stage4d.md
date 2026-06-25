## Session: stage4d-part1-species-resolution-diagnostic
Date: 2026-06-24
Model: Claude Sonnet 4.6

### Prompts and Responses

**User:** Requested the Stage 4d Part 1 species name resolution
diagnostic. Extract distinct `scientificname` values from the final
clean subset of `uncurated_raw_dedup.csv` (`dedup_retained` &
`priority_kept` both TRUE), submit each name as-is (no normalisation) to
WoRMS (primary) with GBIF as fallback for WoRMS `no_match`/`api_error`
only, and report resolution status, taxonomic hierarchy, and habitat
flags. Explicitly diagnostic only — no fixup applied to any existing
file. Detailed spec covered: package checks (taxize, worrms, rgbif,
dplyr, readr, purrr, tibble) with install-command guidance if missing;
a resumable on-disk cache keyed by raw species string, checkpointed
every 100 species; five-way WoRMS status classification (exact /
exact_unaccepted / fuzzy / ambiguous / no_match / api_error); GBIF
fallback classification (gbif_exact / gbif_fuzzy / gbif_no_match /
gbif_api_error); a summary CSV with one row per unique species; and a
nine-section markdown report (input summary, resolution status
overview, taxonomic hierarchy distribution, sample unresolved species,
sample fuzzy/unaccepted matches, all ambiguous matches, API error
summary, habitat coverage check, recommendations for Part 2). User
granted permission up front to install taxize/rgbif (worrms was already
present).

**Claude:** Confirmed git status (only `CLAUDE.md` had uncommitted
changes; the target CSV was clean/committed) and read both `CLAUDE.md`
files per instruction. Verified `uncurated_raw_dedup.csv` is 449,888
rows × 21 cols and the final clean subset is 381,410 rows across 4,348
distinct `scientificname` values, confirming the numbers already
recorded in the project `CLAUDE.md`. Installed `taxize` and `rgbif` (R
4.5.2, WSL). Before writing the production script, ran small
exploratory queries against `worrms::wm_records_name()` and
`rgbif::name_backbone()` to characterise actual API response shapes —
this surfaced two design points not obvious from the package docs:

1. `wm_records_name()` defaults to `marine_only = TRUE`, which would
   silently exclude freshwater/terrestrial taxa (the package's own help
   page recommends `marine_only = FALSE` for non-marine genera). Set
   `marine_only = FALSE` explicitly given this dataset spans Freshwater,
   Marine, and Unknown media.
2. `fuzzy = TRUE` causes WoRMS to return a wide "like"-style candidate
   set for many ordinary binomial queries (e.g. `Oncorhynchus mykiss`
   also returns its own named subspecies), which inflates the literal
   "ambiguous" bucket (`nrow > 1`) well beyond genuine taxonomic
   ambiguity. Kept the literal classification rule as specified (this is
   diagnostic-only, no fixup), but added an `n_unique_names` /
   `n_records` distinction in Section 6 so the report itself
   distinguishes "false-alarm" ambiguity (multiple records, one
   underlying valid name) from genuine multi-candidate ambiguity, and
   surfaced the split count in the Section 9 recommendation.

Wrote `scripts/stage4d-species-resolution-diagnostic.R` (single script,
covers extraction, caching, WoRMS/GBIF resolution loop, summary CSV, and
report generation — no DB connection required). Before running the full
4,348-species job, validated the whole pipeline end-to-end on a small,
deliberately diverse test slice (redirected to scratchpad paths): a
common exact match (`Daphnia magna`), a known synonym
(`Palaemonetes pugio` → `Palaemon pugio`), a genus-only ambiguous query
(`Daphnia`), a clearly fake name (`Zzzznotaspecies123`), a family-level
name (`Copepoda`), a "Genus sp." placeholder (`Chlorella sp.`), the
literal `-` placeholder found in the source data, and one genuinely
malformed row discovered during exploration (an embedded-newline,
duplicated-text `scientificname` value). This caught a real bug: WoRMS
returns HTTP 404 (not 204) for "Genus sp."-style queries, which the
initial classifier was misreading as `api_error` instead of `no_match`
— fixed by broadening the no-match regex to `"204|404"` with a comment
explaining why both codes are treated as "no taxon found." Re-validated
after the fix before running the real job.

Ran the full resolution pass in the background (~13 minutes for all
4,348 species against the live WoRMS API, polite 0.2s/0.1s rate
limiting per the spec, checkpointed every 100 species). No API errors
occurred. Outputs:

- `data-raw/alldata/species_resolution_cache.rds` — raw resolver
  responses keyed by raw species string (1.3 MB).
- `data-raw/alldata/species_resolution_summary.csv` — one row per
  unique species (4,348 rows; `n_rows` sums exactly to 381,410).
- `data-raw/alldata/stage4d-species-resolution-report.md` — full
  9-section diagnostic report.

After the first full run, reviewed the report and caught a second,
more substantive issue before treating the report as final: Section
4 ("Sample unresolved species") explicitly excludes WoRMS-ambiguous
species, but Section 9's recommendation logic used
`resolved_by == "none"`, which (by construction) also catches
ambiguous species — inflating the "unresolved" count used for the
manual-review-feasibility recommendation from the true 113 species /
2,078 rows up to 1,192 species / 158,209 rows, and flipping the
recommendation from "small enough for manual review" to "not
practical for manual review." Fixed Section 9 to use the same
`combined_status %in% c("Unresolved (both failed)", "API errors")`
definition as Section 4, then re-ran the script — fast, since the
cache was already complete and no API calls were repeated.

Key findings from the corrected report (full detail in the report
itself):

- Resolution status (species / rows, out of 4,348 species / 381,410
  rows): WoRMS exact 1,191 / 166,676; WoRMS exact (unaccepted,
  synonym) 472 / 20,893; WoRMS fuzzy 52 / 1,281; WoRMS ambiguous 1,079
  / 156,131; GBIF exact (WoRMS fallback) 725 / 23,683; GBIF fuzzy
  (WoRMS fallback) 716 / 10,668; genuinely unresolved (both WoRMS and
  GBIF failed) 113 / 2,078; API errors 0.
- Of the 1,079 ambiguous species, 251 are "false alarm" (multiple raw
  WoRMS records, all tracing to one valid name) and 828 have genuinely
  distinct candidate names needing human judgement.
- 99 distinct classes observed, covering 98.3% of resolved rows with a
  non-NA class — workable for majorgroup derivation but with a longer
  tail than hoped; report recommends a phylum-level fallback for
  unmappable classes.
- Truly unresolved set (113 species, 2,078 rows, 0.54% of final clean
  rows) is small enough for full manual review.
- Habitat sanity check passed: of 1,715 WoRMS-resolved species, 1,002
  carry a freshwater flag, 649 marine-only, 117 both, 17 with no
  habitat data at all — consistent with the dataset's mixed
  Freshwater/Marine/Unknown media composition.

No existing file was modified — `uncurated_raw_dedup.csv` and all
other prior outputs are untouched. `CLAUDE.md` was explicitly left for
the user to update manually after reviewing the report, per
instruction.

---

## Session: stage4d-part1.5-source-taxonomy-extract
Date: 2026-06-25
Model: Claude Sonnet 4.6

### Prompts and Responses

**User:** Requested Stage 4d Part 1.5 — extract each source's own
(source-native) taxonomy for every distinct species in the final
clean subset, from each source's own data (anztox via live
`infogathering` Postgres DB, wqbench via its SQLite `species` table,
envirotox via its xlsx `taxonomy` sheet), and harmonise the three
per-source vocabularies into one controlled schema. Explicitly a
read-only intermediate artefact for Part 2 (context-aware WoRMS
querying) — the Part 1 WoRMS/GBIF cache is preserved untouched, no
existing pipeline file is modified. Detailed spec covered: schema
discovery for anztox's `species`/`animaltype`/`animalcategory`/
`speciesclass`/`speciesphylum` tables (diagram is a guide, not
authoritative); wqbench SQLite read matching Stage 4b's file
(`ecotox_ascii_12_11_2025`) with a documented fallback; envirotox
xlsx taxonomy sheet read; an 18-column harmonised output schema with
an explicit per-source field mapping table; vocabulary normalisation
(whitespace, sentence case, trailing punctuation); an anztox-specific
phylum→kingdom lookup (anztox has no native kingdom field); a
cross-source consistency diagnostic for species appearing in >1
source; a cross-check against Part 1's genuinely-unresolved species;
and a 7-section markdown report.

**Claude:** Read `CLAUDE.md` (both levels), the Part 1 report/summary
CSV, the ANZTOX vignette, and `data-raw/wqbench/DATASET.R` lines
30–60 per instruction. Confirmed R 4.5.1 is installed under
`C:\Program Files\R\R-4.5.1` but not on `PATH` in this shell — invoked
via explicit path for every R step this session. Verified live
connectivity to the `infogathering` Postgres DB from this Windows
shell (not WSL, consistent with project convention) and ran read-only
`information_schema` queries to confirm the actual anztox schema
before writing any extraction code:

- `species` table: `id, scientificname, commonname, status,
  majorgroup, minorgroup, isheterotroph, animaltype_id,
  animalcategory_id, class_id` — no direct `phylum_id`; phylum is
  reached only via `class_id → speciesclass.phylum_id →
  speciesphylum.id`, confirming the spec's join path.
- Of 6,078 species rows, `class_id` is populated for only 138
  (2.3%) — anztox's class/phylum taxonomy is much sparser than the
  diagram implies; `animaltype_id`/`animalcategory_id` are populated
  for ~65% but are coarse/functional categories (Fish, Invertebrate,
  Plant, Others; or named categories like "Sheepshead Minnow" mixed
  in with taxonomic ones); `isheterotroph` populated for only 129
  rows; `majorgroup` (62.5% populated) mixes 2-letter codes, full
  taxonomic names, and plain-English terms — confirms and quantifies
  the inconsistency flagged in Stage 4a.
- 60 of 6,078 `scientificname` values are duplicated in the raw
  `species` table.

Confirmed wqbench's sqlite `species` table (`ecotox_ascii_12_11_2025.sqlite`,
the file matching Stage 4b, present alongside the newer
`ecotox_ascii_06_11_2026.sqlite` that `DATASET.R` has since moved to)
has exactly the 19 documented columns, and envirotox's `taxonomy`
sheet has exactly the 10 documented columns — both matched the spec
with no fallback needed.

Wrote `scripts/stage4d-taxonomy-extract.R` (single script, Steps
2–10). Key implementation decisions, each documented in the script
header:

- **Duplicate raw rows.** A generic `collapse_by_key()` helper
  reduces each source's raw table to one row per join key, taking the
  first non-NA value per field and separately counting genuine
  conflicts (>1 distinct non-NA value for the same key) rather than
  silently picking an arbitrary row.
- **`source_trophic` for anztox left NA.** anztox's `animaltype`
  and `animalcategory` are already preserved losslessly as
  `source_animaltype`/`source_animalcategory`; mapping either onto
  `source_trophic` as well would just duplicate one of them under a
  different name.
- **anztox `kingdom` derivation.** Built a controlled
  phylum→kingdom lookup (Step 6) and cross-checked it against the
  Part 1 WoRMS/GBIF kingdom/phylum cross-tabulation (Section 3 of the
  Part 1 report) before finalising it, so anztox's derived kingdom
  scheme (Animalia/Plantae/Chromista/Bacteria/Protozoa/Fungi) is
  internally consistent with the scheme Part 1 already produced,
  rather than introducing a second, incompatible kingdom scheme. All
  19 phyla observed in anztox's `speciesphylum` table were covered;
  0 unmapped.
- **Output CSV completeness.** Initially built each source's
  taxonomy table from matched species only; caught before finalising
  that Step 7 requires one row per in-scope `(source, scientificname)`
  combination, not just matched ones — left-joined against the full
  Step 2 scope so unmatched species get explicit NA rows. This also
  fixes a subtler bug it would otherwise have caused in the Step 8
  cross-source check: a species nominally in 2 sources but matched in
  only 1 would otherwise have looked like a single non-NA value with
  no conflict ("agreeing") rather than "incomplete data".

Caught two bugs during validation before treating the report as
final:

1. A sequencing bug — the anztox field-availability counts (feeding
   the Section 2 report table) were computed before Step 6 filled in
   `kingdom` from `phylum`, so the first run reported anztox kingdom
   coverage as 0 instead of the correct 94/804. Fixed by recomputing
   after the kingdom-derivation step.
2. A more substantive one — Step 9's spec literally says "the 113
   species genuinely unresolved by Part 1 (`resolved_by == "none"`)",
   but `resolved_by == "none"` in `species_resolution_summary.csv`
   also catches all 1,079 WoRMS-ambiguous species (they never reach a
   single-record GBIF fallback query either, so they end up with
   `resolved_by == "none"` too) — the first run reported 1,192
   "unresolved" species, not 113. This is the exact same conflation
   the Part 1 diagnostic script's own report-generation code had
   already identified and corrected in its Section 9 (documented in
   this file's previous session entry) — but the fix lives in that
   script's local report logic, not in the `resolved_by` column
   itself, so it had to be re-applied here independently. Fixed by
   filtering on `gbif_status == "gbif_no_match"` instead (isolates
   rows where GBIF was actually queried and also failed), which
   reproduced the documented 113-species figure exactly. Added an
   explicit note in both the script and the report explaining the
   conflation, so a future reader doesn't hit the same trap.

Ran the full script end-to-end from Windows (DB connection + 174 MB
CSV read + sqlite read + xlsx read, a few minutes total). Outputs:

- `data-raw/alldata/species_source_taxonomy.csv` — 6,198 rows (one
  per in-scope `(source, scientificname)` combination: anztox 804,
  wqbench 3,805, envirotox 1,589), 19 columns.
- `data-raw/alldata/stage4d-taxonomy-inventory.md` — full 7-section
  report.

Key findings (full detail in the report itself):

- Match rates against each source's own taxonomy table: 100% for
  all three sources (anztox 804/804, wqbench 3,805/3,805, envirotox
  1,589/1,589) — every in-scope species was found in its own
  source's lookup table.
- Field availability: wqbench and envirotox are well populated down
  to family level (~99.7–99.9%) and reasonably populated at
  subphylum/superclass (59–68% / 18–28%); anztox is populated for
  kingdom/phylum/class only via the derived lookup (94/804, 11.7%) and
  has no subphylum/superclass/order/family/genus fields at all —
  anztox's richest native fields are actually `source_majorgroup`
  (82.7%), `source_animalcategory` (93.9%), and `common_name` (87.6%),
  not the taxonomic rank columns.
- Cross-source consistency (1,508 species present in >1 source):
  kingdom/phylum/class agree for ~63% where comparable, disagree for
  ~2%, and are incomplete (≥1 source NA) for ~35%. 40 species disagree
  on kingdom or phylum specifically — mostly either genuine
  classification-scheme differences (Monera vs Bacteria vs Eubacteria
  for cyanobacteria; Cyanophycota vs Cyanobacteria as phylum name;
  Magnoliophyta vs Tracheophyta for vascular plants) or real
  source-vocabulary variants (Rhodophyta vs Rhodophycota) rather than
  factual disagreement about the organism's identity.
- Part 1 unresolved cross-check: of the 113 genuinely-unresolved
  species from Part 1, 100 (88.5%) have at least a non-NA
  kingdom/phylum/class from source-native taxonomy (mostly "Genus sp."
  placeholders resolvable to genus + class even though the bare name
  failed WoRMS/GBIF) — source-native taxonomy substantially, but not
  fully, covers the Part 1 gap. The 13 still uncovered are mostly
  anztox-only literal placeholders ("-", "Algae", "Periphyton",
  "Invertebrates", strain-code variants) with no taxonomic content in
  any source.
- Recommendation for Part 2: class-first WoRMS query filtering is
  viable for wqbench/envirotox-only species; anztox-only species need
  a phylum or `source_majorgroup`/`source_animalcategory` fallback
  given class's 11.7% coverage.

No existing file was modified — verified via `git status` after the
run that only new files appear (`species_source_taxonomy.csv`,
`stage4d-taxonomy-inventory.md`, this script, and this log entry);
`uncurated_raw_dedup.csv`, `anztox_extracted.csv`, and all
`data-raw/anztox|wqbench|envirotox` source files are untouched. The
Part 1 cache/summary/report are untouched and were read only for the
Step 9 cross-check. `CLAUDE.md` was explicitly left for the user to
update manually, per instruction.

---

## Session: stage4d-part2-context-aware-resolution
Date: 2026-06-25
Model: Claude Sonnet 4.6

### Prompts and Responses

**User:** Requested Stage 4d Part 2 -- context-aware WoRMS resolution.
For each of the 4,348 distinct species in the final clean subset, pool
each species' own source-native taxonomy (Decision P3: the source with
the most non-NA fields among kingdom/phylum/class/order_taxon/family/
genus supplies all six, ties broken wqbench > envirotox > anztox), then
use that pooled context as a client-side filter to disambiguate WoRMS
candidate sets left ambiguous or unresolved by Part 1's bare-name query
(Decision C: tiered class -> phylum -> genus -> none fallback cascade).
"Genus sp." placeholders get a dedicated genus-level WoRMS query and are
written through at genus rank without being dropped or promoted
(Decision R1, explicitly scoped to the uncurated pipeline only -- see
CLAUDE.md caveat below). Two deliverables: a per-species resolution
table and a synonym audit table (raw names collapsing to the same
accepted_name) for Part 3 to consume.

**Claude:** Read `CLAUDE.md` (both levels), the Part 1 report, the Part
1.5 taxonomy inventory report, and this log, then inspected the actual
column structure of `species_source_taxonomy.csv`,
`species_resolution_summary.csv`, and the Part 1 cache's raw WoRMS/GBIF
response objects directly in R before writing any code.

**Engineering decision (flagged prominently, open to revision):** Part
1's cache already stores the full raw record set for the exact same
bare WoRMS query this stage would otherwise re-issue (ambiguous status
keeps the full multi-row set; exact/fuzzy/unaccepted keeps the one-row
result, which by construction was already the complete original result
since classify_worms() only returns those statuses when nrow == 1;
no_match/api_error keep zero rows / the error, nothing lost). Re-running
~4,348 identical bare-name HTTP calls against the live WoRMS API for
data already on disk would cost ~15 minutes for no scientific benefit,
so this script reads Part 1's cache as "the bare query result" and only
issues NEW network queries for genus-only lookups (a different query
string, Decision R1) and rare GBIF fallback gaps. This reduced the
expected runtime from ~15 minutes to under 2 minutes of actual query
time (558 distinct genus strings queried; everything else served from
cache).

Wrote `scripts/stage4d-context-aware-resolution.R`. Validated the core
cascade/filter logic interactively against known cases from Part 1's
cache (`Daphnia magna` exact, `Oncorhynchus mykiss`/`Cyprinus carpio`
ambiguous, a `Chlorella sp.` placeholder) before running the full job --
this caught two real issues that materially changed the design:

1. **Genus homonyms.** WoRMS has two unrelated genus-rank records named
   "Chlorella" (an accepted Plantae/Chlorophyta alga and an unaccepted
   Animalia/Ctenophora genus). The spec's genus-only query path as
   originally planned only checked for a single bare genus-rank match,
   which fails on homonyms like this. Fixed by applying the same pooled
   phylum -> class -> kingdom context narrowing to genus-level
   candidates, not just to species-level ones.
2. **Fuzzy-match noise dominates the "ambiguous" bucket, and no amount
   of taxonomic filtering can fix it.** `Oncorhynchus mykiss` and
   `Cyprinus carpio` both stayed `ambiguous_after_filter` even with
   correct class/phylum/genus context, because WoRMS's `fuzzy = TRUE`
   (kept from Part 1) pulls in subspecies-named records (e.g.
   "Oncorhynchus mykiss aguabonita") that share IDENTICAL higher
   taxonomy with the true match -- class/phylum/genus filtering cannot
   distinguish them by construction. Investigated how many of Part 1's
   1,079 ambiguous species have exactly one candidate record whose
   `scientificname` verbatim-matches the query string: 951 (88%). Added
   an exact-name-priority pre-filter (runs before the class/phylum/genus
   cascade, recorded as `filter_level_used = "exact_name_priority"` for
   auditability) -- this single addition was a far bigger contributor to
   resolving the ambiguous bucket than the originally-specified
   taxonomic cascade (1 species) combined. This is a deviation from the
   literal Part 2 spec (which only described the class/phylum/genus/none
   cascade), documented prominently in the script header and flagged
   here for the user's awareness.

First full run (4,348 species, 559 new network queries, ~background
job) completed the resolution loop successfully but crashed in Step 5
(CSV assembly) on species index 839 (`Chauliodes sp`) with "missing
value where TRUE/FALSE needed". Root cause: a GBIF backbone match can
return a record missing entire columns (not just NA values) when the
match is very coarse -- a KINGDOM-rank "fuzzy" match (GBIF guessing
"Animalia" for an unparseable name) has no phylum/class/order/family/
genus columns at all, so direct `rec$phylum`-style access returned NULL
instead of NA, breaking `is.na()` downstream. Re-applied Part 1's own
defensive `gbif_chr()` accessor (present in
`stage4d-species-resolution-diagnostic.R` but not carried over when this
script was first written) to fix the crash, and went further: checked
how many species dataset-wide were affected by Part 1 having accepted
this kind of coarse match as "resolved" -- 62, spanning KINGDOM (42),
PHYLUM (9), CLASS (6), ORDER (3), and FAMILY (2) ranks. Added a rank
floor (`is_meaningful_gbif_rank()`): only GENUS-rank-or-finer GBIF
matches are accepted as `gbif_resolved` here; coarser ones fall through
to `unresolved` instead of corrupting downstream majorgroup derivation
with a non-answer. Re-ran end-to-end (cache fully populated, 0 new
queries, seconds to complete) -- clean run, then fixed two cosmetic
report bugs (a broken two-string `add()` line concatenation and a
double-escaped `%%%%` printing literal `%%` instead of `%` in two Section
7 sentences) and ran once more for a clean final report.

Also added `species_resolution_cache.rds` and
`species_resolution_v2_cache.rds` to `.gitignore` -- the current
`CLAUDE.md` (Section 4, updated by the user before this session) already
documents both as files that "must remain untracked... and are listed
in `.gitignore`", but neither pattern actually existed in `.gitignore`
yet. Closed that gap rather than leaving the documented policy
unenforced.

Outputs (`data-raw/alldata/`, all well under the 5 MB tracked-file
threshold):

- `species_resolution_v2.csv` (1.1 MB, 4,348 rows, `n_rows` sums exactly
  to 381,410): `exact_filtered` 1,857 / `gbif_resolved` 973 /
  `exact_unaccepted_filtered` 758 / `genus_resolved` 594 /
  `ambiguous_after_filter` 84 / `unresolved` 64 / `fuzzy_filtered` 18.
  `filter_level_used` breakdown: `exact_name_priority` 951, `class` 890,
  `phylum` 681, `genus_only` 594, `genus` 102, `none` 1,130 (mostly
  already-trivial single-record Part 1 cases).
- `species_synonym_audit.csv` (47 KB, 546 rows): 254 `accepted_name`
  groups with >1 raw name, 130,124 rows affected by synonym unification
  -- largest groups: Danio rerio (2 raw names, 24,127 rows), Oncorhynchus
  mykiss (2, 20,194), Cyprinus carpio (4, 8,408).
- `species_kingdom_phylum_disagreements.csv` (62 KB, 597 rows): 40
  cross-source (carried from Part 1.5) + 583 resolved-vs-source-native.
  Spot-checked the high count before treating it as final -- it is
  driven by genuine, systematic vocabulary differences between source
  taxonomy and WoRMS/GBIF's current taxonomy (Bacillariophyta vs
  Heterokontophyta, Cyanophycota vs Cyanobacteria, Magnoliophyta vs
  Tracheophyta, etc., consistent with the 40 variants Part 1.5 already
  catalogued), plus a smaller set of genuine kingdom-level
  classification differences (e.g. wqbench files ciliates under
  Animalia; WoRMS/GBIF file them under Chromista) -- not a script bug.
- `stage4d-part2-report.md` (7.6 KB): full 7-section report, including a
  side-by-side Part 1 vs Part 2 status comparison and coverage of Part
  1's 1,079 ambiguous / 113 unresolved species specifically (943/1,079
  ambiguous species now resolved at some level; 61/113 previously
  unresolved species now genus-resolved).
- `species_resolution_v2_cache.rds` (1.2 MB, gitignored): 559 genus
  queries.

Headline result: 4,200 of 4,348 species (378,451 of 381,410 rows,
99.22%) now meet the "resolved enough to use" bar recommended for Part
3 (`exact_filtered`, `exact_unaccepted_filtered`, `fuzzy_filtered`,
`genus_resolved`, `gbif_resolved`), versus Part 1 where 1,079 species
(156,131 rows) were ambiguous and 113 species (2,078 rows) were
genuinely unresolved. The remaining 148 problem species (2,959 rows,
0.78%) are recommended for a manual review queue, not hard exclusion,
given the small size. 4,127 of 4,348 species (94.9%) have a resolved
class, supporting class-level majorgroup derivation in Part 3 with a
phylum-level fallback for the remainder.

**CLAUDE.md note required (not yet applied, left for the user per
instruction):** Decision R1 ("Genus sp." resolved at genus rank, not
dropped or promoted) applies ONLY to the uncurated pipeline handled in
this Stage 4d branch. "Genus sp." entries from curated sources (aims,
csiro, ccme, anzg), handled later in Stage 6/7, must be retained as
distinct species per the curators' own domain judgement -- this
decision must not be generalised to those sources.

No existing file was modified except `.gitignore` (two new ignore
patterns, see above). `uncurated_raw_dedup.csv`,
`species_resolution_cache.rds`, and `species_source_taxonomy.csv` were
read-only inputs and are untouched. `CLAUDE.md` was explicitly left for
the user to update manually, per instruction.

---

## Session: stage4d-part2-source-native-fallback
Date: 2026-06-25
Model: Claude Sonnet 4.6

### Prompts and Responses

**User:** Requested a small standalone fixup for the 148 species left
`ambiguous_after_filter`, `unresolved`, or `api_error` by Stage 4d Part
2's context-aware resolution -- Decision U3 (partial use with
source-native taxonomy fallback). For each problem species, populate
any still-NA `resolved_*` hierarchy field from the species' pooled
source-native taxonomy (already carried in `species_resolution_v2.csv`
as `source_taxonomy_*` from Part 2's own Decision-P3 pooling step),
without ever fabricating `accepted_name`/`aphia_id`/`gbif_key`/
`rank_resolved` for unresolved species. Add a `taxonomy_provenance`
column to all 4,348 species so downstream stages can apply lower
confidence to fallback-derived records. Explicitly scoped to NOT touch
Stage 4d Part 3 (majorgroup derivation). Required idempotency: a second
run must detect an already-consistent `taxonomy_provenance` column and
exit without rewriting any output.

**Claude:** Read `CLAUDE.md` (both levels), the Part 2 report, and this
log per instruction, then inspected the actual column structure of
`species_resolution_v2.csv` and `species_source_taxonomy.csv` directly
in R before writing any code -- confirmed the six hierarchy fields are
named `resolved_kingdom/phylum/class/order/family/genus` (not
`resolved_order_taxon`; "order_taxon" is the pooling-table field name
used only in `species_source_taxonomy.csv`/the Part 2 report prose).
Confirmed the 148-species split (84 `ambiguous_after_filter` + 64
`unresolved` + 0 `api_error`) matches the Part 2 report exactly, and
that ALL 148 had fully NA `resolved_*` fields going in (the spec
anticipated partially-populated `ambiguous_after_filter` candidates,
but none occur in this dataset) -- simplifying Step 4 to a uniform
per-field "fill NA from source-native where source-native is non-NA"
rule with no special-casing needed. Verified structurally, across all
4,348 rows, that WoRMS-derived statuses always carry `aphia_id` and
never `gbif_key` and vice versa for `gbif_resolved` -- this justified
classifying `taxonomy_provenance` by `status` alone rather than
re-deriving "which API" per row.

`data-raw/alldata/species_resolution_v2.csv` is untracked (per the
project's git-awareness policy for Stage 4 intermediates) and was about
to be overwritten in place, so backed it up to `superceded/` first per
CLAUDE.md Section 7's untracked-file rule before running anything.

Wrote `scripts/stage4d-part2-source-native-fallback.R`. The fallback
and provenance logic are each a single shared function so the
idempotency check (run before any output is touched) and the real
computation can never drift apart -- the idempotency check recomputes
both in memory and compares element-wise against what's already on
disk, only short-circuiting (via `quit()`, writing nothing) if every
value matches exactly. Caught one design wrinkle before finalising: a
pre-existing Part 2 data quirk where one `exact_unaccepted_filtered`
species (`Cryptomonas obovata`) has a fully WoRMS-populated `resolved_*`
hierarchy (`aphia_id` present) but a NA `accepted_name` -- gating
`taxonomy_provenance == "worms_full"` strictly on "`accepted_name` is
non-NA" (as the spec's category list literally reads) would leave this
one row matching none of the five provenance categories. Resolved by
classifying on `status` membership alone (the structurally reliable,
verified-clean signal) and flagging the single-row anomaly explicitly
in the report rather than silently special-casing it or leaving it
uncategorised. Also tightened an initial draft that mixed
pre-computed external vectors into `dplyr::filter()` calls in a way
that would have stayed correct only as long as no later edit reordered
rows -- replaced with self-contained `status %in% problem_statuses`
filters and an explicit `n_fields_recovered` column on a dedicated
audit-only tibble (`species_resolution_v2_audit`, never written to
disk as `species_resolution_v2.csv` itself) before the report-writing
section was finalised.

Ran the script (seconds; no network calls, no DB connection). Verified
idempotency directly: ran it a second time immediately and confirmed
it printed the "already consistent, exiting" message and left all
three outputs byte-for-byte unchanged; then restored the pre-fixup
backup from `superceded/` and re-ran end-to-end to confirm the full
computation reproduces identical results (same counts, same report
content) before treating either run as final -- this also doubled as
the test for a markdown-formatting fix made to the Section 2 "note"
paragraph (an early draft split one sentence across several `add()`
calls, which rendered the species name awkwardly isolated on its own
line in the raw `.md` file; consolidated into one `paste0()` call).

Outputs (`data-raw/alldata/`, all well under the 5 MB tracked-file
threshold):

- `species_resolution_v2.csv` (1.16 MB): overwritten in place, original
  26 columns and row order preserved exactly, `taxonomy_provenance`
  appended as column 27, fully populated (0 NA) across all 4,348 rows.
  Distribution: `worms_full` 3,227 / `gbif_full` 973 /
  `ambiguous_partial` 84 / `source_native_fallback` 49 / `no_taxonomy`
  15.
- `species_resolution_v2_problem_species.csv` (31 KB, new): 148 rows,
  23 columns, sorted by status then `n_rows` descending -- before/after
  comparison for all six hierarchy fields plus the pooled
  `source_taxonomy_*` audit columns.
- `stage4d-part2-fallback-report.md` (8.3 KB, new): 5-section report.

Key findings (full detail in the report itself):

- 130 of the 148 problem species (88%) had at least one hierarchy field
  recovered from source-native taxonomy; 130 of 148 now have a non-NA
  `resolved_class` (was 0 of 148 before this fixup).
- Dataset-wide class-level coverage rose from 4,127/4,348 (94.9%) to
  4,257/4,348 (97.9%) -- clears the 95% threshold the Part 2 report
  flagged for majorgroup-derivation feasibility.
- Genuine residual (`no_taxonomy`): 15 species, 33 rows -- entirely
  anztox-only literal placeholders ("-", "Algae", "Periphyton",
  "Invertebrates", strain/typo-code variants like "Cpannonicus",
  "N. humilis") with no taxonomic content recoverable from any source.
  Recommended in the report as Part 3 hard-exclude or manual-review
  candidates given the small size.
- The remaining 133 problem species (84 `ambiguous_partial`, 49
  `source_native_fallback`) now carry at least a partial hierarchy and
  are usable in Part 3 with `taxonomy_provenance` carried forward as a
  lower-confidence marker.

No file other than `species_resolution_v2.csv` was modified.
`species_source_taxonomy.csv` was read-only (used for validation only --
the fallback itself reads the `source_taxonomy_*` columns already
pooled into `species_resolution_v2.csv` by Part 2's own pooling step,
per Decision P3, so no re-pooling happens in this script).
`uncurated_raw_dedup.csv` and Stage 4d Part 3 (not yet started) are
untouched. `CLAUDE.md` was explicitly left for the user to update
manually, per instruction.

---
