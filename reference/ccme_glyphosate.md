# CCME Species Sensitivity Data for ccme_glyphosate

Species Sensitivity Data from the Canadian Council of Ministers of the
Environment for ***glyphosate***.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 18
rows and 6 columns.

## Details

Additional information is available from CCME (2021). “Glyphosate: Water
Quality Guidelines for the Protection of Aquatic Life.” May 06,
<https://ccme.ca/en/chemical/102>.

The columns are as follows:

- Chemical:

  The chemical (chr).

- Species:

  The species binomial name (chr).

- Conc:

  The chemical concentration (dbl).

- Group:

  The taxonomic group (fct).

- Units:

  The units of Conc (chr).

- Medium:

  The medium (freshwater, marine, etc.) (chr).

## Examples

``` r

print(ccme_glyphosate, n=Inf)
#> # A tibble: 18 × 6
#>    Chemical   Species                           Conc Group        Units Medium  
#>    <chr>      <chr>                            <dbl> <fct>        <chr> <chr>   
#>  1 Glyphosate Oncorhynchus kisutch            130000 Fish         ug/L  Freshwa…
#>  2 Glyphosate Oncorhynchus mykiss             150000 Fish         ug/L  Freshwa…
#>  3 Glyphosate Pimephales promelas              25700 Fish         ug/L  Freshwa…
#>  4 Glyphosate Ceriodaphnia dubia               65000 Invertebrate ug/L  Freshwa…
#>  5 Glyphosate Daphnia magna                    10487 Invertebrate ug/L  Freshwa…
#>  6 Glyphosate Hyalella azteca                  20500 Invertebrate ug/L  Freshwa…
#>  7 Glyphosate Pseudosuccinea columella          3162 Invertebrate ug/L  Freshwa…
#>  8 Glyphosate Anabaena flosaquae               12000 Plant        ug/L  Freshwa…
#>  9 Glyphosate Chlorella pyrenoidosa             3530 Plant        ug/L  Freshwa…
#> 10 Glyphosate Chlorella vulgaris                4696 Plant        ug/L  Freshwa…
#> 11 Glyphosate Lemna gibba                       1587 Plant        ug/L  Freshwa…
#> 12 Glyphosate Myriophyllum sibiricum            1474 Plant        ug/L  Freshwa…
#> 13 Glyphosate Navicula pelliculosa              1800 Plant        ug/L  Freshwa…
#> 14 Glyphosate Potamogeton pectinatus            3162 Plant        ug/L  Freshwa…
#> 15 Glyphosate Pseudokirchneriella subcapitata  10000 Plant        ug/L  Freshwa…
#> 16 Glyphosate Scenedesmus acutus                2820 Plant        ug/L  Freshwa…
#> 17 Glyphosate Scenedesmus obliquus             55858 Plant        ug/L  Freshwa…
#> 18 Glyphosate Scenedesmus quadricauda           1090 Plant        ug/L  Freshwa…
```
