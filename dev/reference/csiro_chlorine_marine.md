# Species Sensitivity Data for chlorine_marine

Species Sensitivity Data provided by the Commonwealth Scientific and
Industrial Research Organisation of Australia for ***chlorine*** in
marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 30
rows and 2 columns.

## Details

These data were sourced from: Batley GE, Simpson SL (2020). “Short-Term
Guideline Values for Chlorine in Marine Waters.” *Environmental
Toxicology and Chemistry*. ISSN 15528618.
<https://setac.onlinelibrary.wiley.com/doi/full/10.1002/etc.4661>.

The columns are as follows:

- Conc:

  The chemical concentration (dbl).

- Group:

  Taxonomic grouping information (chr).

## Examples

``` r

print(csiro_chlorine_marine, n=Inf)
#> # A tibble: 30 × 2
#>      Conc Group     
#>     <dbl> <chr>     
#>  1   90   Rotifer   
#>  2  687   Amphipod  
#>  3  145   Amphipod  
#>  4  178   Shrimp    
#>  5 2890   Lobster   
#>  6  162   Mysid     
#>  7   90   Shrimp    
#>  8  134   Shrimp    
#>  9 1420   Crab      
#> 10   54   Fish      
#> 11   24   Fish      
#> 12   32   Fish      
#> 13   65   Fish      
#> 14  167   Fish      
#> 15   71   Fish      
#> 16   82   Fish      
#> 17   73   Fish      
#> 18    5   Sea urchin
#> 19    6.4 Sea urchin
#> 20   25   Oyster    
#> 21   29   Copepod   
#> 22  220   Shrimp    
#> 23   68   Mysid     
#> 24   37   Fish      
#> 25  270   Fish      
#> 26   80   Fish      
#> 27  270   Fish      
#> 28  200   Fish      
#> 29  240   Fish      
#> 30  135   Fish      
```
