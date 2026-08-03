# Species Sensitivity Data provided by CSIRO

Species Sensitivity Data provided by the Commonwealth Scientific and
Industrial Research Organisation of Australia.

## Usage

``` r
csiro_data
```

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 91
rows and 12 columns.

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

  The chemical concentration in micrograms per Litre (dbl).

- Domain:

  Tropical, temperate or other filter (chr).

- Duration:

  Test duration (chr).

- Group:

  Taxonomic grouping information (chr).

- Life_stage:

  Life stage of the test organism (chr).

- Medium:

  The test medium: "Freshwater" or "Marine" (chr).

- Notes:

  Other notes (chr).

- Species:

  The species names name (chr).

- Test_endpoint:

  Endpoint statistic, EC10, NEC etc (chr).

- Toxicity_measure:

  Type of toxicity measure used (chr).

- Units:

  The concentration units of Conc (micrograms per Litre, ug/L) (chr).

## Examples

``` r

head(csiro_data)
#> # A tibble: 6 × 12
#>   Chemical  Conc Domain Duration Group    Life_stage        Medium Notes Species
#>   <chr>    <dbl> <chr>  <chr>    <chr>    <chr>             <chr>  <chr> <chr>  
#> 1 chlorine    90 NA     0.5      Rotifer  NA                Marine NA    Brachi…
#> 2 chlorine   687 NA     96       Amphipod Adult             Marine NA    Pontog…
#> 3 chlorine   145 NA     96       Amphipod Adult             Marine NA    Anonyx…
#> 4 chlorine   178 NA     96       Shrimp   Juvenile and adu… Marine NA    Pandal…
#> 5 chlorine  2890 NA     1        Lobster  Larvae            Marine NA    Homaru…
#> 6 chlorine   162 NA     96       Mysid    Adult             Marine NA    Neomys…
#> # ℹ 3 more variables: Test_endpoint <chr>, Toxicity_measure <chr>, Units <chr>
```
