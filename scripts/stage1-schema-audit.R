#!/usr/bin/env Rscript

# Stage 1 schema audit for ssddata
# - Audits Group A curated CSV sources by prefix
# - Audits Group B primary raw sources for anztox, wqbench, envirotox
# - Audits ANZTOX CAS lookup table
# - Writes markdown report to scripts/stage1-schema-audit.md

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(purrr)
  library(stringr)
  library(tidyr)
})

if (!requireNamespace("readxl", quietly = TRUE)) {
  stop("Package 'readxl' is required to read envirotox.xlsx")
}

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
report_path <- file.path(repo_root, "scripts", "stage1-schema-audit.md")

dir.create(
  file.path(repo_root, "scripts"),
  recursive = TRUE,
  showWarnings = FALSE
)

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

normalize_name <- function(x) {
  x |>
    tolower() |>
    str_replace_all("[^a-z0-9]+", "")
}

first_match <- function(names_vec, patterns) {
  nms <- names_vec
  nms_norm <- normalize_name(nms)

  for (pat in patterns) {
    idx <- which(str_detect(nms_norm, pat))
    if (length(idx) > 0) {
      return(nms[[idx[[1]]]])
    }
  }
  NA_character_
}

field_map <- function(df) {
  nms <- names(df)
  list(
    chemical_name_field = first_match(
      nms,
      c("^chemical$", "chemicalname", "commonname", "substance", "shortname")
    ),
    species_field = first_match(
      nms,
      c("^species$", "scientificname", "latinname", "commonnamespecies")
    ),
    media_field = first_match(
      nms,
      c("^medium$", "mediatype")
    ),
    concentration_field = first_match(
      nms,
      c(
        "^conc$",
        "concentrationused",
        "concentration",
        "effectvalue",
        "dose1mean"
      )
    ),
    units_field = first_match(
      nms,
      c("^unit$", "^units$", "doseconcunit")
    ),
    cas_field = first_match(
      nms,
      c(
        "casnumbergrouped",
        "parentcasnumber",
        "^casnumber$",
        "originalcas",
        "^testcas$",
        "^cas$"
      )
    )
  )
}

value_sample <- function(df, field, n = 10) {
  if (is.na(field) || !(field %in% names(df))) {
    return(character())
  }

  vals <- df[[field]] |>
    as.character() |>
    str_trim() |>
    discard(~ is.na(.x) || .x == "") |>
    unique()

  head(vals, n)
}

infer_col_types <- function(df) {
  tibble(
    column = names(df),
    type = map_chr(df, ~ class(.x)[[1]])
  )
}

read_source <- function(path, source_id) {
  ext <- tolower(tools::file_ext(path))

  if (ext == "csv") {
    dat <- readr::read_csv(path, show_col_types = FALSE, guess_max = 100000)
    return(list(data = dat, source_path = path, source_note = "CSV"))
  }

  if (ext == "txt") {
    dat <- readr::read_delim(
      path,
      delim = "|",
      show_col_types = FALSE,
      guess_max = 100000
    )
    return(list(
      data = dat,
      source_path = path,
      source_note = "pipe-delimited TXT"
    ))
  }

  if (ext == "xlsx") {
    # EnviroTox source workbook
    sheet <- if (source_id == "envirotox") "test" else 1
    dat <- readxl::read_excel(path, sheet = sheet)
    return(list(
      data = dat,
      source_path = path,
      source_note = paste0("XLSX sheet '", sheet, "'")
    ))
  }

  stop("Unsupported file extension for: ", path)
}

escape_md <- function(x) {
  x |>
    as.character() |>
    str_replace_all("\\|", "\\\\|")
}

md_table <- function(df) {
  if (nrow(df) == 0) {
    return("(none)")
  }

  cols <- names(df)
  header <- paste0("| ", paste(cols, collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", length(cols)), collapse = " | "), " |")

  rows <- apply(df, 1, function(r) {
    paste0("| ", paste(escape_md(r), collapse = " | "), " |")
  })

  paste(c(header, sep, rows), collapse = "\n")
}

collapse_values <- function(x, n = 12) {
  if (length(x) == 0) {
    return("(none)")
  }
  x <- unique(x)
  x <- head(x, n)
  paste(x, collapse = ", ")
}

# -----------------------------------------------------------------------------
# Source discovery
# -----------------------------------------------------------------------------

# Group A (curated): CSV sources directly under each data-raw/<prefix>/
# Designed to support multiple files per prefix if introduced later.
group_a_dirs <- c("aims", "csiro", "ccme", "anzg", "anon")

group_a_files <- set_names(
  map(group_a_dirs, function(prefix) {
    list.files(
      file.path(repo_root, "data-raw", prefix),
      pattern = "\\.csv$",
      full.names = TRUE,
      recursive = FALSE,
      ignore.case = TRUE
    )
  }),
  group_a_dirs
)

# Group B primary sources
discover_group_b <- function() {
  # anztox primary CSV
  anztox_candidates <- c(
    file.path(
      repo_root,
      "data-raw",
      "anztox",
      "raw",
      "toxicityvalue_combined_clean.csv"
    ),
    file.path(
      repo_root,
      "data-raw",
      "anztox",
      "toxicityvalue_combined_clean.csv"
    )
  )
  anztox_existing <- anztox_candidates[file.exists(anztox_candidates)]
  if (length(anztox_existing) == 0) {
    stop("No anztox primary CSV found")
  }
  anztox_primary <- anztox_existing[[1]]

  # wqbench: prefer CSV if present, otherwise primary relational export table tests.txt
  wqbench_csvs <- list.files(
    file.path(repo_root, "data-raw", "wqbench"),
    pattern = "\\.csv$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )

  if (length(wqbench_csvs) > 0) {
    wqbench_primary <- wqbench_csvs[[1]]
  } else {
    wqbench_tests <- list.files(
      file.path(repo_root, "data-raw", "wqbench"),
      pattern = "tests\\.txt$",
      full.names = TRUE,
      recursive = TRUE,
      ignore.case = TRUE
    )

    if (length(wqbench_tests) == 0) {
      stop("No wqbench primary file found")
    }

    mtime <- file.info(wqbench_tests)$mtime
    wqbench_primary <- wqbench_tests[[which.max(mtime)]]
  }

  # envirotox: prefer CSV if present, otherwise envirotox.xlsx
  envirotox_csvs <- list.files(
    file.path(repo_root, "data-raw", "envirotox"),
    pattern = "\\.csv$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )

  if (length(envirotox_csvs) > 0) {
    envirotox_primary <- envirotox_csvs[[1]]
  } else {
    envirotox_xlsx <- file.path(
      repo_root,
      "data-raw",
      "envirotox",
      "envirotox.xlsx"
    )
    if (!file.exists(envirotox_xlsx)) {
      stop("No envirotox primary CSV/XLSX file found")
    }
    envirotox_primary <- envirotox_xlsx
  }

  list(
    anztox = anztox_primary,
    wqbench = wqbench_primary,
    envirotox = envirotox_primary
  )
}

group_b_files <- discover_group_b()

cas_lookup_path <- file.path(
  repo_root,
  "data-raw",
  "anztox",
  "cas_parent_lookup.csv"
)
if (!file.exists(cas_lookup_path)) {
  stop("CAS lookup table not found: ", cas_lookup_path)
}

# -----------------------------------------------------------------------------
# Audit Group A
# -----------------------------------------------------------------------------

audit_group_a_one_prefix <- function(prefix, files) {
  if (length(files) == 0) {
    return(list(
      prefix = prefix,
      file_count = 0L,
      files = character(),
      row_counts = integer(),
      union_schema = tibble(
        column = character(),
        types = character(),
        present_in = integer()
      ),
      partial_columns = character(),
      media_values = character(),
      representative_fields = c(
        chemical_name_field = NA_character_,
        species_field = NA_character_,
        media_field = NA_character_,
        concentration_field = NA_character_,
        units_field = NA_character_,
        cas_field = NA_character_
      )
    ))
  }

  file_audits <- map(files, function(path) {
    src <- read_source(path, source_id = prefix)
    dat <- src$data
    fmap <- field_map(dat)

    list(
      path = path,
      data = dat,
      row_count = nrow(dat),
      schema = infer_col_types(dat),
      fields = fmap,
      media_values = value_sample(dat, fmap$media_field, n = 50)
    )
  })

  all_schema <- map_dfr(file_audits, function(x) {
    x$schema |>
      mutate(path = x$path)
  })

  union_schema <- all_schema |>
    group_by(column) |>
    summarise(
      types = paste(sort(unique(type)), collapse = ", "),
      present_in = n_distinct(path),
      .groups = "drop"
    ) |>
    arrange(column)

  partial_columns <- union_schema |>
    filter(present_in < length(files)) |>
    pull(column)

  field_values <- map_dfr(file_audits, function(x) {
    tibble(
      chemical_name_field = x$fields$chemical_name_field,
      species_field = x$fields$species_field,
      media_field = x$fields$media_field,
      concentration_field = x$fields$concentration_field,
      units_field = x$fields$units_field,
      cas_field = x$fields$cas_field
    )
  })

  representative_fields <- map_chr(field_values, function(v) {
    v <- v[!is.na(v)]
    if (length(v) == 0) {
      NA_character_
    } else {
      names(sort(table(v), decreasing = TRUE))[[1]]
    }
  })

  list(
    prefix = prefix,
    file_count = length(files),
    files = files,
    row_counts = map_int(file_audits, "row_count"),
    union_schema = union_schema,
    partial_columns = partial_columns,
    media_values = unique(unlist(map(file_audits, "media_values"))),
    representative_fields = representative_fields
  )
}

group_a_audit <- map(
  group_a_dirs,
  function(prefix) {
    audit_group_a_one_prefix(prefix, group_a_files[[prefix]])
  }
) |>
  set_names(group_a_dirs)

# -----------------------------------------------------------------------------
# Audit Group B
# -----------------------------------------------------------------------------

audit_group_b_one <- function(source_name, path) {
  src <- read_source(path, source_id = source_name)
  dat <- src$data
  fmap <- field_map(dat)

  list(
    source = source_name,
    source_path = src$source_path,
    source_note = src$source_note,
    row_count = nrow(dat),
    schema = infer_col_types(dat),
    fields = fmap,
    chemical_values = value_sample(dat, fmap$chemical_name_field),
    species_values = value_sample(dat, fmap$species_field),
    media_values = value_sample(dat, fmap$media_field),
    units_values = value_sample(dat, fmap$units_field)
  )
}

group_b_audit <- imap(group_b_files, audit_group_b_one)

# -----------------------------------------------------------------------------
# CAS lookup audit
# -----------------------------------------------------------------------------

cas_lookup_src <- read_source(cas_lookup_path, source_id = "cas_lookup")
cas_lookup <- cas_lookup_src$data
cas_lookup_schema <- infer_col_types(cas_lookup)
cas_lookup_sample <- cas_lookup |>
  slice_head(n = 10)

# -----------------------------------------------------------------------------
# Cross-source comparison table
# -----------------------------------------------------------------------------

cross_rows_group_a <- map_dfr(group_a_audit, function(x) {
  row_count <- if (length(x$row_counts) == 0) {
    "0"
  } else {
    paste0(min(x$row_counts), "–", max(x$row_counts))
  }

  tibble(
    Source = x$prefix,
    chemical_name_field = coalesce(
      x$representative_fields[["chemical_name_field"]],
      "ABSENT"
    ),
    species_field = coalesce(
      x$representative_fields[["species_field"]],
      "ABSENT"
    ),
    media_field = coalesce(x$representative_fields[["media_field"]], "ABSENT"),
    units_field = coalesce(x$representative_fields[["units_field"]], "ABSENT"),
    cas_field = coalesce(x$representative_fields[["cas_field"]], "ABSENT"),
    row_count = row_count
  )
})

cross_rows_group_b <- map_dfr(group_b_audit, function(x) {
  tibble(
    Source = x$source,
    chemical_name_field = coalesce(x$fields$chemical_name_field, "ABSENT"),
    species_field = coalesce(x$fields$species_field, "ABSENT"),
    media_field = coalesce(x$fields$media_field, "ABSENT"),
    units_field = coalesce(x$fields$units_field, "ABSENT"),
    cas_field = coalesce(x$fields$cas_field, "ABSENT"),
    row_count = as.character(x$row_count)
  )
})

cross_source <- bind_rows(cross_rows_group_a, cross_rows_group_b) |>
  mutate(
    Source = factor(
      Source,
      levels = c(
        "aims",
        "csiro",
        "ccme",
        "anzg",
        "anon",
        "anztox",
        "wqbench",
        "envirotox"
      )
    )
  ) |>
  arrange(Source) |>
  mutate(Source = as.character(Source))

# -----------------------------------------------------------------------------
# Issues flagged
# -----------------------------------------------------------------------------

issues <- character()

# Non-CSV fallbacks for Group B
for (nm in names(group_b_audit)) {
  if (!str_detect(tolower(group_b_audit[[nm]]$source_note), "csv")) {
    issues <- c(
      issues,
      paste0(
        "Group B source '",
        nm,
        "' has no primary CSV in data-raw/; audited ",
        group_b_audit[[nm]]$source_note,
        " at `",
        gsub(paste0("^", repo_root, "/"), "", group_b_audit[[nm]]$source_path),
        "` instead."
      )
    )
  }
}

# Group A partial columns (if any)
for (nm in names(group_a_audit)) {
  pa <- group_a_audit[[nm]]$partial_columns
  if (length(pa) > 0) {
    issues <- c(
      issues,
      paste0(
        "Group A prefix '",
        nm,
        "' has columns present in some but not all files: ",
        paste(pa, collapse = ", ")
      )
    )
  }
}

# Missing key fields by source
missing_key_issues <- cross_source |>
  mutate(
    missing = pmap_chr(
      list(
        chemical_name_field,
        species_field,
        media_field,
        units_field,
        cas_field
      ),
      function(chem, spp, med, unit, cas) {
        miss <- c(
          if (chem == "ABSENT") "chemical_name" else NULL,
          if (spp == "ABSENT") "species" else NULL,
          if (med == "ABSENT") "media" else NULL,
          if (unit == "ABSENT") "units" else NULL,
          if (cas == "ABSENT") "CAS" else NULL
        )
        paste(miss, collapse = ", ")
      }
    )
  ) |>
  filter(missing != "")

if (nrow(missing_key_issues) > 0) {
  issues <- c(
    issues,
    missing_key_issues |>
      transmute(
        txt = paste0("Source '", Source, "' missing key field(s): ", missing)
      ) |>
      pull(txt)
  )
}

if (length(issues) == 0) {
  issues <- "No blocking schema issues detected in this stage-1 inventory."
}

# -----------------------------------------------------------------------------
# Notes from ANZTOX vignette (schema-relevant, manual summary)
# -----------------------------------------------------------------------------

anztox_notes <- c(
  "`cas_parent_lookup` is used to map variant/salt CAS numbers to parent compounds; key columns documented are `chemicalname`, `casnumber`, `parent_cas_dashed`, `parent_casnumber`, `parent_name`, and `match_rationale`.",
  "After parent-CAS mapping, ANZTOX processing derives grouped identifiers: `casnumber_grouped = coalesce(parent_casnumber, casnumber)` and `chemicalname_grouped = coalesce(parent_name, commonname)`.",
  "`mediatype` is normalised to canonical values (`Freshwater`, `Marine`) via a dedicated normalisation step.",
  "Eligibility filtering relies on `concentrationused` (non-missing, > 0) as the primary concentration field.",
  "The combined cleaned table (`toxicityvalue_combined_clean`) carries source and harmonised fields used downstream for grouping and SSD eligibility checks."
)

# -----------------------------------------------------------------------------
# Write report
# -----------------------------------------------------------------------------

sink(report_path)
on.exit(sink(), add = TRUE)

cat("# Stage 1 Schema Audit\n")
cat("Date: ", format(Sys.Date(), "%Y-%m-%d"), "\n\n", sep = "")

cat("## Group A: Curated datasets (aims, csiro, ccme, anzg, anon)\n\n")

for (nm in names(group_a_audit)) {
  obj <- group_a_audit[[nm]]

  cat("### ", nm, "\n\n", sep = "")
  cat("Source files:\n")
  if (length(obj$files) == 0) {
    cat("- (none found)\n\n")
  } else {
    walk(
      obj$files,
      ~ cat("- `", gsub(paste0("^", repo_root, "/"), "", .x), "`\n", sep = "")
    )
    cat("\n")
  }

  cat("- Row count range: ")
  if (length(obj$row_counts) == 0) {
    cat("0–0\n")
  } else {
    cat(min(obj$row_counts), "–", max(obj$row_counts), "\n", sep = "")
  }

  cat(
    "- Distinct media/mediatype values: ",
    collapse_values(sort(obj$media_values), n = 30),
    "\n\n",
    sep = ""
  )

  cat("#### Union of column names and types\n\n")
  cat(md_table(obj$union_schema), "\n\n")

  cat("#### Columns present in some but not all datasets in group\n\n")
  if (length(obj$partial_columns) == 0) {
    cat("- None\n\n")
  } else {
    walk(obj$partial_columns, ~ cat("- `", .x, "`\n", sep = ""))
    cat("\n")
  }
}

cat("## Group B: Uncurated datasets (anztox, wqbench, envirotox)\n\n")

for (nm in c("anztox", "wqbench", "envirotox")) {
  obj <- group_b_audit[[nm]]

  cat("### ", nm, "\n\n", sep = "")
  cat(
    "- Source used: `",
    gsub(paste0("^", repo_root, "/"), "", obj$source_path),
    "` (",
    obj$source_note,
    ")\n",
    sep = ""
  )
  cat("- Row count: ", obj$row_count, "\n", sep = "")
  cat(
    "- Is a CAS number field present? ",
    ifelse(
      is.na(obj$fields$cas_field),
      "No",
      paste0("Yes (`", obj$fields$cas_field, "`)")
    ),
    "\n\n",
    sep = ""
  )

  cat("#### All column names and types\n\n")
  cat(md_table(obj$schema), "\n\n")

  cat("#### Distinct values (sample)\n\n")
  cat(
    "- Chemical name field: `",
    coalesce(obj$fields$chemical_name_field, "ABSENT"),
    "`\n",
    sep = ""
  )
  cat(
    "  - Sample values: ",
    collapse_values(obj$chemical_values),
    "\n",
    sep = ""
  )

  cat(
    "- Species field: `",
    coalesce(obj$fields$species_field, "ABSENT"),
    "`\n",
    sep = ""
  )
  cat(
    "  - Sample values: ",
    collapse_values(obj$species_values),
    "\n",
    sep = ""
  )

  cat(
    "- Media field: `",
    coalesce(obj$fields$media_field, "ABSENT"),
    "`\n",
    sep = ""
  )
  cat("  - Sample values: ", collapse_values(obj$media_values), "\n", sep = "")

  cat(
    "- Units field: `",
    coalesce(obj$fields$units_field, "ABSENT"),
    "`\n",
    sep = ""
  )
  cat(
    "  - Sample values: ",
    collapse_values(obj$units_values),
    "\n\n",
    sep = ""
  )
}

cat("## CAS Lookup Table\n\n")
cat(
  "- Source: `",
  gsub(paste0("^", repo_root, "/"), "", cas_lookup_path),
  "`\n",
  sep = ""
)
cat("- Row count: ", nrow(cas_lookup), "\n\n", sep = "")

cat("### Column names and types\n\n")
cat(md_table(cas_lookup_schema), "\n\n")

cat("### Sample rows (10)\n\n")
cat(md_table(as.data.frame(cas_lookup_sample)), "\n\n")

cat("## Cross-source comparison\n\n")
cat(
  "| Source | chemical_name_field | species_field | media_field | units_field | cas_field | row_count |\n"
)
cat("| --- | --- | --- | --- | --- | --- | --- |\n")
for (i in seq_len(nrow(cross_source))) {
  r <- cross_source[i, ]
  cat(
    "| ",
    r$Source,
    " | ",
    r$chemical_name_field,
    " | ",
    r$species_field,
    " | ",
    r$media_field,
    " | ",
    r$units_field,
    " | ",
    r$cas_field,
    " | ",
    r$row_count,
    " |\n",
    sep = ""
  )
}
cat("\n")

cat("## Notes from ANZTOX vignette\n\n")
walk(anztox_notes, ~ cat("- ", .x, "\n", sep = ""))
cat("\n")

cat("## Issues flagged\n\n")
walk(issues, ~ cat("- ", .x, "\n", sep = ""))
cat("\n")

invisible(report_path)
