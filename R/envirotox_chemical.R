#' Chemical Lookup Table for the EnviroTox Datasets
#'
#' A lookup table mapping chemical names to their original CAS Registry Numbers
#' for all chemicals present in `envirotox_acute` and `envirotox_chronic`.
#'
#' @details
#' This table is a companion to `envirotox_acute` and `envirotox_chronic`.
#' It is not an SSD-ready dataset but provides the CAS Registry Numbers
#' needed to join the envirotox datasets to other chemical databases.
#'
#' Source database: EnviroTox 2.0.0 \insertRef{Connors2019}{ssddata}.
#'
#' See `envirotox_data` for the full list dataset including all three components.
#'
#' @seealso [envirotox_data], [envirotox_acute], [envirotox_chronic]
#'
#' @name envirotox_chemical
#' @docType data
#' @format A tibble with 744 rows and 2 columns:
#' \describe{
#'   \item{Chemical}{Chemical name (chr).}
#'   \item{OriginalCAS}{Original CAS Registry Number (int).}
#' }
#' @source <https://envirotoxdatabase.org/>
#' @references
#' \insertRef{Connors2019}{ssddata}
#' @keywords datasets internal
#' @examples
#'
#' head(envirotox_chemical)
#'
"envirotox_chemical"
