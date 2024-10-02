#' Species Sensitivity Data Sets
#'
#' @return A named list of the individual data sets.
#' @export
#'
#' @examples
#' ssd_data_sets()
ssd_data_sets <- function() {
  items <- utils::data(package="ssddata")$results[, "Item"]
  items <- items[!items %in% c("ssd_fits")]
  items <- items[!grepl("_data$", items)]
  items <- sort(items)
  datasets <- lapply(items, function(x) eval(parse(text = paste0("ssddata::", x))))
  names(datasets) <- items
  datasets
}
