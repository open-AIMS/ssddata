# Species Sensitivity Data for aluminium_marine

Species Sensitivity Data provided by the Australian Institute of Marine
Science for ***aluminium*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 20
rows and 9 columns.

## Details

These data were sourced from: van Dam JW, Trenfield MA, Streten C,
Harford AJ, Parry D, van Dam RA (2018). “Water quality guideline values
for aluminium, gallium and molybdenum in marine environments.”
*Environmental Science and Pollution Research*, **25**(26), 26592–26602.
ISSN 16147499.
<https://link.springer.com/article/10.1007/s11356-018-2702-y>.

The columns are as follows:

- Common:

  The species common name (chr).

- Conc:

  The chemical concentration in micrograms per Litre (dbl).

- Domain:

  Tropical, temperate or other filter (chr).

- Life_stage:

  Life stage of the test organism (chr).

- Phylum:

  The Phylum name (chr).

- Source:

  The endpoint primary data source (chr).

- Species:

  The species names name (chr).

- Test_endpoint:

  Endpoint statistic, EC10, NEC etc (chr).

- Toxicity_measure:

  Type of toxicity measure used (chr).

## Examples

``` r

data(aims_aluminium_marine)
print(aims_aluminium_marine, n=Inf)
#> # A tibble: 20 × 9
#>    Common             Conc Domain Life_stage Phylum Source Species Test_endpoint
#>    <chr>             <dbl> <chr>  <chr>      <chr>  <chr>  <chr>   <chr>        
#>  1 Diatom              610 Tempe… NA         Bacil… (Gill… Minuto… EC10         
#>  2 Diatom               80 Tempe… NA         Bacil… (Gill… Cerato… EC10         
#>  3 Diatom               18 Tempe… NA         Bacil… (Gill… Cerato… EC10         
#>  4 Diatom               27 Mixed  NA         Bacil… (Gill… Cerato… EC10         
#>  5 Diatom             2100 Tempe… NA         Bacil… (Gill… Phaeod… EC10         
#>  6 Green microalga    1400 Tempe… NA         Chlor… (Gold… Dunali… EC10         
#>  7 Green microalga    3200 Tempe… NA         Chlor… (Gold… Tetras… EC10         
#>  8 Kelp               6800 Tempe… Zoospore   Ochro… (Gold… Ecklon… EC10         
#>  9 Sea grape          9800 Tempe… Zygote     Ochro… (Gold… Hormos… NOEC         
#> 10 Blue mussel         250 Tempe… Embryo     Mollu… (Gold… Mytilu… EC10         
#> 11 Sydney rock oyst…   100 Tempe… Embryo     Mollu… (Wils… Saccos… NOEC         
#> 12 Black sea urchin  28000 Tempe… Embryo     Echin… (Gold… Helioc… NOEC         
#> 13 Diatom               14 Tropi… NA         Bacil… (Harf… Cerato… EC10         
#> 14 Golden microalga    640 Tropi… NA         Hapto… (Tren… Tisoch… EC10         
#> 15 Blacklip oyster     410 Tropi… Embryo     Mollu… (Gold… Saccro… EC10         
#> 16 Dog whelk           115 Tropi… Larva      Mollu… (Tren… Nassar… EC10         
#> 17 Australian land …   312 Tropi… Zoea       Crust… (van … Coenob… EC10         
#> 18 Striped acorn ba…   416 Tropi… Nauplius   Crust… (van … Amphib… EC10         
#> 19 Branching coral    1300 Tropi… Larva      Cnida… (Negr… Acropo… EC10         
#> 20 Glass anemone       817 Tropi… Adult      Cnida… (Tren… Exaipt… EC10         
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
