# allchronic_data is the output of the whole Issue #33 pipeline (Stages 1-7)
# and was previously tested only indirectly, through two ssd_data_sets()
# assertions. These tests pin its schema, its controlled vocabularies and the
# structural invariants the pipeline is documented to guarantee (CLAUDE.md
# sections 5-7), so a rebuild that quietly changes the aggregation, priority
# or pooling rules is caught here rather than downstream in ssdtools.
#
# Row/set counts are deliberately pinned. They are the pipeline's headline
# reproducibility figures; a change to any of them should be a reviewed,
# reported change, not an incidental one.

test_that("allchronic_data has the documented shape", {
  expect_s3_class(allchronic_data, "tbl_df")
  expect_identical(nrow(allchronic_data), 26501L)
  expect_identical(ncol(allchronic_data), 24L)
  expect_identical(
    names(allchronic_data),
    c(
      "Species", "Conc", "Chemical", "CAS", "Medium", "Source", "ValueTier",
      "AnyChronicConvApplied", "EffectCategory", "Class", "Kingdom", "Phylum",
      "Order", "Family", "Genus", "TaxonomyProvenance", "NRecords",
      "SourcesContributing", "AnyAcrApplied", "AnyConcFlagged",
      "GeomeanFlagged", "LifestageMixed", "DurationMixed", "Set"
    )
  )
})

test_that("allchronic_data column types are as expected", {
  chr <- c(
    "Species", "Chemical", "Medium", "Source", "ValueTier", "EffectCategory",
    "Class", "Kingdom", "Phylum", "Order", "Family", "Genus",
    "TaxonomyProvenance", "SourcesContributing", "Set"
  )
  lgl <- c(
    "AnyChronicConvApplied", "AnyAcrApplied", "AnyConcFlagged",
    "GeomeanFlagged", "LifestageMixed", "DurationMixed"
  )
  for (nm in chr) {
    expect_true(is.character(allchronic_data[[nm]]), label = paste(nm, "is character"))
  }
  for (nm in lgl) {
    expect_true(is.logical(allchronic_data[[nm]]), label = paste(nm, "is logical"))
    expect_false(any(is.na(allchronic_data[[nm]])), label = paste(nm, "has no NA"))
  }
  expect_true(is.numeric(allchronic_data$Conc))
  expect_true(is.integer(allchronic_data$NRecords))
  # NOTE: CAS is documented in R/allchronic_data.R as character but is built
  # numeric. Pinned as-is; changing it is a build decision, not a test fix.
  expect_true(is.numeric(allchronic_data$CAS))
  expect_false(any(is.na(allchronic_data$CAS)))
})

test_that("allchronic_data headline counts are unchanged", {
  expect_identical(length(unique(allchronic_data$Set)), 1520L)
  expect_identical(length(unique(allchronic_data$Chemical)), 1175L)
  expect_identical(length(unique(allchronic_data$Species)), 2796L)
})

test_that("Conc is positive and finite", {
  expect_false(any(is.na(allchronic_data$Conc)))
  expect_true(all(is.finite(allchronic_data$Conc)))
  expect_true(all(allchronic_data$Conc > 0))
})

test_that("Species is never NA, empty or a coined placeholder", {
  # Stage 6 decision S6-D4: curated rows with no species name are dropped at
  # load rather than given a placeholder taxon.
  expect_false(any(is.na(allchronic_data$Species)))
  expect_false(any(trimws(allchronic_data$Species) == ""))
  expect_false(any(grepl("^(sp\\.|unknown|placeholder|NA)$", allchronic_data$Species, ignore.case = TRUE)))
})

test_that("Set x Species is a unique key", {
  # Each set must hold one value per species: the geomean is applied at build
  # time, so ssd_data_sets() finds nothing left to collapse at runtime.
  key <- paste(allchronic_data$Set, allchronic_data$Species, sep = "\r")
  expect_identical(anyDuplicated(key), 0L)
})

test_that("controlled vocabularies are respected", {
  expect_setequal(
    unique(allchronic_data$Source),
    c("anzg", "ccme", "aims", "csiro", "uncurated")
  )
  expect_setequal(
    unique(allchronic_data$ValueTier),
    c("accepted", "chronic_converted", "acute_acr", "curated")
  )
  expect_setequal(
    unique(allchronic_data$Medium),
    c(
      "Freshwater", "Marine", "Unknown",
      "Soft freshwater", "Moderate freshwater", "Hard freshwater"
    )
  )
  expect_true(all(
    allchronic_data$EffectCategory[!is.na(allchronic_data$EffectCategory)] %in%
      c("MORT", "IMM", "GRO", "DVP", "POP", "REP", "HAT", "ABD")
  ))
  expect_setequal(
    unique(allchronic_data$TaxonomyProvenance),
    c(
      "worms_full", "gbif_full", "ambiguous_partial", "source_native_fallback",
      "manual_genus_fallback", "curated_source"
    )
  )
})

test_that("source composition is unchanged", {
  expect_identical(
    as.integer(table(allchronic_data$Source)[c("aims", "anzg", "ccme", "csiro", "uncurated")]),
    c(20L, 563L, 98L, 60L, 25760L)
  )
  expect_identical(
    as.integer(table(allchronic_data$ValueTier)[
      c("accepted", "acute_acr", "chronic_converted", "curated")
    ]),
    c(6360L, 16703L, 2697L, 741L)
  )
})

test_that("ValueTier 'curated' identifies exactly the curated-source rows", {
  # Provenance Option A: curated rows bypass the Stage 4e statistic-type
  # hierarchy entirely, so the tier and the source must agree row for row.
  expect_identical(
    allchronic_data$ValueTier == "curated",
    allchronic_data$Source != "uncurated"
  )
})

test_that("curated rows carry no uncurated aggregation artefacts", {
  cur <- allchronic_data[allchronic_data$Source != "uncurated", ]
  expect_gt(nrow(cur), 0L)
  expect_false(any(cur$AnyAcrApplied))
  expect_false(any(cur$AnyChronicConvApplied))
  expect_false(any(cur$AnyConcFlagged))
  expect_false(any(cur$GeomeanFlagged))
  expect_false(any(cur$LifestageMixed))
  expect_false(any(cur$DurationMixed))
  # Curated rows do not pass through Stage 4e, so no endpoint was selected.
  expect_true(all(is.na(cur$EffectCategory)))
  expect_identical(sum(is.na(allchronic_data$EffectCategory)), nrow(cur))
  # SourcesContributing is the single source name for curated rows.
  expect_identical(cur$SourcesContributing, cur$Source)
})

test_that("NRecords is 1 for curated rows apart from the known csiro geomean", {
  # Within-source species duplicates in aims/csiro are geomeaned at build time
  # rather than dropped (CLAUDE.md section 6, Change 1), so exactly one curated
  # row legitimately aggregates two records. The doc entry for NRecords says
  # "always 1" for curated rows; this pins the real exception.
  cur <- allchronic_data[allchronic_data$Source != "uncurated", ]
  exception <- cur[cur$NRecords != 1L, ]
  expect_identical(nrow(exception), 1L)
  expect_identical(exception$Species, "Desmodesmus spinosus")
  expect_identical(exception$Source, "csiro")
  expect_identical(exception$NRecords, 2L)
  expect_true(all(allchronic_data$NRecords >= 1L))
})

test_that("uncurated rows list only known contributing sources", {
  unc <- allchronic_data[allchronic_data$Source == "uncurated", ]
  contributors <- unique(unlist(strsplit(unc$SourcesContributing, ",")))
  expect_setequal(trimws(contributors), c("anztox", "wqbench", "envirotox"))
})

test_that("Set keys are sanitised chemical_medium tokens", {
  sets <- unique(allchronic_data$Set)
  expect_true(all(grepl("^[a-z0-9_]+$", sets)))
  suffixes <- c(
    "_freshwater$", "_marine$", "_mixed$",
    "_soft_freshwater$", "_moderate_freshwater$", "_hard_freshwater$"
  )
  matched <- Reduce(`|`, lapply(suffixes, function(p) grepl(p, sets)))
  expect_true(all(matched), label = "all Set keys end in a known medium token")
})

test_that("each Set maps to exactly one chemical", {
  by_set <- tapply(allchronic_data$Chemical, allchronic_data$Set, function(x) length(unique(x)))
  expect_true(all(by_set == 1L))
  by_cas <- tapply(allchronic_data$CAS, allchronic_data$Set, function(x) length(unique(x)))
  expect_true(all(by_cas == 1L))
})

test_that("real-medium sets hold only their own medium; mixed sets may pool", {
  real <- allchronic_data[!grepl("_mixed$", allchronic_data$Set), ]
  n_medium <- tapply(real$Medium, real$Set, function(x) length(unique(x)))
  expect_true(all(n_medium == 1L), label = "standalone sets are single-medium")
})

test_that("the Set medium token matches the rows' Medium", {
  real <- allchronic_data[!grepl("_mixed$", allchronic_data$Set), ]
  expected_token <- c(
    "Freshwater" = "_freshwater",
    "Marine" = "_marine",
    "Soft freshwater" = "_soft_freshwater",
    "Moderate freshwater" = "_moderate_freshwater",
    "Hard freshwater" = "_hard_freshwater"
  )
  ok <- mapply(
    function(set, medium) endsWith(set, expected_token[[medium]]),
    real$Set,
    real$Medium
  )
  expect_true(all(ok))
})

test_that("ANZG freshwater hardness variants are emitted as separate sets", {
  sets <- unique(allchronic_data$Set)
  expect_true(all(
    c(
      "nitrate_soft_freshwater",
      "nitrate_moderate_freshwater",
      "nitrate_hard_freshwater"
    ) %in% sets
  ))
  hardness <- allchronic_data[
    allchronic_data$Medium %in%
      c("Soft freshwater", "Moderate freshwater", "Hard freshwater"),
  ]
  expect_setequal(unique(hardness$Source), "anzg")
})

test_that("marine chlorine is excluded as short_term while other chlorine media are kept", {
  # Validation V13: the ANZG/CSIRO marine chlorine records are short-term and
  # are filtered after the source-priority gates, so no chlorine_marine set
  # may be emitted, while the uncurated freshwater/unknown data survive.
  sets <- unique(allchronic_data$Set)
  expect_false("chlorine_marine" %in% sets)
  expect_true(all(c("chlorine_freshwater", "chlorine_mixed") %in% sets))

  chlorine <- allchronic_data[grepl("^chlorine_", allchronic_data$Set), ]
  expect_false(any(chlorine$Medium == "Marine"))
  expect_setequal(unique(chlorine$Source), "uncurated")
})

test_that("a higher-priority curated source is never mixed with another source", {
  # Source priority anzg > ccme > aims > csiro > uncurated excludes wholesale
  # at chemical x medium for anzg and ccme; aims/csiro reconcile species-wise
  # and so may legitimately co-occur with uncurated rows.
  key <- paste(allchronic_data$CAS, allchronic_data$Medium, sep = "\r")
  srcs <- tapply(allchronic_data$Source, key, function(x) sort(unique(x)))

  wholesale <- vapply(
    srcs,
    function(x) any(c("anzg", "ccme") %in% x) && length(x) > 1L,
    logical(1)
  )
  expect_identical(sum(wholesale), 0L)

  # aims and ccme never share a chemical x medium with each other either.
  both_curated <- vapply(
    srcs,
    function(x) sum(c("aims", "csiro", "anzg", "ccme") %in% x) > 1L,
    logical(1)
  )
  expect_identical(sum(both_curated), 0L)
})

test_that("uncurated-only sets meet the >=5 species / >=4 class sufficiency bar", {
  # Stage 7 eligibility. Curated-backed sets bypass sufficiency by design.
  srcs <- tapply(allchronic_data$Source, allchronic_data$Set, function(x) unique(x))
  uncurated_only <- names(srcs)[vapply(srcs, function(x) identical(x, "uncurated"), logical(1))]
  expect_gt(length(uncurated_only), 1000L)

  sub <- allchronic_data[allchronic_data$Set %in% uncurated_only, ]
  n_spp <- tapply(sub$Species, sub$Set, function(x) length(unique(x)))
  n_cls <- tapply(sub$Class, sub$Set, function(x) length(unique(x[!is.na(x)])))
  expect_true(all(n_spp >= 5L), label = "uncurated-only sets have >=5 species")
  expect_true(all(n_cls >= 4L), label = "uncurated-only sets span >=4 classes")
})

test_that("every emitted set has at least five species", {
  n_spp <- tapply(allchronic_data$Species, allchronic_data$Set, function(x) length(unique(x)))
  expect_gte(min(n_spp), 5L)
})

test_that("mixed and standalone sets do not share species, bar one known chemical", {
  # CLAUDE.md section 6: a species placed in an emitted real-medium set is
  # stripped from that chemical's mixed pool (DATASET.R step C6.5). One
  # chemical currently breaches this - imidacloprid has viable freshwater AND
  # marine sets yet still emits a mixed set sharing six species with them,
  # which the documented "option (a)" rule says should not happen. Pinned as a
  # single known exception so the breach cannot spread silently and this test
  # turns red once the pipeline is corrected.
  kind <- ifelse(grepl("_mixed$", allchronic_data$Set), "mixed", "real")
  key <- paste(allchronic_data$Chemical, allchronic_data$Species, sep = "\r")
  n_kinds <- tapply(kind, key, function(x) length(unique(x)))
  offenders <- names(n_kinds)[n_kinds > 1L]
  chemicals <- unique(vapply(strsplit(offenders, "\r"), `[`, character(1), 1L))

  expect_identical(length(offenders), 6L)
  expect_identical(
    chemicals,
    "Imidacloprid;N-{1-[(6-Chloropyridin-3-yl)methyl]imidazolidin-2-ylidene}nitramide"
  )
})
