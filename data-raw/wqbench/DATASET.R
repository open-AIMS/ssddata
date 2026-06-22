library(wqbench)
library(tidyverse)
library(readwritesqlite)

.map_wqbench_medium <- function(media_type) {
  media_type |>
    stringr::str_remove("/$") |>
    dplyr::case_match(
      "FW" ~ "Freshwater",
      "SW" ~ "Marine",
      .default = NA_character_
    )
}

.build_wqbench_medium_lookup <- function(data_set) {
  data_set |>
    transmute(
      Chemical = chemical_name,
      Species = latin_name,
      effect = effect,
      Medium = .map_wqbench_medium(media_type)
    ) |>
    filter(!is.na(Medium)) |>
    group_by(Chemical, Species, effect) |>
    summarise(
      Medium = if_else(n_distinct(Medium) == 1L, first(Medium), "Unknown"),
      .groups = "drop"
    )
}

# run when there is a new database to download or you haven't downloaded one yet
# data_set <- wqb_create_data_set(
#   file_path = file.path("data-raw", "wqbench"),
#   folder_path = file.path("data-raw", "wqbench")
# )

# if the database has already been downloaded and the data set is created
data_set <- readRDS(file.path(
  "data-raw",
  "wqbench",
  "ecotox_ascii_12_11_2025.rds"
))

medium_lookup <- .build_wqbench_medium_lookup(data_set)

conn <- rws_connect(file.path(
  "data-raw",
  "wqbench",
  "ecotox_ascii_12_11_2025.sqlite"
))
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
  ungroup() %>%
  # standardise column names to match ssddata conventions
  rename(
    Chemical = chemical_name,
    Species = latin_name,
    Conc = sp_aggre_conc_mg.L,
    Group = trophic_group
  ) %>%
  left_join(medium_lookup, by = c("Chemical", "Species", "effect")) %>%
  mutate(Medium = coalesce(Medium, "Unknown"))

# remove this comment and run once we have decided on the data set
usethis::use_data(wqbench_data, overwrite = TRUE)
