# Species Sensitivity Data for fipronil_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***fipronil*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 13
rows and 10 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2023). “Toxicant default guideline
values for aquatic ecosystem protection: Fipronil in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/fipronil-fresh-dgvs-technical-brief.pdf>.

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

- Notes:

  Other notes (chr).

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

print(anzg_fipronil_fresh, n=Inf)
#> # A tibble: 13 × 10
#>     Conc Duration Genus      Group Life_stage Notes Phylum Species Test_endpoint
#>    <dbl> <chr>    <chr>      <chr> <chr>      <chr> <chr>  <chr>   <chr>        
#>  1 0.015 2        Cheumatop… Inse… Larvae     Acut… Arthr… brevil… Mortality    
#>  2 0.023 2        Simulium   Inse… Larvae     Acut… Arthr… vittat… Mortality    
#>  3 0.035 1        Culex      Inse… Larvae     Acut… Arthr… quinqu… Mortality    
#>  4 0.042 2        Chironomus Inse… Larvae     Acut… Arthr… crassi… Mortality    
#>  5 0.042 2        Glyptoten… Inse… Larvae     Acut… Arthr… paripes Mortality    
#>  6 0.043 2        Aedes      Inse… Larvae     Acut… Arthr… taenio… Mortality    
#>  7 0.043 2        Anopheles  Inse… Larvae     Acut… Arthr… quadri… Mortality    
#>  8 0.044 4        Hexagenia  Inse… Nymph      Acut… Arthr… sp.     Mortality    
#>  9 0.087 2        Culex      Inse… Larvae     Acut… Arthr… nigrip… Mortality    
#> 10 0.1   2        Polypedil… Inse… Larvae     Acut… Arthr… nubife… Mortality    
#> 11 0.12  1        Aedes      Inse… Larvae     Acut… Arthr… aegypti Mortality    
#> 12 0.245 2        Chironomus Inse… Larvae     Acut… Arthr… annula… Mortality    
#> 13 0.81  2        Aedes      Inse… Larvae     Acut… Arthr… albopi… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
