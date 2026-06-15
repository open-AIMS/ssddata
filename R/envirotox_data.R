#' Species Sensitivity Data from the EnviroTox Database
#'
#' A named list containing Species Sensitivity Distribution (SSD) datasets derived
#' from the EnviroTox database 2.0.0 \insertRef{Connors2019}{ssddata}.
#'
#' @details
#' **Copyright and Terms of Use**: The EnviroTox Database is copyrighted
#' (c) 2019 Health and Environmental Sciences Institute (HESI). All rights reserved.
#' **No redistribution license is granted.** Only citation of the database
#' is requested: \insertRef{Connors2019}{ssddata}. Users of these datasets
#' must cite this reference in any publications or reports.
#'
#' The `envirotox` data contains SSD datasets from the
#' [EnviroTox database](https://envirotoxdatabase.org/) 2.0.0
#' (Connors et al. 2019). The datasets are provided for assessing general
#' patterns in SSD data and for testing code. The datasets should not be used
#' to draw any conclusions about the toxicity of individual chemicals.
#'
#' The data are aggregated following the code provided by
#' \insertRef{Yanagihara2024}{ssddata} with three exceptions: the datasets
#' also include chemicals with (1) a bimodality coefficient > 0.555,
#' (2) between six and nine species, and (3) two trophic groups.
#'
#' The logical column `Yanagihara24` in `$acute` and `$chronic` indicates
#' which chemicals meet the original criteria of Yanagihara et al. (2024):
#' bimodality coefficient <= 0.555, at least 10 species, and at least three
#' trophic groups.
#'
#' The logical column `Iwasaki25` in `$acute` indicates which chemicals were
#' included in the analysis of \insertRef{Iwasaki2025}{ssddata}: more than 50
#' species and at least three trophic groups, excluding certain metals.
#'
#' The full reproducible workflow to generate the three component datasets
#' is in `data-raw/envirotox/DATASET.R`.
#'
#' @seealso [envirotox_acute], [envirotox_chronic], [envirotox_chemical]
#'
#' @name envirotox_data
#' @docType data
#' @format A named list with three elements:
#' \describe{
#'   \item{acute}{A tibble with 14,949 rows and 6 columns of acute toxicity
#'     records (EC50/LC50). See [envirotox_acute] for full column descriptions.}
#'   \item{chronic}{A tibble with 1,721 rows and 5 columns of chronic toxicity
#'     records (NOEC/NOEL). See [envirotox_chronic] for full column descriptions.}
#'   \item{chemical}{A tibble with 744 rows and 2 columns mapping chemical
#'     names to CAS Registry Numbers. See [envirotox_chemical] for full column
#'     descriptions.}
#' }
#' @source <https://envirotoxdatabase.org/>
#' @references
#' \insertRef{Connors2019}{ssddata}
#'
#' \insertRef{Yanagihara2024}{ssddata}
#'
#' \insertRef{Iwasaki2025}{ssddata}
#' @keywords datasets
#' @examples
#'
#' data("envirotox_data")
#' names(envirotox_data)
#' head(envirotox_data$acute)
#' head(envirotox_data$chronic)
#' head(envirotox_data$chemical)
#'
"envirotox_data"
