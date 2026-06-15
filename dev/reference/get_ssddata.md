# Get SSD dataset

Retrieves a specific SSD dataset, filtering and groups by species and
applies a geometric mean in the case of duplicate records.

## Usage

``` r
get_ssddata(
  dataset_name,
  filter_val = NULL,
  use_gmmean = TRUE,
  spp_vec = c("Species", "Genus"),
  conc = "Conc"
)
```

## Arguments

- dataset_name:

  The name (chr) of the desired dataset in ssddata.

- filter_val:

  A character string, indicating the filter to be applied (value)
  (colname) and which column it applies to, separated by "\_". Must be
  in the form colname_value.

- use_gmmean:

  Logical indicating if a geometric mean should be applied.

- spp_vec:

  The group_by columns to use for grouping data and applying a geometric
  mean.

- conc:

  The name of the concentration (x data) column.

## Value

The data.frame for dataset_name with any applied groupings and summary.

## Examples

``` r
get_ssddata("ccme_boron")
#> No grouping has been applied, returning raw ccme_boron dataset.
#> # A tibble: 28 × 6
#>    Chemical Species                  Conc Group        Units Medium    
#>    <chr>    <chr>                   <dbl> <fct>        <chr> <chr>     
#>  1 Boron    Oncorhynchus mykiss       2.1 Fish         mg/L  Freshwater
#>  2 Boron    Ictalurus punctatus       2.4 Fish         mg/L  Freshwater
#>  3 Boron    Micropterus salmoides     4.1 Fish         mg/L  Freshwater
#>  4 Boron    Brachydanio rerio        10   Fish         mg/L  Freshwater
#>  5 Boron    Carassius auratus        15.6 Fish         mg/L  Freshwater
#>  6 Boron    Pimephales promelas      18.3 Fish         mg/L  Freshwater
#>  7 Boron    Daphnia magna             6   Invertebrate mg/L  Freshwater
#>  8 Boron    Opercularia bimarginata  10   Invertebrate mg/L  Freshwater
#>  9 Boron    Ceriodaphnia dubia       13.4 Invertebrate mg/L  Freshwater
#> 10 Boron    Entosiphon sulcatum      15   Invertebrate mg/L  Freshwater
#> # ℹ 18 more rows
```
