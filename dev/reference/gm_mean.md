# Calculate geometric mean

Calculates the geometric mean of a numeric vector

## Usage

``` r
gm_mean(x, na.rm = FALSE, zero.propagate = TRUE)
```

## Arguments

- x:

  A numeric vector

- na.rm:

  A flag specifying whether to remove missing values.

- zero.propagate:

  A flag specifying whether to propagate zero values.

## Value

A number of the geometric mean.

## Examples

``` r
gm_mean(c(3, 66, 22, 17))
#> [1] 16.49621
```
