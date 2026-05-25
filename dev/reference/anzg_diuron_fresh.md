# Species Sensitivity Data for diuron_fresh

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***diuron*** in freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 16
rows and 8 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2025). “Toxicant default guideline
values for aquatic ecosystem protection: Diuron in freshwater.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/sites/default/files/documents/diuron-fresh-dgvs-technical-brief.pdf>.

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

print(anzg_diuron_fresh, n=Inf)
#> # A tibble: 16 × 8
#>       Conc Duration Genus         Group         Life_stage Species Test_endpoint
#>      <dbl> <chr>    <chr>         <chr>         <chr>      <chr>   <chr>        
#>  1   10.3  4        Achnanthidium Diatom        Planktoni… minuti… Growth rate  
#>  2  315    4        Craticula     Diatom        Planktoni… accomo… Growth rate  
#>  3    4.9  4        Cyclotella    Diatom        Planktoni… menegh… Growth rate  
#>  4   10.4  4        Encyonema     Diatom        Planktoni… silesi… Growth rate  
#>  5 1886    4        Eolimna       Diatom        Planktoni… minima  Growth rate  
#>  6    0.54 4        Fragilaria    Diatom        Planktoni… capuci… Growth rate  
#>  7    7.43 4        Fragilaria    Diatom        Planktoni… rumpens Growth rate  
#>  8   17.6  4        Fragilaria    Diatom        Planktoni… ulna    Growth rate  
#>  9  365    4        Gomphonema    Diatom        Planktoni… parvul… Growth rate  
#> 10   86.5  4        Mayamaea      Diatom        Planktoni… fossal… Growth rate  
#> 11    9.17 3        Navicula      Diatom        Not stated pellic… Biomass yiel…
#> 12  199    4        Nitzschia     Diatom        Planktoni… palea   Growth rate  
#> 13    2.3  3        Scenedesmus   Green alga    Not stated subspi… Biomass yiel…
#> 14    0.44 4        Selenastrum   Green alga    Not stated capric… Biomass yiel…
#> 15    2.49 7        Lemna         Macrophyte    Not stated gibba   Frond number…
#> 16    1.14 3        Synechococcus Cyanobacteria Not stated leopol… Biomass yiel…
#> # ℹ 1 more variable: Toxicity_measure <chr>
```
