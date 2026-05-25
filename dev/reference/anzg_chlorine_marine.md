# Species Sensitivity Data for chlorine_marine

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***chlorine*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 29
rows and 7 columns.

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

## Examples

``` r

print(anzg_chlorine_marine, n=Inf)
#> # A tibble: 29 × 7
#>      Conc Duration    Genus        Group     Life_stage Species Toxicity_measure
#>     <dbl> <chr>       <chr>        <chr>     <chr>      <chr>   <chr>           
#>  1    6.4 0.003470833 Dendraster   Echinode… Sperm      excent… Acute EC50      
#>  2   90   0.020833333 Brachionus   Rotifer   Not stated plicat… Acute LC50      
#>  3   23   4           Crassostrea  Mollusc   Larva      virgin… Acute LC50      
#>  4   29   4           Acartia      Crustace… Not stated tonsa   Acute LC50      
#>  5  687   4           Pontogeneia  Crustace… Adult      sp.     Acute LC50      
#>  6  145   4           Anonyx       Crustace… Adult      sp.     Acute LC50      
#>  7 2890   0.041666667 Homarus      Crustace… Larva      americ… Acute LC50      
#>  8  162   4           Neomysis     Crustace… Adult      sp.     Acute LC50      
#>  9   68   4           Mysidopsis   Crustace… Juvenile   bahia   Acute LC50      
#> 10  178   4           Pandalus     Crustace… Juvenile … danae   Acute LC50      
#> 11   90   4           Pandalus     Crustace… Adult      gonurus Acute LC50      
#> 12  134   4           Crangon      Crustace… Adult      nigric… Acute LC50      
#> 13  220   4           Palaemonetes Crustace… Adult      pugio   Acute LC50      
#> 14 1420   4           Hemigrapsus  Crustace… Juvenile … nudus   Acute LC50      
#> 15   54   4           Menidia      Fish      Fry        penins… Acute LC50      
#> 16   24   4           Pleuronectes Fish      Larva      plates… Acute LC50      
#> 17   32   4           Oncorhynchus Fish      Juvenile   kisutch Acute LC50      
#> 18   65   4           Clupea       Fish      Juvenile   hareng… Acute LC50      
#> 19  167   4           Gasterosteus Fish      Juvenile … aculea… Acute LC50      
#> 20   71   4           Cymatogaster Fish      Juvenile … aggreg… Acute LC50      
#> 21   82   4           Ammodytes    Fish      Juvenile … hexapt… Acute LC50      
#> 22   73   4           Parophrys    Fish      Juvenile   vetulus Acute LC50      
#> 23   37   4           Menidia      Fish      Juvenile   menidia Acute LC50      
#> 24  135   4           Menidia      Fish      Juvenile   beryll… Acute LC50      
#> 25  270   4           Syngnathus   Fish      Juvenile   fuscus  Acute LC50      
#> 26   80   4           Gobiosoma    Fish      Juvenile   bosci   Acute LC50      
#> 27  270   3.166666667 Morone       Fish      Egg        americ… Acute LC50      
#> 28  200   2           Morone       Fish      Egg        saxati… Acute LC50      
#> 29  240   2           Alosa        Fish      Egg        aestiv… Acute LC50      
```
