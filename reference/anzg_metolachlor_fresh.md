# Species Sensitivity Data for metolachlor_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***metolachlor*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 21
rows and 10 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2020). “Toxicant default guideline
values for aquatic ecosystem protection: Metolachlor in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/anz-guidelines/guideline-values/default/water-quality-toxicants/toxicants/metolachlor-fresh-2020>.

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

- Notes:

  Other notes (chr).

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

print(anzg_metolachlor_fresh, n=Inf)
#> # A tibble: 21 × 10
#>       Conc Duration Genus    Group Life_stage Notes Phylum Species Test_endpoint
#>      <dbl> <chr>    <chr>    <chr> <chr>      <chr> <chr>  <chr>   <chr>        
#>  1 6528    4        Achnant… Diat… Exponenti… Spec… Bacil… minuti… Cell density 
#>  2  240    5        Anabaena Blue… Not stated NA    Cyano… flosaq… Biomass yiel…
#>  3   14    14       Ceratop… Macr… Not stated Spec… Trach… demers… Wet weight   
#>  4  228    4        Chlamyd… Gree… Not stated Spec… Chlor… reinha… Chlorophyll-…
#>  5    1    4        Chlorel… Gree… Exponenti… Spec… Chlor… pyreno… Chlorophyll-…
#>  6 4016    4        Craticu… Diat… Exponenti… Spec… Bacil… accomo… Chlorophyll-…
#>  7  925    4        Cyclote… Diat… Exponenti… Spec… Bacil… menegh… Cell density 
#>  8  224    21       Daphnia  Macr… <24 hour … NA    Arthr… magna   Young per fe…
#>  9  471    14       Elodea   Macr… Not stated Spec… Trach… canade… Wet weight   
#> 10 1048    4        Encyone… Diat… Exponenti… Spec… Bacil… silesi… Chlorophyll-…
#> 11   90    4        Fragila… Diat… Not stated Spec… Bacil… capuci… Chlorophyll-…
#> 12    1    7        Gomphon… Diat… Exponenti… Spec… Bacil… gracile Live cell de…
#> 13 6384    4        Gomphon… Diat… Exponenti… NA    Bacil… parvul… Chlorophyll-…
#> 14    8.4  14       Lemna    Macr… Stage 3 (… NA    Trach… gibba   Frond number 
#> 15  863    4        Mayamaea Diat… Exponenti… NA    Bacil… fossal… Chlorophyll-…
#> 16   48.4  14       Najas    Macr… Not stated NA    Trach… sp.     Wet weight   
#> 17   76    5        Navicula Diat… Not stated Spec… Bacil… pellic… Biomass yiel…
#> 18  640    35       Pimepha… Fish  Early lif… NA    Chord… promel… Mortality    
#> 19   27.4  3        Pseudok… Gree… Not stated Also… Chlor… subcap… Cell density 
#> 20    0.53 2        Scenede… Gree… Exponenti… NA    Chlor… vacuol… Cell density 
#> 21   27    4        Ulnaria  Diat… Exponenti… Spec… Bacil… ulna    Chlorophyll-…
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
