# Species Sensitivity Data for iron_marine

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***iron*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 16
rows and 8 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2025). “Toxicant default guideline
values for aquatic ecosystem protection: Iron in marine water.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/iron-marine-dgvs-technical-brief.pdf>.

The columns are as follows:

- Conc:

  The chemical concentration in micrograms per Litre (dbl).

- Duration:

  The duration of the test in days (chr).

- Genus:

  The Genus name (chr).

- Group:

  The taxonomic group (chr).

- Life_stage:

  Life stage of the test organism (chr).

- Species:

  The species binomial name (chr).

- Test_endpoint:

  The test endpoint measure (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

## Examples

``` r

print(anzg_iron_marine, n=Inf)
#> # A tibble: 16 × 8
#>     Conc Duration Genus  Group Life_stage Species Test_endpoint Toxicity_measure
#>    <dbl> <chr>    <chr>  <chr> <chr>      <chr>   <chr>         <chr>           
#>  1 50000 4        Isoch… Micr… Not appli… galbana Growth rate … Chronic NOEC    
#>  2 18700 0.229    Acrop… Cnid… Gametes    spathu… Fertilisation Chronic EC10    
#>  3  2750 0.229    Platy… Cnid… Gametes    daedal… Fertilisation Chronic NOEC    
#>  4  2000 3        Helio… Echi… Embryo/la… tuberc… Larval devel… Chronic NOEC    
#>  5   935 2        Anada… Moll… Embryo     trapez… Abnormalities Chronic NEC     
#>  6   893 2        Barnea Moll… Embryo     austra… Abnormalities Chronic NEC     
#>  7   806 2        Fulvia Moll… Embryo     tenuic… Abnormalities Chronic NEC     
#>  8   810 2        Hiatu… Moll… Embryo     alba    Abnormalities Chronic NEC     
#>  9  1020 2        Irus   Moll… Embryo     crenat… Abnormalities Chronic NEC     
#> 10   724 2        Magal… Moll… Embryo     gigas   Abnormalities Chronic NEC     
#> 11   738 2        Sacco… Moll… Embryo     glomer… Abnormalities Chronic NEC     
#> 12  1270 2        Scaeo… Moll… Embryo     livida  Abnormalities Chronic NEC     
#> 13   948 2        Spisu… Moll… Embryo     trigon… Abnormalities Chronic NEC     
#> 14   896 2        Xenos… Moll… Embryo     securis Abnormalities Chronic NEC     
#> 15  4360 2        Halio… Moll… Embryoâ€“… rubra   Normal devel… Chronic EC10    
#> 16  1000 7        Cancer Crus… Embryo     anthon… Hatching      Chronic NOEC    
```
