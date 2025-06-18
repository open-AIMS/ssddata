test_that("multiplication works", {
  data_sets <- ssd_data_sets()
  expect_type(data_sets, "list")
  expect_length(data_sets, 20)
  expect_named(data_sets)
  expect_identical(
    names(data_sets), 
    sort(c(
      "aims_aluminium_marine", "aims_gallium_marine", "aims_molybdenum_marine", 
      "anon_a", "anon_b", "anon_c", "anon_d", "anon_e", "anzg_metolachlor_fresh", 
      "ccme_boron", "ccme_cadmium", "ccme_chloride", "ccme_endosulfan", 
      "ccme_glyphosate", "ccme_silver", "ccme_uranium", "csiro_chlorine_marine", 
      "csiro_cobalt_marine", "csiro_lead_marine", "csiro_nickel_fresh"
    )))
  
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
