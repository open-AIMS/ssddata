# Species Sensitivity Data for perfluorooctane_sulfonate_pfos_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***perfluorooctane_sulfonate_pfos*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 37
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2026). “Toxicant default guideline
values for aquatic ecosystem protection: Perfluorooctane sulfonate
(PFOS) in freshwater.” Australian and New Zealand Governments and
Australian State and Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/pfos-fresh-dgvs-technical-brief.pdf>.

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

print(anzg_perfluorooctane_sulfonate_pfos_fresh, n=Inf)
#> # A tibble: 37 × 9
#>        Conc Duration Genus         Group Life_stage Phylum Species Test_endpoint
#>       <dbl> <chr>    <chr>         <chr> <chr>      <chr>  <chr>   <chr>        
#>  1  2000    30       Bufo          Amph… Tadpole    Chord… gargar… Mortality    
#>  2    57.6  72       Lithobates    Amph… Tadpole    Chord… catesb… Growth       
#>  3    10    40       Lithobates    Amph… Tadpole    Chord… pipiens Development  
#>  4  1250    36       Xenopus       Amph… Tadpole    Chord… laevis  Growth       
#>  5   590    150      Xenopus       Amph… Embryo     Chord… tropic… Growth       
#>  6 82000    4        Anabaena      Cyan… Not stated Cyano… flos-a… Growth and b…
#>  7  6900    6        Ceriodaphnia  Crus… Neonate    Arthr… dubia   Reproduction 
#>  8   400    28       Cyclops       Crus… Not stated Arthr… diapto… Survival     
#>  9  1000    35       Cyclops       Crus… Not stated Arthr… cantho… Survival     
#> 10     0.4  21       Daphnia       Crus… Neonate    Arthr… carina… Reproduction 
#> 11   933    21       Daphnia       Crus… Neonate    Arthr… magna   Intrinsic po…
#> 12  6000    21       Daphnia       Crus… Neonate    Arthr… pulica… Survival     
#> 13   700    42       Hyalella      Crus… Juvenile   Arthr… azteca  Reproduction 
#> 14    90.6  7        Moina         Crus… Neonate    Arthr… macroc… Reproduction 
#> 15   200    28       Procambarus   Crus… Juvenile   Arthr… fallax… Survival     
#> 16 62300    4        Navicula      Diat… Not stated Bacil… pellic… Growth and c…
#> 17    11    28       Anguilla      Fish  Adult      Chord… anguil… Growth       
#> 18    16    180      Danio         Fish  Embryo F1… Chord… rerio   Growth       
#> 19     4    24       Oryzias       Fish  Embryo F1… Chord… latipes Reproduction 
#> 20    44    21       Pimephales    Fish  Larvae F1… Chord… promel… Growth       
#> 21  2120    30       Pseudorasbora Fish  Adult      Chord… parva   Mortality    
#> 22    40    90       Xiphophorus   Fish  Fry        Chord… helleri Growth       
#> 23  8200    4        Chlorella     Gree… Not stated Chlor… vulgar… Growth and b…
#> 24 49790    4        Desmodesmus   Gree… Exponenti… Chlor… commun… Growth       
#> 25  5300    4        Raphidocelis  Gree… Not stated Chlor… subcap… Growth and b…
#> 26 25000    4        Tetradesmus   Gree… Exponenti… Chlor… obliqu… Growth and b…
#> 27    50    40       Aedes         Inse… Larva 1st… Arthr… aegypti Survival     
#> 28     1.36 16       Chironomus    Inse… Larva      Arthr… dilutus Mortality    
#> 29     7.95 120      Enallagma     Inse… Larva      Arthr… cyathi… Development  
#> 30     0.23 14       Neocloeon     Inse… Larva      Arthr… triang… Growth       
#> 31   300    42       Lemna         Macr… Not stated Trach… gibba   Growth       
#> 32   600    42       Myriophyllum  Macr… Not stated Trach… sibiri… Growth       
#> 33  3300    28       Myriophyllum  Macr… Not stated Trach… spicat… Growth       
#> 34  3000    21       Lymnaea       Moll… Adult      Mollu… stagna… Survival     
#> 35 10000    44       Physa         Moll… Egg F1 ge… Mollu… pomilia Reproduction 
#> 36   200    10       Dugesia       Flat… Fragment   Platy… japoni… Reproduction 
#> 37   100    28       Brachionus    Roti… Neonate    Rotif… calyci… Population   
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
