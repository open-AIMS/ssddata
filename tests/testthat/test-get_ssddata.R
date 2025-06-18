test_that("get_ssddata returns the raw data with no species group vector", {
  expect_message(
    expect_s3_class(get_ssddata("ccme_boron", spp_vec = NA), "tbl"),
    "No grouping has been applied, returning raw ccme_boron dataset."
  )
  expect_message(chk::check_data(
    get_ssddata("ccme_boron", spp_vec = NA),
    values = list(
      Chemical = c("Boron", "Boron", "Boron"),
      Species = "",
      Units = c("mg/L", "mg/L", "mg/L"),
      Conc = c(1.0, 70.7),
      Group = factor(c("Amphibian", "Fish", "Invertebrate", "Plant"))
    ),
    nrow = 28L
  ), "No grouping has been applied, returning raw ccme_boron dataset.")
})

test_that("get_ssddata returns raw data with a species group vector when there are no duplicates", {
  expect_message(
    expect_s3_class(get_ssddata("ccme_boron"), "tbl"),
    "No grouping has been applied, returning raw ccme_boron dataset."
  )
  expect_message(chk::check_data(
    get_ssddata("ccme_boron"),
    nrow = 28L
  ), "No grouping has been applied, returning raw ccme_boron dataset.")
})

test_that("get_ssddata returns the aluminium raw data with no species group vector", {
  expect_message(
    expect_s3_class(get_ssddata("aims_aluminium_marine", spp_vec = NA), "tbl"),
    "No grouping has been applied, returning raw aims_aluminium_marine dataset."
  )
  expect_message(chk::check_data(
    get_ssddata("aims_aluminium_marine", spp_vec = NA),
    nrow = 20L
  ), "No grouping has been applied, returning raw aims_aluminium_marine dataset.")
})

test_that("get_ssd_data returns modified data with a species group vector with the right number of rows", {
  expect_message(
    expect_s3_class(get_ssddata("aims_aluminium_marine"), "tbl"),
    "Data aims_aluminium_marine grouped by Species with a geometric mean applied to duplicate records."
  )
  expect_message(chk::check_data(
    get_ssddata("aims_aluminium_marine"),
    nrow = 17L
  ), "Data aims_aluminium_marine grouped by Species with a geometric mean applied to duplicate records.")
})


test_that("get_ssd_data returns raw data when default spp_vec isn't present", {
  expect_message(
    expect_s3_class(get_ssddata("anon_a"), "tbl"),
    "No grouping has been applied, returning raw anon_a dataset."
  )
  expect_message(chk::check_data(
    get_ssddata("anon_a"),
    nrow = 18L
  ), "No grouping has been applied, returning raw anon_a dataset.")
})

test_that("Filter works as expected", {
  expect_message(
    expect_s3_class(get_ssddata("aims_aluminium_marine", spp_vec = NA, filter_val = "Domain_Temperate"), "tbl"),
    "No grouping has been applied, returning raw aims_aluminium_marine dataset."
  )
  expect_message(chk::check_data(
    get_ssddata("aims_aluminium_marine", spp_vec = NA, filter_val = "Domain_Temperate"),
    nrow = 11L
  ), "No grouping has been applied, returning raw aims_aluminium_marine dataset.")
  expect_message(
    expect_s3_class(get_ssddata("aims_aluminium_marine", filter_val = "Domain_Temperate"), "tbl"),
    "Data aims_aluminium_marine grouped by Species with a geometric mean applied to duplicate records."
  )
  expect_message(chk::check_data(
    get_ssddata("aims_aluminium_marine", filter_val = "Domain_Temperate"),
    nrow = 10L
  ), "Data aims_aluminium_marine grouped by Species with a geometric mean applied to duplicate records.")
})


test_that("Filter does nothing when filter_val level doesnt exist in data", {
  expect_message(
    expect_s3_class(get_ssddata("aims_aluminium_marine", spp_vec = NA, filter_val = "Domain_emperate"), "tbl"),
    "No grouping has been applied, returning raw aims_aluminium_marine dataset."
  )
})

test_that("Returns error when filter_val column heading doesnt exist in data", {
  expect_error(get_ssddata("aims_aluminium_marine", filter_val = "omain_Temperate"))
})
