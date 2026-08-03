# Species Sensitivity Data for ammonia_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***ammonia*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 40
rows and 7 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2026). “Toxicant default guideline
values for aquatic ecosystem protection: Ammonia in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/ammonia-fresh-dgvs-technical-brief.pdf>.

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

print(anzg_ammonia_fresh, n=Inf)
#> # A tibble: 40 × 7
#>      Conc Duration Genus         Group      Species       Toxicity_measure Units
#>     <dbl> <chr>    <chr>         <chr>      <chr>         <chr>            <chr>
#>  1 165    3        Chlorella     Microalga  vulgaris      Chronic EC10     ug/L 
#>  2 560    3        Raphidocelis  Microalga  subcapitata   Chronic EC10     ug/L 
#>  3   1.2  30       Polycelis     Flatworm   felina        Chronic NOEC     ug/L 
#>  4  42    7        Ceriodaphnia  Cladoceran dubia         Chronic NOEC     ug/L 
#>  5  21    21       Daphnia       Cladoceran magna         Chronic NOEC     ug/L 
#>  6  29    21       Chironomus    Insect     riparius      Chronic NOEC     ug/L 
#>  7   7.2  29       Coloburiscus  Insect     humeralis     Chronic NOEC     ug/L 
#>  8   3.2  29       Deleatidium   Insect     sp.           Chronic NOEC     ug/L 
#>  9   8.9  70       Hyalella      Amphipod   azteca        Chronic NOEC     ug/L 
#> 10  19    21       Neocardidina  Shrimp     denticulata … Chronic NOEC     ug/L 
#> 11  48    26       Bellamya      Mollusc    aeruginosa    Chronic NOEC     ug/L 
#> 12   8.8  28       Fluminicola   Mollusc    sp.           Chronic EC20     ug/L 
#> 13   2.8  28       Fontigens     Mollusc    aldrichi      Chronic EC20     ug/L 
#> 14  31    28       Lymnaea       Mollusc    stagnalis     Chronic EC20     ug/L 
#> 15  38    28       Physa         Mollusc    gyrina        Chronic EC20     ug/L 
#> 16   4.4  40       Potamopyrgus  Mollusc    antipodarum   Chronic NOEC     ug/L 
#> 17  14    28       Pyrgulopis    Mollusc    robusta       Chronic LC20     ug/L 
#> 18  12    28       Taylorconcha  Mollusc    serpenticola  Chronic LC20     ug/L 
#> 19   0.43 28       Lampsilis     Mollusc    fasciola      Chronic IC10     ug/L 
#> 20   0.92 28       Lampsilis     Mollusc    siliquoidea   Chronic IC10     ug/L 
#> 21   2.3  42       Musculium     Mollusc    transversum   Chronic NOEC     ug/L 
#> 22   1.1  60       Sphaerium     Mollusc    novaezelandi… Chronic NOEC     ug/L 
#> 23   1.3  28       Villosa       Mollusc    iris          Chronic IC10     ug/L 
#> 24   4.8  39       Bidyanus      Fish       bidyanus      Chronic EC10     ug/L 
#> 25  14    30       Deltistes     Fish       luxatus       Chronic NOEC     ug/L 
#> 26  20    52       Esox          Fish       lucius        Chronic EC20     ug/L 
#> 27   5.2  30       Ictalurus     Fish       punctatus     Chronic NOEC     ug/L 
#> 28  11    44       Lepomis       Fish       cyanellus     Chronic NOEC     ug/L 
#> 29   3.2  60       Lota          Fish       lota          Chronic EC10     ug/L 
#> 30  10    63       Megalobrama   Fish       amblycephala  Chronic NOEC     ug/L 
#> 31  13    32       Micropterus   Fish       dolomieue     Chronic NOEC     ug/L 
#> 32  18    30       Notropis      Fish       topeka        Chronic NOEC     ug/L 
#> 33  11    35       Oncorhynchus  Fish       mykiss        Chronic NOEC     ug/L 
#> 34   3.8  75       Oreochromis   Fish       niloticus     Chronic NOEC     ug/L 
#> 35   4.1  56       Pelteobagrus  Fish       fulvidraco    Chronic NOEC     ug/L 
#> 36   7.2  28       Pimephales    Fish       promelas      Chronic LC1      ug/L 
#> 37  21    28       Ptychocheilus Fish       lucius        Chronic LC1      ug/L 
#> 38  14    28       Xyrauchen     Fish       texanus       Chronic LC1      ug/L 
#> 39   7.1  10       Pseudacris    Amphibian  regilla       Chronic NOEC     ug/L 
#> 40  86    10       Xenopus       Amphibian  laevis        Chronic NOEC     ug/L 
```
