# ssddata 1.0.0.9000 (development)

## Bug fixes

- Added the missing species names to `csiro_chlorine_marine`, which shipped all
  30 of its rows with a blank `Species`. The names were reconstructed from
  Batley & Simpson (2020). The dataset now also carries `Duration`,
  `Life_stage`, `Notes`, `Test_endpoint` and `Toxicity_measure`, taking it from
  3 columns to 9.
- Corrected concentration units for four ANZG freshwater datasets that were
  stored in mg/L but documented and treated as ug/L, so their `get_ssddata()`
  values disagreed with the gazetted `ssd_fits` estimates by ~1000x
  (GitHub #47): `anzg_boron_fresh`, `anzg_nitrate_soft_fresh`,
  `anzg_nitrate_moderate_fresh` and `anzg_nitrate_hard_fresh` are now in ug/L.
- Corrected the `ssd_fits` estimates for `anzg_dioxins_fresh`, which were
  stored in ng/L rather than ug/L (GitHub #47).
- Added a `Units` column to `ssd_fits` recording each fit's concentration
  units (per-dataset: ccme datasets are mg/L / ug/L / ng/L; anzg/aims/csiro
  are ug/L; anon not recorded), and to the ANZG, aims and csiro raw datasets.
  Added a test asserting that no gazetted hazard concentration exceeds the raw
  data maximum for any dataset (`test-units-consistency.R`).

## New datasets

### ANZG datasets
- Added 30 new ANZG individual chemical datasets: `anzg_alpha_cypermethrin_fresh`,
  `anzg_aluminium_marine`, `anzg_ametryn_fresh`, `anzg_ammonia_fresh`,
  `anzg_bisphenol_a_fresh`, `anzg_bisphenol_a_marine`, `anzg_boron_fresh`,
  `anzg_chlorine_marine`, `anzg_chromium_III_fresh`, `anzg_copper_marine`,
  `anzg_dioxins_fresh`, `anzg_diuron_fresh`, `anzg_diuron_marine`,
  `anzg_fipronil_fresh`, `anzg_fluoride_fresh`, `anzg_glyphosate_fresh`,
  `anzg_iron_fresh`, `anzg_iron_marine`, `anzg_mancozeb_fresh`,
  `anzg_manganese_marine`, `anzg_mcpa_fresh`, `anzg_metolachlor_fresh`,
  `anzg_metsulfuron_methyl_fresh`, `anzg_nickel_marine`,
  `anzg_nitrate_hard_fresh`, `anzg_nitrate_moderate_fresh`,
  `anzg_nitrate_soft_fresh`, `anzg_paraquat_fresh`,
  `anzg_perfluorooctane_sulfonate_pfos_fresh`, `anzg_picloram_fresh`,
  `anzg_simazine_fresh`, `anzg_simazine_marine`,
  `anzg_sulfometuron_methyl_fresh`, `anzg_zinc_marine`.
- Added `anzg_data` aggregate dataset.

### EnviroTox datasets
- Added `envirotox_data` (list), `envirotox_acute`, `envirotox_chronic`,
  and `envirotox_chemical` datasets from the EnviroTox database.

### ANZTox datasets
- Added `anztox_data` aggregated dataset derived from the ANZTox database,
  with accompanying Quarto vignette documenting data processing steps.

### WQBench datasets
- Added `wqbench_data` aggregated dataset from Australian water quality
  benchmarking work.

## New and improved functions

- `ssd_data_sets()` gains a `set` argument supporting `"v1"`, `"v2"` (default),
  prefix vectors (e.g. `c("aims", "ccme")`), `"wqbench"`, `"envirotox_acute"`,
  `"envirotox_chronic"`, `"anztox"`, and `"alldata"` to flexibly retrieve
  per-chemical tibbles from any data source.
- `ssd_data_sets()` gains a `split` argument to further split datasets by
  arbitrary columns.
- `ssd_data_sets()` gains a `summarize` argument (`"geomean"` or `"none"`)
  controlling duplicate species handling.
- `ssd_data_sets()` gains a `cas_lookup` argument for CAS number alignment
  across sources.
- Column names standardised across all datasets returned by `ssd_data_sets()`:
  `Species` (first) and `Conc` (second) are guaranteed.
- Added `list_datasets()` as a deprecated wrapper for backwards compatibility
  with EnviroTox workflows.

## Other changes

- Updated `ssd_fits` dataset to align distribution naming with ssdtools and
  distinguish shinyssdtools results.
- Auto-generated `_pkgdown.yml` via `data-raw/build_pkgdown_yml.R` with
  structured reference sections.
- Added Ayla Pearson as package author.
- Documentation improvements throughout, including Rdpack bibliography
  references for new datasets.
- Naming convention standardised (e.g. `freshwater` → `fresh`, `marine` suffix).

# ssddata 1.0.0 (2021-09-13)

- Release to CRAN.
- Added `ssd_fits` dataset of fitted SSD results.
- CRAN packaging fixes: license, URLs, return value descriptions.

# ssddata 0.0.0.9001 (2021-08-31)

- Added datasets.

# ssddata 0.0.0.9001 (2021-08-27)

- Initialised package.