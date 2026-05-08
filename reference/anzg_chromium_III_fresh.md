# Species Sensitivity Data for chromium_III_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***chromium III*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 13
rows and 6 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2026). “Toxicant default guideline
values for aquatic ecosystem protection: Chromium (III) in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/chromium-III-fresh-dgvs-technical-brief.pdf>.

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

print(anzg_chromium_III_fresh, n=Inf)
#> # A tibble: 13 × 6
#>     Conc Duration Genus           Group      Species       Toxicity_measure
#>    <dbl> <chr>    <chr>           <chr>      <chr>         <chr>           
#>  1  19   48       Spirostomum     Protozoa   ambiguum      Chronic EC50    
#>  2   3.4 72       Raphidocelis    Microalga  subcapitata   Chronic EC50    
#>  3  10   72       Chlorella       Microalga  kessleri      Chronic EC50    
#>  4 557   72       Dictyosphaerium Microalga  chlorelloides Chronic EC50    
#>  5  82   24       Brachionus      Rotifer    calyciflorus  Acute LC50      
#>  6 128   24       Lecane          Rotifer    quadridentata Acute LC50      
#>  7 330   504      Daphnia         Crustacean magna         Chronic EC16    
#>  8 324   48       Daphnia         Crustacean similis       Acute EC50      
#>  9  48   1,728    Oncorhynchus    Fish       mykiss        Chronic NOEC    
#> 10 333   96       Poecilia        Fish       reticulata    Acute LC50      
#> 11 410   96       Carassius       Fish       auratus       Acute LC50      
#> 12 507   96       Pimephales      Fish       promelas      Acute LC50      
#> 13 746   96       Lepomis         Fish       macrochirus   Acute LC50      
```
