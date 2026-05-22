# CCME Species Sensitivity Data for ccme_silver

Species Sensitivity Data from the Canadian Council of Ministers of the
Environment for ***silver***.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 9
rows and 5 columns.

## Details

Additional information is available from CCME (2021). “Silver: Water
Quality Guidelines for the Protection of Aquatic Life.” May 06,
<https://ccme.ca/en/chemical/198>.

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

print(ccme_silver, n=Inf)
#> # A tibble: 9 × 5
#>   Chemical Species                Conc Group        Units
#>   <chr>    <chr>                 <dbl> <fct>        <chr>
#> 1 Silver   Oncorhynchus mykiss    0.24 Fish         ug/L 
#> 2 Silver   Lemna gibba            0.63 Plant        ug/L 
#> 3 Silver   Ceriodaphnia dubia     0.78 Invertebrate ug/L 
#> 4 Silver   Pimephales promelas    0.83 Fish         ug/L 
#> 5 Silver   Ictalurus punctatus    1.9  Fish         ug/L 
#> 6 Silver   Daphnia magna          2.12 Invertebrate ug/L 
#> 7 Silver   Hyalella azteca        4    Invertebrate ug/L 
#> 8 Silver   Chironomus tentans    13    Invertebrate ug/L 
#> 9 Silver   Micropterus salmoides 23    Fish         ug/L 
```
