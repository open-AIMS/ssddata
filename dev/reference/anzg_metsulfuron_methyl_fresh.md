# Species Sensitivity Data for metsulfuron_methyl_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***metsulfuron_methyl*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 8
rows and 10 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2021). “Toxicant default guideline
values for aquatic ecosystem protection: Metsulfuron-methyl in
freshwater.” Australian and New Zealand Governments and Australian State
and Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/metsulfuron-methyl_fresh_dgv-technical-brief_0.pdf>.

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

print(anzg_metsulfuron_methyl_fresh, n=Inf)
#> # A tibble: 8 × 10
#>        Conc Duration Genus   Group Life_stage Notes Phylum Species Test_endpoint
#>       <dbl> <chr>    <chr>   <chr> <chr>      <chr> <chr>  <chr>   <chr>        
#> 1    95.4   5        Anabae… Blue… Not stated NA    Cyano… flos-a… Biomass yiel…
#> 2     0.054 8        Elodea  Macr… Apical sh… Apic… Trach… canade… Shoot length 
#> 3     0.193 7        Lemna   Macr… Not stated NA    Trach… gibba   Frond count  
#> 4     0.1   42       Lemna   Macr… Exponenti… NA    Trach… minor   Frond count  
#> 5     0.4   14       Myriop… Macr… Apical sh… NA    Trach… spicat… Root occurre…
#> 6 92800     4        Navicu… Diat… Not stated NA    Bacil… pellic… Biomass yiel…
#> 7  4500     90       Oncorh… Fish  Early life NA    Chord… mykiss  Mortality    
#> 8    10     5        Pseudo… Gree… Not stated NA    Chlor… subcap… Biomass yiel…
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
