test_that("anzg_metolachlor_fresh", {
  expect_silent(chk::check_data(
    anzg_metolachlor_fresh,
    values = list(
      Conc = c(0.53, 6528)
    ),
    nrow = 21L
  ))
})
