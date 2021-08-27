
files <- unlist(sapply(list.dirs("data-raw")[-1], FUN = function(x) {
  list.files(x, pattern = "[.][rR]$", full.names = TRUE)
}))
invisible(lapply(files, source))
roxygen2md::roxygen2md()
# styler::style_pkg(filetype = c("R", "Rmd"))
devtools::document()
