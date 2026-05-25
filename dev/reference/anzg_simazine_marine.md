# Species Sensitivity Data for simazine_marine

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***simazine*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 14
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2026). “Toxicant default guideline
values for aquatic ecosystem protection: Simazine in marine water.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/simazine-marine-dgvs-technical-brief.pdf>.

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

print(anzg_simazine_marine, n=Inf)
#> # A tibble: 14 × 9
#>        Conc Duration Genus         Group Life_stage Phylum Species Test_endpoint
#>       <dbl> <chr>    <chr>         <chr> <chr>      <chr>  <chr>   <chr>        
#>  1    310   3        Ceratoneis    Diat… Exponenti… Bacil… closte… Growth rate  
#>  2    400   10       Chlorococcum  Gree… Not stated Chlor… sp.     Cell density 
#>  3   1000   7        Crassostrea   Biva… Spat       Mollu… virgin… Mortality an…
#>  4    257   14       Cladocopium   Dino… Exponenti… Dinof… goreaui Growth rate  
#>  5   1000   10       Dunaliella    Gree… Not stated Chlor… tertio… Cell density 
#>  6    100   10       Isochrysis    Gold… Not stated Hapto… galbana Cell density 
#>  7 100000   4        Neopanope     Crus… Not stated Arthr… texana  Mortality    
#>  8  10000   2        Palaemonetes  Crus… Not stated Arthr… kadiak… Mortality    
#>  9  11300   4        Penaeus       Crus… Not stated Arthr… duorar… Mortality    
#> 10    100   3        Phaeodactylum Diat… Exponenti… Bacil… tricor… Growth rate  
#> 11     38.4 3        Rhodomonas    Cryp… Exponenti… Crypt… salina  Growth rate  
#> 12    250   5        Skeletonema   Diat… Not stated Bacil… costat… Cell density 
#> 13     37.5 3        Tetraselmis   Gree… Exponenti… Chlor… sp.     Growth rate  
#> 14     60.2 3        Tisochrysis   Gold… Exponenti… Hapto… lutea   Growth rate  
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
