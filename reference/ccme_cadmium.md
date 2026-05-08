# CCME Species Sensitivity Data for ccme_cadmium

Species Sensitivity Data from the Canadian Council of Ministers of the
Environment for ***cadmium***.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 36
rows and 5 columns.

## Details

Additional information is available from CCME (2021). “Cadmium: Water
Quality Guidelines for the Protection of Aquatic Life.” May 06,
<https://ccme.ca/en/chemical/20>.

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

print(ccme_cadmium, n=Inf)
#> # A tibble: 36 × 5
#>    Chemical Species                             Conc Group        Units
#>    <chr>    <chr>                              <dbl> <fct>        <chr>
#>  1 Cadmium  Oncorhynchus mykiss                 0.23 Fish         ug/L 
#>  2 Cadmium  Salvelinus confluentus              0.83 Fish         ug/L 
#>  3 Cadmium  Cottus bairdi                       0.96 Fish         ug/L 
#>  4 Cadmium  Salmo salar                         0.99 Fish         ug/L 
#>  5 Cadmium  Acipenser transmontanus             1.14 Fish         ug/L 
#>  6 Cadmium  Prosopium williamsoni               1.25 Fish         ug/L 
#>  7 Cadmium  Salmo trutta                        1.36 Fish         ug/L 
#>  8 Cadmium  Salvelinus fontinalis               2.23 Fish         ug/L 
#>  9 Cadmium  Oncorhynchus tshawytscha            2.29 Fish         ug/L 
#> 10 Cadmium  Pimephales promelas                 2.36 Fish         ug/L 
#> 11 Cadmium  Catostomus commersoni               7.75 Fish         ug/L 
#> 12 Cadmium  Oncorhynchus kisutch                7.81 Fish         ug/L 
#> 13 Cadmium  Salvelinus namaycush                8.03 Fish         ug/L 
#> 14 Cadmium  Esox lucius                         8.03 Fish         ug/L 
#> 15 Cadmium  Daphnia magna                       0.05 Invertebrate ug/L 
#> 16 Cadmium  Ceriodaphnia reticulata             0.12 Invertebrate ug/L 
#> 17 Cadmium  Hyalella azteca                     0.12 Invertebrate ug/L 
#> 18 Cadmium  Hydra viridissima                   0.87 Invertebrate ug/L 
#> 19 Cadmium  Chironomus tentans                  0.96 Invertebrate ug/L 
#> 20 Cadmium  Echinogammarus meridionalis         1.3  Invertebrate ug/L 
#> 21 Cadmium  Atyaephyra desmarestii              1.32 Invertebrate ug/L 
#> 22 Cadmium  Gammarus pulex                      1.86 Invertebrate ug/L 
#> 23 Cadmium  Daphnia pulex                       2.07 Invertebrate ug/L 
#> 24 Cadmium  Ceriodaphnia dubia                  4.9  Invertebrate ug/L 
#> 25 Cadmium  Lampsilis siliquoidea               5.12 Invertebrate ug/L 
#> 26 Cadmium  Aeolosoma headleyi                 14.7  Invertebrate ug/L 
#> 27 Cadmium  Lymnaea stagnalis                  18.9  Invertebrate ug/L 
#> 28 Cadmium  Chironomus riparius                27.1  Invertebrate ug/L 
#> 29 Cadmium  Lymnaea palustris                  58.2  Invertebrate ug/L 
#> 30 Cadmium  Rhithrogena hageni               2659    Invertebrate ug/L 
#> 31 Cadmium  Erythemis simplicicollis        48400    Invertebrate ug/L 
#> 32 Cadmium  Pachydiplax longipennis         76500    Invertebrate ug/L 
#> 33 Cadmium  Ambystoma gracile                 106    Amphibian    ug/L 
#> 34 Cadmium  Ankistrodesmus falcatus             4.9  Plant        ug/L 
#> 35 Cadmium  Pseudokirchneriella subcapitata    19.8  Plant        ug/L 
#> 36 Cadmium  Lemna minor                        79    Plant        ug/L 
```
