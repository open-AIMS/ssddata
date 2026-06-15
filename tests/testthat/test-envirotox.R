test_that("envirotox_acute is correct", {
  chk::check_key(envirotox_acute, c("Chemical", "Species"))
  expect_identical(nrow(envirotox_acute), 14949L)
  chk::check_data(
    envirotox_acute,
    values = list(
      Chemical = "",
      Conc = c(0, Inf),
      Species = "",
      Group = "",
      Yanagihara24 = c(TRUE, FALSE),
      Iwasaki25 = c(TRUE, FALSE)
    )
  )
})

test_that("envirotox_chronic is correct", {
  chk::check_key(envirotox_chronic, c("Chemical", "Species"))
  expect_identical(nrow(envirotox_chronic), 1721L)
  chk::check_data(
    envirotox_chronic,
    values = list(
      Chemical = "",
      Conc = c(0, Inf),
      Species = "",
      Group = "",
      Yanagihara24 = c(TRUE, FALSE)
    )
  )
})

test_that("envirotox_chemical is correct", {
  chk::check_key(envirotox_chemical, "Chemical")
  chk::check_key(envirotox_chemical, "OriginalCAS")
  expect_identical(nrow(envirotox_chemical), 744L)
  chk::check_data(
    envirotox_chemical,
    values = list(
      Chemical = "",
      OriginalCAS = 1L
    )
  )
})

test_that("envirotox_data is correct", {
  expect_type(envirotox_data, "list")
  expect_length(envirotox_data, 3L)
  expect_named(envirotox_data, c("acute", "chronic", "chemical"))
  expect_identical(envirotox_data$acute, envirotox_acute)
  expect_identical(envirotox_data$chronic, envirotox_chronic)
  expect_identical(envirotox_data$chemical, envirotox_chemical)
})

test_that("ssd_data_sets count is unchanged", {
  expect_length(ssd_data_sets(), 53L)
})

test_that("list_datasets() is deprecated alias for envirotox_data_sets()", {
  expect_warning(
    result <- list_datasets(),
    regexp = "`list_datasets\\(\\)` was renamed to `envirotox_data_sets\\(\\)`",
    fixed = FALSE
  )
  expect_identical(result, envirotox_data_sets())
})
