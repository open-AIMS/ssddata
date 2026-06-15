# Chronic Species Sensitivity Data from the EnviroTox Database

Chronic toxicity records (NOEC/NOEL) from the EnviroTox database 2.0.0
Connors KA, Beasley A, Barron MG, Belanger SE, Bonnell M, Brill JL, de
Zwart D, Kienzler A, Krailler J, Otter R, Phillips JL, Embry MR (2019).
“Creation of a Curated Aquatic Toxicology Database: EnviroTox.”
*Environmental Toxicology and Chemistry*, **38**(5), 1062–1073.
[doi:10.1002/etc.4382](https://doi.org/10.1002/etc.4382) . , aggregated
to one geometric mean concentration per species per chemical.

## Usage

``` r
envirotox_chronic
```

## Format

A tibble with 1,721 rows and 5 columns:

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

## See also

[envirotox_data](https://open-aims.github.io/ssddata/dev/reference/envirotox_data.md),
[envirotox_acute](https://open-aims.github.io/ssddata/dev/reference/envirotox_acute.md),
[envirotox_chemical](https://open-aims.github.io/ssddata/dev/reference/envirotox_chemical.md)

## Examples

``` r

head(envirotox_chronic)
#> # A tibble: 6 × 6
#>   Chemical                 Conc Species                Group Yanagihara24 Medium
#>   <chr>                   <dbl> <chr>                  <chr> <lgl>        <chr> 
#> 1 1,2,4-Trichlorobenzene   85.4 Americamysis bahia     Inve… FALSE        Unkno…
#> 2 1,2,4-Trichlorobenzene  264.  Daphnia magna          Inve… FALSE        Unkno…
#> 3 1,2,4-Trichlorobenzene  410.  Oncorhynchus mykiss    Fish  FALSE        Unkno…
#> 4 1,2,4-Trichlorobenzene  260   Oryzias latipes        Fish  FALSE        Unkno…
#> 5 1,2,4-Trichlorobenzene  417.  Pimephales promelas    Fish  FALSE        Unkno…
#> 6 1,2,4-Trichlorobenzene 1483.  Raphidocelis subcapit… Algae FALSE        Unkno…
```
