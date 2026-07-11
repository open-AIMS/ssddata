# Data dictionary — `allchronic_data_source.csv`

Row-level, uncurated, **pre-aggregation** provenance file for the `all_chronic` pipeline (uncurated sources only: anztox, wqbench, envirotox). One row in the aggregated `allchronic_data` object corresponds to many rows here — this file records the individual endpoint records that were rolled up under a parent CAS and a resolved species. The CAS-group columns (`native_chemicalname`, `casnumber_grouped`, `cas_group_rationale`) are LLM-assisted / heuristic wherever `cas_group_human_checked = n` and are pending expert review. The five anztox synthetic-placeholder CAS (`1`, `100000001`–`100000004`) and the NA-parent junk CAS carry a curated `exclusion_reason` in the master lookup and are dropped before extraction (Task B); they never appear in this file.

Columns: 49 total.

## Review-facing columns

| Column | Group | Description | Example value |
|---|---|---|---|
| `source` | identity | Originating uncurated database for the record (anztox, wqbench, or envirotox). | `anztox` |
| `native_cas` | identity | CAS number exactly as reported by the source, in its original format, before parent-CAS grouping. | `60515` |
| `native_chemicalname` | identity | Chemical name for native_cas from the master parent lookup; for the five synthetic-placeholder CAS (absent from the lookup) it is the explicit source-native anztox label. | `Dimethoate;O,O-Dimethyl S-[2-(methylamino)-2-oxoethyl] phosphorodithioate` |
| `casnumber_grouped` | identity | Parent CAS after rollup via the master lookup; equals native_cas where no simpler parent exists. | `60515` |
| `chemicalname_grouped` | identity | Harmonised parent chemical name for casnumber_grouped. | `Dimethoate;O,O-Dimethyl S-[2-(methylamino)-2-oxoethyl] phosphorodithioate` |
| `cas_group_rationale` | identity | Basis for the native-to-parent CAS mapping (lookup match_rationale); reviewers use this to judge each rollup. Placeholder CAS carry an explicit excluded-from-grouping note. | `direct — no simpler parent` |
| `cas_group_human_checked` | identity | Whether the CAS mapping was expert-reviewed: `n` = LLM-assisted/heuristic, not yet reviewed; `NA` = synthetic placeholder outside the lookup. | `n` |
| `scientificname` | taxonomy | Species name carried through the pipeline; identical to original_scientificname in this file. | `Daphnia magna` |
| `medium` | endpoint | Test medium: Freshwater, Marine, or Unknown. | `Freshwater` |
| `test_class` | endpoint | Exposure-duration classification carried from the source: chronic, subchronic, or acute. | `chronic` |
| `statistic_type` | endpoint | Toxicity statistic reported for the record (e.g. NOEC, NOEL, LOEC, MATC, EC50, LC50, IC50, EC10, NEC, NSEC). | `NOEC` |
| `effect_category` | endpoint | Harmonised effect category (controlled vocabulary): MORT, GRO, REP, IMM, DVP, HAT, POP, ABD. | `IMM` |
| `duration_hours` | endpoint | Test exposure duration in hours (NA where not reported). | `552` |
| `life_stage` | endpoint | Organism life stage at test; NA is a distinct level, not missing-at-random. | `4th instar larvae` |
| `conc_ug_L` | endpoint | Per-record toxicity concentration in µg/L, after unit normalisation and any ACR (÷10) or chronic (÷5/÷2.5/÷2) conversion applied to this record; divide back by acr_applied / chronic_conv_factor to recover the raw value. | `76` |
| `conc_unit` | endpoint | Original concentration unit, normalised to ug/L for every row (wqbench mg/L converted in Stage 4e). | `ug/L` |
| `study_reference` | provenance | Source citation / study reference for the record. | `Beusen, JM, Neven, B (1989). Toxicity of dimethoate to daphnia magna and fres...` |
| `original_scientificname` | taxonomy | Species name exactly as reported by the source (the native back-track key). | `Daphnia magna` |
| `accepted_name` | taxonomy | Resolved / accepted species name after WoRMS/GBIF resolution; the Stage 4e aggregation species key. | `Daphnia magna` |
| `synonym_unified` | taxonomy | TRUE if original_scientificname was a synonym unified to a different accepted_name. | `FALSE` |
| `kingdom` | taxonomy | Resolved kingdom. | `Animalia` |
| `phylum` | taxonomy | Resolved phylum. | `Arthropoda` |
| `class` | taxonomy | Resolved class; also the sufficiency grouping variable. | `Branchiopoda` |
| `order_taxon` | taxonomy | Resolved order (named order_taxon to avoid clashing with the reserved word order). | `Anomopoda` |
| `family` | taxonomy | Resolved family. | `Daphniidae` |
| `genus` | taxonomy | Resolved genus. | `Daphnia` |
| `majorgroup` | taxonomy | Major taxonomic group; equals the resolved class in this file. | `Branchiopoda` |
| `taxonomy_provenance` | taxonomy | Resolver route that produced the taxonomy: worms_full, gbif_full, ambiguous_partial, source_native_fallback, or manual_genus_fallback. | `worms_full` |
| `conc_plausibility` | endpoint | Concentration plausibility flag from the D6 filter: ok, low_soft, or high_soft (hard-implausible records are excluded upstream and never exported). | `ok` |
| `value_tier` | provenance | Three-tier hierarchy label for the record (uncurated only here): accepted > chronic_converted > acute_acr; NA for records dropped by the per-species tier-preference filter. | `accepted` |
| `final_conc_ug_L` | endpoint | Final aggregated published concentration (µg/L) for the record's casnumber_grouped × accepted_name × medium group; populated only on is_provenance rows, NA elsewhere. | `10000` |

## Pipeline-internal columns

| Column | Group | Description | Example value |
|---|---|---|---|
| `acr_eligible` | conversion | TRUE if statistic_type is ACR-eligible (acute EC50/IC50/LC50), i.e. permitted to undergo the acute-to-chronic ratio conversion. | `FALSE` |
| `source_id` | bookkeeping | Source-native record identifier as issued by the originating database. | `8705` |
| `acr_applied` | conversion | TRUE if the ACR ÷10 acute-to-chronic conversion was applied to conc_ug_L for this record. | `FALSE` |
| `within_source_duplicate` | dedup | Stage 4c flag: TRUE if the record was identified as a duplicate of another record within the same source. | `FALSE` |
| `dedup_retained` | dedup | Stage 4c flag: TRUE if the record was retained after within- and cross-source deduplication (all exported rows are TRUE). | `TRUE` |
| `priority_kept` | dedup | Stage 4c flag: TRUE if the record survived cross-source priority selection (chronic > subchronic > acute; all exported rows are TRUE). | `TRUE` |
| `dedup_note` | dedup | Stage 4c free-text note recording the deduplication decision for the record. | `excluded from cross-source dedup -- NA in key field(s)` |
| `resolution_status` | taxonomy | Stage 4d name-resolution outcome: exact_filtered, exact_unaccepted_filtered, fuzzy_filtered, ambiguous_after_filter, gbif_resolved, or unresolved. | `exact_filtered` |
| `stat_tier` | statistic | Warne et al. 2025 statistic tier for statistic_type (e.g. negligible_no_conversion, appropriate_no_conversion, less_pref_no_conversion, low_effect_conv_2.5, low_effect_conv_2, median_effect_conv_5). | `negligible_no_conversion` |
| `stat_action` | statistic | Coarse action derived from stat_tier: accepted (used as-is) or convert (chronic conversion). exclude-tier records are dropped before export. | `accepted` |
| `conv_factor` | conversion | Chronic-conversion divisor implied by stat_tier for convert-tier records (5, 2.5, or 2); NA otherwise. | `2.5` |
| `chronic_conv_applied` | conversion | TRUE if a chronic §3.4.2.1 conversion (÷5/÷2.5/÷2) was applied to conc_ug_L for this record. | `FALSE` |
| `chronic_conv_factor` | conversion | The chronic-conversion factor actually applied (conv_factor where chronic_conv_applied is TRUE); NA otherwise. | `2.5` |
| `record_uid` | bookkeeping | Unique within-file record identifier assigned to the post-filter base frame (row number). | `1` |
| `in_geomean_input` | provenance | TRUE if the record survived the three-tier preference filter and fed the geometric-mean aggregation input. | `TRUE` |
| `step1_group_id` | provenance | Identifier of the Stage 4e Step-1 aggregation group (cas × species × medium × effect_category × statistic_type × duration × life_stage) the record belongs to; NA for records not entering aggregation. | `5765` |
| `is_provenance` | provenance | TRUE if the record belongs to the winning Step-1 group whose value equals the final published concentration for its casnumber_grouped × accepted_name × medium. | `FALSE` |
| `provenance_tie` | provenance | TRUE if more than one Step-1 group tied at the minimum when selecting the published value for the group (provenance is ambiguous). | `FALSE` |

