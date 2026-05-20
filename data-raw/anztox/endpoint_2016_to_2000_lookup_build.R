library(dplyr)
library(stringr)
library(readr)
library(DBI)
library(RPostgres)

normalize_endpoint <- function(x) {
  x |>
    as.character() |>
    str_to_lower() |>
    str_replace_all("[^a-z0-9]+", " ") |>
    str_squish()
}

map_endpoint_2016_to_2000 <- function(
  endpoint_raw,
  endpoint_abbrev = NA_character_
) {
  x <- normalize_endpoint(endpoint_raw)
  a <- normalize_endpoint(endpoint_abbrev)

  case_when(
    str_detect(x, "14co2|co2 uptake") |
      str_detect(a, "14co2|co2up") ~ "14CO2 UPTAKE",
    str_detect(x, "glucose") ~ "GLUCOSEUTILISATION",
    str_detect(x, "protein") ~ "PRP",
    str_detect(x, "respir") ~ "PSR",
    str_detect(x, "photosynth") | str_detect(a, "^pse$") ~ "PSE",
    str_detect(x, "population growth|general population change") |
      str_detect(a, "^popg$") ~ "POP",
    str_detect(
      x,
      "mortality abnormal development|total frond number growth rate mortality"
    ) ~ "MORT",
    str_detect(
      x,
      "mort|surviv|lethal|death|moribund|longevity|live animal count|viabil"
    ) |
      str_detect(a, "^mor|lsur|morib|viab") ~ "MORT",
    str_detect(x, "immobil|immobility") | str_detect(a, "^imm") ~ "IMM",
    str_detect(
      x,
      "fertili|max(imum)? dimension minus diameter of fertilised eggs"
    ) |
      str_detect(a, "fert") ~ "FERTILISATION",
    str_detect(x, "hatch") | str_detect(a, "hatch") ~ "HAT",
    str_detect(x, "develop|metamorph|embryonic|mature to adult") |
      str_detect(a, "devp") ~ "DVP",
    str_detect(
      x,
      "repro|brood|offspring|fecund|fercund|fercun|neonat|spawn|young per female|abortion|sex ratio"
    ) |
      str_detect(a, "^rep") ~ "REP",
    str_detect(x, "biolum|lumines") | str_detect(a, "biolm") ~ "LUM",
    str_detect(x, "attach to host") ~ "ABD",
    str_detect(
      x,
      "growth|biomass|chlorophyll|chla|chl a|fluores|fluoresence|fluorescence|cell density|cell count|cell number|cell volume|biovolume|abundance|frond|leaf area|new leaf|number of new leaves|shoot|root|length|weight|body length|dry weight|wet weight|fresh weight|divisions per day|area under the curve|auc|hydroid"
    ) ~ "GRO",
    TRUE ~ NA_character_
  )
}

if (exists("raw_2016") && exists("lu_endpoint")) {
  raw_2016_src <- raw_2016
  lu_endpoint_src <- lu_endpoint
} else {
  con_local <- dbConnect(
    RPostgres::Postgres(),
    dbname = "infogathering",
    host = "localhost",
    port = 5432,
    user = "postgres",
    password = "X@nclidae1blennidae1"
  )

  on.exit(
    {
      if (DBI::dbIsValid(con_local)) {
        dbDisconnect(con_local)
      }
    },
    add = TRUE
  )

  raw_2016_src <- dbReadTable(con_local, "toxicityvalue2016")
  lu_endpoint_src <- dbReadTable(con_local, "endpoint")
}

endpoint_2016 <- raw_2016_src |>
  left_join(
    lu_endpoint_src |>
      rename(endpoint_measured = name, abbreviation_measured = abbreviation),
    by = c("endpointmeasurement_id" = "id")
  ) |>
  left_join(
    lu_endpoint_src |>
      rename(endpoint_paper = name, abbreviation_paper = abbreviation),
    by = c("endpointfrompaper_id" = "id")
  ) |>
  transmute(
    endpoint_2016_raw = coalesce(endpoint_measured, endpoint_paper),
    endpoint_2016_abbrev = coalesce(abbreviation_measured, abbreviation_paper)
  ) |>
  filter(!is.na(endpoint_2016_raw), str_squish(endpoint_2016_raw) != "") |>
  count(
    endpoint_2016_raw,
    endpoint_2016_abbrev,
    name = "n_rows_2016",
    sort = TRUE
  )

manual_refined <- tibble::tribble(
  ~endpoint_2016_norm                                 , ~endpoint_2000_code_manual , ~map_method_manual ,
  "fluoresence"                                       , "GRO"                      , "manual_refined"   ,
  "fluorescence"                                      , "GRO"                      , "manual_refined"   ,
  "leaf area"                                         , "GRO"                      , "manual_refined"   ,
  "chla content"                                      , "GRO"                      , "manual_refined"   ,
  "chl a fluorescence"                                , "GRO"                      , "manual_refined"   ,
  "chl a"                                             , "GRO"                      , "manual_refined"   ,
  "fercundity"                                        , "REP"                      , "manual_refined"   ,
  "fercunity"                                         , "REP"                      , "manual_refined"   ,
  "young per female"                                  , "REP"                      , "manual_refined"   ,
  "number of new leaves"                              , "GRO"                      , "manual_refined"   ,
  "cell volume"                                       , "GRO"                      , "manual_refined"   ,
  "cellular biovolume dimension of cells no of cells" , "GRO"                      , "manual_refined"   ,
  "algal cell viability"                              , "MORT"                     , "manual_refined"   ,
  "ability to attach to host"                         , "ABD"                      , "manual_refined"
)

endpoint_lookup <- endpoint_2016 |>
  mutate(endpoint_2016_norm = normalize_endpoint(endpoint_2016_raw)) |>
  left_join(manual_refined, by = "endpoint_2016_norm") |>
  mutate(
    endpoint_2000_code_rule = map_endpoint_2016_to_2000(
      endpoint_raw = endpoint_2016_raw,
      endpoint_abbrev = endpoint_2016_abbrev
    ),
    endpoint_2000_code = coalesce(
      endpoint_2000_code_manual,
      endpoint_2000_code_rule
    ),
    map_method = case_when(
      !is.na(endpoint_2000_code_manual) ~ map_method_manual,
      !is.na(endpoint_2000_code_rule) ~ "rule_refined",
      TRUE ~ "unmapped"
    ),
    needs_review = is.na(endpoint_2000_code)
  ) |>
  select(
    endpoint_2016_raw,
    endpoint_2016_abbrev,
    endpoint_2016_norm,
    n_rows_2016,
    endpoint_2000_code,
    map_method,
    needs_review
  ) |>
  arrange(desc(n_rows_2016), endpoint_2016_raw)

coverage <- endpoint_lookup |>
  summarise(
    endpoint_labels_total = n(),
    endpoint_labels_mapped = sum(!is.na(endpoint_2000_code)),
    endpoint_labels_unmapped = sum(is.na(endpoint_2000_code)),
    rows_total_2016 = sum(n_rows_2016),
    rows_mapped_2016 = sum(n_rows_2016[!is.na(endpoint_2000_code)]),
    rows_unmapped_2016 = sum(n_rows_2016[is.na(endpoint_2000_code)])
  )

top_unmapped <- endpoint_lookup |>
  filter(is.na(endpoint_2000_code)) |>
  arrange(desc(n_rows_2016), endpoint_2016_raw)

write_csv(
  endpoint_lookup,
  "data-raw/anztox/endpoint_2016_to_2000_lookup.csv"
)
