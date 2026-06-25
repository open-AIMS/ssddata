# Stage 4d Part 1 -- Species Resolution Diagnostic Report

Generated: 2026-06-24 20:31:05 AWST

## 1. Input summary

- Total final clean rows (`dedup_retained` & `priority_kept`): 381,410
- Unique `scientificname` values: 4,348

Row-count distribution of species:

| row_bucket | n_species | n_rows |
|---|---|---|
| <10 | 2317 |   8327 |
| 10-99 | 1610 |  51928 |
| 100-999 |  362 |  98969 |
| >=1000 |   59 | 222186 |

## 2. Resolution status overview

Parenthetical "(WoRMS fallback)" / "(both failed)" rows include cases
where WoRMS returned no_match OR api_error before GBIF was queried --
GBIF was only ever queried for those two WoRMS outcomes (see script
header). Categories are mutually exclusive and sum to all species.

| combined_status | n_species | n_rows |
|---|---|---|
| API errors |    0 |      0 |
| GBIF exact (WoRMS fallback) |  725 |  23683 |
| GBIF fuzzy (WoRMS fallback) |  716 |  10668 |
| Unresolved (both failed) |  113 |   2078 |
| WoRMS ambiguous | 1079 | 156131 |
| WoRMS exact | 1191 | 166676 |
| WoRMS exact (unaccepted, has synonym) |  472 |  20893 |
| WoRMS fuzzy |   52 |   1281 |

## 3. Taxonomic hierarchy distribution

Restricted to species with `resolved_by %in% c("worms", "gbif")` (a single accepted/candidate record was assigned).

### Kingdoms

| kingdom | n_species | n_rows |
|---|---|---|
| Animalia | 2621 | 188854 |
| Plantae |  250 |  25367 |
| Chromista |  199 |   6795 |
| Bacteria |   73 |   2079 |
| Protozoa |   11 |     98 |
| Fungi |    2 |      8 |

### Phyla

| phylum | n_species | n_rows |
|---|---|---|
| Arthropoda | 1271 | 85068 |
| Chordata |  751 | 86861 |
| Mollusca |  308 | 11178 |
| Chlorophyta |  118 | 13232 |
| Tracheophyta |  112 | 11831 |
| Cyanobacteria |   70 |  2071 |
| Ciliophora |   63 |  2899 |
| Annelida |   60 |  1625 |
| Ochrophyta |   59 |   626 |
| NA |   42 |   641 |
| Cnidaria |   40 |   913 |
| Rotifera |   40 |   403 |
| Platyhelminthes |   36 |   621 |
| Echinodermata |   31 |  1197 |
| Heterokontophyta |   30 |  1969 |
| Nematoda |   29 |   275 |
| Myzozoa |   23 |   444 |
| Haptophyta |   13 |   606 |
| Bryozoa |   10 |   115 |
| Charophyta |   10 |    73 |
| Cryptophyta |   10 |   161 |
| Rhodophyta |    7 |   208 |
| Amoebozoa |    6 |    62 |
| Euglenozoa |    4 |    34 |
| Ctenophora |    2 |     7 |
| Porifera |    2 |    44 |
| Ascomycota |    1 |     2 |
| Chaetognatha |    1 |    12 |
| Firmicutes |    1 |     2 |
| Firmicutes_A |    1 |     3 |
| Gastrotricha |    1 |     4 |
| Microsporidia |    1 |     6 |
| Mycetozoa |    1 |     2 |
| Proteobacteria |    1 |     3 |
| Sipuncula |    1 |     3 |

### Classes (top 30 by row count)

| class | n_species | n_rows |
|---|---|---|
| Teleostei | 459 | 69912 |
| Branchiopoda | 125 | 42199 |
| Malacostraca | 348 | 20352 |
| Insecta | 645 | 19647 |
| Amphibia | 186 | 13481 |
| Chlorophyceae |  76 | 11998 |
| Magnoliopsida |  62 | 10042 |
| Bivalvia | 161 |  7165 |
| Gastropoda | 136 |  3956 |
| NA | 140 |  3789 |
| Oligohymenophorea |  34 |  2383 |
| Bacillariophyceae |  63 |  2234 |
| Copepoda |  90 |  2194 |
| Liliopsida |  40 |  1557 |
| Cyanophyceae |  35 |  1490 |
| Echinoidea |  19 |  1090 |
| Polychaeta |  21 |   930 |
| Trebouxiophyceae |  20 |   672 |
| Clitellata |  37 |   659 |
| Chondrostei |   7 |   654 |
| Cyanobacteriia |  35 |   581 |
| Coccolithophyceae |   7 |   522 |
| Hydrozoa |  10 |   464 |
| Hexacorallia |  27 |   409 |
| Dinophyceae |  21 |   402 |
| Eurotatoria |  39 |   402 |
| Ostracoda |  24 |   364 |
| Ulvophyceae |   8 |   272 |
| Heterotrichea |   6 |   258 |
| Chromadorea |  24 |   249 |

All other classes (69 distinct, 251 species, 2,874 rows combined):

## 4. Sample unresolved species (top 30 by row count)

Excludes `WoRMS ambiguous` (see Section 6).

| raw_species | n_rows | sources | example_cas | worms_status | gbif_status |
|---|---|---|---|---|---|
| Chlorella sp. | 476 | anztox,wqbench |  34014181 | no_match | gbif_no_match |
| Anabaena sp. | 127 | wqbench |  77238392 | no_match | gbif_no_match |
| Chlorella fusca var vacuolata | 123 | envirotox |     51036 | no_match | gbif_no_match |
| Morone saxatilis x chrysops | 123 | wqbench |  99300784 | no_match | gbif_no_match |
| tribe Chironomini |  88 | wqbench | 103055078 | no_match | gbif_no_match |
| Microcystis sp. |  85 | anztox,wqbench |  51218452 | no_match | gbif_no_match |
| Lemna sp. |  83 | wqbench |    330541 | no_match | gbif_no_match |
| Nitzschia sp. |  82 | wqbench |  21725462 | no_match | gbif_no_match |
| Najas sp. |  61 | anztox,wqbench |  51218452 | no_match | gbif_no_match |
| Lepidostoma sp. |  48 | wqbench |   7758987 | no_match | gbif_no_match |
| Alona sp. |  45 | wqbench |   2921882 | no_match | gbif_no_match |
| Diatoma sp. |  42 | wqbench |    709988 | no_match | gbif_no_match |
| Ephemerella sp. |  35 | wqbench | 135410207 | no_match | gbif_no_match |
| Crithidia fasciculata |  32 | wqbench |     50293 | no_match | gbif_no_match |
| Cymbella sp. |  32 | wqbench |    330541 | no_match | gbif_no_match |
| Navicula sp. |  31 | wqbench |  51235042 | no_match | gbif_no_match |
| Enallagma sp. |  29 | wqbench |    115297 | no_match | gbif_no_match |
| Trichodina sp. |  29 | wqbench |     50000 | no_match | gbif_no_match |
| Stenonema sp. |  25 | wqbench |    298464 | no_match | gbif_no_match |
| Synchaeta sp. |  24 | wqbench |  70288867 | no_match | gbif_no_match |
| Tetrahymena sp. |  24 | wqbench |  10108642 | no_match | gbif_no_match |
| Chlorella fusca ssp. fusca |  22 | wqbench |  51218452 | no_match | gbif_no_match |
| Dugesia sp. |  21 | wqbench |  79622596 | no_match | gbif_no_match |
| Sphaerium sp. |  19 | wqbench |  66230044 | no_match | gbif_no_match |
| Myriophyllum sp. |  17 | wqbench |  59756604 | no_match | gbif_no_match |
| Holopedium sp. |  16 | wqbench |  51235042 | no_match | gbif_no_match |
| Ceratophyllum sp. |  12 | wqbench |  21087649 | no_match | gbif_no_match |
| Egeria sp. |  12 | wqbench |  21087649 | no_match | gbif_no_match |
| Euplotes sp. |  12 | wqbench |  10108642 | no_match | gbif_no_match |
| Nais sp. |  12 | wqbench |   7440020 | no_match | gbif_no_match |

## 5. Sample fuzzy / unaccepted matches (top 30 by row count)

| raw_species | n_rows | worms_status | gbif_status | accepted_name |
|---|---|---|---|---|
| Gobiocypris rarus | 1859 | exact_unaccepted | NA | Gobiocyproides rarus |
| Crassostrea gigas |  980 | exact_unaccepted | NA | Magallana gigas |
| Gibelion catla |  664 | exact_unaccepted | NA | Labeo catla |
| Litopenaeus vannamei |  664 | exact_unaccepted | NA | Penaeus (Litopenaeus) vannamei |
| Anabaena flosaquae |  607 | fuzzy | NA | Dolichospermum flos-aquae |
| Fistulifera pelliculosa |  545 | exact_unaccepted | NA | Synedra minutissima var. pelliculosa |
| Phaeodactylum tricornutum |  523 | exact_unaccepted | NA | Phaeodactylum tricornutum |
| Daphnia carinata |  427 | exact_unaccepted | NA | Daphnia (Ctenodaphnia) carinata |
| Thalassiosira pseudonana |  424 | exact_unaccepted | NA | Thalassiosira pseudonana |
| Artemia sp. |  410 | no_match | gbif_fuzzy | Artemia |
| Colisa fasciata |  348 | exact_unaccepted | NA | Trichogaster fasciata |
| Palaemonetes kadiakensis |  323 | exact_unaccepted | NA | Palaemon kadiakensis |
| Farfantepenaeus duorarum |  317 | exact_unaccepted | NA | Penaeus (Farfantepenaeus) duorarum |
| Lymnaea acuminata |  311 | exact_unaccepted | NA | Radix rufescens |
| Villosa iris |  306 | exact_unaccepted | NA | Cambarunio iris |
| Pelteobagrus fulvidraco |  297 | exact_unaccepted | NA | Tachysurus fulvidraco |
| Cancer magister |  283 | exact_unaccepted | NA | Metacarcinus magister |
| Leuciscus idus ssp. melanotus |  278 | no_match | gbif_fuzzy | Leuciscus idus |
| Hyla versicolor |  257 | exact_unaccepted | NA | Dryophytes versicolor |
| Palaemonetes pugio |  253 | exact_unaccepted | NA | Palaemon pugio |
| Chironomus sp. |  251 | no_match | gbif_fuzzy | Chironomus |
| Leuciscus idus melanotus |  248 | no_match | gbif_fuzzy | Leuciscus idus |
| Cipangopaludina malleata |  237 | exact_unaccepted | NA | Margarya laeta |
| Chaetogammarus marinus |  213 | exact_unaccepted | NA | Marinogammarus marinus |
| Palaemonetes sp. |  212 | no_match | gbif_fuzzy | Palaemonetes |
| Culex pipiens ssp. quinquefasciata |  211 | no_match | gbif_fuzzy | Culex pipiens quinquefasciatus |
| Synechogobius hasta |  206 | exact_unaccepted | NA | Acanthogobius hasta |
| Gymnodinium splendens |  205 | exact_unaccepted | NA | Akashiwo sanguinea |
| Uca pugilator |  205 | exact_unaccepted | NA | Leptuca pugilator |
| Daphnia similis |  195 | exact_unaccepted | NA | Daphnia (Ctenodaphnia) similis |

## 6. Ambiguous matches (WoRMS returned multiple records)

| raw_species | n_rows | n_records | n_unique_names | candidate_accepted_names |
|---|---|---|---|---|
| Oncorhynchus mykiss | 20188 |  3 |  2 | Oncorhynchus mykiss; Oncorhynchus aguabonita |
| Pimephales promelas | 17876 |  3 |  1 | Pimephales promelas |
| Lepomis macrochirus | 12104 |  3 |  1 | Lepomis macrochirus |
| Cyprinus carpio |  8249 | 23 |  6 | Cyprinus carpio; Cyprinus chilia; Cyprinus intha; Cyprinus megalophthalmus; Cyprinus multitaeniatus; Cyprinus rubrofuscus |
| Oryzias latipes |  6522 |  3 |  2 | Oryzias latipes; Oryzias sinensis |
| Carassius auratus |  4442 | 14 |  4 | Carassius auratus; Carassius cuvieri; Carassius gibelio; Carassius langsdorfii |
| Cyprinodon variegatus |  3234 |  8 |  5 | Cyprinodon variegatus; Cyprinodon artifrons; Cyprinodon dearborni; Cyprinodon hubbsi; Cyprinodon riverendi |
| Oreochromis niloticus |  2912 | 11 |  1 | Oreochromis niloticus |
| Gambusia affinis |  2301 |  5 |  2 | Gambusia affinis; Gambusia holbrooki |
| Salmo salar |  2020 | 11 |  1 | Salmo salar |
| Chlorella vulgaris |  1897 |  9 |  8 | Chlorella vulgaris; Chlorella vulgaris f. globosa; Chlorella vulgaris f. minuscula; Chlorella vulgaris f. suboblonga; Chlorella vulgaris var. autotrophica; Jaagichlorella luteoviridis; Chlorella vulgaris var. tertia; Chlorella vulgaris var. ultrasquamata |
| Microcystis aeruginosa |  1879 | 11 |  7 | Microcystis aeruginosa; Microcystis flos-aquae; Microcystis aeruginosa f. minor; NA; Microcystis viridis; Microcystis aeruginosa var. elongata; Microcystis aeruginosa var. major |
| Chlorella pyrenoidosa |  1678 |  4 |  4 | Auxenochlorella pyrenoidosa; Chlorella vulgaris; Chlorella pyrenoidosa var. tumidus; Coelastrella vacuolata |
| Brachionus calyciflorus |  1670 | 16 |  6 | Brachionus calyciflorus; Brachionus calyciflorus borgerti; Brachionus calyciflorus calyciflorus; Brachionus dorcas; Brachionus calyciflorus giganteus; Brachionus dimidiatus |
| Salvelinus fontinalis |  1614 |  2 |  1 | Salvelinus fontinalis |
| Fundulus heteroclitus |  1611 |  6 |  3 | Fundulus heteroclitus; Fundulus bermudae; Fundulus heteroclitus diaphanus |
| Desmodesmus subspicatus |  1559 |  2 |  2 | Desmodesmus subspicatus; Desmodesmus subspicatus var. bicaudatus |
| Skeletonema costatum |  1516 |  5 |  4 | Skeletonema costatum; Melosira costata; Skeletonema costatum f. tropicum; Skeletonema costatum var. spiralis |
| Mytilus galloprovincialis |  1475 | 11 |  1 | Mytilus galloprovincialis |
| Salmo trutta |  1369 | 19 | 13 | Salmo trutta; Salmo abanticus; Salmo caspius; Salmo ciscaucasicus; Salmo dentex; Salmo ezenami; Salmo labrax; Salvelinus alpinus; Salmo macrostigma; Salmo marmoratus (+3 more) |
| Tubifex tubifex |  1185 |  9 |  7 | Tubifex tubifex; Tubifex bergi; Tubifex blanchardi; Tubifex tubifex f. grandiseta; Amerigodrilus kleerekoperi; Amerigodrilus siolii; Tubifex tubifex tubifex |
| Dugesia japonica |  1167 |  3 |  2 | Dugesia japonica; Dugesia ryukyuensis |
| Oncorhynchus clarkii |  1082 |  6 |  1 | Oncorhynchus clarkii |
| Cirrhinus mrigala |  1077 |  3 |  2 | Cirrhinus mrigala; Cirrhinus molitorella |
| Rasbora heteromorpha |  1009 |  2 |  2 | Trigonostigma heteromorpha; Trigonostigma espei |
| Lymnaea stagnalis |   961 | 13 |  4 | Lymnaea stagnalis; Lymnaea jugularis; Lymnaea stagnalis stagnalis; Lymnaea fragilis |
| Mytilus edulis |   931 | 17 |  9 | Mytilus edulis; Mytilus planulatus; Mytilus edulis balthicus; Mytilus chilensis; Mytilus trossulus; Mytilus platensis; Mytilus galloprovincialis; Mytilus edulis edulis; Mytilus californianus |
| Dreissena polymorpha |   930 |  5 |  2 | Dreissena polymorpha; Dreissena polymorpha polymorpha |
| Macrobrachium rosenbergii |   856 |  2 |  1 | Macrobrachium rosenbergii |
| Chlamydomonas reinhardtii |   831 |  2 |  2 | Chlamydomonas reinhardtii; Chlamydomonas reinhardtii f. basimaculata |
| Anguilla anguilla |   821 |  6 |  1 | Anguilla anguilla |
| Gasterosteus aculeatus |   818 | 12 |  3 | Gasterosteus aculeatus; Gasterosteus crenobiontus; Gasterosteus microcephalus |
| Gammarus pulex |   816 | 13 |  9 | Gammarus pulex; Gammarus pulex araurensis; Gammarus pulex cognominis; Gammarus fossarum; Gammarus pulex gallicus; Gammarus ibericus; Gammarus koreanus; Gammarus pulex polonensis; Gammarus sobaegensis |
| Artemia salina |   809 | 12 |  2 | Artemia salina; NA |
| Rivulus marmoratus |   798 |  2 |  1 | Kryptolebias marmoratus |
| Scenedesmus quadricauda |   787 | 46 | 38 | Desmodesmus communis; NA; Scenedesmus quadricauda f. bicaudatus; Scenedesmus quadricauda f. crassiaculeatus; Scenedesmus quadricauda f. giganticus; Desmodesmus perforatus; Scenedesmus quadricauda f. minus; Scenedesmus quadricauda f. vidyanagarensis; Desmodesmus abundans; Scenedesmus quadricauda var. aculeolatus (+28 more) |
| Micropterus salmoides |   776 |  3 |  2 | Micropterus salmoides; Micropterus floridanus |
| Brachionus plicatilis |   626 | 14 |  8 | Brachionus plicatilis; Brachionus plicatilis colongulaciensis; Brachionus plicatilis decemcornis; Brachionus plicatilis estonianus; Brachionus plicatilis longicornis; Brachionus plicatilis magadiensis; Brachionus plicatilis var. ecornis; Brachionus spatiosus |
| Lampsilis siliquoidea |   580 |  6 |  2 | Lampsilis siliquoidea; Lampsilis hydiana |
| Corbicula fluminea |   546 |  6 |  5 | Corbicula fluminea; Corbicula baudoni; Corbicula bocourti; Corbicula japonica; Corbicula moreletiana |
| Moina macrocopa |   542 |  3 |  3 | Moina macrocopa; Moina macrocopa americana; Moina macrocopa macrocopa |
| Gambusia holbrooki |   517 |  2 |  1 | Gambusia holbrooki |
| Philodina acuticornis |   514 |  5 |  3 | Philodina acuticornis; Philodina acuticornis minor; Philodina acuticornis odiosa |
| Rhamdia quelen |   509 |  2 |  1 | Rhamdia quelen |
| Acartia tonsa |   507 |  2 |  2 | Acartia (Acanthacartia) tonsa; Acartia tonsa cryophylla |
| Ruditapes philippinarum |   503 |  2 |  1 | Ruditapes philippinarum |
| Penaeus monodon |   464 |  2 |  2 | Penaeus (Penaeus) monodon; Penaeus (Eopenaeus) semisulcatus |
| Menidia beryllina |   455 |  2 |  1 | Menidia beryllina |
| Asellus aquaticus |   454 | 15 | 15 | Asellus (Asellus) aquaticus aquaticus; Asellus arthrobranchialis; Asellus (Asellus) balcanicus; Asellus (Asellus) aquaticus carniolicus; Asellus (Asellus) aquaticus cavernicolus; Asellus (Asellus) aquaticus carsicus; Asellus (Asellus) aquaticus cyclobranchialis; Asellus (Asellus) aquaticus infernus; Asellus (Asellus) aquaticus irregularis; Asellus (Asellus) aquaticus longicornis (+5 more) |
| Lumbriculus variegatus |   427 |  3 |  2 | Lumbriculus variegatus; Lumbriculus inconstans |
| Carassius gibelio |   420 |  2 |  2 | Carassius gibelio; Carassius carassius |
| Gammarus lacustris |   415 |  2 |  2 | Gammarus lacustris; Gammarus lacustris limnaeus |
| Hydra vulgaris |   410 |  2 |  1 | Hydra vulgaris |
| Nitocra spinipes |   390 |  4 |  2 | Nitocra spinipes spinipes; Nitocra spinipes orientalis |
| Carcinus maenas |   384 |  3 |  2 | Carcinus maenas; Carcinus aestuarii |
| Chlamys farreri |   350 |  3 |  1 | Scaeochlamys farreri |
| Petromyzon marinus |   350 |  4 |  2 | Petromyzon marinus; Lethenteron camtschaticum |
| Oncorhynchus nerka |   348 |  4 |  2 | Oncorhynchus nerka; Oncorhynchus kawamurae |
| Mystus vittatus |   340 |  4 |  3 | Mystus vittatus; Mystus dibrugarensis; Mystus horai |
| Notemigonus crysoleucas |   334 |  2 |  1 | Notemigonus crysoleucas |
| Anabaena flos-aquae |   330 | 22 | 15 | Dolichospermum flos-aquae; Dolichospermum perturbatum; Anabaena discoidea; Anabaena flos-aquae f. gracilis; Dolichospermum flos-aquae var. intermedium; Dolichospermum lemmermannii; Anabaena flos-aquae f. major; Anabaena flos-aquae f. minor; Anabaena flos-aquae f. spiroides; Dolichospermum mendotae (+5 more) |
| Macrocystis pyrifera |   315 |  4 |  1 | Macrocystis pyrifera |
| Eriocheir sinensis |   310 |  6 |  2 | Eriocheir sinensis; Eriocheir sinensis reovirus |
| Penaeus aztecus |   310 |  2 |  2 | Penaeus (Farfantepenaeus) aztecus; Penaeus (Farfantepenaeus) subtilis |
| Callinectes sapidus |   309 |  2 |  1 | Callinectes sapidus |
| Nostoc muscorum |   308 |  3 |  3 | Desmonostoc muscorum; Nostoc muscorum var. lichenoides; Nostoc muscorum var. tenax |
| Ameiurus melas |   300 |  2 |  1 | Ameiurus melas |
| Misgurnus anguillicaudatus |   295 |  2 |  1 | Misgurnus anguillicaudatus |
| Gadus morhua |   293 |  7 |  2 | Gadus morhua; Gadus macrocephalus |
| Scylla serrata |   293 |  2 |  2 | Scylla serrata; Scylla paramamosain |
| Lamellidens marginalis |   291 |  3 |  3 | Lamellidens marginalis; Lamellidens candaharicus; Trapezidens angustior |
| Sander vitreus |   289 |  2 |  1 | Sander vitreus |
| Biomphalaria alexandrina |   282 |  3 |  3 | Biomphalaria alexandrina; Biomphalaria sudanica; Biomphalaria camerunensis |
| Mugil cephalus |   281 |  5 |  2 | Mugil cephalus; Chelon ramada |
| Perna perna |   278 |  2 |  1 | Perna perna |
| Tapes philippinarum |   271 |  2 |  1 | Ruditapes philippinarum |
| Scenedesmus acutus |   253 | 10 |  7 | Tetradesmus obliquus; Scenedesmus acutus f. alterans; Scenedesmus acutus f. costulatus; Scenedesmus acutus f. tetradesmiformis; Tetradesmus dimorphus; Scenedesmus acutus var. globosus; Scenedesmus acutus var. symmetricus |
| Catostomus commersoni |   250 |  3 |  1 | Catostomus commersonii |
| Anabas testudineus |   248 |  4 |  1 | Anabas testudineus |
| Acutodesmus acuminatus |   246 |  4 |  2 | Tetradesmus lagerheimii; NA |
| Rutilus rutilus |   246 | 22 |  3 | Rutilus rutilus; Rutilus caspicus; Rutilus heckelii |
| Penaeus indicus |   239 |  3 |  2 | Penaeus (Fenneropenaeus) indicus; Penaeus (Fenneropenaeus) penicillatus |
| Lepeophtheirus salmonis |   238 |  3 |  2 | Lepeophtheirus salmonis salmonis; Lepeophtheirus salmonis oncorhynchi |
| Crassostrea rhizophorae |   236 |  2 |  2 | Crassostrea rhizophorae; Crassostrea praia |
| Euglena gracilis |   235 | 15 |  7 | Euglena gracilis; NA; Euglena gracilis f. hiemalis; Euglena longa; Euglena gracilis var. acuticauda; Euglena gracilis var. saccharophila; Euglena gracilis var. urophora |
| Oncorhynchus keta |   235 |  2 |  2 | Oncorhynchus keta; NA |
| Leuciscus idus |   231 |  6 |  1 | Leuciscus idus |
| Viviparus bengalensis |   231 |  3 |  2 | Filopaludina bengalensis; Filopaludina doliaris |
| Anodonta anatina |   224 |  5 |  1 | Anodonta anatina |
| Brachionus koreanus |   221 |  2 |  2 | Brachionus koreanus; Brachionus koreanus santodomingensis |
| Esox lucius |   220 |  6 |  1 | Esox lucius |
| Crangon crangon |   213 |  4 |  1 | Crangon crangon |
| Limnodrilus hoffmeisteri |   213 |  5 |  3 | Limnodrilus hoffmeisteri; Limnodrilus hoffmeisteri f. spiralis; Limnodrilus hoffmeisteri tenellulus |
| Psetta maxima |   211 |  3 |  2 | Scophthalmus maximus; Scophthalmus maeoticus |
| Dendraster excentricus |   206 |  3 |  1 | Dendraster excentricus |
| Carassius carassius |   200 |  6 |  4 | Carassius carassius; Carassius auratus; Carassius cuvieri; Carassius langsdorfii |
| Tilapia mossambica |   200 |  4 |  3 | Oreochromis mossambicus; Oreochromis korogwe; Oreochromis mortimeri |
| Marisa cornuarietis |   197 |  2 |  1 | Marisa cornuarietis |
| Gomphonema gracile |   195 | 37 | 33 | Gomphonema gracile; Gomphonema gracile f. affines; Gomphonema gracile f. alpha; Gomphonema gracile f. beta; Gomphonema gracile var. cymbelloides; Gomphonema gracile f. gracile; Gomphonema gracile f. major; Gomphonema gracile f. parva; Gomphonema gracile f. turris; Gomphonema gracile var. acutiuscula (+23 more) |
| Capitella capitata |   194 | 14 |  9 | Capitella capitata; Capitella capitata antarctica; Capitella capitata capitata; Capitella capitata europaea; Capitella capitata floridana; Capitella capitata japonica; Capitella capitata oculata; Capitella capitata ovincola; Capitella capitata tripartita |
| Ulva fasciata |   194 | 14 | 11 | Ulva lactuca; Ulva linza; Ulva fasciata f. caespitosa; Ulva expansa; Ulva fasciata f. major; Ulva fasciata f. minor; Ulva taeniata; Ulva fasciata var. concolor; Ulva fasciata var. lobata; Ulva fasciata var. palmata (+1 more) |
| Crangon septemspinosa |   192 |  3 |  2 | Crangon septemspinosa; Crangon amurensis |
| Anabaena variabilis |   182 | 14 | 10 | Trichormus variabilis; NA; Anabaena variabilis f. mareotica; Trichormus rotundosporus; Anabaena variabilis var. cylindracea; Trichormus ellipsosporus; Anabaena variabilis var. ellipsospora; Trichormus kashiensis; Trichormus steloides; Anabaena variabilis var. vietnamensis |
| Paratya australiensis |   179 |  3 |  2 | Paratya australiensis; Paratya norfolkensis |
| Penaeus duorarum |   179 |  4 |  2 | Penaeus (Farfantepenaeus) duorarum; Penaeus (Farfantepenaeus) notialis |
| Proales similis |   178 |  2 |  1 | Proales similis |
| Atherinops affinis |   177 |  3 |  1 | Atherinops affinis |
| Micropterus dolomieu |   175 |  4 |  1 | Micropterus dolomieu |
| Cerastoderma edule |   174 |  2 |  1 | Cerastoderma edule |
| Pomatoschistus minutus |   166 |  3 |  1 | Pomatoschistus minutus |
| Ankistrodesmus falcatus |   165 | 35 | 18 | Ankistrodesmus falcatus; NA; Ankistrodesmus falcatus f. dulcis; Ankistrodesmus falcatus f. gigas; Monoraphidium flexuosum f. longisetum; Ankistrodesmus falcatus f. longissimus; Monoraphidium terrestre; Monoraphidium griffithii; Ankistrodesmus falcatus var. biplex; Monoraphidium contortum (+8 more) |
| Barbus ticto |   162 |  2 |  2 | Pethia ticto; Pethia stoliczkana |
| Fundulus similis |   162 |  2 |  1 | Fundulus similis |
| Utterbackia imbecillis |   162 |  2 |  1 | Utterbackia imbecillis |
| Corophium volutator |   161 |  3 |  3 | Corophium volutator; Corophium orientale; Sinocorophium japonicum |
| Cyclotella meneghiniana |   160 | 45 | 37 | Cyclotella meneghiniana; Cyclotella meneghiniana var. binotata; Cyclotella meneghiniana f. meneghiniana; Cyclotella meneghiniana f. minor; Cyclotella meneghiniana f. nuda; Cyclotella meneghiniana f. plana; Cyclotella meneghiniana f. unipunctata; Cyclotella meneghiniana var. baileyi; Cyclotella meneghiniana var. beta; Cyclotella meneghiniana var. brevistriata (+27 more) |
| Perca fluviatilis |   159 | 11 |  2 | Perca fluviatilis; Perca flavescens |
| Poecilia vivipara |   158 |  2 |  2 | Poecilia vivipara; Poecilia parae |
| Pontastacus leptodactylus |   156 |  2 |  1 | Pontastacus leptodactylus |
| Anabaena cylindrica |   155 |  8 |  5 | Anabaena cylindrica; NA; Anabaena cylindrica var. marchica; Anabaena cylindrica var. fertilissima; Anabaena cylindrica var. punctata |
| Eurytemora affinis |   155 |  5 |  3 | Eurytemora affinis affinis; Eurytemora affinis hispida; Eurytemora raboti |
| Salvelinus confluentus |   148 |  2 |  2 | Salvelinus confluentus; Salvelinus malma |
| Tilapia zillii |   147 |  2 |  2 | Coptodon zillii; Coptodon guineensis |
| Alburnus alburnus |   146 | 12 |  8 | Alburnus alburnus; Alburnus albidus; Alburnus arborella; Alburnus belvica; Alburnus alburnus charusini; Alburnus hohenackeri; Alburnus macedonicus; Alburnus thessalicus |
| Moina micrura |   143 |  3 |  3 | Moina micrura; Moina micrura ciliata; Moina micrura micrura |
| Anodonta cygnea |   141 |  7 |  3 | Anodonta cygnea; Brachyanodon nuttallianus; Anodonta anatina |
| Cottus bairdi |   141 |  6 |  1 | Cottus bairdii |
| Keratella cochlearis |   141 | 34 | 14 | Keratella cochlearis; Keratella irregularis; Keratella cochlearis f. postcurvata; Keratella valdiviensis; Keratella cochlearis nordica; Keratella cochlearis pachyacantha; Keratella cochlearis polaris; Keratella cochlearis cochlearis; Keratella cochlearis var. baltica; Keratella cochlearis var. carinata (+4 more) |
| Physa heterostropha |   136 | 10 |  5 | Physella acuta; Physa heterostropha nigricans; Physella pomilia; NA; Physella gyrina |
| Pomacea paludosa |   136 |  2 |  1 | Pomacea paludosa |
| Leucaspius delineatus |   135 |  5 |  1 | Leucaspius delineatus |
| Sargassum hornschuchii |   134 |  2 |  2 | Sargassum hornschuchii; Sargassum hornschuchii var. lundense |
| Macrobrachium lamarrei |   133 |  4 |  4 | Macrobrachium lamarrei; Macrobrachium lamarrei korangii; Macrobrachium lamarrei lamarrei; Macrobrachium lamarrei lamarroides |
| Stylophora pistillata |   133 |  2 |  1 | Stylophora pistillata |
| Chasmichthys dolichognathus |   131 |  3 |  2 | Chaenogobius annularis; Chaenogobius gulosus |
| Sinanodonta woodiana |   125 |  2 |  2 | Sinanodonta woodiana; Sinanodonta lauta |
| Thymallus arcticus |   125 | 14 |  7 | Thymallus arcticus; Thymallus baicalensis; Thymallus brevipinnis; Thymallus grubii; Thymallus mertensii; Thymallus nigrescens; Thymallus pallasii |
| Nostoc commune |   123 |  8 |  6 | Nostoc commune; Nostoc antarcticum; Nostoc commune f. ulvaceum; NA; Nostoc commune var. fieldii; Nostoc flagelliforme |
| Strongylocentrotus droebachiensis |   123 |  3 |  2 | Strongylocentrotus droebachiensis; Strongylocentrotus pallidus |
| Ulva lactuca |   123 | 48 | 42 | Ulva lactuca; Ulva lactuca f. australis; Ulva lactuca f. consociata; Ulva lactuca f. contorta; Ulva lactuca f. cribrosa; Ulva lactuca f. crispa; Ulva lactuca f. dillenii; Ulva lactuca f. foraminata; Ulva lactuca f. genuina; Ulva lactuca f. laciniata (+32 more) |
| Pocillopora damicornis |   120 |  7 |  2 | Pocillopora damicornis; Pocillopora acuta |
| Chaetoceros calcitrans |   116 |  2 |  2 | Chaetoceros simplex var. calcitrans; Chaetoceros calcitrans f. pumilus |
| Daphnia obtusa |   116 |  2 |  2 | Daphnia obtusa; Simocephalus obtusatus |
| Cambarus bartonii |   112 |  8 |  8 | Cambarus bartonii; Cambarus asperimanus; Cambarus bartonii bartonii; Cambarus carinirostris; Cambarus bartonii cavatus; Cambarus tenebrosus; Cambarus longirostris; Cambarus veteranus |
| Strongylocentrotus intermedius |   110 |  3 |  2 | Strongylocentrotus intermedius; Strongylocentrotus intermedius longispina |
| Acipenser oxyrhynchus |   109 |  3 |  2 | Acipenser oxyrinchus; Acipenser desotoi |
| Lymnaea palustris |   108 | 10 |  5 | Stagnicola palustris; Ladislavella terebra; Stagnicola saridalensis; Ladislavella elodes; Kazakhlymnaea taurica kazakensis |
| Navicula pelliculosa |   106 |  4 |  4 | Synedra minutissima var. pelliculosa; Navicula pelliculosa; Navicula pelliculosa var. ceylonica; Navicula pelliculosa var. pelliculosa |
| Caecidotea brevicauda |   105 |  3 |  3 | Caecidotea brevicauda; Caecidotea brevicauda bivittatus; Caecidotea brevicauda brevicauda |
| Lepidocephalichthys guntea |   104 |  2 |  1 | Lepidocephalichthys guntea |
| Neocaridina denticulata |   104 |  9 |  8 | Neocaridina denticulata; Neocaridina davidi; Neocaridina denticulata denticulata; Neocaridina koreana; Neocaridina linfenensis; Neocaridina luoyangensis; Neocaridina denticulata moganica; Neocaridina zhoushanensis |
| Balanus amphitrite |   102 |  4 |  3 | Amphibalanus amphitrite; Amphibalanus amphitrite amphitrite; Fistulobalanus pallidus |
| Macoma balthica |   102 |  2 |  1 | Macoma balthica |
| Platichthys flesus |   102 |  7 |  1 | Platichthys flesus |
| Cancer irroratus |   100 |  2 |  2 | Cancer plebejus; Cancer irroratus |
| Pomacea canaliculata |   100 |  2 |  1 | Pomacea canaliculata |
| Phormidium foveolarum |    99 |  2 |  2 | Leptolyngbya foveolarum; Phormidium foveolarum f. majus |
| Pacifastacus leniusculus |    98 |  2 |  1 | Pacifastacus leniusculus |
| Planorbella trivolvis |    98 |  3 |  3 | Planorbella trivolvis; Planorbella trivolvis intertextum; Planorbella trivolvis trivolvis |
| Synechococcus elongatus |    98 |  3 |  2 | Synechococcus elongatus; Thermostichus bigranulatus |
| Diplodus cervinus |    97 |  4 |  3 | Diplodus cervinus; Diplodus hottentotus; Diplodus omanensis |
| Nitzschia palea |    97 | 48 | 39 | Nitzschia palea; Nitzschia palea f. astriata; Nitzschia palea f. curta; Synedra dissipata var. dissipata; Nitzschia palea f. dubia; Synedra famelica var. famelica; Nitzschia palea f. genuina; Nitzschia palea f. major; Nitzschia palea f. minor; Nitzschia minuta f. minuta (+29 more) |
| Esomus danricus |    96 |  2 |  1 | Esomus danrica |
| Scenedesmus pannonicus |    96 |  2 |  2 | Desmodesmus pannonicus; Scenedesmus pannonicus var. papillatae |
| Acanthopagrus schlegelii |    94 |  3 |  1 | Acanthopagrus schlegelii |
| Lecane quadridentata |    94 |  4 |  2 | Lecane quadridentata; Lecane quadridentata f. grandis |
| Galaxias maculatus |    90 |  2 |  1 | Galaxias maculatus |
| Achnanthidium minutissimum |    89 |  7 |  6 | Achnanthes minutissima var. minutissima; Achnanthes minutissima var. inconspicua; Achnanthes affinis var. affinis; Microneis gracillima; Achnanthidium minutissimum var. jackii; Achnanthidium caledonicum |
| Haliotis rufescens |    88 |  2 |  1 | Haliotis rufescens |
| Nitzschia closterium |    88 | 12 | 10 | Nitzschia closterium; Ceratoneis closterium; Nitzschia closterium f. curvata; Nitzschia closterium f. minutissima; Nitzschia closterium f. tenuissima; Nitzschia closterium var. minutissima; Nitzschia closterium var. parva; Nitzschia closterium var. recta; Nitzschia closterium var. striatula; Nitzschia closterium var. tenuirostris |
| Fundulus diaphanus |    87 |  3 |  1 | Fundulus diaphanus |
| Xiphophorus helleri |    87 |  8 |  3 | Xiphophorus hellerii; Xiphophorus alvarezi; Xiphophorus signum |
| Actinonaias ligamentina |    86 |  2 |  1 | Ortmanniana ligamentina |
| Pinctada imbricata |    86 |  4 |  3 | Pinctada imbricata; Pinctada fucata; Pinctada radiata |
| Scenedesmus acuminatus |    84 | 15 | 11 | Tetradesmus lagerheimii; Scenedesmus falcatus f. globosus; Pectinodesmus javanensis; Scenedesmus acuminatus f. maximus; NA; Tetradesmus lagerheimii var. tetradesmoides; Pectinodesmus pectinatus f. tortuosus; Tetradesmus bernardii; Oedogonium punctatostriatum; Scenedesmus acuminatus var. inermius (+1 more) |
| Macrobrachium malcolmsonii |    82 |  3 |  3 | Macrobrachium malcolmsonii; Macrobrachium malcolmsonii kotreeanum; Macrobrachium malcolmsonii malcolmsonii |
| Tilapia aurea |    80 |  2 |  1 | Oreochromis aureus |
| Acipenser baerii |    79 |  5 |  1 | Acipenser baerii |
| Scenedesmus subspicatus |    79 |  4 |  4 | Desmodesmus subspicatus; Scenedesmus abundans var. brevicauda; Scenedesmus subspicatus var. crassicauda; NA |
| Dunaliella salina |    78 |  2 |  2 | Dunaliella salina; Dunaliella salina subsp. sibirica |
| Plationus patulus |    78 |  5 |  3 | Plationus patulus; Plationus patulus macracanthus; Plationus patulus var. macracanthus |
| Pila globosa |    77 |  3 |  1 | Pila globosa |
| Pseudorasbora parva |    77 |  3 |  1 | Pseudorasbora parva |
| Acartia clausi |    76 |  4 |  3 | Acartia (Acartiura) clausii; Acartia clausi gaboonensis; Acartia (Acartiura) hudsonica |
| Aplexa hypnorum |    76 |  6 |  2 | Aplexa hypnorum; Sibirenauta elongata |
| Anopheles gambiae |    75 |  2 |  2 | Anopheles gambiae; Anopheles gambiae var. melas |
| Euchlanis dilatata |    75 |  9 |  2 | Euchlanis dilatata; Euchlanis dilatata lucksiana |
| Scenedesmus armatus |    75 | 26 | 25 | Desmodesmus armatus; Scenedesmus armatus f. bicauda; Scenedesmus armatus f. bicaudatus; Scenedesmus armatus f. brevicaudatus; Scenedesmus armatus f. deflexus; Scenedesmus armatus f. semicostatus; Scenedesmus armatus f. simplex; Desmodesmus armatus var. asymetricus; Scenedesmus armatus var. bajaensis; Desmodesmus armatus var. bicaudatus (+15 more) |
| Pleuronectes platessa |    74 |  2 |  1 | Pleuronectes platessa |
| Chlorella sp |    73 |  2 |  2 | Droopiella spaerckii; Jaagichlorella sphaerica |
| Fucus vesiculosus |    73 | 47 |  7 | Fucus vesiculosus; Fucus vesiculosus f. gracillimus; Fucus vesiculosus var. linearis; Fucus vesiculosus f. mytili; Fucus spiralis; Fucus vesiculosus f. volubilis; Fucus vesiculosus var. compressus |
| Oncorhynchus clarki |    73 | 11 |  1 | Oncorhynchus clarkii |
| Notropis atherinoides |    71 |  4 |  1 | Notropis atherinoides |
| Mya arenaria |    70 |  5 |  3 | Mya arenaria; Mya baxteri; Mya truncata |
| Notodiaptomus conifer |    70 |  2 |  2 | Notodiaptomus conifer; Notodiaptomus coniferoides |
| Champia parvula |    69 |  4 |  4 | Champia parvula; Champia parvula var. amphibolis; Champia parvula var. prostrata; Champia parvula var. vaga |
| Lebistes reticulatus |    69 |  2 |  2 | Poecilia reticulata; Lebistes reticulatus aurata |
| Mysis oculata |    69 |  2 |  2 | Mysis oculata; Mysis relicta |
| Pomatoschistus microps |    69 |  3 |  2 | Pomatoschistus microps; Pomatoschistus marmoratus |
| Brachionus angularis |    68 | 24 |  8 | Brachionus angularis; Brachionus angularis bidens; Brachionus dolabratus; Brachionus pseudodolabratus; Brachionus murphyi; Brachionus caudatus; Brachionus angularis var. bidens; Brachionus chelonis |
| Ictalurus melas |    68 |  2 |  1 | Ameiurus melas |
| Lampsilis cardium |    68 |  4 |  2 | Lampsilis cardium; Lampsilis satura |
| Salvelinus alpinus |    68 |  9 |  6 | Salvelinus alpinus; Salvelinus faroensis; Salvelinus malma; Salvelinus alpinus oquassa; Salvelinus taranetzi; Salvelinus youngeri |
| Gracilaria tenuistipitata |    67 |  3 |  3 | Gracilaria tenuistipitata; Gracilaria tenuistipitata var. liui; Gracilaria tenuistipitata var. tenuistipitata |
| Philodina roseola |    67 |  4 |  3 | Philodina roseola; Philodina roseola var. glacialis; Philodina roseola var. nivalis |
| Physa gyrina |    67 | 13 |  2 | Physella gyrina; Physella latchfordi |
| Silurus glanis |    67 |  2 |  1 | Silurus glanis |
| Daphnia sp |    66 |  3 |  3 | Daphnia (Daphnia) hyalina; Scapholeberis spinifera; Daphnia spinosa |
| Diopatra neapolitana |    66 |  3 |  3 | Diopatra neapolitana; Diopatra neapolitana capensis; Diopatra khargiana |
| Hoplias malabaricus |    66 |  3 |  3 | Hoplias malabaricus; Hoplias lacerdae; Hoplias macrophthalmus |
| Hyas araneus |    66 |  2 |  1 | Hyas araneus |
| Sepia officinalis |    65 |  5 |  4 | Sepia officinalis; Sepia hierredda; Sepioteuthis sepioidea; Sepia vermiculata |
| Cladophora glomerata |    64 | 49 | 25 | Cladophora glomerata; Cladophora glomerata f. boreali-americana; Cladophora glomerata var. crassior; Cladophora glomerata f. callicoma; NA; Cladophora glomerata f. cartilaginea; Cladophora glomerata f. declinata; Cladophora glomerata f. fasciculata; Cladophora glomerata f. flavescens; Cladophora glomerata f. glomerata (+15 more) |
| Gammarus minus |    64 |  2 |  2 | Gammarus minus; Gammarus minus var. tenuipes |
| Hormosira banksii |    64 |  2 |  1 | Hormosira banksii |
| Zostera marina |    64 |  3 |  1 | Zostera marina |
| Arbacia lixula |    63 |  4 |  3 | Arbacia lixula; Arbacia lixula africana; Arbacia lixula lixula |
| Chaetoceros gracilis |    63 |  3 |  2 | Chaetoceros neogracilis; Chaetoceros gracilis |
| Chlorella fusca |    63 |  3 |  3 | Desmodesmus abundans; Halochlorella rubescens; Coelastrella vacuolata |
| Coretus corneus |    63 |  3 |  1 | Planorbarius corneus |
| Ulnaria ulna |    63 | 10 | 10 | Synedra ulna var. subcontracta; Ulnaria ulna var. acus; Frustulia aequalis; Synedra amphirhynchus var. amphirhynchus; Ulnaria ulna var. chaseana; Ulnaria ulna var. constricta; Synedra notata; Synedra spathulifera; Frustulia splendens; Synedra subaequalis f. subaequalis |
| Meretrix meretrix |    62 |  8 |  4 | Meretrix meretrix; Meretrix aurora; Meretrix attenuata; Meretrix lamarckii |
| Spirulina platensis |    62 |  3 |  3 | Arthrospira platensis; Arthrospira platensis var. non-constricta; Spirulina platensis var. tenuis |
| Chlorolobion braunii |    61 |  2 |  2 | Chlorolobion braunii; Chlorolobion braunii var. pusilla |
| Tilapia nilotica |    61 |  9 |  5 | Oreochromis niloticus; Oreochromis spilurus; Oreochromis aureus; Oreochromis rukwaensis; Oreochromis upembae |
| Caridina nilotica |    60 | 16 | 13 | Caridina nilotica; Caridina elongapoda; Caridina macrophora; Caridina aruensis; Caridina meridionalis; Caridina gracilipes; Caridina brachydactyla; Caridina brevidactyla; Caridina chauhani; Caridina wyckii (+3 more) |
| Gomphonema parvulum |    60 | 39 | 35 | Gomphonema parvulum; Gomphonema parvulum f. affine; Gomphonema parvulum f. astigma; Gomphonema parvulum f. bacillum; Gomphonema parvulum f. elongata; Gomphonema parvulum f. fossilis; Gomphonema parvulum f. genuinum; Gomphonema lagenula var. lagenula; Gomphonema parvulum var. lanceolata; Gomphonema micropus f. micropus (+25 more) |
| Musculium transversum |    60 |  2 |  1 | Sphaerium transversum |
| Zostera muelleri |    60 |  6 |  5 | Zostera muelleri; Zostera capricorni; Zostera mucronata; Zostera muelleri subsp. novazelandica; Zostera novazelandica |
| Neogobius melanostomus |    59 |  2 |  1 | Neogobius melanostomus |
| Chlorella saccharophila |    58 |  2 |  2 | Chloroidium saccharophilum; Chloroidium ellipsoideum |
| Daphnia cucullata |    58 |  2 |  2 | Daphnia cucullata; Daphnia cucullata cucullata |
| Dugesia lugubris |    58 |  2 |  2 | Schmidtea lugubris; Dugesia lugubris wytegrensis |
| Engraulis mordax |    58 |  2 |  1 | Engraulis mordax |
| Melanoides tuberculata |    57 |  4 |  3 | Melanoides tuberculata; NA; Melanoides tuberculata tuberculata |
| Unio pictorum |    57 | 14 |  3 | Unio pictorum; Nodularia douglasiae; Unio elongatulus |
| Acipenser ruthenus |    56 | 19 |  1 | Acipenser ruthenus |
| Babylonia areolata |    56 |  6 |  5 | Babylonia areolata; Babylonia areolata areolata; Babylonia areolata aurantiaca; Babylonia areolata candida; Babylonia areolata multilineata |
| Branchiostoma belcheri |    56 |  3 |  2 | Branchiostoma belcheri; Branchiostoma japonicum |
| Poeciliopsis occidentalis |    56 |  3 |  2 | Poeciliopsis occidentalis; Poeciliopsis sonoriensis |
| Scrobicularia plana |    56 |  4 |  1 | Scrobicularia plana |
| Argopecten irradians |    55 |  6 |  5 | Argopecten irradians; Argopecten irradians amplicostatus; Argopecten irradians concentricus; Argopecten irradians irradians; Argopecten irradians sablensis |
| Calothrix brevissima |    55 |  2 |  2 | Calothrix brevissima; Calothrix brevissima var. moniliformis |
| Rasbora daniconius |    55 |  3 |  2 | Rasbora daniconius; Rasbora labiosa |
| Elliptio complanata |    54 |  3 |  1 | Elliptio complanata |
| Fucus serratus |    54 | 13 |  1 | Fucus serratus |
| Hypomesus transpacificus |    54 |  3 |  2 | Hypomesus transpacificus; Hypomesus nipponensis |
| Idotea balthica |    54 |  4 |  1 | Idotea balthica |
| Lecane luna |    54 | 18 |  8 | Lecane luna; Lecane papuana; Lecane lunaris; Lecane acus; Lecane obtusa; Lecane crenata; Lecane perplexa; Lecane lunaris virga |
| Prorocentrum minimum |    54 |  2 |  1 | Prorocentrum cordatum |
| Pyropia yezoensis |    54 |  2 |  2 | Pyropia yezoensis; Pyropia yezoensis f. narawaensis |
| Karenia brevis |    53 |  2 |  2 | Karenia brevis; Karenia brevisulcata |
| Keratella americana |    52 |  4 |  2 | Keratella americana; Keratella nhamundaiensis |
| Etheostoma spectabile |    51 |  4 |  3 | Etheostoma spectabile; Etheostoma fragi; Etheostoma uniporum |
| Keratella quadrata |    51 | 28 | 12 | Keratella quadrata; Keratella australis; Keratella quadrata dispersa; Keratella testudo; Keratella quadrata f. valgoides; Keratella quadrata jakutica; Keratella ticinensis; Keratella edmondsoni; Keratella zhugeae; Keratella tropica (+2 more) |
| Palaemon longirostris |    51 |  2 |  1 | Palaemon longirostris |
| Phoxinus phoxinus |    51 |  6 |  4 | Phoxinus phoxinus; Phoxinus colchicus; Phoxinus strandjae; Phoxinus ujmonensis |
| Aphanizomenon flos-aquae |    50 | 10 |  5 | Aphanizomenon flos-aquae; Aphanizomenon gracile; Aphanizomenon flos-aquae f. incurvatum; Aphanizomenon klebahnii; Aphanizomenon flos-aquae f. macrosporum |
| Channa argus |    50 |  3 |  1 | Channa argus |
| Metapenaeus ensis |    50 |  2 |  1 | Metapenaeus ensis |
| Biomphalaria tenagophila |    49 |  4 |  4 | Biomphalaria tenagophila; Biomphalaria tenagophila guaibensis; Biomphalaria occidentalis; Biomphalaria tenagophila tenagophila |
| Laminaria saccharina |    48 | 31 |  8 | Saccharina latissima; Laminaria saccharina f. agardhi; Laminaria longipes f. angustifolia; Saccharina complanata; Himantothallus grandifolius; NA; Laminaria saccharina var. viridissima; Laminaria saccharina var. vittata |
| Nuria danrica |    48 |  4 |  3 | Esomus danrica; Esomus altus; Esomus malayensis |
| Didymosphenia geminata |    47 | 16 | 16 | Didymosphenia geminata; Didymosphenia geminata f. anomala; Didymosphenia geminata f. baicalensis; Didymosphenia geminata f. capitata; Didymosphenia geminata f. curta; Didymosphenia geminata f. curvata; Didymosphenia geminata f. elongata; Didymosphenia geminata f. genuina; Didymosphenia geminata f. subcapitata; Didymosphenia geminata var. baicalensis (+6 more) |
| Scenedesmus abundans |    47 |  9 |  9 | Desmodesmus abundans; Desmodesmus asymmetricus; Desmodesmus subspicatus var. bicaudatus; Scenedesmus abundans var. brevicauda; Scenedesmus abundans var. indica; Scenedesmus abundans var. longicauda; Scenedesmus fuscus var. peruvianus; Scenedesmus abundans var. skujae; Desmodesmus subspicatus |
| Zostera capricorni |    47 |  2 |  1 | Zostera capricorni |
| Ameiurus nebulosus |    46 |  2 |  1 | Ameiurus nebulosus |
| Strombus gigas |    46 |  2 |  1 | Aliger gigas |
| Leuciscus cephalus |    45 | 18 |  4 | Squalius cephalus; Squalius moreoticus; Squalius prespensis; Squalius vardarensis |
| Scyliorhinus canicula |    45 |  2 |  1 | Scyliorhinus canicula |
| Cyprinella lutrensis |    44 |  2 |  1 | Cyprinella lutrensis |
| Metapenaeus dobsoni |    44 |  2 |  1 | Metapenaeus dobsoni |
| Pandalus montagui |    44 |  2 |  2 | Pandalus montagui; Pandalus tridens |
| Valvata piscinalis |    44 | 14 |  8 | Valvata piscinalis; Valvata annandalei; Valvata kukunorica; Valvata piscinalis discors; Valvata alpestris; Valvata piscinalis piscinalis; Valvata simusyuensis; NA |
| Donax faba |    43 |  2 |  2 | Latona faba; Donax semistriatus |
| Unio tumidus |    43 | 21 |  3 | Unio tumidus; Unio crassus; Anodonta cygnea |
| Cyclops viridis |    42 | 11 |  8 | Megacyclops viridis viridis; Cyclops viridis acutulus; Acanthocyclops americanus americanus; Acanthocyclops robustus robustus; Cyclops viridis europaeus; Megacyclops gigas gigas; Acanthocyclops insectus; Cyclops viridis ochridensis |
| Cylindrotheca closterium |    42 |  3 |  3 | Cylindrotheca closterium; Nitzschiella californica; Ceratoneis closterium |
| Littorina littorea |    42 | 22 |  1 | Littorina littorea |
| Melosira varians |    42 |  9 |  7 | Melosira varians; Melosira aequalis; Melosira varians var. genuina; Melosira varians var. moniliformis; Melosira varians var. orichalcea; Melosira subflexilis; Melosira varians var. varians |
| Campostoma anomalum |    41 |  3 |  3 | Campostoma anomalum; Campostoma oligolepis; Campostoma pullum |
| Heterosigma akashiwo |    41 |  3 |  3 | Heterosigma akashiwo; Heterosigma akashiwo RNA virus; Heterosigma akashiwo virus 01 |
| Physa fontinalis |    41 | 11 |  1 | Physa fontinalis |
| Potamopyrgus jenkinsi |    40 |  2 |  1 | Potamopyrgus antipodarum |
| Stichococcus bacillaris |    40 |  2 |  2 | Stichococcus bacillaris; NA |
| Thalassoma pavo |    39 |  4 |  1 | Thalassoma pavo |
| Planorbella pilsbryi |    38 |  3 |  3 | Planorbella pilsbryi; Planorbella pilsbryi infracarinatum; Planorbella pilsbryi pilsbryi |
| Chlamydomonas oblonga |    37 |  2 |  1 | Chlamydomonas oblonga |
| Mayamaea fossalis |    37 |  2 |  2 | Navicula fossalis f. fossalis; Navicula obsidialis |
| Parreysia favidens |    37 |  2 |  2 | Parreysia corrugata; Parreysia marcens |
| Pyrocystis lunula |    37 |  2 |  2 | Pyrocystis lunula; Pyrocystis robusta |
| Scenedesmus dimorphus |    37 |  5 |  5 | Tetradesmus dimorphus; Tetradesmus obliquus; Scenedesmus dimorphus f. minor; Scenedesmus dimorphus f. tortus; Scenedesmus dimorphus var. longispina |
| Scenedesmus obtusus |    37 |  8 |  6 | Scenedesmus obtusus; NA; Scenedesmus obtusus f. disciformis; Scenedesmus obtusus f. ecornis; Scenedesmus obtusus var. apiculatus; Scenedesmus obtusus var. ecornis |
| Chlamydomonas moewusii |    36 |  5 |  5 | Chlamydomonas moewusii; Chlamydomonas moewusii var. microstigmata; Chlamydomonas moewusii var. eumetabletos; Chlamydomonas moewusii var. major; NA |
| Ecklonia cava |    36 |  2 |  2 | Ecklonia cava; Ecklonia cava subsp. kurome |
| Lytechinus variegatus |    36 |  8 |  4 | Lytechinus variegatus; Lytechinus variegatus variegatus; Lytechinus variegatus carolinus; Lytechinus variegatus pallidus |
| Microcystis wesenbergii |    36 |  2 |  2 | Microcystis wesenbergii; Sphinctosiphon polymorphus |
| Stizostedion vitreum |    36 |  3 |  1 | Sander vitreus |
| Coregonus fera |    35 |  2 |  2 | Coregonus fera; Coregonus pidschian |
| Crangon franciscorum |    35 |  3 |  3 | Crangon franciscorum; Crangon franciscorum angustimana; Crangon franciscorum franciscorum |
| Geophagus brasiliensis |    35 |  4 |  3 | Geophagus brasiliensis; Geophagus iporangensis; Geophagus itapicuruensis |
| Solea senegalensis |    35 |  2 |  2 | Solea senegalensis; Dicologlossa cuneata |
| Stenocypris major |    35 |  2 |  2 | Stenocypris major; Stenocypris major major |
| Tilapia guineensis |    35 |  2 |  1 | Coptodon guineensis |
| Tilapia sp |    35 | 12 |  6 | Tilapia sparrmanii; Coptodon zillii; Astatotilapia bloyeti; Tilapia spilurus; Oreochromis spilurus; Coptodon spongotroktis |
| Tympanotonus fuscatus |    35 |  2 |  1 | Tympanotonos fuscatus |
| Dorosoma cepedianum |    34 |  2 |  1 | Dorosoma cepedianum |
| Elimia livescens |    34 |  3 |  3 | Elimia livescens; Elimia livescens haldemani; Elimia livescens livescens |
| Lecane hamata |    34 |  4 |  1 | Lecane hamata |
| Nereis virens |    34 |  2 |  2 | Alitta virens; Alitta plenidentata |
| Osmerus mordax |    34 |  3 |  2 | Osmerus mordax; Osmerus dentex |
| Aphyocypris chinensis |    33 |  3 |  1 | Aphyocypris chinensis |
| Ascophyllum nodosum |    33 | 11 |  3 | Ascophyllum nodosum; Ascophyllum nodosum f. mackayi; Ascophyllum nodosum f. scorpioides |
| Bufo bufo |    33 |  2 |  2 | Bufo bufo; Bufo gargarizans |
| Bulinus truncatus |    33 |  5 |  5 | Bulinus truncatus; Bulinus truncatus contortus; Bulinus truncatus randabeli; Bulinus truncatus rivularis; Bulinus truncatus truncatus |
| Coregonus lavaretus |    33 | 44 | 19 | Coregonus lavaretus; Coregonus megalops; Coregonus baerii; Coregonus baicalensis; Coregonus baunti; Coregonus maraena; Coregonus pallasii; Coregonus nilssoni; Coregonus hoferi; NA (+9 more) |
| Etheostoma caeruleum |    33 |  2 |  1 | Etheostoma caeruleum |
| Palaemonetes varians |    33 |  6 |  3 | Palaemon varians; Palaemon mesogenitor; Palaemon antennarius |
| Planothidium lanceolatum |    33 |  8 |  8 | Planothidium lanceolatum; Achnanthes lanceolata var. ventricosa; Achnanthes lanceolata subsp. robusta; Planothidium lanceolatum var. bimaculatum; Achnanthes lanceolata var. elliptica; Planothidium lanceolatum var. genuinum; Planothidium haynaldii; Planothidium lanceolatum var. omissum |
| Schistosoma mansoni |    33 |  2 |  2 | Schistosoma mansoni; Schistosoma mansoni var. rodentorum |
| Tolypothrix tenuis |    33 |  6 |  6 | Tolypothrix tenuis; Tolypothrix lanata; Tolypothrix tenuis f. terrestris; Tolypothrix calcarata; NA; Tolypothrix tenuis var. pygmaea |
| Austropotamobius pallipes |    32 |  4 |  3 | Austropotamobius pallipes; Cambaroides schrenckii; Austropotamobius fulcisianus fulcisianus |
| Encyonema silesiacum |    32 | 10 | 10 | Cymbella silesiaca; Encyonema silesiacum var. altensis; Encyonema silesiacum var. distigmata; Encyonema silesiacum var. distinctepunctata; Encyonema silesiacum var. elegans; Encyonema silesiacum var. excisa; Encyonema silesiacum var. latarea; Encyonema silesiacum var. latistriata; Encyonema silesiacum var. latum; Encyonema silesiacum var. ventriformis |
| Haliotis rubra |    32 |  3 |  3 | Haliotis rubra; Haliotis rubra conicopora; Haliotis rubra rubra |
| Polycelis felina |    32 |  6 |  6 | Polycelis felina; Polycelis felina borellii; Polycelis felina brunnea; Polycelis felina felina; Ijimia lomensis; Polycelis felina viganensis |
| Bellamya bengalensis |    31 |  4 |  1 | Filopaludina bengalensis |
| Bithynia tentaculata |    31 |  5 |  3 | Bithynia tentaculata; Bithynia tentaculata tentaculata; Digoniostoma kashmirense |
| Labeo niloticus |    31 |  2 |  2 | Labeo niloticus; Labeo senegalensis |
| Oscillatoria agardhii |    31 |  9 |  4 | Planktothrix agardhii; Planktothrix mougeotii; Planktothrix isothrix; Planktothrix suspensa |
| Penaeus semisulcatus |    31 |  3 |  2 | Penaeus (Eopenaeus) semisulcatus; Penaeus (Penaeus) monodon |
| Unio elongatulus |    31 |  5 |  3 | Unio elongatulus; Unio dembeae; Unio durieui |
| Acanthomysis sculpta |    30 |  2 |  2 | Holmesimysis sculpta; Holmesimysis nuda |
| Brachionus rubens |    30 |  2 |  2 | Brachionus rubens; Brachionus urceolaris |
| Crepidula fornicata |    30 |  3 |  3 | Crepidula fornicata; Crepidula cruzana; Crepidula porcellana |
| Limnoperna fortunei |    30 |  2 |  2 | Limnoperna fortunei; Xenostrobus securis |
| Nannochloropsis oceanica |    30 |  2 |  2 | Nannochloropsis oceanica; Nannochloropsis oceanica var. sinensis |
| Chlamydomonas noctigama |    29 |  5 |  5 | Chlamydomonas noctigama; Chlamydomonas noctigama var. ellipsoidea; Chlamydomonas noctigama var. eupapillata; Chlamydomonas noctigama var. hyperpyrenoidosa; Chlamydomonas noctigama var. minor |
| Chlorella ellipsoidea |    29 |  3 |  3 | Chloroidium ellipsoideum; Chlorella ellipsoidea f. antarctica; Chlorella ellipsoidea var. minor |
| Clupea pallasii |    29 |  4 |  1 | Clupea pallasii |
| Cyprinodon bovinus |    29 |  2 |  2 | Cyprinodon bovinus; Cyprinodon rubrofluviatilis |
| Lessonia nigrescens |    29 |  3 |  2 | Lessonia nigrescens; Lessonia flavicans |
| Nitzschia pungens |    29 |  5 |  5 | Nitzschia pungens; Nitzschia pungens f. multiseries; Nitzschia pungens var. atlantica; Nitzschia pungens var. genuina; Nitzschia pungens var. pungens |
| Oocystis submarina |    29 |  3 |  3 | Oocystis submarina; NA; Oocystis submarina var. variabilis |
| Pseudanabaena galeata |    29 |  2 |  1 | Pseudanabaena galeata |
| Aequipecten tehuelchus |    28 |  3 |  3 | Aequipecten tehuelchus; Aequipecten tehuelchus madrynensis; Aequipecten tehuelchus tehuelchus |
| Amphidinium operculatum |    28 | 11 |  7 | Amphidinium herdmanii; Amphidinium operculatum; Amphidinium operculatum f. minutum; Amphidinium discoidale; Amphidinium emarginatum; Amphidinium gibbosum; Amphidinium steinii |
| Anuraeopsis fissa |    28 | 11 | 10 | Anuraeopsis fissa; Anuraeopsis fissa beauchampi; Anuraeopsis cristata; Anuraeopsis fissa donghuensis; Anuraeopsis fissa haueri; Anuraeopsis coelata; Anuraeopsis fissa neali; Anuraeopsis fissa pejleri; Anuraeopsis fissa pseudonavicula; Anuraeopsis urawensis |
| Halophila ovalis |    28 |  6 |  5 | Halophila ovalis; Halophila australis; Halophila hawaiiana; Halophila major; Halophila minor |
| Nerita albicilla |    28 |  2 |  1 | Nerita albicilla |
| Puntius stigma |    28 |  2 |  2 | Puntius stigma; Barbodes aurotaeniatus |
| Rana pipiens |    28 |  2 |  2 | Lithobates pipiens; Lithobates sphenocephalus |
| Elimia catenaria |    27 |  2 |  1 | Elimia catenaria |
| Lota lota |    27 |  8 |  1 | Lota lota |
| Stephanodiscus hantzschii |    27 |  9 |  9 | Stephanodiscus hantzschii; Stephanodiscus hantzschii f. hantzschii; Stephanodiscus hantzschii f. major; Stephanodiscus hantzschii f. parva; Stephanodiscus tenuis var. tenuis; Stephanodiscus hantzschii var. delicatula; Stephanodiscus hantzschii var. pusillus; Stephanodiscus hantzschii var. striatior; Stephanodiscus hantzschii var. tenuis |
| Abramis brama |    26 |  5 |  1 | Abramis brama |
| Acropora tenuis |    26 |  3 |  3 | Acropora tenuis; Acropora divaricata; Acropora tenuissima |
| Cyclops strenuus |    26 | 20 | 17 | Cyclops strenuus strenuus; Cyclops abyssorum abyssorum; Cyclops strenuus corsicana; Cyclops divergens; Cyclops strenuus divulsus; Cyclops gracilipes; Cyclops abyssorum laevis; Cyclops landei; Cyclops strenuus mauritaniae; Cyclops ochridanus (+7 more) |
| Dilocarcinus pagei |    26 |  3 |  2 | Dilocarcinus pagei; Dilocarcinus cristatus |
| Elasmopus rapax |    26 |  5 |  5 | Elasmopus rapax; Elasmopus barbatus; Elasmopus mutatus; Elasmopus serricatus; Elasmopus dentipalmus |
| Gammarus duebeni |    26 |  2 |  2 | Gammarus duebeni; Gammarus wilkitzkii |
| Huso huso |    26 |  5 |  1 | Acipenser huso |
| Panopeus herbstii |    26 |  5 |  4 | Panopeus herbstii; Panopeus simpsoni; Panopeus lacustris; Panopeus obesus |
| Thymallus thymallus |    26 |  3 |  1 | Thymallus thymallus |
| Closterium ehrenbergii |    25 | 31 | 28 | Closterium ehrenbergii; NA; Closterium ehrenbergii f. attenuatum; Closterium ehrenbergii f. colorato; Closterium ehrenbergii f. curtum; Closterium ehrenbergii f. elevatum; Closterium ehrenbergii f. grande; Closterium ehrenbergii f. magnum; Closterium submoniliferum var. malinvernianum; Closterium ehrenbergii f. percrassum (+18 more) |
| Encyonema gracile |    25 |  9 |  8 | Encyonema gracile; Encyonema gracile f. minor; Encyonema gracile var. genuinum; Encyonema gracile var. lunata; Cymbella lunata; Encyonema gracile var. minor; Cymbella scotica; Encyonema gracile var. undulatum |
| Lecane lunaris |    25 | 12 |  6 | Lecane lunaris; Lecane acus; Lecane obtusa; Lecane crenata; Lecane perplexa; Lecane lunaris virga |
| Margaritifera margaritifera |    25 |  7 |  5 | Margaritifera margaritifera; Pinctada margaritifera; Margaritifera falcata; NA; Pinctada persica |
| Obliquaria reflexa |    25 |  3 |  1 | Obliquaria reflexa |
| Oreochromis spilurus |    25 |  4 |  1 | Oreochromis spilurus |
| Pediastrum duplex |    25 | 48 | 22 | Pediastrum duplex; NA; Pediastrum duplex f. clathratum; Pediastrum duplex var. cohaerens; Pediastrum duplex f. denticulatum; Pediastrum duplex f. nagdaense; Pediastrum duplex var. punctatum; Pediastrum duplex var. recurvatum; Pediastrum duplex f. reticulatum; Pediastrum duplex var. asperum (+12 more) |
| Cyprinodon macularius |    24 |  6 |  3 | Cyprinodon macularius; Crenichthys baileyi; Cyprinodon eremus |
| Echinoparyphium recurvatum |    24 |  4 |  4 | Echinoparyphium recurvatum; Echinoparyphium recurvatum circi; Echinoparyphium recurvatum indiana; Echinoparyphium recurvatum vanelli |
| Lepadella patella |    24 | 12 |  5 | Lepadella patella; Lepadella patella oblonga; Lepadella patella matudai; Lepadella patella persimilis; Lepadella biloba |
| Polycelis tenuis |    24 |  2 |  2 | Polycelis tenuis; Polycelis tenuis altaica |
| Scardinius erythrophthalmus |    24 |  8 |  3 | Scardinius erythrophthalmus; Scardinius elmaliensis; Scardinius scardafa |
| Scenedesmus bijugatus |    24 | 20 | 18 | Tetradesmus obliquus; Scenedesmus arcuatus; NA; Scenedesmus bijugus var. irregularis; Scenedesmus bijugatus f. major; Verrucodesmus parvus; Scenedesmus bijugatus var. alternans; Comasiella arcuata; Desmodesmus bicellularis; Scenedesmus bijugatus var. clathratus (+8 more) |
| Spisula solidissima |    24 |  2 |  1 | Spisula solidissima |
| Staurastrum cristatum |    24 |  7 |  7 | Staurastrum cristatum; Staurastrum cristatum f. reinschii; Staurastrum cristatum var. cristatum; Staurastrum cristatum var. cuneatum; Staurastrum cristatum var. japonicum; Staurastrum cristatum var. navigiolum; Staurastrum cristatum var. oligacanthum |
| Tripneustes gratilla |    24 |  4 |  3 | Tripneustes gratilla; Tripneustes gratilla elatensis; Tripneustes gratilla gratilla |
| Alona sp |    23 |  3 |  3 | Alona sphagnophila; Alona affinis; Alona guttata |
| Chlamydomonas eugametos |    23 |  3 |  3 | Chlamydomonas moewusii; Chlamydomonas sphagnophila var. indica; Chlamydomonas eugametos var. moewusii |
| Ditylum brightwellii |    23 |  9 |  8 | Ditylum brightwellii; Ditylum brightwellii f. biangulata; Ditylum brightwellii f. pentagona; Ditylum brightwellii var. tetragona; Ditylum brightwellii var. brightwellii; Ditylum brightwellii var. inaequalis; NA; Ditylum brightwellii var. trigona |
| Etheostoma nigrum |    23 |  2 |  1 | Etheostoma nigrum |
| Eurythoe complanata |    23 |  2 |  2 | Eurythoe complanata; Eurythoe complanata mexicana |
| Fucus virsoides |    23 |  3 |  1 | Fucus virsoides |
| Hormidium flaccidum |    23 |  4 |  4 | Klebsormidium flaccidum; Klebsormidium mucosum; Hormidium flaccidum f. cryophila; Klebsormidium dissectum |
| Tilapia melanopleura |    23 |  3 |  2 | Coptodon zillii; Coptodon rendalli |
| Uca pugnax |    23 |  2 |  2 | Minuca pugnax; Minuca rapax |
| Aphanius dispar |    22 |  5 |  3 | Aphaniops dispar; Aphaniops richardsoni; Aphaniops stoliczkanus |
| Bugula neritina |    22 |  7 |  6 | Bugula neritina; Bugula neritina var. fastigiata; Bugula minima; Bugula ramosa; Bugula robusta; Dendrobeania sessilis |
| Mesocyclops leuckarti |    22 | 13 | 10 | Mesocyclops (Mesocyclops) leuckarti leuckarti; Mesocyclops aequatorialis aequatorialis; Mesocyclops leuckarti arakhlensis; Mesocyclops australiensis; Mesocyclops leuckarti deccanensis; Mesocyclops (Neomesocyclops) edax; Mesocyclops leuckarti fortii; Mesocyclops mongoliensis; Mesocyclops pilosus; Mesocyclops annulatus annulatus |
| Mesocyclops longisetus |    22 |  4 |  3 | Mesocyclops longisetus longisetus; Mesocyclops araucanus; Mesocyclops longisetus curvatus |
| Navicula incerta |    22 |  6 |  6 | Navicula salinicola; Navicula incerta; Navicula incerta f. asiatica; Navicula incerta f. incerta; NA; Navicula incertata |
| Navicula seminulum |    22 | 18 | 15 | Sellaphora saugerresii; Navicula seminulum; Navicula seminulum f. major; Navicula seminulum f. seminulum; Navicula seminulum var. bergii; Navicula seminulum var. brevis; Navicula seminulum var. capitata; Navicula seminulum var. densestriata; Navicula seminulum var. fragilarioides; Navicula seminulum var. genuina (+5 more) |
| Platichthys stellatus |    22 |  2 |  1 | Platichthys stellatus |
| Plecostomus commersoni |    22 |  4 |  2 | Hypostomus commersoni; Hypostomus scabriceps |
| Acropora formosa |    21 |  3 |  1 | Acropora muricata |
| Chlamydomonas sp |    21 | 16 | 15 | Chlamydomonas speciosa; Chlamydomonas sphaerica; Chlamydomonas sphaeroides; Chlamydomonas sphaeroides f. maior; Chlamydomonas sphagnicola; Chlamydomonas sphagnophila; Chlamydomonas sphagnophila var. dysosmos; Chlamydomonas sphagnophila var. indica; Chlamydomonas spinifera; Chloromonas spirochloris (+5 more) |
| Diaptomus gracilis |    21 |  5 |  5 | Eudiaptomus gracilis gracilis; Eudiaptomus gracilis aemilianus; Copidodiaptomus steueri; Eudiaptomus gracilis ligustica; Diaptomus gracilis minutus |
| Donax trunculus |    21 |  7 |  2 | Donax trunculus; Donax vittatus |
| Echinometra mathaei |    21 |  4 |  4 | Echinometra mathaei; Echinometra mathaei mathaei; Echinometra oblonga; Echinometra mathaei violacea |
| Fragilaria capucina |    21 | 43 | 35 | Synedra amphicephala var. amphicephala; Fragilaria capucina; Fragilaria capucina f. acuta; Fragilaria capucina f. capucina; Fragilaria capucina f. caudata; Fragilaria capucina f. continua; Fragilaria capucina f. distans; Fragilaria capucina f. genuina; Fragilaria capucina var. lanceolata; Fragilaria capucina f. lanceolata-baikali (+25 more) |
| Helisoma trivolvis |    21 |  5 |  1 | Planorbella trivolvis |
| Paramecium bursaria |    21 | 18 | 18 | Paramecium bursaria; Paramecium bursaria Chlorella virus 1; Paramecium bursaria Chlorella virus A1; Paramecium bursaria Chlorella virus AL1A; Paramecium bursaria Chlorella virus AL2A; Paramecium bursaria Chlorella virus BJ2C; Paramecium bursaria Chlorella virus CA4A; Paramecium bursaria Chlorella virus CA4B; Paramecium bursaria Chlorella virus IL3A; Paramecium bursaria Chlorella virus NC1A (+8 more) |
| Planorbella campanulata |    21 |  3 |  3 | Planorbella campanulata; Planorbella campanulata campanulata; Planorbella campanulata collinsi |
| Platynereis dumerilii |    21 |  5 |  5 | Platynereis dumerilii; Platynereis bicanaliculata; Platynereis antipoda; Platynereis dumerilii comata; Platynereis dumerilii ocellata |
| Proasellus coxalis |    21 | 20 | 19 | Proasellus coxalis coxalis; Proasellus coxalis africanus; Proasellus coxalis aoualensis; Proasellus coxalis banyulensis; Proasellus coxalis cephallenus; Proasellus coxalis corcyraeus; Proasellus coxalis cyanophilus; Proasellus coxalis cyrenaicus; Proasellus coxalis epiroticus; Proasellus coxalis italicus (+9 more) |
| Scapholeberis kingi |    21 |  2 |  2 | Scapholeberis kingi; Scapholeberis kingii |
| Synechocystis aquatilis |    21 |  2 |  2 | Synechocystis aquatilis; NA |
| Aequipecten opercularis |    20 |  2 |  2 | Aequipecten opercularis; Aequipecten opercularis opercularis |
| Capoeta capoeta |    20 | 10 |  7 | Capoeta capoeta; Capoeta aculeata; Capoeta bergamae; Capoeta damascina; Capoeta gracilis; Capoeta kosswigi; Capoeta sevangi |
| Cephalodella gibba |    20 |  2 |  1 | Cephalodella gibba |
| Chroococcus minor |    20 |  2 |  2 | Chroococcus minor; Chroococcus dispersus |
| Coelastrum microporum |    20 |  6 |  6 | Coelastrum microporum; Coelastrum astroideum; Coelastrum microporum f. irregulare; Coelastrum microporum var. octaëdricum; Coelastrum microporum var. ovale; Coelastrum speciosum |
| Esox masquinongy |    20 |  2 |  1 | Esox masquinongy |
| Keratella tropica |    20 |  6 |  2 | Keratella tropica; Keratella tropica aspina |
| Neopanope texana |    20 |  2 |  2 | Dyspanopeus texanus; Dyspanopeus sayi |
| Nitellopsis obtusa |    20 |  3 |  1 | Nitellopsis obtusa |
| Nitzschia kuetzingiana |    20 | 12 | 12 | Nitzschia kuetzingiana; Nitzschia kuetzingiana f. exigua; Nitzschia kuetzingiana f. hyalina; Nitzschia kuetzingiana f. kuetzingiana; Nitzschia kuetzingiana f. terrestris; Nitzschia kuetzingiana var. capitata; Nitzschia kuetzingiana var. exilis; Nitzschia kuetzingiana var. fonticola; Nitzschia kuetzingiana var. genuina; Nitzschia kuetzingiana var. major (+2 more) |
| Nitzschia linearis |    20 | 26 | 21 | Nitzschia linearis; Nitzschia linearis f. brevis; Nitzschia linearis f. constricta; Nitzschia linearis f. genuina; Frustulia linearis; Nitzschia linearis f. major; Nitzschia linearis f. medioconstricta; Nitzschia linearis f. minor; Nitzschia linearis f. minuta; Nitzschia tenuis f. tenuis (+11 more) |
| Protothaca staminea |    20 |  4 |  2 | Leukoma staminea; Leukoma laciniata |
| Rhodomonas salina |    20 |  2 |  2 | Rhodomonas salina; NA |
| Semotilus atromaculatus |    20 |  2 |  1 | Semotilus atromaculatus |
| Ulva reticulata |    20 |  2 |  2 | Ulva reticulata; NA |
| Ancylus fluviatilis |    19 | 13 |  8 | Ancylus fluviatilis; Acroloxus tetensi; Ancylus fluviatilis var. armenia; Ancylus fluviatilis var. capuliformis; Ancylus capuloides; Ancylus fluviatilis var. depressus; Ancylus fluviatilis var. dimidiatus; Ancylus fluviatilis var. lepidus |
| Bryocamptus zschokkei |    19 | 15 | 14 | Bryocamptus (Rheocamptus) zschokkei zschokkei; Bryocamptus (Rheocamptus) zschokkei alleganiensis; Bryocamptus (Rheocamptus) balcanicus balcanicus; Bryocamptus (Rheocamptus) zschokkei caucasicus; Bryocamptus zschokkei caucasicus f. triarticulata; Bryocamptus zschokkei frigidus; Bryocamptus zschokkei himalayensis; Bryocamptus (Rheocamptus) zschokkei kalinae; Bryocamptus (Rheocamptus) zschokkei komi; Bryocamptus zschokkei orientalis (+4 more) |
| Echinogammarus berilloni |    19 |  2 |  2 | Echinogammarus berilloni; Echinogammarus calvus |
| Enteromorpha intestinalis |    19 | 43 | 27 | Ulva intestinalis; NA; Enteromorpha intestinalis f. bravis; Enteromorpha intestinalis f. brevis; Enteromorpha intestinalis f. bullosa; Enteromorpha intestinalis f. clava; Ulva intestinalis f. cornucopiae; Enteromorpha intestinalis f. cornucopiae; Enteromorpha intestinalis f. crispa; Enteromorpha intestinalis f. crispata (+17 more) |
| Gammarus sp |    19 |  8 |  8 | Gammarus spelaeus; Leucothoe spinicarpa; Gammarus balcanicus; Paramelita spinicornis; Gammarus spinipalmus; Jassa spinipes; Melphidippa goesi; Gammarus spooneri |
| Ligumia recta |    19 |  2 |  1 | Ligumia recta |
| Nephrops norvegicus |    19 |  2 |  1 | Nephrops norvegicus |
| Oocystis lacustris |    19 |  4 |  4 | Oocystis lacustris; Cryodactylon antarctica; Oocystis natans; Oocystis lacustris var. paludensis |
| Ostrea edulis |    19 |  9 |  2 | Ostrea edulis; Ostrea stentina |
| Planorbis carinatus |    19 |  2 |  2 | Planorbis carinatus; Planorbis kubanicus |
| Prymnesium parvum |    19 |  2 |  2 | Prymnesium parvum; Prymnesium parvum f. patelliferum |
| Rhinichthys atratulus |    19 |  3 |  1 | Rhinichthys atratulus |
| Astacus astacus |    18 |  4 |  4 | Astacus astacus; Astacus astacus astacus; Astacus balcanicus balcanicus; Astacus astacus canadziae |
| Attheyella crassa |    18 |  3 |  2 | Attheyella (Attheyella) crassa; Attheyella crassa thracica |
| Aulacomya ater |    18 |  4 |  2 | Aulacomya atra; Aulacomya maoriana |
| Barilius bendelisis |    18 |  3 |  1 | Opsarius bendelisis |
| Chlamydomonas snowiae |    18 |  4 |  4 | Chlamydomonas snowiae; Chlamydomonas snowiae var. ovata; Chlamydomonas snowiae var. palmelloides; Chlamydomonas snowiae var. pluristigma |
| Chydorus sp |    18 |  3 |  3 | Chydorus patagonicus; Chydorus sphaericus; Chydorus spinosus |
| Cyclops sp |    18 |  4 |  4 | Apocyclops spartinus; Eucyclops (Speratocyclops) speratus speratus; Mesocyclops annulatus annulatus; Tropocyclops prasinus prasinus |
| Diplodus sargus |    18 | 11 |  7 | Diplodus sargus; Diplodus ascensionis; Diplodus cadenati; Diplodus capensis; Diplodus helenae; Diplodus lineatus; Diplodus kotschyi |
| Fundulus grandis |    18 |  4 |  3 | Fundulus grandis; Fundulus saguanus; Fundulus grandissimus |
| Hexarthra fennica |    18 |  3 |  2 | Hexarthra fennica; Hexarthra polyodonta |
| Macropodus cupanus |    18 |  2 |  2 | Pseudosphromenus cupanus; Pseudosphromenus dayi |
| Misgurnus fossilis |    18 |  2 |  2 | Misgurnus fossilis; Misgurnus anguillicaudatus |
| Planorbis corneus |    18 |  2 |  1 | Planorbarius corneus |
| Uca annulipes |    18 |  5 |  4 | Austruca annulipes; Austruca albimana; Austruca iranica; Austruca perplexa |
| Venustaconcha ellipsiformis |    18 |  3 |  2 | Venustaconcha ellipsiformis; Venustaconcha pleasii |
| Astyanax bimaculatus |    17 |  5 |  3 | Astyanax bimaculatus; Astyanax asuncionensis; Astyanax novae |
| Barbus sophore |    17 |  2 |  2 | Puntius sophore; Puntius stigma |
| Caridina weberi |    17 |  7 |  5 | Caridina weberi; Caridina papuana; Caridina weberi var. keiensis; Caridina longicarpus; Caridina sumatrensis |
| Diaptomus sp |    17 |  5 |  5 | Aglaodiaptomus spatulocrenatus; Tropodiaptomus spectabilis; Leptodiaptomus spinicornis; Argyrodiaptomus spiniger; Arctodiaptomus (Rhabdodiaptomus) spinosus |
| Dugesia gonocephala |    17 |  9 |  9 | Dugesia gonocephala; Dugesia bakurianica; Dugesia gonocephala gonocephala; Dugesia ilvana; Dugesia gonocephala meridionalis; Dugesia gonocephala precaucasica; Dugesia subtentaculata; Dugesia gonocephala taurocaucasica; Dugesia gonocephala transcaucasica |
| Megacyclops viridis |    17 |  7 |  6 | Megacyclops viridis viridis; Megacyclops viridis batiale; Megacyclops viridis deserticola; Megacyclops viridis latipes; Megacyclops viridis oligotrichus; Megacyclops viridis takebuensis |
| Navicula longa |    17 |  4 |  4 | Navicula longa; Navicula longa var. curta; Navicula longa var. irregularis; Pinnularia longa |
| Tigriopus fulvus |    17 |  4 |  3 | Tigriopus fulvus fulvus; Tigriopus fulvus adriatica; Tigriopus fulvus algirica |
| Amblema plicata |    16 | 12 |  3 | Amblema plicata; Amblema elliottii; Amblema neislerii |
| Amphora coffeaeformis |    16 | 37 | 35 | Halamphora coffeiformis; Amphora coffeaeformis; Amphora acutiuscula var. acutiuscula; Amphora coffeaeformis f. africana; Amphora coffeaeformis f. angularis; Frustulia coffeaeformis; Amphora coffeaeformis f. curta; Amphora coffeaeformis f. kurze; Amphora coffeaeformis f. minima; Amphora lineata var. subconstricta (+25 more) |
| Aphanius fasciatus |    16 |  2 |  1 | Aphanius fasciatus |
| Asellus racovitzai |    16 |  3 |  3 | Caecidotea racovitzai; Caecidotea racovitzai australis; Caecidotea racovitzai racovitzai |
| Brachionus caudatus |    16 | 12 |  3 | Brachionus caudatus; Brachionus austrogenitus; Brachionus ahlstromi |
| Chara vulgaris |    16 | 50 | 37 | Chara vulgaris; Chara andina; Chara contraria var. arrudensis; Chara vulgaris f. atrovirens; Chara vulgaris var. boveana; Chara brionica; Chara calveraënsis; Chara gymnophylla f. conimbrigensis; Chara contraria; Chara vulgaris f. crispa (+27 more) |
| Notropis hudsonius |    16 |  3 |  1 | Notropis hudsonius |
| Oncorhynchus masou |    16 |  8 |  3 | Oncorhynchus masou; Oncorhynchus formosanus; Oncorhynchus rhodurus |
| Orconectes propinquus |    16 |  3 |  3 | Faxonius propinquus; Faxonius sanbornii erismorphorous; Faxonius jeffersoni |
| Oscillatoria limnetica |    16 |  5 |  3 | Pseudanabaena limnetica; Pseudanabaena acicularis; Oscillatoria limnetica f. major |
| Panulirus homarus |    16 |  4 |  3 | Panulirus homarus; Panulirus homarus homarus; Panulirus homarus rubellus |
| Pinctada fucata |    16 |  3 |  1 | Pinctada fucata |
| Acipenser stellatus |    15 |  4 |  1 | Acipenser stellatus |
| Amphibalanus amphitrite |    15 | 16 | 14 | Amphibalanus amphitrite; Amphibalanus amphitrite abundantatus; Tasmanobalanus acutus acutus; Amphibalanus amphitrite amphitrite; Amphibalanus amphitrite archi-inexpectatus; Amphibalanus amphitrite cochinensis; Amphibalanus amphitrite helenae; Amphibalanus amphitrite hungaricus; Amphibalanus amphitrite karakumiensis; Amphibalanus amphitrite litoralis (+4 more) |
| Anabaena oscillarioides |    15 | 31 | 20 | Anabaena oscillarioides; Anabaena oscillarioides var. caucasica; Anabaena oscillarioides f. circinalis; Anabaena torulosa var. cylindracea; Anabaena oscillarioides f. elliptica; Anabaena oscillarioides var. elongata; Anabaena oscillarioides f. intermedia; NA; Anabaena oscillarioides f. major; Anabaena oscillarioides f. minor (+10 more) |
| Ankistrodesmus fusiformis |    15 |  2 |  2 | Ankistrodesmus fusiformis; Ankistrodesmus fusiformis f. stipitatus |
| Argopecten ventricosus |    15 |  3 |  2 | Argopecten ventricosus; Argopecten ventricosus ventricosus |
| Channa marulius |    15 |  2 |  1 | Channa marulius |
| Coscinodiscus centralis |    15 | 10 |  6 | Coscinodiscus centralis; Coscinodiscus centralis f. centralis; Coscinodiscus centralis f. maxima; Coscinodiscus centralis f. minor; Coscinodiscus centralis var. micraster; Coscinodiscus centralis var. pacifica |
| Diadema antillarum |    15 |  3 |  2 | Diadema antillarum; Diadema antillarum ascensionis |
| Eudiaptomus gracilis |    15 |  5 |  4 | Eudiaptomus gracilis gracilis; Eudiaptomus gracilis aemilianus; Eudiaptomus gracilis carnicus; Eudiaptomus gracilis ligustica |
| Gambusia yucatana |    15 |  2 |  1 | Gambusia yucatana |
| Gobio gobio |    15 | 42 | 22 | Gobio gobio; Gobio acutipinnatus; Gobio brevicirris; Gobio bulgaricus; Gobio carpathicus; Gobio cynocephalus; Gobio feraeensis; Gobio gymnostethus; Gobio holurus; Gobio insuyanus (+12 more) |
| Merismopedia tenuissima |    15 |  3 |  3 | Merismopedia tenuissima; NA; Merismopedia tenuissima var. polyedrica |
| Parorchis acanthus |    15 |  3 |  2 | Parorchis acanthus; Parorchis acanthus numenii |
| Pollimyrus isidori |    15 |  4 |  1 | Pollimyrus isidori |
| Rhodeus ocellatus |    15 |  6 |  3 | Rhodeus ocellatus; Rhodeus smithii; Rhodeus spinalis |
| Scenedesmus sp |    15 | 12 | 11 | Desmodesmus armatus; Desmodesmus subspicatus; Scenedesmus spinosiformis; Scenedesmus spinoso-aculeolatus; Desmodesmus spinosus; Scenedesmus subspicatus var. crassicauda; Scenedesmus spinosus var. bicaudatus; Desmodesmus flavescens; Desmodesmus armatus var. microspinosus; Scenedesmus spinosus var. symmetricus (+1 more) |
| Scorpaenichthys marmoratus |    15 |  2 |  1 | Scorpaenichthys marmoratus |
| Stigeoclonium tenue |    15 |  5 |  4 | Stigeoclonium tenue; Stigeoclonium gracile; Stigeoclonium lubricum; Stigeoclonium uniforme |
| Syngnathus scovelli |    15 |  2 |  2 | Syngnathus scovelli; Syngnathus makaxi |
| Trichocerca similis |    15 |  6 |  2 | Trichocerca similis; Trichocerca similis grandis |
| Wallago attu |    15 |  2 |  1 | Wallago attu |
| Asellus meridianus |    14 |  4 |  3 | Proasellus meridianus meridianus; Proasellus anophtalmus anophtalmus; Proasellus meridianus xavieri |
| Bryocamptus pygmaeus |    14 |  3 |  3 | Bryocamptus (Rheocamptus) pygmaeus pygmaeus; Bryocamptus pygmaeus balcanica; Bryocamptus (Bryocamptus) pygmaeus bulbochaetus |
| Chara aculeolata |    14 |  3 |  3 | Chara aculeolata; Chara aculeolata f. pannonica; Chara aculeolata var. bohemica |
| Cyclops vernalis |    14 |  8 |  7 | Acanthocyclops vernalis vernalis; Acanthocyclops americanus americanus; NA; Acanthocyclops vernalis elongatus; Acanthocyclops vernalis ornatus; Acanthocyclops parcus; Acanthocyclops vernalis robustus |
| Dendrocoelum lacteum |    14 |  8 |  8 | Dendrocoelum lacteum; Dendrocoelum lacteum bathycola; Dendrocoelum lacteum crenata; Dendrocoelum lacteum croceum; Dendrocoelum lacteum lacteum; Dendrocoelum lacteum simplex; Dendrocoelum lacteum verbanence; Dendrocoelum lacteum verbanense |
| Hydra attenuata |    14 |  2 |  2 | Hydra circumcincta; Hydra thomseni |
| Lecane closterocerca |    14 |  2 |  1 | Lecane closterocerca |
| Nostoc kihlmani |    14 |  2 |  2 | Nostoc kihlmanii; Nostoc kihlmanii var. vaginatum |
| Ozius rugulosus |    14 |  2 |  1 | Ozius rugulosus |
| Pediastrum tetras |    14 | 37 | 15 | Stauridium tetras; NA; Pediastrum tetras var. apiculatum; Crucigenia australis; Crucigenia cruxmichaeli; Pediastrum tetras var. cuspidatum; Pediastrum tetras var. fluviatile; Pediastrum tetras var. integrum; Pediastrum tetras var. longicornutum; Pediastrum tetras var. obtusatum (+5 more) |
| Pithophora oedogonia |    14 |  2 |  2 | Pithophora roettleri; NA |
| Potomida littoralis |    14 |  5 |  3 | Potomida littoralis; Unio mardinensis; Potomida littoralis littoralis |
| Pseudodiaptomus inopinus |    14 |  4 |  3 | Pseudodiaptomus inopinus inopinus; Pseudodiaptomus inopinus gordioides; Pseudodiaptomus inopinus saccupodus |
| Saccostrea cuccullata |    14 |  2 |  2 | Saccostrea cuccullata; Saccostrea glomerata |
| Trichocerca porcellus |    14 |  2 |  2 | Trichocerca porcellus; Trichocerca maior |
| Vimba vimba |    14 | 12 |  1 | Vimba vimba |
| Anabaena sp |    13 | 46 | 31 | Anabaena sphaerica; Anabaena sphaerica f. conoidea; NA; Sphaerospermopsis kisseleviana; Anabaena sphaerica f. microsperma; Anabaena sphaerica f. tenuis; Anabaena sphaerica var. attenuata; Anabaena ellipsoidea; Anabaena beckii; Anabaena sphaerica var. major (+21 more) |
| Aulosira fertilissima |    13 |  2 |  2 | Aulosira fertilissima; Aulosira fertilissima var. tenuis |
| Cerastoderma glaucum |    13 |  3 |  1 | Cerastoderma glaucum |
| Galaxias truttaceus |    13 |  2 |  1 | Galaxias truttaceus |
| Leptodea fragilis |    13 |  2 |  1 | Potamilus fragilis |
| Lymnaea peregra |    13 |  2 |  2 | Peregriana peregra; Ampullaceana balthica |
| Mytilina ventralis |    13 |  8 |  4 | Mytilina ventralis; Mytilina brevispina; Mytilina michelangellii; Mytilina ventralis wuhanensis |
| Niphargus aquilex |    13 |  6 |  5 | Niphargus aquilex; Niphargus dobati; Niphargus moldavicus; Niphargus pretneri; Niphargus tauri |
| Physa acuta |    13 | 14 |  1 | Physella acuta |
| Platygyra daedalea |    13 | 11 |  2 | Platygyra daedalea; Platygyra lamellina |
| Procambarus simulans |    13 |  2 |  2 | Procambarus simulans; Procambarus regiomontanus |
| Ruppia maritima |    13 |  2 |  1 | Ruppia maritima |
| Unio crassus |    13 | 15 |  5 | Ortmanniana ligamentina; Unio crassus; Unio carneus; Unio nanus; Middendorffinaia mongolica |
| Aldrichetta forsteri |    12 |  2 |  1 | Aldrichetta forsteri |
| Aphanothece clathrata |    12 |  4 |  4 | Anathece clathrata; Anathece bachmannii; Aphanothece clathrata var. maxima; Aphanothece clathrata var. rosea |
| Aporrectodea caliginosa |    12 |  2 |  2 | Aporrectodea caliginosa; Aporrectodea caliginosa trapezoides |
| Asterias amurensis |    12 |  7 |  3 | Asterias amurensis; Asterias amurensis f. amurensis; Asterias amurensis f. robusta |
| Barilius vagra |    12 |  3 |  2 | Barilius vagra; Barilius pakistanicus |
| Bryocamptus minutus |    12 |  2 |  2 | Bryocamptus (Bryocamptus) minutus minutus; Bryocamptus minutus minnesotensis |
| Ceratoneis closterium |    12 |  2 |  2 | Ceratoneis closterium; Nitzschiella californica |
| Chara globularis |    12 | 42 | 32 | Chara globularis; Chara altaica var. abnormiformis; Chara arcuatofolia; NA; Chara capensis; Chara chrysospora; Chara connivens; Chara curta; Chara fischeri; Chara fragifera (+22 more) |
| Clupea harengus |    12 | 25 |  4 | Clupea harengus; Clupea pallasii; Sardina pilchardus; Amblygaster sirm |
| Diaptomus leptopus |    12 |  2 |  1 | Aglaodiaptomus leptopus |
| Eucyclops sp |    12 |  6 |  4 | Eucyclops (Eucyclops) spatharum; Eucyclops (Eucyclops) spatulatus; Eucyclops (Speratocyclops) speratus speratus; Eucyclops speratus elegans |
| Gomphonema clavatum |    12 |  5 |  3 | Gomphonema clavatum; Gomphonema clavatum f. clavatum; Gomphonema clavatum var. curta |
| Madracis mirabilis |    12 |  3 |  2 | Madracis myriaster; Madracis auretenra |
| Monodonta labio |    12 |  2 |  2 | Monodonta labio; Monodonta confusa |
| Navicula confervacea |    12 | 11 |  8 | Diadesmis confervacea; Navicula confervacea f. nipponica; Navicula confervacea f. rostrata; Navicula ignorata var. baikalensis; Navicula confervacea var. hungarica; Navicula confervacea var. laterostrata; Diadesmis peregrina; Navicula confervacea var. tenuis |
| Nitzschia obtusa |    12 | 43 | 39 | Nitzschia obtusa; Nitzschia obtusa f. angusta; Nitzschia obtusa f. lata; Nitzschia obtusa f. minor; Nitzschia obtusa f. nipponica; Nitzschia obtusa f. obtusa; Nitzschia obtusa f. parva; Nitzschia obtusa f. scalpelliformis; Nitzschia scalpelliformis; Nitzschia obtusa var. amphiglottis (+29 more) |
| Scherffelia dubia |    12 |  3 |  3 | Scherffelia dubia; Scherffelia dubia f. maxima; Scherffelia dubia var. major |
| Seriola lalandi |    12 |  2 |  1 | Seriola lalandi |
| Squalus acanthias |    12 |  5 |  1 | Squalus acanthias |
| Unio ravoisieri |    12 |  2 |  1 | Unio ravoisieri |
| Amphiprora paludosa |    11 | 26 | 25 | Entomoneis paludosa; Amphiprora paludosa f. hyperborea; Amphiprora hyperborea f. minuta; Amphiprora paludosa var. africana; Amphiprora paludosa var. bahusiensis; Amphiprora paludosa var. bergmannii; Amphiprora paludosa var. borealis; Amphiprora paludosa var. densestriata; Amphiprora dilatata; Amphiprora duplex var. duplex (+15 more) |
| Ankistrodesmus sp |    11 |  4 |  4 | Ankistrodesmus spiralis; Ankistrodesmus densus; Elakatothrix spirochroma; Koliella spirotaenia |
| Balanus crenatus |    11 |  4 |  4 | Balanus crenatus; Balanus crenatus crenatus; Balanus crenatus curviscutum; Balanus crenatus delicatus |
| Brachionus havanaensis |    11 |  6 |  2 | Brachionus havanaensis; Brachionus ahlstromi |
| Brachionus patulus |    11 |  4 |  2 | Plationus patulus; Plationus patulus var. macracanthus |
| Caulerpa lentillifera |    11 |  6 |  4 | Caulerpa lentillifera; Caulerpa microphysa; Caulerpa lentillifera var. compacta; Caulerpa lentillifera var. condensata |
| Cryptomonas erosa |    11 |  2 |  2 | Cryptomonas erosa; Cryptomonas pyrenoidifera |
| Dunaliella viridis |    11 |  3 |  2 | Dunaliella viridis; Dunaliella viridis var. palmelloides |
| Eudorina elegans |    11 |  3 |  3 | Eudorina elegans; Eudorina unicocca; Eudorina elegans var. richmondiae |
| Haliotis diversicolor |    11 |  3 |  3 | Haliotis diversicolor; Haliotis diversicolor diversicolor; Haliotis diversicolor squamata |
| Leuciscus leuciscus |    11 |  5 |  2 | Leuciscus leuciscus; Leuciscus baicalensis |
| Neocaridina heteropoda |    11 |  4 |  3 | Neocaridina davidi; Neocaridina koreana; Neocaridina luoyangensis |
| Phormidium fragile |    11 |  2 |  2 | Leptolyngbya fragilis; Leptolyngbya maius |
| Rhinichthys osculus |    11 | 11 |  1 | Rhinichthys osculus |
| Staurodesmus convergens |    11 | 13 | 11 | Staurodesmus convergens; Staurodesmus convergens var. curtus; Staurodesmus convergens var. deplanatus; Staurodesmus dickiei; Staurodesmus convergens var. convergens; Staurodesmus convergens var. depressus; Staurodesmus convergens var. incrassatus; Staurodesmus convergens var. laportei; Staurodesmus convergens var. pumilus; Staurodesmus convergens var. ralfsii (+1 more) |
| Synedra acus |    11 | 41 | 35 | Synedra radians var. radians; Fragilaria ostenfeldii; Synedra acus; Synedra acus f. acus; Synedra delicatissima var. angustissima; Synedra acus f. anomala; Synedra acus f. continua; Synedra acus f. curvula; Synedra delicatissima f. delicatissima; Synedra acus f. fossilis (+25 more) |
| Tegillarca granosa |    11 |  3 |  2 | Tegillarca granosa; Tegillarca granosa granosa |
| Thermocyclops oblongatus |    11 |  2 |  2 | Thermocyclops oblongatus; Thermocyclops nigerianus |
| Achnanthes minutissima |    10 | 27 | 23 | Achnanthes minutissima; Achnanthes minutissima f. curta; Microneis gracillima; Achnanthes minutissima var. inconspicua; Achnanthes affinis; Achnanthes minutissima var. ambigua; Achnanthes minutissima var. amphicephala; NA; Achnanthes minutissima var. capitata; Achnanthes minutissima var. constricta (+13 more) |
| Anabaena catenula |    10 |  6 |  6 | Anabaena catenula; Dolichospermum affine; Anabaena catenula var. africana; Dolichospermum danicum; Trichormus minor; Dolichospermum solitarium |
| Caridina africana |    10 |  9 |  7 | Caridina africana; Caridina togoensis; Caridina africana f. brevis; Caridina africana f. longa; Elephantis jaggeri; Caridina roubaudi; Caridina africana nigerdeltae |
| Chaetoceros muelleri |    10 |  4 |  4 | Chaetoceros muelleri; Chaetoceros muelleri var. duplex; Chaetoceros muelleri var. muelleri; Chaetoceros subsalsus |
| Chattonella marina |    10 |  3 |  3 | Chattonella marina; Chattonella marina var. antiqua; Chattonella marina var. ovata |
| Chrysophrys auratus |    10 |  2 |  2 | Pagrus auratus; Sparus aurata |
| Coregonus albula |    10 | 13 |  4 | Coregonus albula; Coregonus ladogae; Coregonus lucinensis; Coregonus kiletz |
| Elimia virginica |    10 |  2 |  1 | Elimia virginica |
| Fragilaria crotonensis |    10 | 20 | 19 | Fragilaria crotonensis; Fragilaria crotonensis f. curta; Fragilaria crotonensis f. curvata; Fragilaria prolongata; Fragilaria crotonensis var. contorta; Fragilaria crotonensis var. crotonensis; Fragilaria crotonensis var. curta; Fragilaria crotonensis var. genuina; Fragilaria crotonensis var. media; Fragilaria crotonensis var. mesolepta (+9 more) |
| Furcellaria lumbricalis |    10 |  2 |  1 | Furcellaria lumbricalis |
| Haliotis cracherodii |    10 |  7 |  3 | Haliotis cracherodii; Haliotis cracherodii californiensis; Haliotis cracherodii cracherodii |
| Laminaria digitata |    10 | 30 |  9 | Laminaria digitata; Laminaria hyperborea; Laminaria digitata var. bifida; NA; Laminaria digitata var. elliptica; Laminaria digitata var. ligulata; Laminaria digitata var. lyrata; Laminaria digitata var. palmata; Laminaria digitata var. pseudosaccharina |
| Monoraphidium convolutum |    10 |  2 |  2 | Monoraphidium convolutum; Monoraphidium convolutum var. pseudosabulosum |
| Nitella opaca |    10 | 16 |  5 | Nitella opaca; NA; Nitella opaca var. attenuata; Nitella opaca var. brachyclema; Nitella opaca var. paucicostata |
| Oscillatoria chalybea |    10 |  4 |  4 | Phormidium chalybeum; Oscillatoria anguina; Phormidium insulare; Oscillatoria chalybea var. luticola |
| Platygobio gracilis |    10 |  3 |  1 | Platygobio gracilis |
| Poecilia sp |    10 |  5 |  3 | Poecilia sphenops; Epiplatys spilargyreius; Aplocheilichthys spilauchen |
| Porites astreoides |    10 |  3 |  1 | Porites astreoides |
| Radix peregra |    10 |  3 |  2 | Peregriana peregra; Ampullaceana balthica |
| Scenedesmus obliquus |    10 | 10 |  8 | Tetradesmus obliquus; NA; Pectinodesmus javanensis; Scenedesmus obliquus f. tetradesmoides; Tetradesmus lagerheimii; Tetradesmus obliquus var. alternans; Tetradesmus dimorphus; Scenedesmus acuminatus var. inermius |
| Sphaerechinus granularis |    10 |  2 |  1 | Sphaerechinus granularis |
| Tropisternus lateralis |    10 |  2 |  2 | Tropisternus lateralis; Tropisternus lateralis nimbatus |
| Urosalpinx cinerea |    10 |  2 |  1 | Urosalpinx cinerea |
| Amnicola limosa |     9 |  2 |  1 | Amnicola limosus |
| Arenicola marina |     9 |  3 |  3 | Arenicola marina; Arenicola marina glacialis; Arenicola marina schantarica |
| Catostomus catostomus |     9 |  5 |  2 | Catostomus catostomus; Catostomus columbianus |
| Cosmarium obtusatum |     9 |  7 |  7 | Cosmarium obtusatum; Cosmarium obtusatum f. aequale; Cosmarium obtusatum f. minus; Cosmarium obtusatum var. beanlandii; Cosmarium obtusatum var. glabrum; Cosmarium obtusatum var. minus; Cosmarium obtusatum var. skujae |
| Helisoma anceps |     9 |  9 |  3 | Helisoma anceps; Helisoma anceps anceps; Helisoma anceps royalense |
| Macropodus opercularis |     9 |  3 |  2 | Macropodus opercularis; Macropodus spechti |
| Navicula forcipata |     9 | 19 | 17 | Navicula forcipata f. forcipata; Navicula forcipata f. parva; Navicula pygmaea var. balnearis; Navicula forcipata var. densestriata; Navicula forcipata var. elongata; Navicula forcipata var. forcipata; Navicula forcipata var. intermedia; Navicula forcipata var. minima; Navicula forcipata var. minor; Navicula suborbicularis var. nankoorensis (+7 more) |
| Nitzschia sp |     9 | 25 | 24 | Nitzschia spathulata; Nitzschia spathulata var. angusta; Nitzschia hyalina; Nitzschia spathulata var. spathulata; Nitzschia spathulatoides; Nitzschia spathulifera; Nitzschia speciosa; Nitzschia spectabilis; Nitzschia spectabilis var. americana; Nitzschia spectabilis var. genuina (+14 more) |
| Nostoc calcicola |     9 |  3 |  3 | Schizothrix calcicola; Nostoc calcicola; Nostoc calcicola f. variabilis |
| Nostoc sp |     9 | 14 | 13 | Nostoc sphaericum; Nostoc sphaericum var. cylindrosporum; NA; Nostoc sphaeroides; Nostoc sphaerosporum; Nostoc spinosum; Nostoc carneum; Nostoc spongiaeforme var. tenue; Nostoc spongiaeforme var. varians; Nostoc spongiiforme var. regulare (+3 more) |
| Pandorina morum |     9 |  6 |  6 | Pandorina morum; Pandorina morum f. cylindrica; Pandorina morum f. major; Pandorina morum f. oligosoma; Pandorina morum var. coelastroidea; Pandorina morum var. tropica |
| Peloscolex gabriellae |     9 |  4 |  3 | Tectidrilus gabriellae; Tubificoides apectinatus; Tubificoides nerthoides |
| Pisidium casertanum |     9 |  3 |  3 | Euglesa casertana; NA; Euglesa ponderosa |
| Pisidium compressum |     9 | 14 |  1 | Euglesa compressa |
| Salmo clarkii |     9 |  4 |  1 | Oncorhynchus clarkii |
| Scytosiphon lomentaria |     9 | 14 |  7 | Scytosiphon lomentaria; Scytosiphon dotyi; NA; Asperococcus fistulosus; Planosiphon complanatus; Scytosiphon lomentaria var. fistulosus; Scytosiphon lomentaria var. gracilis |
| Staurastrum manfeldtii |     9 | 20 | 17 | Staurastrum manfeldtii; Staurastrum manfeldtii f. concinnum; NA; Staurastrum manfeldtii f. spinulosum; Staurastrum manfeldtii var. africanum; Staurastrum manfeldtii var. annulatum; Staurastrum manfeldtii var. bispinatum; Staurastrum manfeldtii var. eichleri; Staurastrum manfeldtii var. elegans; Staurastrum manfeldtii var. ornatum (+7 more) |
| Acanthopagrus schlegeli |     8 |  4 |  1 | Acanthopagrus schlegelii |
| Anabaena torulosa |     8 |  5 |  5 | Anabaena torulosa; Anabaena torulosa var. cylindracea; NA; Anabaena torulosa var. stenospora; Anabaena torulosa var. tenuis |
| Anguilla australis |     8 |  5 |  1 | Anguilla australis |
| Barbus stigma |     8 |  5 |  5 | Puntius stigma; Enteromius stigmasemion; Labeobarbus natalensis; Enteromius stigmatopygus; Barbodes aurotaeniatus |
| Brachionus quadridentatus |     8 | 19 |  5 | Brachionus quadridentatus; Brachionus quadridentatus quadridentatus; Brachionus bidentatus; Brachionus mirabilis; Brachionus quadridentatus urawensis |
| Brachionus rotundiformis |     8 |  3 |  3 | Brachionus rotundiformis; Brachionus plicatilis decemcornis; Brachionus plicatilis |
| Chlamydomonas variabilis |     8 |  2 |  2 | Chloromonas variabilis; Chlamydomonas variabilis f. anglica |
| Cocconeis placentula |     8 | 43 | 36 | Cocconeis placentula; Cocconeis placentula var. baicalensis; Cocconeis placentula f. anormalis; Cocconeis placentula f. elata; Cocconeis euglypta; Cocconeis intermedia f. intermedia; Cocconeis placentula f. klinoraphis; Cocconeis lineata; Cocconeis placentula f. major; Cocconeis placentula f. maximaornata (+26 more) |
| Cosmarium crenulatum |     8 |  2 |  1 | Cosmarium crenulatum |
| Cottus gobio |     8 | 12 |  4 | Cottus gobio; Cottus haemusi; Cottus hispaniolensis; Cottus koshewnikowi |
| Desmodesmus armatus |     8 | 11 | 11 | Desmodesmus armatus; Desmodesmus armatus var. armatus; Desmodesmus armatus var. asymetricus; Desmodesmus armatus var. bicaudatus; Desmodesmus armatus var. boglariensis; Desmodesmus armatus var. longispina; Desmodesmus armatus var. major; Desmodesmus armatus var. microspinosus; Desmodesmus armatus var. pluricostatus; Desmodesmus armatus var. spinosus (+1 more) |
| Etheostoma flabellare |     8 |  4 |  2 | Etheostoma flabellare; Etheostoma brevispinum |
| Ictalurus nebulosus |     8 |  4 |  1 | Ameiurus nebulosus |
| Leptomysis mediterranea |     8 |  3 |  3 | Leptomysis mediterranea; Leptomysis mediterranea atlantica; Leptomysis mediterranea mediterranea |
| Limnocalanus macrurus |     8 |  4 |  1 | Limnocalanus macrurus |
| Micropterus dolomieui |     8 |  2 |  1 | Micropterus dolomieu |
| Nemacheilus angorae |     8 |  3 |  2 | Oxynoemacheilus angorae; Oxynoemacheilus lenkoranensis |
| Petrolisthes armatus |     8 |  2 |  1 | Petrolisthes armatus |
| Poecilia mexicana |     8 |  2 |  1 | Poecilia mexicana |
| Stauroneis amphoroides |     8 |  2 |  1 | NA |
| Synedra radians |     8 |  5 |  5 | Fragilaria radians; Synedra radians; Synedra debilis; Synedra radians var. radians; Exilaria tenuissima |
| Theragra chalcogramma |     8 |  2 |  1 | Gadus chalcogrammus |
| Ulothrix sp |     8 |  3 |  3 | Ulothrix speciosa; NA; Planktolyngbya contorta |
| Villosa vibex |     8 |  2 |  2 | Villosa vibex; Villosa amygdalum |
| Asplanchna brightwelli |     7 |  4 |  3 | Asplanchna brightwellii; Asplanchna asymmetrica; Asplanchna girodi |
| Asterias rubens |     7 |  4 |  2 | Asterias rubens; Asterias amurensis |
| Asterionella formosa |     7 | 16 | 15 | Asterionella formosa; Asterionella formosa var. acaroides; Asterionella formosa f. brevis; Asterionella formosa f. capitellata; Asterionella bleakeleyi var. bleakeleyi; Asterionella formosa var. brevis; Asterionella formosa var. epilimnetica; Asterionella formosa var. formosa; Diatoma gracillimum; Asterionella formosa var. hypolimnetica (+5 more) |
| Atherinosoma microstoma |     7 |  2 |  2 | Atherinosoma microstoma; Leptatherina presbyteroides |
| Blicca bjoerkna |     7 |  4 |  1 | Blicca bjoerkna |
| Ceratium hirundinella |     7 | 18 | 15 | Ceratium hirundinella; Ceratium hirundinella f. austriacum; Ceratium hirundinella f. brachyceroides; Ceratium hirundinella f. carinthiacum; Ceratium furcoides; Ceratium rhomvoides; Ceratium hirundinella f. piburgense; Ceratium hirundinella f. robustum; Ceratium hirundinella f. scoticum; Ceratium hirundinella f. silesiacum (+5 more) |
| Chara hispida |     7 | 36 | 19 | Chara hispida; Chara aculeolata var. bohemica; Chara corfuensis; Chara hispida f. crassicaulis; Chara hispida f. equisetina; Chara horrida; Chara intermedia var. papillosa; Chara hispida f. laevis; Chara baltica var. liljebladii; Chara hispida f. macracantha (+9 more) |
| Chlorella emersonii |     7 |  3 |  3 | Graesiella emersonii; Coelastrella vacuolata; Halochlorella rubescens |
| Cosmarium turpinii |     7 |  5 |  5 | Cosmarium turpinii; Cosmarium turpinii var. cambricum; Cosmarium turpinii var. eximium; Cosmarium turpinii var. intermedium; Cosmarium turpinii var. podolicum |
| Evasterias troschelii |     7 |  7 |  6 | Evasterias troschelii; Evasterias troschelii f. alveolata; Evasterias troschelii f. parvispina; Evasterias troschelii var. densa; Evasterias troschelii var. rudis; Evasterias troschelii var. subnodosa |
| Leptodius exaratus |     7 |  2 |  2 | Leptodius exaratus; Leptodius sanguineus |
| Leptoxis dilatata |     7 |  5 |  3 | Leptoxis dilatata; NA; Leptoxis dilatata var. sinuata |
| Lophopodella carteri |     7 |  3 |  3 | Lophopodella carteri; Lophopodella carteri himalayana; Lophopodella carteri var. typica |
| Maja squinado |     7 |  3 |  3 | Maja squinado; Maja brachydactyla; Maja cornuta |
| Nemacheilus botia |     7 |  3 |  2 | Paracanthocobitis botia; Acanthocobitis mooreh |
| Nitella pseudoflabellata |     7 | 50 | 29 | Nitella pseudoflabellata; Nitella pseudoflabellata f. australiana; NA; Nitella baronii; Nitella crispa; Nitella elegans; Nitella horikawae; Nitella imperialis; Nitella leptosoma; Nitella megaspora (+19 more) |
| Oncomelania nosophora |     7 |  3 |  1 | Oncomelania hupensis nosophora |
| Oscillatoria sp |     7 | 17 | 14 | Oscillatoria spadicea; Phormidium spirulinoides; Oscillatoria spirulinoides; Geitlerinema splendidum; Oscillatoria splendida f. attenuata; Oscillatoria splendida f. clarescens; Oscillatoria splendida var. uncinata; Oscillatoria splendida var. amylacea; NA; Geitlerinema major (+4 more) |
| Oscillatoria tenuis |     7 | 16 | 14 | Oscillatoria tenuis; Oscillatoria tenuis f. natans; Oscillatoria tenuis f. symplociformis; Phormidium tergestinum; Oscillatoria tenuis f. asiatica; Kamptonema formosum; Oscillatoria gyrosa; Oscillatoria levis; Oscillatoria limosa; Lyngbya natans (+4 more) |
| Patella vulgata |     7 | 16 |  5 | Patella vulgata; Patella caerulea; Patella ulyssiponensis; NA; Patella depressa |
| Pectinaria californiensis |     7 |  2 |  2 | Pectinaria californiensis; Pectinaria californiensis newportensis |
| Plecoglossus altivelis |     7 |  4 |  1 | Plecoglossus altivelis |
| Plumatella casmiana |     7 |  4 |  4 | Plumatella casmiana; Plumatella casmiana fungosa; Plumatella casmiana kamtschadalica; Plumatella casmiana rossica |
| Plumatella emarginata |     7 |  2 |  2 | Plumatella emarginata; Plumatella emarginata typica |
| Scenedesmus opoliensis |     7 | 17 | 16 | Desmodesmus opoliensis; Scenedesmus opoliensis f. granulatus; Scenedesmus opoliensis var. abundans; Desmodesmus opoliensis var. aculeatus; Scenedesmus opoliensis var. aculeolatus; Desmodesmus opoliensis var. alatus; Scenedesmus opoliensis var. asymmetricus; Scenedesmus opoliensis var. bicaudatus; Desmodesmus opoliensis var. carinatus; Scenedesmus smithii (+6 more) |
| Schilbe mystus |     7 |  5 |  3 | Schilbe mystus; Schilbe depressirostris; Schilbe intermedius |
| Staurastrum chaetoceras |     7 |  6 |  6 | Staurastrum chaetoceras; Staurastrum chaetoceras f. triradiata; Staurastrum chaetoceras f. triradiatum; Staurastrum chaetoceras var. biradiatum; Staurastrum chaetoceras var. convexum; Staurastrum chaetoceras var. tricrenatum |
| Triops longicaudatus |     7 |  2 |  1 | Triops longicaudatus |
| Uca marionis |     7 |  5 |  3 | Gelasimus vocans; Gelasimus excisus; Gelasimus vomeris |
| Acanthocyclops venustus |     6 |  6 |  4 | Acanthocyclops venustus venustus; Acanthocyclops crinitus; Acanthocyclops venustus italicus; Acanthocyclops troglophilus |
| Achnanthes brevipes |     6 | 46 | 38 | Achnanthes brevipes; Achnanthes brevipes f. curtata; Achnanthes brevipes f. elliptica; Achnanthes brevipes f. gaussii; Achnanthes brevipes f. rostrata; Achnanthes brevipes f. trigona; Achnanthes brevipes var. angustata; Achnanthidium arcticum; Achnanthes brevipes var. bacillaris; Achnanthes brevipes var. biareolata (+28 more) |
| Achnanthes lanceolata |     6 | 44 | 30 | Planothidium apiculatum; Planothidium biporomum; Achnanthes lanceolata; Achnanthes lanceolatoides; Achnanthes lanceolata var. robusta; Achnanthes rostrata; Achnanthes lanceolata var. dubia; Planothidium lanceolatum; Achnanthes lanceolata f. baicalensis; Achnanthes lanceolata var. capitata (+20 more) |
| Amniataba percoides |     6 |  3 |  1 | Amniataba percoides |
| Amphora exigua |     6 |  3 |  3 | Halamphora exigua; Amphora exigua var. exigua; Amphora exigua var. robusta |
| Anabaena affinis |     6 |  4 |  3 | Dolichospermum affine; Dolichospermum viguieri; Dolichospermum danicum |
| Asellus sp |     6 |  3 |  2 | Proasellus spelaeus; Proasellus aquaecalidae |
| Atyaephyra desmarestii |     6 |  3 |  3 | Atyaephyra desmarestii; Atyaephyra orientalis; Atyaephyra stankoi |
| Caecidotea bicrenata |     6 |  3 |  3 | Caecidotea bicrenata; Caecidotea bicrenata bicrenata; Caecidotea bicrenata whitei |
| Calothrix parietina |     6 |  7 |  4 | Calothrix parietina; Calothrix parietina f. crassior; NA; Calothrix parietina var. torulosa |
| Chlamydomonas acidophila |     6 |  2 |  2 | Chlamydomonas nygaardii; Chlamydomonas acidophila |
| Cichlasoma urophthalmus |     6 | 11 | 11 | Mayaheros urophthalmus; Mayaheros aguadae; Mayaheros alborus; Mayaheros amarus; Mayaheros cienagae; Mayaheros conchitae; Mayaheros ericymba; Mayaheros mayorum; Mayaheros stenozonus; Mayaheros trispilus (+1 more) |
| Cryptomonas ovata |     6 |  4 |  4 | Cryptomonas ovata; Cryptomonas curvata; Cryptomonas ovata var. splendida; Cryptomonas borealis |
| Cyprinus sp |     6 |  2 |  2 | Cyprinus carpio; Alburnoides bipunctatus |
| Diadema setosum |     6 |  2 |  1 | Diadema setosum |
| Echinogammarus olivii |     6 |  2 |  2 | Pectenogammarus olivii; Pectenogammarus oliviiformis |
| Fragilaria pinnata |     6 | 40 | 34 | Fragilaria pinnata; Fragilaria pinnata f. brevistriata; Fragilaria mutabilis var. bullata; Fragilaria pinnata var. capitata; Fragilaria pinnata f. capitata; Fragilaria clevei var. clevei; Fragilaria pinnata f. constricta; Fragilaria pinnata f. genuina; Odontidium glaciale; Fragilaria mutabilis var. intercedens (+24 more) |
| Fragilaria rumpens |     6 | 11 | 11 | Fragilaria rumpens; Synedra familiaris f. familiaris; Fragilaria rumpens f. inflata; Fragilaria rumpens f. major; Fragilaria rumpens f. parva; Fragilaria rumpens f. scotia; Fragilaria rumpens var. familiaris; Synedra rumpens f. fragilarioides; Synedra rumpens var. genuina; Synedra rumpens f. meneghiniana (+1 more) |
| Hyale longicornis |     6 |  2 |  2 | Apohyale grandicornis; Hyale longicornis |
| Lythrurus umbratilis |     6 |  3 |  1 | Lythrurus umbratilis |
| Margariscus margarita |     6 |  2 |  2 | Margariscus margarita; Margariscus nachtriebi |
| Melampus bidentatus |     6 |  2 |  1 | Melampus bidentatus |
| Melosira granulata |     6 | 50 | 35 | Aulacoseira granulata; Melosira granulata; Melosira granulata f. angustissima; Melosira granulata f. australiensis; Melosira granulata var. curvata; Melosira granulata f. curvata; Melosira granulata f. delicatula; Melosira granulata f. depauperata; Melosira granulata f. epiphytica; Gaillonella granulata var. granulata (+25 more) |
| Microcoleus vaginatus |     6 |  6 |  4 | Microcoleus vaginatus; Microcoleus vaginatus f. monticola; NA; Microcoleus vaginatus var. acuminatus |
| Monopylephorus rubroniveus |     6 |  6 |  5 | Monopylephorus rubroniveus; Monopylephorus rubroniveus corderoi; Monopylephorus rubroniveus iturupi; Monopylephorus kermadecensis; Monopylephorus rubroniveus ponticus |
| Navicula cryptocephala |     6 | 37 | 31 | Navicula cryptocephala; Navicula cryptocephala f. cryptocephala; Navicula cryptocephala f. minuta; Navicula cryptocephala f. nanissima; Navicula cryptocephala f. parva; Navicula cryptocephala f. terrestris; Navicula veneta var. veneta; Navicula cryptocephala var. angusta; Navicula angustata var. angustata; Navicula cryptocephala var. australis (+21 more) |
| Nitzschia fonticola |     6 | 13 | 12 | Nitzschia fonticola; Nitzschia palea var. fonticola; Nitzschia fonticola f. minutissima; NA; Nitzschia baikalensis; Nitzschia fonticola var. capitata; Nitzschia fonticola var. constricta; Nitzschia fonticola var. fonticola; Nitzschia fonticola var. genuina; Nitzschia fonticola var. pelagica (+2 more) |
| Noemacheilus barbatulus |     6 |  2 |  2 | Barbatula barbatula; Barbatula quignardi |
| Oocystis naegelii |     6 |  8 |  8 | Oocystis naegelii; Oocystis irregularis; Oocystis biplacata; Oocystis naegelii var. curta; Oocystis naegelii var. incrassata; Oocystis naegelii var. minutissima; Oocystis novae-semliae; Oocystis naegelii var. obesa |
| Ophionereis dubia |     6 |  6 |  3 | Ophionereis (Ophiotriton) dubia; Ophionereis (Ophiotriton) amoyensis; Ophionereis dubia dubia |
| Paracalanus parvus |     6 |  8 |  5 | Paracalanus parvus parvus; Paracalanus parvus borealis; Paracalanus parvus major; Paracalanus parvus minor; Paracalanus parvus var. perplexus |
| Penium margaritaceum |     6 | 14 | 12 | Penium margaritaceum; Penium margaritaceum f. elongatum; Penium margaritaceum f. longum; Penium margaritaceum f. majus; Penium margaritaceum var. brevius; Penium margaritaceum var. incognitum; Penium margaritaceum var. indivisum; Penium margaritaceum var. irregulare; Penium margaritaceum var. margaritaceum; Penium margaritaceum var. obesum (+2 more) |
| Planothidium hauckianum |     6 |  4 |  4 | Planothidium hauckianum; Planothidium hauckianum var. rhombicum; Achnanthes hauckiana var. rostrata; Planothidium hauckianum var. rostratum |
| Porphyra yezoensis |     6 |  4 |  4 | Pyropia yezoensis; Porphyra yezoensis f. coreana; Pyropia kinositae; Pyropia yezoensis f. narawaensis |
| Pyganodon grandis |     6 |  2 |  1 | Pyganodon grandis |
| Saccharina japonica |     6 |  6 |  5 | Saccharina japonica; Saccharina japonica var. diabolica; Saccharina japonica f. longipes; Saccharina japonica var. ochotensis; Saccharina japonica var. religiosa |
| Saduria entomon |     6 |  2 |  1 | Saduria entomon |
| Salmo gairdneri |     6 |  9 |  1 | Oncorhynchus mykiss |
| Salvelinus malma |     6 | 11 |  4 | Salvelinus malma; Salvelinus curilus; Salvelinus kuznetzovi; Salvelinus schmidti |
| Staurastrum sp |     6 | 43 | 34 | Staurastrum simonyi var. sparsiaculeatum; NA; Staurastrum sparsum; Staurastrum sparsum var. arthrodesmiforme; Staurastrum spetsbergense; Staurastrum simonyi; Staurastrum quadrispinatum var. spicatum; Staurastrum spiculosum; Staurastrum spiculiferum; Staurastrum spiculiferum f. minor (+24 more) |
| Sterechinus neumayeri |     6 |  4 |  2 | Sterechinus neumayeri; Sterechinus neumayeri nigroalba |
| Synedra ulna |     6 | 50 | 39 | Synedra ulna; Synedra danica; Synedra longissima var. acicularis; Synedra amphirhynchus var. amphirhynchus; Synedra ulna f. arcuata; Synedra balatonis f. balatonis; Synedra biceps f. biceps; Synedra bicurvata; Synedra ulna f. biwensis; Synedra ulna f. brevis (+29 more) |
| Acartia pacifica |     5 |  2 |  2 | Acartia (Odontacartia) pacifica; Acartia (Odontacartia) pacifica mertoni |
| Ambloplites rupestris |     5 |  2 |  1 | Ambloplites rupestris |
| Anabaena circinalis |     5 |  5 |  5 | Dolichospermum sigmoideum; Anabaena circinalis f. hyalinospora; Anabaena circinalis var. crassa; Anabaena circinalis var. macrospora; Anabaena hassallii f. tenuis |
| Ankistrodesmus braunii |     5 |  6 |  6 | Chlorolobion braunii; Ankistrodesmus braunii f. turfosum; Ankistrodesmus braunii var. lacustris; Ankistrodesmus braunii var. minutus; Monoraphidium pusillum; Ankistrodesmus braunii var. pygmaeus |
| Ascomorpha saltans |     5 |  3 |  2 | Ascomorpha saltans; Ascomorpha saltans indica |
| Bulinus globosus |     5 |  2 |  2 | Bulinus globosus; Bulinus ugandae |
| Chalcalburnus chalcoides |     5 | 11 |  7 | Alburnus chalcoides; Alburnus derjugini; Alburnus volviticus; Alburnus mandrensis; Alburnus mento; Alburnus mentoides; Alburnus schischkovi |
| Chlamys asperrimus |     5 |  2 |  1 | Mimachlamys asperrima |
| Chlorella protothecoides |     5 |  4 |  4 | Auxenochlorella protothecoides; Pumiliosphaera acidophila; Jaagichlorella luteoviridis; Chlorella protothecoides var. galactophila |
| Chydorus eurynotus |     5 |  3 |  3 | Chydorus eurynotus; Chydorus eurynotus eurynotus; Chydorus eurynotus strictomarginatus |
| Cipangopaludina chinensis |     5 |  6 |  6 | Margarya chinensis; Cipangopaludina chinensis chinensis; Margarya fluminalis; Margarya compacta; Margarya lecythis; Margarya lecythoides |
| Clarias submarginatus |     5 |  3 |  3 | Clarias submarginatus; Clarias liocephalus; Clarias camerunensis |
| Clupea pallasi |     5 |  8 |  1 | Clupea pallasii |
| Copepoda |     5 |  2 |  2 | Copepoda; Copepoda incertae sedis |
| Filinia longiseta |     5 |  6 |  3 | Filinia longiseta; Filinia saltator; Filinia limnetica |
| Garra rufa |     5 |  5 |  2 | Garra rufa; Garra persica |
| Gobiosoma bosc |     5 |  2 |  1 | Gobiosoma bosc |
| Halteria grandinella |     5 |  3 |  3 | Halteria grandinella; Halteria chlorelligera; Pelagohalteria cirrifera |
| Laminaria hyperborea |     5 |  3 |  2 | Laminaria hyperborea; Laminaria hyperborea f. cucullata |
| Lampsilis teres |     5 |  4 |  1 | Lampsilis teres |
| Micromonas pusilla |     5 |  3 |  3 | Micromonas pusilla; Micromonas pusilla reovirus; Micromonas pusilla virus SP1 |
| Modiolus auriculatus |     5 |  2 |  1 | Modiolus auriculatus |
| Modiolus demissus |     5 |  3 |  2 | Geukensia demissa; Geukensia granosissima |
| Navicula sp |     5 | 45 | 35 | Navicula sparsipunctata; Navicula sparsistriata; Navicula spartinetensis; Navicula spathifera; Navicula spathula; Navicula spatiata; Navicula speciosa; Navicula spectabilis; Navicula spectabilis f. angelorum; Navicula spectabilis f. bullata (+25 more) |
| Oscillatoria laetevirens |     5 |  3 |  3 | Kamptonema laetevirens; Oscillatoria laetevirens var. minima; NA |
| Phormidium tenue |     5 |  7 |  7 | Leptolyngbya tenuis; Phormidium tenue f. nonconstrictum; Phormidium tenue var. chlorina; NA; Leptolyngbya granulifera; Leptolyngbya marina; Phormidium tenue var. minus |
| Physa sp |     5 |  4 |  4 | Physella acuta; Physella spelunca; Mayabina spiculata; Bulinus forskalii |
| Pila ovata |     5 |  3 |  3 | Pila ovata; Pila ovata gordoni; Pila ovata ovata |
| Planorbis planorbis |     5 |  4 |  3 | Planorbis planorbis; Planorbis planorbis planorbis; Planorbis tangitarensis |
| Plectus parietinus |     5 |  2 |  2 | Plectus parietinus; Plectus australis |
| Pleurocera uncialis |     5 |  3 |  3 | Pleurocera uncialis; Pleurocera uncialis hastata; Pleurocera uncialis uncialis |
| Porites lutea |     5 |  2 |  1 | Porites lutea |
| Pseudosuccinea columella |     5 |  5 |  1 | Pseudosuccinea columella |
| Scenedesmus incrassatulus |     5 |  4 |  3 | Tetradesmus incrassatulus; Scenedesmus raciborskii; Scenedesmus incrassatulus var. spinosus |
| Tetraedron minimum |     5 | 15 | 13 | Tetraedron minimum; Tetraedron minimum f. apiculatum; Tetraedron minimum f. elegans; Tetraedron minimum f. polypapillatum; Tetraedron minimum var. tetralobulatum; Tetraedron minimum f. trigonum; Tetraedron minimum var. australe; Tetraedron minimum var. longispinum; Tetraedron minimum var. minimum; Tetraedron minimum var. morsum (+3 more) |
| Trichocerca pusilla |     5 |  2 |  1 | Trichocerca pusilla |
| Uronema marinum |     5 |  2 |  2 | Uronema marinum; NA |
| Viviparus georgianus |     5 |  5 |  1 | Callinina georgiana |
| Acanthocyclops vernalis |     4 | 12 | 11 | Acanthocyclops vernalis vernalis; Acanthocyclops vernalis aculeata; Acanthocyclops vernalis ambigua; Acanthocyclops vernalis brevispinosus; Acanthocyclops vernalis elongatus; Acanthocyclops vernalis infesta; Acanthocyclops orientalis; Acanthocyclops vernalis ornatus; Acanthocyclops parcus; Acanthocyclops vernalis robustus (+1 more) |
| Acartia bifilosa |     4 |  3 |  2 | Acartia (Acanthacartia) bifilosa; NA |
| Anabaena spiroides |     4 | 28 | 18 | Dolichospermum spiroides; Anabaena spiroides; Anabaena spiroides f. africana; Anabaena spiroides f. baltica; Dolichospermum compactum; Anabaena spiroides var. contracta; Dolichospermum crassum; Anabaena bolochonzewii; Anabaena bolochonceviana; Dolichospermum circinale (+8 more) |
| Anodonta sp |     4 |  2 |  2 | Cristaria plicata; Chambardia rubens |
| Aplocheilus panchax |     4 |  9 |  2 | Aplocheilus panchax; Aplocheilus parvus |
| Caligus elongatus |     4 |  2 |  2 | Caligus coryphaenae; Caligus elongatus |
| Cephalobus persegnis |     4 | 11 |  8 | Cephalobus persegnis; Eucephalobus mucronatus; Acrobeloides buetschlii; Cephalobus dubius apicatus; Acrobeloides dubius; Acrobeloides nanus; Panagrolaimus paranensis; Cephalobus persegnis setifera |
| Chlorococcum humicola |     4 |  2 |  1 | Chlorococcum infusionum |
| Chlorogonium elongatum |     4 |  5 |  5 | Chlorogonium elongatum; Chlorogonium elongatum var. aculeatum; Chlorogonium elongatum var. opulentum; Chlorogonium elongatum var. plurivacuolatum; Chlorogonium elongatum var. truncatum |
| Closterium moniliferum |     4 | 34 | 28 | Closterium moniliferum; Closterium moniliferum f. angulatum; Closterium moniliferum f. boryanum; Closterium moniliferum f. ehrenbergianum; Closterium moniliferum var. giganteum; NA; Closterium moniliferum f. intermedia; Closterium moniliferum f. kuetzingiana; Closterium moniliferum f. leibleiniana; Closterium moniliferum f. leibleinii (+18 more) |
| Craterocephalus stercusmuscarum |     4 |  3 |  2 | Craterocephalus stercusmuscarum; Craterocephalus fulvus |
| Cryptophyceae |     4 |  2 |  2 | Cryptophyceae; Cryptophyceae incertae sedis |
| Cyclops bicuspidatus |     4 |  7 |  6 | Diacyclops bicuspidatus bicuspidatus; Diacyclops bicuspidatus jurinei; Diacyclops bicuspidatus lubbocki; Diacyclops navus; Diacyclops odessanus; Diacyclops thomasi |
| Dactylogyrus vastator |     4 |  2 |  2 | Dactylogyrus vastator; Dactylogyrus vastator var. minor |
| Diogenes pugilator |     4 |  7 |  3 | Diogenes pugilator; Diogenes denticulatus; Diogenes ovatus |
| Echinometra lucunter |     4 |  4 |  4 | Echinometra lucunter; Echinometra lucunter lucunter; Echinometra lucunter polypora; Echinometra mathaei violacea |
| Epithemia adnata |     4 | 10 |  8 | Frustulia adnata; Epithemia zebra var. genuina; Epithemia adnata var. intermedia; Epithemia zebra var. minor; Epithemia porcellus; Epithemia proboscidea; Epithemia adnata var. proboscidea; Epithemia saxonica |
| Fragilaria ulna |     4 | 14 | 13 | Bacillaria ulna; Fragilaria ulna f. continua; Fragilaria ulna f. contracta; Synedra acus f. acus; Synedra amphirhynchus var. amphirhynchus; Fragilaria ulna var. amphyrhynchus; Synedra biceps f. biceps; Synedra ulna var. contracta; Synedra danica; Synedra goulardi f. goulardi (+3 more) |
| Gammarus zaddachi |     4 |  2 |  2 | Gammarus zaddachi; Gammarus oceanicus |
| Gobius minutus |     4 |  6 |  4 | Pomatoschistus minutus; Pomatoschistus lozanoi; Pomatoschistus microps; Pomatoschistus norvegicus |
| Gomphonema pumilum |     4 |  5 |  4 | Gomphonema intricatum var. pumila; Gomphonema pumilum f. biseriatum; Gomphonema pumilum var. elegans; Gomphonema pumilum var. rigidum |
| Graptoleberis testudinaria |     4 |  3 |  3 | Graptoleberis testudinaria; Graptoleberis testudinaria occidentalis; Graptoleberis testudinaria testudinaria |
| Heliocidaris erythrogramma |     4 |  8 |  3 | Heliocidaris erythrogramma; Heliocidaris erythrogramma armigera; Heliocidaris erythrogramma erythrogramma |
| Ichthyobodo necator |     4 |  2 |  1 | Ichthyobodo necator |
| Ilyodrilus frantzi |     4 |  5 |  1 | Ilyodrilus frantzi |
| Kappaphycus alvarezii |     4 |  2 |  2 | Kappaphycus alvarezii; Kappaphycus alvarezii var. tambalang |
| Lampsilis radiata |     4 |  7 |  3 | Lampsilis radiata; Lampsilis siliquoidea; Lampsilis splendida |
| Lyngbya sp |     4 | 10 | 10 | Ulothrix speciosa; Pseudoscytonema sphaerocephalum; Lyngbya spiralis; Lyngbya spiralis f. crassivaginata; Lyngbya spiraloides; Limnothrix pseudospirulina; Lyngbya spirulinoides; Lyngbya spirulinoides var. minor; Lyngbya spissa; Lyngbya splendens |
| Macrobrachium sp |     4 |  3 |  3 | Macrobrachium spelaeus; Macrobrachium spinipes; Macrobrachium spinosum |
| Micractinium pusillum |     4 |  8 |  4 | Micractinium pusillum; Micractinium pusillum f. quadrisetum; NA; Micractinium pusillum var. elegans |
| Modiolus modiolus |     4 |  4 |  3 | Modiolus modiolus; Modiolus kurilensis; Modiolus squamosus |
| Murex trunculus |     4 | 40 |  1 | Hexaplex trunculus |
| Nais communis |     4 |  4 |  2 | Nais communis; Nais communis magenta |
| Nostoc sphaericum |     4 |  4 |  3 | Nostoc sphaericum; Nostoc sphaericum var. cylindrosporum; NA |
| Pagurus bernhardus |     4 |  5 |  2 | Pagurus bernhardus; Pagurus ochotensis |
| Panulirus argus |     4 |  2 |  2 | Panulirus argus; Panulirus meripurpuratus |
| Perinereis nuntia |     4 |  8 |  7 | Perinereis nuntia; Perinereis vallata; Perinereis nuntia djiboutensis; Perinereis nuntia heterodonta; Perinereis majungaensis; Perinereis nuntia typica; Perinereis nuntia var. bombayensis |
| Platyias quadricornis |     4 | 11 |  3 | Platyias quadricornis; Platyias quadricornis andhraensis; Platyias leloupi |
| Proasellus meridianus |     4 |  4 |  3 | Proasellus meridianus meridianus; Proasellus meridianus belgicus; Proasellus meridianus xavieri |
| Protosiphon botryoides |     4 |  2 |  2 | Protosiphon botryoides; Protosiphon botryoides f. parieticola |
| Prymnesiophyceae |     4 |  2 |  2 | Coccolithophyceae; Prymnesiophyceae incertae sedis |
| Pungitius pungitius |     4 |  4 |  3 | Pungitius pungitius; Pungitius sinensis; Pungitius tymensis |
| Richardsonius balteatus |     4 |  3 |  1 | Richardsonius balteatus |
| Salvelinus leucomaenis |     4 |  4 |  1 | Salvelinus leucomaenis |
| Sarotherodon galilaeus |     4 |  6 |  1 | Sarotherodon galilaeus |
| Sphaerium corneum |     4 |  4 |  2 | Sphaerium corneum; Sphaerium nucleus |
| Staurastrum sebaldi |     4 | 45 | 34 | Staurastrum sebaldi; Staurastrum sebaldi f. africanum; Staurastrum sebaldi f. alatum; NA; Staurastrum sebaldi f. armatum; Staurastrum sebaldi f. bifidum; Staurastrum sebaldi f. elongatum; Staurastrum sebaldi f. groenlandica; Staurastrum sebaldi f. macedoniensis; Staurastrum sebaldi f. minor (+24 more) |
| Syngnathus abaster |     4 |  3 |  1 | Syngnathus abaster |
| Thalassiosira fluviatilis |     4 |  3 |  3 | Conticribra weissflogii; Thalassiosira fluviatilis f. fluviatilis; Thalassiosira fluviatilis f. mangrovii |
| Tilapia galilaea |     4 |  6 |  1 | Sarotherodon galilaeus |
| Trochus maculatus |     4 |  2 |  2 | Trochus maculatus; Calliostoma laugieri |
| Vibrio fischeri |     4 |  2 |  2 | Vibrio fischeri; Aliivibrio fischeri |
| Zeuxapta seriolae |     4 |  2 |  2 | Zeuxapta seriolae; Zeuxapta australica |
| Acropora surculosa |     3 |  2 |  2 | Acropora surculosa; Acropora turbinata |
| Adineta vaga |     3 |  8 |  5 | Adineta vaga; Adineta vaga major; Adineta vaga minor; Adineta rhomboidea; Adineta vaga tenuicornis |
| Anonyx nugax |     3 |  3 |  3 | Anonyx sarsi; Anonyx nugax; Anonyx pacificus |
| Asterionella japonica |     3 |  4 |  3 | Asterionella japonica; Asterionella japonica f. spiroides; Asterionella japonica f. tropicum |
| Aulacoseira granulata |     3 |  8 |  7 | Aulacoseira granulata; Melosira granulata f. curvata; Melosira granulata f. spiralis; Melosira granulata f. angustissima; Melosira granulata var. jonensis; Melosira muzzanensis; Aulacoseira granulata var. valida |
| Barbus sp |     3 |  8 |  7 | Poropuntius speleops; Barbus sperchiensis; Chagunius chagunio; Puntius spilopterus; Systomus spilurus; Neolissochilus spinulosus; Enteromius ablabes |
| Bellerochea malleus |     3 |  9 |  7 | Bellerochea malleus; Bellerochea malleus f. biangularis; Bellerochea malleus var. biangulata; Triceratium malleus var. malleus; Bellerochea malleus f. quadrangularis; Triceratium malleus var. tetragona; Bellerochea malleus f. triangularis |
| Bithynia leachi |     3 |  4 |  3 | Bithynia leachii; Bithynia prespensis; Bithynia italica |
| Brachidontes exustus |     3 |  2 |  1 | Brachidontes exustus |
| Brachionus urceolaris |     3 |  9 |  8 | Brachionus urceolaris; Brachionus amazonicus; Brachionus angularis; Brachionus urceolaris reductispinis; Brachionus rubens; Brachionus urceolaris sericus; Brachionus sericus; Brachionus urceolaris var. armatus |
| Bulinus tropicus |     3 |  2 |  1 | Bulinus tropicus |
| Calothrix marchica |     3 |  3 |  3 | Calothrix marchica; Calothrix marchica var. crassa; Calothrix marchica var. intermedia |
| Cardium edule |     3 | 19 |  2 | Cerastoderma edule; Cerastoderma glaucum |
| Chara aspera |     3 | 34 |  9 | Chara aspera; Chara curta; Chara canescens; Chara aspera var. equisetifolia; Chara galioides; Chara macounii; NA; Chara aspera var. nodulifera; Chara aspera var. subinermis |
| Chara baltica |     3 | 12 |  9 | Chara baltica; Chara baltica f. densa; Chara baltica var. liljebladii; Chara andina; Chara baltica var. baltica; Chara baltica var. borealis; Chara baltica var. breviaculeata; Chara baltica var. densa; Chara horrida |
| Chlorella salina |     3 |  2 |  1 | Chlorella salina |
| Cladophora fracta |     3 | 50 | 29 | Cladophora fracta; Cladophora rivularis; Cladophora fracta f. breviarticulata; Cladophora glomerata; Cladophora glomerata var. crassior; Cladophora fracta f. fuscescens; Cladophora fracta f. globulina; Cladophora fracta f. gossypina; Cladophora fracta f. gracilis; Cladophora hauckii (+19 more) |
| Cryptomonas ozolini |     3 |  2 |  2 | Cryptomonas pyrenoidifera; NA |
| Elliptio buckleyi |     3 |  5 |  1 | Elliptio jayensis |
| Elliptio dilatata |     3 |  4 |  1 | Eurynia dilatata |
| Entosiphon sulcatum |     3 |  2 |  2 | Entosiphon sulcatum; Entosiphon sulcatum var. tricostatum |
| Euchaeta marina |     3 |  2 |  2 | Euchaeta marina; Euchaeta marina longispina |
| Eucyclops agilis |     3 |  4 |  3 | Eucyclops (Eucyclops) pectinifer pectinifer; Eucyclops agilis montanus; Eucyclops (Speratocyclops) speratus speratus |
| Euglena mutabilis |     3 |  5 |  5 | Euglena mutabilis; NA; Euglena mutabilis var. lefevrei; Euglena mutabilis var. mainxi; Euglena mutabilis var. pseudolaminata |
| Gambusia patruelis |     3 |  2 |  2 | Gambusia affinis; Gambusia holbrooki |
| Gobius microps |     3 |  3 |  1 | Pomatoschistus microps |
| Goniobasis livescens |     3 |  4 |  1 | Elimia livescens |
| Grateloupia dichotoma |     3 |  3 |  2 | Dermocorynus dichotomus; NA |
| Haliotis midae |     3 |  3 |  1 | Haliotis midae |
| Helisoma campanulatum |     3 |  6 |  2 | Planorbella campanulata; Planorbella campanulata collinsi |
| Heteromastus filiformis |     3 |  2 |  2 | Heteromastus filiformis; Heteromastus filiformis laminariae |
| Hyalella sp |     3 |  2 |  2 | Hyalella spelaea; Hyalella spinicauda |
| Liza carinata |     3 |  2 |  1 | Planiliza carinata |
| Lynceus brachyurus |     3 |  3 |  1 | Lynceus brachyurus |
| Metamysidopsis elongata |     3 |  3 |  2 | Metamysidopsis elongata; Metamysidopsis atlantica |
| Navicula salinarum |     3 | 20 | 17 | Navicula salinarum; Navicula salinarum f. arcuata; Navicula salinarum f. capitata; NA; Navicula salinarum f. minima; Navicula salinarum f. parallela; Navicula salinarum f. salinarum; Navicula salinarum var. capitata; Navicula salinarum var. genuina; Navicula salinarum var. gracilior (+7 more) |
| Nitella hyalina |     3 | 19 |  9 | Nitella hyalina; Nitella hyalina var. brachyactis; Nitella hyalina f. formosa; Nitella hyalina f. maxima; Nitella hyalina var. aberrans; Nitella hyalina var. engelmanni; Nitella hyalina var. hyalina; Nitella hyalina var. indica; Nitella hyalina var. novae zeelandiae |
| Nitzschia sigma |     3 | 46 | 44 | Nitzschia sigma; Nitzschia sigma f. brevior; Nitzschia clausii f. clausii; Nitzschia sigma f. elongatae; Nitzschia sigma f. genuina; Nitzschia sigma f. habirshawii; Nitzschia sigma f. indica; Nitzschia sigma f. longissima; Nitzschia sigma f. major; Nitzschia maxima f. maxima (+34 more) |
| Nostoc punctiforme |     3 |  7 |  4 | Nostoc punctiforme; Nostoc punctiforme f. populorum; NA; Nostoc punctiforme var. fuscescens |
| Nymphaea odorata |     3 |  2 |  2 | Nymphaea odorata; Nymphaea odorata subsp. odorata |
| Orconectes neglectus |     3 |  2 |  2 | Faxonius neglectus; Faxonius neglectus chaenodactylus |
| Paramelita nigroculus |     3 |  2 |  1 | Paramelita nigroculus |
| Patella caerulea |     3 |  3 |  2 | Patella caerulea; Patella ulyssiponensis |
| Phagocata gracilis |     3 |  5 |  3 | Phagocata gracilis; Phagocata monopharyngea; Phagocata woodworthi |
| Plectonema boryanum |     3 |  2 |  2 | Leptolyngbya boryana; Pseudophormidium hollerbachianum |
| Pontoporeia affinis |     3 |  2 |  2 | Monoporeia affinis; Monoporeia microphthalma |
| Ptychobranchus fasciolaris |     3 |  4 |  1 | Ptychobranchus fasciolaris |
| Rhinichthys cataractae |     3 |  5 |  1 | Rhinichthys cataractae |
| Scenedesmus bicaudatus |     3 |  2 |  2 | Desmodesmus bicaudatus; Desmodesmus armatus var. bicaudatus |
| Scenedesmus intermedius |     3 | 10 |  8 | Desmodesmus intermedius; Scenedesmus intermedius f. danubialis; Scenedesmus soli; Scenedesmus intermedius f. longispinus; Scenedesmus intermedius var. acaudatus; Desmodesmus intermedius var. acutispinus; Desmodesmus intermedius var. balatonicus; NA |
| Schoenoplectus tabernaemontani |     3 |  4 |  2 | Schoenoplectus tabernaemontani; NA |
| Segmentina nitida |     3 |  2 |  2 | Segmentina nitida; Kolhymorbis angarensis |
| Semibalanus balanoides |     3 |  2 |  2 | Semibalanus balanoides; Semibalanus balanoides calcaratus |
| Sillago ciliata |     3 |  2 |  1 | Sillago ciliata |
| Sillago maculata |     3 |  5 |  3 | Sillago maculata; Sillago aeolus; Sillago burrus |
| Siphonaria capensis |     3 |  2 |  1 | Siphonaria capensis |
| Sparus macrocephalus |     3 |  2 |  1 | Acanthopagrus schlegelii |
| Surirella angusta |     3 | 23 | 20 | Surirella angusta; Surirella angusta f. angusta; Surirella angusta f. constricta; Surirella angusta f. ovata; Surirella angusta f. punctata; Surirella angusta var. amoyensis; Surirella angusta var. apiculata; NA; Surirella angusta var. constricta; Surirella angusta var. contorta (+10 more) |
| Synedra rumpens |     3 | 22 | 20 | Fragilaria capucina subsp. rumpens; Synedra rumpens f. constricta; Synedra rumpens f. curta; Synedra rumpens f. familiaris; Synedra rumpens f. fragilarioides; Synedra rumpens f. major; Synedra rumpens f. meneghiniana; Synedra rumpens f. nipponica; Synedra rumpens f. parva; Synedra familiaris f. familiaris (+10 more) |
| Tilapia rendalli |     3 |  5 |  1 | Coptodon rendalli |
| Tilapia spilurus |     3 |  3 |  2 | Tilapia spilurus; Oreochromis spilurus |
| Urosolenia eriensis |     3 |  2 |  2 | Rhizosolenia eriensis f. eriensis; Rhizosolenia eriensis f. morsa |
| Acanthocyclops viridis |     2 |  4 |  3 | Megacyclops viridis viridis; Megacyclops viridis deserticola; Megacyclops viridis oligotrichus |
| Acanthodiaptomus denticornis |     2 |  3 |  2 | Acanthodiaptomus denticornis denticornis; Acanthodiaptomus denticornis molvensis |
| Acartia sp |     2 |  2 |  2 | Acartia (Acanthacartia) spinata; Acartia (Odontacartia) spinicauda |
| Acipenser gueldenstaedtii |     2 |  4 |  2 | Acipenser gueldenstaedtii; Acipenser persicus |
| Actinia equina |     2 | 25 | 22 | Actinia equina; Actinia sali; Actinia cari; Actinia equina castanea; Actinia equina coccinea; Actinia equina concentrica; Actinia equina equina; Actinia equina glauca; Actinia equina hemisphaerica; Actinia equina hepatica (+12 more) |
| Alpheus malabaricus |     2 |  4 |  2 | Alpheus malabaricus; Alpheus songkla |
| Amphipleura pellucida |     2 | 16 | 12 | Amphipleura pellucida; Amphipleura pellucida f. minor; Amphipleura pellucida var. brasiliensis; Amphipleura pellucida var. craticula; Amphipleura pellucida var. intermedia; Amphipleura lindheimeri var. lindheimeri; Amphipleura maxima; Amphipleura oregonica; Frustulia pellucida; Amphipleura pellucida var. recta (+2 more) |
| Anisakis simplex |     2 |  4 |  3 | Anisakis simplex; Anisakis pegreffii; Anisakis berlandi |
| Anodonta piscinalis |     2 |  8 |  2 | Anodonta anatina; Anodonta cygnea |
| Arenicola cristata |     2 |  2 |  2 | Arenicola cristata; Arenicola brasiliensis |
| Argulus japonicus |     2 |  2 |  2 | Argulus japonicus; Argulus japonicus europaeus |
| Astacus fluviatilis |     2 |  2 |  2 | Astacus astacus astacus; Austropotamobius fulcisianus fulcisianus |
| Astasia longa |     2 |  2 |  2 | Euglena longa; Astasia longa var. truncata |
| Aulacoseira ambigua |     2 |  4 |  4 | Aulacoseira ambigua; Aulacoseira ambigua f. curvata; Aulacoseira ambigua f. japonica; Melosira ambigua f. spiralis |
| Australorbis glabratus |     2 |  2 |  1 | Biomphalaria glabrata |
| Bacillariophyceae |     2 |  2 |  2 | Bacillariophyceae; Bacillariophyceae incertae sedis |
| Barbus anoplus |     2 |  5 |  1 | Enteromius anoplus |
| Barbus sarana |     2 |  3 |  2 | Systomus sarana; Systomus rubripinnis |
| Buccinum undatum |     2 | 11 |  1 | Buccinum undatum |
| Calanus finmarchicus |     2 |  5 |  2 | Calanus finmarchicus; Calanus ponticus |
| Caridina denticulata |     2 |  7 |  7 | Neocaridina denticulata; Neocaridina anhuiensis; Neocaridina denticulata denticulata; Neocaridina ishigakiensis; Neocaridina keunbaei; Neocaridina davidi; Neocaridina palmata palmata |
| Chaetogaster diaphanus |     2 |  4 |  2 | Chaetogaster diaphanus; Chaetogaster diaphanus litoralis |
| Cheirodon interruptus |     2 |  3 |  2 | Cheirodon interruptus; Cheirodon ibicuhiensis |
| Chlamydomonas globosa |     2 |  3 |  3 | Chlamydomonas globosa; Chlamydomonas globosa var. arenariae; Chlamydomonas globosa var. maculata |
| Chrysichthys longidorsalis |     2 |  3 |  2 | Chrysichthys longidorsalis; Chrysichthys nyongensis |
| Clibanarius longitarsus |     2 |  3 |  1 | Clibanarius longitarsus |
| Coelastrum astroideum |     2 |  2 |  2 | Coelastrum astroideum; Coelastrum rugosum |
| Coelastrum cambricum |     2 |  8 |  8 | Coelastrum cambricum; Coelastrum pulchrum var. colliferum; Coelastrum cambricum var. cristata; Coelastrum pulchrum var. cruciatum; NA; Coelastrum cambricum var. intermedium; Coelastrum rugosum; Coelastrum stuhlmannii |
| Colurella uncinata |     2 |  4 |  4 | Colurella uncinata; Colurella uncinata bicuspidata; Colurella uncinata deflexa; Colurella uncinata ornata |
| Corophium spinicorne |     2 |  2 |  2 | Americorophium spinicorne; Crassicorophium crassicorne |
| Cottus cognatus |     2 |  2 |  1 | Cottus cognatus |
| Crangon sp |     2 |  3 |  3 | Metacrangon spinirostris; Metacrangon spinosissima; Pontophilus spinosus |
| Craterocephalus stercusmuscar |     2 |  3 |  2 | Craterocephalus stercusmuscarum; Craterocephalus fulvus |
| Craticula cuspidata |     2 |  3 |  3 | Frustulia cuspidata; Navicula cuspidata f. major; Navicula cuspidata var. media |
| Cryptomonas tetrapyrenoidosa |     2 |  2 |  2 | Cryptomonas tetrapyrenoidosa; NA |
| Cyclops varicans |     2 |  4 |  4 | Microcyclops varicans varicans; Microcyclops (Microcyclops) furcatus; Microcyclops (Microcyclops) rubellus; Cyclops varicans rubens |
| Cymbella affinis |     2 | 28 | 25 | Cymbella affinis; Cymbella affinis f. affinis; Cymbella affinis f. curta; Cymbella excisa; Cymbella affinis f. venter; Cymbella affinis f. ventriconcava; Cymbella affinis var. afarensis; Cymbella affinis var. angusta; Cymbella affinis var. elegans; Cymbella affinis var. genuina (+15 more) |
| Cymbella microcephala |     2 | 12 | 11 | Encyonopsis microcephala; Cymbella microcephala f. intermedia; Cymbella microcephala f. major; Cymbella microcephala f. minor; Encyonopsis robusta; Cymbella microcephala f. sublinearis; Cymbella microcephala f. subrostrata; Cymbella microcephala f. undulata; Cymbella microcephala var. crassa; Cymbella microcephala var. robusta (+1 more) |
| Cymbella minuta |     2 |  7 |  7 | Cymbella minuta; Cymbella latens; Cymbella ventricosa var. groenlandica; Cymbella minuta var. minuta; Cymbella turgida var. pseudogracilis; Cymbella affinis var. semicircularis; Cymbella silesiaca |
| Diacyclops bicuspidatus |     2 | 10 |  8 | Diacyclops bicuspidatus bicuspidatus; Diacyclops bicuspidatus jurinei; Diacyclops limnobius; Diacyclops bicuspidatus lubbocki; Diacyclops bicuspidatus lucanus; Diacyclops navus; Diacyclops odessanus; Diacyclops thomasi |
| Diatoma hiemale |     2 | 33 | 27 | Fragilaria hiemalis; Odontidium anomalum var. curtum; Diatoma hiemale f. curta; Diatoma anceps var. genuinum; Odontidium glaciale; Diatoma hiemale f. inaequalis; Fragilaria mesodon; Diatoma hiemale f. rotundata; Diatoma anceps var. subconstrictum; Diatoma hiemale var. truncatum (+17 more) |
| Diatoma vulgaris |     2 | 34 | 33 | Diatoma vulgaris; Diatoma vulgaris f. ("lusus") flectata; Diatoma vulgaris f. abbreviata; Diatoma vulgaris f. asymmetrica; Diatoma vulgaris f. capitata; Diatoma vulgaris f. caudatum; Diatoma vulgaris f. cuneata; Diatoma vulgaris f. deforme; Diatoma vulgaris f. elliptica; Diatoma vulgaris f. ellipticum (+23 more) |
| Dictyosphaerium pulchellum |     2 |  6 |  3 | Mucidosphaerium pulchellum; NA; Hindakia tetrachotoma |
| Dinophyceae |     2 |  2 |  2 | Dinophyceae; Dinophyceae incertae sedis |
| Emiliania huxleyi |     2 |  6 |  6 | Gephyrocapsa huxleyi; Emiliania huxleyi var. aurorae; Emiliania huxleyi var. corona; Emiliania huxleyi var. kleijneae; Emiliania huxleyi var. pujosae; Emiliania huxleyi virus 86 |
| Ensis minor |     2 |  4 |  3 | Ensis megistus coseli; Ensis minor; Ensis megistus |
| Enteromorpha sp |     2 |  4 |  4 | Enteromorpha spermatoidea; Ulva clathrata; Enteromorpha spinescens f. major; Enteromorpha spinescens f. minor |
| Esomus danrica |     2 |  3 |  2 | Esomus danrica; Esomus thermoicos |
| Fucus spiralis |     2 | 12 |  3 | Fucus spiralis; Fucus guiryi; Fucus spiralis var. lutarius |
| Gammarus balcanicus |     2 | 10 |  5 | Gammarus balcanicus; Gammarus albimanus; Gammarus anatoliensis; Gammarus dacicus; Gammarus halilicae |
| Gammarus komareki |     2 |  2 |  2 | Gammarus komareki; Gammarus komareki aznavensis |
| Gomphonema truncatum |     2 | 12 | 12 | Gomphonema truncatum; Gomphonema constrictum f. bipunctata; Gomphonema capitatum f. capitatum; Gomphonema italicum; Gomphonema truncatum f. robustum; Gomphonema turgidum; Gomphonema truncatum var. capitatum; Gomphonema constrictum var. cuneata; Gomphonema constrictum var. elongata; Gomphonema truncatum var. macilentum (+2 more) |
| Gomphosphaeria lacustris |     2 |  3 |  2 | Snowella lacustris; Woronichinia compacta |
| Goniastrea retiformis |     2 |  3 |  2 | Goniastrea retiformis; Goniastrea edwardsi |
| Haliotis fulgens |     2 |  5 |  5 | Haliotis fulgens; Haliotis fulgens fulgens; Haliotis fulgens guadalupensis; Haliotis fulgens turveri; Haliotis walallensis |
| Hexaplex trunculus |     2 |  2 |  2 | Hexaplex trunculus; Hexaplex trunculus trunculus |
| Hydrobia ulvae |     2 |  2 |  1 | Peringia ulvae |
| Hydrolithon onkodes |     2 |  3 |  3 | Porolithon onkodes; NA; Hydrolithon onkodes f. subramosum |
| Kirchneriella irregularis |     2 |  3 |  3 | Kirchneriella irregularis; NA; Kirchneriella irregularis var. spiralis |
| Lasmigona costata |     2 |  7 |  2 | Lasmigona costata; Platynaias compressa |
| Leander squilla |     2 |  5 |  2 | Palaemon adspersus; Palaemon elegans |
| Limnodrilus udekemianus |     2 |  3 |  2 | Limnodrilus udekemianus; Limnodrilus profundicola |
| Lymnaea emarginata |     2 |  3 |  3 | Ladislavella emarginata; Ladislavella mighelsi; Ladislavella catascopium |
| Mayamaea atomus |     2 |  3 |  3 | Amphora atomus; Navicula atomus var. alcimonica; Navicula permitis |
| Meloidogyne incognita |     2 |  3 |  2 | Meloidogyne incognita; Meloidogyne inornata |
| Mesidotea entomon |     2 |  5 |  1 | Saduria entomon |
| Mesostoma ehrenbergi |     2 |  3 |  1 | Mesostoma ehrenbergii |
| Microcystis firma |     2 |  2 |  2 | Microcystis firma; NA |
| Misgurnus mizolepis |     2 | 10 |  4 | Misgurnus mizolepis; Misgurnus anguillicaudatus; Misgurnus multimaculatus; Misgurnus tonkinensis |
| Myoxocephalus quadricornis |     2 |  7 |  1 | Myoxocephalus quadricornis |
| Navicula minima |     2 | 14 | 13 | Navicula minima; Navicula minima f. magis; Navicula minima f. magis stauroneiformis; Navicula minima f. minima; Navicula atomoides f. atomoides; Navicula minima var. atomoides; Navicula minima var. atomus; Navicula minima var. genuina; Navicula minima var. minima; Navicula minima var. okamurae (+3 more) |
| Navicula schroeteri |     2 |  3 |  3 | Navicula schroeteri; Navicula schroeteri var. escambia; Navicula schroeteri var. schroeteri |
| Navicula tripunctata |     2 |  9 |  9 | Vibrio tripunctatus; Navicula tripunctata f. minor; Navicula tripunctata var. arctica; Navicula gracilis var. cuneata; Navicula tripunctata var. flavescens; Navicula tripunctata var. minor; Navicula gracilis var. schizonemoides; Navicula tripunctata var. tripunctata; Navicula tripunctata var. viridis |
| Nitzschia paleacea |     2 |  3 |  3 | Nitzschia paleacea; Nitzschia paleacea var. baikalensis; Nitzschia paleacea var. ebroicensis |
| Nitzschia perminuta |     2 |  3 |  3 | Nitzschia perminuta; Nitzschia perminuta f. curta; Nitzschia frustulum f. perminuta |
| Nostoc linckia |     2 |  7 |  6 | Nostoc linckia; NA; Nostoc linckia f. piscinale; Nostoc linckia f. spongieaforme; Trichormus arvensis; Nostoc linckia var. crispulum |
| Notholca acuminata |     2 |  9 |  4 | Notholca acuminata; Notholca acuminata cincta; Notholca acuminata extensa; Notholca marina |
| Obovaria subrotunda |     2 |  7 |  2 | Obovaria subrotunda; Obovaria unicolor |
| Oedogonium cardiacum |     2 | 14 | 10 | Oedogonium cardiacum; Oedogonium cardiacum f. amurense; Oedogonium cardiacum f. interjectum; NA; Oedogonium cardiacum f. pulchellum; Oedogonium cardiacum f. thermale; Oedogonium cardiacum var. carbonicum; Oedogonium cardiacum var. explens; Oedogonium cardiacum var. minor; Oedogonium cardiacum var. minus |
| Oocystis borgei |     2 |  4 |  4 | Oocystis borgei; Oocystis borgei f. nivicola; Oocystis borgei var. hypanica; Oocystis borgei var. indica |
| Opsopoeodus emiliae |     2 |  3 |  1 | Opsopoeodus emiliae |
| Pagrus auratus |     2 |  2 |  2 | Pagrus auratus; Sparus aurata |
| Palaemon paucidens |     2 |  2 |  2 | Palaemon paucidens; Macrobrachium lanchesteri |
| Palaemon sp |     2 |  7 |  6 | Macrobrachium lar; Macrobrachium placidulum; Macrobrachium spinipes; Macrobrachium birmanicum; Oplophorus spinosus; NA |
| Pandalus borealis |     2 |  4 |  2 | Pandalus borealis; Pandalus eous |
| Paracalliope fluviatilis |     2 |  2 |  2 | Paracalliope fluviatilis; Indocalliope indica |
| Paracyclops fimbriatus |     2 | 13 | 11 | Paracyclops fimbriatus fimbriatus; Paracyclops fimbriatus abnobensis; Paracyclops hardingi; Paracyclops baicalensis; Paracyclops fimbriatus bromeliarum; Paracyclops chiltoni; Paracyclops fimbriatus euchaetus; Paracyclops imminutus; Paracyclops fimbriatus orientalis; Paracyclops fimbriatus paropamisi (+1 more) |
| Patella aspera |     2 |  3 |  2 | Patella aspera; Patella gomesii |
| Pediastrum boryanum |     2 | 47 | 15 | Pseudopediastrum boryanum; Pediastrum boryanum var. brevicorne; Pediastrum boryanum f. brevicorne; NA; Pseudopediastrum boryanum var. longicorne; Pediastrum boryanum f. punctata; Pediastrum boryanum f. reticulatum; Pediastrum boryanum subsp. perforatum; Pediastrum boryanum var. australe; Pediastrum boryanum var. capitatum (+5 more) |
| Pediastrum sp |     2 |  2 |  2 | NA; Pediastrum spinosum |
| Pelvetia canaliculata |     2 | 10 |  1 | Pelvetia canaliculata |
| Periophthalmus dipus |     2 |  3 |  1 | Periophthalmus argentilineatus |
| Pisidium sp |     2 |  6 |  3 | Euglesa adamsii; Pisidium sphaeriiforme; Euglesa nitida |
| Portunus sanguinolentus |     2 |  3 |  2 | Portunus sanguinolentus; Portunus hawaiiensis |
| Posthodiplostomum minimum |     2 |  3 |  3 | Posthodiplostomum minimum; Posthodiplostomum centrarchi; Posthodiplostomum vancleavei |
| Potamocorbula amurensis |     2 |  2 |  1 | Potamocorbula amurensis |
| Pristina longiseta |     2 |  5 |  2 | Pristina (Pristina) longiseta; Pristina (Pristina) leidyi |
| Pseudanabaena catenata |     2 |  2 |  2 | Pseudanabaena catenata; Pseudanabaena starmachii |
| Purpura lapillus |     2 | 14 |  1 | Nucella lapillus |
| Rasbora sp |     2 |  2 |  2 | Rasbosoma spilocerca; Rasbora spilotaenia |
| Rhodeus sericeus |     2 |  4 |  2 | Rhodeus sericeus; Rhodeus amarus |
| Rhopalodia gibba |     2 | 41 | 37 | Rhopalodia gibba; Rhopalodia gibba f. balatonica; Epithemia gibberula var. directa; Epithemia gibba var. genuina; Navicula gibba; Rhopalodia gibba f. gracilis; Rhopalodia gibba f. longissima; Rhopalodia gibba f. minutissima; Rhopalodia gibba f. ovalis; Epithemia ventricosa (+27 more) |
| Sarotherodon mossambicus |     2 |  3 |  2 | Oreochromis mossambicus; Oreochromis mortimeri |
| Scenedesmus aristatus |     2 |  2 |  2 | Scenedesmus protuberans var. aristatus; Scenedesmus aristatus var. major |
| Scenedesmus denticulatus |     2 | 16 | 16 | Desmodesmus denticulatus; Scenedesmus denticulatus f. carinatus; Scenedesmus denticulatus f. granulatus; Desmodesmus serratus; Scenedesmus denticulatus f. maximus; Scenedesmus denticulatus var. australis; Scenedesmus denticulatus var. brevispinus; Scenedesmus denticulatus var. costatogranulatus; Scenedesmus denticulatus var. disciformis; NA (+6 more) |
| Scenedesmus dispar |     2 | 10 |  9 | Desmodesmus dispar; Scenedesmus dispar f. denticulatus; Scenedesmus dispar f. elegans; Scenedesmus dispar f. semidenticulatus; Scenedesmus dispar f. spinosus; Scenedesmus dispar var. costatogranulatus; NA; Scenedesmus dispar var. rabae; Scenedesmus dispar var. robustus |
| Scenedesmus maximus |     2 |  4 |  4 | Desmodesmus maximus; Desmodesmus tropicus; NA; Desmodesmus maximus var. peruviensis |
| Scenedesmus platydiscus |     2 |  2 |  2 | Scenedesmus platydiscus; Scenedesmus platydiscus var. pentarch |
| Scenedesmus tropicus |     2 |  2 |  1 | Desmodesmus tropicus |
| Stephanodiscus invisitatus |     2 |  2 |  2 | Stephanodiscus invisitatus; Stephanodiscus invisitatus f. hakanssoniae |
| Stylonychia mytilus |     2 |  2 |  1 | Stylonychia mytilus |
| Testudinella parva |     2 |  5 |  4 | Testudinella parva; Testudinella parva dissimilis; Testudinella parva semiparva; Testudinella parva triangulata |
| Theodoxus fluviatilis |     2 |  7 |  5 | Theodoxus fluviatilis; Theodoxus fluviatilis fluviatilis; Theodoxus fluviatilis sardous; Theodoxus thermalis; Theodoxus fluviatilis transversetaeniatus |
| Tisbe furcata |     2 |  4 |  3 | Tisbe furcata furcata; Tisbe furcata johnsoni; Tisbe furcata tuberculata |
| Tolypothrix limbata |     2 |  2 |  2 | Tolypothrix limbata; Tolypothrix limbata var. cylindrica |
| Trichocerca capucina |     2 |  2 |  2 | Trichocerca capucina; Trichocerca multicrinis |
| Tropocyclops prasinus |     2 | 17 | 16 | Tropocyclops prasinus prasinus; Tropocyclops prasinus altoandinus; Tropocyclops prasinus aztequei; Tropocyclops breviramus; Tropocyclops candidiusi; Tropocyclops prasinus divergens; Tropocyclops prasinus guawana; Tropocyclops jerseyensis; Tropocyclops prasinus meridionalis; Tropocyclops prasinus mexicanus (+6 more) |
| Undinula vulgaris |     2 |  7 |  1 | Undinula vulgaris |
| Volvulina steinii |     2 |  4 |  4 | Volvulina steinii; Volvulina steinii var. lenticularis; Volvulina steinii var. parvicellula; Volvulina steinii var. subreniformis |
| Vorticella campanula |     2 |  2 |  2 | Vorticella campanula; Vorticella campanulata |
| Acanthocyclops robustus |     1 | 10 |  9 | Acanthocyclops robustus robustus; Acanthocyclops robustus alphnes; Acanthocyclops robustus armata; Acanthocyclops robustus brevispinosus; Acanthocyclops robustus insueta; Acanthocyclops americanus americanus; Acanthocyclops robustus saxonica; Acanthocyclops robustus setiger; Acanthocyclops robustus typica |
| Adlafia bryophila |     1 |  2 |  2 | Adlafia bryophila; Navicula bryophila f. constricta |
| Anodonta cataracta |     1 |  4 |  2 | Pyganodon cataracta; Pyganodon fragilis |
| Anodonta complanata |     1 |  6 |  2 | Pseudanodonta complanata; Anodonta anatina |
| Anomia ephippium |     1 | 11 |  1 | Anomia ephippium |
| Aphyosemion gardneri |     1 |  7 |  4 | Fundulopanchax gardneri; Fundulopanchax clauseni; Fundulopanchax lacustris; Fundulopanchax mamfensis |
| Apocryptes bato |     1 |  2 |  1 | Apocryptes bato |
| Asplanchna sieboldi |     1 |  4 |  2 | Asplanchna sieboldii; Asplanchna brightwellii |
| Bithynia sp |     1 |  2 |  2 | Bithynia boissieri; Pseudovivipara manchourica |
| Bourletiella spinata |     1 |  2 |  1 | Bourletiella hortensis |
| Branchiobdella parasita |     1 |  5 |  4 | Branchiobdella parasita; Branchiobdella astaci; Branchiobdella hexadonta; Branchiobdella pentadonta |
| Calothrix braunii |     1 |  5 |  5 | Calothrix braunii; Calothrix braunii f. major; Calothrix braunii var. contorta; Calothrix braunii var. maxima; Calothrix braunii var. mollis |
| Caridina indistincta |     1 |  3 |  2 | Caridina indistincta; Caridina sobrina |
| Chaetoceros decipiens |     1 | 14 | 13 | Chaetoceros decipiens; Chaetoceros decipiens f. barrowensis; Chaetoceros decipiens f. decipiens; Chaetoceros decipiens f. divaricata; Chaetoceros decipiens f. hiemalis; Chaetoceros decipiens f. interrupta; Chaetoceros decipiens f. macroporica; Chaetoceros decipiens f. princeps; Chaetoceros decipiens f. singularis; Chaetoceros decipiens var. concreta (+3 more) |
| Chaetoceros didymus |     1 | 19 | 17 | Chaetoceros didymus; Chaetoceros didymus f. adriatica; Chaetoceros didymus f. aestiva; Chaetoceros didymus f. autumnalis; Chaetoceros didymus f. didymus; Chaetoceros didymus f. genuina; Chaetoceros didymus f. rectus; Chaetoceros didymus f. singularis; Chaetoceros didymus var. aggregata; Chaetoceros anglicus (+7 more) |
| Chodatella ciliata |     1 |  3 |  3 | Lagerheimia ciliata; Franceia amphitricha; Lagerheimia ciliata var. minor |
| Chondrosia reniformis |     1 |  2 |  2 | Chondrosia reniformis; Chondrosia rugosa |
| Cladocera |     1 |  2 |  2 | Diplostraca; Cladocera incertae sedis |
| Closterium lanceolatum |     1 | 10 | 10 | Closterium lanceolatum; Closterium lanceolatum f. angustum; Closterium lanceolatum f. minor; Closterium lanceolatum f. parvum; Closterium lanceolatum f. sigmoideum; Closterium lanceolatum var. bernardi; Closterium lanceolatum var. coloratum; Closterium lanceolatum var. elongatum; Closterium lanceolatum var. majus; Closterium lanceolatum var. parvum |
| Closterium lunula |     1 | 33 | 26 | Closterium lunula; Closterium lunula f. biconvexum; Closterium lunula var. biconvexum; NA; Closterium lunula f. farcinalis; Closterium lunula f. gracile; Closterium lunula f. levanderi; Closterium lunula f. nasutum; Closterium lunula f. retusum; Closterium lunula f. striata (+16 more) |
| Clupea harengus pallasi |     1 |  4 |  1 | Clupea pallasii |
| Cocconeis sp |     1 | 12 |  9 | Cocconeis sparsipunctata; Cocconeis spathulatum; Cocconeis speciosa; Cocconeis speciosa var. cruciata; Cocconeis speciosa var. speciosa; Cocconeis spina-christi; Cocconeis splendida var. splendida; Cocconeis splendida var. crucifera; Cocconeis splendida var. lucida |
| Coelastrum morus |     1 |  3 |  3 | Coelastrum sphaericum; Coelastrum verrucosum f. acutiverrucosum; Coelastrum morus f. capensis |
| Coelastrum reticulatum |     1 |  4 |  3 | Hariotina reticulata; Coelastrum reticulatum var. duplex; Coelastrum reticulatum var. cubanum |
| Corydoras melanistius |     1 |  3 |  3 | Corydoras melanistius; Corydoras brevirostris; Corydoras ambiacus |
| Cosmarium botrytis |     1 | 24 | 21 | Cosmarium botrytis; Cosmarium botrytis f. latum; Cosmarium botrytis var. afganicum; Cosmarium botrytis var. canadense; Cosmarium botrytis var. dayense; Cosmarium botrytis var. depressum; Cosmarium botrytis var. emarginatum; Cosmarium botrytis var. gemmiferum; NA; Cosmarium botrytis var. hyacinthi (+11 more) |
| Crepidula convexa |     1 |  2 |  1 | Crepidula convexa |
| Cyclops vicinus |     1 |  6 |  5 | Cyclops vicinus vicinus; Cyclops vicinus brevicornis; Cyclops vicinus glacialis; Cyclops kikuchii; Cyclops vicinus lobosus |
| Cyclotella cryptica |     1 |  2 |  2 | Cyclotella cryptica; Cyclotella cryptica var. ambigua |
| Cymbella aspera |     1 | 22 | 18 | Cymbella aspera; Cymbella aspera f. baicalensis; Cocconema asperum; Cymbella bengalensis; Cymbella aspera var. elongata; Cymbella aspera var. fossilis; Cymbella aspera var. genuina; Cymbella aspera var. gigantea; Cymbella aspera var. gigas; Cymbella aspera var. incerta (+8 more) |
| Cyprinion watsoni |     1 |  2 |  1 | Cyprinion watsoni |
| Cypris pubera |     1 |  5 |  1 | Cypris pubera |
| Elakatothrix gelatinosa |     1 |  4 |  4 | Elakatothrix gelatinosa; Elakatothrix biplex; Elakatothrix gelatinosa f. minor; Elakatothrix gelatinosa var. aplanospora |
| Enchytraeus albidus |     1 |  2 |  1 | Enchytraeus albidus |
| Enchytraeus buchholzi |     1 |  4 |  2 | Enchytraeus buchholzi; Enchytraeus australis |
| Ensis siliqua |     1 |  2 |  2 | Ensis siliqua; Ensis minor |
| Epithemia cistula |     1 |  9 |  8 | Eunotia cistula; Epithemia cistula; Epithemia cistula var. acuta; Epithemia cistula var. crassa; Epithemia cistula var. lunaris; Epithemia cistula var. proboscidea; Epithemia cistula var. producta; Epithemia cistula var. undulata |
| Euastrum verrucosum |     1 | 48 | 40 | Euastrum verrucosum; Euastrum verrucosum f. alpina; Euastrum verrucosum var. alpinum; Euastrum verrucosum f. altaicum; Euastrum verrucosum f. angustisinuatum; NA; Euastrum verrucosum f. cyclops; Euastrum verrucosum f. evoluta; Euastrum verrucosum f. evolutum; Euastrum verrucosum f. extensum (+30 more) |
| Eucalanus elongatus |     1 |  5 |  3 | Eucalanus elongatus elongatus; Eucalanus bungii; Eucalanus inermis |
| Eucocconeis flexella |     1 |  5 |  5 | Cymbella flexella; Achnanthes flexella var. alpestris; Eucocconeis flexella var. lusus-appendiculata; Eucocconeis flexella var. montana; Eucocconeis flexella var. naviculoides |
| Eucyclops serrulatus |     1 | 18 | 17 | Eucyclops (Eucyclops) serrulatus serrulatus; Eucyclops serrulatus agilis; Eucyclops (Macrurocyclops) macrurus; Eucyclops serrulatus brevicaudata; Eucyclops (Eucyclops) chilensis chilensis; Eucyclops (Eucyclops) defectus; Eucyclops (Denticyclops) denticulatus; Eucyclops (Eucyclops) elegans elegans; Eucyclops (Eucyclops) agiloides roseus; Eucyclops (Eucyclops) serrulatus hadjebensis (+7 more) |
| Favites abdita |     1 |  7 |  1 | Favites abdita |
| Fragilaria capucina var. mesolepta |     1 |  2 |  1 | Fragilaria capucina var. mesolepta |
| Galaxea fascicularis |     1 |  8 |  1 | Galaxea fascicularis |
| Gayralia oxysperma |     1 |  2 |  2 | Gayralia oxysperma; Gayralia oxysperma f. wittrockii |
| Gloeocapsa crepidinum |     1 |  2 |  2 | Gloeocapsopsis crepidinum; Gloeocapsa crepidinum var. ghazipurensis |
| Gloeocapsa sanguinea |     1 |  2 |  2 | Gloeocapsa sanguinea; Gloeocapsa sanguinea var. grandis |
| Gobius sp |     1 |  4 |  4 | Glossogobius giuris; Istigobius spence; Amblygobius sphynx; Gobius cobitis |
| Goniobasis sp |     1 |  5 |  4 | Elimia laqueata; Elimia dislocata; Elimia paupercula; Elimia arachnoidea |
| Gonyaulax sp |     1 |  5 |  3 | Gonyaulax sphaeroidea; Gonyaulax spinifera; Gonyaulax spinosa |
| Gracilaria vermiculophylla |     1 |  2 |  2 | Gracilaria vermiculophylla; Gracilaria vermiculophylla var. zhengii |
| Gyrosigma spencerii |     1 |  8 |  8 | Gyrosigma acuminatum; Gyrosigma spencerii; NA; Pleurosigma spenceri f. curvula; Gyrosigma spencerii var. halophila; Pleurosigma nodiferum; Gyrosigma spencerii var. nodifera; Pleurosigma spencerii var. smithii |
| Haliotis sp |     1 |  4 |  4 | Haliotis spadicea; Haliotis tuberculata; Haliotis fulgens fulgens; Haliotis cracherodii cracherodii |
| Hepsetus odoe |     1 |  2 |  2 | Hepsetus odoe; Hepsetus lineatus |
| Hiatella arctica |     1 |  3 |  1 | Hiatella arctica |
| Hippoglossus hippoglossus |     1 |  2 |  2 | Hippoglossus hippoglossus; Hippoglossus stenolepis |
| Holosticha kessleri |     1 |  2 |  2 | Holosticha gibba; Holosticha pullaster |
| Hydrobia ventrosa |     1 |  3 |  3 | Ecrobia ventrosa; Potamopyrgus antipodarum; Caspiohydrobia eichwaldiana |
| Hypomesus olidus |     1 |  3 |  1 | Hypomesus olidus |
| Karayevia clevei |     1 |  5 |  5 | Karayevia clevei; Achnanthes clevei f. rostrata; Achnanthes clevei f. balcanica; Achnanthes clevei var. bottnica; Achnanthes clevei var. rostrata |
| Lecane bulla |     1 | 12 |  5 | Lecane bulla; Lecane bulla diabolica; Lecane bulla f. alveola; Lecane bulla papillosa; Lecane styrax |
| Lecane cornuta |     1 |  3 |  2 | Lecane cornuta; Lecane closterocerca |
| Lepidonotus squamatus |     1 |  2 |  2 | Lepidonotus squamatus; Lepidonotus angustus |
| Leuciscus rutilus |     1 | 16 |  2 | Rutilus rutilus; Rutilus caspicus |
| Littorina obtusata |     1 | 36 |  3 | Littorina obtusata; Littorina obtusata littoralis; Littorina fabalis |
| Lysmata seticaudata |     1 |  2 |  2 | Lysmata seticaudata; Lysmata ternatensis |
| Mesocyclops thermocyclopoides |     1 |  4 |  3 | Mesocyclops thermocyclopoides thermocyclopoides; Mesocyclops thermocyclopoides acutus; Mesocyclops australiensis |
| Mesostoma ehrenbergii |     1 |  2 |  1 | Mesostoma ehrenbergii |
| Mesotaenium caldariorum |     1 |  2 |  2 | Mesotaenium caldariorum; Mesotaenium caldariorum var. gracile |
| Micropterus treculi |     1 |  2 |  1 | Micropterus treculii |
| Molgula sp |     1 |  3 |  3 | Molgula sphaera; Molguloides sphaeroidea; Molgula spiralis |
| Myoxocephalus scorpius |     1 |  3 |  1 | Myoxocephalus scorpius |
| Mytilus sp |     1 |  3 |  3 | Mytilus edulis; Modiolus capax; Semimytilus patagonicus |
| Nematoda |     1 |  6 |  5 | Nematoda; Nematoda incertae sedis; Nematobrachion; Nematobrachion boopis; Nematobrachion flexipes |
| Nitella furcata |     1 | 34 | 28 | Nitella furcata; Nitella mucronata var. brachyteles; Nitella furcata f. burmanica; Nitella flagellifera var. coreana; Nitella oligospira var. dictyosperma; Nitella microcarpa var. glaziovii; Nitella gracilens; Nitella inversa; Nitella japonica; Nitella madagascariensis (+18 more) |
| Nitzschia angularis |     1 | 14 | 13 | Nitzschia angularis; Nitzschia angularis f. angularis; Nitzschia angularis f. minor; Nitzschia angularis f. tenuistriata; Nitzschia angularis f. upolensis; Nitzschia affinis f. affinis; Nitzschia angularis var. australis; Nitzschia angularis var. borealis; Nitzschia angularis var. catalana; Nitzschia angularis var. genuina (+3 more) |
| Nitzschia ovalis |     1 |  4 |  4 | Nitzschia ovalis; Nitzschia ovalis var. antarctica; Nitzschia ovalis var. major; Nitzschia ovalis var. ovalis |
| Nucella lima |     1 |  2 |  2 | Nucella lima; Nucella freycinetii |
| Ochromonas sp |     1 |  2 |  2 | Ochromonas sparsiverrucosa; Ochromonas sphaerocystis |
| Oncorhynchus gilae |     1 |  3 |  2 | Oncorhynchus gilae; Oncorhynchus apache |
| Oocystis pusilla |     1 |  2 |  2 | Oocystis pusilla; Oocystis pusilla var. maior |
| Opsariichthys uncirostris |     1 |  5 |  3 | Opsariichthys uncirostris; Opsariichthys bidens; Opsariichthys hainanensis |
| Parechinus angulosus |     1 |  2 |  1 | Parechinus angulosus |
| Pavlova gyrans |     1 |  2 |  2 | Pavlova gyrans; Pavlova gyrans var. simplex |
| Pecten maximus |     1 |  2 |  2 | Pecten maximus; Pecten sulcicostatus |
| Pediastrum simplex |     1 | 15 |  8 | Monactinus simplex; NA; Pediastrum simplex f. ovata; Monactinus simplex var. sturmii; Monactinus simplex var. biwaensis; Pediastrum simplex var. clathratum; Monactinus simplex var. echinulatum; Pediastrum simplex var. granulatum |
| Physa pomilia |     1 |  3 |  2 | Physella pomilia; Physella hendersoni |
| Planorbella duryi |     1 |  2 |  2 | Planorbella duryi; Planorbella duryi duryi |
| Podura aquatica |     1 |  7 |  1 | Podura aquatica |
| Pomacea patula |     1 |  2 |  2 | Pomacea patula; Pomacea catemacensis |
| Proasellus sp |     1 |  4 |  4 | Proasellus spelaeus; Proasellus anophtalmus anophtalmus; Proasellus aquaecalidae; Proasellus spinipes |
| Pseudocrenilabrus philander |     1 |  4 |  1 | Pseudocrenilabrus philander |
| Puntius sarana |     1 |  5 |  4 | Systomus sarana; Systomus orphoides; Systomus spilurus; Systomus subnasutus |
| Reimeria sinuata |     1 |  3 |  3 | Reimeria sinuata; Cymbella abnormis var. antiqua; Cymbella sinuata var. ovata |
| Rhodomonas lacustris |     1 |  2 |  2 | Rhodomonas lacustris; Plagioselmis nannoplanctica |
| Robertgurneya hopkinsi |     1 |  2 |  1 | Robertgurneya hopkinsi |
| Rutilus rutilus caspicus |     1 |  5 |  2 | Rutilus caspicus; Rutilus rutilus |
| Scytonema multiramosum |     1 |  2 |  2 | Scytonema multiramosum; Scytonema multiramosum var. ceylonicum |
| Sebastes schlegeli |     1 |  2 |  1 | Sebastes schlegelii |
| Selenastrum bibraianum |     1 |  2 |  2 | Selenastrum bibraianum; Messastrum gracile |
| Stigeoclonium amoenum |     1 |  3 |  3 | Stigeoclonium amoenum; NA; Stigeoclonium amoenum var. novizelandicum |
| Stigeoclonium nanum |     1 |  2 |  2 | Stigeoclonium nanum; NA |
| Surirella brebissonii |     1 |  4 |  4 | Surirella brebissonii; Surirella brebissonii var. kuetzingii; Surirella brebissonii var. lineata; Surirella brebissonii var. punctata |
| Surirella tenera |     1 | 28 | 24 | Surirella tenera; Surirella tenera f. constricta; Surirella tenera f. cristata; Surirella tenera f. horrida; Surirella tenera f. manguini; Surirella tenera f. minor; Surirella tenera f. nervosa; Surirella tenera f. punctata; Surirella tenera f. pusilla; Surirella tenera var. subconstricta (+14 more) |
| Tetradesmus obliquus |     1 |  4 |  4 | Tetradesmus obliquus; Tetradesmus obliquus var. alternans; Tetradesmus obliquus var. dactylococcoides; Tetradesmus obliquus var. flexuosus |
| Tetraedron caudatum |     1 |  6 |  4 | Tetraedron caudatum; NA; Tetraedron caudatum var. australe; Tetraedron caudatum var. longispinum |
| Thalassiosira nordenskioeldii |     1 |  3 |  3 | Thalassiosira nordenskioeldii; Thalassiosira nordenskioeldii f. fossilis; Thalassiosira nordenskioeldii f. nordenskioeldii |
| Thalassiosira sp |     1 |  7 |  6 | Thalassiosira spicula; Thalassiosira spinoconvexa; Thalassiosira spinosa; Thalassiosira spinosa var. aspinosa; Thalassiosira spinulata; Thalassiosira spumellaroides |
| Triceratium dubium |     1 |  3 |  3 | Pseudictyota dubium; Triceratium dubium var. dubium; Triceratium dubium var. irregularis |
| Tubifex rivulorum |     1 |  2 |  2 | Tubifex tubifex; Rhyacodrilus coccineus |
| Volvox aureus |     1 |  3 |  3 | Volvox aureus; Volvox aureus f. madagascariensis; Volvox aureus var. hemisphaericus |
| Zannichellia palustris |     1 |  5 |  3 | Zannichellia palustris; Zannichellia palustris subsp. palustris; Zannichellia palustris subsp. pedicellata |

## 7. API error summary

No API errors encountered.

## 8. Habitat coverage check

Restricted to `resolved_by == "worms"` -- GBIF does not provide habitat flags.

- WoRMS-resolved species: 1715
- With a freshwater habitat flag: 1002
- Marine only (no freshwater flag): 649
- Marine + freshwater (both flags): 117
- No habitat data (no flags set): 17

## 9. Recommendations for Part 2

- **Normalisation:** of 113 unresolved species, 0 have a case/whitespace-only variant that already resolved under a different casing/spacing. This is a small fraction -- normalisation alone is unlikely to meaningfully reduce the unresolved set; most failures look like genuine non-matches (placeholders, strain IDs, subfamily/family-level names) rather than casing issues.
- **Manual review feasibility:** 113 unresolved species account for 2,078 rows (0.54% of the 381,410 final clean rows). A queue of this size is borderline for full manual review -- consider triaging by row count (review the high-row-count tail individually; hard-exclude or bulk-flag the long low-row-count tail).
- **Ambiguous matches (1079 species):** 251 of these (see Section 6's `n_unique_names` column) have multiple raw WoRMS records that all trace back to a single accepted name (an accepted species plus its own unaccepted subspecies, picked up by `fuzzy = TRUE` matching on the shared binomial prefix) -- these are false-alarm ambiguity, not genuine taxonomic uncertainty. The remaining 828 have more than one distinct candidate name and need real human judgement. Part 2 should re-classify the former as resolved (using the single unique name) and only carry the latter into manual review.
- **Majorgroup derivation level:** 99 distinct classes observed across resolved species (top 30 shown in Section 3), covering 98.30% of resolved rows with a non-NA class. Class-level coverage or cardinality is less clean than hoped -- consider falling back to phylum for unmappable classes, or reviewing whether order-level mapping is needed for specific taxa.

