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
library(Rd2roxygen)
source("data-raw/create_data.R")

anon_data <- read_csv("data-raw/anon/anonymous data.csv")
anon_data <- anon_data[!is.na(anon_data$Conc), ]

col_list <- list(
  Chemical = "The chemical name",
  Conc = "The chemical concentration"
)

col_desc_all_use <- col_desc_all[sort(intersect(
  names(col_desc_all),
  colnames(anon_data)
))]

create_data(anon_data[, c(names(col_desc_all_use), "Reference")],
  template = "data-raw/anon/doc_data_template.Rd", col_desc_list = col_desc_all_use,
  prefix = "anon"
)

create_data_subset(anon_data,
  template = "data-raw/anon/doc_template.Rd", col_desc_list = col_desc_all_use,
  prefix = "anon"
)
