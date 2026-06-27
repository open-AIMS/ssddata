# Stage 4c Part 2 -- Cross-Source Duplicate Detection and ANZG Priority Selection
Date: 2026-06-24

**Revised (Stage 4c Part 3, session "stage4c-part3-effect-category-harmonisation"):** this run follows `scripts/alldata/stage4c-effect-category-fixup.R`, which harmonised `effect_category` to a single controlled vocabulary across all three sources. `effect_category` is now included in the cross-source key (Phase 2) and produces correct cross-source comparisons in the ANZG priority-selection grouping (Phase 3) -- both previously limited by the vocabulary mismatch documented in the prior run of this report (see Section 3 and Section 6 below for the resolution).

Audit-and-flag stage only -- no rows were hard-dropped from `uncurated_raw_combined.csv`. All 449,888 rows appear in `uncurated_raw_dedup.csv` with four new columns: `within_source_duplicate`, `dedup_retained`, `priority_kept`, `dedup_note`.

---

## 1. Input summary

- Input: `data-raw/alldata/uncurated_raw_combined.csv`
- Rows: 449888 | Columns: 17
- Source counts: anztox = 15667, envirotox = 72439, wqbench = 361782
- All input validation checks (Step 2) passed: source/conc_unit vocabulary, no NA/non-positive `conc_value`, `mg/L` confined to wqbench.

## 2. Phase 1 -- within-source duplicate findings

Within-source keys used (Decision G2; NA in any key field excludes a row from the check, per Decision J2b):

- **anztox**: `native_cas x scientificname_norm x medium x statistic_type_norm x effect_category x duration_hours x study_reference x conc_value`
- **wqbench**: `native_cas x scientificname_norm x medium x statistic_type_norm x effect_category x duration_hours x life_stage x study_reference x conc_value`
- **envirotox**: `native_cas x scientificname_norm x statistic_type_norm x effect_category x duration_hours x study_reference x conc_value`

| source | n_total | n_eligible | n_excluded_na_key | n_dup_groups | n_dup_rows | pct_dup |
|---|---|---|---|---|---|---|
| anztox | 15667 | 15364 | 303 | 631 | 1440 | 9.191% |
| wqbench | 361782 | 194973 | 166809 | 21197 | 90801 | 25.098% |
| envirotox | 72439 | 67601 | 4838 | 202 | 407 | 0.562% |

All sources are within the 50% within-source duplicate threshold -- pipeline proceeded to Phase 2.

### Rationale: why these rates are not a data-quality problem

The Phase 1 hard-stop threshold was downgraded from 1% to 50% (Option 1, `scripts/alldata/stage4c-deferred-decisions.md`, resolved 2026-06-24). The rates observed this run -- anztox 9.191%, wqbench 25.098%, envirotox 0.562% -- are intrinsic to each source's underlying data granularity as captured by the common 17-column schema, not symptoms of a data-quality defect or a key-design bug. The specific cause differs by source:

- **anztox** (9.191%): legitimate multi-lab ring-test replication that the schema cannot surface -- e.g. a 1987 zebrafish ring test with ~10 participating labs reporting an identical NOEC result. Confirmed via `source_id`: every row in every sampled group has a distinct `source_id`, i.e. these are genuinely separate database records, not a single record duplicated by a join.
- **wqbench** (25.098%): a structural consequence of the wqbench package's own prepared-dataset output, not a choice made in this pipeline's intercept. `wqb_create_data_set()` discards fine-grained per-row identifiers (`test_id`, `result_id`) and specific gene/biomarker descriptors before producing the RDS this pipeline reads as its source. The most extreme example found: a single paper reporting zebrafish gene-expression results across ~180 distinct genes, all sharing the same NOEC, duration, life stage, and study reference, and all bucketed under the one coarse `effect_category` value `"Genetics"` -- there is no field anywhere in wqbench's contribution to the common schema that identifies which gene/biomarker was measured.
- **envirotox** (0.562%): well under threshold; the within-source key (including `study_reference`) is sufficient to distinguish envirotox's records.

The `within_source_duplicate` flag is preserved in the output for downstream use -- this is a diagnostic flag-and-retain stage, not a hard drop. Stage 4d's geometric-mean aggregation (Section 3.4.4, Warne et al. 2025) will correctly collapse these within-source duplicate rows to single species-level values, so the elevated rates do not propagate as an error into the final SSD dataset.

**Future enhancement (deferred, out of scope for this branch):** the wqbench SQLite database (`ecotox_ascii_*.sqlite`, shipped alongside the RDS) may retain per-row identifiers recoverable via a join on `species_number x cas x endpoint x effect_conc_mg.L`. This has not been investigated and is not required for the current branch -- bypassing the RDS intercept entirely (e.g. to re-run `wqb_create_data_set()` against a fresh EPA ECOTOX download) would mean wqbench is no longer being used as a source in the form this pipeline was designed around.

### Sample within-source duplicate groups (largest first, up to 5 per source)

**anztox** (5 sample group(s) shown):

```
 source native_cas scientificname_norm     medium statistic_type_norm
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 effect_category duration_hours
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
                                                                                                                                                                                                                          study_reference
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 conc_value conc_unit source_id
      42500      ug/L     21342
      42500      ug/L     21343
      42500      ug/L     21344
      42500      ug/L     21345
      42500      ug/L     21346
      42500      ug/L     21347
      42500      ug/L     21348
      42500      ug/L     21349
      42500      ug/L     21350
      42500      ug/L     21351
```

```
 source native_cas scientificname_norm     medium statistic_type_norm
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 effect_category duration_hours
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
                                                                                                                                                                                                                          study_reference
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 conc_value conc_unit source_id
      48000      ug/L     21325
      48000      ug/L     21326
      48000      ug/L     21327
      48000      ug/L     21328
      48000      ug/L     21329
      48000      ug/L     21330
      48000      ug/L     21331
      48000      ug/L     21332
      48000      ug/L     21333
      48000      ug/L     21334
```

```
 source native_cas scientificname_norm     medium statistic_type_norm
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 anztox    7778509   brachydanio rerio Freshwater                NOEC
 effect_category duration_hours
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
            MORT            384
                                                                                                                                                                                                                          study_reference
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 Dave,G., B.Damgaard, M.Grande, J.E.Martelin, B.Rosander, and T.Viktor (1987). Ring Test of an Embryo-Larval Toxicity Test with Zebrafish (Brachydanio rerio) Using Chromium and Zinc As Toxicants. Environ. Toxicol. Chem., 6(1): 61–71.
 conc_value conc_unit source_id
      60000      ug/L     21359
      60000      ug/L     21360
      60000      ug/L     21361
      60000      ug/L     21362
      60000      ug/L     21363
      60000      ug/L     21364
      60000      ug/L     21365
      60000      ug/L     21366
      60000      ug/L     21367
      60000      ug/L     21368
```

```
 source native_cas   scientificname_norm medium statistic_type_norm
 anztox      51285 cyprinodon variegatus Marine                NOEC
 anztox      51285 cyprinodon variegatus Marine                NOEC
 anztox      51285 cyprinodon variegatus Marine                NOEC
 anztox      51285 cyprinodon variegatus Marine                NOEC
 anztox      51285 cyprinodon variegatus Marine                NOEC
 anztox      51285 cyprinodon variegatus Marine                NOEC
 anztox      51285 cyprinodon variegatus Marine                NOEC
 anztox      51285 cyprinodon variegatus Marine                NOEC
 effect_category duration_hours
            MORT            336
            MORT            336
            MORT            336
            MORT            336
            MORT            336
            MORT            336
            MORT            336
            MORT            336
                                                                                                                                                                                                                                           study_reference
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 conc_value conc_unit source_id
      10600      ug/L     10693
      10600      ug/L     10695
      10600      ug/L     10696
      10600      ug/L     10697
      10600      ug/L     10698
      10600      ug/L     10699
      10600      ug/L     10700
      10600      ug/L     10701
```

```
 source native_cas   scientificname_norm medium statistic_type_norm
 anztox      51285 cyprinodon variegatus Marine                NOEC
 anztox      51285 cyprinodon variegatus Marine                NOEC
 anztox      51285 cyprinodon variegatus Marine                NOEC
 anztox      51285 cyprinodon variegatus Marine                NOEC
 anztox      51285 cyprinodon variegatus Marine                NOEC
 anztox      51285 cyprinodon variegatus Marine                NOEC
 anztox      51285 cyprinodon variegatus Marine                NOEC
 anztox      51285 cyprinodon variegatus Marine                NOEC
 effect_category duration_hours
            MORT            504
            MORT            504
            MORT            504
            MORT            504
            MORT            504
            MORT            504
            MORT            504
            MORT            504
                                                                                                                                                                                                                                           study_reference
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 Linton,T.K., F.L.Mayer, T.L.Simon, J.A.Malone, and L.L.Marking (1994). Salinity and Temperature Effects on Chronic Toxicity of 2,4- Dinitrophenol and 4-Nitrophenol to Sheepshead Minnows (Cyprinodon variegatus). Environ. Toxicol. Chem., 13(1): 85–92.
 conc_value conc_unit source_id
      10600      ug/L     10702
      10600      ug/L     10704
      10600      ug/L     10705
      10600      ug/L     10706
      10600      ug/L     10707
      10600      ug/L     10708
      10600      ug/L     10709
      10600      ug/L     10710
```

**wqbench** (5 sample group(s) shown):

```
  source native_cas scientificname_norm     medium statistic_type_norm
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 wqbench   10102064         danio rerio Freshwater                NOEC
 effect_category duration_hours life_stage
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
             BCH            864      Adult
                                                                                                                                                                                                                                                                                                                   study_reference
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 Lerebours,A., P. Gonzalez, C. Adam, V. Camilleri, J. Bourdineaud, and J. Garnier-Laplace | Comparative Analysis of Gene Expression in Brain, Liver, Skeletal Muscles, and Gills of Zebrafish (Danio rerio) Exposed to Environmentally Relevant Waterborne Uranium Concentrations | Environ. Toxicol. Chem.28(6): 1271-1278 | 2009
 conc_value conc_unit source_id
       0.13      mg/L      6020
       0.13      mg/L      8820
       0.13      mg/L     10205
       0.13      mg/L     13029
       0.13      mg/L     14428
       0.13      mg/L     18515
       0.13      mg/L     19903
       0.13      mg/L     22700
       0.13      mg/L     24128
       0.13      mg/L     25605
       0.13      mg/L     25606
       0.13      mg/L     27020
       0.13      mg/L     29883
       0.13      mg/L     34129
       0.13      mg/L     36941
       0.13      mg/L     38418
       0.13      mg/L     39904
       0.13      mg/L     39906
       0.13      mg/L     39907
       0.13      mg/L     41336
       0.13      mg/L     42815
       0.13      mg/L     51290
       0.13      mg/L     52733
       0.13      mg/L     54164
       0.13      mg/L     54165
       0.13      mg/L     55577
       0.13      mg/L     56992
       0.13      mg/L     56994
       0.13      mg/L     59771
       0.13      mg/L     59772
       0.13      mg/L     61163
       0.13      mg/L     62592
       0.13      mg/L     63981
       0.13      mg/L     65351
       0.13      mg/L     65352
       0.13      mg/L     69594
       0.13      mg/L     71053
       0.13      mg/L     78181
       0.13      mg/L     78183
       0.13      mg/L     79580
       0.13      mg/L     79581
       0.13      mg/L     80992
       0.13      mg/L     85150
       0.13      mg/L     86596
       0.13      mg/L     89372
       0.13      mg/L     92024
       0.13      mg/L     93443
       0.13      mg/L     99164
       0.13      mg/L     99165
       0.13      mg/L    103437
       0.13      mg/L    111963
       0.13      mg/L    113439
       0.13      mg/L    113440
       0.13      mg/L    117622
       0.13      mg/L    118996
       0.13      mg/L    120401
       0.13      mg/L    121870
       0.13      mg/L    124684
       0.13      mg/L    132970
       0.13      mg/L    134440
       0.13      mg/L    137267
       0.13      mg/L    137268
       0.13      mg/L    137269
       0.13      mg/L    138683
       0.13      mg/L    141521
       0.13      mg/L    141522
       0.13      mg/L    144378
       0.13      mg/L    147259
       0.13      mg/L    151458
       0.13      mg/L    151459
       0.13      mg/L    152977
       0.13      mg/L    152978
       0.13      mg/L    152979
       0.13      mg/L    157212
       0.13      mg/L    162894
       0.13      mg/L    162895
       0.13      mg/L    165725
       0.13      mg/L    168672
       0.13      mg/L    171466
       0.13      mg/L    172885
       0.13      mg/L    174315
       0.13      mg/L    175703
       0.13      mg/L    177152
       0.13      mg/L    177153
       0.13      mg/L    179999
       0.13      mg/L    180000
       0.13      mg/L    181374
       0.13      mg/L    182819
       0.13      mg/L    184244
       0.13      mg/L    184245
       0.13      mg/L    194217
       0.13      mg/L    195646
       0.13      mg/L    198509
       0.13      mg/L    198510
       0.13      mg/L    198511
       0.13      mg/L    202743
       0.13      mg/L    205677
       0.13      mg/L    207159
       0.13      mg/L    207160
       0.13      mg/L    208520
       0.13      mg/L    209856
       0.13      mg/L    211285
       0.13      mg/L    215479
       0.13      mg/L    219821
       0.13      mg/L    222675
       0.13      mg/L    224062
       0.13      mg/L    225499
       0.13      mg/L    225500
       0.13      mg/L    226914
       0.13      mg/L    231155
       0.13      mg/L    231156
       0.13      mg/L    231158
       0.13      mg/L    232510
       0.13      mg/L    232511
       0.13      mg/L    235346
       0.13      mg/L    236730
       0.13      mg/L    238129
       0.13      mg/L    239524
       0.13      mg/L    239525
       0.13      mg/L    242374
       0.13      mg/L    243822
       0.13      mg/L    245236
       0.13      mg/L    246594
       0.13      mg/L    249412
       0.13      mg/L    250830
       0.13      mg/L    252261
       0.13      mg/L    252262
       0.13      mg/L    256492
       0.13      mg/L    257900
       0.13      mg/L    259291
       0.13      mg/L    259295
       0.13      mg/L    260676
       0.13      mg/L    263563
       0.13      mg/L    267859
       0.13      mg/L    270715
       0.13      mg/L    270716
       0.13      mg/L    274925
       0.13      mg/L    276347
       0.13      mg/L    277755
       0.13      mg/L    279144
       0.13      mg/L    280548
       0.13      mg/L    283389
       0.13      mg/L    284763
       0.13      mg/L    286140
       0.13      mg/L    287523
       0.13      mg/L    287524
       0.13      mg/L    288895
       0.13      mg/L    288896
       0.13      mg/L    290291
       0.13      mg/L    293111
       0.13      mg/L    300211
       0.13      mg/L    300212
       0.13      mg/L    300213
       0.13      mg/L    307285
       0.13      mg/L    308649
       0.13      mg/L    310039
       0.13      mg/L    310040
       0.13      mg/L    311451
       0.13      mg/L    314311
       0.13      mg/L    315670
       0.13      mg/L    318445
       0.13      mg/L    322589
       0.13      mg/L    324051
       0.13      mg/L    324053
       0.13      mg/L    324054
       0.13      mg/L    324055
       0.13      mg/L    326823
       0.13      mg/L    329628
       0.13      mg/L    332368
       0.13      mg/L    333780
       0.13      mg/L    336667
       0.13      mg/L    343550
       0.13      mg/L    347771
       0.13      mg/L    352142
       0.13      mg/L    353571
       0.13      mg/L    353572
       0.13      mg/L    354989
       0.13      mg/L    359278
       0.13      mg/L    359279
       0.13      mg/L    359280
       0.13      mg/L    360708
       0.13      mg/L    360710
```

```
  source native_cas scientificname_norm     medium statistic_type_norm
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 wqbench     375735         danio rerio Freshwater                NOEC
 effect_category duration_hours life_stage
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
             BCH            336      Adult
                                                                                                                                                                                                                                          study_reference
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 Hu,C., B. Sun, M. Liu, J. Yu, X. Zhou, and L. Chen | Fecal Transplantation from Young Zebrafish Donors Efficiently Ameliorates the Lipid Metabolism Disorder of Aged Recipients Exposed to Perfluorobutanesulfonate | Sci. Total Environ.823:8 p. | 2022
 conc_value conc_unit source_id
        0.1      mg/L       349
        0.1      mg/L       350
        0.1      mg/L       654
        0.1      mg/L      1718
        0.1      mg/L      3178
        0.1      mg/L      4631
        0.1      mg/L      4632
        0.1      mg/L      7473
        0.1      mg/L     10569
        0.1      mg/L     10572
        0.1      mg/L     11964
        0.1      mg/L     17216
        0.1      mg/L     17217
        0.1      mg/L     21342
        0.1      mg/L     21343
        0.1      mg/L     25982
        0.1      mg/L     27407
        0.1      mg/L     31635
        0.1      mg/L     32761
        0.1      mg/L     34192
        0.1      mg/L     34505
        0.1      mg/L     39963
        0.1      mg/L     41387
        0.1      mg/L     44617
        0.1      mg/L     48495
        0.1      mg/L     49927
        0.1      mg/L     50240
        0.1      mg/L     50241
        0.1      mg/L     55952
        0.1      mg/L     57053
        0.1      mg/L     62939
        0.1      mg/L     65717
        0.1      mg/L     69650
        0.1      mg/L     71413
        0.1      mg/L     72485
        0.1      mg/L     75624
        0.1      mg/L     78549
        0.1      mg/L     85527
        0.1      mg/L     86647
        0.1      mg/L     88010
        0.1      mg/L     99229
        0.1      mg/L    103497
        0.1      mg/L    104951
        0.1      mg/L    109499
        0.1      mg/L    110602
        0.1      mg/L    110603
        0.1      mg/L    112020
        0.1      mg/L    112021
        0.1      mg/L    113829
        0.1      mg/L    116311
        0.1      mg/L    117978
        0.1      mg/L    119375
        0.1      mg/L    125028
        0.1      mg/L    126389
        0.1      mg/L    128842
        0.1      mg/L    130260
        0.1      mg/L    130261
        0.1      mg/L    131934
        0.1      mg/L    136236
        0.1      mg/L    138739
        0.1      mg/L    141903
        0.1      mg/L    141904
        0.1      mg/L    143341
        0.1      mg/L    143344
        0.1      mg/L    145868
        0.1      mg/L    150448
        0.1      mg/L    159055
        0.1      mg/L    159058
        0.1      mg/L    159060
        0.1      mg/L    165775
        0.1      mg/L    166112
        0.1      mg/L    169030
        0.1      mg/L    176065
        0.1      mg/L    176066
        0.1      mg/L    177543
        0.1      mg/L    178645
        0.1      mg/L    178951
        0.1      mg/L    180055
        0.1      mg/L    181429
        0.1      mg/L    181430
        0.1      mg/L    183197
        0.1      mg/L    184304
        0.1      mg/L    186010
        0.1      mg/L    191414
        0.1      mg/L    191415
        0.1      mg/L    195715
        0.1      mg/L    197143
        0.1      mg/L    200286
        0.1      mg/L    202801
        0.1      mg/L    202802
        0.1      mg/L    206048
        0.1      mg/L    206049
        0.1      mg/L    207500
        0.1      mg/L    208568
        0.1      mg/L    209910
        0.1      mg/L    210235
        0.1      mg/L    211335
        0.1      mg/L    211336
        0.1      mg/L    215842
        0.1      mg/L    216981
        0.1      mg/L    216982
        0.1      mg/L    217302
        0.1      mg/L    224128
        0.1      mg/L    225559
        0.1      mg/L    225892
        0.1      mg/L    228667
        0.1      mg/L    230148
        0.1      mg/L    236784
        0.1      mg/L    241325
        0.1      mg/L    244215
        0.1      mg/L    245613
        0.1      mg/L    250878
        0.1      mg/L    259635
        0.1      mg/L    266483
        0.1      mg/L    270786
        0.1      mg/L    272201
        0.1      mg/L    276731
        0.1      mg/L    284820
        0.1      mg/L    288939
        0.1      mg/L    294576
        0.1      mg/L    297433
        0.1      mg/L    300579
        0.1      mg/L    303431
        0.1      mg/L    304796
        0.1      mg/L    311819
        0.1      mg/L    314378
        0.1      mg/L    315724
        0.1      mg/L    316033
        0.1      mg/L    317113
        0.1      mg/L    317114
        0.1      mg/L    317410
        0.1      mg/L    318822
        0.1      mg/L    318823
        0.1      mg/L    320204
        0.1      mg/L    321569
        0.1      mg/L    322638
        0.1      mg/L    322966
        0.1      mg/L    324113
        0.1      mg/L    324461
        0.1      mg/L    327174
        0.1      mg/L    331346
        0.1      mg/L    335287
        0.1      mg/L    335603
        0.1      mg/L    352194
        0.1      mg/L    356475
        0.1      mg/L    360760
```

```
  source native_cas scientificname_norm     medium statistic_type_norm
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 wqbench     335671   gobiocypris rarus Freshwater                LOEC
 effect_category duration_hours life_stage
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
             BCH            672      Adult
                                                                                                                                                                                             study_reference
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 Wei,Y., Y. Liu, J. Wang, Y. Tao, and J. Dai | Toxicogenomic Analysis of the Hepatic Effects of Perfluorooctanoic Acid on Rare Minnows (Gobiocypris rarus) | Toxicol. Appl. Pharmacol.226(3): 285-297 | 2008
 conc_value conc_unit source_id
         10      mg/L      3149
         10      mg/L      3578
         10      mg/L      4263
         10      mg/L     11092
         10      mg/L     11139
         10      mg/L     14571
         10      mg/L     16906
         10      mg/L     18800
         10      mg/L     19240
         10      mg/L     26577
         10      mg/L     27614
         10      mg/L     31074
         10      mg/L     33029
         10      mg/L     41065
         10      mg/L     45831
         10      mg/L     47572
         10      mg/L     49141
         10      mg/L     50507
         10      mg/L     56734
         10      mg/L     58461
         10      mg/L     60200
         10      mg/L     60215
         10      mg/L     61145
         10      mg/L     64504
         10      mg/L     67024
         10      mg/L     69316
         10      mg/L     71035
         10      mg/L     82305
         10      mg/L     85982
         10      mg/L     85989
         10      mg/L     92577
         10      mg/L     92750
         10      mg/L     95317
         10      mg/L     95853
         10      mg/L    100053
         10      mg/L    107342
         10      mg/L    107558
         10      mg/L    113539
         10      mg/L    113567
         10      mg/L    114035
         10      mg/L    119233
         10      mg/L    123318
         10      mg/L    125010
         10      mg/L    128147
         10      mg/L    132412
         10      mg/L    133522
         10      mg/L    135981
         10      mg/L    144678
         10      mg/L    150072
         10      mg/L    150397
         10      mg/L    151440
         10      mg/L    151614
         10      mg/L    152265
         10      mg/L    153102
         10      mg/L    155423
         10      mg/L    155732
         10      mg/L    158035
         10      mg/L    158190
         10      mg/L    161343
         10      mg/L    164344
         10      mg/L    166735
         10      mg/L    170091
         10      mg/L    170858
         10      mg/L    172296
         10      mg/L    173285
         10      mg/L    176866
         10      mg/L    179525
         10      mg/L    184064
         10      mg/L    186321
         10      mg/L    187019
         10      mg/L    189146
         10      mg/L    190171
         10      mg/L    198071
         10      mg/L    202903
         10      mg/L    203801
         10      mg/L    206459
         10      mg/L    207655
         10      mg/L    214772
         10      mg/L    217099
         10      mg/L    217858
         10      mg/L    218327
         10      mg/L    221869
         10      mg/L    224213
         10      mg/L    224747
         10      mg/L    226567
         10      mg/L    228442
         10      mg/L    231309
         10      mg/L    236387
         10      mg/L    241967
         10      mg/L    243253
         10      mg/L    245289
         10      mg/L    245437
         10      mg/L    246123
         10      mg/L    254781
         10      mg/L    259843
         10      mg/L    262274
         10      mg/L    264058
         10      mg/L    264292
         10      mg/L    266542
         10      mg/L    268237
         10      mg/L    268324
         10      mg/L    270468
         10      mg/L    273429
         10      mg/L    277007
         10      mg/L    277490
         10      mg/L    281019
         10      mg/L    284957
         10      mg/L    289231
         10      mg/L    289633
         10      mg/L    289670
         10      mg/L    289920
         10      mg/L    292050
         10      mg/L    292532
         10      mg/L    293088
         10      mg/L    296568
         10      mg/L    297451
         10      mg/L    300556
         10      mg/L    302853
         10      mg/L    304310
         10      mg/L    306232
         10      mg/L    308150
         10      mg/L    308835
         10      mg/L    309674
         10      mg/L    312071
         10      mg/L    313617
         10      mg/L    317555
         10      mg/L    318129
         10      mg/L    320466
         10      mg/L    321931
         10      mg/L    322435
         10      mg/L    324136
         10      mg/L    326094
         10      mg/L    334105
         10      mg/L    334431
         10      mg/L    334468
         10      mg/L    335793
         10      mg/L    345534
         10      mg/L    346602
         10      mg/L    350618
         10      mg/L    354009
         10      mg/L    354601
         10      mg/L    357040
         10      mg/L    357310
         10      mg/L    358351
         10      mg/L    358489
```

```
  source native_cas scientificname_norm medium statistic_type_norm
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 wqbench     375735  oryzias melastigma Marine                NOEC
 effect_category duration_hours life_stage
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
             BCH            504      Adult
                                                                                                                                                                                                                             study_reference
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 Sun,B., J. Li, C. Hu, J.P. Giesy, P.K.S. Lam, and L. Chen | Toxicity of Perfluorobutanesulfonate on Gill Functions of Marine Medaka (Oryzias melastigma): A Time Course and Hypoxia Co-Exposure Study | Sci. Total Environ.872:12 p. | 2023
 conc_value conc_unit source_id
     0.0095      mg/L      2798
     0.0095      mg/L      5671
     0.0095      mg/L      9849
     0.0095      mg/L     15490
     0.0095      mg/L     18202
     0.0095      mg/L     19580
     0.0095      mg/L     25938
     0.0095      mg/L     27367
     0.0095      mg/L     28147
     0.0095      mg/L     30903
     0.0095      mg/L     33777
     0.0095      mg/L     35897
     0.0095      mg/L     37271
     0.0095      mg/L     38035
     0.0095      mg/L     46662
     0.0095      mg/L     47298
     0.0095      mg/L     50966
     0.0095      mg/L     62231
     0.0095      mg/L     63657
     0.0095      mg/L     64979
     0.0095      mg/L     72107
     0.0095      mg/L     73504
     0.0095      mg/L     73505
     0.0095      mg/L     77807
     0.0095      mg/L     77809
     0.0095      mg/L     80664
     0.0095      mg/L     83392
     0.0095      mg/L     84813
     0.0095      mg/L     86919
     0.0095      mg/L     86920
     0.0095      mg/L     89026
     0.0095      mg/L     92333
     0.0095      mg/L     93065
     0.0095      mg/L     96011
     0.0095      mg/L     97351
     0.0095      mg/L    100917
     0.0095      mg/L    104536
     0.0095      mg/L    106649
     0.0095      mg/L    107360
     0.0095      mg/L    113792
     0.0095      mg/L    114516
     0.0095      mg/L    115167
     0.0095      mg/L    116571
     0.0095      mg/L    117932
     0.0095      mg/L    120052
     0.0095      mg/L    123616
     0.0095      mg/L    125738
     0.0095      mg/L    125739
     0.0095      mg/L    125740
     0.0095      mg/L    131230
     0.0095      mg/L    132609
     0.0095      mg/L    133289
     0.0095      mg/L    134077
     0.0095      mg/L    139039
     0.0095      mg/L    139802
     0.0095      mg/L    139803
     0.0095      mg/L    143303
     0.0095      mg/L    150410
     0.0095      mg/L    168309
     0.0095      mg/L    168310
     0.0095      mg/L    168994
     0.0095      mg/L    170384
     0.0095      mg/L    171124
     0.0095      mg/L    172548
     0.0095      mg/L    174623
     0.0095      mg/L    177500
     0.0095      mg/L    182479
     0.0095      mg/L    185280
     0.0095      mg/L    186702
     0.0095      mg/L    192448
     0.0095      mg/L    206001
     0.0095      mg/L    209525
     0.0095      mg/L    211614
     0.0095      mg/L    212358
     0.0095      mg/L    214383
     0.0095      mg/L    215140
     0.0095      mg/L    222983
     0.0095      mg/L    225169
     0.0095      mg/L    226600
     0.0095      mg/L    232168
     0.0095      mg/L    232169
     0.0095      mg/L    234262
     0.0095      mg/L    236371
     0.0095      mg/L    241999
     0.0095      mg/L    242000
     0.0095      mg/L    243464
     0.0095      mg/L    249727
     0.0095      mg/L    251899
     0.0095      mg/L    251900
     0.0095      mg/L    256174
     0.0095      mg/L    258960
     0.0095      mg/L    259595
     0.0095      mg/L    263208
     0.0095      mg/L    264644
     0.0095      mg/L    270368
     0.0095      mg/L    271790
     0.0095      mg/L    280206
     0.0095      mg/L    282279
     0.0095      mg/L    287174
     0.0095      mg/L    289210
     0.0095      mg/L    293427
     0.0095      mg/L    294193
     0.0095      mg/L    297036
     0.0095      mg/L    299047
     0.0095      mg/L    301285
     0.0095      mg/L    308972
     0.0095      mg/L    315336
     0.0095      mg/L    316744
     0.0095      mg/L    319536
     0.0095      mg/L    323702
     0.0095      mg/L    324406
     0.0095      mg/L    327906
     0.0095      mg/L    334871
     0.0095      mg/L    340527
     0.0095      mg/L    346721
     0.0095      mg/L    348919
     0.0095      mg/L    350372
     0.0095      mg/L    361008
```

```
  source native_cas scientificname_norm     medium statistic_type_norm
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 wqbench      84742     cyprinus carpio Freshwater                LOEC
 effect_category duration_hours life_stage
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
             BCH            840 Fingerling
                                                                                                                                                                                                               study_reference
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 Poopal,R.K., M. Ramesh, V. Maruthappan, and R.B. Rajendran | Potential Effects of Low Molecular Weight Phthalate Esters (C16H22O4 and C12H14O4) on the Freshwater Fish Cyprinus carpio | Toxicol. Res. (Oxf.)6:505-520 | 2017
 conc_value conc_unit source_id
       1.75      mg/L      1193
       1.75      mg/L      1194
       1.75      mg/L      4063
       1.75      mg/L      8337
       1.75      mg/L      9708
       1.75      mg/L     11123
       1.75      mg/L     20837
       1.75      mg/L     29431
       1.75      mg/L     35087
       1.75      mg/L     36458
       1.75      mg/L     37908
       1.75      mg/L     39387
       1.75      mg/L     40856
       1.75      mg/L     43767
       1.75      mg/L     47951
       1.75      mg/L     55102
       1.75      mg/L     55103
       1.75      mg/L     57967
       1.75      mg/L     60703
       1.75      mg/L     73346
       1.75      mg/L     84680
       1.75      mg/L     87493
       1.75      mg/L     92930
       1.75      mg/L    100125
       1.75      mg/L    100126
       1.75      mg/L    105837
       1.75      mg/L    110066
       1.75      mg/L    110067
       1.75      mg/L    114376
       1.75      mg/L    115795
       1.75      mg/L    115797
       1.75      mg/L    122808
       1.75      mg/L    124210
       1.75      mg/L    124213
       1.75      mg/L    125601
       1.75      mg/L    129729
       1.75      mg/L    141086
       1.75      mg/L    141087
       1.75      mg/L    145351
       1.75      mg/L    149621
       1.75      mg/L    155325
       1.75      mg/L    168153
       1.75      mg/L    175231
       1.75      mg/L    176675
       1.75      mg/L    176676
       1.75      mg/L    178083
       1.75      mg/L    178085
       1.75      mg/L    187979
       1.75      mg/L    187984
       1.75      mg/L    193737
       1.75      mg/L    203716
       1.75      mg/L    205174
       1.75      mg/L    205175
       1.75      mg/L    209415
       1.75      mg/L    210806
       1.75      mg/L    212226
       1.75      mg/L    219299
       1.75      mg/L    225039
       1.75      mg/L    230705
       1.75      mg/L    234871
       1.75      mg/L    239058
       1.75      mg/L    239059
       1.75      mg/L    240466
       1.75      mg/L    243326
       1.75      mg/L    261647
       1.75      mg/L    267377
       1.75      mg/L    268735
       1.75      mg/L    268736
       1.75      mg/L    268740
       1.75      mg/L    274456
       1.75      mg/L    274457
       1.75      mg/L    275877
       1.75      mg/L    275886
       1.75      mg/L    278686
       1.75      mg/L    278687
       1.75      mg/L    282922
       1.75      mg/L    285696
       1.75      mg/L    291217
       1.75      mg/L    296902
       1.75      mg/L    298286
       1.75      mg/L    301148
       1.75      mg/L    303998
       1.75      mg/L    305344
       1.75      mg/L    308133
       1.75      mg/L    312390
       1.75      mg/L    315209
       1.75      mg/L    317981
       1.75      mg/L    322142
       1.75      mg/L    325012
       1.75      mg/L    326352
       1.75      mg/L    336181
       1.75      mg/L    336192
       1.75      mg/L    337621
       1.75      mg/L    344543
       1.75      mg/L    347277
       1.75      mg/L    348775
       1.75      mg/L    348776
       1.75      mg/L    351652
       1.75      mg/L    353098
       1.75      mg/L    355935
       1.75      mg/L    357361
       1.75      mg/L    358777
       1.75      mg/L    360216
```

**envirotox** (5 sample group(s) shown):

```
    source native_cas scientificname_norm statistic_type_norm effect_category
 envirotox  107534963     daphnia galeata                NOEC             REP
 envirotox  107534963     daphnia galeata                NOEC             REP
 envirotox  107534963     daphnia galeata                NOEC             REP
 duration_hours
            504
            504
            504
                                                                                                                                                                     study_reference
 Cuco,A.P., N. Abrantes, F. Goncalves, J. Wolinska, and B.B. Castro. Toxicity of Two Fungicides in Daphnia: Is It Always Temperature-Dependent?. 2016. Ecotoxicology25(7): 1376-1389
 Cuco,A.P., N. Abrantes, F. Goncalves, J. Wolinska, and B.B. Castro. Toxicity of Two Fungicides in Daphnia: Is It Always Temperature-Dependent?. 2016. Ecotoxicology25(7): 1376-1389
 Cuco,A.P., N. Abrantes, F. Goncalves, J. Wolinska, and B.B. Castro. Toxicity of Two Fungicides in Daphnia: Is It Always Temperature-Dependent?. 2016. Ecotoxicology25(7): 1376-1389
 conc_value conc_unit source_id
        192      ug/L     71354
        192      ug/L     71356
        192      ug/L     71357
```

```
    source native_cas scientificname_norm statistic_type_norm effect_category
 envirotox    7758987     daphnia galeata                NOEC             REP
 envirotox    7758987     daphnia galeata                NOEC             REP
 envirotox    7758987     daphnia galeata                NOEC             REP
 duration_hours
            504
            504
            504
                                                                                                                                                                     study_reference
 Cuco,A.P., N. Abrantes, F. Goncalves, J. Wolinska, and B.B. Castro. Toxicity of Two Fungicides in Daphnia: Is It Always Temperature-Dependent?. 2016. Ecotoxicology25(7): 1376-1389
 Cuco,A.P., N. Abrantes, F. Goncalves, J. Wolinska, and B.B. Castro. Toxicity of Two Fungicides in Daphnia: Is It Always Temperature-Dependent?. 2016. Ecotoxicology25(7): 1376-1389
 Cuco,A.P., N. Abrantes, F. Goncalves, J. Wolinska, and B.B. Castro. Toxicity of Two Fungicides in Daphnia: Is It Always Temperature-Dependent?. 2016. Ecotoxicology25(7): 1376-1389
 conc_value conc_unit source_id
       33.1      ug/L     52900
       33.1      ug/L     52902
       33.1      ug/L     52903
```

```
    source native_cas scientificname_norm statistic_type_norm effect_category
 envirotox      84742 oncorhynchus mykiss                NOEC             GRO
 envirotox      84742 oncorhynchus mykiss                NOEC             GRO
 envirotox      84742 oncorhynchus mykiss                NOEC             GRO
 duration_hours
           2376
           2376
           2376
                                                                                                                                                                                                             study_reference
 Rhodes,J.E., W.J. Adams, G.R. Biddinger, K.A. Robillard, and J.W. Gorsuch. Chronic Toxicity of 14 Phthalate Esters to Daphnia magna and Rainbow Trout (Oncorhynchus mykiss). 1995. Environ. Toxicol. Chem.14(11): 1967-1976
 Rhodes,J.E., W.J. Adams, G.R. Biddinger, K.A. Robillard, and J.W. Gorsuch. Chronic Toxicity of 14 Phthalate Esters to Daphnia magna and Rainbow Trout (Oncorhynchus mykiss). 1995. Environ. Toxicol. Chem.14(11): 1967-1976
 Rhodes,J.E., W.J. Adams, G.R. Biddinger, K.A. Robillard, and J.W. Gorsuch. Chronic Toxicity of 14 Phthalate Esters to Daphnia magna and Rainbow Trout (Oncorhynchus mykiss). 1995. Environ. Toxicol. Chem.14(11): 1967-1976
 conc_value conc_unit source_id
        100      ug/L     10242
        100      ug/L     10243
        100      ug/L     10244
```

```
    source native_cas scientificname_norm statistic_type_norm effect_category
 envirotox   10025737       daphnia magna                NOEC             REP
 envirotox   10025737       daphnia magna                NOEC             REP
 duration_hours
            504
            504
                                                                                                                                                                       study_reference
 Kuhn, R., M. Pattard, K.D. Pernak, and A. Winter, 1989. Results of the Harmful Effects of Water Pollutants to Daphnia magna in the 21 Day Reproduction Test, Water Res. 23(4):501-510
 Kuhn, R., M. Pattard, K.D. Pernak, and A. Winter, 1989. Results of the Harmful Effects of Water Pollutants to Daphnia magna in the 21 Day Reproduction Test, Water Res. 23(4):501-510
 conc_value conc_unit source_id
        700      ug/L     56520
        700      ug/L     56521
```

```
    source native_cas scientificname_norm statistic_type_norm effect_category
 envirotox   10043353       daphnia magna                NOEC             REP
 envirotox   10043353       daphnia magna                NOEC             REP
 duration_hours
            504
            504
                                                                                                                                       study_reference
 Lewis, M.A., and L.C. Valentine, 1981. Acute and Chronic Toxicities of Boric Acid to Daphnia magna Straus, Bull.Environ.Contam.Toxicol. 27(3):309-315
 Lewis, M.A., and L.C. Valentine, 1981. Acute and Chronic Toxicities of Boric Acid to Daphnia magna Straus, Bull.Environ.Contam.Toxicol. 27(3):309-315
 conc_value conc_unit source_id
       6000      ug/L     56721
       6000      ug/L     56722
```

---

## 3. Phase 2 -- cross-source duplicate detection

**J-DEVIATION resolved (Stage 4c Part 3):** in the prior run of this report, `effect_category` was removed from the cross-source key by explicit user decision taken mid-session, because it was not yet a shared vocabulary across sources -- wqbench retained its own literal English-word vocabulary (`effect_category = effect`), while anztox and envirotox used MORT/GRO/REP-style codes, and including it produced *zero* cross-source candidate groups anywhere in the file. `scripts/alldata/stage4c-effect-category-fixup.R` has since harmonised wqbench's English words and anztox's free-text tail onto the shared codes (unmappable values set to NA rather than guessed), so `effect_category` is restored to the key for this run:

`native_cas x scientificname_norm x medium x statistic_type_norm x effect_category x duration_hours x conc_ug_L (0.1% relative tolerance)`

### NA exclusions from cross-source dedup (Decision J2b)

| source | n_excluded_cs_na |
|---|---|
| anztox | 303 |
| envirotox | 4838 |
| wqbench | 21971 |

### Source-pair breakdown (exact + tolerance matches)

| dropped source | preferred (retained) source | match_type | n_rows |
|---|---|---|---|
| anztox | wqbench | exact | 6575 |
| anztox | wqbench | tolerance | 375 |
| envirotox | wqbench | exact | 390 |
| envirotox | wqbench | tolerance | 26 |

- Exact-pass rows flagged (Step 5e): 6965
- Tolerance-pass rows flagged (Step 5f): 401
- Total cross-source duplicate rows flagged (dedup_retained = FALSE): 7366

### Match counts at alternative tolerance thresholds (diagnostic only)

| threshold | n_rows_flagged |
|---|---|
| 0.000% | 6965 |
| 0.100% | 7366 |
| 1.000% | 7473 |
| 5.000% | 7730 |

Confirmed: the 0% threshold diagnostic count matches the Step 5e exact-pass count exactly.

Max group size for the tolerance pass (key minus conc_ug_L): 284 rows.

Sanity check (5i) passed: no cross-source group retains a record from a lower-priority source than a record it drops.

---

## 4. Phase 3 -- ANZG priority selection

Applied to `dedup_retained == TRUE` rows only, grouped by `native_cas x scientificname_norm x medium x effect_category` (Decision H2: `native_cas`, not `casnumber_grouped`). Within each group, chronic > subchronic > acute priority is applied; only the highest-priority test_class present in the group is kept (`priority_kept = TRUE`).

### priority_kept counts, total and by source

Total:
```
# A tibble: 3 × 2
  priority_kept      n
  <lgl>          <int>
1 FALSE          61112
2 TRUE          381410
3 NA              7366
```

By source (retained rows only):
```
# A tibble: 6 × 3
  source    priority_kept      n
  <chr>     <lgl>          <int>
1 anztox    FALSE            958
2 anztox    TRUE            7759
3 envirotox FALSE          11199
4 envirotox TRUE           60824
5 wqbench   FALSE          48955
6 wqbench   TRUE          312827
```

### Rows displaced by priority selection (priority_kept == FALSE), by source and displaced test_class

```
# A tibble: 4 × 3
  source    test_class     n
  <chr>     <chr>      <int>
1 anztox    acute        957
2 anztox    subchronic     1
3 envirotox acute      11199
4 wqbench   acute      48955
```

Sanity check (6d) passed: every `(native_cas, scientificname_norm, medium, effect_category)` group with `priority_kept == TRUE` rows is internally single-`test_class`.

---

## 5. Final retention summary

### "Final clean" subset (dedup_retained AND priority_kept), by source

```
# A tibble: 3 × 2
  source         n
  <chr>      <int>
1 anztox      7759
2 envirotox  60824
3 wqbench   312827
```

Total final-clean rows: 381410
Distinct `casnumber_grouped` values in the final clean subset: 6003

### dedup_retained == FALSE, by source and match_type

```
# A tibble: 4 × 3
  source    match_type     n
  <chr>     <chr>      <int>
1 anztox    exact       6575
2 anztox    tolerance    375
3 envirotox exact        390
4 envirotox tolerance     26
```

### within_source_duplicate == TRUE, by source

```
# A tibble: 3 × 2
  source        n
  <chr>     <int>
1 anztox     1440
2 envirotox   407
3 wqbench   90801
```

---

## 6. Anomalies and findings requiring human attention

1. **RESOLVED (Stage 4c Part 3) -- `effect_category` is now a shared cross-source vocabulary.** `scripts/alldata/stage4c-effect-category-fixup.R` mapped wqbench's literal English-word field (`Mortality`, `Growth`, ...) onto the MORT/GRO/REP-style codes already used by anztox and envirotox, using an explicit lookup table; values with no table entry (`Intoxication`, `Multiple`, `General`, `Accumulation`, plus `Unspecified`/`Immunological`/`Injury`/`Ecosystem process`, not anticipated by the original mapping table) were set to NA rather than guessed. `effect_category` is restored to both the cross-source key (Phase 2, this run) and was already in the Phase 3 priority-selection key -- cross-source priority comparisons against wqbench now group correctly with anztox/envirotox records of the same endpoint. See `data-raw/alldata/uncurated_raw_combined.csv`'s `effect_category` column and the fixup script's header for the full mapping.

2. **RESOLVED (Stage 4c Part 3) -- anztox free-text fallback values mapped or explicitly excluded.** 240 anztox rows previously carried raw free-text or non-standard codes (e.g. "Disc area", "Dry mass", "PGR", "Cumulative eggs layed/female") instead of the controlled MORT/GRO/REP-style codes. A first-pass keyword classifier (`scripts/alldata/stage4c-effect-category-fixup.R` Step 1c) mapped 65 of these to a controlled code; the remaining 175 (dominated by "PGR", 147 rows) could not be classified by keyword and were set to NA -- they are excluded from cross-source dedup and priority selection rather than guessed. Full audit trail with proposed mappings: `data-raw/alldata/anztox_2016_effect_category_map.csv`. Recommended follow-up: human review of the 175 NA rows ("PGR" in particular) before Stage 4d, since the same field is used there for aggregation grouping.

3. **Checked (Stage 4c Part 3) -- envirotox `MOR` vs `MORT` confirmed correct, no change needed.** `scripts/alldata/stage4c-effect-category-fixup.R` Step 1d cross-checked every `MOR`- and `MORT`-mapped raw `Effect` value in `envirotox_effect_category_map.csv` for misassignment (e.g. a mortality-worded value mapped to `MOR`, or a morphology-worded value mapped to `MORT`). None were found: `MOR` (4 rows) covers genuine morphology endpoints ("Morphology, Shell deposition"; "Regeneration..."), and `MORT` (52,432 rows) covers genuine mortality/survival endpoints. The two codes correctly distinguish distinct underlying categories and were left as-is.

