# ssddata

`ssddata` is an R package of Species Sensitivity Distribution (SSD)
benchmark datasets that can serve as a reference standard for testing
and evaluation of SSD methodologies.

The package includes a range of data sets sourced from the Canadian
Council of Ministers of the Environment (ccme), the Australian Institute
of Marine Science (aims), the Commonwealth Scientific and Industrial
Research Organisation (csiro), and the Australian and New Zealand water
water quality guideline website (angz, all datasets with a published
date later than 2000), as well as anonymous datasets supplied by various
parties (anon). The source of each dataset are indicated using a pre-fix
in the data name (e.g. ccme, aims, etc), with the actual chemical name
following (e.g. ccme_boron).

The package also includes wqbench_data, a large data set from the US EPA
ECOTOX database, cleaned and standardized by the
[`wqbench`](https://github.com/bcgov/wqbench/) package; envirotox_data,
a dataset based on the [envirotox
database](https://envirotoxdatabase.org/); and anztox_data, based on the
ANZTOX database historically hoasted on the SETAC AU website.

Please see the relevant
[reference](https://open-aims.github.io/ssddata/reference/index.html)
page more info information on each dataset.

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
