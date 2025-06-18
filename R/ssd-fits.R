#    Copyright 2021 Province of British Columbia
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

#' Species Sensitivity Distribution Fit Data
#'
#' @format
#'
#' A tibble with 12 columns.
#'
#' \describe{
#'   \item{Dataset}{The name of the dataset in the ssddata package (chr).}
#'   \item{Filter}{Any filtering applied to the data (chr).}
#'   \item{Software}{The name of the software (chr).}
#'   \item{Version}{The version of the software (chr).}
#'   \item{Distribution}{The name of the distribution (chr)}
#'   \item{PC}{The percent of the community protected (int).}
#'   \item{Estimate}{The estimated concentration (dbl).}
#'   \item{SE}{The standard error of the estimated concentration (dbl).}
#'   \item{Lower}{The lower 95% CI of the estimated concentration (dbl).}
#'   \item{Upper}{The upper 95% CI of the estimated concentration (dbl).}
#'   \item{Source}{The source of the fit (chr).}
#'   \item{Notes}{Additional information on the fitting process (chr).}
#' }
#'
#' @examples
#' head(ssd_fits)
"ssd_fits"
