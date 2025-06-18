#' Species Sensitivity Data for chlorine_marine
#' 
#' Species Sensitivity Data provided by the Commonwealth Scientific and
#' Industrial Research Organisation of Australia for chlorine in marine water.
#' 
#' These data were sourced from: 
#'\insertRef{Batley2020}{ssddata} 
#'
#' 
#' The columns are as follows:
#' 
#' \describe{ 
#'\item{Conc}{The chemical concentration (dbl).}
#'\item{Group}{Taxonomic grouping information (chr).} 
#'
#' 
#' Where toxicity measure is not a chronic NEC, EC10 or NOEC value,
#' concentration has been converted using the appropriate default ratio, as
#' follows: 10 from acute EC50/LC50 to chronic EC10; 5 from chronic EC50 to
#' EC10; 2.5 from LOEC to EC10. Please see the primary reference material for
#' more information.
#' 
#' All concentration data are ug/L unless otherwise stated. }
#' 
#' @name csiro_chlorine_marine
#' @docType data
#' @format An object of class `tbl_df` (inherits from `tbl`,
#' `data.frame`) with 30 rows and 2 columns.
#' @keywords datasets
#' @examples
#' 
#' print(csiro_chlorine_marine, n=Inf)
#' 
"csiro_chlorine_marine"
