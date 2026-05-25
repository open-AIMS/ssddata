# Species Sensitivity Data for iron_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***iron*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 20
rows and 8 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2025). “Toxicant default guideline
values for aquatic ecosystem protection: Iron in freshwater.” Australian
and New Zealand Governments and Australian State and Territory
Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/iron-fresh-dgvs-technical-brief.pdf>.

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

- Species:

  The species binomial name (chr).

- Test_endpoint:

  The test endpoint measure (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

## Examples

``` r

print(anzg_iron_fresh, n=Inf)
#> # A tibble: 20 × 8
#>     Conc Duration Genus  Group Life_stage Species Test_endpoint Toxicity_measure
#>    <dbl> <chr>    <chr>  <chr> <chr>      <chr>   <chr>         <chr>           
#>  1  6900 21       Alato… Fung… NR         acumin… Growth        Chronic NOEC    
#>  2  6900 21       Artic… Fung… NR         tetrac… Growth        Chronic NOEC    
#>  3  6900 21       Tetra… Fung… NR         elegans Growth        Chronic NOEC    
#>  4   442 3        Raphi… Micr… Not stated subcap… Yield         Chronic EC10    
#>  5  1000 64       Phrag… Macr… Seedling   austra… Growth        Chronic NOEC    
#>  6   957 5        Euchl… Roti… Neonate    dilata… Reproduction  Chronic LC10    
#>  7   470 35       Lumbr… Anne… Worm       varieg… Reproduction  Chronic EC10    
#>  8 40000 30       Duges… Plan… Not stated doroto… Growth        Chronic EC10    
#>  9  7863 30       Hexag… Inse… Nymph      limbata Survival      Chronic EC10    
#> 10 50000 30       Lepto… Inse… Larvae     margin… Immobility    Chronic NOEC    
#> 11   383 7        Cerio… Crus… Neonate    dubia   Reproduction  Chronic EC10    
#> 12  4380 21       Daphn… Crus… Neonate    magna   Reproduction  Chronic EC16    
#> 13   852 21       Daphn… Crus… Neonate    pulex   Reproduction  Chronic NOEC    
#> 14  2607 35       Bufo   Amph… Tadpole    boreas  Biomass       Chronic EC10    
#> 15  3040 7        Oncor… Fish  Larvae     kisutch Mortality     Chronic NOECâ†’…
#> 16 25000 7        Oryzi… Fish  Larvae     latipes Mortality     Chronic NOEC    
#> 17   192 7        Pimep… Fish  Larvae     promel… Growth        Chronic EC10    
#> 18   868 78       Proso… Fish  Egg        willia… Biomass       Chronic EC10    
#> 19  5000 79       Salmo  Fish  Egg        trutta  Biomass       Chronic EC20    
#> 20 10280 245      Salve… Fish  3 months   fontin… Growth        Chronic NOEC    
```
