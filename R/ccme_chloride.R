#' CCME Species Sensitivity Data for ccme_chloride
#' 
#' Species Sensitivity Data from the Canadian Council of Ministers of the
#' Environment for chloride.
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
#' }
#' 
#' @name ccme_chloride
#' @docType data
#' @format An object of class `tbl_df` (inherits from `tbl`,
#' `data.frame`) with 28 rows and 5 columns.
#' @keywords datasets
#' @examples
#' 
#' print(ccme_chloride, n=Inf)
#' 
"ccme_chloride"
