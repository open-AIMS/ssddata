# Acute Species Sensitivity Data from the EnviroTox Database

Acute toxicity records (EC50/LC50) from the EnviroTox database 2.0.0
Connors KA, Beasley A, Barron MG, Belanger SE, Bonnell M, Brill JL, de
Zwart D, Kienzler A, Krailler J, Otter R, Phillips JL, Embry MR (2019).
“Creation of a Curated Aquatic Toxicology Database: EnviroTox.”
*Environmental Toxicology and Chemistry*, **38**(5), 1062–1073.
[doi:10.1002/etc.4382](https://doi.org/10.1002/etc.4382) . , aggregated
to one geometric mean concentration per species per chemical.

## Usage

``` r
envirotox_acute
```

## Format

A tibble with 14,949 rows and 6 columns:

- Chemical:

  Chemical name (chr).

- Conc:

  Geometric mean concentration in micrograms per litre (dbl).

- Species:

  Latin species name (chr).

- Group:

  Taxonomic group of species (chr).

- Yanagihara24:

  Whether the chemical meets the criteria of Yanagihara et al. (2024)
  (lgl).

- Iwasaki25:

  Whether the chemical was included in Iwasaki et al. (2025) (lgl).

## Source

<https://envirotoxdatabase.org/>

## Details

The data are aggregated following the code provided by Yanagihara M,
Hiki K, Iwasaki Y (2024). “Which distribution to choose for deriving a
species sensitivity distribution? Implications from analysis of acute
and chronic ecotoxicity data.” *Ecotoxicology and Environmental Safety*,
**278**, 116379.
[doi:10.1016/j.ecoenv.2024.116379](https://doi.org/10.1016/j.ecoenv.2024.116379)
. with three exceptions: the dataset also includes chemicals with (1) a
bimodality coefficient \> 0.555, (2) between six and nine species, and
(3) two trophic groups.

The logical column `Yanagihara24` indicates whether a chemical meets the
criteria used by Yanagihara et al. (2024): bimodality coefficient \<=
0.555, at least 10 species, and at least three trophic groups.

The logical column `Iwasaki25` indicates whether a chemical was included
in the analysis by Iwasaki Y, Yanagihara M (2025). “Comparison of
model-averaging and single-distribution approaches to estimating species
sensitivity distributions and hazardous concentrations for 5\\ of
species.” *Environmental Toxicology and Chemistry*, **44**(3), 834–840.
[doi:10.1093/etojnl/vgae060](https://doi.org/10.1093/etojnl/vgae060) . :
more than 50 species and at least three trophic groups, excluding
certain metals.

See `envirotox_chemical` for the corresponding CAS Registry Numbers, and
`envirotox_data` for the complete list dataset.

## References

Connors KA, Beasley A, Barron MG, Belanger SE, Bonnell M, Brill JL, de
Zwart D, Kienzler A, Krailler J, Otter R, Phillips JL, Embry MR (2019).
“Creation of a Curated Aquatic Toxicology Database: EnviroTox.”
*Environmental Toxicology and Chemistry*, **38**(5), 1062–1073.
[doi:10.1002/etc.4382](https://doi.org/10.1002/etc.4382) .

Yanagihara M, Hiki K, Iwasaki Y (2024). “Which distribution to choose
for deriving a species sensitivity distribution? Implications from
analysis of acute and chronic ecotoxicity data.” *Ecotoxicology and
Environmental Safety*, **278**, 116379.
[doi:10.1016/j.ecoenv.2024.116379](https://doi.org/10.1016/j.ecoenv.2024.116379)
.

Iwasaki Y, Yanagihara M (2025). “Comparison of model-averaging and
single-distribution approaches to estimating species sensitivity
distributions and hazardous concentrations for 5\\ of species.”
*Environmental Toxicology and Chemistry*, **44**(3), 834–840.
[doi:10.1093/etojnl/vgae060](https://doi.org/10.1093/etojnl/vgae060) .

## See also

[envirotox_data](https://open-aims.github.io/ssddata/dev/reference/envirotox_data.md),
[envirotox_chronic](https://open-aims.github.io/ssddata/dev/reference/envirotox_chronic.md),
[envirotox_chemical](https://open-aims.github.io/ssddata/dev/reference/envirotox_chemical.md)

## Examples

``` r

head(envirotox_acute)
#> # A tibble: 6 × 7
#>   Chemical              Conc Species         Group Yanagihara24 Iwasaki25 Medium
#>   <chr>                <dbl> <chr>           <chr> <lgl>        <lgl>     <chr> 
#> 1 (+/-)-cis-Permethrin  0.36 Culex quinquef… Inve… FALSE        FALSE     Unkno…
#> 2 (+/-)-cis-Permethrin  5    Cyprinodon mac… Fish  FALSE        FALSE     Unkno…
#> 3 (+/-)-cis-Permethrin 13    Gambusia affin… Fish  FALSE        FALSE     Unkno…
#> 4 (+/-)-cis-Permethrin 13.2  Oncorhynchus m… Fish  FALSE        FALSE     Unkno…
#> 5 (+/-)-cis-Permethrin  5.6  Oreochromis mo… Fish  FALSE        FALSE     Unkno…
#> 6 (+/-)-cis-Permethrin 38    Oryzias latipes Fish  FALSE        FALSE     Unkno…
```
