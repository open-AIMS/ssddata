#' CCME Species Sensitivity Data
#' 
#' Species Sensitivity Data from the Canadian Council of Ministers of the
#' Environment. The taxonomic groups are Amphibian, Fish, Invertebrate and
#' Plant. Plants includes freshwater algae.
#' 
#' Additional information on each of the chemicals is available from the CCME
#' website.
#' 
#' \describe{
#'	\item{boron}{\insertRef{Boron}{ssddata}}
#'	\item{cadmium}{\insertRef{Cadmium}{ssddata}}
#'	\item{chloride}{\insertRef{Chloride}{ssddata}}
#'	\item{endosulfan}{\insertRef{Endosulfan}{ssddata}}
#'	\item{glyphosate}{\insertRef{Glyphosate}{ssddata}}
#'	\item{uranium}{\insertRef{Uranium}{ssddata}}
#'	\item{silver}{\insertRef{Silver}{ssddata}} 
#'}
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
#' @name ccme_data
#' @docType data
#' @format An object of class `tbl_df` (inherits from `tbl`,
#' `data.frame`) with 144 rows and 5 columns.
#' @keywords datasets
#' @examples
#' 
#' head(ccme_data)
#' 
"ccme_data"
