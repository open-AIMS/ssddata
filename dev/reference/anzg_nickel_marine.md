# Species Sensitivity Data for nickel_marine

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***nickel*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 31
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2026). “Toxicant default guideline
values for aquatic ecosystem protection: Nickel in marine water.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/nickel-marine-dgvs-technical-brief.pdf>.

The columns are as follows:

- Conc:

  The chemical concentration in micrograms per Litre (dbl).

- Duration:

  The duration of the test in days (chr).

- Genus:

  The Genus name (chr).

- Group:

  The taxonomic group (chr).

- Life_stage:

  Life stage of the test organism (chr).

- Phylum:

  The Phylum name (chr).

- Species:

  The species binomial name (chr).

- Test_endpoint:

  The test endpoint measure (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

## Examples

``` r

print(anzg_nickel_marine, n=Inf)
#> # A tibble: 31 × 9
#>       Conc Duration Genus          Group Life_stage Phylum Species Test_endpoint
#>      <dbl> <chr>    <chr>          <chr> <chr>      <chr>  <chr>   <chr>        
#>  1  3700   3        Cyanobium      Cyan… 6 x 10^3 … Cyano… sp.     Growth rate  
#>  2  2870   3        Ceratoneis     Diat… 5-6 d old… Bacil… closte… Growth rate  
#>  3   132   4        Skeletonema    Diat… Not stated Bacil… costat… Growth       
#>  4 17900   4        Dunaliella     Gree… Not stated Chlor… tertio… Growth       
#>  5   250   3        Isochrysis     Brow… 5-6 d old… Hapto… lutea   Growth rate  
#>  6   310   3        Symbiodinium   Dino… 6-7 d old… Dinop… sp.     Growth rate  
#>  7   144   10       Champia        Red … Adult      Rhodo… parvula Reproduction 
#>  8    96.7 10       Macrocystis    Brow… Zoospore   Phaeo… pyrife… Reproduction 
#>  9     5.5 3.33     Acartia        Crus… Egg        Arthr… sinjie… Development  
#> 10    67   4        Amphibalanus   Crus… Nauplius   Arthr… amphit… Metamorphosis
#> 11    10   28       Mysidopsis     Crus… Neonate    Arthr… intii   Survival     
#> 12    61   36       Mysidopsis     Crus… Larva      Arthr… bahia   Reproduction 
#> 13    29.1 25       Tigriopus      Crus… Nauplius … Arthr… japoni… Intrinsic ra…
#> 14   191   2        Dendraster     Echi… Embryo     Echin… excent… Abnormalities
#> 15     2.9 1.67     Diadema        Echi… Larva      Echin… antill… Abnormalities
#> 16    23   2        Diadema        Echi… Gamete     Echin… savign… Fertilisatio…
#> 17    50   3        Paracentrotus  Echi… Embryo     Echin… lividus Larval survi…
#> 18   335   2        Strongylocent… Echi… Embryo     Echin… purpur… Abnormalities
#> 19    21.5 14       Haliotis       Gast… Embryo     Mollu… rufesc… Shell growth 
#> 20    33.6 30       Monodonta      Gast… Juvenile   Mollu… labio   Growth rate  
#> 21    64   4        Nassarius      Gast… Larva      Mollu… dorsat… Growth rate  
#> 22  1680   0.208    Acropora       Cnid… Gamete     Cnida… digiti… Fertilisation
#> 23   920   0.208    Platygyra      Cnid… Gamete     Cnida… daedal… Fertilisation
#> 24    65   28       Exaiptasia     Cnid… Adult      Cnida… pulche… Reproduction 
#> 25   431   4        Crassostrea    Biva… Embryo     Mollu… gigas   Reproduction 
#> 26   270   2        Mytilus        Biva… Embryo     Mollu… gallop… Survival     
#> 27    88   2        Mytilus        Biva… Embryo     Mollu… trosso… Survival     
#> 28    22.5 90       Neanthes       Anne… Adult      Annel… arenac… Reproduction 
#> 29  3600   40       Atherinops     Fish  Embryo     Chord… affinis Larval survi…
#> 30 20300   28       Cyprinodon     Fish  Juvenile   Chord… varieg… Growth       
#> 31  1660   21       Oryzias        Fish  Juvenile   Chord… melast… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
