# Species Sensitivity Data for bisphenol_a_marine

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***bisphenol a*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 8
rows and 6 columns.

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

- Genus:

  The Genus name (chr).

- Group:

  The taxonomic group (chr).

- Species:

  The species binomial name (chr).

- Test_endpoint:

  The test endpoint measure (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

## Examples

``` r

print(anzg_bisphenol_a_marine, n=Inf)
#> # A tibble: 8 × 6
#>      Conc Genus              Group        Species Test_endpoint Toxicity_measure
#>     <dbl> <chr>              <chr>        <chr>   <chr>         <chr>           
#> 1  302    Prorocentrum       Dinoflagell… cordat… Chronic EC50  72              
#> 2 3470    Margalefidinium    Dinoflagell… polykr… Chronic EC50  72              
#> 3   45.6  Hemicentrotus      Echinoderm   pulche… Chronic LOEC  920             
#> 4   38.8  Paracentrotus      Echinoderm   lividus Acute EC50    0.5             
#> 5   45.3  Strongylocentrotus Echinoderm   purpur… Chronic EC50  96              
#> 6    0.19 Haliotis           Mollusc      divers… Chronic EC5   96              
#> 7   20    Tigriopus          Crustacean   japoni… Acute LC50    96              
#> 8  103    Americamysis       Crustacean   bahia   Acute LC50    96              
```
