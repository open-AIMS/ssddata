# README
devtools::build_readme()

# Generate dataset R files
source("data-raw/source_all.R")

# Generate documentation
devtools::document()

# Update pkgdown config
source("data-raw/build_pkgdown_yml.R")

# Build site
pkgdown::build_site()

browseURL("docs/index.html")

devtools::test()

devtools::check()

rcmdcheck::rcmdcheck(
  args = c("--no-manual", "--as-cran"),
  build_args = "--resave-data=best",
  error_on = "warning"
)
