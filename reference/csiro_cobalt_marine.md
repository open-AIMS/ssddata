# Species Sensitivity Data for cobalt_marine

Species Sensitivity Data provided by the Commonwealth Scientific and
Industrial Research Organisation of Australia for ***cobalt*** in marine
water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 14
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

print(csiro_cobalt_marine, n=Inf)
#> # A tibble: 14 × 7
#>        Conc Duration Group     Life_stage Species Test_endpoint Toxicity_measure
#>       <dbl> <chr>    <chr>     <chr>      <chr>   <chr>         <chr>           
#>  1   590    72       Diatom    Exponenti… Skelet… EC10          Chronic         
#>  2   408    96       Diatom    Exponenti… Nitzsc… EC50          Chronic         
#>  3   880    96       Diatom    Exponenti… Chaeto… EC50          Chronic         
#>  4 12000    96       Green al… Exponenti… Dunali… EC10          Chronic         
#>  5  2480    96       Green al… Exponenti… Platym… EC50          Chronic         
#>  6     1.23 48       Red alga  Adult bra… Champi… EC10          Chronic         
#>  7   206    113 d    Annelid   Post-emer… Neanth… EC10          Chronic         
#>  8  2760    52 d     Mollusc   Adult      Idotea… LC50          Chronic         
#>  9  1660    48       Mollusc   Larvae     Crasso… EC10          Chronic         
#> 10   968    48       Echinode… Embryos    Mytilu… EC10          Chronic         
#> 11  1790    72       Echinode… Embryos    Dendra… EC10          Chronic         
#> 12    42    96       Cnidarian Larvae     Strong… EC10          Chronic         
#> 13 31800    28 d     Fish      Lacerate   Aiptas… EC10          Chronic         
#> 14  2000    28 d     Isopod    Freshly f… Cyprin… EC10          Chronic         
```
