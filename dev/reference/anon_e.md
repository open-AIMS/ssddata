# Anonymous Species Sensitivity Data anon_e

Species Sensitivity Data from anonymous sources.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 17
rows and 3 columns.

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

  The chemical concentration (dbl).

- Medium:

  The medium (freshwater, marine, or unknown) (chr).

## Examples

``` r

print(anon_e, n=Inf)
#> # A tibble: 17 × 3
#>    Chemical    Conc Medium 
#>    <chr>      <dbl> <chr>  
#>  1 e           11.2 Unknown
#>  2 e           17   Unknown
#>  3 e            3.4 Unknown
#>  4 e            5.5 Unknown
#>  5 e           20   Unknown
#>  6 e         1376   Unknown
#>  7 e            0.8 Unknown
#>  8 e         8200   Unknown
#>  9 e         3000   Unknown
#> 10 e        29050   Unknown
#> 11 e        11290   Unknown
#> 12 e         7116   Unknown
#> 13 e        13000   Unknown
#> 14 e        16400   Unknown
#> 15 e        16280   Unknown
#> 16 e         7100   Unknown
#> 17 e          100   Unknown
```
