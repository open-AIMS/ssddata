# The five source families each ship per-chemical objects plus an aggregate
# `{prefix}_data` object. Nothing previously guarded that the two stay in
# step, so a per-chemical dataset could be rebuilt (or added, as the ANZG set
# regularly is) while its aggregate went stale. These tests assert the
# aggregate is exactly the union of its components.

test_that("each source family ships an aggregate plus at least one component", {
  items <- shipped_items()
  for (p in source_families) {
    expect_true(paste0(p, "_data") %in% items, label = paste0(p, "_data exists"))
    expect_gt(length(family_components(p)), 0L)
  }
})

test_that("aggregate row count equals the sum of its component datasets", {
  for (p in source_families) {
    comps <- family_components(p)
    n_comp <- sum(vapply(comps, function(x) nrow(pkg_data(x)), integer(1)))
    expect_identical(
      nrow(pkg_data(paste0(p, "_data"))),
      n_comp,
      label = paste0(p, "_data rows vs sum of components")
    )
  }
})

test_that("every component Conc value is present in its aggregate", {
  # Row counts alone would not catch a component being rebuilt with different
  # values, so match on the concentrations themselves. Rounded to guard
  # against build-time floating-point drift.
  for (p in source_families) {
    agg <- round(pkg_data(paste0(p, "_data"))$Conc, 10)
    for (cc in family_components(p)) {
      comp <- round(pkg_data(cc)$Conc, 10)
      expect_true(
        all(comp %in% agg),
        label = paste("all", cc, "Conc values present in", paste0(p, "_data"))
      )
    }
  }
})

test_that("every component species is present in its aggregate", {
  for (p in setdiff(source_families, "anon")) {
    agg <- pkg_data(paste0(p, "_data"))$Species
    for (cc in family_components(p)) {
      expect_true(
        all(pkg_data(cc)$Species %in% agg),
        label = paste("all", cc, "species present in", paste0(p, "_data"))
      )
    }
  }
})

test_that("aggregates carry a Chemical column that components identify by name", {
  # Component objects are named {prefix}_{chemical}_{medium} and drop the
  # Chemical column; the aggregate re-adds it. Every aggregate Chemical value
  # must therefore be traceable to at least one component name.
  for (p in setdiff(source_families, "anon")) {
    agg <- pkg_data(paste0(p, "_data"))
    expect_true("Chemical" %in% names(agg), label = paste0(p, "_data has Chemical"))
    comps <- family_components(p)
    for (chem in unique(agg$Chemical)) {
      # Case-insensitive: ccme uses "Boron" where the object is ccme_boron,
      # and anzg_chromium_III_fresh keeps the roman numeral capitalised.
      token <- tolower(gsub("[^A-Za-z0-9]+", "_", chem))
      expect_true(
        any(grepl(token, tolower(comps), fixed = TRUE)),
        label = paste0("chemical '", chem, "' in ", p, "_data has a component dataset")
      )
    }
  }
})

test_that("anzg_data preserves the three hardness freshwater variants", {
  # Collapsing these to plain "freshwater" would silently merge three
  # separate ANZG guideline datasets (CLAUDE.md section 7: never collapse).
  anzg <- pkg_data("anzg_data")
  nitrate <- anzg[anzg$Chemical == "nitrate", ]
  expect_setequal(
    unique(nitrate$Medium),
    c("Soft freshwater", "Moderate freshwater", "Hard freshwater")
  )
  expect_identical(nrow(pkg_data("anzg_nitrate_soft_fresh")), 14L)
  expect_identical(nrow(pkg_data("anzg_nitrate_moderate_fresh")), 11L)
  expect_identical(nrow(pkg_data("anzg_nitrate_hard_fresh")), 12L)
})

test_that("component datasets omit the columns their name already encodes", {
  # Per-chemical objects encode chemical (and medium, for aims/anzg/csiro) in
  # the object name, so carrying the column too would be redundant and could
  # drift out of step with the name.
  for (p in c("aims", "anzg", "csiro")) {
    for (cc in family_components(p)) {
      expect_false(
        "Chemical" %in% names(pkg_data(cc)),
        label = paste(cc, "has no redundant Chemical column")
      )
    }
  }
})
