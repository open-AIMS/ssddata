# CCME Species Sensitivity Data for ccme_boron

Species Sensitivity Data from the Canadian Council of Ministers of the
Environment for ***boron***.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 28
rows and 5 columns.

## Details

Additional information is available from CCME (2021). “Boron: Water
Quality Guidelines for the Protection of Aquatic Life.” May 06,
<https://ccme.ca/en/chemical/16>.

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

print(ccme_boron, n=Inf)
#> # A tibble: 28 × 5
#>    Chemical Species                    Conc Group        Units
#>    <chr>    <chr>                     <dbl> <fct>        <chr>
#>  1 Boron    Oncorhynchus mykiss         2.1 Fish         mg/L 
#>  2 Boron    Ictalurus punctatus         2.4 Fish         mg/L 
#>  3 Boron    Micropterus salmoides       4.1 Fish         mg/L 
#>  4 Boron    Brachydanio rerio          10   Fish         mg/L 
#>  5 Boron    Carassius auratus          15.6 Fish         mg/L 
#>  6 Boron    Pimephales promelas        18.3 Fish         mg/L 
#>  7 Boron    Daphnia magna               6   Invertebrate mg/L 
#>  8 Boron    Opercularia bimarginata    10   Invertebrate mg/L 
#>  9 Boron    Ceriodaphnia dubia         13.4 Invertebrate mg/L 
#> 10 Boron    Entosiphon sulcatum        15   Invertebrate mg/L 
#> 11 Boron    Chironomus decorus         20   Invertebrate mg/L 
#> 12 Boron    Paramecium caudatum        20   Invertebrate mg/L 
#> 13 Boron    Rana pipiens               20.4 Amphibian    mg/L 
#> 14 Boron    Bufo fowleri               48.6 Amphibian    mg/L 
#> 15 Boron    Bufo americanus            50   Amphibian    mg/L 
#> 16 Boron    Ambystoma jeffersonianum   70.7 Amphibian    mg/L 
#> 17 Boron    Ambystoma maculatum        70.7 Amphibian    mg/L 
#> 18 Boron    Rana sylvatica             70.7 Amphibian    mg/L 
#> 19 Boron    Elodea canadensis           1   Plant        mg/L 
#> 20 Boron    Spirodella polyrrhiza       1.8 Plant        mg/L 
#> 21 Boron    Chlorella pyrenoidosa       2   Plant        mg/L 
#> 22 Boron    Phragmites australis        4   Plant        mg/L 
#> 23 Boron    Chlorella vulgaris          5.2 Plant        mg/L 
#> 24 Boron    Selenastrum capricornutum  12.3 Plant        mg/L 
#> 25 Boron    Scenedesmus subspicatus    30   Plant        mg/L 
#> 26 Boron    Myriophyllum spicatum      34.2 Plant        mg/L 
#> 27 Boron    Anacystis nidulans         50   Plant        mg/L 
#> 28 Boron    Lemna minor                60   Plant        mg/L 
```
