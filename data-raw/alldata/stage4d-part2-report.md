# Stage 4d Part 2 -- Context-Aware Resolution Report

Generated: 2026-06-25 14:01:34 AWST

## 1. Input summary

- Pool table size: 4,348 species

Pooling decisions (taxonomy_source distribution):

| taxonomy_source | n_species |
|---|---|
| anztox | 223 |
| envirotox | 320 |
| wqbench | 3805 |

Non-NA pooled-field counts (of 4348 species):

| field | n_nonNA |
|---|---|
| kingdom | 4162 |
| phylum | 4162 |
| class | 4160 |
| order_taxon | 4112 |
| family | 4114 |
| genus | 3805 |

- 'Genus sp.' placeholders: 753
- Non-binomial (excl. placeholders): 194

## 2. Resolution status overview

`no_match_after_filter` is a transient pre-GBIF state (Step 4e always
resolves it onward to either `gbif_resolved` or `unresolved`/`api_error`)
and is included below for completeness against the spec's status list --
it is never a final value in `species_resolution_v2.csv`.

### Part 2 (this script)

| status | n_species | n_rows |
|---|---|---|
| exact_filtered | 1857 | 305491 |
| exact_unaccepted_filtered | 758 | 35609 |
| fuzzy_filtered | 18 | 991 |
| ambiguous_after_filter | 84 | 2152 |
| genus_resolved | 594 | 9266 |
| gbif_resolved | 973 | 27094 |
| no_match_after_filter | 0 | 0 |
| unresolved | 64 | 807 |
| api_error | 0 | 0 |

### Part 1 (for comparison)

| part1_status | n_species | n_rows |
|---|---|---|
| WoRMS exact | 1191 | 166676 |
| WoRMS exact (unaccepted, has synonym) | 472 | 20893 |
| WoRMS fuzzy | 52 | 1281 |
| WoRMS ambiguous | 1079 | 156131 |
| GBIF exact (WoRMS fallback) | 725 | 23683 |
| GBIF fuzzy (WoRMS fallback) | 716 | 10668 |
| Unresolved (both failed) | 113 | 2078 |
| API errors | 0 | 0 |

## 3. Synonym summary

- Total `accepted_name` groups in the dataset: 3907
- Synonym groups (>1 raw name collapsing to the same accepted_name): 254
- Total rows affected by synonym unification: 130,124

Top 20 synonym groups by row count:

| accepted_name | n_raw_names_in_group | total_rows |
|---|---|---|
| Danio rerio | 2 | 24127 |
| Oncorhynchus mykiss | 2 | 20194 |
| Cyprinus carpio | 4 | 8408 |
| Raphidocelis subcapitata | 3 | 8078 |
| Oryzias latipes | 2 | 6571 |
| Ceriodaphnia dubia | 2 | 4410 |
| Poecilia reticulata | 2 | 3176 |
| Americamysis bahia | 2 | 3036 |
| Oreochromis niloticus | 2 | 2973 |
| Oreochromis mossambicus | 3 | 2398 |
| Gambusia affinis | 3 | 2342 |
| Channa punctata | 3 | 1788 |
| Heteropneustes fossilis | 2 | 1728 |
| Desmodesmus subspicatus | 2 | 1638 |
| Clarias gariepinus | 2 | 1438 |
| Oryzias melastigma | 2 | 1410 |
| Palaemon pugio | 2 | 1390 |
| Salmo trutta | 2 | 1371 |
| Morone saxatilis | 2 | 1354 |
| Tubifex tubifex | 2 | 1186 |

## 4. Hierarchy disagreement summary

- Total species with a kingdom/phylum-level disagreement: 597
  - Cross-source disagreement (sources disagree among themselves): 40
  - Resolved-vs-source-native disagreement: 583
  - Of which anztox-sourced with class = NA (flagged separately, see Section 7 note): 0

Breakdown by which source supplied the pooled taxonomy:

| taxonomy_source | n_species |
|---|---|
| anztox | 4 |
| envirotox | 34 |
| wqbench | 559 |

Sample 20 disagreements:

| scientificname | sources | n_rows | status | source_kingdom | source_phylum | resolved_kingdom | resolved_phylum | taxonomy_source |
|---|---|---|---|---|---|---|---|---|
| Lemna gibba | anztox,wqbench | 2356 | exact_filtered | Plantae | Magnoliophyta | Plantae | Tracheophyta | wqbench |
| Lemna minor | anztox,wqbench | 2098 | exact_filtered | Plantae | Magnoliophyta | Plantae | Tracheophyta | wqbench |
| Microcystis aeruginosa | anztox,envirotox,wqbench | 1879 | exact_filtered | Monera | Cyanophycota | Bacteria | Cyanobacteria | wqbench |
| Skeletonema costatum | anztox,envirotox,wqbench | 1516 | exact_filtered | Chromista | Bacillariophyta | Chromista | Heterokontophyta | wqbench |
| Tetrahymena pyriformis | anztox,envirotox,wqbench | 1191 | exact_filtered | Animalia | Ciliophora | Chromista | Ciliophora | wqbench |
| Myriophyllum spicatum | anztox,wqbench | 1072 | exact_filtered | Plantae | Magnoliophyta | Plantae | Tracheophyta | wqbench |
| Myriophyllum sibiricum | wqbench | 1063 | exact_filtered | Plantae | Magnoliophyta | Plantae | Tracheophyta | wqbench |
| Tetrahymena thermophila | envirotox,wqbench | 769 | gbif_resolved | Animalia | Ciliophora | Chromista | Ciliophora | wqbench |
| Ceratophyllum demersum | anztox,wqbench | 697 | exact_filtered | Plantae | Magnoliophyta | Plantae | Tracheophyta | wqbench |
| Anabaena flosaquae | anztox,wqbench | 607 | fuzzy_filtered | Monera | Cyanophycota | Bacteria | Cyanobacteria | wqbench |
| Hydrilla verticillata | wqbench | 591 | exact_filtered | Plantae | Magnoliophyta | Plantae | Tracheophyta | wqbench |
| Fistulifera pelliculosa | wqbench | 545 | exact_unaccepted_filtered | Chromista | Bacillariophyta | Chromista | Heterokontophyta | wqbench |
| Phaeodactylum tricornutum | anztox,envirotox,wqbench | 523 | exact_unaccepted_filtered | Chromista | Bacillariophyta | Chromista | Heterokontophyta | wqbench |
| Isochrysis galbana | anztox,envirotox,wqbench | 462 | exact_filtered | Chromista | Haptophyta | Chromista | Haptophyta | wqbench |
| Thalassiosira pseudonana | anztox,envirotox,wqbench | 424 | exact_unaccepted_filtered | Chromista | Bacillariophyta | Chromista | Heterokontophyta | wqbench |
| Anabaena flos-aquae | anztox,envirotox | 330 | exact_unaccepted_filtered | Monera | Cyanophycota | Bacteria | Cyanobacteria | envirotox |
| Myriophyllum aquaticum | anztox,wqbench | 327 | gbif_resolved | Plantae | Magnoliophyta | Plantae | Tracheophyta | wqbench |
| Vallisneria natans | wqbench | 318 | gbif_resolved | Plantae | Magnoliophyta | Plantae | Tracheophyta | wqbench |
| Macrocystis pyrifera | anztox,envirotox,wqbench | 315 | exact_filtered | Chromista | Phaeophyta | Chromista | Ochrophyta | wqbench |
| Nostoc muscorum | envirotox,wqbench | 308 | exact_unaccepted_filtered | Monera | Cyanophycota | Bacteria | Cyanobacteria | wqbench |

## 5. Coverage of Part 1's problematic categories

### Part 1's 1079 ambiguous species

| status | n_species |
|---|---|
| exact_filtered | 666 |
| exact_unaccepted_filtered | 286 |
| ambiguous_after_filter | 84 |
| genus_resolved | 43 |

### Part 1's 113 genuinely unresolved species

| status | n_species |
|---|---|
| genus_resolved | 61 |
| unresolved | 52 |

## 6. Genus-placeholder handling

- Placeholders: 753
- Resolved at genus level (`genus_resolved`): 594
- Placeholders with no resolvable genus (fell through to general cascade): 159

Outcome breakdown for placeholders that fell through:

| status | n_species |
|---|---|
| gbif_resolved | 131 |
| unresolved | 25 |
| ambiguous_after_filter | 3 |

## 7. Recommendations for Stage 4d Part 3

- **'Resolved enough to use' threshold:** recommend `status %in% c("exact_filtered", "exact_unaccepted_filtered", "fuzzy_filtered", "genus_resolved", "gbif_resolved")` as the usable set -- 4200 species (378,451 rows, 99.22% of final clean rows) meet this bar.
- **Remaining problem species:** 148 species (2,959 rows) are `ambiguous_after_filter`, `unresolved`, or `api_error`. Small enough for a manual review queue in Part 3 -- triage by row count, hard-excluding the long low-row-count tail if time-constrained.
- **Class-level majorgroup feasibility:** 4127 of 4348 species (94.9%) have a non-NA `resolved_class`. This is consistent with Part 1's finding that class-level coverage is workable for majorgroup derivation; Part 3 should fall back to resolved_phylum (or source_taxonomy_class for placeholders/ambiguous species with only source-native context) for the remaining gap.

