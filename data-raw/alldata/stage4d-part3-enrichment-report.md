# Stage 4d Part 3 -- Taxonomy Enrichment Report

Generated: 2026-07-10 22:05:46 AWST

## 1. Input summary

- `uncurated_raw_dedup.csv`: 449,098 rows x 21 columns
- `species_resolution_v2.csv`: 4348 species (4,348 unique scientificnames from the final clean subset)

`taxonomy_provenance` distribution across all 4,348 species:

| taxonomy_provenance    | n_species |
| ----------------------|--------- |
| worms_full             | 3230      |
| gbif_full              |  972      |
| ambiguous_partial      |   84      |
| source_native_fallback |   49      |
| no_taxonomy            |   12      |
| manual_genus_fallback  |    1      |

## 2. Synonym unification result

- Total rows with `synonym_unified == TRUE`: 46,757

Top 20 synonym groups by row count (unified):

| accepted_name (unified)               | n_rows |
| -------------------------------------|------ |
| Gobiocyproides rarus                  | 2045   |
| Auxenochlorella pyrenoidosa           | 1824   |
| Scenedesmus acutus acutus             | 1381   |
| Magallana gigas                       | 1141   |
| Dolichospermum flos-aquae             | 1082   |
| Trigonostigma heteromorpha            | 1028   |
| Kryptolebias marmoratus               |  799   |
| Penaeus (Litopenaeus) vannamei        |  746   |
| Labeo catla                           |  720   |
| Asellus (Asellus) aquaticus aquaticus |  553   |
| Acartia (Acanthacartia) tonsa         |  552   |
| Synedra minutissima var. pelliculosa  |  546   |
| Penaeus (Penaeus) monodon             |  528   |
| Leuciscus idus                        |  526   |
| Penaeus (Farfantepenaeus) duorarum    |  498   |
| Daphnia (Ctenodaphnia) carinata       |  448   |
| Nitocra spinipes spinipes             |  410   |
| Radix rufescens                       |  407   |
| Metacarcinus magister                 |  398   |
| Palaemon kadiakensis                  |  393   |

Spot-check -- top 5 accepted names vs `species_synonym_audit.csv`:

| accepted_name             | n_raw_names | raw_names                               |
| -------------------------|-----------|--------------------------------------- |
| Dolichospermum flos-aquae | 2           | Anabaena flos-aquae; Anabaena flosaquae |

## 3. Taxonomic hierarchy join result


Coverage by field (full enriched dataset, 
449,073
 rows):

| field       | n_non_na | n_na | pct_coverage |
| -----------|--------|----|------------ |
| kingdom     | 449068   |    5 | 100%         |
| phylum      | 449068   |    5 | 100%         |
| class       | 444909   | 4164 | 99.07%       |
| order_taxon | 443675   | 5398 | 98.8%        |
| family      | 448990   |   83 | 99.98%       |
| genus       | 448548   |  525 | 99.88%       |

## 4. Majorgroup distribution


Distinct `majorgroup` (= `class`) values in the enriched file, all rows:

| majorgroup           | n_rows |
| --------------------|------ |
| Teleostei            | 213730 |
| Branchiopoda         |  54370 |
| Malacostraca         |  32738 |
| Insecta              |  21963 |
| Chlorophyceae        |  19844 |
| Bivalvia             |  17856 |
| Amphibia             |  14732 |
| Magnoliopsida        |  11364 |
| Gastropoda           |   8343 |
| Cyanophyceae         |   6372 |
| Bacillariophyceae    |   5787 |
| Trebouxiophyceae     |   5456 |
| Eurotatoria          |   5169 |
| Copepoda             |   4659 |
| Clitellata           |   2618 |
| Oligohymenophorea    |   2526 |
| Liliopsida           |   1872 |
| Echinoidea           |   1775 |
| Polychaeta           |   1573 |
| Chondrostei          |   1223 |
| Phaeophyceae         |    998 |
| Hydrozoa             |    944 |
| Hexacorallia         |    776 |
| Dinophyceae          |    727 |
| Coccolithophyceae    |    561 |
| Ulvophyceae          |    557 |
| Ostracoda            |    439 |
| Petromyzonti         |    410 |
| Florideophyceae      |    377 |
| Chromadorea          |    328 |
| Thecostraca          |    315 |
| Euglenophyceae       |    264 |
| Actinopterygii       |    262 |
| Heterotrichea        |    258 |
| Polypodiopsida       |    238 |
| Cryptophyceae        |    230 |
| Chlorodendrophyceae  |    214 |
| Eustigmatophyceae    |    209 |
| Zygnematophyceae     |    195 |
| Trematoda            |    178 |
| Spirotrichea         |    166 |
| Gymnolaemata         |    152 |
| Monogenea            |    137 |
| Ascidiacea           |    120 |
| Charophyceae         |    116 |
| Arachnida            |    106 |
| Cephalopoda          |    105 |
| Fragilariophyceae    |     90 |
| Elasmobranchii       |     89 |
| Demospongiae         |     84 |
| Asteroidea           |     78 |
| Pavlovophyceae       |     73 |
| Chrysophyceae        |     65 |
| Discosea             |     61 |
| Bangiophyceae        |     60 |
| Leptocardii          |     60 |
| Colpodea             |     56 |
| Raphidophyceae       |     55 |
| Maxillopoda          |     53 |
| Perkinsea            |     46 |
| Crinoidea            |     41 |
| Zoomastigophora      |     36 |
| Nephroselmidophyceae |     34 |
| Cyanobacteriia       |     31 |
| Phylactolaemata      |     31 |
| Scyphozoa            |     31 |
| Merostomata          |     30 |
| Pyramimonadophyceae  |     29 |
| Enoplea              |     28 |
| Prasinophyceae       |     28 |
| Ophiuroidea          |     27 |
| Prostomatea          |     26 |
| Secernentea          |     26 |
| Kinetoplastea        |     24 |
| Holostei             |     20 |
| Phyllopharyngea      |     19 |
| Pelagophyceae        |     17 |
| Polyplacophora       |     17 |
| Sagittoidea          |     17 |
| Coscinodiscophyceae  |     15 |
| Porphyridiophyceae   |     13 |
| Anthozoa             |     12 |
| Oligochaeta          |     12 |
| Ichthyostraca        |     11 |
| Holothuroidea        |     10 |
| Monogononta          |      9 |
| Conjugatophyceae     |      8 |
| Nassophorea          |      8 |
| Tentaculata          |      7 |
| Microsporea          |      6 |
| Oligotrichea         |      6 |
| Gymnostomatea        |      5 |
| Mamiellophyceae      |      5 |
| Ciliatea             |      4 |
| Not stated           |      4 |
| Prymnesiophyceae     |      4 |
| Clostridia           |      3 |
| Entosiphonea         |      3 |
| Turbellaria          |      3 |
| Appendicularia       |      2 |
| Bacili               |      2 |
| Coleochaetophyceae   |      2 |
| Conoidasida          |      2 |
| Dictyosteliomycetes  |      2 |
| Entognatha           |      2 |
| Gammaproteobacteria  |      2 |
| Kinetofragminophora  |      2 |
| Litostomatea         |      2 |
| Peranemea            |      2 |
| Saccharomycetes      |      2 |
| Aves                 |      1 |
| Collembola           |      1 |
| Karyorelictea        |      1 |
| Klebsormidiophyceae  |      1 |
| Lobosa               |      1 |

## 5. Hard exclusions

- 11 no_taxonomy species excluded, 25 rows removed from the enriched file.


Excluded species (all from anztox -- placeholder labels and 
unresolvable misspellings):

| scientificname    | n_rows |
| -----------------|------ |
| -                 | 4      |
| Chlorophycota     | 4      |
| Cyanophycota      | 4      |
| Cpannonicus       | 3      |
| Algae             | 2      |
| Invertebrates     | 2      |
| Triogoma sp.      | 2      |
| Ensimulium sp.    | 1      |
| Lebistes gibbosus | 1      |
| Oxcillatoria spp. | 1      |
| Periphyton        | 1      |

These match the `no_taxonomy` residual from the manual-corrections 
fixup report (`stage4d-part2-manual-corrections-report.md`): 12 species 
after the 3 manual corrections reduced the original 15-species list.


## 6. Final clean subset summary

Filter: `dedup_retained == TRUE & priority_kept == TRUE`

- Total rows: 380,608
- Distinct species (`accepted_name`): 4,039

Per-source breakdown:

| source    | n_rows |
| ---------|------ |
| wqbench   | 312363 |
| envirotox |  60794 |
| anztox    |   7451 |

Top 20 majorgroup values in the final clean subset:

| majorgroup        | n_rows |
| -----------------|------ |
| Teleostei         | 173205 |
| Branchiopoda      |  43938 |
| Malacostraca      |  28284 |
| Insecta           |  20063 |
| Chlorophyceae     |  17225 |
| Bivalvia          |  15822 |
| Amphibia          |  13550 |
| Magnoliopsida     |  10308 |
| Gastropoda        |   7633 |
| Cyanophyceae      |   6011 |
| Bacillariophyceae |   5663 |
| Trebouxiophyceae  |   5083 |
| Eurotatoria       |   4734 |
| Copepoda          |   4129 |
| Clitellata        |   2544 |
| Oligohymenophorea |   2466 |
| Echinoidea        |   1719 |
| Liliopsida        |   1706 |
| Polychaeta        |   1289 |
| Phaeophyceae      |    951 |

Taxonomy provenance in the final clean subset by source:

| source    | taxonomy_provenance    | n_rows |
| ---------|----------------------|------ |
| anztox    | worms_full             |   6840 |
| anztox    | gbif_full              |    495 |
| anztox    | ambiguous_partial      |     97 |
| anztox    | source_native_fallback |     18 |
| anztox    | manual_genus_fallback  |      1 |
| envirotox | worms_full             |  57801 |
| envirotox | gbif_full              |   2523 |
| envirotox | ambiguous_partial      |    305 |
| envirotox | source_native_fallback |    165 |
| wqbench   | worms_full             | 286013 |
| wqbench   | gbif_full              |  24013 |
| wqbench   | ambiguous_partial      |   1746 |
| wqbench   | source_native_fallback |    591 |

## 7. Readiness for Stage 4e

- Stage 4e reads: `data-raw/alldata/uncurated_raw_dedup_enriched.csv` (449,073 rows x 33 cols, 227.4 MB)
- Aggregation grouping key for Stage 4e (Section 3.4.4, Warne et al. 2025):
  `casnumber_grouped x accepted_name x medium x effect_category x
   statistic_type x duration_hours x life_stage (where non-NA)`

Known data quality issues for Stage 4e planning:

- Rows with NA `statistic_type` (final clean subset): 0
- Rows with NA `effect_category` (final clean subset): 23,264
- Rows with NA `duration_hours` (final clean subset): 85
- Rows with NA in any aggregation key field will be excluded from the 
  geomean step or result in singleton groups -- Stage 4e should decide 
  how to handle these (drop vs. retain as-is).
- `conc_unit` is mg/L for wqbench rows and ug/L for anztox/envirotox. 
  The wqbench mg/L -> ug/L conversion (x1000) is applied in Stage 4e 
  before aggregation.
- Acute records with `acr_eligible == FALSE` (NOECs, LOECs etc.) will be 
  dropped at Stage 4e -- they cannot be ACR-converted per Warne et al. 
  2025 Section 3.4.2.2.
- 46,757 rows had `scientificname` replaced by `accepted_name` via synonym unification. Stage 4e MUST aggregate on `accepted_name`, not the original `scientificname` column.
