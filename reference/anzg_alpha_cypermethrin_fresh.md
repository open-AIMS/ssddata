# Species Sensitivity Data for alpha_cypermethrin_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***alpha cypermethrin*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 14
rows and 7 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2023). “Toxicant default guideline
values for aquatic ecosystem protection: Alpha-cypermethrin in
freshwater.” Australian and New Zealand Governments and Australian State
and Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/alpha-cypermethrin-fresh-dgvs-technical-brief.pdf>.

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

- Species:

  The species binomial name (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

## Examples

``` r

print(anzg_alpha_cypermethrin_fresh, n=Inf)
#> # A tibble: 14 × 7
#>      Conc Duration Genus             Group   Life_stage Species Toxicity_measure
#>     <dbl> <chr>    <chr>             <chr>   <chr>      <chr>   <chr>           
#>  1 27.2   96       Anabaena          Cyanob… Not stated flosaq… Chronic NOEC    
#>  2 72     96       Navicula          Diatom  Not stated pellic… Chronic NOEC    
#>  3  1.39  168      Lemna             Macrop… Not stated gibba   Chronic NOEC    
#>  4  0.002 96       Paratya           Crusta… Adults     austra… Acute LC50      
#>  5  0.025 192      Ceriodaphnia      Crusta… Neonates   dubia   Chronic NOEC    
#>  6  0.037 504      Daphnia           Crusta… Neonates   magna   Chronic NOEC    
#>  7  0.143 24       Culex             Insect  Larvae     tritae… Acute LC50      
#>  8  6     24       Anopheles         Insect  Larvae     sinens… Acute LC50      
#>  9  0.69  96       Xenopus           Amphib… Larvae     laevis  Acute LC50      
#> 10  0.063 96       Rutilus           Fish    Juveniles  rutilu… Acute LC50      
#> 11  0.092 96       Hypophthalmicthys Fish    Juveniles  molitr… Acute LC50      
#> 12  0.095 96       Huso              Fish    Juveniles  huso    Acute LC50      
#> 13  0.342 96       Oreochromis       Fish    Larvae     niloti… Acute LC50      
#> 14  0.943 96       Poecilia          Fish    Adults     reticu… Acute LC50      
```
