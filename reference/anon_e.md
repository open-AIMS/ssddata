# Anonymous Species Sensitivity Data anon_e

Species Sensitivity Data from anonymous sources.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 17
rows and 2 columns.

## Details

This example data were sourced from:

Fox DR, van Dam RA, Fisher R, Batley GE, Tillmanns AR, Thorley J,
Schwarz CJ, Spry DJ, McTavish K (2021). “Recent developments in Species
Sensitivity Distribution Modeling.” *Environmental Toxicology and
Chemistry*, **40**(2), 293–308.
[doi:10.1002/etc.4925](https://doi.org/10.1002/etc.4925) .
<https://setac.onlinelibrary.wiley.com/doi/abs/10.1002/etc.4925>.

The columns are as follows:

- Chemical:

  The chemical name (chr).

- Conc:

  The chemical concentration in micrograms per Litre (dbl).

## Examples

``` r

print(anon_e, n=Inf)
#> # A tibble: 17 × 2
#>    Chemical    Conc
#>    <chr>      <dbl>
#>  1 e           11.2
#>  2 e           17  
#>  3 e            3.4
#>  4 e            5.5
#>  5 e           20  
#>  6 e         1376  
#>  7 e            0.8
#>  8 e         8200  
#>  9 e         3000  
#> 10 e        29050  
#> 11 e        11290  
#> 12 e         7116  
#> 13 e        13000  
#> 14 e        16400  
#> 15 e        16280  
#> 16 e         7100  
#> 17 e          100  
```
