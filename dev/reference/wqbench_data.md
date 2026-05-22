# Species Sensitivity Data from US EPA ECOTOX Database

This dataset contains species sensitivity records for multiple
chemicals. The data are from the US EPA ECOTOX database but are cleaned
and standardized by the [`wqbench`](https://github.com/bcgov/wqbench/)
package.

## Usage

``` r
wqbench_data
```

## Format

A tibble with columns:

- chemical_name:

  The chemical common name (chr).

- cas:

  The chemical cas number (chr).

- latin_name:

  The species latin name (chr).

- common_name:

  The species common name (chr).

- effect:

  The effect that was being tested (chr).

- sp_aggre_conc_mg.L:

  The chemical concentration in micrograms per litre (dbl).

- trophic_group:

  Trophic group of species (fct).

- ecological_group:

  Identification of salmonids and planktonic invertebrates; otherwise
  "other" (fct).

- species_present_in_bc:

  Whether species is present in British Columbia, Canada (logi).

- class:

  The class name (chr).

- tax_order:

  The order name (chr).

- family:

  The family name (chr).

## Details

These data were sourced from: U.S. Environmental Protection Agency
(2025). “ECOTOXicology Knowledgebase.” Accessed 2025,
<https://cfpub.epa.gov/ecotox/> (visited on ).

The data cleaning steps closely follow the wqbench processing procedures
and the resulting data should be very similar.

In brief, the wqbench processing compiles data from the ECOTOX database
by firstly classifying tests as either acute or chronic; converting any
acute data to chronic based on published acute to chronic ratios; and
finally aggregating data into a single row for each individual species.

Aggregation is achieved by grouping data by life stage; selecting the
most sensitive endpoint; selecting the most preferred toxicity
estimate(s) in the event that more than one are available; and applying
a geometric mean if more than one value for the preferred toxicity
metric are available for the most sensitive endpoint.

Some deviations from the wqbench processing steps were applied to
generalise the data set beyond a focus on British Columbia (BC), and in
part to align with technical guidance from other jurisdictions (for
example, Australia and New Zealand, ANZG).

Deviations from the wqbench processing steps include:

1.  All chemicals with six or more species are included regardless of
    whether they contain species present in BC. These would be excluded
    for wqbench which was designed with the aim of being representative
    for BC.

2.  Only chemicals with representative species for four or more
    taxonomic classes are included. This was done to align somewhat with
    the methods for ANZG
    (https://www.waterquality.gov.au/anz-guidelines/guideline-values/derive/warne-method-derive-2025)
    which requires guidelines are derived only when there are taxa from
    four or more "distinct taxa". Using class to define "distinct taxa"
    only approximates this requirement, because the definition provided
    in the ANZG is not linked directly to any one taxonomic hierarchical
    level and therefore cannot be applied in any automated way using the
    taxonomic hierarchy.

## Examples

``` r

print(wqbench_data)
#> # A tibble: 36,629 × 14
#>    chemical_name          cas   latin_name common_name effect sp_aggre_conc_mg.L
#>    <chr>                  <chr> <chr>      <chr>       <chr>               <dbl>
#>  1 1-Chloro-4-nitrobenze… 1000… Daphnia m… Water Flea  Repro…              0.19 
#>  2 1-Chloro-4-nitrobenze… 1000… Poecilia … Guppy       Morta…              0.66 
#>  3 1-Chloro-4-nitrobenze… 1000… Chlorella… Green Algae Growth              0.98 
#>  4 1-Chloro-4-nitrobenze… 1000… Tetrahyme… Ciliate     Popul…              7.44 
#>  5 1-Chloro-4-nitrobenze… 1000… Penaeus c… Fleshy Pra… Morta…              0.214
#>  6 1-Chloro-4-nitrobenze… 1000… Danio rer… Zebra Danio Behav…              0.306
#>  7 1-Chloro-4-nitrobenze… 1000… Desmodesm… Green Algae Popul…              3.28 
#>  8 4-Nitrobenzenamine     1000… Pimephale… Fathead Mi… Morta…             11.1  
#>  9 4-Nitrobenzenamine     1000… Lepomis m… Bluegill    Morta…              3.6  
#> 10 4-Nitrobenzenamine     1000… Oncorhync… Rainbow Tr… Morta…              2    
#> # ℹ 36,619 more rows
#> # ℹ 8 more variables: trophic_group <fct>, ecological_group <fct>,
#> #   species_present_in_bc <lgl>, method <chr>, species_number <int>,
#> #   class <chr>, tax_order <chr>, family <chr>
```
