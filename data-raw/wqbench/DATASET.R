#    Copyright 2026 Australian Institute of Marine Science and Poisson consulting
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

library(wqbench)
library(tidyverse)
library(readwritesqlite)
library(magrittr)
library(stringr)
library(dplyr)
library(usethis)
library(readr)
library(sinew)
library(taxize)
library(purrr)
library(tibble)

source("data-raw/create_data.R")


# run when there is a new database to download or you haven't downloaded one yet
data_set <- wqb_create_data_set(
  file_path = file.path("data-raw", "wqbench"),
  folder_path = file.path("data-raw", "wqbench")
)

# if the database has already been downloaded and the data set is created
data_set <- readRDS(file.path("data-raw", "wqbench", "ecotox_ascii_12_11_2025.rds"))

conn <- rws_connect(file.path("data-raw", "wqbench", "ecotox_ascii_12_11_2025.sqlite"))
species <- rws_read_table("species", conn = conn) %>% 
  select(
    species_number,
    latin_name,
    class,
    tax_order, 
    family
  )
rws_disconnect(conn)


data_wqbench <- 
  data_set %>% 
  # set all to SSD 
  mutate(method = "SSD",
         Medium = ifelse(media_type=="FW", "fresh", ifelse(
           media_type=="SW", "marine", NA
         )),
         cas = paste(cas, "_medium: ", media_type, sep = "")) %>% 
  filter(!is.na(Medium)) |> # remove rows that are not either seawater or freshwater
  
  group_split(cas) %>% 
  # wqb_aggregate is designed to be applied to a dataframe of a single chemical
  map(wqbench::wqb_aggregate) %>% 
  bind_rows() %>% 
  # remove any chemicals that don't have at least 6 rows (ie 6 species or more)
  group_by(cas) %>% 
  filter(5 < n()) %>% 
  ungroup() %>% 
  left_join(species, by = "species_number") %>% 
  # remove any chemicals that don't have 4 or more different classes  
  group_by(cas) %>% 
  filter(n_distinct(class) >= 4) %>% 
  ungroup() 

# remove this comment and run once we have decided on the data set
usethis::use_data(data_wqbench, overwrite = TRUE)
