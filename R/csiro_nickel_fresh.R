#' Species Sensitivity Data for nickel_fresh
#' 
#' Species Sensitivity Data provided by the Commonwealth Scientific and
#' Industrial Research Organisation of Australia for nickel in fresh water.
#' 
#' These data were sourced from: 
#'\insertRef{Stauber2021}{ssddata} 
#'
#' 
#' The columns are as follows:
#' 
#' \describe{ 
#'\item{Conc}{The chemical concentration (dbl).}
#'\item{Domain}{Tropical, temperate or other filter (chr).}
#'\item{Group}{Taxonomic grouping information (chr).}
#'\item{Notes}{Other notes (chr).}
#'\item{Species}{The species names name (chr).}
#'\item{Test_endpoint}{Endpoint statistic, EC10, NEC etc (chr).} 
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
#' @name csiro_nickel_fresh
#' @docType data
#' @format An object of class `tbl_df` (inherits from `tbl`,
#' `data.frame`) with 31 rows and 6 columns.
#' @keywords datasets
#' @examples
#' 
#' print(csiro_nickel_fresh, n=Inf)
#' 
"csiro_nickel_fresh"
