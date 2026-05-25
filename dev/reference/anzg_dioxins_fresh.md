# Species Sensitivity Data for dioxins_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***dioxins*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 8
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2021). “Toxicant default guideline
values for aquatic ecosystem protection: Dioxins in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/dioxins_fresh_dgv_technical-brief.pdf>.

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

- Species:

  The species binomial name (chr).

- Test_endpoint:

  The test endpoint measure (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

## Examples

``` r

print(anzg_dioxins_fresh, n=Inf)
#> # A tibble: 8 × 9
#>       Conc Duration Genus        Group Life_stage Notes    Species Test_endpoint
#>      <dbl> <chr>    <chr>        <chr> <chr>      <chr>    <chr>   <chr>        
#> 1 0.000024 132      Cyprinus     Fish  Adult      2,3,7,8… carpio  Mortality    
#> 2 0.0001   15       Esox         Fish  Egg        2,3,7,8… lucius  Mortality    
#> 3 0.00056  64       Oncorhynchus Fish  Juvenile   2,3,7,8… kisutch Mortality    
#> 4 0.000015 56       Oncorhynchus Fish  Fry        2,3,7,8… mykiss  Growth       
#> 5 0.0025   11       Oryzias      Fish  Embryo     2,3,7,8… latipes Mortality    
#> 6 0.00059  7        Pimephales   Fish  Embryo     2,3,7,8… promel… Mortality    
#> 7 0.0009   82       Salvelinus   Fish  Egg        2,3,7,8… fontin… Mortality    
#> 8 0.00125  92       Salvelinus   Fish  Egg        2,3,7,8… namayc… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
