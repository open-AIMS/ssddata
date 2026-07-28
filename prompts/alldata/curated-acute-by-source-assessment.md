## Session: Assess personal task item "treat curated acute by source"
Date: 2026-07-27
Model: Claude Opus 5 (claude-opus-5)

### Prompts and Responses

**User:** Personal task list holds "Update all data workflow to treat curated
acute by source". Unclear whether this maps to a live GitHub issue and whether
it still needs doing. Review issues, recent commits/PRs and repo state.

**Claude:** Assessment only, no code changes. Findings:

- The item maps to the short-term/acute curated scope redesign, not to any
  dedicated GitHub issue. It was done as sub-work under issue #33.
- History: eb4d315 (2026-06-28) added Step B0 driven by a central registry
  `data-raw/alldata/short_term_curated_sets.csv`; 01252bc (2026-07-11)
  replaced it with a per-source `Timeframe` column carried on each curated
  source's own `data-raw/{source}/` CSV — i.e. "by source" — applied as
  Step B4 *after* the B1/B2/B3 priority gates.
- Verified current state: registry file deleted; `Timeframe` populated in
  `data-raw/aims/aims.csv` (40 chronic), `data-raw/anzg/anzg.csv` (563
  chronic / 29 short_term), `data-raw/ccme/CCME data.csv` (145 chronic),
  `data-raw/csiro/csiro.csv` (61 chronic / 30 short_term); column present
  and roxygen-documented in the curated `.rda` objects; Step B4 at
  `data-raw/alldata/DATASET.R:3274`; audit `stage6-timeframe-excluded.csv`
  (29 anzg rows); validation V13; `allchronic_data` 26,501 × 24 with no
  `Timeframe` column and no `chlorine_marine` set.
- Note: csiro's 30 short_term rows never reach B4 — B1's ANZG marine
  priority removes them first — so the B4 audit CSV lists anzg only.
  Consistent with the earlier double-gate diagnostic; not a defect.
- Conclusion: task is complete and committed; it can be ticked off. The
  successor work is the CLAUDE.md §8 roadmap (`short_data` seeded from the
  short_term curated records, then `acute_data` and the `all_data` landing
  page), which is not tracked by any GitHub issue either.

**Files changed:** none (this log only).

---
