# Species Sensitivity Data for paraquat_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***paraquat*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 10
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2024). “Toxicant default guideline
values for aquatic ecosystem protection: Paraquat in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/paraquat-fresh-dgvs-technical-brief.pdf>.

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

print(anzg_paraquat_fresh, n=Inf)
#> # A tibble: 10 × 9
#>     Conc Duration Genus        Group     Life_stage Phylum Species Test_endpoint
#>    <dbl> <chr>    <chr>        <chr>     <chr>      <chr>  <chr>   <chr>        
#>  1   2.6 4        Oscillatoria Cyanobac… Not stated Cyano… cf. ch… Growth       
#>  2 114   4        Raphidocelis Green al… Not stated Chlor… subcap… Growth       
#>  3   5.1 4        Lemna        Macrophy… Not stated Trach… minor   Growth       
#>  4   1   28       Lemna        Macrophy… Not stated Trach… gibba   Growth       
#>  5  31.8 7        Lemna        Macrophy… Not stated Trach… paucic… Growth       
#>  6  15.2 2        Mesocyclops  Crustace… Nauplii    Arthr… sp.     Mortality    
#>  7  20.7 2        Mesocyclops  Crustace… Nauplii    Arthr… asperi… Mortality    
#>  8 125   2        Daphnia      Crustace… Neonates   Arthr… magna   Immobilisati…
#>  9   8.4 1        Oncorhynchus Fish      Juveniles  Chord… mykiss  Mortality    
#> 10  13.8 5        Xenopus      Amphibian Embryo     Chord… laevis  Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
