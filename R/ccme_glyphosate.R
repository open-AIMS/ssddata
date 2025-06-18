#' CCME Species Sensitivity Data for ccme_glyphosate
#' 
#' Species Sensitivity Data from the Canadian Council of Ministers of the
#' Environment for glyphosate.
#' 
#' Additional information is available from 
#'\insertRef{Glyphosate}{ssddata} 
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
#' @name ccme_glyphosate
#' @docType data
#' @format An object of class `tbl_df` (inherits from `tbl`,
#' `data.frame`) with 18 rows and 5 columns.
#' @keywords datasets
#' @examples
#' 
#' print(ccme_glyphosate, n=Inf)
#' 
"ccme_glyphosate"
