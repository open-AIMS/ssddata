# Stage 4d Part 1.5 -- Source-Native Taxonomy Extraction Inventory

Generated: 2026-06-25 12:07:01 AWST

## 1. Input summary

- Final clean rows (`dedup_retained` & `priority_kept`): 381,410
- Distinct `(source, scientificname)` combinations: 6,198
- Distinct `scientificname` values overall (collapsed across sources): 4,348

Species in scope per source:

| source | n_species_in_scope |
|---|---|
| anztox | 804 |
| envirotox | 1589 |
| wqbench | 3805 |

Match rates against each source's own taxonomy table/sheet:

| source | n_in_scope | n_matched | pct_matched |
|---|---|---|---|
| anztox | 804 | 804 | 100 |
| wqbench | 3805 | 3805 | 100 |
| envirotox | 1589 | 1589 | 100 |

- anztox in-scope species with duplicate raw `species` rows (same `scientificname`): 23
- wqbench in-scope species with duplicate raw `species` rows (same `latin_name`): 3
- envirotox in-scope species with duplicate raw taxonomy-sheet rows (same `Latin name`): 0

anztox fields with genuine value conflicts across duplicate raw rows for the same species (first non-NA value was used in the output; conflicting alternatives were discarded):

| field | n_conflicting_species |
|---|---|
| animalcategory | 3 |
| animaltype | 1 |
| commonname | 16 |
| majorgroup | 16 |
| minorgroup | 12 |

## 2. Field availability per source

| field | n_nonNA_anztox | n_nonNA_wqbench | n_nonNA_envirotox | n_total_anztox | n_total_wqbench | n_total_envirotox | pct_nonNA_anztox | pct_nonNA_wqbench | pct_nonNA_envirotox |
|---|---|---|---|---|---|---|---|---|---|
| kingdom | 94 | 3805 | 1586 | 804 | 3805 | 1589 | 11.7 | 100 | 99.8 |
| phylum | 94 | 3805 | 1587 | 804 | 3805 | 1589 | 11.7 | 100 | 99.9 |
| subphylum | 0 | 2258 | 1082 | 804 | 3805 | 1589 | 0 | 59.3 | 68.1 |
| superclass | 0 | 704 | 442 | 804 | 3805 | 1589 | 0 | 18.5 | 27.8 |
| class | 94 | 3803 | 1587 | 804 | 3805 | 1589 | 11.7 | 99.9 | 99.9 |
| order_taxon | 0 | 3795 | 1584 | 804 | 3805 | 1589 | 0 | 99.7 | 99.7 |
| family | 0 | 3796 | 1586 | 804 | 3805 | 1589 | 0 | 99.8 | 99.8 |
| genus | 0 | 3805 | 0 | 804 | 3805 | 1589 | 0 | 100 | 0 |
| common_name | 704 | 3805 | 0 | 804 | 3805 | 1589 | 87.6 | 100 | 0 |
| source_majorgroup | 665 | 0 | 0 | 804 | 3805 | 1589 | 82.7 | 0 | 0 |
| source_minorgroup | 624 | 0 | 0 | 804 | 3805 | 1589 | 77.6 | 0 | 0 |
| source_trophic | 0 | 3805 | 1589 | 804 | 3805 | 1589 | 0 | 100 | 100 |
| source_ecological | 0 | 3805 | 0 | 804 | 3805 | 1589 | 0 | 100 | 0 |
| source_animaltype | 687 | 0 | 0 | 804 | 3805 | 1589 | 85.4 | 0 | 0 |
| source_animalcategory | 755 | 0 | 0 | 804 | 3805 | 1589 | 93.9 | 0 | 0 |
| isheterotroph | 86 | 0 | 0 | 804 | 3805 | 1589 | 10.7 | 0 | 0 |
| ncbi_taxid | 0 | 3040 | 0 | 804 | 3805 | 1589 | 0 | 79.9 | 0 |

## 3. Vocabulary distinct values per harmonised field

Distinct non-NA values across all three sources combined, with row counts (capped at top 40 per field; full set available by re-running the script's intermediate objects).

### `kingdom` (8 distinct values)

| kingdom | n_species |
|---|---|
| Animalia | 4494 |
| Plantae | 535 |
| Chromista | 291 |
| Monera | 143 |
| Bacteria | 16 |
| Eubacteria | 4 |
| Protista | 1 |
| Protoctista | 1 |

### `phylum` (41 distinct values)

| phylum | n_species |
|---|---|
| Arthropoda | 1899 |
| Chordata | 1391 |
| Mollusca | 596 |
| Chlorophyta | 303 |
| Bacillariophyta | 198 |
| Cyanophycota | 143 |
| Annelida | 121 |
| Rotifera | 119 |
| Magnoliophyta | 113 |
| Ciliophora | 101 |
| Cnidaria | 66 |
| Platyhelminthes | 66 |
| Echinodermata | 58 |
| Charophyta | 37 |
| Nematoda | 32 |
| Pyrrophycophyta | 29 |
| Phaeophyta | 25 |
| Chrysophyta | 20 |
| Cyanobacteria | 20 |
| Cryptophycophyta | 19 |
| Rhodophycota | 19 |
| Bryozoa | 14 |
| Ochrophyta | 14 |
| Haptophyta | 12 |
| Tracheophyta | 11 |
| Protozoa | 10 |
| Polypodiophyta | 8 |
| Prasinophyta | 8 |
| Euglenophycota | 7 |
| Chaetognatha | 4 |
| Ctenophora | 4 |
| Ectoprocta | 3 |
| Nemata | 3 |
| Porifera | 3 |
| Rhodophyta | 3 |
| Sarcomastigophora | 2 |
| Apicomplexa | 1 |
| Dinoflagellata | 1 |
| Gastrotricha | 1 |
| Myzozoa | 1 |

### `subphylum` (17 distinct values)

| subphylum | n_species |
|---|---|
| Vertebrata | 1347 |
| Crustacea | 1013 |
| Hexapoda | 830 |
| Echinozoa | 42 |
| Chelicerata | 34 |
| Polychaeta | 25 |
| Eleutherozoa | 15 |
| Tunicata | 13 |
| Sarcodina | 6 |
| Khakista | 3 |
| Animalia | 2 |
| Chlorophytina | 2 |
| Mastigophora | 2 |
| Medusozoa | 2 |
| Mycetozoa | 2 |
| Crinozoa | 1 |
| Pyrrhophyta | 1 |

### `superclass` (4 distinct values)

| superclass | n_species |
|---|---|
| Osteichthyes | 1133 |
| Agnatha | 6 |
| Rhizopoda | 6 |
| Acanthophractida | 1 |

### `class` (91 distinct values)

| class | n_species |
|---|---|
| Actinopterygii | 1156 |
| Insecta | 832 |
| Malacostraca | 599 |
| Bivalvia | 309 |
| Chlorophyceae | 276 |
| Gastropoda | 273 |
| Branchiopoda | 207 |
| Amphibia | 205 |
| Maxillopoda | 189 |
| Cyanophyceae | 163 |
| Bacillariophyceae | 131 |
| Monogononta | 104 |
| Ciliatea | 93 |
| Liliopsida | 68 |
| Magnoliopsida | 56 |
| Oligochaeta | 48 |
| Anthozoa | 44 |
| Coscinodiscophyceae | 41 |
| Echinoidea | 39 |
| Trematoda | 36 |
| Arachnida | 33 |
| Ostracoda | 32 |
| Turbellaria | 30 |
| Clitellata | 28 |
| Dinophyceae | 28 |
| Fragilariophyceae | 27 |
| Phaeophyceae | 26 |
| Conjugatophyceae | 24 |
| Secernentea | 23 |
| Errantia | 22 |
| Chrysophyceae | 20 |
| Hydrozoa | 20 |
| Polychaeta | 20 |
| Cryptophyceae | 19 |
| Rhodophyceae | 15 |
| Charophyceae | 13 |
| Adenophorea | 12 |
| Ascidiacea | 12 |
| Prymnesiophyceae | 12 |
| Asteroidea | 9 |

### `order_taxon` (300 distinct values)

| order_taxon | n_species |
|---|---|
| Decapoda | 352 |
| Perciformes | 321 |
| Cypriniformes | 296 |
| Diptera | 279 |
| Anura | 175 |
| Amphipoda | 154 |
| Ephemeroptera | 148 |
| Chlorococcales | 147 |
| Diplostraca | 139 |
| Unionoida | 114 |
| Trichoptera | 112 |
| Veneroida | 102 |
| Ploima | 101 |
| Basommatophora | 99 |
| Nostocales | 97 |
| Siluriformes | 86 |
| Calanoida | 84 |
| Plecoptera | 83 |
| Cyprinodontiformes | 77 |
| Salmoniformes | 74 |
| Neotaenioglossa | 66 |
| Coleoptera | 63 |
| Odonata | 62 |
| Heteroptera | 57 |
| Isopoda | 53 |
| Pennales | 53 |
| Haplotaxida | 49 |
| Volvocales | 49 |
| Cyclopoida | 45 |
| Ostreoida | 42 |
| Chroococcales | 41 |
| Characiformes | 40 |
| Atheriniformes | 39 |
| Hymenostomatida | 39 |
| Harpacticoida | 37 |
| Pleuronectiformes | 37 |
| Scleractinia | 35 |
| Anostraca | 34 |
| Mytiloida | 33 |
| Aciculata | 32 |

### `family` (812 distinct values)

| family | n_species |
|---|---|
| Cyprinidae | 263 |
| Culicidae | 117 |
| Unionidae | 102 |
| Chironomidae | 100 |
| Daphniidae | 79 |
| Salmonidae | 73 |
| Oocystaceae | 65 |
| Gammaridae | 63 |
| Palaemonidae | 60 |
| Cichlidae | 54 |
| Nostocaceae | 53 |
| Ranidae | 50 |
| Scenedesmaceae | 50 |
| Penaeidae | 48 |
| Cyclopidae | 43 |
| Brachionidae | 41 |
| Chroococcaceae | 41 |
| Chydoridae | 39 |
| Hylidae | 39 |
| Heptageniidae | 38 |
| Hydropsychidae | 38 |
| Cambaridae | 37 |
| Planorbidae | 37 |
| Bufonidae | 35 |
| Mytilidae | 33 |
| Poeciliidae | 33 |
| Asellidae | 32 |
| Mysidae | 32 |
| Cyprinodontidae | 31 |
| Centrarchidae | 30 |
| Percidae | 30 |
| Characidae | 29 |
| Chlamydomonadaceae | 29 |
| Dytiscidae | 29 |
| Oscillatoriaceae | 29 |
| Diaptomidae | 28 |
| Naviculaceae | 28 |
| Physidae | 28 |
| Sparidae | 28 |
| Bacillariaceae | 27 |

### `genus` (1803 distinct values)

| genus | n_species |
|---|---|
| Aedes | 26 |
| Gammarus | 25 |
| Chironomus | 24 |
| Daphnia | 24 |
| Culex | 23 |
| Scenedesmus | 23 |
| Anopheles | 19 |
| Macrobrachium | 19 |
| Oncorhynchus | 19 |
| Anabaena | 17 |
| Chlorella | 17 |
| Nitzschia | 17 |
| Barbus | 16 |
| Bufo | 15 |
| Chlamydomonas | 15 |
| Rana | 15 |
| Lithobates | 14 |
| Penaeus | 14 |
| Brachionus | 13 |
| Crassostrea | 13 |
| Hydropsyche | 13 |
| Navicula | 13 |
| Tetrahymena | 13 |
| Haliotis | 12 |
| Palaemon | 12 |
| Procambarus | 12 |
| Simulium | 12 |
| Acartia | 11 |
| Ambystoma | 11 |
| Ceriodaphnia | 11 |
| Lecane | 11 |
| Tilapia | 11 |
| Acipenser | 10 |
| Lampsilis | 10 |
| Notropis | 10 |
| Stenonema | 10 |
| Acropora | 9 |
| Lemna | 9 |
| Moina | 9 |
| Myriophyllum | 9 |

## 4. Cross-source consistency

- Species present in only one source: 2840 (trivially consistent)
- Species present in more than one source: 1508

| field | n_multi_source_species | n_agreeing | n_disagreeing | n_one_or_more_NA |
|---|---|---|---|---|
| kingdom | 1508 | 967 | 14 | 527 |
| phylum | 1508 | 950 | 32 | 526 |
| class | 1508 | 954 | 28 | 526 |
| order_taxon | 1508 | 888 | 37 | 583 |
| family | 1508 | 890 | 34 | 584 |

Sample of species where `class`, `order_taxon`, or `family` disagree across sources (up to 20 species shown):

| scientificname | source | kingdom | phylum | class | order_taxon | family |
|---|---|---|---|---|---|---|
| Bithynia tentaculata | anztox | NA | NA | NA | NA | NA |
| Bithynia tentaculata | envirotox | Animalia | Mollusca | Gastropoda | Littorinimorpha | Bithyniidae |
| Bithynia tentaculata | wqbench | Animalia | Mollusca | Gastropoda | Neotaenioglossa | Bithyniidae |
| Capitella capitata | anztox | NA | NA | NA | NA | NA |
| Capitella capitata | envirotox | Animalia | Annelida | Polychaeta | Canalipalpata | Capitellidae |
| Capitella capitata | wqbench | Animalia | Annelida | Sedentaria | Scolecida | Capitellidae |
| Ceramium tenuicorne | anztox | Plantae | Rhodophyta | Florideophyceae | NA | NA |
| Ceramium tenuicorne | wqbench | Plantae | Rhodophycota | Rhodophyceae | Ceramiales | Ceramiaceae |
| Chaetoceros gracilis | anztox | Chromista | Bacillariophyta | Mediophyceae | NA | NA |
| Chaetoceros gracilis | wqbench | Chromista | Bacillariophyta | Bacillariophyceae | Centrales | Chaetocerotaceae |
| Chlorococcum sp. | anztox | Bacteria | Cyanobacteria | Cyanophyceae | NA | NA |
| Chlorococcum sp. | wqbench | Plantae | Chlorophyta | Chlorophyceae | Chlorococcales | Chlorococcaceae |
| Dinophilus gyrociliatus | anztox | NA | NA | NA | NA | NA |
| Dinophilus gyrociliatus | envirotox | Animalia | Annelida | Polychaeta | Aciculata | Dorvilleidae |
| Dinophilus gyrociliatus | wqbench | Animalia | Annelida | Errantia | Aciculata | Dorvilleidae |
| Eurythoe complanata | anztox | NA | NA | NA | NA | NA |
| Eurythoe complanata | envirotox | Animalia | Annelida | Polychaeta | Aciculata | Amphinomidae |
| Eurythoe complanata | wqbench | Animalia | Annelida | Errantia | Aciculata | Amphinomidae |
| Glyceria maxima | anztox | Plantae | Tracheophyta | Liliopsida | NA | NA |
| Glyceria maxima | wqbench | Plantae | Magnoliophyta | Magnoliopsida | Poales | Poaceae |
| Gracilaria tenuistipitata | anztox | Plantae | Rhodophyta | Florideophyceae | NA | NA |
| Gracilaria tenuistipitata | wqbench | Plantae | Rhodophycota | Rhodophyceae | Gigartinales | Gracilariaceae |
| Grandidierella japonica | anztox | NA | NA | NA | NA | NA |
| Grandidierella japonica | envirotox | Animalia | Arthropoda | Malacostraca | Amphipoda | Corophiidae |
| Grandidierella japonica | wqbench | Animalia | Arthropoda | Malacostraca | Amphipoda | Aoridae |
| Hormosira banksii | anztox | NA | NA | NA | NA | NA |
| Hormosira banksii | envirotox | Chromista | Ochrophyta | Phaeophycaea | Fucales | Hormosiraceae |
| Hormosira banksii | wqbench | Chromista | Phaeophyta | Phaeophyceae | Fucales | Hormosiraceae |
| Limnodrilus hoffmeisteri | anztox | NA | NA | NA | NA | NA |
| Limnodrilus hoffmeisteri | envirotox | Animalia | Annelida | Oligochaeta | Haplotaxida | Tubificidae |
| Limnodrilus hoffmeisteri | wqbench | Animalia | Annelida | Oligochaeta | Haplotaxida | Naididae |
| Nephroselmis pyriformis | anztox | Plantae | Chlorophyta | Nephrophyceae | NA | NA |
| Nephroselmis pyriformis | wqbench | Plantae | Prasinophyta | Prasinophyceae | Pyramimonadales | Polyblepharidaceae |
| Nereis diversicolor | anztox | NA | NA | NA | NA | NA |
| Nereis diversicolor | envirotox | Animalia | Annelida | Polychaeta | Aciculata | Nereididae |
| Nereis diversicolor | wqbench | Animalia | Annelida | Errantia | Aciculata | Nereididae |
| Nereis virens | anztox | NA | NA | NA | NA | NA |
| Nereis virens | envirotox | Animalia | Annelida | Polychaeta | Aciculata | Nereididae |
| Nereis virens | wqbench | Animalia | Annelida | Errantia | Aciculata | Nereididae |
| Noemacheilus barbatulus | anztox | NA | NA | NA | NA | NA |
| Noemacheilus barbatulus | envirotox | Animalia | Chordata | Actinopterygii | Perciformes | Gobiidae |
| Noemacheilus barbatulus | wqbench | Animalia | Chordata | Actinopterygii | Cypriniformes | Balitoridae |
| Ophryotrocha diadema | anztox | NA | NA | NA | NA | NA |
| Ophryotrocha diadema | envirotox | Animalia | Annelida | Polychaeta | Aciculata | Dorvilleidae |
| Ophryotrocha diadema | wqbench | Animalia | Annelida | Errantia | Aciculata | Dorvilleidae |
| Ophryotrocha labronica | anztox | NA | NA | NA | NA | NA |
| Ophryotrocha labronica | envirotox | Animalia | Annelida | Polychaeta | Aciculata | Dorvilleidae |
| Ophryotrocha labronica | wqbench | Animalia | Annelida | Errantia | Aciculata | Dorvilleidae |
| Raphidocelis subcapitata | anztox | Plantae | Chlorophyta | Chlorophyceae | NA | NA |
| Raphidocelis subcapitata | envirotox | Plantae | Chlorophyta | Chlorophyceae | Chlorococcales | Scenedesmaceae |
| Raphidocelis subcapitata | wqbench | Plantae | Chlorophyta | Chlorophyceae | Sphaeropleales | Selenastraceae |
| Thalassiosira fluviatilis | anztox | Chromista | Bacillariophyta | Mediophyceae | NA | NA |
| Thalassiosira fluviatilis | envirotox | Chromista | Bacillariophyta | Coscinodiscophyceae | Thalassiosirales | Thalassiosiraceae |

Species where `kingdom` or `phylum` (the highest-level fields) disagree across sources: 40
| scientificname | source | kingdom | phylum |
|---|---|---|---|
| Anabaena flos-aquae | anztox | Bacteria | Cyanobacteria |
| Anabaena flos-aquae | envirotox | Monera | Cyanophycota |
| Aphanothece clathrata | envirotox | Eubacteria | Cyanobacteria |
| Aphanothece clathrata | wqbench | Monera | Cyanophycota |
| Arthrospira fusiformis | anztox | Bacteria | Cyanobacteria |
| Arthrospira fusiformis | wqbench | Monera | Cyanophycota |
| Berula erecta | anztox | Plantae | Tracheophyta |
| Berula erecta | wqbench | Plantae | Magnoliophyta |
| Ceramium tenuicorne | anztox | Plantae | Rhodophyta |
| Ceramium tenuicorne | wqbench | Plantae | Rhodophycota |
| Chlorococcum sp. | anztox | Bacteria | Cyanobacteria |
| Chlorococcum sp. | wqbench | Plantae | Chlorophyta |
| Chroococcus minor | anztox | Bacteria | Cyanobacteria |
| Chroococcus minor | envirotox | Monera | Cyanophycota |
| Chroococcus minor | wqbench | Monera | Cyanophycota |
| Dexiotricha granulosa | envirotox | Chromista | Ciliophora |
| Dexiotricha granulosa | wqbench | Animalia | Ciliophora |
| Eisenia bicyclis | envirotox | Chromista | Ochrophyta |
| Eisenia bicyclis | wqbench | Chromista | Phaeophyta |
| Glyceria maxima | anztox | Plantae | Tracheophyta |
| Glyceria maxima | wqbench | Plantae | Magnoliophyta |
| Gracilaria tenuistipitata | anztox | Plantae | Rhodophyta |
| Gracilaria tenuistipitata | wqbench | Plantae | Rhodophycota |
| Hormosira banksii | anztox | NA | NA |
| Hormosira banksii | envirotox | Chromista | Ochrophyta |
| Hormosira banksii | wqbench | Chromista | Phaeophyta |
| Hymenomonas elongata | envirotox | Plantae | Haptophyta |
| Hymenomonas elongata | wqbench | Chromista | Haptophyta |
| Isochrysis galbana | anztox | NA | NA |
| Isochrysis galbana | envirotox | Plantae | Haptophyta |
| Isochrysis galbana | wqbench | Chromista | Haptophyta |
| Leptolyngbya boryana | anztox | Bacteria | Cyanobacteria |
| Leptolyngbya boryana | wqbench | Monera | Cyanophycota |
| Lophopodella carteri | envirotox | Animalia | Ectoprocta |
| Lophopodella carteri | wqbench | Animalia | Bryozoa |
| Merismopedia tenuissima | envirotox | Eubacteria | Cyanobacteria |
| Merismopedia tenuissima | wqbench | Monera | Cyanophycota |
| Microcystis sp. | anztox | Bacteria | Cyanobacteria |
| Microcystis sp. | wqbench | Monera | Cyanophycota |
| Micromonas pusilla | envirotox | Plantae | Chlorophyta |
| Micromonas pusilla | wqbench | Plantae | Prasinophyta |
| Monhystera disjuncta | anztox | NA | NA |
| Monhystera disjuncta | envirotox | Animalia | Nemata |
| Monhystera disjuncta | wqbench | Animalia | Nematoda |
| Monhystera microphthalma | anztox | NA | NA |
| Monhystera microphthalma | envirotox | Animalia | Nemata |
| Monhystera microphthalma | wqbench | Animalia | Nematoda |
| Myriophyllum aquaticum | anztox | Plantae | Tracheophyta |
| Myriophyllum aquaticum | wqbench | Plantae | Magnoliophyta |
| Myriophyllum heterophyllum | anztox | Plantae | Tracheophyta |
| Myriophyllum heterophyllum | wqbench | Plantae | Magnoliophyta |
| Najas sp. | anztox | Plantae | Tracheophyta |
| Najas sp. | wqbench | Plantae | Magnoliophyta |
| Nannochloropsis gaditana | envirotox | Plantae | Chlorophyta |
| Nannochloropsis gaditana | wqbench | Chromista | Ochrophyta |
| Neogoniolithon fosliei | anztox | Plantae | Rhodophyta |
| Neogoniolithon fosliei | wqbench | Plantae | Rhodophycota |
| Nephroselmis pyriformis | anztox | Plantae | Chlorophyta |
| Nephroselmis pyriformis | wqbench | Plantae | Prasinophyta |
| Nitzschia kuetzingiana | envirotox | Chromista | Ochrophyta |
| Nitzschia kuetzingiana | wqbench | Chromista | Bacillariophyta |
| Nitzschia pungens | envirotox | Chromista | Ochrophyta |
| Nitzschia pungens | wqbench | Chromista | Bacillariophyta |
| Ochromonas danica | envirotox | Plantae | Chrysophyta |
| Ochromonas danica | wqbench | Chromista | Chrysophyta |
| Pavlova lutheri | envirotox | Plantae | Chrysophyta |
| Pavlova lutheri | wqbench | Chromista | Chrysophyta |
| Pectinatella magnifica | envirotox | Animalia | Ectoprocta |
| Pectinatella magnifica | wqbench | Animalia | Bryozoa |
| Persicaria amphibia | anztox | Plantae | Tracheophyta |
| Persicaria amphibia | wqbench | Plantae | Magnoliophyta |
| Plumatella casmiana | envirotox | Animalia | Ectoprocta |
| Plumatella casmiana | wqbench | Animalia | Bryozoa |
| Prorocentrum minimum | envirotox | Protoctista | Dinoflagellata |
| Prorocentrum minimum | wqbench | Chromista | Pyrrophycophyta |
| Staurastrum chaetoceras | envirotox | Plantae | Chlorophyta |
| Staurastrum chaetoceras | wqbench | Plantae | Charophyta |
| Staurastrum cristatum | envirotox | Plantae | Chlorophyta |
| Staurastrum cristatum | wqbench | Plantae | Charophyta |
| Staurastrum manfeldtii | envirotox | Plantae | Chlorophyta |
| Staurastrum manfeldtii | wqbench | Plantae | Charophyta |
| Staurastrum sebaldi | envirotox | Plantae | Chlorophyta |
| Staurastrum sebaldi | wqbench | Plantae | Charophyta |
| Zostera muelleri | anztox | Plantae | Tracheophyta |
| Zostera muelleri | wqbench | Plantae | Magnoliophyta |

## 5. Part 1 unresolved species cross-check

Note: `resolved_by == "none"` in `species_resolution_summary.csv` also
includes the 1,079 WoRMS-ambiguous species (they never reach a
single-record GBIF fallback query either), so it is NOT used directly here.
The filter below (`gbif_status == "gbif_no_match"`) isolates species
where GBIF was actually queried -- i.e. WoRMS returned no_match/api_error,
not ambiguous -- and GBIF also failed; this matches the Part 1 report's
"113 species, 2,078 rows" figure.

- Part 1 genuinely unresolved species (`gbif_status == "gbif_no_match"`): 113
- Of these, with no matching row at all in `species_source_taxonomy.csv`: 0
- Of these, with at least one non-NA kingdom/phylum/class value from source-native taxonomy: 100
- Conclusion: source-native taxonomy PARTIALLY covers (100 of 113) the Part 1 unresolved set.

Full detail (one row per Part 1 unresolved species):

| raw_species | n_rows | sources | has_any_taxonomy | kingdom | phylum | class |
|---|---|---|---|---|---|---|
| Chlorella sp. | 476 | anztox,wqbench | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Anabaena sp. | 127 | wqbench | TRUE | Monera | Cyanophycota | Cyanophyceae |
| Chlorella fusca var vacuolata | 123 | envirotox | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Morone saxatilis x chrysops | 123 | wqbench | TRUE | Animalia | Chordata | Actinopterygii |
| tribe Chironomini | 88 | wqbench | TRUE | Animalia | Arthropoda | Insecta |
| Microcystis sp. | 85 | anztox,wqbench | TRUE | Bacteria;Monera | Cyanobacteria;Cyanophycota | Cyanophyceae |
| Lemna sp. | 83 | wqbench | TRUE | Plantae | Magnoliophyta | Liliopsida |
| Nitzschia sp. | 82 | wqbench | TRUE | Chromista | Bacillariophyta | Bacillariophyceae |
| Najas sp. | 61 | anztox,wqbench | TRUE | Plantae | Tracheophyta;Magnoliophyta | Liliopsida |
| Lepidostoma sp. | 48 | wqbench | TRUE | Animalia | Arthropoda | Insecta |
| Alona sp. | 45 | wqbench | TRUE | Animalia | Arthropoda | Branchiopoda |
| Diatoma sp. | 42 | wqbench | TRUE | Chromista | Bacillariophyta | Fragilariophyceae |
| Ephemerella sp. | 35 | wqbench | TRUE | Animalia | Arthropoda | Insecta |
| Crithidia fasciculata | 32 | wqbench | TRUE | Animalia | Sarcomastigophora | Zoomastigophora |
| Cymbella sp. | 32 | wqbench | TRUE | Chromista | Bacillariophyta | Bacillariophyceae |
| Navicula sp. | 31 | wqbench | TRUE | Chromista | Bacillariophyta | Bacillariophyceae |
| Enallagma sp. | 29 | wqbench | TRUE | Animalia | Arthropoda | Insecta |
| Trichodina sp. | 29 | wqbench | TRUE | Animalia | Ciliophora | Ciliatea |
| Stenonema sp. | 25 | wqbench | TRUE | Animalia | Arthropoda | Insecta |
| Synchaeta sp. | 24 | wqbench | TRUE | Animalia | Rotifera | Monogononta |
| Tetrahymena sp. | 24 | wqbench | TRUE | Animalia | Ciliophora | Ciliatea |
| Chlorella fusca ssp. fusca | 22 | wqbench | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Dugesia sp. | 21 | wqbench | TRUE | Animalia | Platyhelminthes | Turbellaria |
| Sphaerium sp. | 19 | wqbench | TRUE | Animalia | Mollusca | Bivalvia |
| Myriophyllum sp. | 17 | wqbench | TRUE | Plantae | Magnoliophyta | Magnoliopsida |
| Holopedium sp. | 16 | wqbench | TRUE | Animalia | Arthropoda | Branchiopoda |
| Ceratophyllum sp. | 12 | wqbench | TRUE | Plantae | Magnoliophyta | Magnoliopsida |
| Egeria sp. | 12 | wqbench | TRUE | Plantae | Magnoliophyta | Liliopsida |
| Euplotes sp. | 12 | wqbench | TRUE | Animalia | Ciliophora | Ciliatea |
| Nais sp. | 12 | wqbench | TRUE | Animalia | Annelida | Oligochaeta |
| Ulothrix sp. | 11 | wqbench | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Amphora sp. | 10 | wqbench | TRUE | Chromista | Bacillariophyta | Bacillariophyceae |
| Opercularia sp. | 10 | wqbench | TRUE | Animalia | Ciliophora | Ciliatea |
| Catenula sp. | 9 | wqbench | TRUE | Animalia | Platyhelminthes | Turbellaria |
| Spirulina sp. | 9 | wqbench | TRUE | Monera | Cyanophycota | Cyanophyceae |
| Tinca sp. | 9 | wqbench | TRUE | Animalia | Chordata | Actinopterygii |
| Chara sp. | 8 | wqbench | TRUE | Plantae | Charophyta | Charophyceae |
| Hydrophilus sp. | 8 | wqbench | TRUE | Animalia | Arthropoda | Insecta |
| Nepa sp. | 8 | wqbench | TRUE | Animalia | Arthropoda | Insecta |
| Rhodomonas sp. | 8 | wqbench | TRUE | Plantae | Cryptophycophyta | Cryptophyceae |
| Sphaerocystis sp. | 8 | wqbench | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Stagnicola sp. | 7 | wqbench | TRUE | Animalia | Mollusca | Gastropoda |
| Anax sp. | 6 | wqbench | TRUE | Animalia | Arthropoda | Insecta |
| Brachionus sp. | 6 | wqbench | TRUE | Animalia | Rotifera | Monogononta |
| Cercaria sp. | 6 | wqbench | TRUE | Animalia | Platyhelminthes | Trematoda |
| Ephemerella sp | 6 | anztox,envirotox | TRUE | Animalia | Arthropoda | Insecta |
| Fluminicola sp. | 6 | wqbench | TRUE | Animalia | Mollusca | Gastropoda |
| Oreochromis aureus x niloticus | 6 | wqbench | TRUE | Animalia | Chordata | Actinopterygii |
| Pinnularia sp. | 6 | wqbench | TRUE | Chromista | Bacillariophyta | Bacillariophyceae |
| Alaria sp. | 5 | wqbench | TRUE | Chromista | Phaeophyta | Phaeophyceae |
| Enallagma sp | 5 | anztox,envirotox | TRUE | Animalia | Arthropoda | Insecta |
| Euplotes sp | 5 | envirotox | TRUE | Animalia | Ciliophora | Ciliatea |
| Haematococcus sp. | 5 | wqbench | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Hydrilla sp. | 5 | wqbench | TRUE | Plantae | Magnoliophyta | Liliopsida |
| Kirchneriella sp. | 5 | wqbench | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Oncorhynchus salar | 5 | envirotox | TRUE | Animalia | Chordata | Actinopterygii |
| Oncorhynchus sp. | 5 | wqbench | TRUE | Animalia | Chordata | Actinopterygii |
| - | 4 | anztox | FALSE |  |  |  |
| Chlorophycota | 4 | anztox | FALSE |  |  |  |
| Cyanophycota | 4 | anztox | FALSE |  |  |  |
| Invertebrates | 4 | anztox | FALSE |  |  |  |
| Nepa sp | 4 | anztox,envirotox | TRUE | Animalia | Arthropoda | Insecta |
| Oncorhynchus trutta | 4 | envirotox | TRUE | Animalia | Chordata | Actinopterygii |
| Paphia laterisulca | 4 | envirotox,wqbench | TRUE | Animalia | Mollusca | Bivalvia |
| Sagittaria sp. | 4 | wqbench | TRUE | Plantae | Magnoliophyta | Magnoliopsida |
| Cpannonicus | 3 | anztox | FALSE |  |  |  |
| Dugesia sp | 3 | envirotox | TRUE | Animalia | Platyhelminthes | Turbellaria |
| Hydrophilus sp | 3 | envirotox | TRUE | Animalia | Arthropoda | Insecta |
| Sagitta sp. | 3 | wqbench | TRUE | Animalia | Chaetognatha | Sagittoidea |
| Algae | 2 | anztox | FALSE |  |  |  |
| Capnia sp. | 2 | wqbench | TRUE | Animalia | Arthropoda | Insecta |
| Chaetophora sp. | 2 | wqbench | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Cladophora sp. | 2 | wqbench | TRUE | Plantae | Chlorophyta | Ulvophyceae |
| Eudorina sp. | 2 | wqbench | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Illybius angustior | 2 | wqbench | TRUE | Animalia | Arthropoda | Insecta |
| Illybius augustior | 2 | anztox | FALSE |  |  |  |
| Kurzia sp. | 2 | wqbench | TRUE | Animalia | Arthropoda | Branchiopoda |
| Morone saxatilis ssp. x chrysops | 2 | envirotox | TRUE | Animalia | Chordata | Actinopterygii |
| Nassula variabilis | 2 | wqbench | TRUE | Animalia | Ciliophora | Nassophorea |
| Pontoporeia sp | 2 | anztox,envirotox | TRUE | Animalia | Arthropoda | Malacostraca |
| Rivularia sp. | 2 | wqbench | TRUE | Monera | Cyanophycota | Cyanophyceae |
| Sagitta sp | 2 | envirotox | TRUE | Animalia | Chaetognatha | Sagittoidea |
| Salmoides micropterus | 2 | anztox | FALSE |  |  |  |
| Triogoma sp. | 2 | anztox | FALSE |  |  |  |
| Uronema sp. | 2 | wqbench | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Carteria sp. | 1 | wqbench | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Chlamydomanas - Strain CC125 | 1 | anztox | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Chlamydomanas - Strain CC1373 | 1 | anztox | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Chlamydomanas - Strain CC2290 | 1 | anztox | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Chlamydomanas - Strain CC2342 | 1 | anztox | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Chlamydomanas - Strain CC2343 | 1 | anztox | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Chlamydomanas - Strain CC2344 | 1 | anztox | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Chlamydomanas - Strain CC2931 | 1 | anztox | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Chlamydomanas - Strain CC2935 | 1 | anztox | TRUE | Plantae | Chlorophyta | Chlorophyceae |
| Ensimulium sp. | 1 | anztox | FALSE |  |  |  |
| Gracilaria sp. | 1 | wqbench | TRUE | Plantae | Rhodophycota | Rhodophyceae |
| Lepidostoma sp | 1 | envirotox | TRUE | Animalia | Arthropoda | Insecta |
| Mansonia sp. | 1 | wqbench | TRUE | Animalia | Arthropoda | Insecta |
| Microcystis sp. S17 | 1 | anztox | TRUE | Bacteria | Cyanobacteria | Cyanophyceae |
| Microcystis sp. S31 | 1 | anztox | TRUE | Bacteria | Cyanobacteria | Cyanophyceae |
| Microcystis sp. S44 | 1 | anztox | TRUE | Bacteria | Cyanobacteria | Cyanophyceae |
| N. humilis | 1 | anztox | FALSE |  |  |  |
| Oreochromis mossambicus X niloticus | 1 | wqbench | TRUE | Animalia | Chordata | Actinopterygii |
| Oreochromis mossambicus X urolepis | 1 | wqbench | TRUE | Animalia | Chordata | Actinopterygii |
| Orthotrichia sp. | 1 | wqbench | TRUE | Animalia | Arthropoda | Insecta |
| Oxcillatoria spp. | 1 | anztox | FALSE |  |  |  |
| Periphyton | 1 | anztox | FALSE |  |  |  |
| Pontogeneia sp | 1 | envirotox | TRUE | Animalia | Arthropoda | Malacostraca |
| Pontogeneia sp. | 1 | wqbench | TRUE | Animalia | Arthropoda | Malacostraca |
| Pontoporeia sp. | 1 | wqbench | TRUE | Animalia | Arthropoda | Malacostraca |
| Radix sp. | 1 | wqbench | TRUE | Animalia | Mollusca | Gastropoda |
| Rhyacophila sp. | 1 | wqbench | TRUE | Animalia | Arthropoda | Insecta |
| Stenonema sp | 1 | envirotox | TRUE | Animalia | Arthropoda | Insecta |

## 6. Phylum -> kingdom lookup used (anztox kingdom derivation)

Built to align with the 6-kingdom scheme (Animalia, Plantae, Chromista, Bacteria, Protozoa, Fungi) already produced by the Part 1 WoRMS/GBIF resolution -- see script header for derivation rationale.

| phylum | kingdom |
|---|---|
| Annelida | Animalia |
| Arthropoda | Animalia |
| Bryozoa | Animalia |
| Chaetognatha | Animalia |
| Chordata | Animalia |
| Cnidaria | Animalia |
| Ctenophora | Animalia |
| Echinodermata | Animalia |
| Gastrotricha | Animalia |
| Mollusca | Animalia |
| Nematoda | Animalia |
| Platyhelminthes | Animalia |
| Porifera | Animalia |
| Rotifera | Animalia |
| Sipuncula | Animalia |
| Cyanobacteria | Bacteria |
| Firmicutes | Bacteria |
| Firmicutes_a | Bacteria |
| Proteobacteria | Bacteria |
| Bacillariophyta | Chromista |
| Ciliophora | Chromista |
| Cryptophyta | Chromista |
| Haptophyta | Chromista |
| Heterokontophyta | Chromista |
| Myzozoa | Chromista |
| Ochrophyta | Chromista |
| Ascomycota | Fungi |
| Chytridiomycota | Fungi |
| Microsporidia | Fungi |
| Charophyta | Plantae |
| Chlorophyta | Plantae |
| Magnoliophyta | Plantae |
| Rhodophyta | Plantae |
| Tracheophyta | Plantae |
| Amoebozoa | Protozoa |
| Euglenozoa | Protozoa |
| Mycetozoa | Protozoa |

All anztox phyla observed among in-scope species were covered by this lookup.

## 7. Recommendations for Part 2

- **WoRMS query filter level:** class-level source-native taxonomy is well populated for wqbench and envirotox but very sparse for anztox (anztox's `species` table only carries `class_id` for a small minority of rows; most anztox taxonomic signal lives in the coarser `majorgroup`/`minorgroup`/`animalcategory` fields instead). Recommend Decision C's class-first approach for wqbench/envirotox-only species, but fall back to phylum (derived for anztox via the Step 6 lookup) or to `source_majorgroup`/`source_animalcategory` as a coarse filter for anztox-only species where class is NA.
- **Cross-source disagreements:** 40 species disagree on kingdom or phylum across sources -- these are the highest-priority candidates for human review before Part 2 treats source-native taxonomy as ground truth for query filtering.
- **Part 1 unresolved species:** source-native taxonomy partially or fully covers the 113 genuinely-unresolved species from Part 1 (100/113 have at least a kingdom/phylum/class value). Part 2 should use this source-native context to construct a narrower WoRMS query (e.g. genus + class) for these species rather than retrying the same bare-name query that already failed.
- **Future enhancement:** anztox's `species` table has very low fill rates for `class_id`/`isheterotroph` (a small fraction of rows) and 60 duplicate `scientificname` entries with potentially conflicting `majorgroup`/`minorgroup` values -- both are data-quality characteristics of the source `infogathering` database itself, not of this extraction script, and are out of scope to fix here.

