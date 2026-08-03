# Anonymous Species Sensitivity Data anon_a

Species Sensitivity Data from anonymous sources.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 18
rows and 3 columns.

## Details

This example data were sourced from:

DAWE (2021). “Unpublished data, anonymous information supplied by
Department of Agriculture Water and the Environment, Australia.” April
20.

The columns are as follows:

- Chemical:

  The chemical name (chr).

- Conc:

  The chemical concentration (dbl).

- Medium:

  The medium (freshwater, marine, or unknown) (chr).

## Examples

``` r

print(anon_a, n=Inf)
#> # A tibble: 18 × 3
#>    Chemical   Conc Medium 
#>    <chr>     <dbl> <chr>  
#>  1 a         500   Unknown
#>  2 a        1800   Unknown
#>  3 a         120   Unknown
#>  4 a         490   Unknown
#>  5 a           4   Unknown
#>  6 a          16   Unknown
#>  7 a        6250   Unknown
#>  8 a         100   Unknown
#>  9 a        7800   Unknown
#> 10 a        7990   Unknown
#> 11 a        1360   Unknown
#> 12 a        4000   Unknown
#> 13 a        1800   Unknown
#> 14 a          36.4 Unknown
#> 15 a         492   Unknown
#> 16 a          50   Unknown
#> 17 a         200   Unknown
#> 18 a        1600   Unknown
```
