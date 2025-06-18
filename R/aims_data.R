#' Species Sensitivity Data provided by AIMS
#' 
#' Species Sensitivity Data provided by the Australian Institute of Marine
#' Science.
#' 
#' Additional information may be available from the primary source for each
#' chemical:
#' 
#' \describe{
#'	\item{aluminium_marine}{\insertRef{VanDam2018}{ssddata}}
#'	\item{gallium_marine}{\insertRef{VanDam2018}{ssddata}}
#'	\item{molybdenum_marine}{\insertRef{VanDam2018}{ssddata}} 
#'}
#' 
#' The columns are as follows, noting that all information may not be available
#' for all chemicals:
#' 
#' \describe{ 
#'\item{Chemical}{The chemical name (chr).}
#'\item{Common}{The species common name (chr).}
#'\item{Conc}{The chemical concentration in micrograms per Litre (dbl).}
#'\item{Domain}{Tropical, temperate or other filter (chr).}
#'\item{Life_stage}{Life stage of the test organism (chr).}
#'\item{Medium}{The medium - fresh or marine water (chr).}
#'\item{Phylum}{The Phylum name (chr).}
#'\item{Source}{The endpoint primary data source (chr).}
#'\item{Species}{The species names name (chr).}
#'\item{Test_endpoint}{Endpoint statistic, EC10, NEC etc (chr).}
#'\item{Toxicity_measure}{Type of toxicity measure used (chr).} 
#' }
#' 
#' @name aims_data
#' @docType data
#' @format An object of class `tbl_df` (inherits from `tbl`,
#' `data.frame`) with 40 rows and 11 columns.
#' @keywords datasets
#' @examples
#' 
#' head(aims_data)
#' 
"aims_data"
