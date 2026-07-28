# Session: issue dependency review and sequencing

Date: 2026-07-27
Model: Claude Opus 5 (claude-opus-5)

### Prompts and Responses

**User:** can you review the current set of issues and identify inter-dependencies
and what order they should be tackled in

**Claude:** Read all 17 open issues (#25, #29, #30, #31, #33, #35, #37, #44, #47,
#49–#56) plus repo state (branch `create_alldata`, 20+ commits ahead of `main`,
uncommitted test-suite expansion). No code changed — analysis only.

Findings summarised:

- **Gate 0**: the uncommitted test suite pins the defects in #49–#55 and must be
  committed as the baseline; `create_alldata` must be merged to `main` before new
  work streams fork, else every fix rebases against a stale main.
- **Closable now**: #29 (wqbench Medium delivered by merged PR #43); #47 (both unit
  mismatches fixed on branch, close on merge).
- **Shared root cause**: #50, #51, #55 are all "name-derived keys where CAS is the
  real identity" — one naming-policy decision serves all three, and #51's CAS-lookup
  question (105827789 vs 138261413; 16065831 vs 7440473) must be answered first
  because a lookup merge could dissolve the other two.
- **Rebuild batching**: #51, #52, #53 item 2, #55 and the `chronic_data` rename all
  require an `allchronic_data` rebuild + re-pinning the same ~6 test blocks. Batch
  into one rebuild event; rename first (mechanical) so logic fixes land on final names.
- **anzg.csv serialisation**: #52 (medium vocabulary) and #25 (expand 28 → 2000+
  DGVs) both rewrite `data-raw/anzg/anzg.csv`; #25 and #56 both append to
  `ssd-fits.csv`. Serialise. #25 is a second unavoidable rebuild event since anzg is
  the top-priority curated source.
- **Independent / cheap**: #54 (arg validation, R/ only), #53 items 1 and 3
  (doc-only), #49 (wqbench-only rebuild, no allchronic impact).
- **Long lead time, start in parallel**: #30's non-code items (copyright review,
  collaborator invites, CONTRIBUTING, AI-usage disclosure).

Recommended order delivered as six waves: (0) merge/close housekeeping → (1) cheap
independents → (2) identity/naming policy decision → (3) single batched rebuild →
(4) ssd_fits content (#56 then #25) → (5) new sources/features (#44, #35, #37, #33
roadmap) → (6) terminal (#31, #30).

---
