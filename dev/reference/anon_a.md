# Anonymous Species Sensitivity Data anon_a

Species Sensitivity Data from anonymous sources.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 18
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

print(anon_a, n=Inf)
#> # A tibble: 18 × 2
#>    Chemical   Conc
#>    <chr>     <dbl>
#>  1 a         500  
#>  2 a        1800  
#>  3 a         120  
#>  4 a         490  
#>  5 a           4  
#>  6 a          16  
#>  7 a        6250  
#>  8 a         100  
#>  9 a        7800  
#> 10 a        7990  
#> 11 a        1360  
#> 12 a        4000  
#> 13 a        1800  
#> 14 a          36.4
#> 15 a         492  
#> 16 a          50  
#> 17 a         200  
#> 18 a        1600  
```
