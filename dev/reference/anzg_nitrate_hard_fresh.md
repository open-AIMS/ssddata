# Species Sensitivity Data for nitrate_hard_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***nitrate*** in hard freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 12
rows and 9 columns.

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

## Examples

``` r

print(anzg_nitrate_hard_fresh, n=Inf)
#> # A tibble: 12 × 9
#>      Conc Duration Genus        Group    Life_stage Phylum Species Test_endpoint
#>     <dbl> <chr>    <chr>        <chr>    <chr>      <chr>  <chr>   <chr>        
#>  1 1600   3        Chlorella    Microal… Exponenti… Chlor… sp.     Growth       
#>  2 1700   3        Oocystis     Microal… Exponenti… Chlor… solita… Growth       
#>  3  220   4        Hydra        Cnidari… Adult      Cnida… viridi… Population g…
#>  4  120   10       Chironomus   Insect   Larvae     Arthr… dilutus Growth weight
#>  5   28.5 7        Ceriodaphnia Crustac… Neonates   Arthr… dubia   Reproduction 
#>  6  358   7        Daphnia      Crustac… Neonates   Arthr… magna   Reproduction 
#>  7  102   14       Hyalella     Crustac… Juvenile   Arthr… azteca  Growth weight
#>  8   45   13       Simocephalus Crustac… Neonates   Arthr… heilon… Reproduction 
#>  9  268   30       Notropis     Fish     Juvenile   Chord… topeka  Growth       
#> 10  335   42       Oncorhynchus Fish     Fry        Chord… mykiss  Growth       
#> 11   46.7 32       Pimephales   Fish     Embryo la… Chord… promel… Growth weight
#> 12   47   52       Hyla         Amphibi… Juvenile   Chord… versic… Metamorphosis
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
