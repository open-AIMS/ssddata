## Session: stage2c-consistency-check
Date: 2026-06-23
Model: Claude Sonnet 4.6 (claude-sonnet-4-6)

### Prompts and Responses

**User:** Perform a consistency audit (reporting only, no edits to the
lookup table) of the completed 587-row CAS parent lookup at
`scripts/stage2b-full-results-combined.csv`. Six checks requested: (1)
duplicate CAS with conflicting parents; (2) chemical-class consistency
across seven groups — alkali-metal halides, alkaline-earth salts, arsenic
compounds, nutrient oxyanions, organophosphate insecticides, HCl/HBr organic
salts, esters; (3) confidence-by-category cross-tab with unexpected-combo
flags; (4) missing parent CAS on resolved rows; (5) CAS dashed-format and
dashed-vs-nodash validation; (6) cross-reference against the original
41-row human-curated lookup. Save a re-runnable script to
`scripts/stage2c-consistency-check.R` and a structured report to
`scripts/stage2c-consistency-report.md`, ending with a consolidated
"decisions required" list (phrased as yes/no questions) and a separate
"resolvable programmatically" list.

**Claude:** Read `CLAUDE.md` (both the parent R-environment file and the
repo-level file), `data-raw/anztox/speciation_convention.md`, and
`scripts/stage2b-pilot-report.md` first, then `prompts/stage2b-full-run.md`
in full to recover the conventions established across Stage 2b's three
sessions (Part 1, Part 2, and the Batch 6 manual-review pass) before
designing any check, since several of the groups named in the brief
(Ca/Mg-vs-Barium, alkali halides, heavy-metal-overrides-nutrient-ion) are
documented only in that prompt log, not in `speciation_convention.md`
itself.

Confirmed `scripts/stage2b-full-results-combined.csv` has exactly 587 rows
and zero duplicate `casnumber` values. Derived a canonical 4-way category
classification from `proposed_match_rationale` text (`direct`, `transform`,
`MIXTURE OR PSEUDO-CAS`, `UNCERTAIN`) and validated the resulting counts
(316 / 246 / 19 / 6) against the totals already published in
`prompts/stage2b-full-run.md` before trusting the classification for the
rest of the audit. The first version of the `direct` vs. `MIXTURE` split
used a bare `grepl("mixture")`, which produced 5 false positives (rows
whose `direct` rationale text used "mixture" descriptively, e.g. "alkyl
chain mixture from coconut oil") — fixed by anchoring on the literal label
`"MIXTURE OR PSEUDO-CAS"` instead.

Worked through each of the 6 checks interactively against the live data
before writing the script, to calibrate regex patterns against real
chemical-name variants rather than guessing. This surfaced two further
false positives in the first script draft, both fixed before finalising:
- Check 2d's "bare nutrient-ion" filter initially used `nchar(chemicalname)
  < 20` as a proxy for "this row IS the ion, not a salt of it" — caught
  "Sodium phosphate" and "Potassium phosphate" (legitimate `transform`
  salts) as false `direct` candidates. Replaced with a direct check against
  the `is_direct` category flag.
- Check 2g's pesticide-acid-ester detector used a bare `"2,4-D"` substring
  match, which incidentally matched inside the unrelated IUPAC fragment
  "2,4-Dichlorophenoxy" for a `mixt. with` row (CAS 57571058), flagging it
  as a false inconsistency. Fixed with a negative-lookahead
  (`2,4-D(?![a-z])`) and by excluding rows already classified as
  `MIXTURE OR PSEUDO-CAS` from the pesticide-acid check entirely.

**Findings (full detail in `scripts/stage2c-consistency-report.md`):**
- Check 1: no duplicate CAS rows.
- Check 2a (11 alkali halide rows): all resolve to the halide ion,
  consistent but flagged as a judgment call (D1) since halides aren't named
  in the speciation convention doc.
- Check 2b (14 alkaline-earth rows): Barium always → element; Calcium/
  Magnesium → anion when one exists, else → element; Strontium follows the
  Ca/Mg pattern. Internally consistent within each metal group, but the
  Ba-vs-Ca/Mg split (D2) and the Sr classification (D3) are both unconfirmed
  judgment calls already flagged in the Stage 2b log.
- Check 2c (3 arsenic rows): all resolve to elemental Arsenic per
  `speciation_convention.md`. No issue.
- Check 2d: the 3 true bare-ion entries are correctly `direct`; a 134-row
  broader scan found zero rows that overshoot the ion to the bare element.
  Noted but did not treat as an inconsistency: heavy-metal cations (Fe/Co/
  Ni/Zr/Be) override the nutrient-ion convention and resolve to the metal —
  documented in the prompt log but not yet in `speciation_convention.md`
  (D4).
- Check 2e: no rows in this population match the OP-specific suffixes; a
  broader phosphate scan confirms the OP pesticide active ingredients and
  oxon metabolites present in this batch are all correctly `direct`.
- Check 2f (51 HCl/HBr rows): 49/51 resolve to the free base; the 2
  exceptions (Thiamine chloride hydrochloride, Amprolium hydrochloride) are
  justified — both have a permanently-charged heteroaromatic core with no
  neutral free-base form, the same logic already applied to quaternary
  ammonium salts elsewhere in the lookup.
- Check 2g (11 ester rows): the registered-pesticide-acid vs.
  industrial-ester split is fully consistent once the regex false positive
  above was fixed; a wider scan adding non-ester salts of the same acids (16
  more rows) found no further inconsistencies.
- Check 3: confidence/category cross-tab has no unexpected combinations —
  zero `direct + low`, zero `transform + high + missing CAS`; the single
  `transform + low` row was already flagged in the Stage 2b log for an
  unrelated reason (organolead toxicology).
- Check 4: 12 `transform` rows have an identified parent name but a blank
  parent CAS (all medium confidence) — a stronger gap than the "unverified
  CAS" framing in the Stage 2b log suggested, since no CAS was recorded at
  all for these 12, not just an unconfirmed one (D5).
- Check 5a: 1 row (CAS 5471089, Phenethylamine) has a malformed dashed CAS
  (`6-40-4`) that does not match the real-world registry number (`64-04-4`)
  — both the dashed and nodash fields appear to share the same dropped-digit
  error, so this is a substantive data error, not just an internal mismatch
  (D6).
- Check 5b: 2 further rows (Urea sulfate CAS 21351393, 1,2-Propanediamine
  acetate CAS 56896685) have a nodash field that doesn't match the dashed
  field with dashes stripped — in both cases the dashed value matches the
  known real-world CAS and only the nodash field dropped a trailing digit,
  so these are mechanically fixable without a judgment call.
- Check 6: 0 of the original lookup's 40 data rows (`data-raw/anztox/cas_parent_lookup.csv`
  — 41 lines including header, not 41 data rows) appear in the 587-row
  Stage 2b file, as expected, since that population was already resolved
  before Stage 2b began. Cross-checked all 40 directly against the master
  `data-raw/cas_parent_lookup_all.csv` and confirmed every `parent_casnumber`
  is unchanged — no silent overwrite occurred.

Wrote `scripts/stage2c-consistency-check.R` (self-contained, reproduces every
figure in the report on re-run) and `scripts/stage2c-consistency-report.md`
(structured per the requested template, ending with 6 numbered
"decisions required" questions and a short programmatic-fix list covering
the two mechanically-correctable CAS mismatches). No changes were made to
`scripts/stage2b-full-results-combined.csv` or any other existing file.

---
