# Stage 4d Part 3 -- Taxonomy Enrichment Report

Generated: 2026-06-25 16:19:43 AWST

## 1. Input summary

- `uncurated_raw_dedup.csv`: 449,888 rows x 21 columns
- `species_resolution_v2.csv`: 4348 species (4,348 unique scientificnames from the final clean subset)

`taxonomy_provenance` distribution across all 4,348 species:

| taxonomy_provenance    | n_species |
| ----------------------|--------- |
| worms_full             | 3228      |
| gbif_full              |  974      |
| ambiguous_partial      |   84      |
| source_native_fallback |   49      |
| no_taxonomy            |   12      |
| manual_genus_fallback  |    1      |

## 2. Synonym unification result

- Total rows with `synonym_unified == TRUE`: 46,826

Top 20 synonym groups by row count (unified):

| accepted_name (unified)               | n_rows |
| -------------------------------------|------ |
| Gobiocyproides rarus                  | 2045   |
| Auxenochlorella pyrenoidosa           | 1824   |
| Scenedesmus acutus acutus             | 1381   |
| Magallana gigas                       | 1141   |
| Dolichospermum flos-aquae             | 1082   |
| Trigonostigma heteromorpha            | 1032   |
| Kryptolebias marmoratus               |  799   |
| Penaeus (Litopenaeus) vannamei        |  746   |
| Labeo catla                           |  720   |
| Asellus (Asellus) aquaticus aquaticus |  553   |
| Acartia (Acanthacartia) tonsa         |  552   |
| Synedra minutissima var. pelliculosa  |  546   |
| Penaeus (Penaeus) monodon             |  531   |
| Leuciscus idus                        |  526   |
| Penaeus (Farfantepenaeus) duorarum    |  499   |
| Daphnia (Ctenodaphnia) carinata       |  448   |
| Nitocra spinipes spinipes             |  410   |
| Radix rufescens                       |  407   |
| Metacarcinus magister                 |  398   |
| Palaemon kadiakensis                  |  397   |

Spot-check -- top 5 accepted names vs `species_synonym_audit.csv`:

| accepted_name             | n_raw_names | raw_names                               |
| -------------------------|-----------|--------------------------------------- |
| Dolichospermum flos-aquae | 2           | Anabaena flos-aquae; Anabaena flosaquae |

## 3. Taxonomic hierarchy join result


Coverage by field (full enriched dataset, 
449,860
 rows):

| field       | n_non_na | n_na | pct_coverage |
| -----------|--------|----|------------ |
| kingdom     | 449855   |    5 | 100%         |
| phylum      | 449855   |    5 | 100%         |
| class       | 445694   | 4166 | 99.07%       |
| order_taxon | 444448   | 5412 | 98.8%        |
| family      | 449777   |   83 | 99.98%       |
| genus       | 449334   |  526 | 99.88%       |

## 4. Majorgroup distribution


Distinct `majorgroup` (= `class`) values in the enriched file, all rows:

| majorgroup           | n_rows |
| --------------------|------ |
| Teleostei            | 214144 |
| Branchiopoda         |  54527 |
| Malacostraca         |  32796 |
| Insecta              |  21991 |
| Chlorophyceae        |  19883 |
| Bivalvia             |  17873 |
| Amphibia             |  14751 |
| Magnoliopsida        |  11365 |
| Gastropoda           |   8348 |
| Cyanophyceae         |   6375 |
| Bacillariophyceae    |   5793 |
| Trebouxiophyceae     |   5459 |
| Eurotatoria          |   5173 |
| Copepoda             |   4659 |
| Clitellata           |   2628 |
| Oligohymenophorea    |   2526 |
| Liliopsida           |   1872 |
| Echinoidea           |   1775 |
| Polychaeta           |   1587 |
| Chondrostei          |   1223 |
| Phaeophyceae         |    998 |
| Hydrozoa             |    945 |
| Hexacorallia         |    776 |
| Dinophyceae          |    727 |
| Coccolithophyceae    |    563 |
| Ulvophyceae          |    557 |
| Ostracoda            |    439 |
| Petromyzonti         |    410 |
| Florideophyceae      |    377 |
| Chromadorea          |    328 |
| Thecostraca          |    316 |
| Euglenophyceae       |    264 |
| Actinopterygii       |    262 |
| Heterotrichea        |    258 |
| Polypodiopsida       |    240 |
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
| Gammaproteobacteria  |      3 |
| Turbellaria          |      3 |
| Appendicularia       |      2 |
| Bacili               |      2 |
| Coleochaetophyceae   |      2 |
| Conoidasida          |      2 |
| Dictyosteliomycetes  |      2 |
| Entognatha           |      2 |
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

- 12 no_taxonomy species excluded, 28 rows removed from the enriched file.


Excluded species (all from anztox -- placeholder labels and 
unresolvable misspellings):

| scientificname    | n_rows |
| -----------------|------ |
| -                 | 4      |
| Chlorophycota     | 4      |
| Cyanophycota      | 4      |
| Invertebrates     | 4      |
| Cpannonicus       | 3      |
| Algae             | 2      |
| Triogoma sp.      | 2      |
| Ensimulium sp.    | 1      |
| Lebistes gibbosus | 1      |
| N. humilis        | 1      |
| Oxcillatoria spp. | 1      |
| Periphyton        | 1      |

These match the `no_taxonomy` residual from the manual-corrections 
fixup report (`stage4d-part2-manual-corrections-report.md`): 12 species 
after the 3 manual corrections reduced the original 15-species list.


## 6. Final clean subset summary

Filter: `dedup_retained == TRUE & priority_kept == TRUE`

- Total rows: 381,382
- Distinct species (`accepted_name`): 4,042

Per-source breakdown:

| source    | n_rows |
| ---------|------ |
| wqbench   | 312827 |
| envirotox |  60824 |
| anztox    |   7731 |

Top 20 majorgroup values in the final clean subset:

| majorgroup        | n_rows |
| -----------------|------ |
| Teleostei         | 173584 |
| Branchiopoda      |  44078 |
| Malacostraca      |  28332 |
| Insecta           |  20091 |
| Chlorophyceae     |  17261 |
| Bivalvia          |  15839 |
| Amphibia          |  13569 |
| Magnoliopsida     |  10309 |
| Gastropoda        |   7638 |
| Cyanophyceae      |   6014 |
| Bacillariophyceae |   5684 |
| Trebouxiophyceae  |   5091 |
| Eurotatoria       |   4742 |
| Copepoda          |   4129 |
| Clitellata        |   2554 |
| Oligohymenophorea |   2474 |
| Echinoidea        |   1719 |
| Liliopsida        |   1706 |
| Polychaeta        |   1303 |
| Phaeophyceae      |    951 |

Taxonomy provenance in the final clean subset by source:

| source    | taxonomy_provenance    | n_rows |
| ---------|----------------------|------ |
| anztox    | worms_full             |   7101 |
| anztox    | gbif_full              |    510 |
| anztox    | ambiguous_partial      |    101 |
| anztox    | source_native_fallback |     18 |
| anztox    | manual_genus_fallback  |      1 |
| envirotox | worms_full             |  57829 |
| envirotox | gbif_full              |   2525 |
| envirotox | ambiguous_partial      |    305 |
| envirotox | source_native_fallback |    165 |
| wqbench   | worms_full             | 286429 |
| wqbench   | gbif_full              |  24061 |
| wqbench   | ambiguous_partial      |   1746 |
| wqbench   | source_native_fallback |    591 |

## 7. Readiness for Stage 4e

- Stage 4e reads: `data-raw/alldata/uncurated_raw_dedup_enriched.csv` (449,860 rows x 33 cols, 227.9 MB)
- Aggregation grouping key for Stage 4e (Section 3.4.4, Warne et al. 2025):
  `casnumber_grouped x accepted_name x medium x effect_category x
   statistic_type x duration_hours x life_stage (where non-NA)`

Known data quality issues for Stage 4e planning:

- Rows with NA `statistic_type` (final clean subset): 0
- Rows with NA `effect_category` (final clean subset): 23,567
- Rows with NA `duration_hours` (final clean subset): 199
- Rows with NA in any aggregation key field will be excluded from the 
  geomean step or result in singleton groups -- Stage 4e should decide 
  how to handle these (drop vs. retain as-is).
- `conc_unit` is mg/L for wqbench rows and ug/L for anztox/envirotox. 
  The wqbench mg/L -> ug/L conversion (x1000) is applied in Stage 4e 
  before aggregation.
- Acute records with `acr_eligible == FALSE` (NOECs, LOECs etc.) will be 
  dropped at Stage 4e -- they cannot be ACR-converted per Warne et al. 
  2025 Section 3.4.2.2.
- 46,826 rows had `scientificname` replaced by `accepted_name` via synonym unification. Stage 4e MUST aggregate on `accepted_name`, not the original `scientificname` column.
