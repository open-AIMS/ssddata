# Species Sensitivity Data for nitrate_hard_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***nitrate*** in hard freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 12
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

print(anzg_nitrate_hard_fresh, n=Inf)
#> # A tibble: 12 × 10
#>       Conc Duration Genus        Group   Life_stage Phylum Species Test_endpoint
#>      <dbl> <chr>    <chr>        <chr>   <chr>      <chr>  <chr>   <chr>        
#>  1 1600000 3        Chlorella    Microa… Exponenti… Chlor… sp.     Growth       
#>  2 1700000 3        Oocystis     Microa… Exponenti… Chlor… solita… Growth       
#>  3  220000 4        Hydra        Cnidar… Adult      Cnida… viridi… Population g…
#>  4  120000 10       Chironomus   Insect  Larvae     Arthr… dilutus Growth weight
#>  5   28500 7        Ceriodaphnia Crusta… Neonates   Arthr… dubia   Reproduction 
#>  6  358000 7        Daphnia      Crusta… Neonates   Arthr… magna   Reproduction 
#>  7  102000 14       Hyalella     Crusta… Juvenile   Arthr… azteca  Growth weight
#>  8   45000 13       Simocephalus Crusta… Neonates   Arthr… heilon… Reproduction 
#>  9  268000 30       Notropis     Fish    Juvenile   Chord… topeka  Growth       
#> 10  335000 42       Oncorhynchus Fish    Fry        Chord… mykiss  Growth       
#> 11   46700 32       Pimephales   Fish    Embryo la… Chord… promel… Growth weight
#> 12   47000 52       Hyla         Amphib… Juvenile   Chord… versic… Metamorphosis
#> # ℹ 2 more variables: Toxicity_measure <chr>, Units <chr>
```
