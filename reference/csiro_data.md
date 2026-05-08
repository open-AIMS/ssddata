# Species Sensitivity Data provided by CSIRO

Species Sensitivity Data provided by the Commonwealth Scientific and
Industrial Research Organisation of Australia.

## Usage

``` r
csiro_data
```

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 91
rows and 11 columns.

## Details

Additional information may be available from the primary source for each
chemical:

- chlorine_marine:

  Batley GE, Simpson SL (2020). “Short-Term Guideline Values for
  Chlorine in Marine Waters.” *Environmental Toxicology and Chemistry*.
  ISSN 15528618.
  <https://setac.onlinelibrary.wiley.com/doi/full/10.1002/etc.4661>.

- nickel_fresh:

  Stauber J, Golding L, Peters A, Merrington G, Adams M, Binet M, Batley
  G, Gissi F, Mcknight K, Garman E, Middleton E, Gadd J, Schlekat C
  (2021). “Environmental Toxicology Application of Bioavailability
  Models to Derive Chronic Guideline Values for Nickel in Freshwaters of
  Australia and New Zealand.” *Environmental Toxicology and Chemistry*,
  **40**(1), 100–112.
  [doi:10.1002/etc.4885](https://doi.org/10.1002/etc.4885) .
  <https://setac.onlinelibrary.wiley.com/doi/abs/10.1002/etc.4885>.

- cobalt_marine:

  Batley G (2021). “Unpublished data, anonymous information.” March 23.

- lead_marine:

  Batley G (2021). “Unpublished data, anonymous information.” March 23.

The columns are as follows, noting that not all information are
available for all chemicals:

- Chemical:

  The chemical name (chr).

- Conc:

  The chemical concentration (dbl).

- Domain:

  Tropical, temperate or other filter (chr).

- Duration:

  Test duration (chr).

- Group:

  Taxonomic grouping information (chr).

- Life_stage:

  Life stage of the test organism (chr).

- Medium:

  The medium - fresh or marine water (chr).

- Notes:

  Other notes (chr).

- Species:

  The species names name (chr).

- Test_endpoint:

  Endpoint statistic, EC10, NEC etc (chr).

- Toxicity_measure:

  Type of toxicity measure used (chr).

## Examples

``` r

head(csiro_data)
#> # A tibble: 6 × 11
#>   Chemical  Conc Domain Duration Group    Life_stage Medium Notes Species
#>   <chr>    <dbl> <chr>  <chr>    <chr>    <chr>      <chr>  <chr> <chr>  
#> 1 chlorine    90 NA     NA       Rotifer  NA         marine NA    NA     
#> 2 chlorine   687 NA     NA       Amphipod NA         marine NA    NA     
#> 3 chlorine   145 NA     NA       Amphipod NA         marine NA    NA     
#> 4 chlorine   178 NA     NA       Shrimp   NA         marine NA    NA     
#> 5 chlorine  2890 NA     NA       Lobster  NA         marine NA    NA     
#> 6 chlorine   162 NA     NA       Mysid    NA         marine NA    NA     
#> # ℹ 2 more variables: Test_endpoint <chr>, Toxicity_measure <chr>
```
