#' CCME Species Sensitivity Data for ccme_chloride
#' 
#' Species Sensitivity Data from the Canadian Council of Ministers of the
#' Environment for \strong{\emph{chloride}}.
#' 
#' Additional information is available from 
#'\insertRef{Chloride}{ssddata} 
#'
#' 
#' The columns are as follows:
#' 
#' \describe{ 
#'\item{Chemical}{The chemical (chr).}
#'\item{Species}{The species binomial name (chr).}
#'\item{Conc}{The chemical concentration (dbl).}
#'\item{Group}{The taxonomic group (fct).}
#'\item{Units}{The units of Conc (chr).}
#'\item{Medium}{The medium (freshwater, marine, etc.) (chr).} 
#' }
#' 
#' @name ccme_chloride
#' @docType data
#' @format An object of class \code{tbl_df} (inherits from \code{tbl},
#' \code{data.frame}) with 28 rows and 6 columns.
#' @keywords datasets
#' @examples
#' 
#' print(ccme_chloride, n=Inf)
#' 
NULL
