#' CCME Species Sensitivity Data for ccme_silver
#' 
#' Species Sensitivity Data from the Canadian Council of Ministers of the
#' Environment for silver.
#' 
#' Additional information is available from 
#'\insertRef{Silver}{ssddata} 
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
#' }
#' 
#' @name ccme_silver
#' @docType data
#' @format An object of class `tbl_df` (inherits from `tbl`,
#' `data.frame`) with 9 rows and 5 columns.
#' @keywords datasets
#' @examples
#' 
#' print(ccme_silver, n=Inf)
#' 
"ccme_silver"
