# Anonymous Species Sensitivity Data anon_b

Species Sensitivity Data from anonymous sources.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 10
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

print(anon_b, n=Inf)
#> # A tibble: 10 × 3
#>    Chemical  Conc Medium 
#>    <chr>    <dbl> <chr>  
#>  1 b          1   Unknown
#>  2 b          2.6 Unknown
#>  3 b          5.1 Unknown
#>  4 b          8.4 Unknown
#>  5 b         13.8 Unknown
#>  6 b         15.2 Unknown
#>  7 b         20.7 Unknown
#>  8 b         31.8 Unknown
#>  9 b        114   Unknown
#> 10 b        125   Unknown
```
