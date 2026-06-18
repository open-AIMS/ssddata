
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ssddata

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#maturing)
[![R-CMD-check](https://github.com/open-AIMS/ssddata/workflows/R-CMD-check/badge.svg?branch=dev)](https://github.com/open-AIMS/ssddata/actions)
[![R-CMD-check](https://github.com/open-AIMS/ssddata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/open-AIMS/ssddata/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

`ssddata` is an R package of Species Sensitivity Distribution (SSD)
benchmark datasets that can serve as a reference standard for testing
and evaluation of SSD methodologies.

The package includes a range of data sets sourced from the Canadian
Council of Ministers of the Environment
([ccme_data](https://open-aims.github.io/ssddata/dev/reference/ccme_data.html)),
the Australian Institute of Marine Science
([aims_data](https://open-aims.github.io/ssddata/dev/reference/aims_data.html)),
the Commonwealth Scientific and Industrial Research Organisation
([csiro_data](https://open-aims.github.io/ssddata/dev/reference/csiro_data.html)),
and the Australian and New Zealand water quality guideline website
([anzg_data](https://open-aims.github.io/ssddata/dev/reference/anzg_data.html),
all datasets with a published date later than 2000), as well as
anonymous datasets supplied by various parties (anon). The source of
each dataset are indicated using a pre-fix in the data name (e.g. ccme,
aims, etc), with the actual chemical name following (e.g. ccme_boron).

The package also includes
[wqbench_data](https://open-aims.github.io/ssddata/dev/reference/wqbench_data.html),
a large data set from the US EPA ECOTOX database, cleaned and
standardized by the [`wqbench`](https://github.com/bcgov/wqbench/)
package;
[envirotox_data](https://open-aims.github.io/ssddata/dev/reference/envirotox_data.html),
a dataset based on the [envirotox
database](https://envirotoxdatabase.org/); and
[anztox_data](https://open-aims.github.io/ssddata/dev/reference/anztox_data.html),
based on the ANZTOX database historically hosted on the SETAC AU
website.

Please see the relevant
[reference](https://open-aims.github.io/ssddata/dev/reference/index.html)
page for more information on each dataset.

You can browse the [source code](https://github.com/open-AIMS/ssddata)
on github.

Top report an error, request features or data additions please post on
the github [issues](https://github.com/open-AIMS/ssddata/issues) page.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("open-AIMS/ssddata")
```
