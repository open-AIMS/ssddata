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
