library(wqbench)
library(tidyverse)
library(readwritesqlite)

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
    class,
    tax_order, 
    family
  )
rws_disconnect(conn)

wqbench_data <- 
  data_set %>% 
  # set all to SSD 
  mutate(method = "SSD") %>% 
  group_split(cas) %>% 
  # wqb_aggregate is designed to be applied to a dataframe of a single chemical
  map(wqbench::wqb_aggregate) %>% 
  bind_rows() %>% 
  # remove any chemicals that doesn't have at least 6 rows (ie 6 species or more)
  group_by(cas) %>% 
  filter(5 < n()) %>% 
  ungroup() %>% 
  left_join(species, by = "species_number") %>% 
  # remove any chemicals that don't have 4 or more different classes  
  group_by(cas) %>% 
  filter(n_distinct(class) >= 4) %>% 
  ungroup() 

# remove this comment and run once we have decided on the data set
usethis::use_data(wqbench_data, overwrite = TRUE)
