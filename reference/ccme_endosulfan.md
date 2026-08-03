# CCME Species Sensitivity Data for ccme_endosulfan

Species Sensitivity Data from the Canadian Council of Ministers of the
Environment for ***endosulfan***.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 12
rows and 6 columns.

## Details

Additional information is available from CCME (2021). “Endosulfan: Water
Quality Guidelines for the Protection of Aquatic Life.” May 06,
<https://ccme.ca/en/chemical/93>.

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

- Medium:

  The medium (freshwater, marine, etc.) (chr).

## Examples

``` r

print(ccme_endosulfan, n=Inf)
#> # A tibble: 12 × 6
#>    Chemical   Species                            Conc Group        Units Medium 
#>    <chr>      <chr>                             <dbl> <fct>        <chr> <chr>  
#>  1 Endosulfan Oncorhynchus mykiss                0.05 Fish         ng/L  Freshw…
#>  2 Endosulfan Channa punctata                    0.24 Fish         ng/L  Freshw…
#>  3 Endosulfan Pimephales promelas                0.28 Fish         ng/L  Freshw…
#>  4 Endosulfan Hydra vulgaris                     0.06 Invertebrate ng/L  Freshw…
#>  5 Endosulfan Hydra viridissima                  0.07 Invertebrate ng/L  Freshw…
#>  6 Endosulfan Daphnia magna                     14.1  Invertebrate ng/L  Freshw…
#>  7 Endosulfan Ceriodaphnia dubia                14.1  Invertebrate ng/L  Freshw…
#>  8 Endosulfan Moinodaphnia macleayi             28.3  Invertebrate ng/L  Freshw…
#>  9 Endosulfan Daphnia cephalata                113.   Invertebrate ng/L  Freshw…
#> 10 Endosulfan Brachionus calyciflorus         1000    Invertebrate ng/L  Freshw…
#> 11 Endosulfan Pseudokirchneriella subcapitata  428.   Plant        ng/L  Freshw…
#> 12 Endosulfan Scenedesmus subspicatus          560    Plant        ng/L  Freshw…
```
