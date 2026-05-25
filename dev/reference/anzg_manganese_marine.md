# Species Sensitivity Data for manganese_marine

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***manganese*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 18
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2026). “Toxicant default guideline
values for aquatic ecosystem protection: Manganese in marine water.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/manganese-marine-dgvs-technical-brief.pdf>.

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

- Phylum:

  The Phylum name (chr).

- Species:

  The species binomial name (chr).

- Test_endpoint:

  The test endpoint measure (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

## Examples

``` r

print(anzg_manganese_marine, n=Inf)
#> # A tibble: 18 × 9
#>      Conc Duration Genus        Group    Life_stage Phylum Species Test_endpoint
#>     <dbl> <chr>    <chr>        <chr>    <chr>      <chr>  <chr>   <chr>        
#>  1  18000 3        Ceratoneis   Diatom   N.A.       Bacil… closte… Growth rate  
#>  2 125000 3        Isochrysis   Golden … Log phase  Hapto… lutea   Growth rate  
#>  3   1090 14       Acropora     Cnidari… Adult      Cnida… millep… Tissue sloug…
#>  4    358 2        Acropora     Cnidari… Adult      Cnida… murica… Tissue sloug…
#>  5    304 2        Acropora     Cnidari… Adult      Cnida… spathu… Tissue sloug…
#>  6  54000 0.229    Platygyra    Cnidari… Gametes    Cnida… daedal… Fertilisation
#>  7    374 2        Stylophora   Cnidari… Adult      Cnida… pistil… Tissue sloug…
#>  8   1580 3        Heliocidaris Echinod… Embryo     Echin… tuberc… Embryo devel…
#>  9   1040 2        Anadara      Mollusc… Embryo     Mollu… trapez… Embryo devel…
#> 10   1780 2        Barnea       Mollusc… Embryo     Mollu… austra… Embryo devel…
#> 11   1460 2        Fulvia       Mollusc… Embryo     Mollu… tenuic… Embryo devel…
#> 12   1520 2        Hiatula      Mollusc… Embryo     Mollu… alba    Embryo devel…
#> 13   2410 2        Irus         Mollusc… Embryo     Mollu… crenat… Embryo devel…
#> 14    650 2        Magallana    Mollusc… Embryo     Mollu… gigas   Embryo devel…
#> 15    654 2        Saccostrea   Mollusc… Embryo     Mollu… glomer… Embryo devel…
#> 16    959 2        Scaeochlamys Mollusc… Embryo     Mollu… livida  Embryo devel…
#> 17   2090 2        Spisula      Mollusc… Embryo     Mollu… trigon… Embryo devel…
#> 18    755 2        Xenostrobus  Mollusc… Embryo     Mollu… securis Embryo devel…
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
