# Species Sensitivity Distribution Fit Data

Species Sensitivity Distribution Fit Data

## Usage

``` r
ssd_fits
```

## Format

A tibble with 13 columns.

- Dataset:

  The name of the dataset in the ssddata package (chr).

- Filter:

  Any filtering applied to the data (chr).

- Software:

  The name of the software (chr).

- Version:

  The version of the software (chr).

- Distribution:

  The name of the distribution (chr)

- PC:

  The percent of the community protected (int).

- Estimate:

  The estimated concentration, in the units given by Units (dbl).

- SE:

  The standard error of the estimated concentration, in the units given
  by Units (dbl).

- Lower:

  The lower 95% CI of the estimated concentration, in the units given by
  Units (dbl).

- Upper:

  The upper 95% CI of the estimated concentration, in the units given by
  Units (dbl).

- Reference:

  The source of the fit (chr).

- Notes:

  Additional information on the fitting process (chr).

- Units:

  The concentration units of Estimate, SE, Lower and Upper. Each fit is
  recorded on the scale of the ssddata dataset it was fitted to, so this
  is not uniform: one of "ug/L", "mg/L" or "ng/L" (for example
  ccme_boron and ccme_chloride are mg/L, ccme_endosulfan is ng/L), and
  NA for the anon\_\* datasets, whose concentrations are deliberately
  unitless (chr).

## Examples

``` r
head(ssd_fits)
#> # A tibble: 6 × 13
#>   Dataset  Filter Software Version Distribution    PC Estimate    SE Lower Upper
#>   <chr>    <chr>  <chr>    <chr>   <chr>        <dbl>    <dbl> <dbl> <dbl> <dbl>
#> 1 aims_al… Domai… Burrlioz v2.0    BurrIII         80    277     NA  62    1250 
#> 2 aims_al… Domai… ssdtools 0.3.4   averaged        80    251.   371. 48.6  1408.
#> 3 aims_al… Domai… Burrlioz v2.0    BurrIII         90     78     NA  31     670 
#> 4 aims_al… Domai… ssdtools 0.3.4   averaged        90     84.9  207. 13.8   743.
#> 5 aims_al… Domai… Burrlioz v2.0    BurrIII         95     22     NA   6.3   388 
#> 6 aims_al… Domai… ssdtools 0.3.4   averaged        95     34.3  129.  4.65  428.
#> # ℹ 3 more variables: Reference <chr>, Notes <chr>, Units <chr>
```
