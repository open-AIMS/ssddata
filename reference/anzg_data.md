# ANZG Species Sensitivity Data

ANZG Species Sensitivity Data provided by the Department of Agriculture
Water and the Environment, Australia.

## Usage

``` r
anzg_data
```

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 163
rows and 12 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>).

Additional information is available from the Water Quality website at
<https://www.waterquality.gov.au/>.

Additional information may be available from the primary source for each
chemical:

- metolachlor_fresh:

  ANZG (2020). “Toxicant default guideline values for aquatic ecosystem
  protection: Metolachlor in freshwater.” Australian and New Zealand
  Governments and Australian State and Territory Governments, Canberra,
  Australia.
  <https://www.waterquality.gov.au/anz-guidelines/guideline-values/default/water-quality-toxicants/toxicants/metolachlor-fresh-2020>.

- alpha_cypermethrin_fresh:

  ANZG (2023). “Toxicant default guideline values for aquatic ecosystem
  protection: Alpha-cypermethrin in freshwater.” Australian and New
  Zealand Governments and Australian State and Territory Governments,
  Canberra, Australia.
  <https://www.waterquality.gov.au/sites/default/files/documents/alpha-cypermethrin-fresh-dgvs-technical-brief.pdf>.

- aluminium_marine:

  ANZG (2025). “Toxicant default guideline values for aquatic ecosystem
  protection: Aluminium in marine water.” Australian and New Zealand
  Governments and Australian State and Territory Governments, Canberra,
  Australia.
  <https://www.waterquality.gov.au/sites/default/files/documents/aluminium-marine-dgvs-technical-brief.pdf>.

- ametryn_fresh:

  ANZG (2025). “Toxicant default guideline values for aquatic ecosystem
  protection: Ametryn in freshwater.” Australian and New Zealand
  Governments and Australian State and Territory Governments, Canberra,
  Australia.
  <https://www.waterquality.gov.au/sites/default/files/documents/ametryn-fresh-dgvs-technical-brief.pdf>.

- ammonia_fresh:

  ANZG (2026). “Toxicant default guideline values for aquatic ecosystem
  protection: Ammonia in freshwater.” Australian and New Zealand
  Governments and Australian State and Territory Governments, Canberra,
  Australia.
  <https://www.waterquality.gov.au/sites/default/files/documents/ammonia-fresh-dgvs-technical-brief.pdf>.

- bisphenol_a_fresh:

  ANZG (2023). “Toxicant default guideline values for aquatic ecosystem
  protection: Bisphenol A in freshwater.” Australian and New Zealand
  Governments and Australian State and Territory Governments, Canberra,
  Australia.
  <https://www.waterquality.gov.au/sites/default/files/documents/bisphenol-a-fresh-dgvs-technical-brief.pdf>.

- bisphenol_a_marine:

  ANZG (2023). “Toxicant default guideline values for aquatic ecosystem
  protection: Bisphenol A in marine water.” Australian and New Zealand
  Governments and Australian State and Territory Governments, Canberra,
  Australia.
  <https://www.waterquality.gov.au/sites/default/files/documents/bisphenol-a-marine-dgvs-technical-brief.pdf>.

- boron_fresh:

  ANZG (2021). “Toxicant default guideline values for aquatic ecosystem
  protection: Boron in freshwater.” Australian and New Zealand
  Governments and Australian State and Territory Governments, Canberra,
  Australia.
  <https://www.waterquality.gov.au/sites/default/files/documents/boron_fresh_dgv_technical-brief.pdf>.

- chromium_III_fresh:

  ANZG (2026). “Toxicant default guideline values for aquatic ecosystem
  protection: Chromium (III) in freshwater.” Australian and New Zealand
  Governments and Australian State and Territory Governments, Canberra,
  Australia.
  <https://www.waterquality.gov.au/sites/default/files/documents/chromium-III-fresh-dgvs-technical-brief.pdf>.

The columns are as follows, noting that some information may not be
available for all chemicals:

- Chemical:

  The chemical name (chr).

- Conc:

  The chemical concentration in micrograms per Litre (dbl).

- Duration:

  The duration of the test in days (chr).

- Genus:

  The Genus name (chr).

- Group:

  The taxonomic group (chr).

- Life_stage:

  Life stage of the test organism (chr).

- Medium:

  The medium - freshwater or marine water (chr).

- Notes:

  Other notes (chr).

- Phylum:

  The Phylum name (chr).

- Species:

  The species binomial name (chr).

- Test_endpoint:

  The test endpoint measure (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

## Examples

``` r

head(anzg_data)
#> # A tibble: 6 × 12
#>   Chemical     Conc Duration Genus  Group Life_stage Medium Notes Phylum Species
#>   <chr>       <dbl> <chr>    <chr>  <chr> <chr>      <chr>  <chr> <chr>  <chr>  
#> 1 metolachlor  6528 4        Achna… Diat… Exponenti… fresh… Spec… Bacil… minuti…
#> 2 metolachlor   240 5        Anaba… Blue… Not stated fresh… NA    Cyano… flosaq…
#> 3 metolachlor    14 14       Cerat… Macr… Not stated fresh… Spec… Trach… demers…
#> 4 metolachlor   228 4        Chlam… Gree… Not stated fresh… Spec… Chlor… reinha…
#> 5 metolachlor     1 4        Chlor… Gree… Exponenti… fresh… Spec… Chlor… pyreno…
#> 6 metolachlor  4016 4        Crati… Diat… Exponenti… fresh… Spec… Bacil… accomo…
#> # ℹ 2 more variables: Test_endpoint <chr>, Toxicity_measure <chr>
```
