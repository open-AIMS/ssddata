#' Chronic Species Sensitivity Data from the EnviroTox Database
#'
#' Chronic toxicity records (NOEC/NOEL) from the EnviroTox database 2.0.0
#' \insertRef{Connors2019}{ssddata}, aggregated to one geometric mean
#' concentration per species per chemical.
#'
#' @details
#' **Copyright and Terms of Use**: The EnviroTox Database is copyrighted
#' (c) 2019 Health and Environmental Sciences Institute (HESI). All rights reserved.
#' **No redistribution license is granted.** Only citation of the database
#' is requested: \insertRef{Connors2019}{ssddata}. Users of these datasets
#' must cite this reference in any publications or reports.
#'
#' The data are aggregated following the code provided by
#' \insertRef{Yanagihara2024}{ssddata} with three exceptions: the dataset also
#' includes chemicals with (1) a bimodality coefficient > 0.555, (2) between
#' six and nine species, and (3) two trophic groups.
#'
#' The logical column `Yanagihara24` indicates whether a chemical meets the
#' criteria used by Yanagihara et al. (2024): bimodality coefficient <= 0.555,
#' at least 10 species, and at least three trophic groups.
#'
#' See `envirotox_chemical` for the corresponding CAS Registry Numbers, and
#' `envirotox_data` for the complete list dataset.
#'
#' @seealso [envirotox_data], [envirotox_acute], [envirotox_chemical]
#'
#' @name envirotox_chronic
#' @docType data
#' @format A tibble with 1,721 rows and 5 columns:
#' \describe{
#'   \item{Chemical}{Chemical name (chr).}
#'   \item{Conc}{Geometric mean concentration in micrograms per litre (dbl).}
#'   \item{Species}{Latin species name (chr).}
#'   \item{Group}{Taxonomic group of species (chr).}
#'   \item{Yanagihara24}{Whether the chemical meets the criteria of
#'     Yanagihara et al. (2024) (lgl).}
#' }
#' @source <https://envirotoxdatabase.org/>
#' @references
#' \insertRef{Connors2019}{ssddata}
#'
#' \insertRef{Yanagihara2024}{ssddata}
#' @keywords datasets internal
#' @examples
#'
#' head(envirotox_chronic)
#'
"envirotox_chronic"
