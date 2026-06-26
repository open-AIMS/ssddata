# Stage 4e — Genus-Rank Species Exclusion: Triage Decisions

All genus-rank `accepted_name` entries are excluded from the uncurated aggregation
pipeline (Stage 4e). This covers two sets: (1) the ~10,957 rows whose `accepted_name`
is plainly a bare genus or qualified with sp./spp./cf./aff./nr. (not resolved to
species), and (2) the 16 "floored binomial" entries in the table below — names that
look like binomials in the raw source data but whose resolved `accepted_name` sits at
genus rank. The 8 "correct" entries had their query corrected and were re-resolved via
the Stage 4d Part 2 manual-corrections script; they exit the genus-rank exclusion set.

| original_scientificname | disposition | corrected_name | reason |
|---|---|---|---|
| Artemia parthenogenetica | exclude | — | parthenogenetic Artemia is a multi-lineage species complex; WoRMS unaccepted, no single accepted binomial |
| Panagrellus silusiae | exclude | — | valid as-is but absent from backbone; no synonym to redirect, not recoverable by name correction |
| Hizikia fusiforme | correct | Sargassum fusiforme | established synonym (edible seaweed) |
| Guignotus japonicus | correct | Hydroglyphus japonicus | Guignotus is a junior synonym of Hydroglyphus (genus field already mapped) |
| Pseudanabaena foetida | exclude | — | cyanobacterial name with no confident accepted binomial |
| Echinisca triserialis | correct | Macrothrix triserialis | Echinisca is a synonym of the cladoceran genus Macrothrix (genus field confirms) |
| Chrissia halyi | exclude | — | doubtful/ambiguous identity; no confident accepted binomial |
| Poecilobdella viridis | exclude | — | not confidently placeable to a single accepted species |
| Anacystis alpicola | exclude | — | Anacystis is a rejected cyanobacterial genus; redirect ambiguous |
| Cochliopodium bilimbosum | exclude | — | valid as-is but absent from backbone; no synonym to redirect |
| Eurycyclops agilis | correct | Neocyclops agilis | Eurycyclops is a synonym of the copepod genus Neocyclops (genus field confirms); moderate confidence |
| Chaetocorophium lucasi | exclude | — | valid amphipod as-is but absent from backbone; no synonym to redirect |
| Mugil goorgii | exclude | — | garbled/doubtful epithet; no confident accepted species |
| Barilius varga | exclude | — | epithet appears to be a metathesis of "vagra"; genus placement unstable |
| Belostoma indicum | exclude | — | likely misapplied (Belostoma is New World); ambiguous Old World identity |
| Odagmia ornata | correct | Simulium ornatum | Odagmia is a subgenus/synonym of Simulium; moderate-high confidence |
| Sphaerodema annulatum | correct | Diplonychus annulatus | Sphaerodema is a synonym of the giant water bug genus Diplonychus (genus field confirms) |
| Berosus afairmaiyi | exclude | — | garbled epithet; no confident species |
| Coelambus novemlimeatus | exclude | — | epithet appears misspelled and genus is a synonym of Hygrotus; double uncertainty |
| Oxytrema catenaria | correct | Pleurocera catenaria | Oxytrema is a synonym of the freshwater snail genus Pleurocera (genus field confirms) |
| Palaemonetes setiferus | exclude | — | doubtful/possibly chimeric ("setiferus" is the white-shrimp epithet of Penaeus); identity not confident |
| Paramecium primaurelia | exclude | — | valid sibling species of the P. aurelia complex but absent from backbone; not recoverable |
| Salmo gardieri | correct | Oncorhynchus mykiss | "gardieri" is a misspelling of "gairdneri", the classic rainbow trout synonym now Oncorhynchus mykiss |
| Skeletonema capricornutum | exclude | — | chimeric/erroneous (the epithet "capricornutum" belongs to a green alga, not the diatom Skeletonema) |
