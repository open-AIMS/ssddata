roxygen2md::roxygen2md()
roxygen2::roxygenise()
#styler::style_pkg(filetype = c("R", "Rmd"))
#lintr::lint_package()

devtools::test()
devtools::document()

pkgdown::build_site()


devtools::check()

rcmdcheck::rcmdcheck(args = c("--no-manual", "--as-cran"),
                     build_args = "--resave-data=best",
                     error_on = "warning")
