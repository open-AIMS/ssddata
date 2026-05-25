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

## Examples

``` r

print(anzg_bisphenol_a_marine, n=Inf)
#> # A tibble: 8 × 6
#>      Conc Duration Genus              Group          Species    Toxicity_measure
#>     <dbl> <chr>    <chr>              <chr>          <chr>      <chr>           
#> 1  302    72       Prorocentrum       Dinoflagellate cordatum   Chronic EC50    
#> 2 3470    72       Margalefidinium    Dinoflagellate polykriko… Chronic EC50    
#> 3   45.6  920      Hemicentrotus      Echinoderm     pulcherri… Chronic LOEC    
#> 4   38.8  0.5      Paracentrotus      Echinoderm     lividus    Acute EC50      
#> 5   45.3  96       Strongylocentrotus Echinoderm     purpuratus Chronic EC50    
#> 6    0.19 96       Haliotis           Mollusc        diversico… Chronic EC5     
#> 7   20    96       Tigriopus          Crustacean     japonicus  Acute LC50      
#> 8  103    96       Americamysis       Crustacean     bahia      Acute LC50      
```
