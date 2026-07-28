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

ssd_fits <- read_csv(
  "data-raw/ssd-fits/ssd-fits.csv",
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


# Append fit data from May 7th 2021
load(
  "data-raw/ssd-fits/ssd-fit-data/ssddata_ssdtools_v0.3.42021-09-02burrlioz_fits_batch.RData"
)
load(
  "data-raw/ssd-fits/ssd-fit-data/ssddata_ssdtools_v0.3.42021-09-02shiny_default.RData"
)


all_ssd_fits[[1]]$hc_out
summary(all_ssd_fits[[1]]$dist[[1]])
names(all_ssd_fits)

new_fits[[1]]$hc_out
summary(new_fits[[1]]$dist[[1]])
names(new_fits)

all_fits_add <- bind_rows(
  lapply(all_ssd_fits, FUN = function(x) {
    x$hc_out
  }),
  .id = "Dataset"
) %>%
  dplyr::mutate(
    Notes = "llogis-gamma-lnorm model averaged fit with 10000 bootstrap iterations. Used geometric mean of multiple species (if relevant)",
    Filter = NA,
    Software = "ssdtools",
    Version = "0.3.4",
    Distribution = "averaged",
    PC = 100 - percent,
    Estimate = est,
    SE = se,
    Lower = lcl,
    Upper = ucl,
    Reference = "data-raw/ssd-fits/ssd-fit-data/ssddata_ssdtools_v0.3.42021-09-shiny_default.RData"
  ) %>%
  dplyr::select(all_of(colnames(ssd_fits)))

new_fits_add <- cbind(
  do.call(
    "rbind",
    lapply(new_fits, FUN = function(x) {
      x$hc_out
    })
  ),
  burrlioz_fits
) %>%
  dplyr::mutate(
    Notes = paste(
      sapply(new_fits, FUN = function(x) {
        paste(names(x$dist), collapse = "-")
      }),
      " model averaged fit with 10000 bootstrap iterations. Used geometric mean of multiple species (if relevant)"
    ),
    Software = "ssdtools",
    Version = "0.3.4",
    Distribution = "averaged",
    Estimate = est,
    SE = se,
    Lower = lcl,
    Upper = ucl,
    Reference = "data-raw/ssd-fits/ssd-fit-data/ssddata_ssdtools_v0.3.42021-09-02burrlioz_fits_batch.RData"
  ) %>%
  dplyr::select(all_of(colnames(ssd_fits)))


updated_ssd_fits <- rbind(ssd_fits, all_fits_add, new_fits_add) %>%
  arrange(Dataset, Filter, PC) %>%
  distinct()

ssd_fits <- updated_ssd_fits

# Record the concentration units of each fit so unit consistency between
# ssd_fits and get_ssddata() is self-documenting and checkable (issue #47).
# Units are PER-DATASET, not uniform: ccme records mg/L / ug/L / ng/L per
# chemical, anzg/aims/csiro are ug/L. They are therefore read back from the
# raw data object each fit was computed on (the fit is in the raw data's
# units), so this stays correct if any source's units change. Sources with no
# Units column (e.g. anon) -> NA.
raw_units <- function(dataset) {
  f <- file.path("data", paste0(dataset, ".rda"))
  if (!file.exists(f)) {
    return(NA_character_)
  }
  d <- get(load(f))
  if (!"Units" %in% names(d)) {
    return(NA_character_)
  }
  u <- unique(stats::na.omit(as.character(d$Units)))
  if (length(u) == 1L) u else paste(sort(u), collapse = ";")
}
ssd_fits$Units <- vapply(ssd_fits$Dataset, raw_units, character(1))

use_data(ssd_fits, overwrite = TRUE)
