#' CCME Species Sensitivity Data for ccme_uranium
#' 
#' Species Sensitivity Data from the Canadian Council of Ministers of the
#' Environment for uranium.
#' 
#' Additional information is available from 
#'\insertRef{Uranium}{ssddata} 
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
#' @name ccme_uranium
#' @docType data
#' @format An object of class `tbl_df` (inherits from `tbl`,
#' `data.frame`) with 13 rows and 5 columns.
#' @keywords datasets
#' @examples
#' 
#' print(ccme_uranium, n=Inf)
#' 
"ccme_uranium"
