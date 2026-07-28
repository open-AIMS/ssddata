# Argument validation and edge-case behaviour for get_ssddata(). The existing
# test-get_ssddata.R covers the happy paths (grouping, filtering, messages);
# these cover what happens when arguments are wrong or unusual, including two
# branches of the function that had no coverage at all: the explicit
# `filter_val = NA` handling and the non-default `conc` / `use_gmmean`
# arguments.

test_that("get_ssddata validates its arguments", {
  expect_error(get_ssddata(1), "`dataset_name` must be a string")
  expect_error(get_ssddata(c("ccme_boron", "ccme_silver")), "`dataset_name` must be a string")
  expect_error(get_ssddata(NA_character_), "`dataset_name` must be a string")
  expect_error(get_ssddata("ccme_boron", use_gmmean = "yes"), "`use_gmmean` must be a flag")
  expect_error(get_ssddata("ccme_boron", use_gmmean = NA), "`use_gmmean` must be a flag")
  expect_error(get_ssddata("ccme_boron", conc = 1), "`conc` must be a string")
  expect_error(get_ssddata("ccme_boron", filter_val = 1), "`filter_val` must be")
})

test_that("filter_val = NA is treated as no filter", {
  # The function explicitly converts a missing filter_val to NULL up front so
  # callers can pass through an absent filter from a lookup table.
  unfiltered <- suppressMessages(get_ssddata("ccme_boron"))
  na_filter <- suppressMessages(get_ssddata("ccme_boron", filter_val = NA))
  expect_identical(na_filter, unfiltered)
  expect_identical(nrow(na_filter), 28L)
})

test_that("use_gmmean = FALSE returns the raw data even when duplicates exist", {
  raw <- suppressMessages(get_ssddata("aims_aluminium_marine", use_gmmean = FALSE))
  grouped <- suppressMessages(get_ssddata("aims_aluminium_marine", use_gmmean = TRUE))
  expect_identical(nrow(raw), 20L)
  expect_identical(nrow(grouped), 17L)
  expect_identical(raw, pkg_data("aims_aluminium_marine"))
  expect_message(
    get_ssddata("aims_aluminium_marine", use_gmmean = FALSE),
    "No grouping has been applied"
  )
})

test_that("the geometric mean is applied to the column named by `conc`", {
  grouped <- suppressMessages(get_ssddata("aims_aluminium_marine"))
  raw <- pkg_data("aims_aluminium_marine")
  expect_identical(names(grouped), c("Species", "Conc"))

  # Spot-check one geomeaned species against gm_mean() of its raw values.
  dups <- names(which(table(raw$Species) > 1L))
  expect_gt(length(dups), 0L)
  spp <- dups[1]
  expect_equal(
    grouped$Conc[grouped$Species == spp],
    gm_mean(raw$Conc[raw$Species == spp])
  )
  # Species with a single record pass through unchanged.
  singles <- setdiff(raw$Species, dups)
  expect_equal(
    grouped$Conc[match(singles, grouped$Species)],
    raw$Conc[match(singles, raw$Species)]
  )
})

test_that("spp_vec uses every grouping column present in the data", {
  # anzg_data carries both Species and Genus and has duplicate pairs, so both
  # default spp_vec columns are used: the message names both and the key
  # column is the two pasted together.
  expect_message(
    get_ssddata("anzg_data"),
    "grouped by Species, Genus"
  )
  grouped <- suppressMessages(get_ssddata("anzg_data"))
  expect_identical(names(grouped), c("Species_Genus", "Conc"))
  expect_true(all(grepl("_", grouped$Species_Genus)))

  # Per-chemical anzg datasets have no duplicate Species/Genus pairs, so they
  # short-circuit to the raw data instead.
  expect_message(
    get_ssddata("anzg_copper_marine"),
    "No grouping has been applied"
  )
})

test_that("an unrecognised spp_vec falls back to the raw data", {
  expect_message(
    out <- get_ssddata("ccme_boron", spp_vec = "NotAColumn"),
    "No grouping has been applied"
  )
  expect_identical(out, pkg_data("ccme_boron"))
})

test_that("filtering to a single Domain level narrows the data", {
  temperate <- suppressMessages(
    get_ssddata("aims_aluminium_marine", spp_vec = NA, filter_val = "Domain_Temperate")
  )
  expect_true(all(temperate$Domain == "Temperate"))
  expect_lt(nrow(temperate), nrow(pkg_data("aims_aluminium_marine")))
})

test_that("getdata retrieves any shipped dataset by name", {
  expect_identical(ssddata:::getdata("anzg_boron_fresh"), pkg_data("anzg_boron_fresh"))
  expect_identical(ssddata:::getdata("wqbench_data"), pkg_data("wqbench_data"))
})
