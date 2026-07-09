## Session: Task A — parent-lookup coverage-gap correction (8 salts + ammonia alias)
Date: 2026-07-09
Model: Claude Fable 5 (claude-fable-5)

### Prompts and Responses

**User:** Task A — correct the parent-lookup coverage gap: add 8 mis-grouped salt
CAS + 1 trailing-zero ammonia alias to `data-raw/cas_parent_lookup_all.csv`, run
the consistency check, rebuild `allchronic_data`, and make three surgical vignette
corrections. Do not add the 5 synthetic placeholders (Task B). No DB, no git.

**Claude:**

**A1/A2 — 9 rows appended.** Master lookup grew 6,336 → 6,345 rows (9 cols incl.
`excluded`). Parent representation for each new row copied verbatim from an existing
sibling of the target element (all 9 passed the verbatim-sibling guard). Native
chemical names recovered from `uncurated_raw_combined.csv` (`chemicalname_grouped`).
Ammonia check-digit verified in code: `76644170` fails the CAS check digit; dropping
its trailing zero → `7664417` (ammonia `7664-41-7`), which is valid and already in
the lookup. Yb/Y guard: neither `10361918` nor `10361929` is the elemental CAS
(elementals `7440-64-4`/`7440-65-5` already present as self-rows), so both added as
transform rows to the elemental parent — self-row branch NOT applied. All 9
`human_checked = "n"`, `excluded = FALSE`, provenance recorded in `notes`.

**A3 — consistency check.** Ran stage2c-equivalent checks on the master lookup:
existing 6,336 rows byte-identical (unaltered), 0 duplicate CAS, all 9 new rows carry
a parent CAS, new-row dashed/nodash agree, new-row dashed format valid. Whole-file
scan flagged 5 pre-existing dashed/nodash mismatches (tributyltin-oxide parent
`56-35-9`/`56360`) — confirmed present in git HEAD, unrelated to Task A, left
untouched.

**A4 — propagated into `allchronic_data`.** stage4b-extract.R needs PostgreSQL (not
available on WSL); since dedup keys on `native_cas` and taxonomy on species, the
lookup fix changes only `casnumber_grouped`/`chemicalname_grouped` for the 9
`native_cas`. Surgically re-grouped those (31 rows) in
`uncurated_raw_dedup_enriched.csv`, replicating stage4b's
`coalesce(parent, native)` — verified only those two columns on exactly those rows
changed, all other columns byte-identical. Re-ran DATASET.R (36s, all 16 validation
checks PASS). Result: final `allchronic_data` unchanged in counts (26,536 rows /
1,525 sets / 1,173 CAS / 1,180 chem / 2,796 species); no rows added/removed; exactly
ONE concentration corrected — *Sparus aurata* marine ammonia 3638→270 µg/L
(NRecords 2→5) from the repaired `76644170` records. The 8 metal salts fold into
element groups at source/grouping level but change nothing in the final aggregate
(species already dominated or filtered at Stage 4e dedup). Source-CSV join gap
14 → 5 (synthetic placeholders `1`, `100000001`–`4` only).

**A5 — three vignette edits (surgical).** C1 & C2 in
`cas_parent_lookup_build.qmd` (expanded lookup now read by stage4b-extract.R;
anztox not independently enumerated); C3 in `alldata_pipeline.qmd` (587 → 6,345
rows). Each matched exact source text.

---
