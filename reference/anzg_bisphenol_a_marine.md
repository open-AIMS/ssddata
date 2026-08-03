# Species Sensitivity Data for bisphenol_a_marine

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***bisphenol_a*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 8
rows and 7 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2023). “Toxicant default guideline
values for aquatic ecosystem protection: Bisphenol A in marine water.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/bisphenol-a-marine-dgvs-technical-brief.pdf>.

The columns are as follows:

- Conc:

  The chemical concentration in micrograms per Litre (dbl).

- Duration:

  The duration of the test in days (chr).

- Genus:

  The Genus name (chr).

- Group:

  The taxonomic group (chr).

- Species:

  The species binomial name (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

- Units:

  The concentration units of Conc (micrograms per Litre, ug/L) (chr).

## Examples

``` r

print(anzg_bisphenol_a_marine, n=Inf)
#> # A tibble: 8 × 7
#>      Conc Duration Genus              Group       Species Toxicity_measure Units
#>     <dbl> <chr>    <chr>              <chr>       <chr>   <chr>            <chr>
#> 1  302    72       Prorocentrum       Dinoflagel… cordat… Chronic EC50     ug/L 
#> 2 3470    72       Margalefidinium    Dinoflagel… polykr… Chronic EC50     ug/L 
#> 3   45.6  920      Hemicentrotus      Echinoderm  pulche… Chronic LOEC     ug/L 
#> 4   38.8  0.5      Paracentrotus      Echinoderm  lividus Acute EC50       ug/L 
#> 5   45.3  96       Strongylocentrotus Echinoderm  purpur… Chronic EC50     ug/L 
#> 6    0.19 96       Haliotis           Mollusc     divers… Chronic EC5      ug/L 
#> 7   20    96       Tigriopus          Crustacean  japoni… Acute LC50       ug/L 
#> 8  103    96       Americamysis       Crustacean  bahia   Acute LC50       ug/L 
```
