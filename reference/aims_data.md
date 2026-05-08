# Species Sensitivity Data provided by AIMS

Species Sensitivity Data provided by the Australian Institute of Marine
Science.

## Usage

``` r
aims_data
```

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 40
rows and 11 columns.

## Details

Additional information may be available from the primary source for each
chemical:

- aluminium_marine:

  van Dam JW, Trenfield MA, Streten C, Harford AJ, Parry D, van Dam RA
  (2018). “Water quality guideline values for aluminium, gallium and
  molybdenum in marine environments.” *Environmental Science and
  Pollution Research*, **25**(26), 26592–26602. ISSN 16147499.
  <https://link.springer.com/article/10.1007/s11356-018-2702-y>.

- gallium_marine:

  van Dam JW, Trenfield MA, Streten C, Harford AJ, Parry D, van Dam RA
  (2018). “Water quality guideline values for aluminium, gallium and
  molybdenum in marine environments.” *Environmental Science and
  Pollution Research*, **25**(26), 26592–26602. ISSN 16147499.
  <https://link.springer.com/article/10.1007/s11356-018-2702-y>.

- molybdenum_marine:

  van Dam JW, Trenfield MA, Streten C, Harford AJ, Parry D, van Dam RA
  (2018). “Water quality guideline values for aluminium, gallium and
  molybdenum in marine environments.” *Environmental Science and
  Pollution Research*, **25**(26), 26592–26602. ISSN 16147499.
  <https://link.springer.com/article/10.1007/s11356-018-2702-y>.

The columns are as follows, noting that all information may not be
available for all chemicals:

- Chemical:

  The chemical name (chr).

- Common:

  The species common name (chr).

- Conc:

  The chemical concentration in micrograms per Litre (dbl).

- Domain:

  Tropical, temperate or other filter (chr).

- Life_stage:

  Life stage of the test organism (chr).

- Medium:

  The medium - fresh or marine water (chr).

- Phylum:

  The Phylum name (chr).

- Source:

  The endpoint primary data source (chr).

- Species:

  The species names name (chr).

- Test_endpoint:

  Endpoint statistic, EC10, NEC etc (chr).

- Toxicity_measure:

  Type of toxicity measure used (chr).

## Examples

``` r

head(aims_data)
#> # A tibble: 6 × 11
#>   Chemical  Common           Conc Domain Life_stage Medium Phylum Source Species
#>   <chr>     <chr>           <dbl> <chr>  <chr>      <chr>  <chr>  <chr>  <chr>  
#> 1 aluminium Diatom            610 Tempe… NA         marine Bacil… (Gill… Minuto…
#> 2 aluminium Diatom             80 Tempe… NA         marine Bacil… (Gill… Cerato…
#> 3 aluminium Diatom             18 Tempe… NA         marine Bacil… (Gill… Cerato…
#> 4 aluminium Diatom             27 Mixed  NA         marine Bacil… (Gill… Cerato…
#> 5 aluminium Diatom           2100 Tempe… NA         marine Bacil… (Gill… Phaeod…
#> 6 aluminium Green microalga  1400 Tempe… NA         marine Chlor… (Gold… Dunali…
#> # ℹ 2 more variables: Test_endpoint <chr>, Toxicity_measure <chr>
```
