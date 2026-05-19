# ANZTOX Species Sensitivity Data

A curated dataset of species-level ecotoxicity data compiled from the
ANZTOX database and harmonised for Species Sensitivity Distribution
(SSD) analysis. Data encompass two source datasets: toxicityvalue2000
(ANZECC & ARMCANZ 2000 guidelines, 17,755 records) and toxicityvalue2016
(post-2000 ANZG revision data, 2,794 records).

## Usage

``` r
anztox_data
```

## Format

A tibble with one row per chemical × mediatype combination and columns:

- casnumber_grouped:

  Grouped CAS number (character).

- chemicalname_grouped:

  Grouped chemical name (character).

- mediatype:

  "Freshwater" or "Marine" (character).

- data:

  List-column of nested tibbles containing species-level toxicity data.

## Details

These data were sourced from the ANZTOX database, originally served by
SETAC and now maintained locally. The dataset has been processed and
harmonised following the principles documented in ANZECC & ARMCANZ
(2000) and Warne et al. (2025).

The data cleaning and SSD eligibility workflow is fully documented in
the accompanying vignette:
`vignette("ANZTOX-data-processing", package = "ssddata")`

In brief:

1.  **Harmonisation**: The 2000 and 2016 datasets—which differ in
    structure and endpoint vocabulary—are de-normalised, cleaned, and
    combined into a single table. Chemical variants and salts are mapped
    to parent compounds via a curated CAS parent lookup. Endpoint labels
    from 2016 are mapped to 2000 effect codes.

2.  **Test type priority**: Within each species × chemical × endpoint
    group, chronic data are preferred over subchronic, and subchronic
    over acute.

3.  **Acute-to-chronic conversion**: Where only acute data are available
    for a species, acute LC/EC/IC50 values are divided by a default ACR
    of 10 (Warne et al. 2025, Section 3.4.2.2) to obtain chronic
    negligible-effect equivalents before SSD fitting.

4.  **Aggregation**: Concentration values for the same species ×
    endpoint are geometric-mean averaged. The most sensitive endpoint
    per species is retained.

5.  **Eligibility threshold**: Only chemical × media combinations with ≥
    5 species from ≥ 4 distinct major taxonomic groups are retained.
    These are then nested into a list-column ready for SSD fitting or
    related functions.

The columns are as follows:

- casnumber_grouped:

  The grouped chemical CAS number, mapped to parent compound where
  applicable (chr).

- chemicalname_grouped:

  The grouped chemical name, mapped to parent compound name where
  applicable (chr).

- mediatype:

  Water type: "Freshwater" or "Marine" (chr).

- data:

  A list-column containing a tibble of species-level rows for that
  chemical × media combination. Each row represents a single species and
  contains columns: `scientificname`, `commonname_species`,
  `majorgroup`, `minorgroup`, `endpoint`, `endpoint_concentration`
  (geometric mean concentration in µg/L or mg/L, depending on the
  chemical), `testtype` (Chronic or Acute), `source_datasets`
  (comma-separated source: "2000", "2016", or both), and
  `n_acute_converted` (count of acute records that contributed to the
  geometric mean after ACR conversion).

## Examples

``` r

print(anztox_data)
#> # A tibble: 174 × 4
#>    casnumber_grouped chemicalname_grouped  mediatype  data             
#>    <chr>             <chr>                 <chr>      <list>           
#>  1 60515             Dimethoate            Freshwater <tibble [30 × 9]>
#>  2 79005             1,1,2-Trichloroethane Freshwater <tibble [19 × 9]>
#>  3 79005             1,1,2-Trichloroethane Marine     <tibble [17 × 9]>
#>  4 58899             Lindane               Freshwater <tibble [71 × 9]>
#>  5 2921882           Chlorpyrifos          Freshwater <tibble [53 × 9]>
#>  6 2921882           Chlorpyrifos          Marine     <tibble [29 × 9]>
#>  7 309002            Aldrin                Freshwater <tibble [41 × 9]>
#>  8 12789036          Chlordane             Freshwater <tibble [38 × 9]>
#>  9 60571             Dieldrin              Freshwater <tibble [17 × 9]>
#> 10 115297            Endosulfan            Freshwater <tibble [74 × 9]>
#> # ℹ 164 more rows

# Nest structure: each row contains species data ready for ssdtools
head(anztox_data$data[[1]])
#> # A tibble: 6 × 9
#>   scientificname      commonname_species majorgroup minorgroup endpoint testtype
#>   <chr>               <chr>              <chr>      <chr>      <chr>    <chr>   
#> 1 Daphnia magna       Water flea         Crustacea  Cladoceron GRO      Chronic 
#> 2 Brachydanio rerio   Zebra danio, zebr… Osteichth… Cyprinidae MORT     Chronic 
#> 3 Oncorhynchus mykiss Rainbow trout      Osteichth… Salmonidae MORT     Acute   
#> 4 Lepomis macrochirus Bluegill           OS         CENT       MORT     Acute   
#> 5 Gammarus lacustris  Scud               CR         AMPH       MORT     Acute   
#> 6 Poecilia reticulata Guppy              OS         POEC       MORT     Acute   
#> # ℹ 3 more variables: endpoint_concentration <dbl>, source_datasets <chr>,
#> #   n_acute_converted <int>
```
