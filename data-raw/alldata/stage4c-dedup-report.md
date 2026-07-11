# Stage 4c Part 2 -- Cross-Source Duplicate Detection and ANZG Priority Selection
Date: 2026-06-24

**Revised (Stage 4c Part 3, session "stage4c-part3-effect-category-harmonisation"):** this run follows `data-raw/alldata/scripts/stage4c-effect-category-fixup.R`, which harmonised `effect_category` to a single controlled vocabulary across all three sources. `effect_category` is now included in the cross-source key (Phase 2) and produces correct cross-source comparisons in the ANZG priority-selection grouping (Phase 3) -- both previously limited by the vocabulary mismatch documented in the prior run of this report (see Section 3 and Section 6 below for the resolution).

Audit-and-flag stage only -- no rows were hard-dropped from `uncurated_raw_combined.csv`. All 449,098 rows appear in `uncurated_raw_dedup.csv` with four new columns: `within_source_duplicate`, `dedup_retained`, `priority_kept`, `dedup_note`.

---

## 1. Input summary

- Input: `data-raw/alldata/uncurated_raw_combined.csv`
- Rows: 449098 | Columns: 17
- Source counts: anztox = 15391, envirotox = 72388, wqbench = 361319
- All input validation checks (Step 2) passed: source/conc_unit vocabulary, no NA/non-positive `conc_value`, `mg/L` confined to wqbench.

## 2. Phase 1 -- within-source duplicate findings

Within-source keys used (Decision G2; NA in any key field excludes a row from the check, per Decision J2b):

- **anztox**: `native_cas x scientificname_norm x medium x statistic_type_norm x effect_category x duration_hours x study_reference x conc_value`
- **wqbench**: `native_cas x scientificname_norm x medium x statistic_type_norm x effect_category x duration_hours x life_stage x study_reference x conc_value`
- **envirotox**: `native_cas x scientificname_norm x statistic_type_norm x effect_category x duration_hours x study_reference x conc_value`

| source | n_total | n_eligible | n_excluded_na_key | n_dup_groups | n_dup_rows | pct_dup |
|---|---|---|---|---|---|---|
| anztox | 15391 | 15374 | 17 | 625 | 1427 | 9.272% |
| wqbench | 361319 | 194773 | 166546 | 21184 | 90770 | 25.122% |
| envirotox | 72388 | 67557 | 4831 | 201 | 405 | 0.559% |

All sources are within the 50% within-source duplicate threshold -- pipeline proceeded to Phase 2.

### Rationale: why these rates are not a data-quality problem

The Phase 1 hard-stop threshold was downgraded from 1% to 50% (Option 1, `data-raw/alldata/scripts/stage4c-deferred-decisions.md`, resolved 2026-06-24). The rates observed this run -- anztox 9.272%, wqbench 25.122%, envirotox 0.559% -- are intrinsic to each source's underlying data granularity as captured by the common 17-column schema, not symptoms of a data-quality defect or a key-design bug. The specific cause differs by source:

- **anztox** (9.272%): legitimate multi-lab ring-test replication that the schema cannot surface -- e.g. a 1987 zebrafish ring test with ~10 participating labs reporting an identical NOEC result. Confirmed via `source_id`: every row in every sampled group has a distinct `source_id`, i.e. these are genuinely separate database records, not a single record duplicated by a join.
- **wqbench** (25.122%): a structural consequence of the wqbench package's own prepared-dataset output, not a choice made in this pipeline's intercept. `wqb_create_data_set()` discards fine-grained per-row identifiers (`test_id`, `result_id`) and specific gene/biomarker descriptors before producing the RDS this pipeline reads as its source. The most extreme example found: a single paper reporting zebrafish gene-expression results across ~180 distinct genes, all sharing the same NOEC, duration, life stage, and study reference, and all bucketed under the one coarse `effect_category` value `"Genetics"` -- there is no field anywhere in wqbench's contribution to the common schema that identifies which gene/biomarker was measured.
- **envirotox** (0.559%): well under threshold; the within-source key (including `study_reference`) is sufficient to distinguish envirotox's records.

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
       0.13      mg/L      6013
       0.13      mg/L      8807
       0.13      mg/L     10190
       0.13      mg/L     13012
       0.13      mg/L     14411
       0.13      mg/L     18490
       0.13      mg/L     19873
       0.13      mg/L     22670
       0.13      mg/L     24097
       0.13      mg/L     25571
       0.13      mg/L     25572
       0.13      mg/L     26984
       0.13      mg/L     29843
       0.13      mg/L     34085
       0.13      mg/L     36895
       0.13      mg/L     38369
       0.13      mg/L     39852
       0.13      mg/L     39854
       0.13      mg/L     39855
       0.13      mg/L     41283
       0.13      mg/L     42758
       0.13      mg/L     51227
       0.13      mg/L     52669
       0.13      mg/L     54098
       0.13      mg/L     54099
       0.13      mg/L     55510
       0.13      mg/L     56925
       0.13      mg/L     56927
       0.13      mg/L     59701
       0.13      mg/L     59702
       0.13      mg/L     61090
       0.13      mg/L     62516
       0.13      mg/L     63902
       0.13      mg/L     65268
       0.13      mg/L     65269
       0.13      mg/L     69499
       0.13      mg/L     70956
       0.13      mg/L     78073
       0.13      mg/L     78075
       0.13      mg/L     79469
       0.13      mg/L     79470
       0.13      mg/L     80879
       0.13      mg/L     85027
       0.13      mg/L     86470
       0.13      mg/L     89244
       0.13      mg/L     91894
       0.13      mg/L     93311
       0.13      mg/L     99021
       0.13      mg/L     99022
       0.13      mg/L    103285
       0.13      mg/L    111805
       0.13      mg/L    113281
       0.13      mg/L    113282
       0.13      mg/L    117462
       0.13      mg/L    118833
       0.13      mg/L    120236
       0.13      mg/L    121702
       0.13      mg/L    124513
       0.13      mg/L    132788
       0.13      mg/L    134256
       0.13      mg/L    137081
       0.13      mg/L    137082
       0.13      mg/L    137083
       0.13      mg/L    138496
       0.13      mg/L    141331
       0.13      mg/L    141332
       0.13      mg/L    144179
       0.13      mg/L    147053
       0.13      mg/L    151245
       0.13      mg/L    151246
       0.13      mg/L    152762
       0.13      mg/L    152763
       0.13      mg/L    152764
       0.13      mg/L    156989
       0.13      mg/L    162661
       0.13      mg/L    162662
       0.13      mg/L    165490
       0.13      mg/L    168428
       0.13      mg/L    171221
       0.13      mg/L    172638
       0.13      mg/L    174066
       0.13      mg/L    175450
       0.13      mg/L    176898
       0.13      mg/L    176899
       0.13      mg/L    179742
       0.13      mg/L    179743
       0.13      mg/L    181115
       0.13      mg/L    182560
       0.13      mg/L    183983
       0.13      mg/L    183984
       0.13      mg/L    193946
       0.13      mg/L    195371
       0.13      mg/L    198230
       0.13      mg/L    198231
       0.13      mg/L    198232
       0.13      mg/L    202456
       0.13      mg/L    205385
       0.13      mg/L    206866
       0.13      mg/L    206867
       0.13      mg/L    208226
       0.13      mg/L    209561
       0.13      mg/L    210989
       0.13      mg/L    215179
       0.13      mg/L    219516
       0.13      mg/L    222366
       0.13      mg/L    223752
       0.13      mg/L    225187
       0.13      mg/L    225188
       0.13      mg/L    226601
       0.13      mg/L    230836
       0.13      mg/L    230837
       0.13      mg/L    230839
       0.13      mg/L    232189
       0.13      mg/L    232190
       0.13      mg/L    235021
       0.13      mg/L    236404
       0.13      mg/L    237803
       0.13      mg/L    239195
       0.13      mg/L    239196
       0.13      mg/L    242041
       0.13      mg/L    243488
       0.13      mg/L    244902
       0.13      mg/L    246259
       0.13      mg/L    249070
       0.13      mg/L    250487
       0.13      mg/L    251916
       0.13      mg/L    251917
       0.13      mg/L    256139
       0.13      mg/L    257544
       0.13      mg/L    258935
       0.13      mg/L    258939
       0.13      mg/L    260319
       0.13      mg/L    263205
       0.13      mg/L    267496
       0.13      mg/L    270350
       0.13      mg/L    270351
       0.13      mg/L    274556
       0.13      mg/L    275975
       0.13      mg/L    277382
       0.13      mg/L    278771
       0.13      mg/L    280173
       0.13      mg/L    283011
       0.13      mg/L    284384
       0.13      mg/L    285760
       0.13      mg/L    287140
       0.13      mg/L    287141
       0.13      mg/L    288509
       0.13      mg/L    288510
       0.13      mg/L    289902
       0.13      mg/L    292719
       0.13      mg/L    299813
       0.13      mg/L    299814
       0.13      mg/L    299815
       0.13      mg/L    306877
       0.13      mg/L    308238
       0.13      mg/L    309625
       0.13      mg/L    309626
       0.13      mg/L    311036
       0.13      mg/L    313892
       0.13      mg/L    315249
       0.13      mg/L    318021
       0.13      mg/L    322161
       0.13      mg/L    323623
       0.13      mg/L    323625
       0.13      mg/L    323626
       0.13      mg/L    323627
       0.13      mg/L    326390
       0.13      mg/L    329192
       0.13      mg/L    331928
       0.13      mg/L    333339
       0.13      mg/L    336220
       0.13      mg/L    343100
       0.13      mg/L    347317
       0.13      mg/L    351686
       0.13      mg/L    353115
       0.13      mg/L    353116
       0.13      mg/L    354530
       0.13      mg/L    358817
       0.13      mg/L    358818
       0.13      mg/L    358819
       0.13      mg/L    360246
       0.13      mg/L    360248
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
        0.1      mg/L      1716
        0.1      mg/L      3173
        0.1      mg/L      4624
        0.1      mg/L      4625
        0.1      mg/L      7463
        0.1      mg/L     10554
        0.1      mg/L     10557
        0.1      mg/L     11948
        0.1      mg/L     17192
        0.1      mg/L     17193
        0.1      mg/L     21312
        0.1      mg/L     21313
        0.1      mg/L     25948
        0.1      mg/L     27370
        0.1      mg/L     31595
        0.1      mg/L     32719
        0.1      mg/L     34148
        0.1      mg/L     34461
        0.1      mg/L     39911
        0.1      mg/L     41334
        0.1      mg/L     44559
        0.1      mg/L     48434
        0.1      mg/L     49865
        0.1      mg/L     50178
        0.1      mg/L     50179
        0.1      mg/L     55885
        0.1      mg/L     56986
        0.1      mg/L     62863
        0.1      mg/L     65633
        0.1      mg/L     69555
        0.1      mg/L     71316
        0.1      mg/L     72384
        0.1      mg/L     75520
        0.1      mg/L     78439
        0.1      mg/L     85402
        0.1      mg/L     86521
        0.1      mg/L     87884
        0.1      mg/L     99086
        0.1      mg/L    103345
        0.1      mg/L    104796
        0.1      mg/L    109343
        0.1      mg/L    110446
        0.1      mg/L    110447
        0.1      mg/L    111862
        0.1      mg/L    111863
        0.1      mg/L    113671
        0.1      mg/L    116152
        0.1      mg/L    117817
        0.1      mg/L    119212
        0.1      mg/L    124857
        0.1      mg/L    126214
        0.1      mg/L    128664
        0.1      mg/L    130082
        0.1      mg/L    130083
        0.1      mg/L    131753
        0.1      mg/L    136051
        0.1      mg/L    138552
        0.1      mg/L    141713
        0.1      mg/L    141714
        0.1      mg/L    143146
        0.1      mg/L    143149
        0.1      mg/L    145663
        0.1      mg/L    150236
        0.1      mg/L    158828
        0.1      mg/L    158831
        0.1      mg/L    158833
        0.1      mg/L    165540
        0.1      mg/L    165876
        0.1      mg/L    168786
        0.1      mg/L    175812
        0.1      mg/L    175813
        0.1      mg/L    177288
        0.1      mg/L    178389
        0.1      mg/L    178695
        0.1      mg/L    179798
        0.1      mg/L    181170
        0.1      mg/L    181171
        0.1      mg/L    182937
        0.1      mg/L    184043
        0.1      mg/L    185747
        0.1      mg/L    191148
        0.1      mg/L    191149
        0.1      mg/L    195440
        0.1      mg/L    196866
        0.1      mg/L    200003
        0.1      mg/L    202514
        0.1      mg/L    202515
        0.1      mg/L    205755
        0.1      mg/L    205756
        0.1      mg/L    207207
        0.1      mg/L    208274
        0.1      mg/L    209615
        0.1      mg/L    209939
        0.1      mg/L    211039
        0.1      mg/L    211040
        0.1      mg/L    215541
        0.1      mg/L    216678
        0.1      mg/L    216679
        0.1      mg/L    216999
        0.1      mg/L    223818
        0.1      mg/L    225247
        0.1      mg/L    225579
        0.1      mg/L    228352
        0.1      mg/L    229831
        0.1      mg/L    236458
        0.1      mg/L    240993
        0.1      mg/L    243881
        0.1      mg/L    245278
        0.1      mg/L    250535
        0.1      mg/L    259278
        0.1      mg/L    266121
        0.1      mg/L    270421
        0.1      mg/L    271834
        0.1      mg/L    276359
        0.1      mg/L    284441
        0.1      mg/L    288553
        0.1      mg/L    294182
        0.1      mg/L    297035
        0.1      mg/L    300181
        0.1      mg/L    303029
        0.1      mg/L    304393
        0.1      mg/L    311404
        0.1      mg/L    313959
        0.1      mg/L    315303
        0.1      mg/L    315612
        0.1      mg/L    316691
        0.1      mg/L    316692
        0.1      mg/L    316987
        0.1      mg/L    318398
        0.1      mg/L    318399
        0.1      mg/L    319778
        0.1      mg/L    321141
        0.1      mg/L    322210
        0.1      mg/L    322538
        0.1      mg/L    323685
        0.1      mg/L    324031
        0.1      mg/L    326741
        0.1      mg/L    330907
        0.1      mg/L    334843
        0.1      mg/L    335158
        0.1      mg/L    351738
        0.1      mg/L    356016
        0.1      mg/L    360298
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
         10      mg/L      3144
         10      mg/L      3573
         10      mg/L      4257
         10      mg/L     11076
         10      mg/L     11123
         10      mg/L     14554
         10      mg/L     16882
         10      mg/L     18774
         10      mg/L     19214
         10      mg/L     26542
         10      mg/L     27577
         10      mg/L     31034
         10      mg/L     32987
         10      mg/L     41012
         10      mg/L     45771
         10      mg/L     47511
         10      mg/L     49079
         10      mg/L     50445
         10      mg/L     56667
         10      mg/L     58394
         10      mg/L     60130
         10      mg/L     60145
         10      mg/L     61072
         10      mg/L     64424
         10      mg/L     66937
         10      mg/L     69222
         10      mg/L     70938
         10      mg/L     82189
         10      mg/L     85857
         10      mg/L     85864
         10      mg/L     92447
         10      mg/L     92619
         10      mg/L     95184
         10      mg/L     95719
         10      mg/L     99908
         10      mg/L    107186
         10      mg/L    107402
         10      mg/L    113381
         10      mg/L    113409
         10      mg/L    113877
         10      mg/L    119070
         10      mg/L    123149
         10      mg/L    124839
         10      mg/L    127971
         10      mg/L    132231
         10      mg/L    133340
         10      mg/L    135796
         10      mg/L    144479
         10      mg/L    149860
         10      mg/L    150185
         10      mg/L    151227
         10      mg/L    151401
         10      mg/L    152052
         10      mg/L    152887
         10      mg/L    155202
         10      mg/L    155510
         10      mg/L    157811
         10      mg/L    157966
         10      mg/L    161112
         10      mg/L    164110
         10      mg/L    166498
         10      mg/L    169846
         10      mg/L    170613
         10      mg/L    172050
         10      mg/L    173038
         10      mg/L    176613
         10      mg/L    179268
         10      mg/L    183803
         10      mg/L    186058
         10      mg/L    186755
         10      mg/L    188880
         10      mg/L    189905
         10      mg/L    197793
         10      mg/L    202616
         10      mg/L    203514
         10      mg/L    206166
         10      mg/L    207362
         10      mg/L    214473
         10      mg/L    216796
         10      mg/L    217555
         10      mg/L    218024
         10      mg/L    221560
         10      mg/L    223903
         10      mg/L    224437
         10      mg/L    226254
         10      mg/L    228127
         10      mg/L    230990
         10      mg/L    236061
         10      mg/L    241635
         10      mg/L    242920
         10      mg/L    244955
         10      mg/L    245102
         10      mg/L    245788
         10      mg/L    254433
         10      mg/L    259486
         10      mg/L    261917
         10      mg/L    263700
         10      mg/L    263934
         10      mg/L    266180
         10      mg/L    267874
         10      mg/L    267961
         10      mg/L    270103
         10      mg/L    273061
         10      mg/L    276635
         10      mg/L    277118
         10      mg/L    280644
         10      mg/L    284578
         10      mg/L    288845
         10      mg/L    289245
         10      mg/L    289282
         10      mg/L    289532
         10      mg/L    291660
         10      mg/L    292140
         10      mg/L    292696
         10      mg/L    296170
         10      mg/L    297053
         10      mg/L    300158
         10      mg/L    302451
         10      mg/L    303908
         10      mg/L    305826
         10      mg/L    307741
         10      mg/L    308424
         10      mg/L    309261
         10      mg/L    311656
         10      mg/L    313199
         10      mg/L    317132
         10      mg/L    317706
         10      mg/L    320040
         10      mg/L    321503
         10      mg/L    322007
         10      mg/L    323708
         10      mg/L    325663
         10      mg/L    333662
         10      mg/L    333988
         10      mg/L    334025
         10      mg/L    335348
         10      mg/L    345081
         10      mg/L    346149
         10      mg/L    350162
         10      mg/L    353553
         10      mg/L    354143
         10      mg/L    356581
         10      mg/L    356851
         10      mg/L    357890
         10      mg/L    358028
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
     0.0095      mg/L      2794
     0.0095      mg/L      5664
     0.0095      mg/L      9835
     0.0095      mg/L     15471
     0.0095      mg/L     18177
     0.0095      mg/L     19552
     0.0095      mg/L     25904
     0.0095      mg/L     27330
     0.0095      mg/L     28109
     0.0095      mg/L     30863
     0.0095      mg/L     33735
     0.0095      mg/L     35853
     0.0095      mg/L     37223
     0.0095      mg/L     37986
     0.0095      mg/L     46602
     0.0095      mg/L     47237
     0.0095      mg/L     50904
     0.0095      mg/L     62156
     0.0095      mg/L     63579
     0.0095      mg/L     64898
     0.0095      mg/L     72008
     0.0095      mg/L     73403
     0.0095      mg/L     73404
     0.0095      mg/L     77700
     0.0095      mg/L     77702
     0.0095      mg/L     80551
     0.0095      mg/L     83274
     0.0095      mg/L     84690
     0.0095      mg/L     86793
     0.0095      mg/L     86794
     0.0095      mg/L     88899
     0.0095      mg/L     92203
     0.0095      mg/L     92934
     0.0095      mg/L     95876
     0.0095      mg/L     97211
     0.0095      mg/L    100771
     0.0095      mg/L    104381
     0.0095      mg/L    106493
     0.0095      mg/L    107204
     0.0095      mg/L    113634
     0.0095      mg/L    114358
     0.0095      mg/L    115009
     0.0095      mg/L    116412
     0.0095      mg/L    117771
     0.0095      mg/L    119887
     0.0095      mg/L    123447
     0.0095      mg/L    125564
     0.0095      mg/L    125565
     0.0095      mg/L    125566
     0.0095      mg/L    131049
     0.0095      mg/L    132427
     0.0095      mg/L    133107
     0.0095      mg/L    133895
     0.0095      mg/L    138852
     0.0095      mg/L    139615
     0.0095      mg/L    139616
     0.0095      mg/L    143108
     0.0095      mg/L    150198
     0.0095      mg/L    168065
     0.0095      mg/L    168066
     0.0095      mg/L    168750
     0.0095      mg/L    170139
     0.0095      mg/L    170879
     0.0095      mg/L    172302
     0.0095      mg/L    174373
     0.0095      mg/L    177245
     0.0095      mg/L    182220
     0.0095      mg/L    185019
     0.0095      mg/L    186439
     0.0095      mg/L    192181
     0.0095      mg/L    205708
     0.0095      mg/L    209231
     0.0095      mg/L    211318
     0.0095      mg/L    212061
     0.0095      mg/L    214084
     0.0095      mg/L    214841
     0.0095      mg/L    222674
     0.0095      mg/L    224858
     0.0095      mg/L    226287
     0.0095      mg/L    231847
     0.0095      mg/L    231848
     0.0095      mg/L    233939
     0.0095      mg/L    236045
     0.0095      mg/L    241667
     0.0095      mg/L    241668
     0.0095      mg/L    243130
     0.0095      mg/L    249385
     0.0095      mg/L    251554
     0.0095      mg/L    251555
     0.0095      mg/L    255822
     0.0095      mg/L    258604
     0.0095      mg/L    259238
     0.0095      mg/L    262850
     0.0095      mg/L    264286
     0.0095      mg/L    270003
     0.0095      mg/L    271423
     0.0095      mg/L    279831
     0.0095      mg/L    281901
     0.0095      mg/L    286791
     0.0095      mg/L    288824
     0.0095      mg/L    293034
     0.0095      mg/L    293799
     0.0095      mg/L    296638
     0.0095      mg/L    298649
     0.0095      mg/L    300885
     0.0095      mg/L    308561
     0.0095      mg/L    314915
     0.0095      mg/L    316323
     0.0095      mg/L    319111
     0.0095      mg/L    323274
     0.0095      mg/L    323977
     0.0095      mg/L    327472
     0.0095      mg/L    334427
     0.0095      mg/L    340079
     0.0095      mg/L    346268
     0.0095      mg/L    348465
     0.0095      mg/L    349916
     0.0095      mg/L    360545
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
       1.75      mg/L      1192
       1.75      mg/L      1193
       1.75      mg/L      4058
       1.75      mg/L      8326
       1.75      mg/L      9694
       1.75      mg/L     11107
       1.75      mg/L     20807
       1.75      mg/L     29391
       1.75      mg/L     35043
       1.75      mg/L     36412
       1.75      mg/L     37859
       1.75      mg/L     39337
       1.75      mg/L     40803
       1.75      mg/L     43709
       1.75      mg/L     47890
       1.75      mg/L     55035
       1.75      mg/L     55036
       1.75      mg/L     57900
       1.75      mg/L     60631
       1.75      mg/L     73245
       1.75      mg/L     84557
       1.75      mg/L     87367
       1.75      mg/L     92799
       1.75      mg/L     99980
       1.75      mg/L     99981
       1.75      mg/L    105681
       1.75      mg/L    109910
       1.75      mg/L    109911
       1.75      mg/L    114218
       1.75      mg/L    115636
       1.75      mg/L    115638
       1.75      mg/L    122640
       1.75      mg/L    124040
       1.75      mg/L    124043
       1.75      mg/L    125428
       1.75      mg/L    129551
       1.75      mg/L    140897
       1.75      mg/L    140898
       1.75      mg/L    145149
       1.75      mg/L    149410
       1.75      mg/L    155104
       1.75      mg/L    167909
       1.75      mg/L    174979
       1.75      mg/L    176422
       1.75      mg/L    176423
       1.75      mg/L    177828
       1.75      mg/L    177830
       1.75      mg/L    187715
       1.75      mg/L    187720
       1.75      mg/L    193467
       1.75      mg/L    203429
       1.75      mg/L    204883
       1.75      mg/L    204884
       1.75      mg/L    209121
       1.75      mg/L    210510
       1.75      mg/L    211930
       1.75      mg/L    218995
       1.75      mg/L    224728
       1.75      mg/L    230387
       1.75      mg/L    234547
       1.75      mg/L    238729
       1.75      mg/L    238730
       1.75      mg/L    240135
       1.75      mg/L    242993
       1.75      mg/L    261290
       1.75      mg/L    267015
       1.75      mg/L    268371
       1.75      mg/L    268372
       1.75      mg/L    268376
       1.75      mg/L    274087
       1.75      mg/L    274088
       1.75      mg/L    275505
       1.75      mg/L    275514
       1.75      mg/L    278313
       1.75      mg/L    278314
       1.75      mg/L    282544
       1.75      mg/L    285316
       1.75      mg/L    290828
       1.75      mg/L    296504
       1.75      mg/L    297888
       1.75      mg/L    300749
       1.75      mg/L    303596
       1.75      mg/L    304939
       1.75      mg/L    307724
       1.75      mg/L    311974
       1.75      mg/L    314788
       1.75      mg/L    317558
       1.75      mg/L    321714
       1.75      mg/L    324582
       1.75      mg/L    325920
       1.75      mg/L    335734
       1.75      mg/L    335745
       1.75      mg/L    337174
       1.75      mg/L    344092
       1.75      mg/L    346824
       1.75      mg/L    348321
       1.75      mg/L    348322
       1.75      mg/L    351196
       1.75      mg/L    352642
       1.75      mg/L    355476
       1.75      mg/L    356901
       1.75      mg/L    358316
       1.75      mg/L    359755
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

**J-DEVIATION resolved (Stage 4c Part 3):** in the prior run of this report, `effect_category` was removed from the cross-source key by explicit user decision taken mid-session, because it was not yet a shared vocabulary across sources -- wqbench retained its own literal English-word vocabulary (`effect_category = effect`), while anztox and envirotox used MORT/GRO/REP-style codes, and including it produced *zero* cross-source candidate groups anywhere in the file. `data-raw/alldata/scripts/stage4c-effect-category-fixup.R` has since harmonised wqbench's English words and anztox's free-text tail onto the shared codes (unmappable values set to NA rather than guessed), so `effect_category` is restored to the key for this run:

`native_cas x scientificname_norm x medium x statistic_type_norm x effect_category x duration_hours x conc_ug_L (0.1% relative tolerance)`

### NA exclusions from cross-source dedup (Decision J2b)

| source | n_excluded_cs_na |
|---|---|
| anztox | 17 |
| envirotox | 4831 |
| wqbench | 21936 |

### Source-pair breakdown (exact + tolerance matches)

| dropped source | preferred (retained) source | match_type | n_rows |
|---|---|---|---|
| anztox | wqbench | exact | 6605 |
| anztox | wqbench | tolerance | 376 |
| envirotox | wqbench | exact | 390 |
| envirotox | wqbench | tolerance | 26 |

- Exact-pass rows flagged (Step 5e): 6995
- Tolerance-pass rows flagged (Step 5f): 402
- Total cross-source duplicate rows flagged (dedup_retained = FALSE): 7397

### Match counts at alternative tolerance thresholds (diagnostic only)

| threshold | n_rows_flagged |
|---|---|
| 0.000% | 6995 |
| 0.100% | 7397 |
| 1.000% | 7504 |
| 5.000% | 7762 |

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
1 FALSE          61068
2 TRUE          380633
3 NA              7397
```

By source (retained rows only):
```
# A tibble: 6 × 3
  source    priority_kept      n
  <chr>     <lgl>          <int>
1 anztox    FALSE            934
2 anztox    TRUE            7476
3 envirotox FALSE          11178
4 envirotox TRUE           60794
5 wqbench   FALSE          48956
6 wqbench   TRUE          312363
```

### Rows displaced by priority selection (priority_kept == FALSE), by source and displaced test_class

```
# A tibble: 4 × 3
  source    test_class     n
  <chr>     <chr>      <int>
1 anztox    acute        933
2 anztox    subchronic     1
3 envirotox acute      11178
4 wqbench   acute      48956
```

Sanity check (6d) passed: every `(native_cas, scientificname_norm, medium, effect_category)` group with `priority_kept == TRUE` rows is internally single-`test_class`.

---

## 5. Final retention summary

### "Final clean" subset (dedup_retained AND priority_kept), by source

```
# A tibble: 3 × 2
  source         n
  <chr>      <int>
1 anztox      7476
2 envirotox  60794
3 wqbench   312363
```

Total final-clean rows: 380633
Distinct `casnumber_grouped` values in the final clean subset: 5952

### dedup_retained == FALSE, by source and match_type

```
# A tibble: 4 × 3
  source    match_type     n
  <chr>     <chr>      <int>
1 anztox    exact       6605
2 anztox    tolerance    376
3 envirotox exact        390
4 envirotox tolerance     26
```

### within_source_duplicate == TRUE, by source

```
# A tibble: 3 × 2
  source        n
  <chr>     <int>
1 anztox     1427
2 envirotox   405
3 wqbench   90770
```

---

## 6. Anomalies and findings requiring human attention

1. **RESOLVED (Stage 4c Part 3) -- `effect_category` is now a shared cross-source vocabulary.** `data-raw/alldata/scripts/stage4c-effect-category-fixup.R` mapped wqbench's literal English-word field (`Mortality`, `Growth`, ...) onto the MORT/GRO/REP-style codes already used by anztox and envirotox, using an explicit lookup table; values with no table entry (`Intoxication`, `Multiple`, `General`, `Accumulation`, plus `Unspecified`/`Immunological`/`Injury`/`Ecosystem process`, not anticipated by the original mapping table) were set to NA rather than guessed. `effect_category` is restored to both the cross-source key (Phase 2, this run) and was already in the Phase 3 priority-selection key -- cross-source priority comparisons against wqbench now group correctly with anztox/envirotox records of the same endpoint. See `data-raw/alldata/uncurated_raw_combined.csv`'s `effect_category` column and the fixup script's header for the full mapping.

2. **RESOLVED (Stage 4c Part 3) -- anztox free-text fallback values mapped or explicitly excluded.** 240 anztox rows previously carried raw free-text or non-standard codes (e.g. "Disc area", "Dry mass", "PGR", "Cumulative eggs layed/female") instead of the controlled MORT/GRO/REP-style codes. A first-pass keyword classifier (`data-raw/alldata/scripts/stage4c-effect-category-fixup.R` Step 1c) mapped 65 of these to a controlled code; the remaining 175 (dominated by "PGR", 147 rows) could not be classified by keyword and were set to NA -- they are excluded from cross-source dedup and priority selection rather than guessed. Full audit trail with proposed mappings: `data-raw/alldata/anztox_2016_effect_category_map.csv`. Recommended follow-up: human review of the 175 NA rows ("PGR" in particular) before Stage 4d, since the same field is used there for aggregation grouping.

3. **Checked (Stage 4c Part 3) -- envirotox `MOR` vs `MORT` confirmed correct, no change needed.** `data-raw/alldata/scripts/stage4c-effect-category-fixup.R` Step 1d cross-checked every `MOR`- and `MORT`-mapped raw `Effect` value in `envirotox_effect_category_map.csv` for misassignment (e.g. a mortality-worded value mapped to `MOR`, or a morphology-worded value mapped to `MORT`). None were found: `MOR` (4 rows) covers genuine morphology endpoints ("Morphology, Shell deposition"; "Regeneration..."), and `MORT` (52,432 rows) covers genuine mortality/survival endpoints. The two codes correctly distinguish distinct underlying categories and were left as-is.

