#' Species Sensitivity Data for molybdenum_marine
#' 
#' Species Sensitivity Data provided by the Australian Institute of Marine
#' Science for molybdenum in marine water.
#' 
#' These data were sourced from: 
#'\insertRef{VanDam2018}{ssddata} 
#'
#' 
#' The columns are as follows:
#' 
#' \describe{ 
#'\item{Common}{The species common name (chr).}
#'\item{Conc}{The chemical concentration in micrograms per Litre (dbl).}
#'\item{Domain}{Tropical, temperate or other filter (chr).}
#'\item{Life_stage}{Life stage of the test organism (chr).}
#'\item{Phylum}{The Phylum name (chr).}
#'\item{Source}{The endpoint primary data source (chr).}
#'\item{Species}{The species names name (chr).}
#'\item{Test_endpoint}{Endpoint statistic, EC10, NEC etc (chr).}
#'\item{Toxicity_measure}{Type of toxicity measure used (chr).} 
#' }
#' 
#' @name aims_molybdenum_marine
#' @docType data
#' @format An object of class `tbl_df` (inherits from `tbl`,
#' `data.frame`) with 14 rows and 9 columns.
#' @keywords datasets
#' @examples
#' 
#' print(aims_molybdenum_marine, n=Inf)
#' 
"aims_molybdenum_marine"
