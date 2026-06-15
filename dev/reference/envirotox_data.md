# Species Sensitivity Data from the EnviroTox Database

A named list containing Species Sensitivity Distribution (SSD) datasets
derived from the EnviroTox database 2.0.0 Connors KA, Beasley A, Barron
MG, Belanger SE, Bonnell M, Brill JL, de Zwart D, Kienzler A, Krailler
J, Otter R, Phillips JL, Embry MR (2019). “Creation of a Curated Aquatic
Toxicology Database: EnviroTox.” *Environmental Toxicology and
Chemistry*, **38**(5), 1062–1073.
[doi:10.1002/etc.4382](https://doi.org/10.1002/etc.4382) . .

## Usage

``` r
envirotox_data
```

## Format

A named list with three elements:

- acute:

  A tibble with 14,949 rows and 6 columns of acute toxicity records
  (EC50/LC50). See
  [envirotox_acute](https://open-aims.github.io/ssddata/dev/reference/envirotox_acute.md)
  for full column descriptions.

- chronic:

  A tibble with 1,721 rows and 5 columns of chronic toxicity records
  (NOEC/NOEL). See
  [envirotox_chronic](https://open-aims.github.io/ssddata/dev/reference/envirotox_chronic.md)
  for full column descriptions.

- chemical:

  A tibble with 744 rows and 2 columns mapping chemical names to CAS
  Registry Numbers. See
  [envirotox_chemical](https://open-aims.github.io/ssddata/dev/reference/envirotox_chemical.md)
  for full column descriptions.

## Source

<https://envirotoxdatabase.org/>

## Details

The `envirotox` data contains SSD datasets from the [EnviroTox
database](https://envirotoxdatabase.org/) 2.0.0 (Connors et al. 2019).
The datasets are provided for assessing general patterns in SSD data and
for testing code. The datasets should not be used to draw any
conclusions about the toxicity of individual chemicals.

The data are aggregated following the code provided by Yanagihara M,
Hiki K, Iwasaki Y (2024). “Which distribution to choose for deriving a
species sensitivity distribution? Implications from analysis of acute
and chronic ecotoxicity data.” *Ecotoxicology and Environmental Safety*,
**278**, 116379.
[doi:10.1016/j.ecoenv.2024.116379](https://doi.org/10.1016/j.ecoenv.2024.116379)
. with three exceptions: the datasets also include chemicals with (1) a
bimodality coefficient \> 0.555, (2) between six and nine species, and
(3) two trophic groups.

The logical column `Yanagihara24` in `$acute` and `$chronic` indicates
which chemicals meet the original criteria of Yanagihara et al. (2024):
bimodality coefficient \<= 0.555, at least 10 species, and at least
three trophic groups.

The logical column `Iwasaki25` in `$acute` indicates which chemicals
were included in the analysis of Iwasaki Y, Yanagihara M (2025).
“Comparison of model-averaging and single-distribution approaches to
estimating species sensitivity distributions and hazardous
concentrations for 5\\ of species.” *Environmental Toxicology and
Chemistry*, **44**(3), 834–840.
[doi:10.1093/etojnl/vgae060](https://doi.org/10.1093/etojnl/vgae060) . :
more than 50 species and at least three trophic groups, excluding
certain metals.

The full reproducible workflow to generate the three component datasets
is in `data-raw/envirotox/DATASET.R`.

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

[envirotox_acute](https://open-aims.github.io/ssddata/dev/reference/envirotox_acute.md),
[envirotox_chronic](https://open-aims.github.io/ssddata/dev/reference/envirotox_chronic.md),
[envirotox_chemical](https://open-aims.github.io/ssddata/dev/reference/envirotox_chemical.md)

## Examples

``` r

data("envirotox_data")
names(envirotox_data)
#> [1] "acute"    "chronic"  "chemical"
head(envirotox_data$acute)
#> # A tibble: 6 × 7
#>   Chemical              Conc Species         Group Yanagihara24 Iwasaki25 Medium
#>   <chr>                <dbl> <chr>           <chr> <lgl>        <lgl>     <chr> 
#> 1 (+/-)-cis-Permethrin  0.36 Culex quinquef… Inve… FALSE        FALSE     Unkno…
#> 2 (+/-)-cis-Permethrin  5    Cyprinodon mac… Fish  FALSE        FALSE     Unkno…
#> 3 (+/-)-cis-Permethrin 13    Gambusia affin… Fish  FALSE        FALSE     Unkno…
#> 4 (+/-)-cis-Permethrin 13.2  Oncorhynchus m… Fish  FALSE        FALSE     Unkno…
#> 5 (+/-)-cis-Permethrin  5.6  Oreochromis mo… Fish  FALSE        FALSE     Unkno…
#> 6 (+/-)-cis-Permethrin 38    Oryzias latipes Fish  FALSE        FALSE     Unkno…
head(envirotox_data$chronic)
#> # A tibble: 6 × 6
#>   Chemical                 Conc Species                Group Yanagihara24 Medium
#>   <chr>                   <dbl> <chr>                  <chr> <lgl>        <chr> 
#> 1 1,2,4-Trichlorobenzene   85.4 Americamysis bahia     Inve… FALSE        Unkno…
#> 2 1,2,4-Trichlorobenzene  264.  Daphnia magna          Inve… FALSE        Unkno…
#> 3 1,2,4-Trichlorobenzene  410.  Oncorhynchus mykiss    Fish  FALSE        Unkno…
#> 4 1,2,4-Trichlorobenzene  260   Oryzias latipes        Fish  FALSE        Unkno…
#> 5 1,2,4-Trichlorobenzene  417.  Pimephales promelas    Fish  FALSE        Unkno…
#> 6 1,2,4-Trichlorobenzene 1483.  Raphidocelis subcapit… Algae FALSE        Unkno…
head(envirotox_data$chemical)
#> # A tibble: 6 × 2
#>   Chemical                  OriginalCAS
#>   <chr>                           <int>
#> 1 (+/-)-cis-Permethrin         61949766
#> 2 (2R,6S)-Fenpropimorph        67564914
#> 3 1,1,1-Trichloroethane           71556
#> 4 1,1,2,2-Tetrachloroethane       79345
#> 5 1,1,2-Trichloroethane           79005
#> 6 1,1-Dichloroethylene            75354
```
