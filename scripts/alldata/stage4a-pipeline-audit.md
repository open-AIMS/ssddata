# Stage 4a Pipeline Audit
Date: 2026-06-23

Audit and documentation only — no `DATASET.R` files, `.rda` files, or source
CSVs/spreadsheets were modified to produce this report. Where a claim below
depends on the actual data rather than just the script text (row counts,
distinct values, NA counts), it was checked by loading the relevant cached
`.rda`/`.rds`/`.csv` file or the raw `envirotox.xlsx` / `wqbench` RDS/SQLite
read-only — never by re-running a `DATASET.R` end to end. The live ANZTOX
PostgreSQL database was not available in this session, so anything that
would require a fresh query against it is flagged as unverified below
rather than asserted.

---

## anztox pipeline summary

**Inputs read:**
- `data-raw/anztox/raw/cas_parent_lookup.csv` — the **original 40-row**
  lookup, not the expanded 6,336-row `data-raw/cas_parent_lookup_all.csv`.
  This confirms what the `cas_parent_lookup_build` vignette already states:
  the expanded table is not wired into any build script yet.
- A `toxicants-dgvs-mastertable-*.xlsx` file from `data-raw/anzg/` (most
  recently modified one if several exist) — published 2000 DGVs, used only
  for the downstream validation/diagnostic step, not for filtering.
- `data-raw/anztox/endpoint_2016_to_2000_lookup.csv` — maps free-text 2016
  endpoint labels to 2000 endpoint codes; validated for uniqueness at load
  time (`stop()` on duplicate `endpoint_2016_raw`).
- Live PostgreSQL tables: `toxicityvalue`, `toxicityvalue2000`,
  `toxicityvalue2016`, `chemical`, `species`, `mediatype`, `endpoint`,
  `effect`, `testtype`, `concentrationcode`, `status`, `reference`.

**Filtering applied (SSD eligibility workflow, Step 1):** records are
dropped where `concentrationused` is NA or ≤ 0, `scientificname` is NA,
`testtype` is NA, `mediatype` is NA (i.e. not "Freshwater"/"Marine"), or
`casnumber_grouped` is NA.

**CAS parent lookup:** applied once, immediately after `tox2000_core` and
`tox2016_core` are row-bound into `toxicityvalue_combined_clean` — i.e.
*before* any of the SSD eligibility filters run. Produces
`casnumber_grouped = coalesce(parent_casnumber, casnumber)` and
`chemicalname_grouped = coalesce(parent_name, commonname)`.

**Section 3.4.4-equivalent aggregation:** yes — geometric mean of
`concentration_chronic_equiv` within
chemical × mediatype × species × endpoint × testtype (Step 4), then
`slice_min()` to the single most-sensitive endpoint per species (Step 5).
**Important:** filtering and aggregation are **not separated into two
named objects** — Steps 1 through 6 are one continuous `|>` chain from
`toxicityvalue_combined_clean` straight to `ssd_species_eligible_combined`.
There is no intermediate variable that is "filtered but not yet
aggregated."

**Pre-aggregation state / object name:** the closest existing object is
`toxicityvalue_combined_clean` (also written to
`data-raw/anztox/toxicityvalue_combined_clean.csv`), but this is filtered
**not at all** — it sits *before* even Step 1's base filters, still
containing rows with NA concentrations, NA mediatype, etc. The genuinely
"filtered-but-unaggregated" state exists only transiently, between the
`acr_applied`/`concentration_chronic_equiv` `mutate()` and the
`summarise()` call that computes the geometric mean — it is never bound to
a name.

**Fields in `toxicityvalue_combined_clean`** (20,549 rows, confirmed from
the cached CSV): `source_dataset`, `toxicityvalue_id`, `casnumber`,
`commonname`, `mediatype`, `scientificname`, `commonname_species`,
`majorgroup`, `minorgroup`, `testtype`, `endpoint`, `concentrationused`,
`concentration`, `reference_bib`, `parent_casnumber`, `parent_name`,
`casnumber_grouped`, `chemicalname_grouped`.

**Fields in final `anztox_data.rda`** (174 chemical × mediatype rows,
confirmed by loading the `.rda`): nesting keys `casnumber_grouped`,
`chemicalname_grouped`, `mediatype`, plus a nested `data` list-column whose
elements have `Species`, `commonname_species`, `Group`, `minorgroup`,
`endpoint`, `testtype`, `Conc`, `source_datasets`, `n_acute_converted`,
`Chemical`, `Medium`.

**Units field:** **none.** No units/UOM column exists anywhere in the
cached CSV, the final `.rda`, the vignette, or any other file checked in
this audit (the bundled `DBASE-setacorg_bolt942.sql` turned out to be an
unrelated Bolt-CMS website dump, not the ANZTOX schema, and contains no
`toxicityvalue`/`chemical` table definitions at all). Confirming whether a
units column exists upstream in the live database would require a fresh
DB connection, which was not available in this session.

**Other findings worth flagging:**
- **The script as committed does not parse.** Line 431 reads
  `by = c("species_id" => "id")` (note `=>` instead of `=`) inside the
  `toxicityvalue2016_clean` build. Confirmed directly:
  `parse("data-raw/anztox/DATASET.R")` fails with
  `'=>' is disabled; set '_R_USE_PIPEBIND_' envvar to a true value to enable it`.
  `=>` is R's experimental "pipebind" placeholder operator, disabled by
  default — this is almost certainly a typo for `=`. As committed, sourcing
  this script in a default R session will fail at parse time before any
  code runs.
- **`testtype` values are not fully covered by the documented
  classification.** Besides `"chronic"`, `"sub-chronic"`/`"subchronic"`,
  and `"acute"`, the combined data also contains 632 rows of
  `"Chronic QSAR"` (and 1 NA). `"chronic qsar"` does not match the
  `test_class` regex for `"chronic"` exactly, so it falls into the `"other"`
  bucket — and `"other"` is not included in any of the three retained
  branches of the priority-selection filter. These 632 rows are therefore
  **silently dropped entirely**, not merely deprioritised, even in groups
  that have no competing chronic/subchronic/acute record.
- **`majorgroup` mixes two incompatible vocabularies.** Confirmed via the
  combined CSV: short 2000-style codes (`OS`, `CR`, `ML`, `IN`, `AL`, `AN`,
  `AM`, `RO`, `CY`, `PR`, `CN`, `EC`, `NM`, `PL`, `UR`, `MI`, `CH`, `SI`,
  `LI`, `TR`) co-occur with full taxonomic names apparently from the 2016
  dataset (`Osteichthyes`, `Crustacea`, `Algae`, `Mollusca`,
  `Magnoliophyta`, `Annelida`, `Cnidaria`, `Cyanophycota`, `Amphibia`,
  `Phaeophycophyta`, `Insecta`, `Phytoplankton`, `Collembola`). These are
  never reconciled against each other within anztox's own pipeline, so
  `"OS"` and `"Osteichthyes"` count as two different groups for the
  ≥4-major-group eligibility threshold, and both leak into the final
  `Group` column (confirmed: the first nested species table in
  `anztox_data` contains both `"Osteichthyes"` and `"OS"` rows for the
  same chemical).
- 939 of 20,549 rows have NA `mediatype` (anything other than
  freshwater/marine/"marine water" text is normalised to NA and dropped);
  3,310 have NA concentration; 113 have NA `endpoint`; 75 have NA
  `chemicalname_grouped`.

---

## wqbench pipeline summary

**Input:** `data-raw/wqbench/ecotox_ascii_12_11_2025.rds` (already built;
loaded via `readRDS`) and the matching `.sqlite` file (used only to pull a
`species` lookup of `species_number`, `class`, `tax_order`, `family`). The
upstream `wqb_create_data_set()` call that would build the RDS from a fresh
EPA ECOTOX download is present in the script but **commented out** — it is
not run in this pipeline today.

**Function call order and what each does.** `DATASET.R` itself calls only
two `wqbench` functions directly (`.build_wqbench_medium_lookup` is a local
helper, not a package function). Almost all filtering/classification work
is already baked into the RDS by the time this script runs, inside
`wqb_create_data_set()` (source inspected directly from the installed
`wqbench` package, since `DATASET.R` does not call its sub-steps
explicitly):

1. *(commented out, not run this session)* `wqb_create_data_set()` →
   internally: `wqb_download_epa_ecotox` → `wqb_create_epa_ecotox` →
   `wqb_add_bc_species` → `wqb_add_bc_wqg` →
   `wqb_add_concentration_endpoints` → `wqb_add_lifestage` →
   `wqb_add_media` → `wqb_add_trophic_group` →
   `wqb_add_duration_conversions` → `wqb_add_conc_conversions` →
   `wqb_join_data` (internal) → `wqb_clean_data` (internal) →
   `wqb_classify_duration` → `wqb_standardize_effect` → `saveRDS`.
2. `.build_wqbench_medium_lookup(data_set)` — builds a
   Chemical × Species × effect → Medium lookup from `data_set$media_type`
   via the local `.map_wqbench_medium()` (`"FW"`→`"Freshwater"`,
   `"SW"`→`"Marine"`, everything else → `NA`, collapsed to `"Unknown"` if a
   group spans more than one mapped value).
3. `mutate(method = "SSD")` — tags every row for the SSD branch inside
   `wqb_aggregate()` (it has a separate, slightly different priority
   ranking for a non-SSD `method`).
4. `group_split(cas) |> map(wqbench::wqb_aggregate) |> bind_rows()` — **the
   aggregation step**, Section-3.4.4 equivalent. Inside `wqb_aggregate()`
   (source inspected): groups by `species_number × lifestage × effect`,
   derives `endpoint_alpha`/`endpoint_numeric` from the `endpoint` field,
   ranks endpoint types via an `effect_priority_order` (under the `"SSD"`
   method, EC/IC ≤10 ranks highest at 8, NOEC/NOEL ranks 5, LC ≥20 ranks
   lowest at 1), keeps only the top-ranked endpoint type per group,
   geometric-means `effect_conc_std_mg.L` within that group into
   `sp_aggre_conc_mg.L`, then keeps the single lowest-concentration row per
   `species_number`.
5. `filter(n() > 5)` per `cas` (≥6 species) and, after joining the
   `species` lookup, `filter(n_distinct(class) >= 4)` per `cas` — the SSD
   eligibility threshold, analogous to anztox's ≥5 species/≥4 major-group
   rule but counted on taxonomic `class` rather than `majorgroup`, with a
   slightly higher minimum species count.
6. Rename to ssddata conventions, left-join `medium_lookup`, coalesce
   missing `Medium` to `"Unknown"`.

**Intercept point:** `data_set` (loaded from the RDS), specifically its
state immediately after load and *before* `mutate(method = "SSD")`. This is
the **best-positioned of the three uncurated sources** for a Stage 4b
intercept — a single, cleanly named, already-materialized object.

**Fields at the intercept point** (confirmed by loading the RDS directly:
361,817 rows × 24 columns): `chemical_name`, `cas`, `latin_name`,
`common_name`, `endpoint`, `effect`, `effect_conc_mg.L`, `lifestage`,
`duration_hrs`, `duration_class`, `effect_conc_std_mg.L`, `acr`,
`media_type`, `trophic_group`, `ecological_group`, `species_present_in_bc`,
`author`, `title`, `source`, `publication_year`, `present_in_bc_wqg`,
`species_number`, `download_date`, `version`.

**Filtering already applied before this intercept point** (baked into the
RDS by `wqb_clean_data`, an internal/unexported function inspected via
`wqbench:::wqb_clean_data`): drops `conc1_mean == "NR"` or containing
`<`/`>`; drops `genus == ""`; drops NA `trophic_group`; drops NA/""/"NR"
`duration_mean`; requires the `duration_units_to_keep` and
`conc_conversion_flag` flags. **No ecological-relevance/effect-category
filtering happens at all** — every value of `effect` (22 categories, see
below) survives to this point and beyond. **`wqb_filter_chemical(data,
cas_num)` exists in the package but is never called** in `DATASET.R`;
per-chemical separation is instead achieved procedurally via
`group_split(cas)`, which is functionally equivalent but means there is no
single "filter to one chemical" call to hook into for a Stage 4b
intercept — the right hook is the pre-`group_split` `data_set` object
itself.

**Final `wqbench_data.rda` fields** (confirmed: 36,629 rows × 15 columns):
`Chemical`, `cas`, `Species`, `common_name`, `effect`, `Conc`, `Group`,
`ecological_group`, `species_present_in_bc`, `method`, `species_number`,
`class`, `tax_order`, `family`, `Medium`.

**Units field:** **none, as a literal column.** The unit (mg/L) is encoded
only in the *column name* (`effect_conc_mg.L` → `effect_conc_std_mg.L` →
`sp_aggre_conc_mg.L` → renamed to bare `Conc`). No `Units`/`unit` column
ever exists at any stage, including the intercept point and the final
output. `Conc` in `wqbench_data` is implicitly always mg/L.

**Distinct `effect` values in final `wqbench_data`** (22 categories, a
clean controlled vocabulary — contrast with envirotox below): `Mortality`,
`Population`, `Intoxication`, `Growth`, `Biochemistry`, `Physiology`,
`Reproduction`, `Enzyme(s)`, `Behavior`, `Development`, `Genetics`,
`Accumulation`, `Morphology`, `Cell(s)`, `Multiple`, `Feeding behavior`,
`Unspecified`, `Histology`, `Avoidance`, `Hormone(s)`, `Immunological`,
`Injury`, `Ecosystem process`.

**Distinct `Medium` in final data:** `Freshwater`, `Marine`, `Unknown`
(consistent with the Stage 3 media audit).

---

## envirotox pipeline summary

**Input:** `data-raw/envirotox/envirotox.xlsx`, sheets `test` (80,912
rows), `substance` (4,267 rows, read as `EnviroTox_chem`), `taxonomy`
(`EnviroTox_taxo`).

**Acute/chronic classification — reproduced from the script:**
```r
EnviroTox_test_selected <- EnviroTox_test %>%
  filter(
    (Test.statistic == "EC50" & Test.type == "A") |
      (Test.statistic == "LC50" & Test.type == "A") |
      (Test.statistic == "NOEC" & Test.type == "C") |
      (Test.statistic == "NOEL" & Test.type == "C")
  ) %>%
  filter(Effect.is.5X.above.water.solubility == "0") %>%
  ...
```
This is **not a derived classification** — `Test.type` (`"A"`/`"C"`) is
already a raw column in the source spreadsheet (confirmed: 67,478 `"A"`,
13,434 `"C"` of 80,912 total). The script merely *filters* to four specific
statistic × type combinations; every other statistic value present in the
raw data (`IC50`, `MATC`, `LD50`, `EC20`, `IC25`, `IC10`, `IC20`, `EC25`,
`LC70`, `LC30`, `LC10`, `LC25`, `LC60`, `LC40`, `LC75`, ...) is discarded
regardless of `Test.type`.

**Effect filtering: none.** The `Effect` column — confirmed to hold 113
distinct, largely free-text values, e.g. `"Mortality"`, `"Population"`,
`"Intoxication"`, `"Immobilization: Change in the failure to respond or
lack of movement after mechanical stimulation."` — is **never referenced
anywhere in `DATASET.R`**. Direct comparison confirms this: 110 of the 113
distinct `Effect` values still appear after the
`Test.statistic`/`Test.type`/water-solubility filter is applied; the 3
that disappear are singleton rows removed for unrelated reasons (filtered
out by the statistic/type/solubility conditions, not by `Effect` itself).
Effectively **every** effect category survives — there is no
ecological-relevance filtering in envirotox today.

**Aggregation:** yes, equivalent to the Section 3.4.4 geometric-mean step,
via base-R `aggregate(..., FUN = function(x) geoMean(x))` grouped by
`original.CAS × Test.type × Latin.name` → `EnviroTox_test_selected2`. Note
the grouping key does **not** include `Effect` or `Test.statistic`.
Unlike anztox and wqbench, there is **no subsequent "most sensitive
endpoint" selection step** — because the group-by keys already collapse to
one row per chemical × duration-class × species, different statistic types
(`EC50` vs `LC50` within Acute; `NOEC` vs `NOEL` within Chronic) and every
surviving effect category are blended into a single geometric mean,
rather than the lowest value being selected as anztox/wqbench do.

**Eligibility thresholds (different from anztox and wqbench):**
`group_by(original.CAS, Test.type) %>% filter(n() >= 6) %>%
filter(var(Effect.value) > 0)`, followed by `No_trophic_Acute >= 2 &
No_species_Acute >= 6` (acute) / `No_trophic_Chronic >= 2 &
No_species_Chronic >= 6` (chronic) — i.e. **≥6 species and ≥2 trophic
levels**, versus anztox's ≥5 species/≥4 major groups and wqbench's ≥6
species/≥4 classes. None of the three sources use the same numeric
thresholds.

**Final fields in `envirotox_acute`/`envirotox_chronic`** (confirmed from
the script's final `select()` calls): `Chemical`, `Conc`, `Species`,
`Group`, `Medium` (hardcoded `"Unknown"` for every row), `Yanagihara24`
(both acute and chronic), `Iwasaki25` (acute only). **`OriginalCAS` is
explicitly dropped** (`select(!OriginalCAS)`) before these objects are
finalised — the only way back to a CAS number from the final output is via
the separate `envirotox_chemical` lookup table (`Chemical` ↔ `OriginalCAS`,
each enforced as a unique key by `chk::check_key`).

**Units field:** the raw `Unit` column is uniformly `"mg/L"` (confirmed:
80,912/80,912 rows). `DATASET.R` unconditionally multiplies `Effect.value`
by 1000 and replaces `Unit == "mg/L"` with `"ug/L"` early in Section 2 — so
the data is internally consistent at ug/L by construction. **But `Unit` is
never included in any `select()` from `EnviroTox_test_selected2` onward**,
so it does not survive into `envirotox_acute`/`envirotox_chronic`/
`envirotox_data`. There is no literal units field in the final output,
despite a real (and currently safe, since 100% of input rows are mg/L)
unconditional unit conversion having been applied upstream.

**Statistical estimate / `Test statistic` field:** raw column
`Test.statistic`; distinct values and counts (80,912 rows total): `LC50`
48,014, `EC50` 18,329, `NOEC` 9,977, `NOEL` 1,252, `EC10` 1,120, `IC50` 585,
`MATC` 398, `LD50` 226, `EC20` 189, `IC25` 171, `IC10` 139, `IC20` 116,
`EC25` 93, plus small counts (19–34 each) of `LC70`, `LC30`, `LC10`,
`LC25`, `LC60`, `LC40`, `LC75`. Only `EC50`/`LC50`/`NOEC`/`NOEL` survive
the `DATASET.R` filter, and **even that survives only as a filter
condition** — `Test.statistic` itself is not selected into any final
object, so the granular statistic-type information is discarded entirely
before output, the same way `Effect` is.

**EnviroTox's own internal chemical-grouping field is not used.** The
`substance` sheet carries a `CAS` column that already groups related salts
under a shared pseudo-identifier (e.g. `"Metalgrp.Ag"` covers silver
sulfate, elemental silver, silver nitrate, silver chloride, silver iodide
all at once — confirmed: 4,149 distinct `CAS` values vs 4,267 distinct
`original.CAS` values across 4,267 substance rows). `DATASET.R` aggregates
by `original.CAS` (the per-form CAS), **not** by this internal grouped
`CAS` field — which is the right choice for Stage 4b, since `original.CAS`
is exactly the join key `cas_parent_lookup_all.csv$casnumber` expects.

---

## Units audit (all sources)

| Source | Units field name | Distinct values | Stored as data field, or hardcoded/derived in `DATASET.R`? |
|---|---|---|---|
| aims | `Units` (added in `DATASET.R`) | `"ug/L"` — a constant for every row | **Hardcoded literal** (`Units = "ug/L"`); `Conc` is pre-multiplied by a `Conversion` column already present in `aims.csv` before this line runs |
| csiro | *(none)* | n/a | Not present in `csiro.csv`; not added in `DATASET.R`. Documented only as prose in the Rd template: *"All concentration data are ug/L unless otherwise stated."* |
| ccme | `Units` (added in `DATASET.R`) | `mg/L` (Boron, Chloride); `ug/L` (Cadmium, Glyphosate, Uranium, Silver); `ng/L` (Endosulfan) | **Derived** via a 7-step chained `str_replace()` keyed on the `Chemical` name — see reproduced block and verification below |
| anzg | *(none)* | n/a | Not present in `anzg.csv`; not added in `DATASET.R`. Documented only as a column-description string in the Rd template: *"The chemical concentration in micrograms per Litre."* |
| anztox | *(none)* | unknown — not verifiable in this audit | No units column anywhere in `toxicityvalue_combined_clean.csv`, `anztox_data.rda`, the vignette, or any other accessible file; live-DB schema not queryable here |
| wqbench | *(none — unit is encoded only in column names)* | implicitly `mg/L` for every row (`effect_conc_mg.L` / `effect_conc_std_mg.L` / `sp_aggre_conc_mg.L`) | Derived inside the `wqbench` package's own `wqb_add_conc_conversions()` / `wqb_clean_data()`, upstream of `ssddata`'s `DATASET.R`; no literal units column is ever created |
| envirotox | `Unit` exists in raw data, is converted, then **dropped** before final output | raw: 100% `"mg/L"`; converted internally to `"ug/L"` for all rows; absent from `envirotox_acute`/`envirotox_chronic`/`envirotox_data` | Read from the source `.xlsx`, unconditionally rewritten to `ug/L` in `DATASET.R`, then never selected into any downstream object |

**ccme `str_replace` block — reproduced from the current
`data-raw/ccme/DATASET.R` (confirmed present and unchanged):**
```r
ccme_data$Units <- str_replace(ccme_data$Chemical, "Boron", "mg/L") %>%
  str_replace("Cadmium", "ug/L") %>%
  str_replace("Chloride", "mg/L") %>%
  str_replace("Endosulfan", "ng/L") %>%
  str_replace("Glyphosate", "ug/L") %>%
  str_replace("Uranium", "ug/L") %>%
  str_replace("Silver", "ug/L")
```
Checked against the actual data (`CCME data.csv`, 144 rows after the
`!is.na(Conc)` filter): there are **exactly 7 distinct `Chemical` values**
in the current file, and they are precisely the 7 names this chain
matches. Cross-tabulating `Chemical` against the resulting `Units` (Boron
28→mg/L, Cadmium 36→ug/L, Chloride 28→mg/L, Endosulfan 12→ng/L, Glyphosate
18→ug/L, Silver 9→ug/L, Uranium 13→ug/L) confirms **zero rows fall through
unmapped today.** The mechanism is nonetheless fragile for the future:
`str_replace()` leaves a string that matches none of the seven patterns
**unchanged**, not `NA` — so a chemical added to `CCME data.csv` later
without a matching rule would silently get `Units` equal to its own
`Chemical` name (e.g. `Units == "Copper"`), which would not be caught by a
routine `is.na()` data-quality check.

For the curated sources read directly from CSV (aims, csiro, anzg): **none
of the three raw CSVs contain a units column at all** — `aims.csv`,
`csiro.csv`, and `anzg.csv` all lack any `unit`-named field; the unit
convention for each is established either by a hardcoded constant in
`DATASET.R` (aims) or by prose documentation only (csiro, anzg), as
detailed in the table above.

---

## Intercept points

| Source | Object name | Fields at intercept | Gaps |
|---|---|---|---|
| **anztox** | **None materialized.** `toxicityvalue_combined_clean` is filtered-nothing (pre Step 1). The genuine filtered-but-pre-aggregation state exists only transiently inside one dplyr chain, between the ACR `mutate()` and the `summarise()` geomean call — never bound to a name. | *(inferred, transient)*: `casnumber_grouped`, `chemicalname_grouped`, `mediatype`, `scientificname`, `commonname_species`, `majorgroup`, `minorgroup`, `endpoint`, `testtype`, `concentration_chronic_equiv`, `acr_applied`, `source_dataset` | No materialized intercept object — Stage 4b must either replicate anztox's Steps 1–3 logic standalone, or `DATASET.R` must be edited to bind an intermediate variable. **No units field at all.** No separate statistical-estimate-type field — `endpoint` only captures effect-type (MORT/GRO/etc.), with no EC50/LC50/NOEC-style granularity retained anywhere downstream. `majorgroup` mixes 2-letter codes and full taxonomic names inconsistently. Script currently **fails to parse** (`=>` on line 431) without `_R_USE_PIPEBIND_` set. |
| **wqbench** | `data_set` — loaded from `ecotox_ascii_12_11_2025.rds`, state immediately after load, before `mutate(method = "SSD")` | `chemical_name`, `cas`, `latin_name`, `common_name`, `endpoint`, `effect`, `effect_conc_mg.L`, `lifestage`, `duration_hrs`, `duration_class`, `effect_conc_std_mg.L`, `acr`, `media_type`, `trophic_group`, `ecological_group`, `species_present_in_bc`, `author`, `title`, `source`, `publication_year`, `present_in_bc_wqg`, `species_number`, `download_date`, `version` | No literal units field (mg/L implicit in the column name only). `wqb_filter_chemical()` exists in the package but is unused (`group_split()` is used instead — functionally fine, but means there's no single "filter to one chemical" call to hook a Stage 4b intercept onto). `media_type` needs `.map_wqbench_medium()` translation before use (`FW`/`SW` only map; `CUL`/`NC`/`NONE`/`NR` → `Unknown`). |
| **envirotox** | **None materialized in final form.** Best available intercept is immediately after `envirotox_acute`/`envirotox_chronic` are built (script Sections 7–8, right after `OriginalCAS = original.CAS` is assigned) but **before** `select(!OriginalCAS)` (Section 10) drops it. | `Chemical` (`Short_name`), `Conc` (`Effect.value`, ug/L), `Species` (`Latin.name`), `Group` (`Trophic.Level`), `OriginalCAS`, `Yanagihara24` (+ `Iwasaki25` for acute) | Chemical identifier is **dropped from the actual current final output**; must be recovered via the separate `envirotox_chemical` lookup, or the intercept taken one step earlier than today's de facto final object. No `Medium` field until hardcoded `"Unknown"`. No units field carried through (dropped, though internally ug/L). **No effect/endpoint-category field survives at all** (`Effect` is never selected). **No statistical-estimate-type field survives** either (`Test.statistic` is filtered on, never selected). Aggregation blends across statistic types and effect categories rather than selecting most-sensitive, unlike anztox/wqbench. |

---

## Gaps and decisions required before Stage 4b

### 1. Unit standardisation

No two of the three uncurated sources expose units the same way, and none
of the curated sources store units as data either:

- **anztox** has no units field and no documented convention anywhere
  accessible in this audit — this needs either a live-DB schema check or a
  domain-expert decision on what unit `concentrationused` is actually in
  (commonly assumed µg/L for ANZECC/ANZG-style data, but that is an
  assumption, not a confirmed fact, in the current pipeline).
- **wqbench** is implicitly always mg/L (by construction inside the
  `wqbench` package), but carries no literal units column to confirm or
  override that assumption downstream.
- **envirotox** is internally ug/L (100% of source rows were mg/L and were
  uniformly ×1000-converted) but the `Unit` column is dropped before the
  final objects, so this fact is not machine-checkable from the final data
  alone — only from re-reading `DATASET.R`.
- Among the curated sources, **aims** is explicitly ug/L (hardcoded),
  **ccme** is a documented per-chemical mix of mg/L, ug/L, and ng/L, while
  **csiro** and **anzg** have no field at all (ug/L only by Rd-template
  prose).

Before the geometric-mean step in Section 3.4.4 can be applied across
sources, every source needs either a real `Units` column or a hard,
written assumption substituting for one, and a single target unit (likely
µg/L, matching aims/most-of-ccme/most ANZG convention) to convert all
seven sources into before any cross-source aggregation.

### 2. Schema alignment

The three uncurated sources do not expose the same set of fields at their
respective natural intercept points:

- anztox has no separately materialized intercept object at all (see
  table above) — this is itself a schema gap relative to wqbench, which
  does.
- envirotox's natural intercept (right before `OriginalCAS` is dropped)
  has no chemical-effect/endpoint-category field and no
  statistical-estimate-type field; both exist as raw columns earlier in
  the pipeline (`Effect`, `Test.statistic`) but are discarded before the
  final `select()`. If Stage 4b needs either of these, the intercept point
  must move earlier still — to `EnviroTox_test_selected2` or even
  `EnviroTox_test_selected` — rather than to the current `envirotox_acute`/
  `envirotox_chronic` objects.
- anztox's `majorgroup` field mixes two incompatible taxonomic-group
  vocabularies within itself (see anztox summary above) and would need
  internal harmonisation before being compared against wqbench's `class`
  or envirotox's `Trophic.Level`/`Group`, none of which use the same
  category scheme either.

### 3. Statistical estimate alignment

The three sources are **not** consistent in how many fields they use for
this concept, let alone in vocabulary:

- **anztox**: a single `endpoint` field that captures only effect-type
  (`MORT`, `GRO`, `IMM`, `REP`, ...) — there is no retained field
  distinguishing EC50 from LC50 from NOEC from IC10, etc.
- **wqbench**: two separate fields — `endpoint` (statistic-type codes such
  as `LC50`, used by `wqb_aggregate()`'s priority ranking) and `effect`
  (effect-type category, e.g. `Mortality`).
- **envirotox**: also two separate fields — `Test.statistic` (`EC50`,
  `LC50`, `NOEC`, `NOEL`, ...) and `Effect` (free text) — but neither
  survives into the final output.

A mapping table will be needed not just for vocabulary (anztox's `MORT` ↔
wqbench's `Mortality` ↔ envirotox's free-text `"Mortality"` entries) but
for **structure** — a decision is required on whether Stage 4b should
synthesise a single statistic-type field for anztox (not currently
possible from the retained data without going back to the live DB), or
instead treat anztox as permanently lacking this distinction.

### 4. Effect category alignment

The three sources are at very different stages of harmonisation already:

- **wqbench** has a clean, already-controlled 22-value vocabulary
  (`Mortality`, `Population`, `Growth`, `Reproduction`, ...).
- **anztox** has its own ~24-value abbreviated-code vocabulary (`MORT`,
  `GRO`, `IMM`, `REP`, `PGR`, `HAT`, `BIOMASS`, `DVP`, `LUM`,
  `GLUCOSEUTILISATION`, `POP`, `ABN`, `FERTILISATION`, ...) that does not
  share tokens with wqbench's vocabulary at all (would need a translation
  table, not a case-fold).
- **envirotox** has **no effect-category filtering or even a surviving
  field** — its 113-value `Effect` column is a largely free-text mix of
  short labels and full sentence descriptions, and is not used or
  selected anywhere in the current pipeline. A mapping table from this raw
  113-value vocabulary down to a shared category scheme is unavoidable if
  effect-category alignment is wanted for envirotox at all; right now
  there is nothing to align *from* in the final output, only in
  `EnviroTox_test_selected`/`_selected2`.

Additional harmonisation is therefore needed for all three, and the
**aggregation granularity itself differs**: anztox and wqbench both
aggregate *within* an endpoint/effect-type group and then pick the most
sensitive type per species; envirotox aggregates *across* every
surviving effect/statistic type directly into one number per species per
duration class, with no most-sensitive-type selection step at all. This is
a methodological difference, not just a vocabulary one, and needs an
explicit decision before Stage 4b: should envirotox's aggregation be
changed to match anztox/wqbench's two-step (group-then-select) approach,
or should anztox/wqbench instead be changed to envirotox's blended
approach, or should the difference be accepted and documented?

### 5. Any other gaps or decisions

- **anztox's `DATASET.R` does not currently parse** (the `=>` typo on line
  431) and so cannot be sourced end-to-end today regardless of any Stage
  4b work; this should be fixed (almost certainly to `=`) before anyone
  next needs to re-run the anztox pipeline.
- **anztox silently drops `"Chronic QSAR"` records** (632 rows) at the
  priority-selection step rather than classifying or flagging them — worth
  a decision on whether these should be recovered as acute/chronic/dropped
  deliberately, since right now the drop is an accidental side-effect of
  the `test_class` regex rather than an intentional choice.
- **anztox eligibility thresholds (≥5 species/≥4 major groups), wqbench's
  (≥6 species/≥4 classes), and envirotox's (≥6 species/≥2 trophic levels)
  are all different**, both in the numeric minimums and in which
  taxonomic-grouping field they're counted against. A single, explicit
  Stage 4b eligibility rule will need to be chosen (or each source's
  existing per-source threshold accepted as a pre-filter applied before
  consolidation, with the cross-source ≥5/≥4 rule reapplied afterward).
- **wqbench's medium join key is name-based, not CAS-based** —
  `medium_lookup` is joined onto the aggregated data using
  `c("Chemical", "Species", "effect")`, not `cas`. This works today but is
  more fragile than a CAS-keyed join would be, since chemical name strings
  are not guaranteed unique per CAS across the underlying EPA ECOTOX data
  the way `cas` is.
- **envirotox's own internal salt-grouping field (`CAS` in the `substance`
  sheet, e.g. `"Metalgrp.Ag"`) is correctly bypassed** in favour of
  `original.CAS` — confirmed this is the right join key into
  `cas_parent_lookup_all.csv$casnumber` — but this should be stated
  explicitly as a Stage 4b design decision rather than left implicit, so a
  future contributor doesn't "fix" it by switching to the internal grouped
  field and inadvertently double-groups chemicals that
  `cas_parent_lookup_all.csv` already groups differently.
- The 18 `UNCERTAIN` CAS parent rows and the ccme medium/issue #34
  decision (both already tracked in the Stage 3 audit's deferred-decisions
  list) remain outstanding and are Stage 6 blockers, not Stage 4b
  blockers, but are noted here for completeness since they intersect with
  several of the same chemicals discussed above.

---

## Prompt log

## Session: stage4a-pipeline-audit
Date: 2026-06-23
Model: Claude Sonnet 4.6

### Prompts and Responses

**User:** Requested a pure audit (Stage 4a) of the three uncurated sources'
data-raw pipelines (anztox, wqbench, envirotox) ahead of the Stage 4b
cross-source consolidation work for Issue #33. Asked for: (1) a structured
read-through of each source's `DATASET.R` covering inputs, filtering, CAS
lookup application, Section 3.4.4-equivalent aggregation, pre-aggregation
fields, and final output fields/units; (2) a concentration-units audit
across all seven sources including reproducing and verifying ccme's
`str_replace` unit-assignment block; (3) documentation of the
filtered-but-unaggregated "intercept point" for each uncurated source,
including which of a specified field checklist is present, named, or
missing; (4) a consolidated gap list covering unit standardisation, schema
alignment, statistical-estimate alignment, effect-category alignment, and
any other issues. Explicit instruction: audit only, no files modified, no
scripts run end-to-end, no aggregation or transformed data produced.
Required reading first: the global and project `CLAUDE.md` files, the
ANZTOX_data_processing and cas_parent_lookup_build vignettes, and the
Stage 3 media audit. Output requested at
`scripts/alldata/stage4a-pipeline-audit.md` with a specific section structure, and
a prompt log appended to the same file (not a separate `prompts/` file, per
the literal task instructions).

**Claude:** Read both `CLAUDE.md` files, both named vignettes, and
`scripts/alldata/stage3-media-audit.md` first. Then read all three `DATASET.R`
files in full (`data-raw/anztox/DATASET.R`, `data-raw/wqbench/DATASET.R`,
`data-raw/envirotox/DATASET.R`) without executing any of them. For
wqbench, since the script itself only calls two `wqbench` package
functions directly (most filtering logic lives inside the package, baked
into the pre-built RDS), inspected the installed `wqbench` package's
source for `wqb_create_data_set`, `wqb_aggregate`, `wqb_filter_chemical`,
`wqb_standardize_effect`, `wqb_classify_duration`, and the unexported
`wqb_join_data`/`wqb_clean_data` via `wqbench:::`, to document what
filtering/classification/unit-standardisation actually happens upstream of
ssddata's own script. Verified field lists and row/distinct-value counts
directly against the real artefacts wherever possible: loaded
`data/anztox_data.rda` and `data/wqbench_data.rda`, read
`data-raw/anztox/raw/toxicityvalue_combined_clean.csv`, loaded
`data-raw/wqbench/ecotox_ascii_12_11_2025.rds` directly, and read
`data-raw/envirotox/envirotox.xlsx` (`test` and `substance` sheets) with
`openxlsx` to confirm raw `Test.statistic`/`Test.type`/`Effect`/`Unit`
distributions and the effect of envirotox's filter step on the `Effect`
field specifically (confirmed effectively no effect-category filtering
occurs). Verified ccme's unit `str_replace` chain by running it against
the actual `CCME data.csv` (confirmed all 144 current rows/7 chemicals are
covered, but the mechanism would silently mis-assign a chemical's own name
as its "unit" for any future unmapped chemical, rather than producing
`NA`). Checked aims/csiro/anzg CSVs and Rd templates for units conventions,
finding aims hardcodes `Units = "ug/L"`, while csiro and anzg have no
machine-readable units field at all (documented only in Rd-template
prose). Discovered and confirmed via `parse()` that
`data-raw/anztox/DATASET.R` line 431 uses the disabled `=>` pipebind
operator instead of `=`, meaning the script fails to parse under default R
settings. Also found and documented: 632 `"Chronic QSAR"` anztox rows
silently dropped by the test-type priority filter; an internal
2-letter-code/full-taxonomic-name inconsistency within anztox's own
`majorgroup` field; and that envirotox's final `envirotox_acute`/
`envirotox_chronic` objects drop their chemical identifier (`OriginalCAS`),
effect category (`Effect`), and statistic type (`Test.statistic`) entirely
before output, none of which survive past `EnviroTox_test_selected2`.
Wrote the consolidated findings to
`scripts/alldata/stage4a-pipeline-audit.md` following the requested section
structure (pipeline summaries, units audit table, intercept-points table,
gap list), then appended this prompt log to the same file. No files other
than this report were created or modified; no `.rda`/data outputs were
regenerated.

---

## Supplementary DB query — Stage 4a (units and schema)
Date: 2026-06-23
Model: Claude Sonnet 4.6

This section is a targeted follow-up to the gap flagged above ("anztox has
no units field and no documented convention anywhere accessible in this
audit"). It required a live connection to the ANZTOX PostgreSQL database,
which was not available in the main Stage 4a session. Audit-only: no
`DATASET.R` files, `.rda` files, or source CSVs were modified. All queries
are reproducible via `scripts/alldata/stage4a-supplementary-db-audit.R` (read-only;
not part of any build pipeline).

### 1. Connection outcome

**Success.** Connected with the exact parameters used by
`data-raw/anztox/DATASET.R` (lines 187–194): `RPostgres::Postgres()`,
`dbname = "infogathering"`, `host = "localhost"`, `port = 5432`,
`user = "postgres"`. The password was resolved via the same
`get_db_password()` fallback the script uses
(`Sys.getenv("ANZTOX_DB_PASSWORD")`, then `keyring::key_get("infogathering_postgres", username = "postgres")`)
— a local PostgreSQL instance with this database was running and reachable
on `localhost:5432` in this session, unlike in the main Stage 4a session.

### 2. `concentrationcode` table

Full content (9 rows, columns `id`, `name` only):

| id | name |
|---|---|
| 1 | U |
| 2 | C |
| 3 | H |
| 4 | HC |
| 5 | UI |
| 6 | UD |
| 7 | T |
| 8 | Tp |
| 9 | TpC |

**No units column exists in this table** — only `id` and `name`. The
codes `"U"`, `"C"`, and `"HC"` referenced in the ANZTOX vignette's stricter
`concentrationcode` filter (`status == 'A'` and
`concentrationcode %in% c("U", "C", "HC")`) **do all appear** (ids 1, 2, 4
respectively), confirming the vignette's reference to these codes is
accurate. `concentrationcode` is a data-acceptability/derivation-method
flag (the vignette explains `concentrationused` is preferred over this
field precisely because it is richer), not a unit indicator. This closes
out one part of the original gap: units are **not** hiding in this table.

### 3. `toxicityvalue2000` / `toxicityvalue2016` schema

**`toxicityvalue2000`** (18 columns) — flagged columns: `concentrationused`,
`hardnesscorrectedconc`, `concentrationcode_id`, `concentrationtype_id`.
None of these is a literal units column. `concentrationtype_id` joins to a
`concentrationtype` lookup table (4 rows: `Measured`, `Nominal`,
`Calculated`, `QSAR`) — this describes *how* the value was derived, not
its unit. Distinct-value queries (top 20 by count) showed `concentrationused`
has 3,310 NA (matching the count already established from the cached CSV)
and a normal-looking numeric distribution; `hardnesscorrectedconc` is
~97% NA (17,152/17,755); `concentrationcode_id` and `concentrationtype_id`
distributions are unremarkable lookup-key counts.

**`toxicityvalue2016`** (10 columns) — only `concentrationused` is flagged;
there is no `hardnesscorrectedconc`, `concentrationcode_id`, or
`concentrationtype_id` in this table at all (consistent with the
structural-differences table already documented in the ANZTOX vignette).
Distinct values are a normal-looking numeric distribution with no obvious
unit markers.

**Neither `toxicityvalue2000` nor `toxicityvalue2016` carries a
`concentrationunit_id` or any other units foreign key directly.** This
confirms the original audit's finding that no units column exists on the
tables `DATASET.R` actually reads from for `concentrationused` — but see
§6 below for a unit-bearing table found one join away, which materially
changes the conclusion.

### 4. `testtype` table

Full content (4 rows):

| id | name |
|---|---|
| 1 | Acute |
| 2 | Chronic |
| 3 | Sub-chronic |
| 4 | **Chronic QSAR** |

**`"Chronic QSAR"` is a real, deliberate, named DB-level `testtype`
category (id 4)** — it is not an artefact of the pipeline's regex. This
resolves the open question from the main Stage 4a audit directly: the 632
`"Chronic QSAR"` rows are not a typo or a derived label, they are a
first-class category in the source database, almost certainly meaning a
chronic value *predicted* by a QSAR (quantitative structure-activity
relationship) model rather than measured empirically — consistent with
`concentrationtype` (§3) also having a `"QSAR"` value. The pipeline's
`test_class` regex (`"chronic"`, `"sub-chronic"`/`"subchronic"`, `"acute"`)
does not match `"Chronic QSAR"` and routes it to `"other"`, which is
silently dropped. Since the DB treats `"Chronic QSAR"` as a real, distinct
category, this is a **pipeline design gap** (an unhandled real category),
not a database inconsistency — Stage 4b/anztox maintainers should decide
explicitly whether QSAR-predicted chronic values are acceptable input for
SSD fitting alongside measured chronic values, rather than have the
decision made implicitly by an unmatched regex.

### 5. `majorgroup` vocabulary

`majorgroup` is a free-text column directly on the `species` table (not a
separate FK'd lookup — confirmed via `information_schema.columns`: `species`
has `majorgroup`/`minorgroup` as plain `text` columns, no
`majorgroup_id`). 67 distinct values, mixing 2-letter codes (`OS`, `IN`,
`CR`, `AL`, `ML`, `CY`, `AN`, `AM`, `PR`, `RO`, `EC`, `PL`, `NM`, `AR`,
`AG`, `UR`, `CH`, `LI`, ...) with full taxonomic names (`Magnoliophyta`,
`Crustacea`, `Osteichthyes`, `Mollusca`, `Algae`, `Insecta`, `Cnidaria`,
`Annelida`, `Bacteria`, `Echinodermata`, `Amphibia`, `Phaeophycophyta`,
`Liliopsida`, `Bryozoa`, `Platyhelminthes`, ...), plus 2,277 NA — matching
the vocabulary mix already observed in the cached
`toxicityvalue_combined_clean.csv`.

**Refinement of the original hypothesis.** The main Stage 4a audit
hypothesised the full taxonomic names came "apparently from the 2016
dataset." A follow-up query joining `species` to `toxicityvalue` and then
to `toxicityvalue2000`/`toxicityvalue2016` (via `toxicityvalue.species_id`,
the same join `DATASET.R` itself uses) shows **this is not correct**: both
vocabularies occur substantially within *both* the 2000-referenced and
2016-referenced subsets of `species` rows. For example, among
2000-referenced rows: `CR` (2,762) and `Crustacea` (1,876) both occur;
`OS` (7,383) and `Osteichthyes` (1,502) both occur; `AL` (418) and `Algae`
(342) both occur. The same paired pattern recurs in the 2016-referenced
subset (`CR` 144 / `Crustacea` 285; `OS` 468 / `Osteichthyes` 170; `AL`
206 / `Algae` 243). The cross-tab of code-style × dataset-of-origin:

| code_style | 2000 only | 2016 only |
|---|---|---|
| 2-letter code | 13,528 | 1,096 |
| full name | 3,865 | 832 |
| NA | 362 | 866 |

**Conclusion: the 2-letter-code/full-name discrepancy originates directly
in the shared `species` table itself**, as an internal data-entry
inconsistency (different species rows were populated with different
naming conventions, likely at different times by different curators),
**not** as a property of which toxicity-value table (2000 vs 2016)
references a given species. Because `toxicityvalue2000` and
`toxicityvalue2016` both join the *same* `species` table via the *same*
`species_id` foreign key, there was never a point downstream in the
pipeline where two different vocabularies were merged from two different
sources — the inconsistency is upstream of both, inside `species`, and
both `DATASET.R` and any Stage 4b consolidation will need to harmonise it
as a single-table internal cleanup (e.g. a `majorgroup` synonym map)
rather than a "2000 convention vs 2016 convention" mapping problem.

### 6. Units convention for `concentrationused` — conclusion

This required going one step further than the schema check in §3: a
**`concentrationunit` lookup table exists** (75 distinct unit strings,
including `µg/L`, `mg/L`, `g/L`, `mol/L`, `PPM`, `% effluent`, `pH units`,
`hours`, and many chemical/matrix-specific variants like `mg Cd/L`,
`ugCu/g tissue`). It is referenced by `toxicityvalue.concentrationunit_id`
— i.e. it describes the unit of the **raw** `toxicityvalue.concentration`
field on the base table (the one `DATASET.R` left-joins onto
`toxicityvalue2000`/`toxicityvalue2016` early in the pipeline), **not**
`concentrationused` directly. Neither `toxicityvalue2000` nor
`toxicityvalue2016` has its own `concentrationunit_id`.

**Step 1 — what unit is the raw concentration recorded in, by dataset?**
Joining `toxicityvalue` to `toxicityvalue2000`/`toxicityvalue2016` and
counting `concentrationunit_id`:

- **toxicityvalue2000** (17,755 rows): **17,714 (99.77%) are `ug/L`**;
  the remaining 41 (0.23%) are `mg/L`. Every row has a determinate unit
  (no NA) — toxicityvalue2000 is overwhelmingly, near-universally `ug/L`
  at the raw-concentration level.
- **toxicityvalue2016** (2,794 rows): a heterogeneous mix of case-variant
  and abbreviated unit codes, **none of which is the canonical lowercase
  `"ug/L"` string used for 2000**: `Ug/L` (1,167), `PPM` (680), `Mg/L`
  (586), `PPB` (189), `UM` (52), `MM` (37), `Ng/L` (26), `NM` (26),
  `Umol/L` (11), `M` (8), `Nmol/L` (8), `Ppm` (3), `Nm/L` (1).

**Step 2 — does `concentrationused` actually track the raw, unit-tagged
`concentration` value (i.e. is it in the same unit), or could it be a
re-derived value in a different/normalised unit?** Computed
`ratio = concentrationused / as.numeric(concentration_raw)`, grouped by the
raw concentration's unit:

*toxicityvalue2000:*

| unit_name | n compared | median ratio | % with ratio ≈ 1 |
|---|---|---|---|
| ug/L | 14,168 | **1.0** | **90.6%** |
| mg/L | 40 | 22.6 | 5.0% |

For the dominant `ug/L`-tagged subset, `concentrationused` equals the raw
`concentration` value almost exactly (ratio ≈ 1 for 90.6% of comparable
rows) — direct, strong evidence that **`concentrationused` is in µg/L**
for these records. For the small `mg/L`-tagged subset (40 of 17,755 rows,
0.23%), the ratio is neither ≈1 (same value, same unit) nor a clean ≈1000
(a straight mg→µg conversion) — it ranges from 0.75 to 164 with no
consistent pattern (spot-checked rows: e.g. `concentrationused = 4.80`
against `concentration = 4.8 mg/L`, ratio exactly 1, i.e. **apparently
still in mg/L, uncorrected** for that one row; but most others diverge
in both directions). This is consistent with `concentrationused` being a
genuinely *curated/re-derived* value rather than a pure copy of
`concentration` (as the vignette already states — "a pre-calculated field
populated by the database curators"), so a non-1 ratio does not by itself
prove a unit error; but it does mean this handful of mg/L-tagged 2000
rows **cannot be confirmed as µg/L** by this check, and at least one row
appears to genuinely be left in mg/L.

*toxicityvalue2016:*

| unit_name | n compared | median ratio | % with ratio ≈ 1 |
|---|---|---|---|
| Ug/L | 1,162 | 0.2 | 25.0% |
| PPM | 680 | 200 | 0% |
| Mg/L | 565 | 400 | 0% |
| PPB | 189 | 0.2 | 17.5% |
| (UM, MM, NM, Ng/L, Umol/L, M, Nmol/L, Ppm, Nm/L) | ≤52 each | highly variable | 0% |

None of the 2016 unit groups shows the clean, near-universal ratio ≈ 1
pattern seen for 2000's `ug/L` group. Even the nominally-µg/L-equivalent
`Ug/L` group only matches 25% of the time. **The unit convention for
`concentrationused` in the 2016 subset cannot be confirmed as µg/L (or any
single unit) from this check** — it may be genuinely mixed-unit, or
`concentrationused` may diverge from the raw `concentration` field for
reasons unrelated to units (curatorial re-derivation, as above) in ways
that mask any consistent unit relationship. Disambiguating further would
require either domain-expert review of individual 2016 records or
additional fields not explored in this session.

**Overall conclusion:**

- `concentrationused` for **toxicityvalue2000** (17,755 of 20,549 combined
  rows, 86.4%) is confirmed as **µg/L** with high confidence: 99.77% of
  its raw-concentration rows are unit-tagged `ug/L`, and `concentrationused`
  tracks that raw value almost exactly for 90.6% of comparable cases.
  Combined, **~69% of all `toxicityvalue_combined_clean` rows
  (14,168 / 20,549)** have direct empirical confirmation of µg/L for
  `concentrationused`.
- `concentrationused` for **toxicityvalue2016** (2,794 of 20,549 combined
  rows, 13.6%) and for the small `mg/L`-tagged minority of
  **toxicityvalue2000** (40 rows, 0.2%) is **not confirmed** as µg/L by
  this audit — the underlying raw-concentration units are heterogeneous
  and/or the curatorial relationship between `concentrationused` and the
  raw value does not show a clean, checkable unit-conversion pattern.
- **Recommendation for Stage 4b:** treat the previously "assumed µg/L"
  convention as **confirmed for the ~86% toxicityvalue2000-derived
  majority of anztox data, but unconfirmed for the ~14% toxicityvalue2016-
  derived minority**. If Stage 4b needs a single target unit before
  cross-source consolidation, µg/L remains the best-supported choice
  (matching the majority of anztox, aims, and most of ccme/anzg by
  convention), but the 2016-derived ~13.6% of anztox rows should be
  flagged as a known residual unit-confidence gap rather than silently
  assumed correct — ideally resolved with a domain expert who has access
  to the original 2016 source records, since the DB schema alone cannot
  settle it.

### Prompt log

## Session: stage4a-supplementary-db-audit
Date: 2026-06-23
Model: Claude Sonnet 4.6

### Prompts and Responses

**User:** Requested a targeted supplementary audit (read-only, no
`DATASET.R`/`.rda`/CSV modifications) to resolve the one outstanding gap
from the Stage 4a pipeline audit that required a live database connection:
confirming the units convention for `concentrationused` in the ANZTOX
PostgreSQL database (`infogathering`), plus three related schema
questions — whether `concentrationcode` encodes units, the schema of
`toxicityvalue2000`/`toxicityvalue2016` and their unit-adjacent columns,
whether `"Chronic QSAR"` is a real `testtype` category or a pipeline
artefact, and where the `majorgroup` 2-letter-code/full-name vocabulary
split originates. Findings were to be appended as a new section to this
file (not a new file), using the same connection parameters as
`data-raw/anztox/DATASET.R`.

**Claude:** Read both `CLAUDE.md` files, this file
(`scripts/alldata/stage4a-pipeline-audit.md`), and
`vignettes/ANZTOX_data_processing.qmd` first. Found the exact connection
parameters in `data-raw/anztox/DATASET.R` (lines 168–198):
`RPostgres::Postgres()`, `dbname = "infogathering"`, `host = "localhost"`,
`port = 5432`, `user = "postgres"`, password via
`Sys.getenv("ANZTOX_DB_PASSWORD")` falling back to
`keyring::key_get("infogathering_postgres", username = "postgres")`.
Confirmed PostgreSQL was reachable on `localhost:5432` before attempting
R, then located R 4.5.1 at `C:\Program Files\R\R-4.5.1\bin\Rscript.exe`
(not on PATH) and wrote a read-only audit script,
`scripts/alldata/stage4a-supplementary-db-audit.R`, using the identical connection
block. The connection succeeded.

Ran the four requested queries (`concentrationcode` full content;
`toxicityvalue2000`/`toxicityvalue2016` schema plus distinct values for
all unit/conc-flagged columns; `testtype` full content; `majorgroup`
distinct values, confirming via `DATASET.R`'s own join that this is a
plain text column on `species`, not a separate lookup table). Then went
beyond the literal query list once `dbListTables()` revealed a
`concentrationunit` table not mentioned in the task brief: investigated
whether it relates to `concentrationused` (it does not directly — it's
keyed off the raw `toxicityvalue.concentration` field one join away) and
ran an empirical check — comparing `concentrationused` against the raw
`concentration` value, grouped by the raw value's tagged unit and by
dataset (2000 vs 2016) — to test whether the assumed µg/L convention
actually holds. This produced a materially more nuanced answer than a
flat "confirmed: µg/L": strong confirmation for the 86% of anztox data
from `toxicityvalue2000` (where 99.77% of raw concentrations are tagged
`ug/L` and `concentrationused` tracks them almost exactly), but no clean
confirmation for the 14% from `toxicityvalue2016` (heterogeneous,
non-`ug/L`-coded raw units with no consistent ratio pattern to
`concentrationused`). Also ran a follow-up join (`species` →
`toxicityvalue` → `toxicityvalue2000`/`2016`) to test the original audit's
hypothesis that the `majorgroup` full-taxonomic-name vocabulary came
specifically from the 2016 dataset — found this hypothesis was **not**
supported: both 2-letter-code and full-name styles occur substantially
within both 2000-referenced and 2016-referenced species, since both
datasets join the same shared `species` table by the same foreign key:
the inconsistency is internal to `species` itself, not a function of
which year's toxicity table references a row. Consolidated three
exploratory scripts into the single
`scripts/alldata/stage4a-supplementary-db-audit.R`, re-ran it end-to-end to
confirm full reproducibility, then wrote up all findings (connection
outcome, four requested query results, the unconfirmed-units nuance, and
the corrected majorgroup explanation) as the "Supplementary DB query"
section above, followed by this prompt log entry appended to the same
file. No `DATASET.R`, `.rda`, or source CSV files were read for write
purposes or modified at any point; the only files created were this
report's new section and the read-only audit script.

---
