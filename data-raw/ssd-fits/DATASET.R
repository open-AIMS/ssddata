#    Copyright 2021 Province of British Columbia
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.1
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

library(readr)
library(usethis)
library(dplyr)
library(tidyr)

ssd_fits <- read_csv("data-raw/ssd-fits/ssd-fits.csv",
  col_types = cols(
    Dataset = col_character(),
    Filter = col_character(),
    Software = col_character(),
    Version = col_character(),
    Distribution = col_character(),
    PC = col_integer(),
    Estimate = col_double(),
    SE = col_double(),
    Lower = col_double(),
    Upper = col_double(),
    Reference = col_character(),
    Notes = col_character()
  )
)


# # Append fit data from May 7th 2021
# load("data-raw/ssd-fits/ssd-fit-data/ssdtools_v0.3.32021-05-12burrlioz_fits_batch.RData")
# load("data-raw/ssd-fits/ssd-fit-data/ssdtools_v0.3.32021-05-12shiny_default.RData")
# 
# 
# all_ssd_fits[[1]]$hc_out
# summary(all_ssd_fits[[1]]$dist[[1]])
# names(all_ssd_fits)
# 
# new_fits[[1]]$hc_out
# summary(new_fits[[1]]$dist[[1]])
# names(new_fits)
# 
# all_fits_add <- bind_rows(lapply(all_ssd_fits, FUN = function(x) {
#   x$hc_out
# }), .id = "Dataset") %>%
#   dplyr::mutate(
#     Notes = "llogis-gamma-lnorm model averaged fit with 10000 bootstrap iterations. Used geometric mean of multiple species (if relevant)",
#     Filter = NA,
#     Software = "ssdtools",
#     Version = "0.3.3",
#     Distribution = "averaged",
#     PC = 100 - percent,
#     Estimate = est,
#     SE = se,
#     Lower = lcl,
#     Upper = ucl,
#     Reference = "data-raw/ssd-fits/ssd-fit-data/ssdtools_v0.3.32021-05-12shiny_default.RData"
#   ) %>%
#   dplyr::select(all_of(colnames(ssd_fits)))
# 
# new_fits_add <- cbind(do.call("rbind", lapply(new_fits, FUN = function(x) {
#   x$hc_out
# })), burrlioz_fits) %>%
#   dplyr::mutate(
#     Notes = paste(
#       sapply(new_fits, FUN = function(x) {
#         paste(names(x$dist), collapse = "-")
#       }),
#       " model averaged fit with 10000 bootstrap iterations. Used geometric mean of multiple species (if relevant)"
#     ),
#     Software = "ssdtools",
#     Version = "0.3.3",
#     Distribution = "averaged",
#     Estimate = est,
#     SE = se,
#     Lower = lcl,
#     Upper = ucl,
#     Reference = "data-raw/ssd-fits/ssd-fit-data/ssdtools_v0.3.32021-05-12burrlioz_fits_batch.RData"
#   ) %>%
#   dplyr::select(all_of(colnames(ssd_fits)))
# 
# ssd_fits <- rbind(ssd_fits, all_fits_add, new_fits_add) %>%
#   arrange(Dataset, Filter, PC) %>%
#   distinct()

use_data(ssd_fits, overwrite = TRUE)
