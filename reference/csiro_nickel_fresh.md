# Species Sensitivity Data for nickel_fresh

Species Sensitivity Data provided by the Commonwealth Scientific and
Industrial Research Organisation of Australia for ***nickel*** in
freshwater.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 31
rows and 6 columns.

## Details

These data were sourced from: Stauber J, Golding L, Peters A, Merrington
G, Adams M, Binet M, Batley G, Gissi F, Mcknight K, Garman E, Middleton
E, Gadd J, Schlekat C (2021). “Environmental Toxicology Application of
Bioavailability Models to Derive Chronic Guideline Values for Nickel in
Freshwaters of Australia and New Zealand.” *Environmental Toxicology and
Chemistry*, **40**(1), 100–112.
[doi:10.1002/etc.4885](https://doi.org/10.1002/etc.4885) .
<https://setac.onlinelibrary.wiley.com/doi/abs/10.1002/etc.4885>.

The columns are as follows:

- Conc:

  The chemical concentration (dbl).

- Domain:

  Tropical, temperate or other filter (chr).

- Group:

  Taxonomic grouping information (chr).

- Notes:

  Other notes (chr).

- Species:

  The species names name (chr).

- Test_endpoint:

  Endpoint statistic, EC10, NEC etc (chr).

## Examples

``` r

print(csiro_nickel_fresh, n=Inf)
#> # A tibble: 31 × 6
#>      Conc Domain    Group                   Notes          Species Test_endpoint
#>     <dbl> <chr>     <chr>                   <chr>          <chr>   <chr>        
#>  1   1.4  temperate Mollusc (snail)         none           Lymnae… EC10         
#>  2   1.52 temperate Crustacean (water flea) geomean        Ceriod… EC10/LOEC    
#>  3   3.63 temperate Crustacean (water flea) geomean        Alona … LC50         
#>  4   8.49 temperate Crustacean (water flea) geomean        Ceriod… EC10         
#>  5  11.0  temperate Crustacean (water flea) geomean        Peraca… EC10         
#>  6  12    temperate Crustacean (water flea) geomean        Daphni… EC10         
#>  7  13.9  temperate Crustacean (water flea) geomean        Ceriod… EC10         
#>  8  14.4  temperate Crustacean (water flea) geomean        Simoce… EC10         
#>  9  17.6  temperate Crustacean (water flea) geomean        Simoce… EC10         
#> 10  36    temperate Microalga (diatom)      none           Navicu… EC10         
#> 11  39.0  temperate Microalga (green alga)  geomean        Pseudo… EC10         
#> 12  40.9  temperate Crustacean (water flea) geomean        Daphni… EC10         
#> 13  62    temperate Fish                    lowest endpoi… Salmo … NOEL         
#> 14 213.   temperate Fish                    geomean        Pimeph… NOEC         
#> 15 306.   temperate Insect (chironomid)     none           Chiron… EC10         
#> 16   3.5  tropical  Macrophyte (duckweed)   none           Lemna … EC10         
#> 17   7.95 tropical  Microalga (green alga)  geomean        Pseudo… EC10         
#> 18   8.2  tropical  Macrophyte (duckweed)   none           Lemna … EC10         
#> 19  11.4  tropical  Microalga (green alga)  geomean        Scened… EC10         
#> 20  12.6  tropical  Microalga (green alga)  geomean        Desmod… EC10         
#> 21  19.3  tropical  Cnidarian (hydra)       geomean        Hydra … EC10         
#> 22  22.1  tropical  Microalga (green alga)  geomean        Sperma… EC10         
#> 23  23.0  tropical  Microalga (green alga)  geomean        Pedias… EC10         
#> 24  28.2  tropical  Microalga (green alga)  geomean        Ankist… EC10         
#> 25  30    tropical  Fish                    none           Melano… EC10         
#> 26  34.5  tropical  Microalga (green alga)  geomean        Chlamy… EC10         
#> 27  61.2  tropical  Microalga (green alga)  geomean        Coelas… EC10         
#> 28  76.5  tropical  Mollusc (snail)         geomean        Chlore… EC10         
#> 29  79.0  tropical  Crustacean (water flea) geomean        Desmod… EC10         
#> 30 104.   tropical  Crustacean (water flea) none           Brachi… EC10         
#> 31 148    tropical  Crustacean (water flea) none           Chlore… EC10         
```
