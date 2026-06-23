# Stage 2c Consistency Check
Date: 2026-06-23

Audit of `scripts/stage2b-full-results-combined.csv` (587 rows, the complete
Stage 2b LLM-assisted CAS parent lookup). Reporting only — the lookup table
itself was not modified. Re-run `scripts/stage2c-consistency-check.R` to
reproduce every figure below.

Categorisation used throughout: each row's `proposed_match_rationale` is
classified into one of four buckets — `direct - no simpler parent` (316
rows), `transform -> simpler parent` (246 rows), `MIXTURE OR PSEUDO-CAS`
(19 rows), `UNCERTAIN - needs human review` (6 rows) — matching the totals
already reported in `prompts/stage2b-full-run.md`.

---

## Check 1: Duplicate CAS with conflicting parents

**Result: none found.** `casnumber` has zero duplicates across all 587 rows
(confirmed both by `duplicated()` and by the validation already logged in
`prompts/stage2b-full-run.md`).

---

## Check 2: Chemical class consistency

### 2a Alkali-metal halides

11 rows matched (sodium/potassium/lithium/cesium/rubidium + chloride/
bromide/fluoride/iodide). **All 11 resolve consistently to the halide ion**,
not the metal:

| casnumber | chemicalname | parent | confidence |
|---|---|---|---|
| 7447407 | Potassium chloride (KCl) | Chloride | medium |
| 7447418 | Lithium chloride | Chloride | medium |
| 7550358 | Lithium bromide | Bromide | medium |
| 7647145 | Sodium chloride (NaCl) | Chloride | medium |
| 7647156 | Sodium bromide (NaBr) | Bromide | medium |
| 7647178 | Cesium chloride | Chloride | medium |
| 7681110 | Potassium iodide | Iodide | medium |
| 7681494 | Sodium fluoride | Fluoride | **high** |
| 7681825 | Sodium iodide | Iodide | medium |
| 7758023 | Potassium bromide | Bromide | medium |
| 7791119 | Rubidium chloride | Chloride | medium |

No inconsistency. This is internally consistent, but it is a **novel
extension** of the project's documented nitrate/vanadate/arsenite precedent
to plain halides — halides are not named as "nutrient ions" in
`speciation_convention.md`, and every row except Sodium fluoride (which has
independent precedent from a standalone Fluoride-ion entry elsewhere in the
batch) is flagged medium confidence for exactly this reason. See
Decision D1 below.

### 2b Alkaline earth metal salts

14 rows matched (calcium/magnesium/barium/strontium + any anion):

| casnumber | chemicalname | parent | confidence |
|---|---|---|---|
| 543806 | Barium acetate | **Barium** | medium |
| 1305620 | Calcium hydroxide | Calcium | high |
| 1305788 | Calcium oxide | Calcium | high |
| 1309428 | Magnesium hydroxide | Magnesium | high |
| 1344816 | Calcium sulfide | Hydrogen sulfide | medium |
| 7487889 | Magnesium sulfate | Sulfate | high |
| 7727437 | Barium sulfate | **Barium** | medium |
| 7778189 | Calcium sulfate | Sulfate | high |
| 7786303 | Magnesium chloride | Chloride | medium |
| 7789415 | Calcium bromide | Bromide | medium |
| 7791186 | Magnesium chloride (hydrate) | Chloride | medium |
| 10043524 | Calcium chloride | Chloride | medium |
| 10361372 | Barium chloride | **Barium** | medium |
| 10476854 | Strontium chloride | Chloride | medium |

The asymmetry flagged in the pilot report **is present, and it is
internally consistent within each metal group**:
- **Barium**: all 3 instances (acetate, sulfate, chloride) → element,
  regardless of anion.
- **Calcium / Magnesium**: resolve to the anion when one exists
  (sulfate/chloride/bromide → Sulfate/Chloride/Bromide); resolve to the
  element only when no anion-parent is available (hydroxide, oxide have no
  independent "anion" form). Calcium sulfide → Hydrogen sulfide follows a
  separate, already-established reference-analyte convention for sulfide
  generally, not a Ca-specific rule.
- **Strontium**: the single instance (chloride) is treated like Ca/Mg
  (→ Chloride), not like Barium.

No row breaks its own group's pattern. The open question is whether Ba
should really be singled out from Ca/Mg/Sr, and which pattern Sr should
follow given there is no precedent either way — both already flagged in
`prompts/stage2b-full-run.md` as judgment calls. See Decisions D2 and D3.

### 2c Arsenic compounds

3 rows matched (`arsen` substring): Trisodium arsenite (13464374), Arsenite
(15502746), Arsenate (15584040). **All 3 resolve to elemental Arsenic, CAS
7440-38-2**, fully consistent with `speciation_convention.md`, all at high
confidence. No inconsistency.

(Other arsenic compounds — Sodium arsenite, Arsenic pentoxide, Arsenic
trioxide — are already resolved in the master `data-raw/cas_parent_lookup_all.csv`
outside the 587-row review population; see Check 6.)

### 2d Nutrient oxyanions

The brief asks to verify that rows where `proposed_parent_name` is Nitrate/
Nitrite/Phosphate/Sulfate are marked `direct`. In practice, most rows whose
final parent is one of these ions are **salts that transform to the ion**
(e.g. "Sodium phosphate" → Phosphate via `transform`, correctly, since the
input itself is a salt, not the bare ion) — only the bare-ion entries
themselves should read literally `direct`. Splitting on that basis:

- **Bare-ion entries** (3 rows: Phosphate CAS 14265442, Nitrite CAS
  14797650, Sulfate CAS 14808798) — **all 3 correctly marked
  `direct - no simpler parent`.**
- **Broader scan** of all 134 rows whose `chemicalname` contains phosphate/
  sulfate/nitrate/nitrite: **zero rows resolve further than the ion** (e.g.
  to elemental Nitrogen/Phosphorus/Sulfur). No violation of the convention.

One related pattern worth flagging for the record, not as an inconsistency:
heavy/trace-metal cations (Fe, Co, Ni, Zr, Be) paired with a nutrient anion
consistently **override** the nutrient-ion convention and resolve to the
metal instead (e.g. Ferric sulfate → Iron, Cobalt nitrate → Cobalt, Nickel
nitrate → Nickel), per the rule documented in `prompts/stage2b-full-run.md`
but not yet written into `speciation_convention.md` itself. See Decision D4.

### 2e Organophosphate insecticides

No rows in this 587-row population match the literal suffixes
"phosphorothioate" / "phosphorodithioate" / "phosphonothioate" (these
compounds were already resolved before Stage 2b — see Check 6 note). A
broader scan of all rows containing "phosphate" found the organophosphate
active ingredients present in this batch (Dichlorvos, Naled, Chlorfenvinphos,
Monocrotophos, Phosphamidon, Propaphos, Dicrotophos, Tetrachlorovinphos /
Z-Tetrachlorvinphos, plus the oxon metabolites Paraoxon, Methylparaoxon,
Diazoxon, Chlorpyrifos oxon, Fospirate, Fenitrooxone) **all correctly marked
`direct - no simpler parent`** — none were incorrectly collapsed to
Phosphate/Phosphorus. No inconsistency.

### 2f HCl/HBr salts of organic bases

51 rows matched ("hydrochloride" or "hydrobromide" in `chemicalname`).
**49 of 51 resolve to the free base**, consistent with convention. The
remaining **2 are marked `direct`**:

| casnumber | chemicalname | rationale |
|---|---|---|
| 67038 | Thiamine chloride hydrochloride (Vitamin B1) | quaternary thiazolium core cannot be neutralised to a free base; registered as this salt form |
| 137882 | Amprolium hydrochloride | quaternary pyridinium core is intrinsic to the registered veterinary drug; Amprolium HCl is itself the standard reference form |

Both are **justified, not inconsistent**: the cationic core in each molecule
is a permanently-charged heteroaromatic ring (thiazolium / pyridinium), not
a simple protonated amine — the same reasoning the lookup already applies to
quaternary ammonium halide salts elsewhere. There is no neutral free-base
form to resolve to. No action needed.

(The known low-confidence CAS 964523 "Moxisylyte-type HCl salt — tentative
structural ID" also falls in this group, already flagged in
`prompts/stage2b-full-run.md`.)

### 2g Esters

11 rows matched ester-suffix patterns. Split by whether the chemical name
names one of the documented registered-pesticide acids (2,4-D, 2,4,5-T,
MCPA, Fenac, NAA):

- **5 pesticide-acid esters** (2,4-D isopropyl/1-butyl/ethyl/3-butoxypropyl
  ester, 2,4,5-T 3-(2-butoxyethoxy)propyl ester) — **all 5 resolve to the
  parent acid** (2,4-D ×4, 2,4,5-T ×1).
- **6 industrial esters** (phosphate/sulfate esters: two
  "Phosphoric acid...ester" diethyl/dimethyl phosphates, a sulfate
  monoester, a sulfate "mixt. with" combination, and the
  O,O-dimethyl-O-(...)phosphate ester) — **all 6 stay direct**, including
  the one row whose chemical name happens to contain the substring "2,4-D"
  as part of the IUPAC fragment "2,4-Dichlorophenoxy" rather than as a use
  of the herbicide code (CAS 57571058 — correctly classified as a `mixt.
  with` combination, unresolvable).

A wider scan adding sodium/lithium/potassium/dimethylamine **salts** (not
just esters) of 2,4-D/2,4,5-T/MCPA found a further 16 rows, all of which
also resolve correctly to the parent acid. No inconsistency found anywhere
in this group.

---

## Check 3: Confidence distribution by category

| Category | high | low | medium |
|---|---|---|---|
| direct - no simpler parent | 292 | 0 | 24 |
| MIXTURE OR PSEUDO-CAS - cannot resolve | 19 | 0 | 0 |
| transform -> simpler parent | 175 | 1 | 70 |
| UNCERTAIN - needs human review | 0 | 6 | 0 |

No unexpected combinations: there are zero `direct + low` rows and zero
`transform + high confidence + missing parent CAS` rows (the one
`transform + low` row — Trimethyllead acetate → Lead, CAS 5711193 — is
itself already flagged in `prompts/stage2b-full-run.md` for the
organolead-vs-elemental-Pb toxicology gap, so the low confidence is
deliberate, not anomalous). `UNCERTAIN` rows are uniformly low confidence
and `MIXTURE` rows are uniformly high confidence, both as expected.

---

## Check 4: Missing parent CAS for resolved rows

**12 `transform` rows have an identified parent name but a blank
`proposed_parent_casnumber`/`proposed_parent_cas_dashed`** — resolutions
without a verifiable CAS anchor. All 12 are medium confidence:

| casnumber | chemicalname (truncated) | proposed parent |
|---|---|---|
| 2026246 | Octahydro-...-phenanthrenemethanamine, Acetate | Dehydroabietylamine (free base) |
| 2051798 | N4,N4-Diethyl-2-methylbenzene-1,4-diamine hydrochloride | N4,N4-Diethyl-2-methylbenzene-1,4-diamine (free base) |
| 5407045 | Dimethylaminopropyl chloride hydrochloride | 3-Chloro-N,N-dimethylpropan-1-amine (free base) |
| 7250671 | 1-(2-Chloroethyl)pyrrolidine hydrochloride | 1-(2-Chloroethyl)pyrrolidine (free base) |
| 7745893 | 3-Chloro-4-methylbenzenamine hydrochloride | 3-Chloro-4-methylaniline (free base) |
| 10114586 | C.I. Basic Brown 1, dihydrochloride | C.I. Basic Brown 1 (free base diazoamino dye) |
| 13071119 | Dexpropranolol hydrochloride | Dexpropranolol (free base) |
| 16058267 | 1-Methyltetradecylamine, Acetate | 1-Methyltetradecylamine (free base) |
| 25646713 | Methanesulfonamide...sulfate (2:3) | N-{2-[(4-amino-3-methylphenyl)(ethyl)amino]ethyl}methanesulfonamide (free base) |
| 25646779 | Ethanol, 2-((4-amino-3-methylphenyl)ethylamino)-, sulfate | 2-[(4-Amino-3-methylphenyl)(ethyl)amino]ethanol (free base) |
| 29235710 | 4-Morpholinepropanamide...monohydrochloride | N-(4-Hydroxyphenyl)-3-(morpholin-4-yl)propanamide (free base) |
| 36362091 | 2-(Decylthio)ethanamine hydrochloride | 2-(Decylthio)ethanamine (free base) |

These are exactly the rows flagged in `prompts/stage2b-full-run.md` as
"several free-base CAS numbers...provided at medium confidence from memory
with an explicit note to verify" — except here the data shows no CAS number
was actually recorded at all (not merely an unverified one). See Decision
D5.

---

## Check 5: Parent CAS format validation

### 5a Dashed-format validation

**1 row fails the standard `digits-digits-digit` dashed CAS pattern:**

| casnumber | chemicalname | proposed_parent_cas_dashed | proposed_parent_casnumber | proposed_parent_name |
|---|---|---|---|---|
| 5471089 | Benzeneethanamine, sulfate (2:1) | `6-40-4` | `6404` | Phenethylamine |

The real-world CAS registry number for phenethylamine (2-phenylethan-1-amine,
the free base of this sulfate salt) is **64-04-4** (nodash `64044`). Both the
dashed and nodash fields in this row appear to have dropped the digit "4"
and the dash is consequently misplaced — this is a data-entry error in the
source value, not just an internal-consistency mismatch (stripping the
dashes from `6-40-4` does yield `6404`, so this row passes Check 5b's
internal-agreement test while still being substantively wrong). See
Decision D6.

### 5b Dashed vs. nodash mismatch

**2 rows where `proposed_parent_casnumber` does not equal
`proposed_parent_cas_dashed` with dashes stripped:**

| casnumber | chemicalname | proposed_parent_cas_dashed | proposed_parent_casnumber | stripped dashed |
|---|---|---|---|---|
| 21351393 | Urea, sulfate (1:1) | `57-13-6` | `5713` | `57136` |
| 56896685 | 1,2-Propanediamine, acetate (1:?) | `78-90-0` | `7890` | `78900` |

In both cases the dashed value matches the well-known real-world CAS
(Urea = 57-13-6; 1,2-Propanediamine = 78-90-0) and the nodash field has
simply dropped the trailing digit. Unlike the Phenethylamine row above,
these two are mechanically fixable — see the programmatic-fix list below.

---

## Check 6: Cross-reference against the original 41-row lookup

`data-raw/anztox/cas_parent_lookup.csv` has **40 data rows** (41 lines
including the header). **Zero of the 40 original CAS numbers appear in the
587-row Stage 2b file.** This is expected, not a gap: the 587-row population
is specifically the subset that was `match_rationale == "NEEDS HUMAN REVIEW"`
in the master `data-raw/cas_parent_lookup_all.csv`, and the original 40
human-curated rows were already resolved before Stage 2 started, so they
were never eligible for Stage 2b review.

Cross-checked directly against the master file: **all 40 original rows are
present in `data-raw/cas_parent_lookup_all.csv` with their `parent_casnumber`
unchanged** (spot-checked exhaustively by exact match, not sampled) —
confirming Stage 2's heuristic pass did not silently overwrite any
human-curated assignment. No divergence to report.

---

## Decisions required before Stage 3

A yes/no or choose-one question for each item requiring human sign-off,
grouped by check:

- **D1 (Check 2a).** Should major-ion alkali-metal cations (Na/K/Li/Cs/Rb)
  paired with a plain halide (Cl/Br/F/I) resolve to the halide ion, the same
  way they already do for nitrate/vanadate/arsenite? *(Currently applied
  this way at medium confidence across all 11 rows; needs explicit
  confirmation since halides are not named in `speciation_convention.md`.)*
- **D2 (Check 2b).** Should Barium continue to be treated as a standalone
  trace metal (→ element, regardless of anion) while Calcium and Magnesium
  are treated as major ions (→ anion, when one exists)? *(Currently applied
  this way consistently; needs confirmation that the Ba vs. Ca/Mg split is
  intentional project policy rather than an artifact of which examples the
  model happened to see first.)*
- **D3 (Check 2b).** Should Strontium follow the Calcium/Magnesium pattern
  (→ anion) or the Barium pattern (→ element)? *(Currently resolved as
  Ca/Mg-like at medium confidence; explicitly flagged with "no precedent
  either way" in `prompts/stage2b-full-run.md` — only one Sr row exists in
  this batch, so the choice has low blast radius now but should be settled
  before more Sr rows are encountered.)*
- **D4 (Check 2d).** Should the documented rule "heavy/trace metal cation +
  nutrient anion → resolves to the metal, overriding the nutrient-ion
  convention" (applied to Fe/Co/Ni/Zr/Be in this batch) be added explicitly
  to `data-raw/anztox/speciation_convention.md`, since it is currently only
  recorded in a prompt log rather than the project's canonical convention
  document?
- **D5 (Check 4).** For the 12 rows with an identified free-base/parent name
  but no CAS anchor (listed above), should a domain expert verify and
  supply the correct parent CAS numbers, or should these 12 rows be
  re-flagged `UNCERTAIN - needs human review` instead of carrying a
  resolved-but-unanchored `transform` classification?
- **D6 (Check 5a).** What is the correct parent CAS for CAS 5471089
  (Benzeneethanamine, sulfate / Phenethylamine)? The value on file
  (`6-40-4` / `6404`) does not match the standard registry number for
  phenethylamine (`64-04-4` / `64044`) — needs a human/domain check before
  correcting, since the discrepancy could in principle reflect an unusual
  named isomer rather than a simple typo (though a typo is far more likely
  given the malformed dash format).

---

## Issues that can be resolved programmatically

No human judgment required — these are simple field-level corrections, not
applied in this stage:

- **CAS 21351393** (Urea, sulfate (1:1)): recompute
  `proposed_parent_casnumber` by stripping dashes from
  `proposed_parent_cas_dashed` (`57-13-6` → `57136`, replacing the
  truncated `5713`).
- **CAS 56896685** (1,2-Propanediamine, acetate (1:?)): recompute
  `proposed_parent_casnumber` by stripping dashes from
  `proposed_parent_cas_dashed` (`78-90-0` → `78900`, replacing the
  truncated `7890`).
- General rule worth applying as a validation step in any future batch:
  for every row where both `proposed_parent_cas_dashed` and
  `proposed_parent_casnumber` are present, assert
  `proposed_parent_casnumber == gsub("-", "", proposed_parent_cas_dashed)`
  at write time, so a dropped trailing digit is caught immediately rather
  than surfacing only in a later audit.

---

## Prompt log

See `prompts/stage2c-consistency-check.md`.
