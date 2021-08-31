#    Copyright 2021 Australian Institute of Marine Science
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
#    Copyright 2021 Australian Institute of Marine Science
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

library(magrittr)
library(stringr)
library(dplyr)
library(usethis)
library(readr)
library(sinew)
source("data-raw/create_data.R")

csiro_data <- read_csv("data-raw/csiro/csiro.csv") %>%
  dplyr::mutate(Medium = ifelse(Medium == "freshwater", "fresh", Medium)) %>%
  dplyr::mutate(
    chem_med = paste(Chemical, Medium, sep = "_"),
    test = as.factor(Species)
  ) %>%
  dplyr::filter(!is.na(Conc)) %>%
  select_if(~ sum(!is.na(.)) > 0)

col_desc_all <- list(
  Chemical = "The chemical name",
  Medium = "The medium - fresh or marine water",
  Domain = "Tropical, temperate or other filter",
  Group = "Taxonomic grouping information",
  Phylum = "The Phylum name",
  Genus = "The genus name",
  Species = "The species names name",
  Notes = "Other notes",
  Life_stage = "Life stage of the test organism",
  Duration = "Test duration",
  Toxicity_measure = "Type of toxicity measure used",
  Test_endpoint = "Endpoint statistic, EC10, NEC etc",
  Conc = "The chemical concentration"
)

col_desc_all_use <- col_desc_all[sort(intersect(
  names(col_desc_all),
  colnames(csiro_data)
))]

create_data(csiro_data[, c(names(col_desc_all_use), "chem_med", "Reference")],
  template = "data-raw/csiro/doc_data_template.Rd",
  col_desc_list = col_desc_all_use,
  prefix = "csiro", chem_col = "chem_med"
)

subset_vars <- setdiff(c(
  names(col_desc_all_use),
  "chem_med", "Reference"
), c("Chemical", "Medium"))

create_data_subset(csiro_data[, subset_vars],
  template = "data-raw/csiro/doc_template.Rd",
  col_desc_list = col_desc_all_use,
  prefix = "csiro", chem_col = "chem_med"
)
