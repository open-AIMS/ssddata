test_that("getdata loads ccme-data", {
  expect_s3_class(ssddata:::getdata("ccme_boron"), "tbl")
  expect_silent(chk::check_data(
    ssddata:::getdata("ccme_boron"),
    values = list(
      Chemical = c("Boron", "Boron", "Boron"),
      Species = "",
      Units = c("mg/L", "mg/L", "mg/L"),
      Conc = c(1.0, 70.7),
      Group = factor(c("Amphibian", "Fish", "Invertebrate", "Plant"))
    ),
    nrow = 28L
  ))
})

test_that("getdata errors rather than returning NULL for an unknown name", {
  expect_error(suppressWarnings(ssddata:::getdata("no_such_dataset")))
})
