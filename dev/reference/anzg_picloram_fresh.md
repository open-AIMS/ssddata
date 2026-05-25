# Species Sensitivity Data for picloram_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***picloram*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 12
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2024). “Toxicant default guideline
values for aquatic ecosystem protection: Picloram in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/picloram-fresh-dgvs-technical-brief.pdf>.

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

print(anzg_picloram_fresh, n=Inf)
#> # A tibble: 12 × 9
#>     Conc Duration Genus        Group     Life_stage Phylum Species Test_endpoint
#>    <dbl> <chr>    <chr>        <chr>     <chr>      <chr>  <chr>   <chr>        
#>  1  8944 4        Raphidocelis Microalga Not stated Chlor… subcap… Growth       
#>  2 10000 4        Chlorella    Microalga Not stated Chlor… vulgar… Growth       
#>  3  1650 4        Gammarus     Crustace… Juvenile   Arthr… pseudo… Mortality    
#>  4  2700 4        Gammarus     Crustace… Adult      Arthr… fascic… Mortality    
#>  5 11800 21       Daphnia      Crustace… Neonate    Arthr… magna   Reproduction 
#>  6  4800 10       Pteronarcys  Insect    YC-2       Arthr… califo… Mortality    
#>  7   140 4        Ictalurus    Fish      Juvenile   Chord… puncta… Mortality    
#>  8   229 4        Oncorhynchus Fish      Juvenile   Chord… clarkii Mortality    
#>  9   236 4        Salvelinus   Fish      Juvenile   Chord… namayc… Mortality    
#> 10   550 60       Oncorhynchus Fish      Embryo     Chord… mykiss  Growth       
#> 11  2226 4        Lepomis      Fish      Juvenile   Chord… macroc… Mortality    
#> 12  5530 4        Pimephales   Fish      Juvenile   Chord… promel… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
