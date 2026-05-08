# Anonymous Species Sensitivity Data anon_c

Species Sensitivity Data from anonymous sources.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 16
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

print(anon_c, n=Inf)
#> # A tibble: 16 × 2
#>    Chemical     Conc
#>    <chr>       <dbl>
#>  1 c            32  
#>  2 c         17020  
#>  3 c        143000  
#>  4 c           470  
#>  5 c            14  
#>  6 c           248  
#>  7 c             7.7
#>  8 c            20  
#>  9 c            20  
#> 10 c            20  
#> 11 c           500  
#> 12 c           500  
#> 13 c           500  
#> 14 c           500  
#> 15 c           500  
#> 16 c         13000  
```
