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

test_that("group splits datasets and appends column value to name", {
  ds <- ssd_data_sets(set = c("aims"), group = "Domain")
  expect_true(all(grepl("_Temperate$|_Tropical$|_Mixed$", names(ds))))
  # datasets without Domain column (ccme etc) are not in this set so no check needed
})

test_that("group silently skips columns absent from a dataset", {
  # ccme datasets don't have Domain — should return unchanged
  ds_with <- ssd_data_sets(set = c("aims"), group = "Domain")
  ds_without <- ssd_data_sets(set = c("ccme"), group = "Domain")
  # ccme datasets returned as-is, names unmodified
  expect_true(all(grepl("^ccme_", names(ds_without))))
  expect_false(any(grepl("_Domain", names(ds_without))))
})

test_that("dedup = 'geomean' emits message when duplicates present", {
  expect_message(
    ssd_data_sets(set = c("aims"), dedup = "geomean"),
    "Geometric mean applied"
  )
})

test_that("dedup = 'none' emits message listing duplicate species", {
  expect_message(
    ssd_data_sets(set = c("aims"), dedup = "none"),
    "Duplicate species"
  )
})

test_that("invalid set value throws informative error", {
  expect_error(
    ssd_data_sets(set = "bad"),
    "Unknown `set` value"
  )
})

test_that("invalid dedup value throws informative error", {
  expect_error(
    ssd_data_sets(dedup = "bad"),
    "`dedup` must be"
  )
})
