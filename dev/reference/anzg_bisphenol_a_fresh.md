# Species Sensitivity Data for bisphenol_a_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***bisphenol_a*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 19
rows and 6 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2023). “Toxicant default guideline
values for aquatic ecosystem protection: Bisphenol A in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/bisphenol-a-fresh-dgvs-technical-brief.pdf>.

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

print(anzg_bisphenol_a_fresh, n=Inf)
#> # A tibble: 19 × 6
#>      Conc Duration Genus        Group              Species      Toxicity_measure
#>     <dbl> <chr>    <chr>        <chr>              <chr>        <chr>           
#>  1  500   90       Xenopus      Amphibian          laevis       Chronic NOEC    
#>  2 1800   14       Rhinella     Amphibian          arenarum     Chronic NOEC    
#>  3  120   21       Daphnia      Crustacean         magna        Chronic LC50    
#>  4  490   42       Hyalella     Crustacean         azteca       Chronic NOEC    
#>  5    4   90       Danio        Fish               rerio        Chronic LOEC    
#>  6   16   164      Pimephales   Fish               promelas     Chronic NOEC    
#>  7   60   44       Oryzias      Fish               latipes      Chronic NOEC    
#>  8  100   20       Chironomus   Insect             riparius     Chronic NOEC    
#>  9 7800   7        Lemna        Macrophyte         gibba        Chronic NOEC    
#> 10 7990   28       Bruguiera    Macrophyte         gymnorhiza   Chronic LC50    
#> 11 1360   4        Raphidocelis Microalga          subcapitata  Chronic EC10    
#> 12 4000   4        Chlorolobion Microalga          braunii      Chronic NOEC    
#> 13 1800   2        Brachionus   Micro-invertebrate calyciflorus Chornic NOEC    
#> 14   36.4 5        Paramecium   Micro-organism     trichium     Chronic IC50    
#> 15  492   5        Paramecium   Micro-organism     caudatum     Chronic IC50    
#> 16   20   28       Potamopyrgus Mollusc            antipodarum  Chronic NOEC    
#> 17   50   14       Marisa       Mollusc            cornuarietis Chronic NOEC    
#> 18  200   21       Physa        Mollusc            acuta        Chronic LOEC    
#> 19 1600   NA       Heteromyenia Sponge             sp.          Chronic NOEC    
```
