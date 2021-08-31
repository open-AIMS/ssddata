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

anzg_data <- read_csv("data-raw/anzg/anzg.csv") %>%
  dplyr::mutate(Medium = ifelse(Medium == "freshwater", "fresh", Medium)) %>%
  dplyr::mutate(
    chem_med = paste(Chemical, Medium, sep = "_"),
    test = as.factor(Species)
  ) %>%
  dplyr::rename(
    Duration = "Duration (d)",
    Life_stage = "Life stage",
    Toxicity_measure = "Toxicity measure",
    Test_endpoint = "Test endpoint"
  ) %>%
  dplyr::filter(!is.na(Conc))


col_desc_all <- list(
  Chemical = "The chemical name",
  Medium = "The medium - fresh or marine water",
  Group = "The taxonomic group",
  Phylum = "The Phylum name",
  Genus = "The Genus name",
  Species = "The species binomial name",
  Notes = "Other notes",
  Life_stage = "Life stage of the test organism",
  Duration = "The duration of the test in days",
  Toxicity_measure = "The toxicity measure used",
  Test_endpoint = "The test endpoint measure",
  Conc = "The chemical concentration in micrograms per Litre"
)

col_desc_all_use <- col_desc_all[sort(intersect(
  names(col_desc_all),
  colnames(anzg_data)
))]

create_data(anzg_data[, c(names(col_desc_all_use), "chem_med", "Reference")], ,
  template = "data-raw/anzg/doc_data_template.Rd",
  col_desc_list = col_desc_all_use,
  prefix = "anzg", chem_col = "chem_med"
)

subset_vars <- setdiff(c(
  names(col_desc_all_use),
  "chem_med", "Reference"
), c("Chemical", "Medium"))

create_data_subset(anzg_data[, subset_vars],
  template = "data-raw/anzg/doc_template.Rd",
  col_desc_list = col_desc_all_use,
  prefix = "anzg", chem_col = "chem_med"
)
