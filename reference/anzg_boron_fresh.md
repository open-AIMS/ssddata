# Species Sensitivity Data for boron_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***boron*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 22
rows and 6 columns.

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

## Examples

``` r

print(anzg_boron_fresh, n=Inf)
#> # A tibble: 22 × 6
#>     Conc Duration Genus               Group           Species   Toxicity_measure
#>    <dbl> <chr>    <chr>               <chr>           <chr>     <chr>           
#>  1  41   7.5      Anaxyrus            Amphibian       fowleri   Chronic LC10    
#>  2  29   7.5      Rana                Amphibian       pipiens   Chronic LC10    
#>  3  17   7        Carassius           Fish            auratus   Chronic LC10    
#>  4   1.8 34       Danio               Fish            rerio     Chronic NOEC    
#>  5  14   9        Ictalurus           Fish            punctatus Chronic LC10    
#>  6 102   12       Melanotaenia        Fish            splendida Chronic LC10    
#>  7   6   11       Micropteris         Fish            salmoides Chronic LC10    
#>  8   6.2 28       Oncorhynchus        Fish            mykiss    Chronic LC10    
#>  9  11   32       Pimephales          Fish            promelas  Chronic NOEC    
#> 10   4   52       Cirrhinus           Fish            mrigala   Chronic NOEC    
#> 11  10   21       Lampsilis           Bivalve         siliquoi… Chronic NOEC    
#> 12   6.6 42       Hyalella            Macrocrustacean azteca    Chronic NOEC    
#> 13   2.4 14       Daphnia             Macrocrustacean magna     Chronic NOEC    
#> 14   5.6 7        Ceriodaphnia        Microcrustacean dubia     Chronic NOEC    
#> 15   6.1 28       Egeria              Macrophyte      densa     Chronic NOEC    
#> 16   1.4 7        Lemna               Macrophyte      disperma  Chronic EC10    
#> 17   4.9 30       Potamogeton         Macrophyte      ochreatus Chronic IC10    
#> 18   2.8 4        Pseudokirchneriella Green microalga subcapit… Chronic NOEC    
#> 19  10   4–14     Cyclotella          Diatom          sp.       Chronic NOEC    
#> 20   0.6 4–12     Navicula            Diatom          sp.       Chronic IC10    
#> 21   1   4–16     Navicula            Diatom          sp.       Chronic NOEC    
#> 22  10   6–26     Nostoc              Blue–green alga punctifo… Chronic NOEC    
```
