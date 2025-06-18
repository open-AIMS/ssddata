#' Species Sensitivity Data provided by CSIRO
#' 
#' Species Sensitivity Data provided by the Commonwealth Scientific and
#' Industrial Research Organisation of Australia.
#' 
#' Additional information may be available from the primary source for each
#' chemical:
#' 
#' \describe{
#'	\item{chlorine_marine}{\insertRef{Batley2020}{ssddata}}
#'	\item{nickel_fresh}{\insertRef{Stauber2021}{ssddata}}
#'	\item{cobalt_marine}{\insertRef{Batley}{ssddata}}
#'	\item{lead_marine}{\insertRef{Batley}{ssddata}} 
#'}
#' 
#' The columns are as follows, noting that not all information are available
#' for all chemicals:
#' 
#' \describe{ 
#'\item{Chemical}{The chemical name (chr).}
#'\item{Conc}{The chemical concentration (dbl).}
#'\item{Domain}{Tropical, temperate or other filter (chr).}
#'\item{Duration}{Test duration (chr).}
#'\item{Group}{Taxonomic grouping information (chr).}
#'\item{Life_stage}{Life stage of the test organism (chr).}
#'\item{Medium}{The medium - fresh or marine water (chr).}
#'\item{Notes}{Other notes (chr).}
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
#' @name csiro_data
#' @docType data
#' @format An object of class `tbl_df` (inherits from `tbl`,
#' `data.frame`) with 91 rows and 11 columns.
#' @keywords datasets
#' @examples
#' 
#' head(csiro_data)
#' 
"csiro_data"
