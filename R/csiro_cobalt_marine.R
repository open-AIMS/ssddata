#' Species Sensitivity Data for cobalt_marine
#' 
#' Species Sensitivity Data provided by the Commonwealth Scientific and
#' Industrial Research Organisation of Australia for cobalt in marine water.
#' 
#' These data were sourced from: 
#'\insertRef{Batley}{ssddata} 
#'
#' 
#' The columns are as follows:
#' 
#' \describe{ 
#'\item{Conc}{The chemical concentration (dbl).}
#'\item{Duration}{Test duration (chr).}
#'\item{Group}{Taxonomic grouping information (chr).}
#'\item{Life_stage}{Life stage of the test organism (chr).}
#'\item{Species}{The species names name (chr).}
#'\item{Test_endpoint}{Endpoint statistic, EC10, NEC etc (chr).}
#'\item{Toxicity_measure}{Type of toxicity measure used (chr).} 
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
#' @name csiro_cobalt_marine
#' @docType data
#' @format An object of class `tbl_df` (inherits from `tbl`,
#' `data.frame`) with 14 rows and 7 columns.
#' @keywords datasets
#' @examples
#' 
#' print(csiro_cobalt_marine, n=Inf)
#' 
"csiro_cobalt_marine"
