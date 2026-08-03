# Species Sensitivity Data for chlorine_marine

Species Sensitivity Data provided by the Commonwealth Scientific and
Industrial Research Organisation of Australia for ***chlorine*** in
marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 30
rows and 9 columns.

## Details

These data were sourced from: Batley GE, Simpson SL (2020). “Short-Term
Guideline Values for Chlorine in Marine Waters.” *Environmental
Toxicology and Chemistry*. ISSN 15528618.
<https://setac.onlinelibrary.wiley.com/doi/full/10.1002/etc.4661>.

The columns are as follows:

- Conc:

  The chemical concentration in micrograms per Litre (dbl).

- Duration:

  Test duration (chr).

- Group:

  Taxonomic grouping information (chr).

- Life_stage:

  Life stage of the test organism (chr).

- Notes:

  Other notes (chr).

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

print(csiro_chlorine_marine, n=Inf)
#> # A tibble: 30 × 9
#>      Conc Duration Group Life_stage Notes Species Test_endpoint Toxicity_measure
#>     <dbl> <chr>    <chr> <chr>      <chr> <chr>   <chr>         <chr>           
#>  1   90   0.5      Roti… NA         NA    Brachi… LC50          Mortality       
#>  2  687   96       Amph… Adult      NA    Pontog… LC50          Mortality       
#>  3  145   96       Amph… Adult      NA    Anonyx… LC50          Mortality       
#>  4  178   96       Shri… Juvenile … NA    Pandal… LC50          Mortality       
#>  5 2890   1        Lobs… Larvae     NA    Homaru… LC50          Mortality       
#>  6  162   96       Mysid Adult      NA    Neomys… LC50          Mortality       
#>  7   90   96       Shri… Adult      NA    Pandal… LC50          Mortality       
#>  8  134   96       Shri… Adult      NA    Crango… LC50          Mortality       
#>  9 1420   96       Crab  Juvenile … two … Hemigr… LC50          Mortality       
#> 10   54   96       Fish  Fry        NA    Menidi… LC50          Mortality       
#> 11   24   96       Fish  Larvae     NA    Pleuro… LC50          Mortality       
#> 12   32   96       Fish  Juvenile   NA    Oncorh… LC50          Mortality       
#> 13   65   96       Fish  Juvenile   NA    Clupea… LC50          Mortality       
#> 14  167   96       Fish  Juvenile … NA    Gaster… LC50          Mortality       
#> 15   71   96       Fish  Juvenile … NA    Cymato… LC50          Mortality       
#> 16   82   96       Fish  Juvenile … NA    Ammody… LC50          Mortality       
#> 17   73   96       Fish  Juvenile   NA    Paroph… LC50          Mortality       
#> 18    5   0.25     Sea … Sperm      15-m… Strong… EC50          Fertilisation   
#> 19    6.4 0.25     Sea … Sperm      15-m… Dendra… EC50          Fertilisation   
#> 20   25   NA       Oyst… Larvae     geom… Crasso… LC50          Mortality       
#> 21   29   96       Cope… NA         NA    Acarti… LC50          Mortality       
#> 22  220   96       Shri… Adult      NA    Palaem… LC50          Mortality       
#> 23   68   96       Mysid Juvenile   geom… Mysido… LC50          Mortality       
#> 24   37   96       Fish  Juvenile   lowe… Menidi… LC50          Mortality       
#> 25  270   96       Fish  Juvenile   NA    Syngna… LC50          Mortality       
#> 26   80   96       Fish  Juvenile   NA    Gobios… LC50          Mortality       
#> 27  270   76       Fish  Eggs       NA    Morone… LC50          Mortality       
#> 28  200   48       Fish  Eggs       NA    Morone… LC50          Mortality       
#> 29  240   48       Fish  Eggs       NA    Alosa … LC50          Mortality       
#> 30  135   96       Fish  Juvenile   geom… Menidi… LC50          Mortality       
#> # ℹ 1 more variable: Units <chr>
```
