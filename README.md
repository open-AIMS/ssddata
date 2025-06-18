
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ssddata

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/open-AIMS/ssddata/workflows/R-CMD-check/badge.svg)](https://github.com/open-AIMS/ssddata/actions)
[![CRAN
status](https://www.r-pkg.org/badges/version/ssddata)](https://CRAN.R-project.org/package=ssddata)
<!-- badges: end -->

`ssddata` is an R package of Species Sensitivity Distribution (SSD)
benchmark datasets that can serve as a reference standard for testing
and evaluation.

The package includes a range of data sets sourced from the Canadian
Council of Ministers of the Environment (ccme), the Australian Institute
of Marine Science (aims), the CSIRO (csiro), and the Australian and New
Zealand water water quality guideline website (angz), as well as
anonymous datasets supplied by the Department of Agriculture Water and
Environment and other parties (anon). The source of each dataset are
indicated using a pre-fix in the data name (e.g. ccme, aims, etc), with
the actual chemical name following (e.g. ccme\_boron).

Please see the relevant
[reference](https://open-aims.github.io/ssddata/reference/index.html)
page more info information on each dataset.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("open-AIMS/ssddata")
```
