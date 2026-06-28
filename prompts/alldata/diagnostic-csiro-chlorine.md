## Session: diagnostic-csiro-chlorine-exclusion
Date: 2026-06-28
Model: Claude Sonnet 4.6

### Prompts and Responses

**User:** Read-only diagnostic — how is CSIRO chlorine excluded from `allchronic_data`?

Requested investigation of the 30 CSIRO chlorine/marine rows excluded from `allchronic_data`. The suspected sole exclusion mechanism was S6-D4 (NA-species drop in `prep_curated_source()`). Task: confirm or refute, trace all gates, check taxonomy cache for the 30 species, identify CSIRO source CSV, assess validation guards, and predict impact if species were populated. Hard constraint: read-only; only permitted write is `data-raw/alldata/diagnostic-csiro-chlorine-exclusion.md`.

**Claude:** Verdict: REFUTED — the exclusion is NOT incidental (NA-species only).

Key findings:

1. **S6-D4 gate** (`DATASET.R:2063–2068`): Predicate is purely `is.na(Species) | trimws(Species) == ""`. No chemical/source/medium/test_class condition. Fires only because csiro_data.rda had NA Species for chlorine rows. With species populated, this gate passes.

2. **B1 ANZG marine exclusion** (`DATASET.R:2168`): `source != "anzg" & casnumber_grouped %in% anzg_marine_cas & medium == "Marine"`. `data/anzg_chlorine_marine.rda` exists → CAS 7782505 (Chlorine) is in `anzg_marine_cas` → all 30 CSIRO chlorine × marine rows are excluded at B1 regardless of species. This is a species-independent exclusion.

3. **Stage 4e filters do NOT apply to curated rows.** Stage 4e operates only on `uncurated_raw_dedup_enriched.csv`. CSIRO bypasses it entirely.

4. **Taxonomy cache:** 2/30 species in `species_resolution_curated.csv` (Acartia tonsa → Copepoda; Dendraster excentricus → Echinoidea). 28 absent. No live WoRMS/GBIF lookup — local cache only. Cache misses keep input name with NA taxonomy. The four non-clean names (Pontogeneia sp., Anonyx sp., Neomysis sp., Hemigrapsus nudus and H. oregonensis) are NOT dropped — `flag_genus_rank()` applies only to uncurated Stage 4e rows.

5. **CSIRO source CSV:** `data-raw/csiro/csiro.csv` — single combined file with chlorine + nickel + cobalt + lead (91 rows total).

6. **Validation guards:** V12 checks NA/empty/placeholder Species; passes with species populated. No validation check catches acute data in curated sources.

7. **Predicted impact:** ZERO change to `allchronic_data`. CSIRO chlorine rows pass S6-D4, eliminated at B1 by ANZG priority. `chlorine_marine` set already exists as ANZG-only; unchanged.

8. **State note:** HEAD commit `fa7913d` already rebuilt `csiro_data.rda` with species for chlorine rows; `allchronic_data.rda` is stale and needs re-run of `data-raw/alldata/DATASET.R`.

9. **Fix implication:** Populating species only removes S6-D4 barrier. To get CSIRO chlorine species into `all_chronic` would require changing the wholesale ANZG priority exclusion (B1) to a per-species reconciliation (like B3 for aims > csiro > uncurated).

Deliverable written: `data-raw/alldata/diagnostic-csiro-chlorine-exclusion.md`.

---
