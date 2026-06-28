<!--
DRAFT vignette addition — Stage 6 short-term-guideline exclusion (Step B0).
Insert within the Stage 6 (curated integration) narrative, ahead of the
source-priority / medium-viability discussion. External-reader prose; edit to taste.

Citation keys used: @Warne2025ANZG (existing). @BatleySimpson2020 and
@ANZG2026Chlorine are placeholders — match these to your .bib or replace with
in-text references.
-->

### Short-term guidelines are out of scope

The curated sources are trusted as-is, but trust in a value does not make it
*comparable*. A small number of curated guidelines are derived under a short-term
(acute) protocol rather than the chronic, negligible-effect basis that defines this
dataset, and those values cannot sit alongside the rest without a unit-of-meaning
mismatch. The benchmark concentrations throughout `allchronic_data` represent
negligible effects — no-effect and low-effect estimates, or median-effect values
converted to that basis [@Warne2025ANZG, Section 3.4.2]. A short-term guideline,
by contrast, is built directly from median-effect data (LC50/EC50) describing 50%
mortality or effect. The two are different quantities, and pooling them would
silently mix protective thresholds with lethal-median concentrations.

Chlorine in marine water is the one case in the current curated set. Because
chlorine-produced oxidants decay within days, a chronic exposure assessment is
inapplicable, so the marine chlorine guideline is derived from short-term tests and
its species sensitivity distribution is fitted to raw acute EC50/LC50 values, with
the conversion to a protective concentration applied only after the distribution is
fitted [@BatleySimpson2020; @ANZG2026Chlorine]. The 29 ANZG marine chlorine records
are therefore median-effect values, and admitting them to a negligible-effect
dataset would be a categorical error rather than merely a conservative one.

To handle this consistently, a short-term scope registry
(`short_term_curated_sets.csv`) lists the chemical × medium combinations that are
out of scope for the chronic dataset, and a dedicated step (B0) removes every
matching record — from *all* sources — before the source-priority gates are applied.
The exclusion is keyed on the chemical (CAS) and medium, deliberately **not** on the
acute/chronic label attached to individual toxicity records. That label is
unreliable provenance: ANZG's fipronil freshwater guideline, for example, is a
chronic default guideline whose underlying acute values have already been converted
to a chronic basis with an acute-to-chronic ratio, yet each record remains labelled
"Acute LC50". Routing on the label would wrongly remove genuine chronic guidelines;
routing on an explicit, brief-level registry does not.

The scope is defined per medium, not per chemical. Only chlorine × Marine is
excluded; uncurated chlorine data for freshwater and unknown media are retained and
treated like any other uncurated chemical, and in practice form a `chlorine_mixed`
set. Step B0 removes 127 records in total (29 from ANZG, 30 from CSIRO, 68
uncurated), all chlorine × Marine, written to `stage6-shortterm-excluded.csv` for
audit. With CSIRO's chlorine records now carrying reconstructed species names, the
earlier no-species safeguard (Section [S6-D4 cross-ref]) no longer applies to them;
Step B0 is the single rule that keeps curated and uncurated short-term chlorine out
of the chronic dataset. The net effect on the output is small — the standalone
`chlorine_marine` set is removed and a `chlorine_mixed` set (uncurated freshwater
and unknown-medium data) appears in its place — leaving `allchronic_data` at 26,536
records across 1,525 sets. The decision is recorded as deviation S6-D5
(Appendix B), and the full before-and-after verification is in
`stage6-shortterm-exclusion-report.md`.
