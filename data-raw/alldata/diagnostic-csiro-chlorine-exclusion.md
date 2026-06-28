# Diagnostic: CSIRO Chlorine/Marine Exclusion from `allchronic_data`

Generated: 2026-06-28  
Model: Claude Sonnet 4.6  
Branch: create_alldata (HEAD: fa7913d "Added species data to csiro_chlorine_marine")

---

## Verdict

**Exclusion is incidental (NA-species only): REFUTED**

The *currently active* gate is S6-D4 (NA-species drop), but a second **species-independent** gate—B1 ANZG marine priority—would exclude the same rows even with species populated. Populating species does **not** cause CSIRO chlorine rows to appear in `allchronic_data`. The `chlorine_marine` set already exists in `allchronic_data` and is served entirely by ANZG.

Controlling code references:
- S6-D4 gate: `DATASET.R:2063–2068` (`prep_curated_source()`)
- B1 ANZG marine gate: `DATASET.R:2162–2170` (Step B)

---

## 1. S6-D4 — Locate the NA-species drop

**Location:** `prep_curated_source()`, `data-raw/alldata/DATASET.R` lines 2063–2068.

```r
n_no_species <- sum(is.na(df_cas$Species) | trimws(as.character(df_cas$Species)) == "")
if (n_no_species > 0) {
  message(sprintf("  %s: dropping %d NA/empty-Species rows (S6-D4)", source_label, n_no_species))
  df_cas <- df_cas |> filter(!is.na(Species), trimws(as.character(Species)) != "")
}
```

**Predicate:** `is.na(Species) | trimws(as.character(Species)) == ""`

This is **purely an NA/empty-Species check**. There is no condition on source, chemical, medium, test_class, or endpoint. Once Species is populated the predicate is FALSE for all rows and **n\_no\_species = 0**: S6-D4 does not fire.

---

## 2. Species-independent exclusions

### Stage 4e filters — do they apply to curated rows?

**No.** Stage 4e (DATASET.R lines 138–1229) operates exclusively on `uncurated_raw_dedup_enriched.csv`, loaded at line 139. The `clean` data frame contains only uncurated data (anztox, wqbench, envirotox). CSIRO data enters via `load("data/csiro_data.rda")` at line 32 and is handled solely by `prep_curated_source()` in Stage 6/7. The Step 2b acute-non-eligible filter (lines 196–208: `test_class == "acute" & !acr_eligible`) **does not touch curated rows**.

### B1 ANZG marine priority — species-independent

**Yes — this fires.** In Step B, lines 2162–2170 of DATASET.R:

```r
anzg_positions <- all_rows |>
  filter(source == "anzg") |>
  select(casnumber_grouped, medium) |>
  distinct()

anzg_marine_cas <- anzg_positions |>
  filter(medium == "Marine") |>
  pull(casnumber_grouped) |>
  unique()

all_rows <- all_rows |>
  mutate(excl = case_when(
    ...
    source != "anzg" & casnumber_grouped %in% anzg_marine_cas & medium == "Marine"
      ~ "anzg_marine",
    ...
  ))
```

`data/anzg_chlorine_marine.rda` **exists** in the package data directory, confirming ANZG has chlorine × Marine data. Therefore CAS 7782505 (Chlorine) appears in `anzg_marine_cas`. Every CSIRO row with `casnumber_grouped == 7782505` and `medium == "Marine"` is flagged `excl = "anzg_marine"` **regardless of whether Species is present**.

---

## 3. Gate-by-gate trace (species populated in csiro_data.rda)

| Gate | Code location | Predicate / logic | Status |
|------|---------------|-------------------|--------|
| CAS lookup | `DATASET.R:2053–2057` | `Chemical = "chlorine"` → CAS 7782505 via `curated_cas_lookup.csv` row 40 | **PASS** — all 30 rows join |
| S6-D4 species drop | `DATASET.R:2065–2068` | `is.na(Species) \| trimws(Species) == ""` | **PASS** — 0 rows dropped (species populated) |
| Taxonomy join | `DATASET.R:2071–2082` | `left_join(taxonomy_lookup, by = c("Species" = "query_name"))` — cache miss → input name kept | **PASS (partial)** — 2 cached, 28 fallback; see §4 |
| Conc filter | `DATASET.R:2086` | `filter(!is.na(Conc))` | **PASS** — all 30 rows have Conc |
| Within-source geomean | `DATASET.R:2086–2113` | `group_by(cas × accepted_name × medium × taxonomy)` | **PASS** — 30 → 30 rows (all accepted_names unique within chlorine × marine) |
| **B1: ANZG marine exclusion** | `DATASET.R:2168` | `source != "anzg" & casnumber_grouped %in% anzg_marine_cas & medium == "Marine"` | **DROP — all 30 rows** (CAS 7782505 in `anzg_marine_cas` because `anzg_chlorine_marine.rda` exists) |
| B2: CCME exclusion | `DATASET.R:2184–2195` | Fires only if `source %in% c("aims","csiro","uncurated")` and CCME covers cas × medium | N/A — rows eliminated at B1 |
| B3: Preference hierarchy | `DATASET.R:2199–2225` | aims > csiro > uncurated at cas × medium × accepted_name | N/A — rows eliminated at B1 |
| Step C: medium viability | `DATASET.R:2247–2344` | N/A | N/A — rows eliminated at B1 |

**ANZG chlorine × marine data confirmed by:** `ls data/ | grep chlorine` → `anzg_chlorine_marine.rda`; `curated_cas_lookup.csv` line 11 (`anzg,chlorine,7782505,Chlorine`); Stage 6 report (`anzg | Marine | 207` retained rows, ANZG marine exclusion 889 rows).

**CCME chlorine check:** `curated_cas_lookup.csv` lists CCME as covering Chloride (CAS 16887006, row 35), not Chlorine (CAS 7782505). B2 does not fire.

---

## 4. Taxonomy resolution sub-findings

**Cache file:** `data-raw/alldata/species_resolution_curated.csv` (77 rows, loaded at `DATASET.R:1926`).

**In cache (2 of 30):**

| Input name (csiro.csv Species) | Accepted name | Class | Cache row |
|--------------------------------|---------------|-------|-----------|
| `Acartia tonsa` | `Acartia (Acanthacartia) tonsa` | Copepoda | species_resolution_curated.csv:15 |
| `Dendraster excentricus` | `Dendraster excentricus` | Echinoidea | species_resolution_curated.csv:17 |

**Absent from cache (28 of 30):** All other chlorine species, including all four non-clean names.

**Behaviour for cache misses** (`DATASET.R:2074–2082`):
```r
accepted_name = case_when(
  !is.na(accepted_name) ~ accepted_name,
  TRUE ~ Species  # cache miss: keep input name
),
taxonomy_provenance = case_when(
  !is.na(taxonomy_provenance) ~ taxonomy_provenance,
  TRUE ~ "source_native_fallback"
)
```
Cache misses keep the input name as `accepted_name`; `class` and all other taxonomy columns are NA. **There is no live WoRMS/GBIF lookup** — `prep_curated_source()` performs only a local `left_join()` with no network call. Unresolved species are **not dropped**.

**Four non-clean names — specific assessment:**

| Name | Issue | Curated handling | flag_genus_rank() applies? |
|------|-------|-----------------|---------------------------|
| `Pontogeneia sp.` | Genus-rank ("sp." qualifier) | Cache miss; accepted_name = "Pontogeneia sp.", NA taxonomy | **No** — `flag_genus_rank()` called only in Step 2c (`DATASET.R:212–218`), which is Stage 4e uncurated-only |
| `Anonyx sp.` | Genus-rank ("sp." qualifier) | Same as above | No |
| `Neomysis sp.` | Genus-rank ("sp." qualifier) | Same as above | No |
| `Hemigrapsus nudus and H. oregonensis` | Two-congener pooled name | Cache miss; accepted_name = full string, NA taxonomy | No |

All four names survive as cache misses and are not dropped by any curated-source gate. If B1 did not exclude them, they would enter the viability check with `class = NA` (contributing 0 to the `n_distinct(class)` count).

---

## 5. CSIRO source CSV identification

**Path:** `data-raw/csiro/csiro.csv`

**Structure:** A **single combined multi-chemical file** (93 data rows + 1 header). Chemicals:
- chlorine × marine: rows 2–31 (30 rows, Reference = "Batley2020")
- nickel × freshwater: rows 32–63 (30 rows, tropical and temperate domains, Reference = "Stauber2021")
- cobalt × marine: rows 64–76 (15 rows, Reference = "Batley")
- lead × marine: rows 77–92 (16 rows, Reference = "Batley")

Total: 91 rows after `filter(!is.na(Conc))` at `data-raw/csiro/DATASET.R:42`. This matches the Stage 6 report input count (91 CSIRO input rows).

**Integration point:** `load("data/csiro_data.rda")` at `data-raw/alldata/DATASET.R:32`. The `csiro_data` object is the combined multi-chemical dataset built from `data-raw/csiro/csiro.csv` by `data-raw/csiro/DATASET.R`.

---

## 6. Validation guards

**V12 — NA/empty/placeholder Species check** (`DATASET.R:2576–2586`):
```r
bad_species <- allchronic_data |>
  filter(
    is.na(Species) | trimws(Species) == "" |
    grepl("^Unknown", Species) |
    grepl("no name in source", Species, ignore.case = TRUE)
  )
chk(nrow(bad_species) == 0, "Species: no NA, empty, or placeholder values", ...)
```
This check would **pass** with species populated (none of the 30 chlorine names are NA, empty, "Unknown...", or "no name in source"). It does not check for acute data, test_class, or endpoint type.

**No validation check catches acute data in allchronic_data.** V1 (`DATASET.R:2455–2463`) verifies curated rows have `ValueTier == "curated"`, `AnyChronicConvApplied == FALSE`, and `EffectCategory == NA` — consistent with any curated row regardless of the original test type. No check guards against test_class == "acute" in curated sources.

---

## 7. Predicted impact on `allchronic_data`

**Context:** HEAD commit `fa7913d` rebuilt `data/csiro_data.rda` to include Species for chlorine rows (file grew from 2402 → 2963 bytes). The `data-raw/alldata/DATASET.R` has not been re-run after this commit. Current `data/allchronic_data.rda` is stale relative to `csiro_data.rda`.

**If `data-raw/alldata/DATASET.R` is re-run with current `csiro_data.rda`:**

- CSIRO chlorine rows (30): pass S6-D4; eliminated at B1 (ANZG marine, `excl = "anzg_marine"`)
- CSIRO cobalt, lead, nickel rows: unchanged (same exclusion pattern as current run)
- `chlorine_marine` set: unchanged — ANZG-served, already present in `allchronic_data`

**Predicted row-count change: zero.**

| Metric | Current (stale allchronic_data) | Predicted (after re-run) |
|--------|--------------------------------|--------------------------|
| Total rows | 26,533 | 26,533 |
| Distinct Sets | 1,525 | 1,525 |
| Distinct chemicals | 1,180 | 1,180 |
| Distinct species | 2,801 | 2,801 |
| Source = csiro | 60 | 60 |
| chlorine_marine set | present (ANZG) | present (ANZG) — unchanged |

The internal pipeline path for CSIRO chlorine rows changes (S6-D4 no longer fires; B1 fires instead), but the output is identical.

**The 30 chlorine rows that currently survive S6-D4 and reach allchronic_data (cobalt + lead rows from csiro):** unaffected — their exclusion/retention logic is independent of chlorine.

---

## 8. Implications for the fix

The CSIRO chlorine rows are double-excluded: first by S6-D4 (NA species, now fixed in HEAD), second by B1 (ANZG marine priority, a structural design choice). Populating species removes only the first barrier.

A **species-independent fix** would need to address the B1 gate. Options that would need to be described and designed (not implemented here):

1. **Change ANZG priority from wholesale to per-species** — modify Step B so that anzg > csiro applies per `casnumber_grouped × medium × accepted_name` (like the B3 aims > csiro > uncurated logic at `DATASET.R:2199–2225`), allowing CSIRO to contribute species not present in the ANZG chlorine marine set.

2. **Accept CSIRO chlorine as supplementary to ANZG** — restructure the exclusion so that within-source reconciliation (B3) handles anzg vs. csiro at species level rather than B1 wholesale exclusion. This would require ANZG to be treated as just the highest-priority curated source rather than an unconditional whole-chemical replacement.

3. **No change / accept current behaviour** — the `chlorine_marine` set is curated by ANZG and serves its designed purpose. CSIRO's acute LC50 chlorine data is ancillary; adding the species populates `csiro_chlorine_marine.rda` for use in `ssd_data_sets(set="v2")` (as a standalone curated dataset), while `all_chronic` correctly defers to ANZG.

The current design is documented in CLAUDE.md §7: "anzg > ccme > aims > csiro > uncurated, exclusion at `casnumber_grouped × medium` (any higher-priority data for a chemical × medium excludes ALL lower-priority rows there)." Any change to option 1 or 2 would be a deliberate policy deviation from this documented rule.

---

*End of diagnostic report.*
