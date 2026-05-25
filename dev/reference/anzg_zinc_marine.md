# Species Sensitivity Data for zinc_marine

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***zinc*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 16
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2021). “Toxicant default guideline
values for aquatic ecosystem protection: Zinc in marine water.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/zinc_marine_dgv_technical-brief.pdf>.

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

print(anzg_zinc_marine, n=Inf)
#> # A tibble: 16 × 9
#>     Conc Duration Genus        Group     Life_stage Phylum Species Test_endpoint
#>    <dbl> <chr>    <chr>        <chr>     <chr>      <chr>  <chr>   <chr>        
#>  1   153 2        Entomoneis   Diatom    Log phase  Ochro… punctu… Population g…
#>  2    84 3        Ceratoneis   Diatom    Log phase  Ochro… closte… Population g…
#>  3    54 3        Dunaliella   Green al… NR         Chlor… tertio… Mortality    
#>  4   143 4        Ulva         Green al… Zoospores  Chlor… fasiata Growth and g…
#>  5  1070 16       Macrocystis  Brown al… Zoospores  Ochro… pyrife… Reproduction 
#>  6    24 4        Hydroides    Annelid   Larvae     Annel… elegans Development  
#>  7     9 28       Aiptasia     Anemone   Adult      Cnida… pulche… Reproduction 
#>  8    62 28       Allorchestes Crustace… Juveniles  Arthr… compre… Mortality    
#>  9   230 14       Callianassa  Crustace… Adult      Arthr… austra… Immobilisati…
#> 10    24 2        Crassostrea  Mollusc   Embryos    Mollu… gigas   Development  
#> 11    64 28       Haliotis     Mollusc   NR         Mollu… divers… Growth       
#> 12     5 2        Mimachlamys  Mollusc   Larvae     Mollu… asperr… Development  
#> 13    35 2        Mytilus      Mollusc   Eggs/Larv… Mollu… edulis  Development  
#> 14    36 2        Mytilus      Mollusc   Embryos    Mollu… gallop… Development  
#> 15    64 2        Mytilus      Mollusc   Embryos    Mollu… trossu… Development  
#> 16  2080 14       Saccostrea   Mollusc   Larvae     Mollu… glomer… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
