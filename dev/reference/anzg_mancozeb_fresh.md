# Species Sensitivity Data for mancozeb_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***mancozeb*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 8
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2023). “Toxicant default guideline
values for aquatic ecosystem protection: Mancozeb in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/mancozeb-fresh-dgvs-technical-brief.pdf>.

The columns are as follows:

- Conc:

  The chemical concentration in micrograms per Litre (dbl).

- Duration:

  The duration of the test in days (chr).

- Genus:

  The Genus name (chr).

- Group:

  The taxonomic group (chr).

- Life_stage:

  Life stage of the test organism (chr).

- Phylum:

  The Phylum name (chr).

- Species:

  The species binomial name (chr).

- Test_endpoint:

  The test endpoint measure (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

## Examples

``` r

print(anzg_mancozeb_fresh, n=Inf)
#> # A tibble: 8 × 9
#>      Conc Duration Genus        Group    Life_stage Phylum Species Test_endpoint
#>     <dbl> <chr>    <chr>        <chr>    <chr>      <chr>  <chr>   <chr>        
#> 1   20    4        Chlorella    Microal… Not stated Chlor… pyreno… Growth       
#> 2  100    4        Chlorella    Microal… Not stated Chlor… vulgar… Growth       
#> 3  100    4        Scenedesmus  Microal… Not stated Chlor… quadri… Growth       
#> 4  100    4        Raphidocelis Microal… Not stated Chlor… subcap… Growth       
#> 5  500    4        Scenedesmus  Microal… Not stated Chlor… obliqu… Growth       
#> 6    7    21       Daphnia      Crustac… Neonate    Arthr… magna   Reproduction 
#> 7 2100    10       Chironomus   Insect   Larvae     Arthr… dilutus Survival     
#> 8    1.35 215      Pimephales   Fish     Larvae     Chord… promel… Growth       
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
