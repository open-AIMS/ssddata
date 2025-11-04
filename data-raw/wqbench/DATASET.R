library(wqbench)
library(tidyverse)

# run when there is a new database to download
data_set <- wqb_create_data_set(
  file_path = file.path("data-raw", "wqbench"),
  folder_path = file.path("data-raw", "wqbench")
)

# if the database has already been downloaded and the data set is created
data_set <- readRDS(file.path("data-raw", "wqbench", "ecotox_ascii_09_11_2025.rds"))

data_set <- 
  data_set %>% 
  group_by(cas) %>% 
  filter(5 < n()) %>% 
  ungroup()

data_wqbench_groups <- 
  data_set %>% 
  # set all to SSD
  mutate(method = "SSD") %>% 
  group_split(cas)

aggregated_data <- map(data_wqbench_groups, wqbench::wqb_aggregate)

data_wqbench <- bind_rows(aggregated_data)


# remove this comment and run once we have decided on the data set
# usethis::use_data(data_wqbench, overwrite = TRUE)
