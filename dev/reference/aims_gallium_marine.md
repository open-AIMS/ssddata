# Species Sensitivity Data for gallium_marine

Species Sensitivity Data provided by the Australian Institute of Marine
Science for ***gallium*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 6
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

data(aims_gallium_marine)
print(aims_gallium_marine, n=Inf)
#> # A tibble: 6 × 9
#>   Common              Conc Domain Life_stage Phylum Source Species Test_endpoint
#>   <chr>              <dbl> <chr>  <chr>      <chr>  <chr>  <chr>   <chr>        
#> 1 Diatom               860 Tropi… NA         Bacil… (Harf… Cerato… EC10         
#> 2 Golden microalga    6000 Tropi… NA         Hapto… (Tren… Tisoch… NOEC         
#> 3 Dog whelk           3800 Tropi… Larva      Mollu… (Tren… Nassar… EC10         
#> 4 Australian land h…  6010 Tropi… Zoea       Crust… (van … Coenob… EC10         
#> 5 Striped acorn bar…  5070 Tropi… Nauplius   Crust… (van … Amphib… EC10         
#> 6 Branching coral     1160 Tropi… Larva      Cnida… (Negr… Acropo… EC10         
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
