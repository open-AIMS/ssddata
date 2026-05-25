# Species Sensitivity Data for mcpa_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***mcpa*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 16
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2024). “Toxicant default guideline
values for aquatic ecosystem protection: MCPA in freshwater.” Australian
and New Zealand Governments and Australian State and Territory
Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/mcpa-fresh-dgvs-technical-brief.pdf>.

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

print(anzg_mcpa_fresh, n=Inf)
#> # A tibble: 16 × 9
#>        Conc Duration Genus         Group Life_stage Phylum Species Test_endpoint
#>       <dbl> <chr>    <chr>         <chr> <chr>      <chr>  <chr>   <chr>        
#>  1     32   4        Raphidocelis  Gree… Not stated Chlor… subcap… Growth       
#>  2  17020   20       Scenedesmus   Gree… Not stated Chlor… quadri… Growth       
#>  3 143000   3        Desmodesmus   Gree… Not stated Chlor… subspi… Growth       
#>  4    470   5        Anabaena      Blue… Not stated Cyano… flos-a… Growth       
#>  5     14   14       Lemna         Macr… Not stated Trach… gibba   Growth       
#>  6    248   7        Lemna         Macr… Not stated Trach… minor   Growth       
#>  7      7.7 5        Navicula      Diat… Not stated Bacil… pellic… Growth       
#>  8     20   2        Gomphonema    Diat… Not stated Bacil… sp.     Growth       
#>  9     20   2        Encyonema     Diat… Not stated Bacil… gracil… Growth       
#> 10     20   2        Ulnaria       Diat… Not stated Bacil… ulna    Growth       
#> 11    500   2        Gomphonema    Diat… Not stated Bacil… gracile Growth       
#> 12    500   2        Cymbella      Diat… Not stated Bacil… sp.     Growth       
#> 13    500   2        Achnanthidium Diat… Not stated Bacil… minuti… Growth       
#> 14    500   2        Eunotia       Diat… Not stated Bacil… cf. in… Growth       
#> 15    500   2        Navicula      Diat… Not stated Bacil… crypto… Growth       
#> 16  13000   21       Daphnia       Crus… Neonate    Arthr… magna   Immobilisati…
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
