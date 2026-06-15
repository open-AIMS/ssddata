# Anonymous Species Sensitivity Data anon_c

Species Sensitivity Data from anonymous sources.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 16
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

print(anon_c, n=Inf)
#> # A tibble: 16 × 3
#>    Chemical     Conc Medium 
#>    <chr>       <dbl> <chr>  
#>  1 c            32   Unknown
#>  2 c         17020   Unknown
#>  3 c        143000   Unknown
#>  4 c           470   Unknown
#>  5 c            14   Unknown
#>  6 c           248   Unknown
#>  7 c             7.7 Unknown
#>  8 c            20   Unknown
#>  9 c            20   Unknown
#> 10 c            20   Unknown
#> 11 c           500   Unknown
#> 12 c           500   Unknown
#> 13 c           500   Unknown
#> 14 c           500   Unknown
#> 15 c           500   Unknown
#> 16 c         13000   Unknown
```
