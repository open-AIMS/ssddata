# Species Sensitivity Data for simazine_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***simazine*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 20
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2024). “Toxicant default guideline
values for aquatic ecosystem protection: Simazine in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/simazine-fresh-dgvs-technical-brief.pdf>.

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

print(anzg_simazine_fresh, n=Inf)
#> # A tibble: 20 × 9
#>      Conc Duration Genus           Group Life_stage Phylum Species Test_endpoint
#>     <dbl> <chr>    <chr>           <chr> <chr>      <chr>  <chr>   <chr>        
#>  1 1000   21       Daphnia         Arth… Not stated Arthr… magna   Mortality    
#>  2   18   5        Navicula        Diat… Not stated Bacil… pellic… Cell density 
#>  3  171   3        Chlamydomonas   Gree… Exponenti… Chlor… geitle… Growth rate  
#>  4   65   6        Chlorella       Gree… Not stated Chlor… pyreno… Abundance    
#>  5  435   4        Chlorella       Gree… Not stated Chlor… vulgar… Abundance    
#>  6   32   3        Pseudokirchner… Gree… Not stated Chlor… subcap… Growth rate  
#>  7   51.4 4        Scenedesmus     Gree… Not stated Chlor… obliqu… Growth rate  
#>  8   30   4        Scenedesmus     Gree… Not stated Chlor… quadri… Abundance    
#>  9 1000   365      Carassius       Fish  Not stated Chord… auratus Mortality    
#> 10   45   90       Cyprinus        Fish  Not stated Chord… carpio  Weight and m…
#> 11 1000   365      Lepomis         Fish  Not stated Chord… macroc… Mortality    
#> 12  500   28       Oncorhynchus    Fish  Not stated Chord… mykiss  Mortality    
#> 13 1000   120      Pimephales      Fish  Early lif… Chord… promel… Mortality    
#> 14    7.2 5        Anabaena        Cyan… Not stated Cyano… flos-a… Cell density 
#> 15  100   7        Acorus          Macr… Not stated Trach… gramin… Fresh weight 
#> 16   28   14       Lemna           Macr… Not stated Trach… gibba   Biomass yield
#> 17   20   7        Myriophyllum    Macr… 2 weeks o… Trach… aquati… Fresh weight 
#> 18  100   7        Pontederia      Macr… Not stated Trach… cordata Fresh weight 
#> 19  300   7        Typha           Macr… Not stated Trach… latifo… Fresh weight 
#> 20   58   13       Vallisneria     Macr… Not stated Trach… americ… Length       
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
