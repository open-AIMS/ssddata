#' Anonymous Species Sensitivity Data
#' 
#' Species Sensitivity Data from Anonymous sources
#' 
#' Additional information on each of the chemicals may be available from their
#' primary source, at: \describe{
#'	\item{a}{\insertRef{VanDam2021}{ssddata}}
#'	\item{c}{\insertRef{VanDam2021}{ssddata}}
#'	\item{d}{\insertRef{VanDam2021}{ssddata}}
#'	\item{b}{\insertRef{VanDam2021}{ssddata}}
#'	\item{e}{\insertRef{fox2020}{ssddata}} 
#'}
#' 
#' \describe{ \item{Chemical}{The chemical (chr), in this case an anonymous
#' unique identifier.} \item{Conc}{The chemical concentration (dbl).} }
#' 
#' @name anon_data
#' @docType data
#' @format An object of class `tbl_df` (inherits from `tbl`,
#' `data.frame`) with 73 rows and 2 columns.
#' @keywords datasets
#' @examples
#' 
#' head(anon_data)
#' 
"anon_data"
