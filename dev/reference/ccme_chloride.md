# CCME Species Sensitivity Data for ccme_chloride

Species Sensitivity Data from the Canadian Council of Ministers of the
Environment for ***chloride***.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 28
rows and 5 columns.

## Details

Additional information is available from CCME (2021). “Chloride: Water
Quality Guidelines for the Protection of Aquatic Life.” May 06,
<https://ccme.ca/en/chemical/28>.

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

print(ccme_chloride, n=Inf)
#> # A tibble: 28 × 5
#>    Chemical Species                       Conc Group        Units
#>    <chr>    <chr>                        <dbl> <fct>        <chr>
#>  1 Chloride Pimephales promelas            598 Fish         mg/L 
#>  2 Chloride Salmo trutta fario             607 Fish         mg/L 
#>  3 Chloride Oncorhynchus mykiss            989 Fish         mg/L 
#>  4 Chloride Xenopus laevis                1307 Amphibian    mg/L 
#>  5 Chloride Rana pipiens                  3431 Amphibian    mg/L 
#>  6 Chloride Lampsilis fasciola              24 Invertebrate mg/L 
#>  7 Chloride Epioblasma torulosa rangiana    42 Invertebrate mg/L 
#>  8 Chloride Musculium securis              121 Invertebrate mg/L 
#>  9 Chloride Daphnia ambigua                259 Invertebrate mg/L 
#> 10 Chloride Daphnia pulex                  368 Invertebrate mg/L 
#> 11 Chloride Elliptio complanata            406 Invertebrate mg/L 
#> 12 Chloride Daphnia magna                  421 Invertebrate mg/L 
#> 13 Chloride Hyalella azteca                421 Invertebrate mg/L 
#> 14 Chloride Ceriodaphnia dubia             454 Invertebrate mg/L 
#> 15 Chloride Tubifex tubifex                519 Invertebrate mg/L 
#> 16 Chloride Villosa delumbis               716 Invertebrate mg/L 
#> 17 Chloride Villosa constricta             789 Invertebrate mg/L 
#> 18 Chloride Lumbriculus variegates         825 Invertebrate mg/L 
#> 19 Chloride Brachionus calyciflorus       1241 Invertebrate mg/L 
#> 20 Chloride Lampsilis siliquoidea         1474 Invertebrate mg/L 
#> 21 Chloride Gammarus pseudopinmaeus       2000 Invertebrate mg/L 
#> 22 Chloride Physa sp                      2000 Invertebrate mg/L 
#> 23 Chloride Stenonema modestum            2047 Invertebrate mg/L 
#> 24 Chloride Chironomus tentans            2316 Invertebrate mg/L 
#> 25 Chloride Lemna minor                   1171 Plant        mg/L 
#> 26 Chloride Chlorella minutissimo         6066 Plant        mg/L 
#> 27 Chloride Chlorella zofingiensis        6066 Plant        mg/L 
#> 28 Chloride Chlorella emersonii           6824 Plant        mg/L 
```
