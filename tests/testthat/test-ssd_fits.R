# ssd_fits is the package's reference table of gazetted / previously published
# SSD fits. It had no schema test: test-units-consistency.R used it only as an
# oracle for the raw data. These tests cover the table in its own right, and
# in particular replace the heuristic HC-below-max unit check with a direct
# one - the Units column of a fit must equal the Units of the dataset it was
# fitted to. That is the exact invariant issue #47 violated.

test_that("ssd_fits has the documented shape", {
  expect_s3_class(ssd_fits, "tbl_df")
  expect_identical(ncol(ssd_fits), 13L)
  expect_identical(
    names(ssd_fits),
    c(
      "Dataset", "Filter", "Software", "Version", "Distribution", "PC",
      "Estimate", "SE", "Lower", "Upper", "Reference", "Notes", "Units"
    )
  )
  expect_identical(nrow(ssd_fits), 377L)
})

test_that("every ssd_fits Dataset is a data object shipped by the package", {
  # A fit referring to a renamed or removed dataset is unusable, and the
  # dataset naming roadmap (CLAUDE.md section 8) will rename objects.
  expect_true(all(unique(ssd_fits$Dataset) %in% shipped_items()))
  expect_true(is.character(ssd_fits$Dataset))
  expect_false(any(is.na(ssd_fits$Dataset)))
})

test_that("PC and Software use their expected vocabularies", {
  expect_setequal(unique(ssd_fits$PC), c(80, 90, 95, 99))
  expect_setequal(
    unique(ssd_fits$Software),
    c("Burrlioz", "ssdtools", "shinyssdtools")
  )
  # Distribution is recorded for every fit bar the twelve Burrlioz v2.0
  # csiro_nickel_fresh rows, whose source did not report which distribution
  # Burrlioz selected.
  na_dist <- ssd_fits[is.na(ssd_fits$Distribution), ]
  expect_identical(nrow(na_dist), 12L)
  expect_setequal(unique(na_dist$Dataset), "csiro_nickel_fresh")
})

test_that("Estimate is non-negative and confidence bounds bracket it", {
  expect_true(all(ssd_fits$Estimate >= 0, na.rm = TRUE))
  ci <- ssd_fits[!is.na(ssd_fits$Lower) & !is.na(ssd_fits$Upper) & !is.na(ssd_fits$Estimate), ]
  expect_gt(nrow(ci), 0L)
  expect_true(all(ci$Lower <= ci$Estimate))
  expect_true(all(ci$Estimate <= ci$Upper))
  expect_true(all(ssd_fits$SE >= 0, na.rm = TRUE))
})

test_that("ssd_fits Units matches the Units of the dataset that was fitted", {
  # Direct guard for the issue #47 class of bug: an estimate left on a
  # different scale from the raw data (ANZG boron/nitrate in mg/L, dioxins in
  # ng/L). Unlike the HC-below-max heuristic this catches a mismatch even when
  # the wrong-scale value still happens to fall below the data maximum.
  mismatched <- character(0)
  for (id in unique(ssd_fits$Dataset)) {
    d <- pkg_data(id)
    fit_units <- unique(ssd_fits$Units[ssd_fits$Dataset == id])
    data_units <- if ("Units" %in% names(d)) unique(d$Units) else NA_character_
    if (!identical(sort(fit_units), sort(data_units))) {
      mismatched <- c(mismatched, id)
    }
  }
  expect_identical(
    mismatched,
    character(0),
    label = "datasets whose ssd_fits Units differ from the dataset's own Units"
  )
})

test_that("ssd_fits Units is NA only for the anon_* datasets", {
  # The anon_* datasets ship no Units column - their concentrations are
  # deliberately unitless - so their fits carry NA Units. Any other NA means a
  # fit was added without recording its scale.
  na_units <- unique(ssd_fits$Dataset[is.na(ssd_fits$Units)])
  expect_setequal(na_units, c("anon_a", "anon_b", "anon_c", "anon_d", "anon_e"))
  expect_true(all(ssd_fits$Units[!is.na(ssd_fits$Units)] %in% c("ug/L", "mg/L", "ng/L")))
})

test_that("Units is constant within a dataset's fits", {
  n_units <- tapply(ssd_fits$Units, ssd_fits$Dataset, function(x) length(unique(x)))
  expect_true(all(n_units == 1L))
})
