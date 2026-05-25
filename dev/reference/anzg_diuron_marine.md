# Species Sensitivity Data for diuron_marine

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***diuron*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 12
rows and 8 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2024). “Toxicant default guideline
values for aquatic ecosystem protection: Diuron in marine water.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/diuron-marine-dgvs-technical-brief.pdf>.

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

- Test_endpoint:

  The test endpoint measure (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

## Examples

``` r

print(anzg_diuron_marine, n=Inf)
#> # A tibble: 12 × 8
#>     Conc Duration Genus  Group Life_stage Species Test_endpoint Toxicity_measure
#>    <dbl> <chr>    <chr>  <chr> <chr>      <chr>   <chr>         <chr>           
#>  1  1.5  3        Chaet… Diat… Exponenti… muelle… Specific gro… Chronic NEC     
#>  2  2    3        Entom… Diat… Not stated punctu… Cell density  Chronic NOEC    
#>  3  2    3        Nitzs… Diat… Not stated closte… Cell density  Chronic NOEC    
#>  4  2.2  3        Nephr… Gree… Not stated pyrifo… Cell density  Chronic EC10    
#>  5  1.64 3        Tetra… Gree… Exponenti… sp.     Specific gro… Chronic EC10    
#>  6  1.7  3        Rhodo… Cryp… Exponenti… salina  Specific gro… Chronic NEC     
#>  7  2.5  14       Clado… Dino… Exponenti… goreaui Specific gro… Chronic EC10    
#>  8  0.54 3        Emili… Gold… Exponenti… huxleyi Cell density  Chronic NOEC    
#>  9  1.09 3        Isoch… Gold… Not stated galbana Cell density  Chronic EC10    
#> 10  0.6  3        Tisoc… Gold… Exponenti… lutea   Specific gro… Chronic EC10    
#> 11  2.3  15       Sacch… Brow… Thalli     japoni… Fresh weight  Chronic EC10    
#> 12  2.5  10       Zoste… Macr… Not stated marina  Biomass (old… Chronic NOEC    
```
