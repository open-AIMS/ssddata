# Species Sensitivity Data for ametryn_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***ametryn*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 8
rows and 6 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2025). “Toxicant default guideline
values for aquatic ecosystem protection: Ametryn in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/ametryn-fresh-dgvs-technical-brief.pdf>.

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

print(anzg_ametryn_fresh, n=Inf)
#> # A tibble: 8 × 6
#>      Conc Duration Genus        Group      Species       Toxicity_measure
#>     <dbl> <chr>    <chr>        <chr>      <chr>         <chr>           
#> 1    0.06 96       Chlorella    Green alga pyrenoidosa   Chronic EC50    
#> 2 2000    240      Chlorococcum Green alga sp.           Chronic EC50    
#> 3    7.2  72       Neochloris   Green alga sp.           Chronic EC50    
#> 4    4.8  72       Platymonas   Green alga sp.           Chronic EC50    
#> 5   30    96       Scenedesmus  Green alga quadricauda   Chronic EC50    
#> 6    1.14 168      Selenastrum  Green alga capricornutum Chronic NOEL    
#> 7    2    168      Lemna        Macrophyte gibba         Chronic NOEL    
#> 8    5.2  72       Stauroneis   Diatom     amphoroides   Chronic EC50    
```
