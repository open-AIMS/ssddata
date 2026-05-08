# Anonymous Species Sensitivity Data

Species Sensitivity Data from Anonymous sources

## Usage

``` r
anon_data
```

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 73
rows and 2 columns.

## Details

Additional information on each of the chemicals may be available from
their primary source, at:

- a:

  DAWE (2021). “Unpublished data, anonymous information supplied by
  Department of Agriculture Water and the Environment, Australia.” April
  20.

- c:

  DAWE (2021). “Unpublished data, anonymous information supplied by
  Department of Agriculture Water and the Environment, Australia.” April
  20.

- d:

  DAWE (2021). “Unpublished data, anonymous information supplied by
  Department of Agriculture Water and the Environment, Australia.” April
  20.

- b:

  DAWE (2021). “Unpublished data, anonymous information supplied by
  Department of Agriculture Water and the Environment, Australia.” April
  20.

- e:

  Fox DR, van Dam RA, Fisher R, Batley GE, Tillmanns AR, Thorley J,
  Schwarz CJ, Spry DJ, McTavish K (2021). “Recent developments in
  Species Sensitivity Distribution Modeling.” *Environmental Toxicology
  and Chemistry*, **40**(2), 293–308.
  [doi:10.1002/etc.4925](https://doi.org/10.1002/etc.4925) .
  <https://setac.onlinelibrary.wiley.com/doi/abs/10.1002/etc.4925>.

&nbsp;

- Chemical:

  The chemical (chr), in this case an anonymous unique identifier.

- Conc:

  The chemical concentration (dbl).

## Examples

``` r

head(anon_data)
#> # A tibble: 6 × 2
#>   Chemical  Conc
#>   <chr>    <dbl>
#> 1 a          500
#> 2 a         1800
#> 3 a          120
#> 4 a          490
#> 5 a            4
#> 6 a           16
```
