# Anonymous Species Sensitivity Data anon_d

Species Sensitivity Data from anonymous sources.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 12
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

print(anon_d, n=Inf)
#> # A tibble: 12 × 3
#>    Chemical  Conc Medium 
#>    <chr>    <dbl> <chr>  
#>  1 d         8944 Unknown
#>  2 d        10000 Unknown
#>  3 d         1650 Unknown
#>  4 d         2700 Unknown
#>  5 d        11800 Unknown
#>  6 d         4800 Unknown
#>  7 d          140 Unknown
#>  8 d          229 Unknown
#>  9 d          236 Unknown
#> 10 d          550 Unknown
#> 11 d         2226 Unknown
#> 12 d         5530 Unknown
```
