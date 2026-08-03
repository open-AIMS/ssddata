# Species Sensitivity Data for boron_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***boron*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 22
rows and 7 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2021). “Toxicant default guideline
values for aquatic ecosystem protection: Boron in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/boron_fresh_dgv_technical-brief.pdf>.

The columns are as follows:

- Conc:

  The chemical concentration in micrograms per Litre (dbl).

- Duration:

  The duration of the test in days (chr).

- Genus:

  The Genus name (chr).

- Group:

  The taxonomic group (chr).

- Species:

  The species binomial name (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

- Units:

  The concentration units of Conc (micrograms per Litre, ug/L) (chr).

## Examples

``` r

print(anzg_boron_fresh, n=Inf)
#> # A tibble: 22 × 7
#>      Conc Duration Genus               Group      Species Toxicity_measure Units
#>     <dbl> <chr>    <chr>               <chr>      <chr>   <chr>            <chr>
#>  1  41000 7.5      Anaxyrus            Amphibian  fowleri Chronic LC10     ug/L 
#>  2  29000 7.5      Rana                Amphibian  pipiens Chronic LC10     ug/L 
#>  3  17000 7        Carassius           Fish       auratus Chronic LC10     ug/L 
#>  4   1800 34       Danio               Fish       rerio   Chronic NOEC     ug/L 
#>  5  14000 9        Ictalurus           Fish       puncta… Chronic LC10     ug/L 
#>  6 102000 12       Melanotaenia        Fish       splend… Chronic LC10     ug/L 
#>  7   6000 11       Micropteris         Fish       salmoi… Chronic LC10     ug/L 
#>  8   6200 28       Oncorhynchus        Fish       mykiss  Chronic LC10     ug/L 
#>  9  11000 32       Pimephales          Fish       promel… Chronic NOEC     ug/L 
#> 10   4000 52       Cirrhinus           Fish       mrigala Chronic NOEC     ug/L 
#> 11  10000 21       Lampsilis           Bivalve    siliqu… Chronic NOEC     ug/L 
#> 12   6600 42       Hyalella            Macrocrus… azteca  Chronic NOEC     ug/L 
#> 13   2400 14       Daphnia             Macrocrus… magna   Chronic NOEC     ug/L 
#> 14   5600 7        Ceriodaphnia        Microcrus… dubia   Chronic NOEC     ug/L 
#> 15   6100 28       Egeria              Macrophyte densa   Chronic NOEC     ug/L 
#> 16   1400 7        Lemna               Macrophyte disper… Chronic EC10     ug/L 
#> 17   4900 30       Potamogeton         Macrophyte ochrea… Chronic IC10     ug/L 
#> 18   2800 4        Pseudokirchneriella Green mic… subcap… Chronic NOEC     ug/L 
#> 19  10000 4–14     Cyclotella          Diatom     sp.     Chronic NOEC     ug/L 
#> 20    600 4–12     Navicula            Diatom     sp.     Chronic IC10     ug/L 
#> 21   1000 4–16     Navicula            Diatom     sp.     Chronic NOEC     ug/L 
#> 22  10000 6–26     Nostoc              Blue–gree… puncti… Chronic NOEC     ug/L 
```
