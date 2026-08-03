# CCME Species Sensitivity Data

Species Sensitivity Data from the Canadian Council of Ministers of the
Environment. The taxonomic groups are Amphibian, Fish, Invertebrate and
Plant. Plants includes freshwater algae.

## Usage

``` r
ccme_data
```

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 144
rows and 6 columns.

## Details

Additional information on each of the chemicals is available from the
CCME website.

- boron:

  CCME (2021). “Boron: Water Quality Guidelines for the Protection of
  Aquatic Life.” May 06, <https://ccme.ca/en/chemical/16>.

- cadmium:

  CCME (2021). “Cadmium: Water Quality Guidelines for the Protection of
  Aquatic Life.” May 06, <https://ccme.ca/en/chemical/20>.

- chloride:

  CCME (2021). “Chloride: Water Quality Guidelines for the Protection of
  Aquatic Life.” May 06, <https://ccme.ca/en/chemical/28>.

- endosulfan:

  CCME (2021). “Endosulfan: Water Quality Guidelines for the Protection
  of Aquatic Life.” May 06, <https://ccme.ca/en/chemical/93>.

- glyphosate:

  CCME (2021). “Glyphosate: Water Quality Guidelines for the Protection
  of Aquatic Life.” May 06, <https://ccme.ca/en/chemical/102>.

- uranium:

  CCME (2021). “Uranium: Water Quality Guidelines for the Protection of
  Aquatic Life.” May 06, <https://ccme.ca/en/chemical/225>.

- silver:

  CCME (2021). “Silver: Water Quality Guidelines for the Protection of
  Aquatic Life.” May 06, <https://ccme.ca/en/chemical/198>.

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

head(ccme_data)
#> # A tibble: 6 × 6
#>   Chemical Species                Conc Group Units Medium    
#>   <chr>    <chr>                 <dbl> <fct> <chr> <chr>     
#> 1 Boron    Oncorhynchus mykiss     2.1 Fish  mg/L  Freshwater
#> 2 Boron    Ictalurus punctatus     2.4 Fish  mg/L  Freshwater
#> 3 Boron    Micropterus salmoides   4.1 Fish  mg/L  Freshwater
#> 4 Boron    Brachydanio rerio      10   Fish  mg/L  Freshwater
#> 5 Boron    Carassius auratus      15.6 Fish  mg/L  Freshwater
#> 6 Boron    Pimephales promelas    18.3 Fish  mg/L  Freshwater
```
