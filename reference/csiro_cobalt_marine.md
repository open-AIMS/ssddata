# Species Sensitivity Data for cobalt_marine

Species Sensitivity Data provided by the Commonwealth Scientific and
Industrial Research Organisation of Australia for ***cobalt*** in marine
water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 14
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

print(csiro_cobalt_marine, n=Inf)
#> # A tibble: 14 × 8
#>      Conc Duration Group Life_stage Species Test_endpoint Toxicity_measure Units
#>     <dbl> <chr>    <chr> <chr>      <chr>   <chr>         <chr>            <chr>
#>  1 5.9 e2 72       Diat… Exponenti… Skelet… EC10          Chronic          ug/L 
#>  2 4.08e2 96       Diat… Exponenti… Nitzsc… EC50          Chronic          ug/L 
#>  3 8.8 e2 96       Diat… Exponenti… Chaeto… EC50          Chronic          ug/L 
#>  4 1.20e4 96       Gree… Exponenti… Dunali… EC10          Chronic          ug/L 
#>  5 2.48e3 96       Gree… Exponenti… Platym… EC50          Chronic          ug/L 
#>  6 1.23e0 48       Red … Adult bra… Champi… EC10          Chronic          ug/L 
#>  7 2.06e2 113 d    Anne… Post-emer… Neanth… EC10          Chronic          ug/L 
#>  8 2.76e3 52 d     Moll… Adult      Idotea… LC50          Chronic          ug/L 
#>  9 1.66e3 48       Moll… Larvae     Crasso… EC10          Chronic          ug/L 
#> 10 9.68e2 48       Echi… Embryos    Mytilu… EC10          Chronic          ug/L 
#> 11 1.79e3 72       Echi… Embryos    Dendra… EC10          Chronic          ug/L 
#> 12 4.2 e1 96       Cnid… Larvae     Strong… EC10          Chronic          ug/L 
#> 13 3.18e4 28 d     Fish  Lacerate   Aiptas… EC10          Chronic          ug/L 
#> 14 2   e3 28 d     Isop… Freshly f… Cyprin… EC10          Chronic          ug/L 
```
