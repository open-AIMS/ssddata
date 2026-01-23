#' Species Sensitivity Data from US EPA ECOTOX Database
#'
#' This dataset contains \Sexpr{data(wqbench_data, package = "ssddata");
#' length(unique(wqbench_data$cas))} different chemicals. The data comes from
#' the US EPA ECOTOX database but is cleaned and standardized by the
#' [`wqbench`](https://github.com/bcgov/wqbench/) package. TODO NOTE ADDITIONAL PROCESSING
#' These data were sourced from: 
#'\insertRef{epa2025ecotox}{ssddata} 
#'
#' The columns are as follows:
#' 
#' \describe{ 
#'\item{chemical_name}{The chemical common name (chr).}
#'\item{cas}{The chemical cas number (chr).}
#'\item{latin_name}{The species latin name (chr).}
#'\item{common_name}{The species common name (chr).}
#'\item{effect}{The effect that was being tested (chr).}
#'\item{sp_aggre_conc_mg.L}{The chemical concentration in micrograms per Litre (dbl).}
#'\item{trophic_group}{Trophic group of species (fct).}
#'\item{ecological_group}{Identification of salmonids and planktonic invertebrates. If neither of these, listed as “other” (fct).}
#'\item{species_present_in_bc}{Whether the species in present in British Columbia, Canada (logi).} 
#'\item{class}{The class name (chr).} 
#'\item{tax_order}{The order name (chr).} 
#'\item{family}{The family name  (chr).} 
#' }
#' 
#' @name wqbench_data
#' @docType data
#' @format An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
#'   \Sexpr{data(wqbench_data, package = "ssddata"); nrow(wqbench_data)} rows
#'   and \Sexpr{data(wqbench_data, package = "ssddata"); ncol(wqbench_data)}
#'   columns.
#' @keywords datasets
#' @examples
#' 
#' print(wqbench_data)
#' 
"wqbench_data"
