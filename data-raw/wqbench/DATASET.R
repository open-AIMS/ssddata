library(wqbench)
library(tidyverse)

# run when there is a new database to download or you haven't downloaded one yet
data_set <- wqb_create_data_set(
  file_path = file.path("data-raw", "wqbench"),
  folder_path = file.path("data-raw", "wqbench")
)

# if the database has already been downloaded and the data set is created
data_set <- readRDS(file.path("data-raw", "wqbench", "ecotox_ascii_09_11_2025.rds"))

data_wqbench <- 
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
  ungroup() 

# remove this comment and run once we have decided on the data set
# usethis::use_data(data_wqbench, overwrite = TRUE)
