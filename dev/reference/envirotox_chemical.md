# Chemical Lookup Table for the EnviroTox Datasets

A lookup table mapping chemical names to their original CAS Registry
Numbers for all chemicals present in `envirotox_acute` and
`envirotox_chronic`.

## Usage

``` r
envirotox_chemical
```

## Format

A tibble with 744 rows and 2 columns:

- Chemical:

  Chemical name (chr).

- OriginalCAS:

  Original CAS Registry Number (int).

## Source

<https://envirotoxdatabase.org/>

## Details

This table is a companion to `envirotox_acute` and `envirotox_chronic`.
It is not an SSD-ready dataset but provides the CAS Registry Numbers
needed to join the envirotox datasets to other chemical databases.

Source database: EnviroTox 2.0.0 Connors KA, Beasley A, Barron MG,
Belanger SE, Bonnell M, Brill JL, de Zwart D, Kienzler A, Krailler J,
Otter R, Phillips JL, Embry MR (2019). “Creation of a Curated Aquatic
Toxicology Database: EnviroTox.” *Environmental Toxicology and
Chemistry*, **38**(5), 1062–1073.
[doi:10.1002/etc.4382](https://doi.org/10.1002/etc.4382) . .

See `envirotox_data` for the full list dataset including all three
components.

## References

Connors KA, Beasley A, Barron MG, Belanger SE, Bonnell M, Brill JL, de
Zwart D, Kienzler A, Krailler J, Otter R, Phillips JL, Embry MR (2019).
“Creation of a Curated Aquatic Toxicology Database: EnviroTox.”
*Environmental Toxicology and Chemistry*, **38**(5), 1062–1073.
[doi:10.1002/etc.4382](https://doi.org/10.1002/etc.4382) .

## See also

[envirotox_data](https://open-aims.github.io/ssddata/dev/reference/envirotox_data.md),
[envirotox_acute](https://open-aims.github.io/ssddata/dev/reference/envirotox_acute.md),
[envirotox_chronic](https://open-aims.github.io/ssddata/dev/reference/envirotox_chronic.md)

## Examples

``` r

head(envirotox_chemical)
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
