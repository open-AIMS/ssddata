# Stage 4c Part 2 -- Cross-Source Duplicate Detection and ANZG Priority Selection
Date: 2026-06-24

**Revised (Stage 4c Part 3, session "stage4c-part3-effect-category-harmonisation"):** this run follows `data-raw/alldata/scripts/stage4c-effect-category-fixup.R`, which harmonised `effect_category` to a single controlled vocabulary across all three sources. `effect_category` is now included in the cross-source key (Phase 2) and produces correct cross-source comparisons in the ANZG priority-selection grouping (Phase 3) -- both previously limited by the vocabulary mismatch documented in the prior run of this report (see Section 3 and Section 6 below for the resolution).

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
| anztox | 15667 | 15535 | 132 | 635 | 1448 | 9.242% |
| wqbench | 361782 | 194973 | 166809 | 21197 | 90801 | 25.098% |
| envirotox | 72439 | 67549 | 4890 | 201 | 405 | 0.559% |

All sources are within the 50% within-source duplicate threshold -- pipeline proceeded to Phase 2.

### Rationale: why these rates are not a data-quality problem

The Phase 1 hard-stop threshold was downgraded from 1% to 50% (Option 1, `data-raw/alldata/scripts/stage4c-deferred-decisions.md`, resolved 2026-06-24). The rates observed this run -- anztox 9.242%, wqbench 25.098%, envirotox 0.559% -- are intrinsic to each source's underlying data granularity as captured by the common 17-column schema, not symptoms of a data-quality defect or a key-design bug. The specific cause differs by source:

- **anztox** (9.242%): legitimate multi-lab ring-test replication that the schema cannot surface -- e.g. a 1987 zebrafish ring test with ~10 participating labs reporting an identical NOEC result. Confirmed via `source_id`: every row in every sampled group has a distinct `source_id`, i.e. these are genuinely separate database records, not a single record duplicated by a join.
- **wqbench** (25.098%): a structural consequence of the wqbench package's own prepared-dataset output, not a choice made in this pipeline's intercept. `wqb_create_data_set()` discards fine-grained per-row identifiers (`test_id`, `result_id`) and specific gene/biomarker descriptors before producing the RDS this pipeline reads as its source. The most extreme example found: a single paper reporting zebrafish gene-expression results across ~180 distinct genes, all sharing the same NOEC, duration, life stage, and study reference, and all bucketed under the one coarse `effect_category` value `"Genetics"` -- there is no field anywhere in wqbench's contribution to the common schema that identifies which gene/biomarker was measured.
- **envirotox** (0.559%): well under threshold; the within-source key (including `study_reference`) is sufficient to distinguish envirotox's records.

The `within_source_duplicate` flag is preserved in the output for downstream use -- this is a diagnostic flag-and-retain stage, not a hard drop. Stage 4d's geometric-mean aggregation (Section 3.4.4, Warne et al. 2025) will correctly collapse these within-source duplicate rows to single species-level values, so the elevated rates do not propagate as an error into the final SSD dataset.

**Future enhancement (deferred, out of scope for this branch):** the wqbench SQLite database (`ecotox_ascii_*.sqlite`, shipped alongside the RDS) may retain per-row identifiers recoverable via a join on `species_number x cas x endpoint x effect_conc_mg.L`. This has not been investigated and is not required for the current branch -- bypassing the RDS intercept entirely (e.g. to re-run `wqb_create_data_set()` against a fresh EPA ECOTOX download) would mean wqbench is no longer being used as a source in the form this pipeline was designed around.

### Sample within-source duplicate groups (largest first, up to 5 per source)

**anztox** (5 sample group(s) shown):

```
 source native_cas scientificname_norm     medium statistic_type_norm effect_category duration_hours
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
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
 source native_cas scientificname_norm     medium statistic_type_norm effect_category duration_hours
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
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
 source native_cas scientificname_norm     medium statistic_type_norm effect_category duration_hours
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
 anztox    7778509   brachydanio rerio Freshwater                NOEC            MORT            384
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
 source native_cas   scientificname_norm medium statistic_type_norm effect_category duration_hours
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            336
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            336
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            336
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            336
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            336
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            336
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            336
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            336
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
 source native_cas   scientificname_norm medium statistic_type_norm effect_category duration_hours
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            504
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            504
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            504
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            504
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            504
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            504
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            504
 anztox      51285 cyprinodon variegatus Marine                NOEC            MORT            504
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
  source native_cas scientificname_norm     medium statistic_type_norm effect_category duration_hours life_stage
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
 wqbench   10102064         danio rerio Freshwater                NOEC             BCH            864      Adult
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
 [ reached 'max' / getOption("max.print") -- omitted 99 rows ]
```

```
  source native_cas scientificname_norm     medium statistic_type_norm effect_category duration_hours life_stage
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
 wqbench     375735         danio rerio Freshwater                NOEC             BCH            336      Adult
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
 [ reached 'max' / getOption("max.print") -- omitted 63 rows ]
```

```
  source native_cas scientificname_norm     medium statistic_type_norm effect_category duration_hours life_stage
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
 wqbench     335671   gobiocypris rarus Freshwater                LOEC             BCH            672      Adult
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
 [ reached 'max' / getOption("max.print") -- omitted 62 rows ]
```

```
  source native_cas scientificname_norm medium statistic_type_norm effect_category duration_hours life_stage
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
 wqbench     375735  oryzias melastigma Marine                NOEC             BCH            504      Adult
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
 [ reached 'max' / getOption("max.print") -- omitted 35 rows ]
```

```
  source native_cas scientificname_norm     medium statistic_type_norm effect_category duration_hours life_stage
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
 wqbench      84742     cyprinus carpio Freshwater                LOEC             BCH            840 Fingerling
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
 [ reached 'max' / getOption("max.print") -- omitted 20 rows ]
```

**envirotox** (5 sample group(s) shown):

```
    source native_cas scientificname_norm statistic_type_norm effect_category duration_hours
 envirotox  107534963     daphnia galeata                NOEC             REP            504
 envirotox  107534963     daphnia galeata                NOEC             REP            504
 envirotox  107534963     daphnia galeata                NOEC             REP            504
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
    source native_cas scientificname_norm statistic_type_norm effect_category duration_hours
 envirotox    7758987     daphnia galeata                NOEC             REP            504
 envirotox    7758987     daphnia galeata                NOEC             REP            504
 envirotox    7758987     daphnia galeata                NOEC             REP            504
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
    source native_cas scientificname_norm statistic_type_norm effect_category duration_hours
 envirotox      84742 oncorhynchus mykiss                NOEC             GRO           2376
 envirotox      84742 oncorhynchus mykiss                NOEC             GRO           2376
 envirotox      84742 oncorhynchus mykiss                NOEC             GRO           2376
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
    source native_cas scientificname_norm statistic_type_norm effect_category duration_hours
 envirotox   10025737       daphnia magna                NOEC             REP            504
 envirotox   10025737       daphnia magna                NOEC             REP            504
                                                                                                                                                                       study_reference
 Kuhn, R., M. Pattard, K.D. Pernak, and A. Winter, 1989. Results of the Harmful Effects of Water Pollutants to Daphnia magna in the 21 Day Reproduction Test, Water Res. 23(4):501-510
 Kuhn, R., M. Pattard, K.D. Pernak, and A. Winter, 1989. Results of the Harmful Effects of Water Pollutants to Daphnia magna in the 21 Day Reproduction Test, Water Res. 23(4):501-510
 conc_value conc_unit source_id
        700      ug/L     56520
        700      ug/L     56521
```

```
    source native_cas scientificname_norm statistic_type_norm effect_category duration_hours
 envirotox   10043353       daphnia magna                NOEC             REP            504
 envirotox   10043353       daphnia magna                NOEC             REP            504
                                                                                                                                       study_reference conc_value
 Lewis, M.A., and L.C. Valentine, 1981. Acute and Chronic Toxicities of Boric Acid to Daphnia magna Straus, Bull.Environ.Contam.Toxicol. 27(3):309-315       6000
 Lewis, M.A., and L.C. Valentine, 1981. Acute and Chronic Toxicities of Boric Acid to Daphnia magna Straus, Bull.Environ.Contam.Toxicol. 27(3):309-315       6000
 conc_unit source_id
      ug/L     56721
      ug/L     56722
```

---

## 3. Phase 2 -- cross-source duplicate detection

**J-DEVIATION resolved (Stage 4c Part 3):** in the prior run of this report, `effect_category` was removed from the cross-source key by explicit user decision taken mid-session, because it was not yet a shared vocabulary across sources -- wqbench retained its own literal English-word vocabulary (`effect_category = effect`), while anztox and envirotox used MORT/GRO/REP-style codes, and including it produced *zero* cross-source candidate groups anywhere in the file. `data-raw/alldata/scripts/stage4c-effect-category-fixup.R` has since harmonised wqbench's English words and anztox's free-text tail onto the shared codes (unmappable values set to NA rather than guessed), so `effect_category` is restored to the key for this run:

`native_cas x scientificname_norm x medium x statistic_type_norm x effect_category x duration_hours x conc_ug_L (0.1% relative tolerance)`

### NA exclusions from cross-source dedup (Decision J2b)

| source | n_excluded_cs_na |
|---|---|
| anztox | 132 |
| envirotox | 4890 |
| wqbench | 21971 |

### Source-pair breakdown (exact + tolerance matches)

| dropped source | preferred (retained) source | match_type | n_rows |
|---|---|---|---|
| anztox | wqbench | exact | 6605 |
| anztox | wqbench | tolerance | 376 |
| envirotox | wqbench | exact | 389 |
| envirotox | wqbench | tolerance | 26 |

- Exact-pass rows flagged (Step 5e): 6994
- Tolerance-pass rows flagged (Step 5f): 402
- Total cross-source duplicate rows flagged (dedup_retained = FALSE): 7396

### Match counts at alternative tolerance thresholds (diagnostic only)

| threshold | n_rows_flagged |
|---|---|
| 0.000% | 6994 |
| 0.100% | 7396 |
| 1.000% | 7503 |
| 5.000% | 7761 |

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
1 FALSE          61131
2 TRUE          381361
3 NA              7396
```

By source (retained rows only):
```
# A tibble: 6 × 3
  source    priority_kept      n
  <chr>     <lgl>          <int>
1 anztox    FALSE            966
2 anztox    TRUE            7720
3 envirotox FALSE          11187
4 envirotox TRUE           60837
5 wqbench   FALSE          48978
6 wqbench   TRUE          312804
```

### Rows displaced by priority selection (priority_kept == FALSE), by source and displaced test_class

```
# A tibble: 4 × 3
  source    test_class     n
  <chr>     <chr>      <int>
1 anztox    acute        965
2 anztox    subchronic     1
3 envirotox acute      11187
4 wqbench   acute      48978
```

Sanity check (6d) passed: every `(native_cas, scientificname_norm, medium, effect_category)` group with `priority_kept == TRUE` rows is internally single-`test_class`.

---

## 5. Final retention summary

### "Final clean" subset (dedup_retained AND priority_kept), by source

```
# A tibble: 3 × 2
  source         n
  <chr>      <int>
1 anztox      7720
2 envirotox  60837
3 wqbench   312804
```

Total final-clean rows: 381361
Distinct `casnumber_grouped` values in the final clean subset: 6003

### dedup_retained == FALSE, by source and match_type

```
# A tibble: 4 × 3
  source    match_type     n
  <chr>     <chr>      <int>
1 anztox    exact       6605
2 anztox    tolerance    376
3 envirotox exact        389
4 envirotox tolerance     26
```

### within_source_duplicate == TRUE, by source

```
# A tibble: 3 × 2
  source        n
  <chr>     <int>
1 anztox     1448
2 envirotox   405
3 wqbench   90801
```

---

## 6. Anomalies and findings requiring human attention

1. **RESOLVED (Stage 4c Part 3) -- `effect_category` is now a shared cross-source vocabulary.** `data-raw/alldata/scripts/stage4c-effect-category-fixup.R` mapped wqbench's literal English-word field (`Mortality`, `Growth`, ...) onto the MORT/GRO/REP-style codes already used by anztox and envirotox, using an explicit lookup table; values with no table entry (`Intoxication`, `Multiple`, `General`, `Accumulation`, plus `Unspecified`/`Immunological`/`Injury`/`Ecosystem process`, not anticipated by the original mapping table) were set to NA rather than guessed. `effect_category` is restored to both the cross-source key (Phase 2, this run) and was already in the Phase 3 priority-selection key -- cross-source priority comparisons against wqbench now group correctly with anztox/envirotox records of the same endpoint. See `data-raw/alldata/uncurated_raw_combined.csv`'s `effect_category` column and the fixup script's header for the full mapping.

2. **RESOLVED (Stage 4c Part 3) -- anztox free-text fallback values mapped or explicitly excluded.** 240 anztox rows previously carried raw free-text or non-standard codes (e.g. "Disc area", "Dry mass", "PGR", "Cumulative eggs layed/female") instead of the controlled MORT/GRO/REP-style codes. A first-pass keyword classifier (`data-raw/alldata/scripts/stage4c-effect-category-fixup.R` Step 1c) mapped 65 of these to a controlled code; the remaining 175 (dominated by "PGR", 147 rows) could not be classified by keyword and were set to NA -- they are excluded from cross-source dedup and priority selection rather than guessed. Full audit trail with proposed mappings: `data-raw/alldata/anztox_2016_effect_category_map.csv`. Recommended follow-up: human review of the 175 NA rows ("PGR" in particular) before Stage 4d, since the same field is used there for aggregation grouping.

3. **Checked (Stage 4c Part 3) -- envirotox `MOR` vs `MORT` confirmed correct, no change needed.** `data-raw/alldata/scripts/stage4c-effect-category-fixup.R` Step 1d cross-checked every `MOR`- and `MORT`-mapped raw `Effect` value in `envirotox_effect_category_map.csv` for misassignment (e.g. a mortality-worded value mapped to `MOR`, or a morphology-worded value mapped to `MORT`). None were found: `MOR` (4 rows) covers genuine morphology endpoints ("Morphology, Shell deposition"; "Regeneration..."), and `MORT` (52,432 rows) covers genuine mortality/survival endpoints. The two codes correctly distinguish distinct underlying categories and were left as-is.

