#' Species Sensitivity Data Sets
#' 
#' @description 
#' Extracts the data sets for all individually documented chemicals in ssddata. 
#' 
#' @details
#' Note only datasets for chemicals that are individually documented are returned.
#' This does not include chemicals from the wqbench US EPA Ecotox database. 
#' Data from wqbench can be retrieved using data("wqbench_data")
#'
#' @return A named list of the available data sets for individual chemicals.
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
