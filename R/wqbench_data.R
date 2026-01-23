#' Species Sensitivity Data from US EPA ECOTOX Database
#'
#' This dataset contains \Sexpr{data(wqbench_data, package = "ssddata");
#' length(unique(wqbench_data$cas))} different chemicals. The data comes from
#' the US EPA ECOTOX database but is cleaned and standardized by the
#' [`wqbench`](https://github.com/bcgov/wqbench/) package.
#' 
#' These data were sourced from: 
#'\insertRef{epa2025ecotox}{ssddata} 
#'
#'@details 
#' The data cleaning steps closely follow the wqbench processing procedures 
#' and the resulting data should be very similar. 
#' 
#' In brief, the wqbench processing compiles data from the ECOTOX database by firstly
#' classifying tests as either acute or chronic; converting any acute data to chronic
#' based on published acute to chronic ratios; and finally aggregating data into a single
#' row for each individual species.
#' 
#' Aggregation is achieved by grouping data by life stage; selecting the most 
#' sensitive endpoint; selecting the most preferred toxicity estimate(s) in the 
#' event that more than one are available; and applying a geometric mean if more 
#' than one value for the preferred toxicity metric are available for the most 
#' sensitive endpoint.
#' 
#' Some deviations from the wqbench processing steps were applied to generalise 
#' the data set beyond a focus on British Columbia (BC), and in part to align with
#' technical guidance from other jurisdictions (for example, Australia and New 
#' Zealand, ANZG).
#' 
#' Deviations from the wqbench processing steps include:
#' 
#' 1. All chemicals with more than six species are included regardless of whether 
#' they contain species present in BC. These would be excluded for 
#' wqbench which was designed with the aim of being representative for BC.
#' 
#' 2. Only chemicals with representative species for four or more taxonomic classes are included.
#' This was done to align somewhat with the methods for ANZG
#' (https://www.waterquality.gov.au/anz-guidelines/guideline-values/derive/warne-method-derive-2025)
#' which requires guidelines are derived only when there are taxa from four or more "distinct taxa".
#' Using class to define "distinct taxa" only approximates this requirement, because
#' the definition provided in the ANZG is not linked directly to any one taxonomic 
#' hierarchical level and therefore cannot be applied in any automated way using
#' the taxonomic hierarchy.
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
