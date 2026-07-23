# Guards against the class of bug reported in GitHub issue #47: the raw
# toxicity data returned by get_ssddata() and the gazetted hazard
# concentrations in ssd_fits drifting onto different concentration units
# (e.g. ANZG boron/nitrate stored in mg/L while ssd_fits was in ug/L, or a
# ssd_fits estimate left in ng/L). A percentile-protection concentration must
# sit at or below the maximum observed toxicity value, so a gazetted HC
# exceeding the raw data maximum is a reliable unit-mismatch signal.

test_that("gazetted hazard concentrations do not exceed the raw data maximum", {
  fits <- ssddata::ssd_fits
  gaz <- fits[
    fits$Software == "Burrlioz" & !is.na(fits$Estimate),
    c("Dataset", "PC", "Estimate")
  ]
  # Only datasets that ship as retrievable objects in this package.
  gaz <- gaz[gaz$Dataset %in% utils::data(package = "ssddata")$results[, "Item"], ]

  offenders <- character(0)
  for (id in unique(gaz$Dataset)) {
    d <- suppressMessages(get_ssddata(id))
    if (!"Conc" %in% names(d)) {
      next
    }
    raw_max <- max(d$Conc, na.rm = TRUE)
    hc <- gaz$Estimate[gaz$Dataset == id]
    if (any(hc > raw_max)) {
      offenders <- c(offenders, id)
    }
  }
  expect_identical(
    offenders,
    character(0),
    label = paste(
      "Datasets whose gazetted HC exceeds the raw data maximum",
      "(likely a unit mismatch between get_ssddata() and ssd_fits)"
    )
  )
})

test_that("issue #47 datasets are on a consistent scale (HC5 in the lower tail)", {
  # The four ANZG datasets whose raw data was corrected from mg/L to ug/L,
  # plus dioxins whose ssd_fits estimate was corrected from ng/L to ug/L.
  # After the fix every gazetted HC5 must lie below the raw data median.
  ids <- c(
    "anzg_boron_fresh",
    "anzg_nitrate_soft_fresh",
    "anzg_nitrate_moderate_fresh",
    "anzg_nitrate_hard_fresh",
    "anzg_dioxins_fresh"
  )
  fits <- ssddata::ssd_fits
  for (id in ids) {
    d <- suppressMessages(get_ssddata(id))
    hc5 <- fits$Estimate[
      fits$Dataset == id & fits$Software == "Burrlioz" & fits$PC == 95
    ]
    expect_true(
      length(hc5) == 1 && hc5 < stats::median(d$Conc),
      label = paste(id, "gazetted HC5 below raw data median")
    )
  }
})
