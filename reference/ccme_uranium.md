# CCME Species Sensitivity Data for ccme_uranium

Species Sensitivity Data from the Canadian Council of Ministers of the
Environment for ***uranium***.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 13
rows and 5 columns.

## Details

Additional information is available from CCME (2021). “Uranium: Water
Quality Guidelines for the Protection of Aquatic Life.” May 06,
<https://ccme.ca/en/chemical/225>.

The columns are as follows:

- Chemical:

  The chemical (chr).

- Species:

  The species binomial name (chr).

- Conc:

  The chemical concentration (dbl).

- Group:

  The taxonomic group (fct).

- Units:

  The units of Conc (chr).

## Examples

``` r

print(ccme_uranium, n=Inf)
#> # A tibble: 13 × 5
#>    Chemical Species                          Conc Group        Units
#>    <chr>    <chr>                           <dbl> <fct>        <chr>
#>  1 Uranium  Oncorhynchus mykiss               350 Fish         ug/L 
#>  2 Uranium  Pimephales promelas              1040 Fish         ug/L 
#>  3 Uranium  Esox lucius                      2550 Fish         ug/L 
#>  4 Uranium  Salvelinus namaycush            13400 Fish         ug/L 
#>  5 Uranium  Catostomus commersoni           14300 Fish         ug/L 
#>  6 Uranium  Hyalella azteca                    12 Invertebrate ug/L 
#>  7 Uranium  Ceriodaphnia dubia                 73 Invertebrate ug/L 
#>  8 Uranium  Simocephalus serrulatus           480 Invertebrate ug/L 
#>  9 Uranium  Daphnia magna                     530 Invertebrate ug/L 
#> 10 Uranium  Chironomus tentans                930 Invertebrate ug/L 
#> 11 Uranium  Pseudokirchneriella subcapitata    40 Plant        ug/L 
#> 12 Uranium  Lemna minor                      3100 Plant        ug/L 
#> 13 Uranium  Cryptomonas erosa                 172 Plant        ug/L 
```
