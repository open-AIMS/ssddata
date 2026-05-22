# Anonymous Species Sensitivity Data anon_b

Species Sensitivity Data from anonymous sources.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 10
rows and 2 columns.

## Details

This example data were sourced from:

DAWE (2021). “Unpublished data, anonymous information supplied by
Department of Agriculture Water and the Environment, Australia.” April
20.

The columns are as follows:

- Chemical:

  The chemical name (chr).

- Conc:

  The chemical concentration in micrograms per Litre (dbl).

## Examples

``` r

print(anon_b, n=Inf)
#> # A tibble: 10 × 2
#>    Chemical  Conc
#>    <chr>    <dbl>
#>  1 b          1  
#>  2 b          2.6
#>  3 b          5.1
#>  4 b          8.4
#>  5 b         13.8
#>  6 b         15.2
#>  7 b         20.7
#>  8 b         31.8
#>  9 b        114  
#> 10 b        125  
```
