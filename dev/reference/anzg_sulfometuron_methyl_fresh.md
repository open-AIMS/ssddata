# Species Sensitivity Data for sulfometuron_methyl_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***sulfometuron_methyl*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 6
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2024). “Toxicant default guideline
values for aquatic ecosystem protection: Sulfometuron-methyl in
freshwater.” Australian and New Zealand Governments and Australian State
and Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/sulfometuron-methyl-fresh-dgvs-technical-brief.pdf>.

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

print(anzg_sulfometuron_methyl_fresh, n=Inf)
#> # A tibble: 6 × 9
#>       Conc Duration Genus        Group   Life_stage Phylum Species Test_endpoint
#>      <dbl> <chr>    <chr>        <chr>   <chr>      <chr>  <chr>   <chr>        
#> 1    0.63  5        Raphidocelis Green … Not stated Chlor… subcap… Growth       
#> 2   14     5        Anabaena     Cyanob… Not stated Cyano… flos-a… Growth       
#> 3  370     5        Navicula     Diatom  Not stated Bacil… pellic… Growth       
#> 4    0.207 14       Lemna        Macrop… Not stated Trach… gibba   Growth       
#> 5 6100     21       Daphnia      Crusta… Neonates   Arthr… magna   Reproduction 
#> 6 1000     30       Xenopus      Amphib… Embryos    Chord… laevis  Development  
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
