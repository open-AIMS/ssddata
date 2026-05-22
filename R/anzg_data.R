#' ANZG Species Sensitivity Data
#' 
#' ANZG Species Sensitivity Data provided by the Department of Agriculture
#' Water and the Environment, Australia.
#' 
#' These data are licensed under CC BY 4.0 (summary of terms provided here:
#' \url{https://creativecommons.org/licenses/by/4.0/}).
#' 
#' Additional information is available from the Water Quality website at
#' \url{https://www.waterquality.gov.au/}.
#' 
#' Additional information may be available from the primary source for each
#' chemical:
#' 
#' \describe{
#'	\item{metolachlor_fresh}{\insertRef{anzg_toxicant_2020}{ssddata}}
#'	\item{alpha_cypermethrin_fresh}{\insertRef{Alpha-cypermethrin2023}{ssddata}}
#'	\item{aluminium_marine}{\insertRef{aluminium-marine2025}{ssddata}}
#'	\item{ametryn_fresh}{\insertRef{ametryn-fresh2025}{ssddata}}
#'	\item{ammonia_fresh}{\insertRef{ammonia-fresh2026}{ssddata}}
#'	\item{bisphenol_a_fresh}{\insertRef{bisphenol-a-fresh2023}{ssddata}}
#'	\item{bisphenol_a_marine}{\insertRef{bisphenol-a-marine2023}{ssddata}}
#'	\item{boron_fresh}{\insertRef{boron-fresh2021}{ssddata}}
#'	\item{chromium_III_fresh}{\insertRef{chromiumIII-fresh2026}{ssddata}} 
#'}
#' 
#' The columns are as follows, noting that some information may not be
#' available for all chemicals:
#' 
#' \describe{ 
#'\item{Chemical}{The chemical name (chr).}
#'\item{Conc}{The chemical concentration in micrograms per Litre (dbl).}
#'\item{Duration}{The duration of the test in days (chr).}
#'\item{Genus}{The Genus name (chr).}
#'\item{Group}{The taxonomic group (chr).}
#'\item{Life_stage}{Life stage of the test organism (chr).}
#'\item{Medium}{The medium - freshwater or marine water (chr).}
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
#' @format An object of class \code{tbl_df} (inherits from \code{tbl},
#' \code{data.frame}) with 163 rows and 12 columns.
#' @keywords datasets
#' @examples
#' 
#' head(anzg_data)
#' 
"anzg_data"
