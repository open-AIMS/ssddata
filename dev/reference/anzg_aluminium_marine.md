# Species Sensitivity Data for aluminium_marine

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***aluminium*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 18
rows and 6 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2025). “Toxicant default guideline
values for aquatic ecosystem protection: Aluminium in marine water.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/aluminium-marine-dgvs-technical-brief.pdf>.

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

print(anzg_aluminium_marine, n=Inf)
#> # A tibble: 18 × 6
#>     Conc Duration Genus         Group      Species            Toxicity_measure
#>    <dbl> <chr>    <chr>         <chr>      <chr>              <chr>           
#>  1    27 72       Ceratoneis    Diatom     closterium         Chronic IC10    
#>  2   610 72       Minutocellus  Diatom     polymorphus        Chronic IC10    
#>  3  2100 72       Phaeodactylum Diatom     tricornutum        Chronic IC10    
#>  4  3200 72       Tetraselmis   Microalga  sp.                Chronic IC10    
#>  5  1400 72       Dunaliella    Microalga  tertiolecta        Chronic IC10    
#>  6  9800 72       Hormosira     Brown alga banksii            Chronic NOEC    
#>  7  6800 72       Ecklonia      Brown alga radiata            Chronic IC10    
#>  8 28000 72       Heliocidaris  Echinoderm tuberculata        Chronic NOEC    
#>  9    32 72       Paracentrotus Echinoderm lividus            Chronic NOEC    
#> 10   250 72       Mytilus       Mollusc    edulis plannulatus Chronic EC10    
#> 11   410 72       Saccostrea    Mollusc    echinata           Chronic EC10    
#> 12   100 72       Saccostrea    Mollusc    glomerata          Chronic NOEC    
#> 13   640 72       Tisochrysis   Microalga  lutea              Chronic IC10    
#> 14  1300 18       Acropora      Cnidarian  tenuis             Chronic EC10    
#> 15   817 336      Exaiptasia    Cnidarian  diaphana           Chronic EC10    
#> 16   115 96       Nassarius     Mollusc    dorsatus           Chronic EC10    
#> 17   416 96       Amphibalanus  Crustacean amphitrite         Chronic EC10    
#> 18   312 72       Coenobita     Crustacean variabilis         Chronic EC10    
```
