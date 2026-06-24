# Stage 4c, Part 1 — Schema Inventory for Duplicate Detection
Date: 2026-06-24

Read-only investigation only — no data files, scripts, or `DATASET.R`
files were modified to produce this report. No `wqb_aggregate()` or any
aggregation function was called. No vocabulary harmonisation or
extraction code was written. Three companion read-only scripts were
created for reproducibility, mirroring the convention established by
`scripts/stage4a-supplementary-db-audit.R`:

- `scripts/stage4c-anztox-db-inventory.R` — live DB queries (Windows
  Positron only, requires `infogathering` PostgreSQL connection)
- `scripts/stage4c-wqbench-inventory.R` — loads
  `data-raw/wqbench/ecotox_ascii_12_11_2025.rds` (the file `DATASET.R`
  currently uses; the newer `ecotox_ascii_06_11_2026.rds` was **not**
  touched)
- `scripts/stage4c-envirotox-inventory.R` — loads
  `data-raw/envirotox/envirotox.xlsx`, sheet `test`, via
  `readxl::read_excel()`

The goal is a field-level comparison across anztox, wqbench, and
envirotox, scoped specifically to the five duplicate-detection
dimensions named in the task brief: test statistic type, effect/endpoint
category, numeric duration, duration unit, life stage, and study/
reference identifier. This directly informs a revised Stage 4b common
schema and the Stage 4c Part 2 dedup keys.

**Editorial note on large lookup-table dumps:** three anztox lookup
tables (`endpoint`, 692 rows; `age`, 534 rows; `duration`, 272 rows) are
too large to usefully paste in full into this document. For each, the
full distinct-value set is reproducible by re-running
`scripts/stage4c-anztox-db-inventory.R`; this report instead gives the
row count, the structurally-relevant controlled-vocabulary subset (where
one exists), and a representative sample. All *smaller* lookup tables
(≤130 rows) are reproduced here in full.

---

## Step 1 — anztox DB schema inventory

Connected successfully using the exact parameters from
`data-raw/anztox/DATASET.R`: `RPostgres::Postgres()`,
`dbname = "infogathering"`, `host = "localhost"`, `port = 5432`,
`user = "postgres"`.

Before querying, the ANZTOX C# domain model source already checked into
this repo (`data-raw/anztox/raw/ANZTOX database/src/TAG.Domain/`) was
read in full. This turned out to be decisive: it documents an `Effect`
lookup table explicitly described in code comments as "Should contain
values like EC10 (10% effect concentration)" — i.e. a **statistic-type**
table, structurally distinct from the `Endpoint` table that anztox's
existing `endpoint` field (MORT/GRO/IMM/...) is drawn from. Per
`ToxicityValueMap.cs`, both the base `toxicityvalue.effect_id` and the
2000-specific `toxicityvalue2000.effectused_id` reference this table.
Neither is currently joined into `core_cols` in `DATASET.R` — both are
read in (`lu_effect <- dbReadTable(con_local, "effect")`) and joined for
the 2000 build, but dropped before the final `select(any_of(core_cols))`
step; for 2016 the join never happens at all. This was the lead that
shaped most of the targeted queries below.

### 1a/1b — `toxicityvalue`, `toxicityvalue2000`, `toxicityvalue2016` full column lists

**`toxicityvalue`** (base table, shared by both subclasses via
`toxicityvalue_id`):

| column_name | data_type |
|---|---|
| id | integer |
| concentration | text |
| chemical_id | integer |
| species_id | integer |
| duration_id | integer |
| durationunit_id | integer |
| durationhour_id | integer |
| effect_id | integer |
| endpoint_id | integer |
| concentrationunit_id | integer |

**`toxicityvalue2000`**:

| column_name | data_type |
|---|---|
| toxicityvalue_id | integer |
| concentrationused | numeric |
| convnoec | numeric |
| hardnesscorrectedconc | numeric |
| temperature | text |
| ph | text |
| hardness | text |
| salinity | text |
| totalammoniamg | numeric |
| totalammoniaph8 | numeric |
| mediatype_id | integer |
| testtype_id | integer |
| effectused_id | integer |
| exposuretype_id | integer |
| concentrationcode_id | integer |
| concentrationtype_id | integer |
| reference_id | integer |
| status_id | integer |

**`toxicityvalue2016`**:

| column_name | data_type |
|---|---|
| toxicityvalue_id | integer |
| record | text |
| datasource | text |
| ischronic | boolean |
| concentrationused | numeric |
| mediatype_id | integer |
| age_id | integer |
| endpointfrompaper_id | integer |
| endpointmeasurement_id | integer |
| guidelinegroup_id | integer |

Note `toxicityvalue2000` has **no** `age_id` column at all (confirmed
directly against its schema) — life stage is structurally absent for
2000, not merely unpopulated.

### Candidate column distinct values

**`effect` table — full content (130 rows).** This is the table
flagged by the C# model as the statistic-type lookup:

LC50, EC50, LOEC, NOEC, MATC, IC50, LTC, TLm, LD50, LT50, NOEL, EC10,
LC10, LOEL, LC1, EC77.2, EC88.7, EC89.4, EC95.4, EC90, LC95, LC100, LC70,
LC0, LC22.8, LC32, LC4.4, LC35.2, LC4.8, LC90, LC15, ET50, EC20, LC20,
EC5, EC44.7, EC26.8, EC0, EC34.3, EC19.6, BEC10, MDEC, EC29, EC83, EC47,
ED50, TL96, IC25, IC90, ILL, LC84, LC16, MEC, MLT, LC60, LC40, LC30,
LC66, LC33, LC57.5, LC80, LC56, LC78, LC89, IC73, EC31, EC9, EC24, EC30,
EC45, EC18, EC36, EC16, EC27, EC6, EC14, EC38, EC41, EC23, EC4, EC15,
I50, I90, EC25, NOLC, IC10, LC02, LC05, LC48, LC88, LC12, LC37, LC76,
LC75, LC98, LC97, LC68, LC51, LC53, LC26, LC11, LC18, LC82, LC79, LC81,
LC91, LBC50, LEC50, <LC10, LC35, LC87, EC80, EA25, EA50, ABN, LOAEC,
EC05, NOAEL, LOAEL, LC25, IC20, EC58, EC1, EC53, NO, IC7, EC2.71, EC2.52,
EC6.99, NOAEC (130 distinct values total).

**Population of `effect_id` / `endpoint_id` / duration-related FKs on
the base `toxicityvalue` table:**

| | n_total | effect_id | endpoint_id | duration_id | durationunit_id | durationhour_id |
|---|---|---|---|---|---|---|
| all anztox-referenced rows | 29234 | 29221 (99.96%) | 29080 | 29036 | 29050 | 21504 |
| 2000 only | 17755 | 17754 (99.99%) | 17642 | 17630 | 17636 | 17630 |
| 2016 only | 2794 | 2794 (100%) | 2793 | 2794 | 2794 | **0** |

**Distinct `effect_id` values actually used (joined to `effect.name`),
by dataset** — this is the empirical confirmation that the statistic-
type field is real, populated, and currently unused:

2000 (14 distinct, n=17755): LC50 13650, NOEC 1936, EC50 1706, LOEC 207,
MATC 143, LC10 34, EC20 28, IC50 25, LD50 10, EC10 5, LC20 5, LT50 3,
LC30 2, NA 1.

2016 (35 distinct, n=2794): LC50 735, EC50 717, NOEC 436, LOEC 315, NOEL
252, EC10 124, IC50 46, EC05 31, IC25 21, LOEL 18, NOAEL 18, LC10 15,
LOAEL 12, IC10 10, EC20 7, EC25 7, LOAEC 6, BEC10 3, NOAEC 3, MDEC 3,
IC20 3, NO 2, LC25 2, EC53 1, EC6.99 1, EC2.71 1, LC15 1, IC7 1, EC1 1,
EC58 1, EC2.52 1.

**`toxicityvalue2000.effectused_id` → `effect.name`** (this is the
"effectused" field already computed mid-pipeline in `DATASET.R` —
`left_join(lu_effect |> rename(effectused = name), by = c("effectused_id" = "id"))`
— but dropped before `core_cols`): 17754/17755 populated (99.99%); 11
distinct values: LC50 12769, NOEC 3261, EC50 1548, LOEC 70, MATC 37,
LC10 34, IC50 17, LD50 10, EC10 5, LT50 3, NA 1.

**`endpoint` table — 692 distinct rows total.** This is the field
`DATASET.R` already resolves into the retained `endpoint` column
(confirmed by the main Stage 4a audit's documented values). Two
structurally different subsets exist within it:

- A ~24-row controlled abbreviation subset, each with a genuine
  distinct `name`/`abbreviation` pair, matching exactly the abbreviated
  vocabulary already documented in `scripts/stage4a-pipeline-audit.md`:
  `MORT`/Mor, `IMM`/Imm, `REP`/Rep, `GRO`/Gro, `DVP`/Devp, `HAT`/Hatch,
  `ASM`/Asm (Bury — burying response), `BIOLUM`/Biolm, `14CO2 UPTAKE`/
  CO2up, `BIOMASS`/Biom, `PGR`/PopG, `O2PRODUCTION`/O2Pr,
  `FERTILISATION`/Fert, `ABN`/Abn, `EMR`/Emer (sic — table has both
  `Emer` under `EMR` and a separate `Emergence` row further down),
  `POP`/Nopop, `LUM`, `GLUCOSEUTILISATION`/Pgluc, plus `PSE`, `ABD`,
  `PSR`, `PRP` (no full-name counterpart seen in the sampled rows).
- ~530 long free-text rows from row ~121 onward where `name` and
  `abbreviation` are **identical strings** (e.g. row 123: both columns
  read `"Body length"`), almost all algae/plant/invertebrate
  growth-and-reproduction sub-measures (e.g. "Population: Growth rate
  (Chlorophyll-a flourescence)", "Reproduction: Number of broods per
  female", "Growth: Shell length"). These look like later, more granular
  endpoint descriptions (plausibly tied to the 2016 paper-level
  `endpointmeasurement_id`/`endpointfrompaper_id` fields) that were never
  given a separate short abbreviation.

**Duration / DurationUnit** (shared base-table fields, currently
**unused** by `DATASET.R` for either 2000 or 2016):

`duration` table: 272 distinct rows, plain numeric-as-text hour values
(e.g. `0.5, 1, 2, 3, 4, 7, 10, 24, 48, 72, 96, 168, 192, 216, 240, 336,
480, 504, 672, ...` up to `7200`). Full list reproducible via the
companion script.

`durationunit` table — full content (8 rows): `Minutes`, `Hours`,
`Days`, `Months`, `Weeks`, `D`, `Year`, `H`.

Distinct `duration_id` values used, by dataset (top values; 2000, n =
17755 total, `<NA>` = 125): 96 hrs (7917), 48 hrs (5161), 72 hrs (1171),
24 hrs (633), 168 hrs (468), 672 hrs (342), 192 hrs (198), 504 hrs (167),
336 hrs (154), then a long tail down to single-digit counts (60 distinct
values shown in the companion script's output; 2016 not separately
tabulated for raw `duration_id` value but covered via durationunit
below).

Distinct `durationunit_id` values used, by dataset:

| dataset | durationunit_name | n |
|---|---|---|
| 2000 | Hours | 17636 |
| 2000 | NA | 119 |
| 2016 | Hours | 1480 |
| 2016 | Days | 1056 |
| 2016 | D | 240 |
| 2016 | H | 16 |
| 2016 | Year | 2 |

i.e. **2000 is almost entirely already in hours** (99.3% Hours, 0.7%
unresolved), and **2016 is a genuine mix of Hours/Days/D/H/Year** — the
"D"/"H" single-letter codes are presumably abbreviated Days/Hours
duplicated under a different lookup row rather than a new unit, but this
was not independently verified against the source spreadsheets in this
session.

`durationhour_id` (a 2000-only convenience field, "appears to be
duration which is assumed to be in hours" per the C# model comment):
99.3% populated for 2000 (17630/17755, values matching `duration_id`'s
distribution almost exactly), **0% populated for 2016** (0/2794) —
confirming this field genuinely does not exist for 2016 records, not
just unpopulated by chance.

**Life stage (`age` table, 2016-only per the domain model — confirmed
empirically, `toxicityvalue2000` has zero `age`-named columns):**

`age` table: 534 distinct rows, almost entirely free text with no
controlled vocabulary (e.g. `"At least 1 well developed bud"`,
`"13 unidentified bacterial strains"`, weight/size ranges like
`"Adults, 0.1-0.2 g and 1.2-2 cm shell length"`, instar/larval stage
descriptions). Population: 2794/2794 (100%) of 2016 rows have an
`age_id`, but the distribution is dominated by two case-variant
placeholder values that should really be one category: `"Not stated"`
(1226) and `"Not-stated"` (134) — 1360/2794 = 48.7% combined — followed
by a long tail of genuine but mostly-unique life-stage descriptions
(`"Exponential Growth Phase"` 101, `"Exponential growth phase"` 86 — note
this is *also* a case-variant duplicate pair — `"Larvae"` 82,
`"Juvenile"` 63, `"<24 hr"` 59, `"Adult"` 48, `"Embryo"` 47, ...; most of
the remaining ~500 values occur 1–10 times each).

**Statistic table (suspected orphaned per the C# model) — confirmed
orphaned.** `statistic` exists in the DB (29 rows: `Probit`,
`Spearman-Karber`, `ANOVA and Dunnett's`, `Graphical`, `Microtox method`,
`Other`, `Moving average`, `Probit & Spearman-Karber`, `Regression`,
`Kruskal-Wallis`, `Interperlation`, `Dunnetts t-test`, `Anova`, `Dunnetts
t-test with Bonferroni adjustment`, `Bartletts test & t-test with
Bonferroni adjustment`, `ANOVA (tukeys)`, `Litchfield-Wilcoxon`,
`Bootstrap method`, `T-test`, `ANOVA & Fishers least significant
difference test`, `USEPA statistics protocols`, `Hoekstra & van Ewijk
(1993)`, `Fishers exact test`, `ANOVA and Kruskal-Wallis`,
`Spearman-Karber and Dunnett's multiple comparison`, `Linear regression
and Dunnett's`, `Polynomial regression`, `3-parameter sigmoidal
equation`, `NEFP`) but **no column on `toxicityvalue`,
`toxicityvalue2000`, or `toxicityvalue2016` references it** (the only
"stat"-matching column found, `status_id`, is an unrelated false-positive
match on the substring "stat"). This table describes the **statistical
analysis method** used to derive a value (e.g. Probit analysis), not the
test-statistic *type* (EC50/NOEC/etc.) — a genuinely separate concept
from what we need for dedup, and not usable for any of the five
dimensions.

**`concentrationtype`** — re-confirmed, not a statistic-type or dedup
field (derivation-method flag): `Measured`, `Nominal`, `Calculated`,
`QSAR` (4 rows).

**`exposuretype`** — flagged by the "type" name-pattern rule, 2000-only.
Full content (5 rows): `Flow-through`/F, `Semi-static`/SS, `Static`/S,
`Pulse`/P, `Pulse & static` (no abbreviation). Population on
`toxicityvalue2000`: only **53/17755 (0.3%)** — essentially unusable for
dedup purposes; almost every row is NA. Distinct values among the 53
populated rows: Static 20, Semi-static 17, Flow-through 16.

### 1d — Study/reference identifier

`reference` table schema: `id`, `orgrefnumber`, `authors`,
`authorsabbreviated`, `title`, `journal`, `year`, `volume`,
`issuenumber`, `firstpage`, `lastpage`.

`toxicityvalue2000.reference_id`: 17754/17755 populated (99.99%) — this
is already resolved into `reference_bib` and already retained in
`core_cols`/the final combined table.

`toxicityvalue2016`: **no `reference_id` FK at all.** Instead:
`datasource` 2727/2794 populated (97.6%), `record` 2794/2794 (100%).
Already documented in the vignette as resolving to only 0.79% bona fide
reference matches via the best-effort regex-to-`orgrefnumber` matcher.

**New finding: `guidelinegroup` (2016-only).** Schema: `id`,
`guidelinevalue`. 735 distinct groups across the full table.
`toxicityvalue2016.guidelinegroup_id`: **2794/2794 populated (100%)** —
every 2016 row belongs to a group of "several related toxicity Values...
processed... to create a final guideline value for that group" (per the
C# model comment on `GuidelineGroup.cs`). Top groups have between 18–42
member rows (e.g. group 641: 42 rows; group 648: 40; group 22: 36).
This field is **not used anywhere in `DATASET.R` and not mentioned in
the vignette** — it is not a literature reference, but it is a
genuine, fully-populated, pre-existing grouping signal for "these rows
were treated as belonging together" that could serve as a weak
study-identity proxy for 2016 records, where literal reference matching
fails 99%+ of the time.

---

## Step 2 — wqbench RDS schema inventory

Loaded `data-raw/wqbench/ecotox_ascii_12_11_2025.rds` directly (the file
`DATASET.R` currently uses). 361,817 rows × 24 columns.

### 2a — Full column inventory

| column | type | n_non_na | n_distinct |
|---|---|---|---|
| chemical_name | character | 361817 | 6007 |
| cas | character | 361817 | 6007 |
| latin_name | character | 361817 | 3806 |
| common_name | character | 361817 | 1653 |
| endpoint | character | 361817 | 55 |
| effect | character | 361817 | 23 |
| effect_conc_mg.L | numeric | 361817 | 23195 |
| lifestage | character | 361817 | 103 |
| duration_hrs | numeric | 361817 | 1002 |
| duration_class | character | 361817 | 2 |
| effect_conc_std_mg.L | numeric | 361817 | 25692 |
| acr | integer | 361817 | 3 |
| media_type | character | 361817 | 6 |
| trophic_group | factor | 361817 | 5 |
| ecological_group | factor | 361817 | 3 |
| species_present_in_bc | logical | 361817 | 2 |
| author | character | 361817 | 13435 |
| title | character | 361817 | 15044 |
| source | character | 361817 | 15015 |
| publication_year | character | 361817 | 78 |
| present_in_bc_wqg | logical | 361817 | 2 |
| species_number | integer | 361817 | 3807 |
| download_date | character | 361817 | 1 |
| version | character | 361817 | 1 |

Every column is 100% populated. None of the task brief's other named
candidates (`obs_duration_mean`, `obs_duration_unit`, `conc1_type`,
`reference_number`, `test_id`, `result_id`, `chemical_grade`) exist in
this RDS — `wqb_create_data_set()`'s internal pipeline has already
renamed/consumed them by the time this object is saved.

### 2b — Candidate column distinct values

**`endpoint` (statistic type) — full content, 55 distinct, 100%
populated:** EC05, EC10, EC15, EC16, EC18, EC20, EC22, EC25, EC30, EC31,
EC35, EC40, EC41, EC45, EC50, EC55, IC05, IC07, IC10, IC15, IC16, IC20,
IC25, IC30, IC40, IC50, LC05, LC06, LC07, LC08, LC09, LC10, LC13, LC15,
LC16, LC20, LC25, LC30, LC31, LC32, LC33, LC34, LC35, LC38, LC40, LC45,
LC50, LC51, LC55, LOEC, LOEL, MATC, MCIG, NOEC, NOEL.

**`effect` (effect/endpoint category) — full content, 23 distinct, 100%
populated:** Accumulation, Avoidance, Behavior, Biochemistry, Cell(s),
Development, Ecosystem process, Enzyme(s), Feeding behavior, Genetics,
Growth, Histology, Hormone(s), Immunological, Injury, Intoxication,
Morphology, Mortality, Multiple, Physiology, Population, Reproduction,
Unspecified.

**`duration_hrs`** — 1002 distinct, 100% populated, numeric. Top values:
96 (87821), 48 (46009), 24 (36654), 168 (18791), 504 (18190), 72
(16328), 336 (13358), 672 (12406), 120 (8355), 720 (7508), 240 (7216),
144 (3764), 360 (3666), 192 (3089), 1440 (2705), 1008 (2634), 288 (2577),
840 (2516), 6 (2373), 1344 (2344), 2160 (2242), 3 (1769), 12 (1729), 960
(1697), 480 (1648), 1 (1573), 384 (1573), 216 (1403), 768 (1285), 4
(1070), 264 (1008), 600 (993), 116 (950), 2 (866), 864 (815), 2880 (815),
36 (777), 1080 (739), 118 (727), 432 (693).

**`duration_class`** — `acute`, `chronic` (2 values, already known/used).

**`lifestage`** — 103 distinct, 100% populated, but `"Not reported"`
(144058, 39.8%) and `"Not coded"` (11521, 3.2%) are explicit
non-informative placeholders — combined, 43.0% of rows lack a genuine
life-stage value. The remaining 57% is a reasonably usable semi-
controlled vocabulary: `Adult` (32543), `Juvenile` (30241), `Larva`
(26510), `Embryo` (26472), `Exponential growth phase (log)` (14545),
`Neonate` (14429), `Egg` (7410), `Fingerling` (6729), `Tadpole` (6093),
`Fry` (4217), `Sexually mature` (2773), `Mature` (2658), `Not intact`
(2228), `Instar` (1947), `Nauplii` (1836), `Sperm` (1752), `Young`
(1549), `Multiple` (1479), `Nymph` (1218), `Immature` (1205),
`Intermolt` (1183), `Blastula` (1172), `Glochidia` (1162), `Shoot`
(1027), and a long tail of 80+ further rarer categories (e.g.
`New/newly/recent hatch`, `Post-larva`, `Eyed egg/embryo`, `Sac fry`,
`Young of year`, `Spat`, `Swim-up`, `Zoea`, `Yearling`, `Oocyte/ova`,
`Seedling`, `Alevin`, `Gamete`).

**`acr`** — 3 distinct values: 1, 5, 10 (already documented).

**Study/reference identifiers** — no `test_id`/`result_id`/
`reference_number` field exists in this RDS at all. Instead, four
separate, fully-populated literal bibliographic fields: `author`
(13,435 distinct), `title` (15,044 distinct), `source` (15,015 distinct
— journal/report citation strings), `publication_year` (78 distinct,
spanning 1978–2023). None of these four survive into the final
`wqbench_data.rda` (confirmed against the field list already documented
in `scripts/stage4a-pipeline-audit.md`) — they are present at the
pre-aggregation intercept and consumed/dropped by `wqb_aggregate()`.

### 2c — Field-removal duplicate count analysis

Full key: `cas, latin_name, media_type, endpoint, effect, lifestage,
duration_hrs`.

| Key | n_dup_groups |
|---|---|
| **Full key (7 fields)** | **57247** |
| drop `cas` | 35139 |
| drop `latin_name` | 52988 |
| drop `media_type` | 57265 |
| drop `endpoint` | **59805** |
| drop `effect` | 51662 |
| drop `lifestage` | 57752 |
| drop `duration_hrs` | 56630 |

Dropping `endpoint` (statistic type) produces the largest **increase**
relative to the full key (+2558, +4.5%) of any single field tested —
empirical confirmation that statistic type is the single most powerful
distinguishing field among the seven for wqbench, ahead of `lifestage`
(+505) and `media_type` (+18). The fields whose removal *decreases* the
count (`cas`, `latin_name`, `effect`, `duration_hrs`) are not "weak"
distinguishers in the usual sense — removing them merges what were
previously several separate same-cas/same-species duplicate groups into
fewer, larger ones (the count of *groups* falls even though more rows
end up sharing a group); they remain necessary identity fields
regardless.

---

## Step 3 — envirotox xlsx schema inventory

Loaded `data-raw/envirotox/envirotox.xlsx`, sheet `test`, via
`readxl::read_excel()` (80,912 rows × 17 columns), per the task brief.
**Note:** `DATASET.R` itself reads this sheet with `openxlsx::read.xlsx()`,
whose default `sep.names = "."` rewrites space/parenthesis-containing
headers with dots (e.g. `"Test statistic"` → `Test.statistic`).
`readxl` preserves the literal headers with spaces; this section uses
those literal names. It is the same underlying data either way.

### 3a — Full column inventory

| column | type | n_non_na | n_distinct |
|---|---|---|---|
| CAS | numeric | 67118 | 4150 |
| Chemical name | character | 80912 | 4260 |
| Latin name | character | 80912 | 1641 |
| Trophic Level | character | 80912 | 4 |
| Effect | character | 80912 | 113 |
| Effect value | numeric | 80912 | 7835 |
| Unit | character | 80912 | 1 |
| Test type | character | 80912 | 2 |
| Test statistic | character | 80912 | 44 |
| Duration | character | 80912 | 672 |
| Duration (days) | character | 80912 | 229 |
| Duration (hours) | character | 80912 | 224 |
| Effect is 5X above water solubility | numeric | 80912 | 2 |
| Source | character | 80912 | 10029 |
| version | character | 80912 | 1 |
| Reported chemical name | character | 80912 | 7545 |
| original CAS | numeric | 80912 | 4267 |

**Unexpected finding:** `original CAS` is already a **native column on
the `test` sheet itself** (100% populated, 4267 distinct), not something
that requires the `substance`-sheet `match()` lookup `DATASET.R`
performs (`mutate(original.CAS = EnviroTox_chem[match(.$CAS,
EnviroTox_chem$CAS), "original.CAS"])`). This was confirmed by attempting
to reproduce that join read-only in the companion script — it failed
with "Unknown or uninitialised column" because the `substance` sheet's
column is *also* space-named (`original CAS`, not `original.CAS`) under
`readxl`. Whether `DATASET.R`'s match()-derived value is identical to
this native column was **not** checked in this session (out of scope —
this is a pure inventory task) but is worth a quick follow-up before any
Stage 4b extraction work, since using the native column directly would
simplify the existing `DATASET.R` logic if the two are equivalent.

No life-stage column, no purity column, and no separate author/year
"Reference" field exist anywhere on this 17-column sheet — confirmed
directly against the full list above, not merely absent from
`DATASET.R`'s final `select()`.

### 3b — Candidate column distinct values

**`Test statistic`** — full content, 44 distinct, 100% populated: LC50
(48014), EC50 (18329), NOEC (9977), NOEL (1252), EC10 (1120), IC50
(585), MATC (398), LD50 (226), EC20 (189), IC25 (171), IC10 (139), IC20
(116), EC25 (93), LC70 (34), LC30 (32), LC10 (29), LC25 (29), LC60 (20),
LC40 (19), LC75 (19), LC50* (17), ER50 (15), EC50* (13), EC05 (11), IC40
(11), LC20 (11), LOEC (10), ED50 (4), EC16 (3), EC40 (3), LD30 (3), LD70
(3), LT50 (3), EL50 (2), IGC50 (2), NOLC (2), EC30 (1), IC07 (1), LC34
(1), LC38 (1), LC51 (1), `NEC (no effect concentration)` (1), NOAEC (1),
NOER (1).

**`Test type`** — `A` (67478), `C` (13434) — already known/used as the
acute/chronic filter.

**`Effect`** — 113 distinct, 100% populated. Top values: Mortality
(49138), Population (7178), Mortality/Growth (5231), Intoxication
(5220), Growth (4068), `Mortality, Mortality` (2410 — looks like a
duplicate-coded artefact, not a genuinely distinct category), Reproduction
(2023), `Immobilization: Change in the failure to respond or lack of
movement after mechanical stimulation.` (1208), `Population, Population
growth rate` (601), a full-sentence "Population Growth" definition
(536), `Intoxication, Immobile` (391), `Population, Abundance` (364),
Development (252), `Mortality, Survival` (232), plus a long tail of
~95 further categories, many of them full-sentence definitions rather
than short labels (consistent with the main Stage 4a audit's
characterisation of this field as "largely free-text").

**`Duration` / `Duration (days)` / `Duration (hours)`** — three
duration-related columns exist natively, none of them retained in any
final envirotox object today. `Duration` (672 distinct) is a free-text
composite (`"96 hours"`, `"4 days"`, `"2 Day(s)"` — note inconsistent
capitalisation/pluralisation between e.g. `"1 day"` and `"4 Day(s)"`).
`Duration (days)` and `Duration (hours)` are parallel pre-split numeric
values (229 / 224 distinct respectively) but are typed as **character**,
not numeric, in R — because a literal text `"NA"` (not a true `NA`)
appears as a value in some rows (91 occurrences in the sampled top-40 for
each column) alongside genuine numbers (`4`, `2`, `3`, `1`, `21`, `7`,
`5`, `28`, `14`, `6`, `30`, `32`, `10`, `35`, `90`, ...). These need a
`suppressWarnings(as.numeric(...))`-style coercion (treating the literal
`"NA"` string as missing) before they are usable as a numeric duration
field — a small, well-contained cleanup.

**`Source`** — 10,029 distinct, 100% populated. A single pre-built
citation-style string per row (author, year, title, journal/report
detail all concatenated), e.g. `"U.S. Environmental Protection Agency,
and Office of Pesticide Programs. Pesticide Ecotoxicity Database
(Formerly: Environmental Effects Database (EEDB))"` (3720 rows),
`"Mayer,F.L.,Jr., and M.R. Ellersieck. Manual of Acute Toxicity..."`
(3288 rows), down through a long tail of single-study citations. This is
the richest single-field reference identifier of the three sources (one
field, already combined, no matching/joining required) — but it is
**entirely dropped** before `envirotox_acute`/`envirotox_chronic` are
built, exactly like `Effect` and `Test statistic`.

**`Unit`** — constant `"mg/L"` for all 80,912 rows (already known).

**`Effect is 5X above water solubility`** — `0` (75682), `1` (5230) —
already known/used as the solubility filter.

**`original CAS`** — 4267 distinct, 100% populated (see "Unexpected
finding" above).

### 3c — Field-removal duplicate count analysis

Key fields available on the raw sheet: `original CAS, Latin name, Test
statistic, Effect, Duration (hours), Source`. (`Organism.lifestage` and
a separate `Reference` field from the task brief's suggested key do not
exist on this sheet — see 3a/3b.)

**Raw sheet (all 80,912 rows):**

| Key | n_dup_groups |
|---|---|
| **Full key (6 fields)** | **9253** |
| drop `original CAS` | 9782 |
| drop `Latin name` | 12721 |
| drop `Test statistic` | 10587 |
| drop `Effect` | 10634 |
| drop `Duration (hours)` | 12045 |
| drop `Source` | **12395** |

**After reproducing the actual `DATASET.R` statistic/type/solubility
filter (72,439 rows survive):**

| Key | n_dup_groups |
|---|---|
| **Full key (6 fields)** | **8280** |
| drop `original CAS` | 8797 |
| drop `Latin name` | 11305 |
| drop `Test statistic` | 9089 |
| drop `Effect` | 9519 |
| drop `Duration (hours)` | 10777 |
| drop `Source` | **11165** |

In both the raw and post-filter analyses, dropping **`Source`** produces
the largest increase in apparent-duplicate groups of any field tested
(+3142 raw, +2885 post-filter) — i.e. the study/reference identifier is
empirically the single most powerful distinguishing field for
envirotox, ahead of `Latin name` (species) and `Duration (hours)`. This
directly validates the task brief's framing that a study/reference
identifier "distinguishes two tests of the same type from different
labs or publications" — and it is currently the field most completely
discarded from envirotox's final output.

---

## Step 4 — Cross-source field comparison table

| Dimension | anztox field(s) | wqbench field(s) | envirotox field(s) | Harmonisable? |
|---|---|---|---|---|
| Test statistic type | `effect_id`/`effectused_id` → `effect.name` (2000: computed mid-pipeline, dropped before `core_cols`; 2016: never joined). Coded FK, ~100% populated both years. | `endpoint` — literal column, 100% populated, 55-value coded vocabulary, present at intercept, **dropped by `wqb_aggregate()`** before final output. | `Test statistic` — literal column, 100% populated, 44-value vocabulary; used only as a filter condition, never selected into final output. | **Partial** — dominant tokens (LC50/EC50/NOEC/NOEL/IC50/LOEC/MATC/LD50) shared across all three, but anztox's underlying `effect` lookup also has many idiosyncratic codes (EC77.2, BEC10, MDEC, ILL, NOAEC/NOAEL/LOAEC/LOAEL, TLm, ET50, ED50...) with no counterpart in the other two. |
| Effect/endpoint category | `endpoint` — coded FK to a 692-row table, but only a ~24-value controlled abbreviation subset (MORT/GRO/IMM/...) is actually exercised; **already retained** in final output. | `effect` — literal column, 23-value controlled vocabulary, 100% populated; **already retained** in final output. | `Effect` — literal column, 113-value largely-free-text vocabulary, 100% populated; **entirely dropped**, never selected into any final object. | **Partial** — anztox's and wqbench's controlled vocabularies overlap conceptually (Mortality/Growth/Reproduction/Development/...) and are mappable with a translation table; envirotox's free-text 113-value field needs substantially more cleanup before it could join the mapping. |
| Numeric duration | `duration_id`/`durationhour_id` → `duration.name` (hours, base table). 2000: 99.3% populated, already effectively in hours. 2016: 100% populated via `duration_id`, but **not** pre-converted to hours (`durationhour_id` is 0% populated for 2016). **Not used anywhere in `DATASET.R`.** | `duration_hrs` — literal numeric column, already in hours, 100% populated, 1002 distinct values. Present at intercept, **dropped by `wqb_aggregate()`**. | `Duration (hours)` — literal column, 224 distinct, 100% non-NA by R's count but contains a literal text `"NA"` token in a small number of rows; stored as character, needs numeric coercion. **Dropped**, never selected into final output. | **Yes** — genuine numeric duration recoverable for all three with modest, well-understood cleanup (anztox 2016 unit conversion for the ~46% of 2016 rows not already in Hours; envirotox character→numeric coercion). |
| Duration unit | `durationunit` lookup (`Minutes/Hours/Days/Months/Weeks/D/Year/H`) via `durationunit_id`. 2000: 99.3% Hours. 2016: Hours 53.0%, Days 37.8%, D 8.6%, H 0.6%, Year 0.1%. | Implicit — `duration_hrs` is pre-converted, no separate unit field exists or is needed. | Implicit via column choice (`Duration (days)` vs `Duration (hours)`) or embedded as text in the composite `Duration` column. | **Yes** (for the harmonised *outcome* — a single hours-based field — even though the three sources expose "unit" structurally differently: explicit lookup vs. pre-converted vs. column-name-encoded). |
| Life stage | `age_id` → `age.name`, **2016-only** (no equivalent column exists on `toxicityvalue2000` at all). 100% populated for 2016, but 48.7% of that is two case-variant placeholder values (`"Not stated"`/`"Not-stated"`); the rest is free text, 534 distinct values, almost no controlled vocabulary, mostly unique. | `lifestage` — literal column, 100% populated, 103-value semi-controlled vocabulary (Adult/Juvenile/Larva/Embryo/Neonate/...), but 43.0% is non-informative placeholder (`"Not reported"`/`"Not coded"`). | **No column exists at all** — confirmed against the full 17-column list. | **No** — envirotox has nothing to harmonise against; anztox's coverage is effectively ≤7% of all anztox rows once placeholders are excluded (13.6% of anztox is 2016, of which ~51% has a non-placeholder value). Only wqbench has a source-wide usable life-stage field. |
| Study/reference ID | 2000: `reference_id` → `reference` table (full bibliographic fields), 99.99% populated, **already** built into `reference_bib` and retained in final output. 2016: `datasource`/`record` free text, only 0.79% resolve to a real reference (documented in the vignette); **new finding** — `guidelinegroup_id`, 100% populated, 735 distinct groups, unused/undocumented, a weaker "related-records" grouping proxy. | `author` + `title` + `source` + `publication_year` — four separate literal fields, all 100% populated, very granular (up to 15044 distinct titles). Present at intercept, **dropped by `wqb_aggregate()`**. | `Source` — single combined citation string, 100% populated, 10029 distinct. **Empirically the single strongest distinguishing field** in the Step 3c duplicate analysis (both raw and post-filter). Currently **entirely dropped**. | **Partial** — every source has *some* literal reference signal pre-aggregation, but the structures are incompatible (FK'd bibliographic table vs. four free-text fields vs. one combined string vs. a numeric grouping ID) — usable for **within-source** dedup/audit trail, not for a literal cross-source join without fuzzy text matching (out of scope here). |

---

## Step 5 — Recommendations for the revised Stage 4b schema

### Recommended field additions

| Field name (proposed) | Source in anztox | Source in wqbench | Source in envirotox | Recommended for dedup key? |
|---|---|---|---|---|
| `statistic_type` | `effect.name` via `effect_id` (2000, already computed — just add to `core_cols`) / `effectused.name` via `effectused_id` (2000, already computed, arguably preferable — it is the curator-selected value, narrower 11-value vocabulary vs. raw 14) / **new** join via `effect_id` (2016, not yet wired up; base `toxicityvalue` table already provides the FK) | `endpoint` (already a literal column at the intercept — needs selecting **before** `wqb_aggregate()` runs, since `wqb_aggregate()` consumes it) | `Test statistic` (already a literal column — needs selecting into a revised extraction step; currently used only as a filter condition) | **Yes** — within-source for all three; cross-source Partial per Step 4 |
| `duration_hours` | `duration_id` + `durationunit_id` (2000: ~already hours via `durationhour_id`; 2016: needs unit conversion using `durationunit_id`) | `duration_hrs` (already hours — needs selecting pre-aggregation) | `Duration (hours)` (needs character→numeric coercion, treating literal `"NA"` as missing) | **Yes** — all three, harmonisable to one hours-based field |
| `effect_category` | `endpoint` (already retained; ~24-value controlled subset of the 692-row lookup) | `effect` (already retained; 23-value controlled vocabulary) | `Effect` (113-value, mostly free text; currently dropped — needs selecting, then a mapping/cleanup pass before it is usable cross-source) | **Yes** — within-source; cross-source Partial (translation table required, larger lift for envirotox) |
| `lifestage` | `age.name` via `age_id` (2016 only; 13.6% of anztox; flag the `"Not stated"`/`"Not-stated"` case-variant pair as one category before use) | `lifestage` (already a literal column — needs selecting pre-aggregation) | not available | **No** for a cross-source key (per Step 4); usable as a **within-source, optional/secondary** field for anztox (2016 subset only) and wqbench |
| `study_reference` | 2000: `reference_bib` (already built and retained). 2016: `datasource`/`record` (weak, ~0.79% resolvable) plus **new** `guidelinegroup_id` (100% populated grouping proxy) | `author` + `title` + `source` + `publication_year` (already literal fields — needs selecting pre-aggregation, before `wqb_aggregate()` drops them; could be concatenated into one string to match the other two sources' shape) | `Source` (already a single combined string — needs selecting; currently dropped) | **Yes** — within-source (and, per Step 3c, this is the *single strongest* distinguishing field for envirotox specifically); cross-source Partial (structurally incompatible, no literal join key) |

### Recommended within-source dedup keys

- **anztox**: `casnumber_grouped, mediatype, scientificname, endpoint
  (effect_category), statistic_type (new), duration_hours (new),
  reference_bib` (2000) / `guidelinegroup_id` (2016, in place of
  `reference_bib` given its near-total absence for 2016)
- **wqbench**: `cas, latin_name, media_type, endpoint (statistic_type,
  new pre-aggregation selection), effect, lifestage, duration_hrs (new
  pre-aggregation selection), author+title+source (new pre-aggregation
  selection)`. The Step 2c analysis already demonstrates this key's
  distinguishing power empirically (57,247 duplicate groups detected
  with a 7-field subset of this key on the full 361,817-row dataset).
- **envirotox**: `original CAS, Latin name, Test statistic, Effect,
  Duration (hours) (new), Source (new)`. The Step 3c analysis shows
  `Source` is the single most load-bearing field in this key for this
  source specifically.

### Recommended cross-source dedup key

Limited to fields marked **Yes** or **Partial** (with a translation
table) in Step 4 — i.e. excluding life stage entirely and treating
literal reference strings as a per-source audit trail rather than a
join key:

`casnumber_grouped (parent CAS) × species (scientificname/latin_name/
Latin.name) × medium × duration_hours × effect_category (mapped) ×
statistic_type (mapped)`

Fields present in two sources but unreliable/absent in the third (flag,
do not include in the cross-source key, but still populate per-source
where available):

- `lifestage` — wqbench (good coverage) + anztox (13.6%-of-anztox,
  partial coverage) but **absent from envirotox**
- `study_reference` — present in all three but **structurally
  incompatible** for a literal join (FK table vs. 4 free-text fields vs.
  1 combined string vs. a numeric grouping ID); retain per-source as an
  audit-trail/tie-breaker field, not a join key
- `exposuretype` (anztox, 2000-only, 0.3% populated) and `statistic`
  (anztox, fully orphaned, describes analysis method not statistic
  type) — investigated and ruled out; not recommended for any dedup use

---

## Prompt log

See `prompts/stage4c-dedup.md`.
