#' ANZTOX Species Sensitivity Data
#'
#' @description
#' A curated dataset of species-level ecotoxicity data.
#' These data were sourced from the ANZTOX database, originally served by the Qld
#' government and then by SETAC,
#' and now maintained locally.
#'
#' The data were cleaned and algorithmically (machine) processed
#' for Species Sensitivity Distribution
#' (SSD) analysis using a workflow developed to mimic as closely as possible the principles
#' and decisions documented in \insertCite{ANZECC2000Guidelines}{ssddata} and \insertCite{Warne2015ANZG}{ssddata} and
#' subsequent updates \insertCite{Warne2018ANZG,Warne2025ANZG}{ssddata}.
#'
#' Data encompass two source tables from the available sql file extracted from the ANZTOX database:
#'
#' - toxicityvalue2000 (17,755 records),
#' originally sourced from \insertCite{Sunderam2000ANZECCdb}{ssddata}, a
#' Microsoft Access database distributed on CD-ROM with the ANZECC & ARMCANZ Water Quality Guidelines.
#'
#' - toxicityvalue2016 (2,794 records),
#' which is the data underpinning the subsequent 2015 and 2018 updates to the water quality
#' guidelines \insertCite{Warne2015ANZG,Warne2018ANZG}{ssddata}.
#'
#' @references
#' \insertAllCited{}
#'
#' @details
#' The data cleaning and SSD eligibility workflow is fully documented in the
#' accompanying vignette:
#' `vignette("ANZTOX-data-processing", package = "ssddata")`
#'
#' In brief:
#'
#' 1. **Harmonisation**: The 2000 and 2016 datasets differed in structure and
#'    endpoint vocabulary and were de-normalised, cleaned, and combined into a single
#'    table. Chemical variants and salts are mapped to parent compounds via a
#'    curated CAS parent lookup. Endpoint labels from 2016 are mapped to 2000
#'    effect codes.
#'
#' 2. **Test type priority**: Within each species x chemical x endpoint group,
#'    chronic data are preferred over subchronic, and subchronic over acute.
#'
#' 3. **Acute-to-chronic conversion**: Where only acute data are available for
#'    a species, acute LC/EC/IC50 values are divided by a default ACR of 10
#'    (Warne et al. 2025, Section 3.4.2.2) to obtain chronic negligible-effect
#'    equivalents before SSD fitting.
#'
#' 4. **Aggregation**: Concentration values for the same species x endpoint are
#'    geometric-mean averaged. The most sensitive endpoint per species is
#'    retained.
#'
#' 5. **Eligibility threshold**: Only chemical x media combinations with >= 5
#'    species from >= 4 distinct major taxonomic groups are retained. These are
#'    then nested into a list-column ready for SSD fitting or related functions.
#'
#' The columns are as follows:
#'
#' \describe{
#'\item{casnumber_grouped}{The grouped chemical CAS number, mapped to parent
#'   compound where applicable (chr).}
#'\item{chemicalname_grouped}{The grouped chemical name, mapped to parent
#'   compound name where applicable (chr).}
#'\item{mediatype}{Water type: "Freshwater" or "Marine" (chr).}
#'\item{data}{A list-column containing a tibble of species-level rows for that
#'   chemical x media combination. Each row represents a single species and
#'   contains columns: `scientificname`, `commonname_species`,
#'   `majorgroup`, `minorgroup`, `endpoint`,
#'   `endpoint_concentration` (geometric mean concentration in ug/L or mg/L,
#'   depending on the chemical), `testtype` (Chronic or Acute),
#'   `source_datasets` (comma-separated source: "2000", "2016", or both),
#'   and `n_acute_converted` (count of acute records that contributed to
#'   the geometric mean after ACR conversion).}
#' }
#'
#' @name anztox_data
#' @docType data
#' @format A tibble with one row per chemical x mediatype combination and columns:
#' \describe{
#'   \item{casnumber_grouped}{Grouped CAS number (character).}
#'   \item{chemicalname_grouped}{Grouped chemical name (character).}
#'   \item{mediatype}{"Freshwater" or "Marine" (character).}
#'   \item{data}{List-column of nested tibbles containing species-level toxicity data.}
#' }
#' @keywords datasets
#' @examples
#'
#' print(anztox_data)
#'
#' # Nest structure: each row contains species data ready for ssdtools
#' head(anztox_data$data[[1]])
#'
"anztox_data"
