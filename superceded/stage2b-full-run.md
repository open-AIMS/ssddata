## Session: stage2b-full-run
Date: 2026-06-22
Model: Claude Sonnet 4.6 (claude-sonnet-4-6)

### Prompts and Responses

**User:** Process the first 300 of the ~587 `NEEDS HUMAN REVIEW` rows in the
CAS parent lookup (sorted by `casnumber` ascending), reasoning through each
one as a chemist would, applying the four-way rule demonstrated in the Stage
2b pilot (salt/oxide/derivative → simpler parent; ester or HCl/salt of an
organic base → parent acid/free base; already-parent → direct; mixture or
pseudo-CAS → unresolvable) plus the documented arsenic/nutrient-ion
speciation convention. Write results to
`scripts/stage2b-full-results-part1.csv` with columns `casnumber`,
`chemicalname`, `proposed_parent_cas_dashed`, `proposed_parent_casnumber`,
`proposed_parent_name`, `proposed_match_rationale`, `confidence`, `notes`.
Process all 300 rows without stopping early; record best guesses with notes
for uncertain rows rather than skipping them. Append a session log noting
category counts.

**Claude:** Read `CLAUDE.md`, `data-raw/anztox/speciation_convention.md`,
`scripts/stage2b-pilot-report.md`, and `scripts/stage2b-pilot-results.csv`
first to match the established quality standard and conventions.

Located the actual input at `data-raw/cas_parent_lookup_all.csv` (not
`data-raw/anztox/...` as named in the brief — same file the pilot used).
Filtered to `match_rationale == "NEEDS HUMAN REVIEW"` (confirmed exactly 587
rows), sorted by `casnumber` ascending (numeric), and took the first 300.

Before processing, grepped the already-resolved (non-review) portion of the
lookup table extensively to recover the project's actual working conventions
rather than relying solely on the four-way rule's stated examples, since the
existing table revealed several established patterns not explicit in the
brief:
- Quaternary ammonium/phosphonium and heteroaromatic onium halide salts
  (e.g. "...ium chloride") are kept **direct**, not resolved to a "free
  base" — the cation is permanently charged and has no neutral form
  (precedented by existing `Quaternary ammonium compounds...chlorides`
  entries). The same logic was extended to cationic dye salts
  (phenothiazinium, xanthenium, iminium, phenazinium, acridinium,
  indolium) on the strength of an existing `Malachite green oxalate →
  direct` entry.
- Simple industrial esters (alkyl acetates, alkyl/aryl phosphate esters,
  alkyl sulfate surfactants) are **not** collapsed to their parent acid —
  only esters/salts of a small set of **registered pesticide active
  ingredients** (2,4-D, 2,4,5-T, MCPA, Fenac, NAA, Paraquat) follow the
  ester/salt→acid convention, precedented by `Phosphoric acid, Tripropyl
  ester → direct` and `Ethyl chloroacetate → direct` alongside the
  pilot's 2,4-D ester examples.
- Organotin compounds mostly stay **direct** (no simpler parent), except
  where the lookup already treats one specific congener (Tributyltin) as
  its own "regulatory representative" parent — extended the same treatment
  to Triphenyltin (→ Fentin hydroxide, CAS 76-87-9) since it has an
  analogous registered-fungicide reference congener.
- Organoarsenic and organomercury compounds are **not** uniformly collapsed
  to elemental Arsenic/Mercury: organoarsenicals stay direct (precedented
  by `Cacodylic acid, sodium salt → direct`), but the specific
  "[X]mercuric/mercury + halide-or-anion" naming pattern already resolves
  to Mercury in several existing entries, so that narrower pattern was
  followed for the 4 organomercury rows encountered (flagged medium
  confidence each time, noting organomercury ≠ elemental Hg toxicology).
- Caught and corrected an internal inconsistency mid-run: the pilot had
  already resolved `Calcium oxide → Calcium` (high confidence). Initially
  treated `Calcium hydroxide` as a "major ion, stays direct" exception, then
  revised it (and the analogous Magnesium/Potassium/Sodium hydroxides
  encountered later) to resolve to the element too, for consistency with the
  pilot's own precedent — flagging the causticity-vs-metal-toxicity nuance
  at medium confidence for the alkali-metal cases.
- 7 CAS numbers overlapped between the pilot's hand-picked 30 and this
  numerically-sorted 300-row slice (Dichlorvos, Naled, Chlorfenvinphos,
  2,4-D 2-EHE, 2,4-D 1-butyl ester, Calcium oxide, Ceric oxide); reused the
  pilot's exact values for these rather than re-deriving them.

Processed all 300 rows in 6 batches of 50, building each batch as a small
Python script (source row data loaded programmatically from the filtered
input to avoid name-transcription errors; only the parent-CAS/name/rationale
judgments were hand-authored) and writing/validating each batch's CSV before
moving on. Combined all 6 batches into
`scripts/stage2b-full-results-part1.csv`, then verified: 300 rows, no
duplicate `casnumber`, row order and `chemicalname` values match the
filtered input exactly, no empty required fields.

**Category breakdown (300 rows):**
| Category | Count |
|---|---|
| Already the parent form (direct — no simpler parent) | 202 |
| Salt / oxide / ester / derivative → resolved to a simpler parent | 96 |
| Mixture or pseudo-CAS — cannot resolve | 1 |
| Uncertain — needs human review | 1 |

**Confidence breakdown:** high 266, medium 32, low 2.

The 2 low-confidence rows (Trimethyllead acetate → Lead; the Moxisylyte-type
HCl salt at CAS 964523) and the medium-confidence rows are flagged in the
`notes` column with the specific reasoning gap (e.g. organomercury/
organolead ≠ elemental-metal toxicology, unverified free-base CAS numbers for
several obscure pharmaceutical/dye intermediates, the causticity-vs-
metal-toxicity question for alkali-metal hydroxides, and one ISO-named
dinitrophenol ester — Dinoterb acetate — where direct-vs-resolve-to-parent
was a judgment call). Recommend a human reviewer pay particular attention to
these flagged rows, plus the organomercury and alkali-hydroxide convention
questions, before the next 287-row batch reuses the same conventions.

---

## Session: stage2b-full-run (Part 2)
Date: 2026-06-23
Model: Claude Sonnet 4.6 (claude-sonnet-4-6)

### Prompts and Responses

**User:** Process rows 301 through the end (287 remaining rows) of the same
587-row `NEEDS HUMAN REVIEW` population, applying the identical four-way rule
and speciation convention established in Part 1. Write results to
`scripts/stage2b-full-results-part2.csv` with the same columns as Part 1.
Then combine Part 1 and Part 2 into `scripts/stage2b-full-results-combined.csv`
and report summary counts by `proposed_match_rationale` category and
confidence level.

**Claude:** Read `CLAUDE.md`, `data-raw/anztox/speciation_convention.md`,
`scripts/stage2b-full-results-part1.csv`, and `scripts/stage2b-pilot-report.md`
first to calibrate against Part 1's conventions. Confirmed the filtered/sorted
input split exactly at the expected boundary (Part 1 ends at CAS 6369977;
this run's row 301 begins at CAS 6439674), and exported the remaining 287
rows for processing.

Before processing, grepped the already-resolved (non-`NEEDS HUMAN REVIEW`)
portion of `cas_parent_lookup_all.csv` to ground several new judgment calls
in actual table precedent rather than inference alone. This surfaced an
important confirmed precedent that Part 1 had not encountered: simple
alkali-metal salts of "nutrient" anions resolve to the **anion**, not the
metal cation (`Sodium nitrate → Nitrate`, `Sodium vanadate → Vanadium`,
`Sodium arsenite → Arsenic` all exist in the already-resolved table). This,
combined with Part 1's own established patterns (oxide/hydroxide → metal when
no anion-parent exists; acetate/carbonate/citrate/tartrate salts stay direct
as the whole salt; ammonium salts stay direct since "ammonium is not a
metal"), was extended into a single consistent framework for the many
major-ion salts encountered in this batch (Part 1 had almost none of these —
they cluster numerically in this later CAS range):

- **Heavy/trace/lanthanide metal cation + any simple anion → always resolves
  to the metal element**, regardless of anion (very well precedented:
  Fe/Co/Ni/Pd/Pt/Ti/Sn/Ga/Au/Ge/Nb/Zr/Th + lanthanides, chloride/sulfate/
  nitrate salts all → element, high confidence).
- **Major-ion alkali/alkaline-earth cation (Na/K/Li/Ca/Mg/Cs/Rb) + a
  documented "nutrient ion" (phosphate, sulfate, nitrite, nitrate) → resolves
  to the ion**, cation treated as spectator (**high** confidence — this is
  explicit project policy, not inference).
- **Same major-ion cations + chloride/bromide/iodide/fluoride → resolves to
  the halide ion** (medium confidence — a *novel* extension of the
  nitrate/vanadate/arsenite precedent to plain halides, since halides are not
  explicitly named "nutrients" in the speciation convention; flagged for
  reviewer in every row where this applies).
- **Major-ion cation + sulfide → Hydrogen sulfide** (Part 1's own established
  reference-analyte precedent, applied consistently to Ammonium sulfide and
  standalone "Sulfide" too).
- **Ammonium + simple anion with no metal of interest (halide, hydroxide) →
  stays direct as the whole salt** (Part 1's explicit "ammonium is not a
  metal" precedent). **Ammonium/sodium + a toxic-metal oxyanion (chromate,
  molybdate) → resolves to the metal**, since that rule takes priority over
  the simple-spectator pattern.
- **Barium → always collapses to element** regardless of anion, per Part 1's
  explicit decision to treat it as a trace metal of guideline interest
  distinct from Ca/Mg. Calcium/Magnesium, by contrast, were treated as common
  major ions whose simple salts resolve toward the anion (this is a
  **judgment call**, flagged in every affected row, since it sits in tension
  with the earlier Calcium oxide/hydroxide → Calcium precedent — that one
  only resolved to the element because no anion-parent existed for
  oxide/hydroxide).
- **Strontium** was treated as a Ca/Mg-like major ion (medium confidence,
  explicitly flagged as a judgment call with no precedent either way).
- **Metal/metalloid oxyanions (borate, chromate, selenite/selenate,
  molybdate, tantalate) → resolve to the element**, extending the documented
  Arsenic/Vanadium speciation logic to other guideline-relevant trace
  elements; Boron specifically reuses Part 1's own `Sodium borate → Boron`
  precedent.
- **Standalone ion entries** in this batch (Chloride, Nitrite, Sulfate,
  Fluoride ion, Phosphate, Borate, Chromate, Selenite, Selenate, Silicate,
  Sulfide, Arsenite, Arsenate) were each resolved using the same
  element-vs-ion split above, rather than reflexively marking every bare ion
  "direct" — e.g. Borate/Chromate/Selenite/Selenate point to their elements,
  while Chloride/Nitrite/Sulfate/Fluoride stay direct as themselves.
- **Two genuinely ambiguous mixed-metal compounds** (Silver vanadium oxide;
  Copper zinc hydroxide sulfate) were flagged `UNCERTAIN — needs human
  review` at low confidence rather than guessing a single dominant metal, since
  no precedent exists in this lookup for selecting between two co-occurring
  metals of independent toxicological interest in one compound.
- **Polymers and homopolymers** ("X polymer with Y", "...chloride,
  homopolymer") were treated as **direct, single defined macromolecular
  substances**, distinct from the `mixt. with`/`compd. with` formulation
  pattern that resolves to `MIXTURE OR PSEUDO-CAS`.
- A defined **metabolite of a registered drug** (Ranitidine S-oxide) was kept
  **direct as its own analyte** rather than folded back into its parent drug,
  by analogy with Part 1's oxon-metabolite precedent (Paraoxon/Diazoxon stay
  direct rather than resolving to parathion/diazinon).
- The Stage 2b pilot's Arsenite "trap case" (CAS 15502746) was **upgraded
  from medium to high confidence**, since `speciation_convention.md` is now
  explicit documented policy rather than inferred precedent.
- 9 CAS numbers overlapped with the pilot's hand-picked 30 (Monocrotophos,
  Propaphos's neighbour Phosphamidon, Chlordimeform hydrochloride, Fluoxetine
  hydrochloride, Beryllium sulfate, and five lanthanide salts/oxides); reused
  the pilot's exact values for these.
- Several free-base CAS numbers for less-mainstream pharmaceuticals/dye
  intermediates (Oxprenolol, Dexpropranolol, Cartap, Morantel, Formetanate,
  several photographic-developer and fatty-amine intermediates) were
  provided at medium confidence from memory with an explicit note to verify,
  rather than left blank, since the numeric pattern (free base/salt CAS
  registered sequentially) gave a reasonable cross-check in most cases — but
  none of these were verified against an external source.

**Scope change mid-session:** after completing batches 1–5 (rows 1–250 of
the 287-row population, CAS 6439674 through 79559970), the user instructed
that batch 6 (the final 37 rows, CAS 79917901 through 850804443) be split out
as a separate "failed"/unprocessed file rather than completed in this run.
Wrote `scripts/stage2b-batch6-failed.csv` containing those 37 rows with their
`casnumber`/`chemicalname` only, decision columns blank, and a note flagging
them as deferred to a follow-up pass. `scripts/stage2b-full-results-part2.csv`
was then finalised from batches 1–5 only (**250 rows**, not 287), and
combined with Part 1 into `scripts/stage2b-full-results-combined.csv`
(**550 rows**, not the full 587). Validated: no duplicate `casnumber` across
either file, row order/`chemicalname` match the filtered input exactly, no
empty required fields in the processed rows.

**Part 2 category breakdown (250 rows):**
| Category | Count |
|---|---|
| Already the parent form (direct — no simpler parent) | 100 |
| Salt / oxide / ester / derivative → resolved to a simpler parent | 137 |
| Mixture or pseudo-CAS — cannot resolve | 10 |
| Uncertain — needs human review | 3 |

**Part 2 confidence breakdown:** high 185, medium 62, low 3.

**Combined Part 1 + Part 2 totals (550 rows):**
| Category | Count |
|---|---|
| Already the parent form (direct — no simpler parent) | 302 |
| Salt / oxide / ester / derivative → resolved to a simpler parent | 233 |
| Mixture or pseudo-CAS — cannot resolve | 11 |
| Uncertain — needs human review | 4 |

**Combined confidence breakdown:** high 451, medium 94, low 5.

**Outstanding work:** 37 rows (CAS 79917901–850804443, in
`scripts/stage2b-batch6-failed.csv`) still need a follow-up pass before the
full 587-row population is complete. A reviewer should also prioritise the
novel major-ion-halide convention (medium confidence throughout this batch),
the Ca/Mg-vs-Barium distinction, and the two `UNCERTAIN` mixed-metal-compound
rows, plus the unverified free-base CAS numbers flagged above.

---
