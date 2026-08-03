# ANZTOX Species Sensitivity Data

A curated dataset of species-level ecotoxicity data. These data were
sourced from the ANZTOX database, originally served by the Qld
government and then by SETAC, and now maintained locally.

The data were cleaned and algorithmically (machine) processed for
Species Sensitivity Distribution (SSD) analysis using a workflow
developed to mimic as closely as possible the principles and decisions
documented in (ANZECC and ARMCANZ 2000) and (Warne et al. 2015) and
subsequent updates (Warne et al. 2018; Warne et al. 2025) .

Data encompass two source tables from the available sql file extracted
from the ANZTOX database:

- toxicityvalue2000 (17,755 records), originally sourced from (Sunderam
  et al. 2000) , a Microsoft Access database distributed on CD-ROM with
  the ANZECC & ARMCANZ Water Quality Guidelines.

- toxicityvalue2016 (2,794 records), which is the data underpinning the
  subsequent 2015 and 2018 updates to the water quality guidelines
  (Warne et al. 2015; Warne et al. 2018) .

## Usage

``` r
anztox_data
```

## Format

A tibble with one row per chemical x mediatype combination and columns:

- casnumber_grouped:

  Grouped CAS number (character).

- chemicalname_grouped:

  Grouped chemical name (character).

- mediatype:

  "Freshwater" or "Marine" (character).

- data:

  List-column of nested tibbles containing species-level toxicity data.

## Details

The data cleaning and SSD eligibility workflow is fully documented in
the accompanying vignette:
`vignette("ANZTOX-data-processing", package = "ssddata")`

In brief:

1.  **Harmonisation**: The 2000 and 2016 datasets differed in structure
    and endpoint vocabulary and were de-normalised, cleaned, and
    combined into a single table. Chemical variants and salts are mapped
    to parent compounds via a curated CAS parent lookup. Endpoint labels
    from 2016 are mapped to 2000 effect codes.

2.  **Test type priority**: Within each species x chemical x endpoint
    group, chronic data are preferred over subchronic, and subchronic
    over acute.

3.  **Acute-to-chronic conversion**: Where only acute data are available
    for a species, acute LC/EC/IC50 values are divided by a default ACR
    of 10 (Warne et al. 2025, Section 3.4.2.2) to obtain chronic
    negligible-effect equivalents before SSD fitting.

4.  **Aggregation**: Concentration values for the same species x
    endpoint are geometric-mean averaged. The most sensitive endpoint
    per species is retained.

5.  **Eligibility threshold**: Only chemical x media combinations with
    \>= 5 species from \>= 4 distinct major taxonomic groups are
    retained. These are then nested into a list-column ready for SSD
    fitting or related functions.

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
  chemical x media combination. Each row represents a single species and
  contains columns: `scientificname`, `commonname_species`,
  `majorgroup`, `minorgroup`, `endpoint`, `endpoint_concentration`
  (geometric mean concentration in ug/L or mg/L, depending on the
  chemical), `testtype` (Chronic or Acute), `source_datasets`
  (comma-separated source: "2000", "2016", or both), and
  `n_acute_converted` (count of acute records that contributed to the
  geometric mean after ACR conversion).

## References

ANZECC, ARMCANZ (2000). *Australian and New Zealand Guidelines for Fresh
and Marine Water Quality*. Australian and New Zealand Environment and
Conservation Council and Agriculture and Resource Management Council of
Australia and New Zealand, Canberra, Australia.  
  
Sunderam RIM, Warne MS, Chapman J, Rose R, Hawkins J, Pablo F (2000).
“The ANZECC & ARMCANZ Toxicant Water Quality Guideline Database.”
Microsoft Access database distributed on CD-ROM with ANZECC & ARMCANZ
Water Quality Guidelines.  
  
Warne MS, Batley GE, van Dam RA, Chapman JC, Fox DR, Hickey CW, Stauber
JL (2015). “Revised Method for Deriving Australian and New Zealand Water
Quality Guideline Values for Toxicants.” Department of Science,
Information Technology and Innovation, Brisbane, Queensland, Australia.
Prepared for the Standing Council on Environment and Water (SCEW).  
  
Warne MS, Batley GE, van Dam RA, Chapman JC, Fox DR, Hickey CW, Stauber
JL (2018). “Revised Method for Deriving Australian and New Zealand Water
Quality Guideline Values for Toxicants.” Australian and New Zealand
Governments, Canberra, ACT, Australia. Updated version associated with
the Australian and New Zealand Guidelines for Fresh and Marine Water
Quality (ANZG 2018).  
  
Warne MS, Batley GE, van Dam RA, Chapman JC, Fox DR, Hickey CW, Stauber
JL, Fisher R (2025). “Method for Deriving Australian and New Zealand
Water Quality Guideline Values for Protecting Aquatic Ecosystems from
Toxicants – Update of 2018 Version.” Australian and New Zealand
Governments, Canberra, ACT, Australia. Prepared for the Australian and
New Zealand Guidelines for Fresh and Marine Water Quality.

## Examples

``` r

print(anztox_data)
#> # A tibble: 174 × 4
#>    casnumber_grouped chemicalname_grouped  mediatype  data              
#>    <chr>             <chr>                 <chr>      <list>            
#>  1 60515             Dimethoate            Freshwater <tibble [30 × 11]>
#>  2 79005             1,1,2-Trichloroethane Freshwater <tibble [19 × 11]>
#>  3 79005             1,1,2-Trichloroethane Marine     <tibble [17 × 11]>
#>  4 58899             Lindane               Freshwater <tibble [71 × 11]>
#>  5 2921882           Chlorpyrifos          Freshwater <tibble [53 × 11]>
#>  6 2921882           Chlorpyrifos          Marine     <tibble [29 × 11]>
#>  7 309002            Aldrin                Freshwater <tibble [41 × 11]>
#>  8 12789036          Chlordane             Freshwater <tibble [38 × 11]>
#>  9 60571             Dieldrin              Freshwater <tibble [17 × 11]>
#> 10 115297            Endosulfan            Freshwater <tibble [74 × 11]>
#> # ℹ 164 more rows

# Nest structure: each row contains species data ready for ssdtools
head(anztox_data$data[[1]])
#> # A tibble: 6 × 11
#>   Species           commonname_species Group minorgroup endpoint testtype   Conc
#>   <chr>             <chr>              <chr> <chr>      <chr>    <chr>     <dbl>
#> 1 Daphnia magna     Water flea         Crus… Cladoceron GRO      Chronic    29  
#> 2 Brachydanio rerio Zebra danio, zebr… Oste… Cyprinidae MORT     Chronic  4053. 
#> 3 Oncorhynchus myk… Rainbow trout      Oste… Salmonidae MORT     Acute     733. 
#> 4 Lepomis macrochi… Bluegill           OS    CENT       MORT     Acute     655. 
#> 5 Gammarus lacustr… Scud               CR    AMPH       MORT     Acute      23.8
#> 6 Poecilia reticul… Guppy              OS    POEC       MORT     Acute    4257. 
#> # ℹ 4 more variables: source_datasets <chr>, n_acute_converted <int>,
#> #   Chemical <chr>, Medium <chr>
```
