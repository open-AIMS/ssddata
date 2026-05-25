# Species Sensitivity Data for nitrate_soft_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***nitrate*** in soft freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 14
rows and 9 columns.

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

## Examples

``` r

print(anzg_nitrate_soft_fresh, n=Inf)
#> # A tibble: 14 × 9
#>     Conc Duration Genus        Group     Life_stage Phylum Species Test_endpoint
#>    <dbl> <chr>    <chr>        <chr>     <chr>      <chr>  <chr>   <chr>        
#>  1 247   3        Raphidocelis Microalga Exponenti… Chlor… subcap… Growth       
#>  2   8.6 60       Sphaerium    Mollusc   Juvenile   Mollu… novaez… Mortality    
#>  3   1.4 40       Potamopyrgus Mollusc   Juvenile   Mollu… antipo… Growth length
#>  4   2.2 60       Paranephrops Crustace… Juvenile   Arthr… planif… Growth length
#>  5   6.3 126      Coregonus    Fish      Embryo al… Chord… clupea… Development  
#>  6   2   40       Galaxias     Fish      Juvenile   Chord… macula… Mortality    
#>  7  22.5 21       Gobiomorphus Fish      Juvenile   Chord… cotidi… Growth weight
#>  8   2.2 30       Oncorhynchus Fish      Fry        Chord… mykiss  Mortality    
#>  9   2.3 30       Oncorhynchus Fish      Fry        Chord… tshawy… Mortality    
#> 10  52   7        Pimephales   Fish      Embryo la… Chord… promel… Growth weight
#> 11   4.5 30       Salmo        Fish      Fry        Chord… clarkii Mortality    
#> 12   1.6 146      Salvelinus   Fish      Embryo al… Chord… namayc… Growth weight
#> 13 117   16       Rana         Amphibian Embryo la… Chord… aurora  Growth weight
#> 14  24.8 10       Xenopus      Amphibian Tadpole    Chord… laevis  Growth weight
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
