# Species Sensitivity Data for chlorine_marine

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***chlorine*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 29
rows and 8 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2026). “Toxicant default guideline
values for aquatic ecosystem protection: Chlorine in marine water.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/chlorine-marine-dgvs-technical-brief.pdf>.

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

- Species:

  The species binomial name (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

- Units:

  The concentration units of Conc (micrograms per Litre, ug/L) (chr).

## Examples

``` r

print(anzg_chlorine_marine, n=Inf)
#> # A tibble: 29 × 8
#>      Conc Duration    Genus      Group Life_stage Species Toxicity_measure Units
#>     <dbl> <chr>       <chr>      <chr> <chr>      <chr>   <chr>            <chr>
#>  1    6.4 0.003470833 Dendraster Echi… Sperm      excent… Acute EC50       ug/L 
#>  2   90   0.020833333 Brachionus Roti… Not stated plicat… Acute LC50       ug/L 
#>  3   23   4           Crassostr… Moll… Larva      virgin… Acute LC50       ug/L 
#>  4   29   4           Acartia    Crus… Not stated tonsa   Acute LC50       ug/L 
#>  5  687   4           Pontogene… Crus… Adult      sp.     Acute LC50       ug/L 
#>  6  145   4           Anonyx     Crus… Adult      sp.     Acute LC50       ug/L 
#>  7 2890   0.041666667 Homarus    Crus… Larva      americ… Acute LC50       ug/L 
#>  8  162   4           Neomysis   Crus… Adult      sp.     Acute LC50       ug/L 
#>  9   68   4           Mysidopsis Crus… Juvenile   bahia   Acute LC50       ug/L 
#> 10  178   4           Pandalus   Crus… Juvenile … danae   Acute LC50       ug/L 
#> 11   90   4           Pandalus   Crus… Adult      gonurus Acute LC50       ug/L 
#> 12  134   4           Crangon    Crus… Adult      nigric… Acute LC50       ug/L 
#> 13  220   4           Palaemone… Crus… Adult      pugio   Acute LC50       ug/L 
#> 14 1420   4           Hemigraps… Crus… Juvenile … nudus   Acute LC50       ug/L 
#> 15   54   4           Menidia    Fish  Fry        penins… Acute LC50       ug/L 
#> 16   24   4           Pleuronec… Fish  Larva      plates… Acute LC50       ug/L 
#> 17   32   4           Oncorhync… Fish  Juvenile   kisutch Acute LC50       ug/L 
#> 18   65   4           Clupea     Fish  Juvenile   hareng… Acute LC50       ug/L 
#> 19  167   4           Gasterost… Fish  Juvenile … aculea… Acute LC50       ug/L 
#> 20   71   4           Cymatogas… Fish  Juvenile … aggreg… Acute LC50       ug/L 
#> 21   82   4           Ammodytes  Fish  Juvenile … hexapt… Acute LC50       ug/L 
#> 22   73   4           Parophrys  Fish  Juvenile   vetulus Acute LC50       ug/L 
#> 23   37   4           Menidia    Fish  Juvenile   menidia Acute LC50       ug/L 
#> 24  135   4           Menidia    Fish  Juvenile   beryll… Acute LC50       ug/L 
#> 25  270   4           Syngnathus Fish  Juvenile   fuscus  Acute LC50       ug/L 
#> 26   80   4           Gobiosoma  Fish  Juvenile   bosci   Acute LC50       ug/L 
#> 27  270   3.166666667 Morone     Fish  Egg        americ… Acute LC50       ug/L 
#> 28  200   2           Morone     Fish  Egg        saxati… Acute LC50       ug/L 
#> 29  240   2           Alosa      Fish  Egg        aestiv… Acute LC50       ug/L 
```
