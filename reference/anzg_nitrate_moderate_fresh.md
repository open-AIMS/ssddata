# Species Sensitivity Data for nitrate_moderate_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***nitrate*** in moderately hard freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 11
rows and 10 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2025). “Toxicant default guideline
values for aquatic ecosystem protection: Nitrate in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/nitrate-fresh-dgvs-technical-brief.pdf>.

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

- Units:

  The concentration units of Conc (micrograms per Litre, ug/L) (chr).

## Examples

``` r

print(anzg_nitrate_moderate_fresh, n=Inf)
#> # A tibble: 11 × 10
#>      Conc Duration Genus        Group    Life_stage Phylum Species Test_endpoint
#>     <dbl> <chr>    <chr>        <chr>    <chr>      <chr>  <chr>   <chr>        
#>  1  17000 28       Lampsilis    Mollusc  Juvenile   Mollu… siliqu… Weight       
#>  2   5800 10       Chironomus   Insect   Larva      Arthr… dilutus Growth weight
#>  3  20300 20       Deleatidium  Insect   Larva      Arthr… sp.     Mortality    
#>  4  19400 7        Ceriodaphnia Crustac… Neonates   Arthr… dubia   Reproduction 
#>  5  11000 42       Hyalella     Crustac… Juvenile   Arthr… azteca  Growth weight
#>  6 200000 29       Danio        Fish     Juvenile   Chord… rerio   Mortality an…
#>  7  26600 40       Galaxias     Fish     Juvenile   Chord… macula… Mortality    
#>  8  24900 21       Gobiomorphus Fish     Juvenile   Chord… cotidi… Mortality    
#>  9 120000 42       Oncorhynchus Fish     Fry        Chord… mykiss  Yolk develop…
#> 10   6600 7        Pimephales   Fish     Embryo la… Chord… promel… Growth weight
#> 11  56700 10       Pseudacris   Amphibi… Embryo     Chord… regilla Length       
#> # ℹ 2 more variables: Toxicity_measure <chr>, Units <chr>
```
