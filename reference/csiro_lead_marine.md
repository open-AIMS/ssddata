# Species Sensitivity Data for lead_marine

Species Sensitivity Data provided by the Commonwealth Scientific and
Industrial Research Organisation of Australia for ***lead*** in marine
water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 16
rows and 7 columns.

## Details

These data were sourced from: Batley G (2021). “Unpublished data,
anonymous information.” March 23.

The columns are as follows:

- Conc:

  The chemical concentration (dbl).

- Duration:

  Test duration (chr).

- Group:

  Taxonomic grouping information (chr).

- Life_stage:

  Life stage of the test organism (chr).

- Species:

  The species names name (chr).

- Test_endpoint:

  Endpoint statistic, EC10, NEC etc (chr).

- Toxicity_measure:

  Type of toxicity measure used (chr).

## Examples

``` r

print(csiro_lead_marine, n=Inf)
#> # A tibble: 16 × 7
#>      Conc Duration Group      Life_stage  Species Test_endpoint Toxicity_measure
#>     <dbl> <chr>    <chr>      <chr>       <chr>   <chr>         <chr>           
#>  1  252   4        Green alga Exponentia… Dunall… IC10          Yield           
#>  2 1230   3        Diatom     Exponentia… Phaeod… IC10          Growth rate     
#>  3   29.4 4        Diatom     Exponentia… Skelet… IC10          Yield           
#>  4   11.9 2        Macroalga  NA          Champi… EC10          Reproduction    
#>  5  397   18       Copepod    Nauplii     Tisbe … EC10          Adult survival  
#>  6   46   3        Sea urchin Embryo      Strong… EC10          Abnormalities   
#>  7  119   2        Sea urchin Embryo      Parace… EC10          Larval growth   
#>  8  250   3        Sea urchin Embryo      Dendra… EC10          Growth          
#>  9   10   3        Sea urchin Embryo      Helioc… NOEC          Reproduction    
#> 10    7   30       Mysid      Neonates    Amerca… EC10          Time to first b…
#> 11   51   2        Bivalve    Embryo      Mytilu… EC10          Abnormalities   
#> 12   12.4 2        Bivalve    Embryo      Mytilu… EC10          Abnormalities   
#> 13  931   2        Bivalve    Embryo      Crasso… EC10          Survival        
#> 14   96   126      Polychaete Juvenile    Neanth… EC10          Survival        
#> 15  230   28       Fish       Embryo      Cyprin… EC10          Dry weight      
#> 16   44.3 28       Fish       Larva       Atheri… EC10          Mortality and g…
```
