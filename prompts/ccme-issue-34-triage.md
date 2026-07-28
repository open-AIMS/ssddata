## Session: ccme issue #34 triage — close medium question, split out CCME GVs
Date: 2026-07-27
Model: Claude Opus 5 (claude-opus-5)

### Prompts and Responses

**User:** Can this issue be closed? https://github.com/open-AIMS/ssddata/issues/34

**Claude:** Assessed the issue as bundling two tasks, only one of which is done.

*Part 1 — check ccme medium: resolved.* Angeline (CCME) confirmed in the issue
thread that "all the data are for chronic exposures in freshwater media". This is
implemented: `data-raw/ccme/DATASET.R:165` sets `Medium = "Freshwater"` for all
ccme datasets and every record carries `Timeframe = "chronic"` (verified against
built `ccme_endosulfan.rda`: 12 rows, all Freshwater/chronic).

*Part 2 — add official CCME GVs + method types to `ssd_fits`: not done.*
`data-raw/ssd-fits/ssd-fits.csv` has 29 `ccme_*` rows, all Burrlioz v2.0 re-fits
attributed to `Fox2021b` (plus one `Thorley (pers comm)` boron row) — no official
guideline values. Contrast the ANZG side, where 132 `anzg_*` rows were appended by
`data-raw/anzg/04_append_dgvs_to_ssd_fits.R` citing official factsheets.

Recommended closing #34 on the medium question and opening a focused follow-up for
the GV work, since no other open issue covers it (#25 is ANZG-scoped).

---

**User:** Yes, draft the closing comment and follow-up issue, as a new focused issue.

**Claude:** Drafted both. In the first draft I incorrectly claimed a units problem —
that `ssd_fits` documents Estimate as ug/L while ccme rows are in native units, and
that a units convention needed settling alongside #47. Also raised a schema question
about whether "method types" needed a new `Method` column.

---

**User:** I am a bit confused about some of your assessment above. The official units
are in the data-raw/ccme/DATASET.R. Can we add a units column to ssd_fits so this is
completely clear going forward. Also for "method types" — we have Software / Version /
Distribution in ssd_fits already. This is probably sufficient? There are also notes as
well, which can be used to make notes for methods that don't easily fit.

**Claude:** User correct on both; corrected the assessment.

*Units.* `ssd_fits` already has a `Units` column, built at
`data-raw/ssd-fits/DATASET.R:111-130`, which derives units per-dataset by reading the
`Units` column off the raw data object each fit was computed on — so it stays correct
if a source's units change. Built object: 288 ug/L, 21 mg/L, 10 ng/L, 58 NA (the NAs
are only the five `anon_*` datasets, deliberately unitless). ccme rows are correct:
boron/chloride mg/L, endosulfan ng/L, rest ug/L — flowing from
`data-raw/ccme/DATASET.R:152`. This landed with the #47 work already on this branch.
What I mistook for a data bug is only stale roxygen in `R/ssd-fits.R` ("in ug/L"),
already filed as item 1 of #53.

*Method types.* Agreed — `Software`/`Version`/`Distribution` + `Notes` suffice, no
schema change. For CCME: SSD-derived GVs get the factsheet distribution with `PC = 95`
(CCME's long-term guideline is the SSD 5th percentile); non-SSD derivations
(assessment-factor / lowest-endpoint) leave `Distribution` and `PC` empty with the
method in `Notes`.

Revised the draft: dropped the units section and the schema question, dropped "and
method types" from the title, kept only the practical point that appended GVs must be
quoted on the dataset's own scale.

---

**User:** If you can find the urls that would be good.

**Claude:** Located all seven CCME factsheet pages. IDs are not strictly alphabetical
(105-110 are trihalomethanes, 112 heptachlor, 124 lead, 162 pH), so glyphosate took
probing to find at 102.

| Dataset | Factsheet | Long-term CWQG | In dataset units | Year |
|---|---|---|---|---|
| `ccme_boron` | /en/chemical/16 | 1,500 ug/L | 1.5 mg/L | 2009 |
| `ccme_cadmium` | /en/chemical/20 | 0.09 ug/L @ 50 mg CaCO3/L | 0.09 ug/L | 2014 |
| `ccme_chloride` | /en/chemical/28 | 120,000 ug/L | 120 mg/L | 2011 |
| `ccme_endosulfan` | /en/chemical/93 | 0.003 ug/L | 3 ng/L | 2010 |
| `ccme_glyphosate` | /en/chemical/102 | 800 ug/L a.i. | 800 ug/L | 2012 |
| `ccme_silver` | /en/chemical/198 | 0.25 ug/L | 0.25 ug/L | 2015 |
| `ccme_uranium` | /en/chemical/225 | 15 ug/L | 15 ug/L | 2011 |

Points surfaced from the factsheets and written into the issue:
- CCME publishes all seven in ug/L; boron, chloride and endosulfan need conversion to
  their dataset's scale (mg/L, mg/L, ng/L).
- Cadmium's CWQG is hardness-dependent — `10^(0.83*log10(hardness) - 2.46)` over
  17-280 mg CaCO3/L; 0.09 ug/L is only the value at 50. Needs a `Notes` entry.
- Silver has no short-term guideline ("NRG") — short- and long-term SSD 5th
  percentiles are essentially equal.
- Chloride, glyphosate and silver are explicitly SSD-derived; the other four need
  checking.
- Incidental corroboration: the chloride factsheet states its SSD was fitted to 28
  species, matching `ccme_chloride`'s 28 rows.

Values were transcribed from the factsheet landing pages via web fetch — the issue
states they must be verified against the factsheet PDFs before being appended to
shipped data.

---

**User:** Yes, post them.

**Claude:** Posted:
- Created issue #56 "Add official CCME guideline values to `ssd_fits`"
  (https://github.com/open-AIMS/ssddata/issues/56)
- Commented on and closed #34, cross-referencing #56.

No repository files were modified in this session; no commit needed beyond this log.

---
