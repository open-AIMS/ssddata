# Species Sensitivity Data for glyphosate_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***glyphosate*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 15
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2021). “Toxicant default guideline
values for aquatic ecosystem protection: Glyphosate in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/glyphosate_fresh_dgv_technical-brief.pdf>.

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

print(anzg_glyphosate_fresh, n=Inf)
#> # A tibble: 15 × 9
#>     Conc Duration Genus          Group   Life_stage Phylum Species Test_endpoint
#>    <dbl> <chr>    <chr>          <chr>   <chr>      <chr>  <chr>   <chr>        
#>  1 12000 5        Anabaena       Blue-g… Not stated Cyano… flosaq… Biomass yiel…
#>  2 65000 7        Ceriodaphnia   Crusta… <24-hour … Arthr… dubia   Survival     
#>  3 22500 50       Cherax         Crusta… Advanced … Arthr… quadri… Growth       
#>  4  1082 3        Chlorella      Green … Exponenti… Chlor… saccha… Cell density 
#>  5   450 21       Daphnia        Crusta… Neonate    Arthr… magna   Reproduction 
#>  6 19145 14       Hyalella       Amphip… Juvenile   Arthr… azteca  Survival     
#>  7 12500 21       Lampsilis      Bivalve Juvenile   Mollu… siliqu… Shell length 
#>  8  1400 14       Lemna          Macrop… Not stated Trach… gibba   Frond number…
#>  9  3780 7        Lemna          Macrop… Not stated Trach… minor   Chlorophyll-…
#> 10  1800 5        Navicula       Diatom  Not stated Bacil… pellic… Biomass yiel…
#> 11   316 12       Pseudosuccinea Gastro… Embryo     Mollu… colume… Hatching suc…
#> 12  2000 4        Scenedesmus    Green … Not stated Chlor… acutus  Chlorophyll-…
#> 13   770 4        Scenedesmus    Green … Not stated Chlor… quadri… Chlorophyll-…
#> 14   400 3        Scenedesmus    Green … Exponenti… Chlor… subspi… Cell density 
#> 15 10000 5        Selenastrum    Green … Not stated Chlor… capric… Chlorophyll-…
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
