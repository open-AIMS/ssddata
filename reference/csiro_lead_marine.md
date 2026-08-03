# Species Sensitivity Data for lead_marine

Species Sensitivity Data provided by the Commonwealth Scientific and
Industrial Research Organisation of Australia for ***lead*** in marine
water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 16
rows and 8 columns.

## Details

These data were sourced from: Batley G (2021). “Unpublished data,
anonymous information.” March 23.

The columns are as follows:

- Conc:

  The chemical concentration in micrograms per Litre (dbl).

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

- Units:

  The concentration units of Conc (micrograms per Litre, ug/L) (chr).

## Examples

``` r

print(csiro_lead_marine, n=Inf)
#> # A tibble: 16 × 8
#>      Conc Duration Group Life_stage Species Test_endpoint Toxicity_measure Units
#>     <dbl> <chr>    <chr> <chr>      <chr>   <chr>         <chr>            <chr>
#>  1  252   4        Gree… Exponenti… Dunall… IC10          Yield            ug/L 
#>  2 1230   3        Diat… Exponenti… Phaeod… IC10          Growth rate      ug/L 
#>  3   29.4 4        Diat… Exponenti… Skelet… IC10          Yield            ug/L 
#>  4   11.9 2        Macr… NA         Champi… EC10          Reproduction     ug/L 
#>  5  397   18       Cope… Nauplii    Tisbe … EC10          Adult survival   ug/L 
#>  6   46   3        Sea … Embryo     Strong… EC10          Abnormalities    ug/L 
#>  7  119   2        Sea … Embryo     Parace… EC10          Larval growth    ug/L 
#>  8  250   3        Sea … Embryo     Dendra… EC10          Growth           ug/L 
#>  9   10   3        Sea … Embryo     Helioc… NOEC          Reproduction     ug/L 
#> 10    7   30       Mysid Neonates   Amerca… EC10          Time to first b… ug/L 
#> 11   51   2        Biva… Embryo     Mytilu… EC10          Abnormalities    ug/L 
#> 12   12.4 2        Biva… Embryo     Mytilu… EC10          Abnormalities    ug/L 
#> 13  931   2        Biva… Embryo     Crasso… EC10          Survival         ug/L 
#> 14   96   126      Poly… Juvenile   Neanth… EC10          Survival         ug/L 
#> 15  230   28       Fish  Embryo     Cyprin… EC10          Dry weight       ug/L 
#> 16   44.3 28       Fish  Larva      Atheri… EC10          Mortality and g… ug/L 
```
