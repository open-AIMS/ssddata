roxygen2md::roxygen2md()
roxygen2::roxygenise()

devtools::test()
devtools::document()

# if updating references
unlink("man", recursive = TRUE)
devtools::document()


pkgdown::build_site()
browseURL("docs/index.html")

devtools::check()

rcmdcheck::rcmdcheck(
  args = c("--no-manual", "--as-cran"),
  build_args = "--resave-data=best",
  error_on = "warning"
)
