# Data Sources and Attribution

The `ssddata` package includes datasets from multiple sources. This document outlines the attribution and licensing terms for each source.

## EnviroTox Database

**Source**: [EnviroTox Database & Tools](https://envirotoxdatabase.org/)

**Copyright**: (c) 2019 Health and Environmental Sciences Institute (HESI). All rights reserved.

**License**: The EnviroTox Database is **not** open source. No redistribution license is granted. 

**Terms of Use**: Only citation is requested. Any use of the `envirotox_acute`, `envirotox_chronic`, `envirotox_chemical`, or `envirotox_data` datasets must cite the following reference:

Connors, K.A., Beasley, A., Barron, M.G., Belanger, S.E., Bonnell, M., Brill, J.L., de Zwart, D., Kienzler, A., Krailler, J., Otter, R., Phillips, J.L., & Embry, M.R. (2019). Creation of a Curated Aquatic Toxicology Database: EnviroTox. *Environmental Toxicology and Chemistry*, 38(5), 1062–1073. https://doi.org/10.1002/etc.4382

For more information about the EnviroTox Database terms of use, see: https://envirotoxdatabase.org/index.php/about

## Other Data Sources

### CCME Datasets

**Source**: Canadian Council of Ministers of the Environment

### AIMS Datasets

**Source**: Australian Institute of Marine Science

### CSIRO Datasets

**Source**: Commonwealth Scientific and Industrial Research Organisation

### ANZG Datasets

**Source**: Australian and New Zealand water quality guideline website

### ANZTOX Data

**Source**: ANZTOX database, originally served by the Queensland government and then by SETAC, now maintained locally.

### Wqbench Data

**Source**: US EPA ECOTOX database, cleaned and standardized by the [`wqbench`](https://github.com/bcgov/wqbench/) package.

### Anonymous Datasets

**Source**: Anonymous datasets supplied by various parties.

## Package License

The `ssddata` R package itself is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0). This license covers the package code and documentation, but does not supersede the licensing terms of the individual datasets contained within the package. Users must comply with the licensing terms of each individual dataset they use.

## Citation

When using datasets from the `ssddata` package, please cite both the package and the original data source(s):

```r
citation("ssddata")
```

For EnviroTox data specifically, please cite:
- Connors et al. (2019) as detailed above
- The ssddata package itself
