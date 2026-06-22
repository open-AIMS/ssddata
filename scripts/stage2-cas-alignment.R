library(readr)
library(dplyr)
library(stringr)
library(readxl)
library(tidyr)
library(purrr)

normalize_cas <- function(x) {
  x <- as.character(x)
  x <- str_replace_all(x, "[^0-9]", "")
  x[x == ""] <- NA_character_
  x
}

format_cas <- function(x) {
  x <- normalize_cas(x)
  out <- rep(NA_character_, length(x))
  ok <- !is.na(x) & nchar(x) >= 3
  out[ok] <- paste0(
    substr(x[ok], 1, nchar(x[ok]) - 3), "-",
    substr(x[ok], nchar(x[ok]) - 2, nchar(x[ok]) - 1), "-",
    substr(x[ok], nchar(x[ok]), nchar(x[ok]))
  )
  out
}

normalize_name <- function(x) {
  x <- as.character(x)
  x <- str_to_lower(x)
  x <- str_replace_all(x, "[[:punct:]]+", " ")
  x <- str_squish(x)
  x[x == ""] <- NA_character_
  x
}

is_salt_like <- function(x) {
  str_detect(
    normalize_name(x),
    "\b(chloride|sulphate|sulfate|nitrate|nitrite|carbonate|bicarbonate|oxide|dioxide|trioxide|phosphate|hydroxide|bromide|iodide|fluoride|sulfide|sulphide|borate|silicate|arsenate|arsenite|chromate|dichromate|molybdate|selenate|selenite|cyanide|acetate|formate|citrate|tartrate)\b"
  )
}

to_md_table <- function(df) {
  if (nrow(df) == 0) return(c("_None_", ""))
  x <- df |> mutate(across(everything(), ~replace_na(as.character(.x), "")))
  header <- paste0("| ", paste(names(x), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(x)), collapse = " | "), " |")
  rows <- apply(x, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  c(header, sep, rows, "")
}

extract_curated <- function(path, source) {
  dat <- read_csv(path, show_col_types = FALSE, guess_max = 10000)
  cas_cols <- names(dat)[str_detect(str_to_lower(names(dat)), "cas")]
  cas_val <- if (length(cas_cols)) as.character(dat[[cas_cols[[1]]]]) else rep(NA_character_, nrow(dat))
  tibble(
    source = source,
    casnumber = cas_val,
    chemicalname = as.character(dat[["Chemical"]])
  ) |>
    filter(!is.na(chemicalname), chemicalname != "") |>
    distinct() |>
    mutate(
      casnumber_norm = normalize_cas(casnumber),
      chemicalname_clean = normalize_name(chemicalname),
      has_cas = length(cas_cols) > 0
    )
}

lookup_path <- "data-raw/anztox/cas_parent_lookup.csv"
report_path <- "scripts/stage2-cas-alignment.md"
prompt_log_path <- "prompts/stage2-cas-alignment.md"
dir.create("scripts", showWarnings = FALSE, recursive = TRUE)
dir.create("prompts", showWarnings = FALSE, recursive = TRUE)

lookup0 <- read_csv(lookup_path, col_types = cols(.default = col_character()))
lookup_fixed <- lookup0 |>
  mutate(
    parent_cas_dashed = if_else(casnumber == "7783064", str_remove(parent_cas_dashed, "^\\s+"), parent_cas_dashed),
    casnumber_norm = normalize_cas(casnumber),
    parent_casnumber_norm = normalize_cas(parent_casnumber),
    chemicalname_clean = normalize_name(chemicalname),
    parent_name_clean = normalize_name(parent_name)
  )

curated <- bind_rows(
  extract_curated("data-raw/aims/aims.csv", "aims"),
  extract_curated("data-raw/csiro/csiro.csv", "csiro"),
  extract_curated("data-raw/ccme/CCME data.csv", "ccme"),
  extract_curated("data-raw/anzg/anzg.csv", "anzg")
)

anztox <- read_csv("data-raw/anztox/raw/toxicityvalue_combined_clean.csv", show_col_types = FALSE, guess_max = 10000) |>
  transmute(source = "anztox", casnumber = as.character(casnumber_grouped), chemicalname = as.character(chemicalname_grouped)) |>
  filter(!is.na(casnumber), !is.na(chemicalname), chemicalname != "") |>
  distinct() |>
  mutate(casnumber_norm = normalize_cas(casnumber), chemicalname_clean = normalize_name(chemicalname))

wqbench <- readRDS("data-raw/wqbench/ecotox_ascii_12_11_2025.rds") |>
  transmute(source = "wqbench", casnumber = as.character(cas), chemicalname = as.character(chemical_name)) |>
  filter(!is.na(casnumber), !is.na(chemicalname), chemicalname != "") |>
  distinct() |>
  mutate(casnumber_norm = normalize_cas(casnumber), chemicalname_clean = normalize_name(chemicalname))

envirotox_raw <- read_excel("data-raw/envirotox/envirotox.xlsx", sheet = "test")
envirotox <- tibble(source = "envirotox", casnumber = as.character(envirotox_raw[["CAS"]]), chemicalname = as.character(envirotox_raw[["Chemical name"]])) |>
  filter(!is.na(casnumber), !is.na(chemicalname), chemicalname != "") |>
  distinct() |>
  mutate(casnumber_norm = normalize_cas(casnumber), chemicalname_clean = normalize_name(chemicalname))

source_counts <- bind_rows(curated, anztox, wqbench, envirotox) |>
  count(source, name = "unique_chemicals") |>
  mutate(group = if_else(source %in% c("aims", "csiro", "ccme", "anzg"), "A: Curated", "B: Uncurated")) |>
  select(group, source, unique_chemicals)

lookup_by_cas <- lookup_fixed |>
  filter(!is.na(casnumber_norm)) |>
  distinct(casnumber_norm, .keep_all = TRUE)

coverage_b <- bind_rows(anztox, wqbench, envirotox) |>
  mutate(in_lookup = casnumber_norm %in% lookup_by_cas$casnumber_norm) |>
  group_by(source) |>
  summarise(total = n(), in_lookup = sum(in_lookup), missing = total - in_lookup, .groups = "drop")

missing_b <- bind_rows(anztox, wqbench, envirotox) |>
  filter(!casnumber_norm %in% lookup_by_cas$casnumber_norm) |>
  select(source, casnumber, chemicalname) |>
  distinct() |>
  arrange(source, casnumber, chemicalname)

lookup_names <- bind_rows(
  lookup_fixed |> transmute(match_name = chemicalname, match_name_clean = chemicalname_clean, parent_name, parent_cas_dashed),
  lookup_fixed |> transmute(match_name = parent_name, match_name_clean = parent_name_clean, parent_name, parent_cas_dashed)
) |>
  filter(!is.na(match_name_clean)) |>
  distinct()

curated_alignment <- pmap_dfr(
  list(curated$source, curated$chemicalname, curated$casnumber, curated$chemicalname_clean),
  function(source, chemicalname, casnumber, chemicalname_clean) {
    exact_hits <- lookup_names |> filter(match_name == chemicalname) |> distinct(parent_name, parent_cas_dashed)
    norm_hits <- lookup_names |> filter(match_name_clean == chemicalname_clean) |> distinct(parent_name, parent_cas_dashed)
    if (nrow(exact_hits) >= 1) {
      tibble(source = source, chemicalname = chemicalname, casnumber = casnumber, parent_name = exact_hits$parent_name[[1]], parent_cas_dashed = exact_hits$parent_cas_dashed[[1]], match_status = "exact_name_match")
    } else if (nrow(norm_hits) == 1) {
      tibble(source = source, chemicalname = chemicalname, casnumber = casnumber, parent_name = norm_hits$parent_name[[1]], parent_cas_dashed = norm_hits$parent_cas_dashed[[1]], match_status = "normalized_name_match_review")
    } else if (nrow(norm_hits) > 1) {
      tibble(source = source, chemicalname = chemicalname, casnumber = casnumber, parent_name = norm_hits$parent_name[[1]], parent_cas_dashed = norm_hits$parent_cas_dashed[[1]], match_status = "multiple_candidate_matches_review")
    } else {
      tibble(source = source, chemicalname = chemicalname, casnumber = casnumber, parent_name = NA_character_, parent_cas_dashed = NA_character_, match_status = "no_match_gap")
    }
  }
) |>
  arrange(source, chemicalname)

coverage_a <- curated_alignment |>
  group_by(source) |>
  summarise(total = n(), in_lookup = sum(match_status == "exact_name_match"), missing = sum(match_status == "no_match_gap"), .groups = "drop")

curated_review <- curated_alignment |> filter(match_status != "exact_name_match")

parents <- lookup_fixed |>
  transmute(parent_name, parent_name_clean, parent_casnumber, parent_cas_dashed) |>
  filter(!is.na(parent_name_clean)) |>
  distinct(parent_name_clean, .keep_all = TRUE)

expand_candidates <- bind_rows(wqbench, envirotox) |>
  filter(!casnumber_norm %in% lookup_by_cas$casnumber_norm) |>
  arrange(source, casnumber, chemicalname) |>
  distinct(casnumber_norm, .keep_all = TRUE)

infer_one <- function(casnumber_norm, chemicalname) {
  chem_clean <- normalize_name(chemicalname)
  if (is.na(chem_clean)) {
    return(tibble(parent_cas_dashed = NA_character_, parent_casnumber = NA_character_, parent_name = NA_character_, match_rationale = "NEEDS HUMAN REVIEW"))
  }
  if (!is_salt_like(chemicalname)) {
    return(tibble(parent_cas_dashed = format_cas(casnumber_norm), parent_casnumber = casnumber_norm, parent_name = chemicalname, match_rationale = "direct — no simpler parent"))
  }
  hit_idx <- map_lgl(parents$parent_name_clean, function(pn) !is.na(pn) && str_detect(chem_clean, regex(paste0("\\b", pn, "\\b"), ignore_case = TRUE)))
  hits <- parents[hit_idx, ]
  if (nrow(hits) == 1) {
    return(tibble(parent_cas_dashed = hits$parent_cas_dashed[[1]], parent_casnumber = hits$parent_casnumber[[1]], parent_name = hits$parent_name[[1]], match_rationale = paste0("heuristic salt/oxide mapping to ", hits$parent_name[[1]])))
  }
  tibble(parent_cas_dashed = NA_character_, parent_casnumber = NA_character_, parent_name = NA_character_, match_rationale = "NEEDS HUMAN REVIEW")
}

new_lookup_rows <- map2_dfr(expand_candidates$casnumber_norm, expand_candidates$chemicalname, infer_one) |>
  bind_cols(expand_candidates |> select(casnumber = casnumber_norm, chemicalname)) |>
  mutate(human_checked = "n") |>
  select(casnumber, chemicalname, parent_cas_dashed, parent_casnumber, parent_name, match_rationale, human_checked) |>
  distinct()

expanded_lookup <- bind_rows(
  lookup_fixed |> select(casnumber, chemicalname, parent_cas_dashed, parent_casnumber, parent_name, match_rationale, human_checked),
  new_lookup_rows
) |>
  distinct()

write_csv(expanded_lookup, lookup_path)

review_rows <- new_lookup_rows |> filter(match_rationale == "NEEDS HUMAN REVIEW")
all_human_n <- expanded_lookup |> filter(human_checked == "n")
coverage_summary <- bind_rows(coverage_a |> mutate(group = "A: Curated"), coverage_b |> mutate(group = "B: Uncurated")) |> select(group, source, total, in_lookup, missing)

report_lines <- c(
  "# Stage 2 CAS / Chemical Name Alignment",
  paste0("Date: ", Sys.Date()),
  "",
  "## Step 1: Data quality fix",
  "Removed the leading tab character from the Hydrogen sulfide row (`casnumber = 7783064`) in `parent_cas_dashed`.",
  "",
  "## Step 2: Chemical universe by source",
  to_md_table(source_counts),
  "## Step 3: Coverage gaps",
  to_md_table(coverage_summary),
  "### Group A curated review table",
  to_md_table(curated_alignment),
  "### Group B absent from lookup: anztox",
  to_md_table(missing_b |> filter(source == "anztox")),
  "### Group B absent from lookup: wqbench",
  to_md_table(missing_b |> filter(source == "wqbench")),
  "### Group B absent from lookup: envirotox",
  to_md_table(missing_b |> filter(source == "envirotox")),
  "## Step 4: Expanded lookup",
  paste0("Rows added: ", nrow(new_lookup_rows)),
  paste0("Rows flagged as NEEDS HUMAN REVIEW: ", nrow(review_rows)),
  "",
  "## Step 5: Curated source name alignment",
  to_md_table(curated_alignment),
  "## Human review required",
  paste0("All rows with `match_rationale = "NEEDS HUMAN REVIEW"`: ", nrow(review_rows)),
  to_md_table(review_rows),
  paste0("All rows with `human_checked = "n"`: ", nrow(all_human_n)),
  "The entire lookup remains human-unchecked and should be reviewed before Stage 6 aggregation work.",
  "",
  "Curated source mismatches flagged in Step 5:",
  to_md_table(curated_review),
  "## Issues flagged",
  "- Curated source CSVs in this snapshot do not expose CAS fields, so curated verification is name-based only.",
  "- Direct mappings for many new wqbench/envirotox rows assume the source CAS/name is already the parent form.",
  "- Salt/oxide rows with unclear parent matches are marked `NEEDS HUMAN REVIEW`.",
  "- EnviroTox names sometimes include semicolon-delimited synonyms that may need later standardization.",
  "",
  "## Prompt log",
  paste0("Session log appended to `", prompt_log_path, "`."),
  ""
)
writeLines(report_lines, report_path)

prompt_entry <- c(
  "## Session: stage2-cas-alignment",
  paste0("Date: ", Sys.Date()),
  "Model: Positron Assistant",
  "",
  "### Prompts and Responses",
  "",
  "**User:** Expand the existing CAS lookup table to cover chemicals present in wqbench and envirotox, verify curated source alignment, produce a cleaned lookup table, an R script, and a markdown report, and append a prompt log.",
  "",
  "**Claude:** Read `CLAUDE.md` and `vignettes/ANZTOX_data_processing.qmd`, fixed the Hydrogen sulfide tab character issue, extracted chemical universes from the requested sources, analyzed lookup coverage gaps, expanded the lookup for missing wqbench and envirotox CAS values with direct or review-needed mappings, wrote the expanded lookup file, generated `scripts/stage2-cas-alignment.md`, and appended this prompt log.",
  "",
  "---",
  ""
)
if (file.exists(prompt_log_path)) {
  writeLines(c(readLines(prompt_log_path), prompt_entry), prompt_log_path)
} else {
  writeLines(prompt_entry, prompt_log_path)
}

invisible(list(
  lookup_rows = nrow(expanded_lookup),
  rows_added = nrow(new_lookup_rows),
  review_rows = nrow(review_rows)
))
