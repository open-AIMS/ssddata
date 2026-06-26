# Stage 4d Part 2 Fixup -- Manual Name Corrections Report

Generated: 2026-06-26 16:50:29 AWST

Human domain review of the `no_taxonomy` residual (15 species, see
`stage4d-part2-fallback-report.md` Section 3) identified 3 species worth
a manual correction pass: 2 anztox data-entry errors (misspelling; reversed
genus/species order) and 1 genuinely valid-but-backbone-absent name.

## Corrections applied

| scientificname | manual_corrected_query_name | status | taxonomy_provenance | accepted_name | resolved_kingdom | resolved_phylum | resolved_class | resolved_order | resolved_family | resolved_genus |
|---|---|---|---|---|---|---|---|---|---|---|
| Hizikia fusiforme | Sargassum fusiforme | exact_filtered | worms_full | Sargassum fusiforme | Chromista | Ochrophyta | Phaeophyceae | Fucales | Sargassaceae | Sargassum |
| Guignotus japonicus | Hydroglyphus japonicus | gbif_resolved | gbif_full | Hydroglyphus japonicus | Animalia | Arthropoda | Insecta | Coleoptera | Dytiscidae | Hydroglyphus |
| Echinisca triserialis | Macrothrix triserialis | gbif_resolved | gbif_full | Macrothrix triserialis | Animalia | Arthropoda | Branchiopoda | Diplostraca | Macrothricidae | Macrothrix |
| Eurycyclops agilis | Neocyclops agilis | gbif_resolved | gbif_full | Neocyclops | Animalia | Arthropoda | Copepoda | Cyclopoida | Halicyclopidae | Neocyclops |
| Illybius augustior | Ilybius augustior | gbif_resolved | gbif_full | Ilybius angustior | Animalia | Arthropoda | Insecta | Coleoptera | Dytiscidae | Ilybius |
| Odagmia ornata | Simulium ornatum | gbif_resolved | gbif_full | Simulium ornatum | Animalia | Arthropoda | Insecta | Diptera | Simuliidae | Simulium |
| Salmoides micropterus | Micropterus salmoides | exact_filtered | worms_full | Micropterus salmoides | Animalia | Chordata | Teleostei | Centrarchiformes | Centrarchidae | Micropterus |
| Sphaerodema annulatum | Diplonychus annulatus | gbif_resolved | gbif_full | Diplonychus annulatus | Animalia | Arthropoda | Insecta | Hemiptera | Belostomatidae | Diplonychus |
| Oxytrema catenaria | Pleurocera catenaria | gbif_resolved | gbif_full | Pleurocera catenaria | Animalia | Mollusca | Gastropoda | NA | Pleuroceridae | Pleurocera |
| Salmo gardieri | Oncorhynchus mykiss | exact_filtered | worms_full | Oncorhynchus mykiss | Animalia | Chordata | Teleostei | Salmoniformes | Salmonidae | Oncorhynchus |
| Sialis flavilatera | Sialis | unresolved | manual_genus_fallback | NA | Animalia | Arthropoda | Insecta | Megaloptera | Sialidae | Sialis |

## Notes

- `Illybius augustior` and `Salmoides micropterus` are now fully resolved
  (`gbif_resolved` / `exact_filtered`) and have dropped out of the problem-
  species set entirely.
- `Sialis flavilatera` keeps `status = "unresolved"` deliberately -- no
  species-level identity (`accepted_name`/`aphia_id`/`gbif_key`/
  `rank_resolved`) was fabricated, per this stage's no-fabrication rule.
  Only genus-level hierarchy was attached, from GBIF's own backbone genus
  record cross-confirmed via two independent queries. Tagged with a NEW
  `taxonomy_provenance` value, `manual_genus_fallback`, kept distinct from
  `source_native_fallback` (which specifically means the hierarchy came
  from the species' OWN data source, not an external cross-genus
  reference).
- **Ordering caveat:** re-running `stage4d-part2-source-native-fallback.R`
  after this script would relabel `Sialis flavilatera`'s
  `taxonomy_provenance` from `manual_genus_fallback` back to
  `source_native_fallback` (its idempotency check does not know about this
  new category) -- harmless to the hierarchy values themselves, but
  re-run this script again afterward to restore the more accurate label.
- **`read_csv()` trap for future readers:** the two new audit columns this
  script adds (`manual_corrected_query_name`, `manual_correction_note`) are
  NA for all but 3 of 4,348 rows, and those 3 rows fall past row 1000.
  `readr::read_csv()`'s default type-guesser only samples the first 1000
  rows, sees an all-NA sample for these columns, infers `logical`, and then
  silently turns the real string values it meets later into NA (with a
  parsing-mismatch warning easy to miss). Confirmed and fixed in this
  script's own reads via `guess_max = Inf`. Any future script (Stage 4d
  Part 3 included) that reads `species_resolution_v2.csv` with default
  `read_csv()` settings and then writes it back out would silently destroy
  this audit trail -- use `guess_max = Inf` (or explicit `col_types`) when
  reading this file going forward.

