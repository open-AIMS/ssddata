test_that("datasets are correct", {
  data_sets <- ssd_data_sets()
  expect_type(data_sets, "list")
  expect_length(data_sets, 53)
  expect_named(data_sets)
  expect_identical(
    names(data_sets),
    sort(c(
      "aims_aluminium_marine",
      "aims_gallium_marine",
      "aims_molybdenum_marine",
      "anon_a",
      "anon_b",
      "anon_c",
      "anon_d",
      "anon_e",
      "anzg_alpha_cypermethrin_fresh",
      "anzg_aluminium_marine",
      "anzg_ametryn_fresh",
      "anzg_ammonia_fresh",
      "anzg_bisphenol_a_fresh",
      "anzg_bisphenol_a_marine",
      "anzg_boron_fresh",
      "anzg_chlorine_marine",
      "anzg_chromium_III_fresh",
      "anzg_copper_marine",
      "anzg_dioxins_fresh",
      "anzg_diuron_fresh",
      "anzg_diuron_marine",
      "anzg_fipronil_fresh",
      "anzg_fluoride_fresh",
      "anzg_glyphosate_fresh",
      "anzg_iron_fresh",
      "anzg_iron_marine",
      "anzg_mancozeb_fresh",
      "anzg_manganese_marine",
      "anzg_mcpa_fresh",
      "anzg_metolachlor_fresh",
      "anzg_metsulfuron_methyl_fresh",
      "anzg_nickel_marine",
      "anzg_nitrate_hard_fresh",
      "anzg_nitrate_moderate_fresh",
      "anzg_nitrate_soft_fresh",
      "anzg_paraquat_fresh",
      "anzg_perfluorooctane_sulfonate_pfos_fresh",
      "anzg_picloram_fresh",
      "anzg_simazine_fresh",
      "anzg_simazine_marine",
      "anzg_sulfometuron_methyl_fresh",
      "anzg_zinc_marine",
      "ccme_boron",
      "ccme_cadmium",
      "ccme_chloride",
      "ccme_endosulfan",
      "ccme_glyphosate",
      "ccme_silver",
      "ccme_uranium",
      "csiro_chlorine_marine",
      "csiro_cobalt_marine",
      "csiro_lead_marine",
      "csiro_nickel_fresh"
    ))
  )

  chk::check_data(
    data_sets$ccme_boron,
    values = list(
      Chemical = c("Boron", "Boron", "Boron"),
      Species = "",
      Units = c("mg/L", "mg/L", "mg/L"),
      Conc = c(1.0, 70.7),
      Group = factor(c("Amphibian", "Fish", "Invertebrate", "Plant"))
    ),
    nrow = 28L
  )
})

test_that("wqbench_data Medium values are standardised", {
  wq <- ssd_data_sets(set = "wqbench")
  mediums <- unlist(lapply(wq, function(x) unique(x$Medium)), use.names = FALSE)
  expect_true(all(mediums %in% c("Freshwater", "Marine", "Unknown")))
})

test_that("set = 'v1' returns exactly 20 hardcoded datasets", {
  ds <- ssd_data_sets(set = "v1")
  expect_type(ds, "list")
  expect_length(ds, 20)
  expect_true(all(c("ccme_boron", "aims_aluminium_marine") %in% names(ds)))
})

test_that("set with prefix filter returns only matching datasets", {
  ds <- ssd_data_sets(set = c("ccme", "anzg"))
  expect_true(all(grepl("^(ccme|anzg)_", names(ds))))
  expect_false(any(grepl("^aims_", names(ds))))
})

test_that("set = 'anztox' returns named list split by chemical x mediatype", {
  ds <- ssd_data_sets(set = "anztox")
  expect_type(ds, "list")
  expect_length(ds, 174)
  expect_true(all(grepl("^anztox_", names(ds))))
})

test_that("set = 'wqbench' returns named list split by chemical_name", {
  ds <- ssd_data_sets(set = "wqbench")
  expect_type(ds, "list")
  expect_true(length(ds) > 0)
  expect_true(all(grepl("^wqbench_", names(ds))))
})

test_that("set = 'envirotox_acute' returns named list split by Chemical", {
  ds <- ssd_data_sets(set = "envirotox_acute")
  expect_type(ds, "list")
  expect_length(ds, 729)
  expect_true(all(grepl("^envirotox_acute_", names(ds))))
})

test_that("split splits datasets and appends column value to name", {
  ds <- ssd_data_sets(set = c("aims"), split = "Domain")
  expect_true(all(grepl("_Temperate$|_Tropical$|_Mixed$", names(ds))))
})

test_that("split silently skips columns absent from a dataset", {
  ds_with <- ssd_data_sets(set = c("aims"), split = "Domain")
  ds_without <- ssd_data_sets(set = c("ccme"), split = "Domain")
  expect_true(all(grepl("^ccme_", names(ds_without))))
  expect_false(any(grepl("_Domain", names(ds_without))))
})

test_that("summarize = 'geomean' emits message when duplicates present", {
  expect_message(
    ssd_data_sets(set = c("aims"), summarize = "geomean"),
    "Geometric mean applied"
  )
})

test_that("summarize = 'none' emits message listing duplicate species", {
  expect_message(
    ssd_data_sets(set = c("aims"), summarize = "none"),
    "Duplicate species"
  )
})

test_that("invalid set value throws informative error", {
  expect_error(
    ssd_data_sets(set = "bad"),
    "Unknown `set` value"
  )
})

test_that("invalid summarize value throws informative error", {
  expect_error(
    ssd_data_sets(summarize = "bad"),
    "`summarize` must be"
  )
})

test_that("alldata returns a named list with deduplication applied via geomean", {
  expect_message(
    ssd_data_sets(set = "alldata", summarize = "geomean"),
    "Geometric mean applied"
  )
})

test_that("set = 'alldata' returns named list split by chemical_name", {
  ds <- ssd_data_sets(set = "alldata")
  expect_type(ds, "list")
  expect_true(length(ds) > 0)
  expect_false(all(grepl("^alldata_", names(ds)))) # names are data sources names, not prefixed with "alldata_"
})

test_that("set = 'alldata' tibbles each have a species column and a concentration column", {
  # .harmonise_columns() guarantees every tibble has Species and Conc.
  # anon_* datasets receive sequential labels ("sp. A", "sp. B", ...) since
  # they have no real species information.
  ds_all <- ssd_data_sets(set = "alldata")
  has_species <- vapply(ds_all, function(x) "Species" %in% names(x), logical(1))
  has_conc <- vapply(ds_all, function(x) "Conc" %in% names(x), logical(1))

  expect_true(
    all(has_species),
    info = paste(
      "Tibbles missing Species column:",
      paste(names(ds_all)[!has_species], collapse = ", ")
    )
  )
  expect_true(
    all(has_conc),
    info = paste(
      "Tibbles missing Conc column:",
      paste(names(ds_all)[!has_conc], collapse = ", ")
    )
  )
})

test_that("all returned tibbles have Species and Conc as the first two columns", {
  ds_v2 <- ssd_data_sets()
  first_two_ok <- vapply(
    ds_v2,
    function(x) {
      identical(names(x)[1:2], c("Species", "Conc"))
    },
    logical(1)
  )
  expect_true(
    all(first_two_ok),
    info = paste(
      "Tibbles where Species/Conc are not first two columns:",
      paste(names(ds_v2)[!first_two_ok], collapse = ", ")
    )
  )
})

test_that("anon_* tibbles receive sequential species labels sp. A, sp. B, ...", {
  ds_anon <- ssd_data_sets(set = "anon")
  for (nm in names(ds_anon)) {
    dat <- ds_anon[[nm]]
    expect_true("Species" %in% names(dat), label = paste(nm, "has Species"))
    expect_true(
      all(grepl("^sp\\. ", dat$Species)),
      label = paste(nm, "species are sequential labels")
    )
  }
})

test_that("mixing aggregated source with prefix in set errors informatively", {
  expect_error(
    ssd_data_sets(set = c("wqbench", "ccme")),
    "Unknown `set` value"
  )
  expect_error(
    ssd_data_sets(set = c("anztox", "aims")),
    "Unknown `set` value"
  )
  expect_error(
    ssd_data_sets(set = c("envirotox_acute", "ccme")),
    "Unknown `set` value"
  )
})

test_that("element names are unique for every set", {
  for (s in c(
    "v1",
    "v2",
    "anztox",
    "wqbench",
    "envirotox_acute",
    "envirotox_chronic"
  )) {
    ds <- suppressMessages(ssd_data_sets(set = s))
    expect_false(any(duplicated(names(ds))), info = s)
  }
})

test_that("anztox names colliding on chemical x medium are split by CAS", {
  ds <- suppressMessages(ssd_data_sets(set = "anztox"))
  # Aroclor 1254 (11097691) and Aroclor 1242 (53469219) share the grouped
  # chemical name "Polychlorinated biphenyls"; both must stay reachable.
  pcb <- grep("^anztox_Polychlorinated", names(ds), value = TRUE)
  expect_setequal(
    pcb,
    c(
      "anztox_Polychlorinated.biphenyls_Freshwater_11097691",
      "anztox_Polychlorinated.biphenyls_Freshwater_53469219"
    )
  )
  expect_false(identical(ds[[pcb[1]]], ds[[pcb[2]]]))
  # Non-colliding names keep their original chemical_medium form.
  expect_true(any(names(ds) == "anztox_Zinc_Freshwater"))
})

test_that("set = NA errors informatively", {
  expect_error(
    ssd_data_sets(set = NA_character_),
    "must not have any missing values"
  )
})

test_that("wqbench_data has no non-positive concentrations", {
  # A zero maps to -Inf on the log scale an SSD is fitted on. ECOTOX records
  # 20 such values as literal zeros; they are dropped at build time (GitHub #49).
  e <- new.env()
  utils::data("wqbench_data", package = "ssddata", envir = e)
  w <- e$wqbench_data
  expect_true(all(w$Conc > 0))
  expect_false(any(is.na(w$Conc)))

  # They must not survive into the user-facing split either.
  ds <- suppressMessages(ssd_data_sets(set = "wqbench"))
  expect_equal(sum(vapply(ds, function(x) sum(x$Conc <= 0), numeric(1))), 0)
})

test_that("Medium uses one harmonised vocabulary across all sources", {
  allowed <- c(
    "Freshwater",
    "Marine",
    "Unknown",
    "Soft freshwater",
    "Moderate freshwater",
    "Hard freshwater"
  )
  pk <- function(n) {
    e <- new.env()
    utils::data(list = n, package = "ssddata", envir = e)
    e[[n]]
  }
  items <- sort(utils::data(package = "ssddata")$results[, "Item"])
  items <- items[vapply(
    items,
    function(x) {
      d <- pk(x)
      is.data.frame(d) && "Medium" %in% names(d)
    },
    logical(1)
  )]
  expect_true(length(items) > 0)

  bad <- items[vapply(
    items,
    function(x) !all(pk(x)$Medium %in% allowed),
    logical(1)
  )]
  expect_identical(
    unname(bad),
    character(0),
    label = "datasets with an unexpected Medium value"
  )

  # anztox_data uses `mediatype` for the same concept.
  expect_true(all(pk("anztox_data")$mediatype %in% allowed))

  # The three ANZG hardness variants must remain distinct, not collapsed.
  expect_setequal(
    unique(pk("anzg_data")$Medium),
    c(
      "Freshwater",
      "Marine",
      "Soft freshwater",
      "Moderate freshwater",
      "Hard freshwater"
    )
  )
})

test_that("no element name contains NA where a chemical name is missing", {
  # anztox_data has two rows with a NA chemicalname_grouped (CAS 7782492,
  # selenium), which produced elements literally named anztox_NA_*. The name
  # falls back to the CAS so they stay identifiable; the underlying NA is
  # GitHub #62 and needs the anztox source rebuilt.
  for (s in c("anztox", "alldata")) {
    ds <- suppressMessages(ssd_data_sets(set = s))
    expect_identical(grep("_NA_", names(ds), value = TRUE), character(0), info = s)
    expect_true(all(c(
      "anztox_7782492_Freshwater",
      "anztox_7782492_Marine"
    ) %in% names(ds)), info = s)
  }

  ds <- suppressMessages(ssd_data_sets(set = "anztox"))
  expect_identical(nrow(ds[["anztox_7782492_Freshwater"]]), 5L)
  expect_identical(nrow(ds[["anztox_7782492_Marine"]]), 13L)
})
