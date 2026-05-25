# Species Sensitivity Data for fluoride_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***fluoride*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 22
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2024). “Toxicant default guideline
values for aquatic ecosystem protection: Fluoride in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/fluoride-fresh-dgvs-technical-brief.pdf>.

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

- Species:

  The species binomial name (chr).

- Test_endpoint:

  The test endpoint measure (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

## Examples

``` r

print(anzg_fluoride_fresh, n=Inf)
#> # A tibble: 22 × 9
#>     Conc Duration Genus          Group    Life_stage Notes Species Test_endpoint
#>    <dbl> <chr>    <chr>          <chr>    <chr>      <chr> <chr>   <chr>        
#>  1  95   15       Chlorella      Green a… Not stated Valu… vulgar… Growth       
#>  2  50   6.3      Scenedesmus    Green a… Not stated Valu… quadri… Growth       
#>  3 127   3        Scenedesmus    Green a… Not stated Valu… subspi… Growth       
#>  4 195   3        Raphidocelis   Green a… Not stated Valu… subcap… Growth       
#>  5  50   6.3      Ankistrodesmus Green a… Not stated Valu… braunii Growth       
#>  6  50   6.3      Nephroselmis   Green a… Not stated Valu… pyrifo… Growth       
#>  7  50   6.3      Cyclotella     Diatom   Not stated Valu… menegh… Growth       
#>  8  50   6.3      Stephanodiscus Diatom   Not stated Valu… minutus Growth       
#>  9  50   6.3      Oscillatoria   Cyanoba… Not stated Valu… limnet… Growth       
#> 10  25   6.3      Synechococcus  Cyanoba… Not stated Valu… leopol… Growth       
#> 11 125   7        Lemna          Macroph… Not stated Valu… minor   Growth       
#> 12  19.7 21       Daphnia        Crustac… Neonate <… Valu… magna   Reproduction 
#> 13  10.6 7        Ceriodaphnia   Crustac… Neonate <… Valu… dubia   Reproduction 
#> 14   1.8 14       Hyalella       Crustac… Not stated Valu… azteca  Growth       
#> 15   4.1 10       Chironomus     Insect   Not stated Valu… dilutus Growth       
#> 16   1.8 56       Musculium      Mollusc  Not stated Valu… transv… Growth       
#> 17   4.6 28       Potamopyrgus   Mollusc  Not stated Valu… antipo… Growth       
#> 18   7.7 90       Acipenser      Fish     Not stated Valu… baerii  Growth       
#> 19   5   21       Oncorhynchus   Fish     10 cm      Valu… mykiss  Mortality    
#> 20  14.6 7        Pimephales     Fish     <24-h pos… Valu… promel… Growth       
#> 21 134   17       Salvelinus     Fish     Embryo     Valu… namayc… Growth       
#> 22   8.5 8        Rana           Amphibi… Embryo     Valu… chensi… Growth       
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
