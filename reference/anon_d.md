# Anonymous Species Sensitivity Data anon_d

Species Sensitivity Data from anonymous sources.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 12
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

print(anon_d, n=Inf)
#> # A tibble: 12 × 2
#>    Chemical  Conc
#>    <chr>    <dbl>
#>  1 d         8944
#>  2 d        10000
#>  3 d         1650
#>  4 d         2700
#>  5 d        11800
#>  6 d         4800
#>  7 d          140
#>  8 d          229
#>  9 d          236
#> 10 d          550
#> 11 d         2226
#> 12 d         5530
```
