# Species Sensitivity Data for alpha_cypermethrin_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***alpha_cypermethrin*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 14
rows and 8 columns.

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

- Units:

  The concentration units of Conc (micrograms per Litre, ug/L) (chr).

## Examples

``` r

print(anzg_alpha_cypermethrin_fresh, n=Inf)
#> # A tibble: 14 × 8
#>      Conc Duration Genus         Group Life_stage Species Toxicity_measure Units
#>     <dbl> <chr>    <chr>         <chr> <chr>      <chr>   <chr>            <chr>
#>  1 27.2   96       Anabaena      Cyan… Not stated flosaq… Chronic NOEC     ug/L 
#>  2 72     96       Navicula      Diat… Not stated pellic… Chronic NOEC     ug/L 
#>  3  1.39  168      Lemna         Macr… Not stated gibba   Chronic NOEC     ug/L 
#>  4  0.002 96       Paratya       Crus… Adults     austra… Acute LC50       ug/L 
#>  5  0.025 192      Ceriodaphnia  Crus… Neonates   dubia   Chronic NOEC     ug/L 
#>  6  0.037 504      Daphnia       Crus… Neonates   magna   Chronic NOEC     ug/L 
#>  7  0.143 24       Culex         Inse… Larvae     tritae… Acute LC50       ug/L 
#>  8  6     24       Anopheles     Inse… Larvae     sinens… Acute LC50       ug/L 
#>  9  0.69  96       Xenopus       Amph… Larvae     laevis  Acute LC50       ug/L 
#> 10  0.063 96       Rutilus       Fish  Juveniles  rutilu… Acute LC50       ug/L 
#> 11  0.092 96       Hypophthalmi… Fish  Juveniles  molitr… Acute LC50       ug/L 
#> 12  0.095 96       Huso          Fish  Juveniles  huso    Acute LC50       ug/L 
#> 13  0.342 96       Oreochromis   Fish  Larvae     niloti… Acute LC50       ug/L 
#> 14  0.943 96       Poecilia      Fish  Adults     reticu… Acute LC50       ug/L 
```
