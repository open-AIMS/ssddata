#' ANZG Species Sensitivity Data
#' 
#' ANZG Species Sensitivity Data provided by the Department of Agriculture
#' Water and the Environment, Australia.
#' 
#' These data are licensed under CC BY 4.0 (summary of terms provided here:
#' <https://creativecommons.org/licenses/by/4.0/>).
#' 
#' Additional information is available from the Water Quality website at
#' <https://www.waterquality.gov.au/>.
#' 
#' Additional information may be available from the primary source for each
#' chemical:
#' 
#' \describe{
#'	\item{metolachlor_fresh}{\insertRef{anzg_toxicant_2020}{ssddata}} 
#'}
#' 
#' The columns are as follows, noting that some information may not be
#' available for all chemicals:
#' 
#' \describe{ 
#'\item{Chemical}{The chemical name (chr).}
#'\item{Conc}{The chemical concentration in micrograms per Litre (dbl).}
#'\item{Duration}{The duration of the test in days (dbl).}
#'\item{Genus}{The Genus name (chr).}
#'\item{Group}{The taxonomic group (chr).}
#'\item{Life_stage}{Life stage of the test organism (chr).}
#'\item{Medium}{The medium - fresh or marine water (chr).}
#'\item{Notes}{Other notes (chr).}
#'\item{Phylum}{The Phylum name (chr).}
#'\item{Species}{The species binomial name (chr).}
#'\item{Test_endpoint}{The test endpoint measure (chr).}
#'\item{Toxicity_measure}{The toxicity measure used (chr).} 
#'
#' 
#' Where toxicity measure is not a chronic NEC, EC10 or NOEC value,
#' concentration has been converted using the appropriate default ratio, as
#' follows: 10 from acute EC50/LC50 to chronic EC10; 5 from chronic EC50 to
#' EC10; 2.5 from LOEC to EC10. Please see the primary reference material for
#' more information. }
#' 
#' @name anzg_data
#' @docType data
#' @format An object of class `tbl_df` (inherits from `tbl`,
#' `data.frame`) with 21 rows and 12 columns.
#' @keywords datasets
#' @examples
#' 
#' head(anzg_data)
#' 
"anzg_data"
