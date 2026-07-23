#' Species Sensitivity Data for chlorine_marine
#' 
#' Species Sensitivity Data provided by the Commonwealth Scientific and
#' Industrial Research Organisation of Australia for \strong{\emph{chlorine}}
#' in marine water.
#' 
#' These data were sourced from: 
#'\insertRef{Batley2020}{ssddata} 
#'
#' 
#' The columns are as follows:
#' 
#' \describe{ 
#'\item{Conc}{The chemical concentration in micrograms per Litre (dbl).}
#'\item{Duration}{Test duration (chr).}
#'\item{Group}{Taxonomic grouping information (chr).}
#'\item{Life_stage}{Life stage of the test organism (chr).}
#'\item{Notes}{Other notes (chr).}
#'\item{Species}{The species names name (chr).}
#'\item{Test_endpoint}{Endpoint statistic, EC10, NEC etc (chr).}
#'\item{Timeframe}{Exposure timeframe basis of the value: "chronic" or "short_term". (chr).}
#'\item{Toxicity_measure}{Type of toxicity measure used (chr).}
#'\item{Units}{The concentration units of Conc (micrograms per Litre, ug/L) (chr).} 
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
#' @format An object of class \code{tbl_df} (inherits from \code{tbl},
#' \code{data.frame}) with 30 rows and 10 columns.
#' @keywords datasets
#' @examples
#' 
#' print(csiro_chlorine_marine, n=Inf)
#' 
NULL
