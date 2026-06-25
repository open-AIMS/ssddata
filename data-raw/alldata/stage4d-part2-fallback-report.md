# Stage 4d Part 2 Fixup -- U3 Source-Native Taxonomy Fallback Report

Generated: 2026-06-25 14:24:06 AWST

## 1. Problem species summary

- Total problem species (status %in% c("ambiguous_after_filter", "unresolved", "api_error")): 148 species, 2,959 rows

By status:

| status | n_species | n_rows |
|---|---|---|
| ambiguous_after_filter | 84 | 2152 |
| unresolved | 64 | 807 |

## 2. Fallback results

- Of the 148 problem species, 130 had at least one hierarchy field recovered from source-native taxonomy.

`taxonomy_provenance` distribution (all 4,348 species):

| taxonomy_provenance | n_species |
|---|---|
| worms_full | 3227 |
| gbif_full | 973 |
| ambiguous_partial | 84 |
| source_native_fallback | 49 |
| no_taxonomy | 15 |

`taxonomy_provenance` distribution restricted to the 148 problem species:

| taxonomy_provenance | n_species |
|---|---|
| ambiguous_partial | 84 |
| source_native_fallback | 49 |
| no_taxonomy | 15 |

- Class-level coverage among the 148 problem species: 130 of 148 now have a non-NA `resolved_class` (was 0 of 148 before this fixup, since all problem species entered Part 2 with fully NA `resolved_*` fields).
- Dataset-wide class-level coverage: 4127 -> 4257 of 4,348 species (94.9% -> 97.9%).

**Note:** 1 `exact_unaccepted_filtered` row(s) (`Cryptomonas obovata`) have a NA `accepted_name` despite a fully WoRMS-derived `resolved_*` hierarchy (their `aphia_id` is populated) -- a pre-existing Part 2 data quirk, not introduced here. Classified `worms_full` on the structural signal that WoRMS-derived statuses always carry `aphia_id` (verified across all 4,348 rows), rather than gating on `accepted_name`, which would otherwise leave this row outside all five provenance categories.

## 3. The `no_taxonomy` residual

- 15 species (33 rows) have NO usable taxonomy from WoRMS, GBIF, OR source-native taxonomy. These are the hard-exclude candidates for Stage 4d Part 3, or a manual-review queue if time allows.

| scientificname | sources | n_rows | status |
|---|---|---|---|
| - | anztox | 4 | unresolved |
| Chlorophycota | anztox | 4 | unresolved |
| Cyanophycota | anztox | 4 | unresolved |
| Invertebrates | anztox | 4 | unresolved |
| Cpannonicus | anztox | 3 | unresolved |
| Algae | anztox | 2 | unresolved |
| Illybius augustior | anztox | 2 | unresolved |
| Salmoides micropterus | anztox | 2 | unresolved |
| Triogoma sp. | anztox | 2 | unresolved |
| Ensimulium sp. | anztox | 1 | unresolved |
| Lebistes gibbosus | anztox | 1 | unresolved |
| N. humilis | anztox | 1 | unresolved |
| Oxcillatoria spp. | anztox | 1 | unresolved |
| Periphyton | anztox | 1 | unresolved |
| Sialis flavilatera | anztox | 1 | unresolved |

## 4. Sample of 20 successful fallback cases (top 20 by n_rows, not a random sample -- deterministic so this report is stable across re-runs)

| scientificname | status | n_rows | source_taxonomy_kingdom | source_taxonomy_phylum | source_taxonomy_class | source_taxonomy_order | source_taxonomy_family | source_taxonomy_genus | resolved_kingdom | resolved_phylum | resolved_class | resolved_order | resolved_family | resolved_genus |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Scenedesmus quadricauda | ambiguous_after_filter | 787 | Plantae | Chlorophyta | Chlorophyceae | Chlorococcales | Scenedesmaceae | Scenedesmus | Plantae | Chlorophyta | Chlorophyceae | Chlorococcales | Scenedesmaceae | Scenedesmus |
| Ulva fasciata | ambiguous_after_filter | 194 | Plantae | Chlorophyta | Chlorophyceae | Ulotrichales | Ulvaceae | Ulva | Plantae | Chlorophyta | Chlorophyceae | Ulotrichales | Ulvaceae | Ulva |
| Chlorella fusca var vacuolata | unresolved | 123 | Plantae | Chlorophyta | Chlorophyceae | Chlorococcales | Oocystaceae | NA | Plantae | Chlorophyta | Chlorophyceae | Chlorococcales | Oocystaceae | NA |
| Morone saxatilis x chrysops | unresolved | 123 | Animalia | Chordata | Actinopterygii | Perciformes | Moronidae | Morone | Animalia | Chordata | Actinopterygii | Perciformes | Moronidae | Morone |
| Navicula pelliculosa | ambiguous_after_filter | 106 | Chromista | Bacillariophyta | Bacillariophyceae | Pennales | Naviculaceae | NA | Chromista | Bacillariophyta | Bacillariophyceae | Pennales | Naviculaceae | NA |
| Cancer irroratus | ambiguous_after_filter | 100 | Animalia | Arthropoda | Malacostraca | Decapoda | Cancridae | Cancer | Animalia | Arthropoda | Malacostraca | Decapoda | Cancridae | Cancer |
| Symbiodinium sp. | unresolved | 90 | Chromista | Pyrrophycophyta | Dinophyceae | Suessiales | Symbiodiniaceae | Symbiodinium | Chromista | Pyrrophycophyta | Dinophyceae | Suessiales | Symbiodiniaceae | Symbiodinium |
| Nitzschia closterium | ambiguous_after_filter | 88 | Chromista | Bacillariophyta | Bacillariophyceae | Pennales | Bacillariaceae | Nitzschia | Chromista | Bacillariophyta | Bacillariophyceae | Pennales | Bacillariaceae | Nitzschia |
| tribe Chironomini | unresolved | 88 | Animalia | Arthropoda | Insecta | Diptera | Chironomidae | Tribe chironomini | Animalia | Arthropoda | Insecta | Diptera | Chironomidae | Tribe chironomini |
| Zostera marina | ambiguous_after_filter | 64 | Plantae | Magnoliophyta | Liliopsida | Najadales | Zosteraceae | Zostera | Plantae | Magnoliophyta | Liliopsida | Najadales | Zosteraceae | Zostera |
| Chaetoceros gracilis | ambiguous_after_filter | 63 | Chromista | Bacillariophyta | Bacillariophyceae | Centrales | Chaetocerotaceae | Chaetoceros | Chromista | Bacillariophyta | Bacillariophyceae | Centrales | Chaetocerotaceae | Chaetoceros |
| Zostera muelleri | ambiguous_after_filter | 60 | Plantae | Magnoliophyta | Liliopsida | Najadales | Zosteraceae | Zostera | Plantae | Magnoliophyta | Liliopsida | Najadales | Zosteraceae | Zostera |
| Zostera capricorni | ambiguous_after_filter | 47 | Plantae | Magnoliophyta | Liliopsida | Najadales | Zosteraceae | Zostera | Plantae | Magnoliophyta | Liliopsida | Najadales | Zosteraceae | Zostera |
| Cyclops viridis | ambiguous_after_filter | 42 | Animalia | Arthropoda | Maxillopoda | Cyclopoida | Cyclopidae | Cyclops | Animalia | Arthropoda | Maxillopoda | Cyclopoida | Cyclopidae | Cyclops |
| Diatoma sp. | unresolved | 42 | Chromista | Bacillariophyta | Fragilariophyceae | Fragilariales | Fragilariaceae | Diatoma | Chromista | Bacillariophyta | Fragilariophyceae | Fragilariales | Fragilariaceae | Diatoma |
| Chlamydomonas oblonga | ambiguous_after_filter | 37 | Plantae | Chlorophyta | Chlorophyceae | Volvocales | Chlamydomonadaceae | Chlamydomonas | Plantae | Chlorophyta | Chlorophyceae | Volvocales | Chlamydomonadaceae | Chlamydomonas |
| Ephemerella sp. | unresolved | 35 | Animalia | Arthropoda | Insecta | Ephemeroptera | Ephemerellidae | Ephemerella | Animalia | Arthropoda | Insecta | Ephemeroptera | Ephemerellidae | Ephemerella |
| Geophagus brasiliensis | ambiguous_after_filter | 35 | Animalia | Chordata | Actinopterygii | Perciformes | Cichlidae | Geophagus | Animalia | Chordata | Actinopterygii | Perciformes | Cichlidae | Geophagus |
| Tilapia guineensis | ambiguous_after_filter | 35 | Animalia | Chordata | Actinopterygii | Perciformes | Cichlidae | Tilapia | Animalia | Chordata | Actinopterygii | Perciformes | Cichlidae | Tilapia |
| Crithidia fasciculata | unresolved | 32 | Animalia | Sarcomastigophora | Zoomastigophora | Kinetoplastida | Trypanosomatidae | Crithidia | Animalia | Sarcomastigophora | Zoomastigophora | Kinetoplastida | Trypanosomatidae | Crithidia |

## 5. Recommendation for Stage 4d Part 3

- Dataset-wide class-level coverage after the U3 fallback is 97.9% (4257 of 4,348 species), meeting the 95% threshold suggested in the Part 2 report.
- Genuine residual: 15 species (33 rows, 0.01% of the final clean rows) have `taxonomy_provenance == "no_taxonomy"` -- no usable hierarchy from any source. Recommend Part 3 hard-excludes these from majorgroup derivation (and flags them for the SSD aggregation stage to drop, since a record with no taxonomic hierarchy cannot be assigned a majorgroup), or queues them for manual domain-expert review given the small size.
- The remaining 133 problem species now carry at least a partial hierarchy (84 `ambiguous_partial`, 49 `source_native_fallback`) and can be used in Part 3 with the `taxonomy_provenance` flag carried forward as a lower-confidence marker.

