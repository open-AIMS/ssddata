# Species Sensitivity Data for molybdenum_marine

Species Sensitivity Data provided by the Australian Institute of Marine
Science for ***molybdenum*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 14
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

data(aims_molybdenum_marine)
print(aims_molybdenum_marine, n=Inf)
#> # A tibble: 14 × 9
#>    Common             Conc Domain Life_stage Phylum Source Species Test_endpoint
#>    <chr>             <dbl> <chr>  <chr>      <chr>  <chr>  <chr>   <chr>        
#>  1 Green microalga  8.81e5 Tempe… NA         Chlor… (Heij… Dunali… EC10         
#>  2 Diatom           1.7 e5 Tempe… NA         Bacil… (Heij… Phaeod… EC10         
#>  3 Red alga         2.74e5 Tempe… Adult      Rhodo… (Heij… Cerami… EC10         
#>  4 Pacific oyster   1.17e6 Tempe… Embryo     Mollu… (Heij… Crasso… EC10         
#>  5 Blue mussel      4.4 e3 Tempe… Embryo     Mollu… (Morg… Mytilu… EC10         
#>  6 Copepod          7.96e3 Tempe… Embryo     Crust… (Heij… Acarti… EC10         
#>  7 Purple sea urch… 3.26e5 Tempe… Embryo     Echin… (Heij… Strong… EC10         
#>  8 Pacific sand do… 2.34e5 Tempe… Embryo     Echin… (Heij… Dendra… EC10         
#>  9 Golden microalga 9.5 e3 Tropi… NA         Hapto… (Tren… Tisoch… NOEC         
#> 10 Dog whelk        7   e3 Tropi… Larva      Mollu… (Tren… Nassar… NOEC         
#> 11 Australian land… 1   e4 Tropi… Zoea       Crust… (van … Coenob… NOEC         
#> 12 Striped acorn b… 9   e3 Tropi… Nauplius   Crust… (van … Amphib… NOEC         
#> 13 Mysid shrimp     1.16e5 Tropi… Larva      Crust… (Heij… Americ… NOEC         
#> 14 Sheepshead minn… 8.41e4 Tropi… Embryo     Chord… (Heij… Cyprin… EC10         
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
