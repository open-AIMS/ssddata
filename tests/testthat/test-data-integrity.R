# Package-wide sweeps over every shipped data object.
#
# The pre-existing tests spot-check three datasets (ccme_boron, ccme_data,
# anzg_metolachlor_fresh). These tests instead assert the structural contract
# that EVERY dataset must satisfy to be usable with ssdtools, so a new or
# rebuilt dataset cannot ship with a broken Conc/Species/Units column
# unnoticed. Failures name the offending dataset(s) rather than just the
# expectation, so the sweep is diagnostic.

# Collect the datasets failing a per-dataset predicate, for informative output.
.offenders <- function(items, f) {
  bad <- vapply(items, function(x) isTRUE(f(pkg_data(x))), logical(1))
  items[bad]
}

test_that("every shipped data object is a tibble, except the envirotox_data list", {
  items <- shipped_items()
  for (it in setdiff(items, "envirotox_data")) {
    expect_s3_class(pkg_data(it), "tbl_df")
  }
  expect_type(pkg_data("envirotox_data"), "list")
  expect_false(is.data.frame(pkg_data("envirotox_data")))
})

test_that("no shipped data frame has empty, duplicated or non-syntactic column names", {
  items <- shipped_data_frames()
  bad <- .offenders(items, function(d) {
    nms <- names(d)
    anyDuplicated(nms) > 0 || any(is.na(nms)) || any(trimws(nms) == "")
  })
  expect_identical(bad, character(0), label = "datasets with bad column names")
})

test_that("no shipped data frame is empty", {
  items <- shipped_data_frames()
  bad <- .offenders(items, function(d) nrow(d) == 0L || ncol(d) == 0L)
  expect_identical(bad, character(0), label = "empty datasets")
})

test_that("Conc is numeric, non-missing and finite wherever it is present", {
  items <- shipped_data_frames()
  items <- items[vapply(items, function(x) "Conc" %in% names(pkg_data(x)), logical(1))]
  # Sanity: the sweep must actually be looking at something.
  expect_gt(length(items), 50L)

  not_numeric <- .offenders(items, function(d) !is.numeric(d$Conc))
  expect_identical(not_numeric, character(0), label = "datasets with non-numeric Conc")

  not_finite <- .offenders(items, function(d) any(is.na(d$Conc) | !is.finite(d$Conc)))
  expect_identical(not_finite, character(0), label = "datasets with missing/infinite Conc")

  # A zero maps to -Inf on the log scale an SSD is fitted on. wqbench_data
  # carried 20 such rows from ECOTOX until they were dropped at build time
  # (GitHub #49); this sweep covers every shipped dataset, not just that one.
  nonpositive <- .offenders(items, function(d) any(d$Conc <= 0))
  expect_identical(nonpositive, character(0), label = "datasets with non-positive Conc")
})

test_that("Species is character, non-missing and non-empty wherever it is present", {
  items <- shipped_data_frames()
  items <- items[vapply(items, function(x) "Species" %in% names(pkg_data(x)), logical(1))]
  expect_gt(length(items), 50L)

  bad <- .offenders(items, function(d) {
    !is.character(d$Species) || any(is.na(d$Species)) || any(trimws(d$Species) == "")
  })
  expect_identical(bad, character(0), label = "datasets with missing/blank Species")
})

test_that("Units, where present, uses the ug/L | mg/L | ng/L vocabulary", {
  # ssd_fits is excluded: its Units column describes the fitted estimates and
  # is NA for the anon_* datasets, which ship no Units of their own. It is
  # covered in test-ssd_fits.R.
  items <- setdiff(shipped_data_frames(), "ssd_fits")
  items <- items[vapply(items, function(x) "Units" %in% names(pkg_data(x)), logical(1))]
  expect_gt(length(items), 40L)

  bad <- .offenders(items, function(d) {
    !is.character(d$Units) ||
      any(is.na(d$Units)) ||
      !all(d$Units %in% c("ug/L", "mg/L", "ng/L"))
  })
  expect_identical(bad, character(0), label = "datasets with an unexpected Units value")
})

test_that("Units is constant within each per-chemical dataset", {
  # A per-chemical dataset mixing units would make Conc uninterpretable and is
  # the exact failure mode behind issue #47. The `{prefix}_data` aggregates are
  # exempt: ccme_data legitimately spans mg/L, ug/L and ng/L across chemicals.
  items <- setdiff(shipped_data_frames(), "ssd_fits")
  items <- items[!grepl("_data$", items)]
  items <- items[vapply(items, function(x) "Units" %in% names(pkg_data(x)), logical(1))]

  bad <- .offenders(items, function(d) length(unique(d$Units)) != 1L)
  expect_identical(bad, character(0), label = "per-chemical datasets with mixed Units")
})

