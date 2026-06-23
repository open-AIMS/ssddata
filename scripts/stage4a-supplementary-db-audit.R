# Stage 4a supplementary DB audit — read-only queries against the live
# ANZTOX PostgreSQL database, run to resolve the units/schema gaps flagged
# in scripts/stage4a-pipeline-audit.md (the concentrationused units
# convention, the testtype "Chronic QSAR" question, and the majorgroup
# vocabulary discrepancy). No tables are written to; no DATASET.R files,
# .rda files, or source CSVs are touched by this script. Findings are
# written up in the "Supplementary DB query" section appended to
# scripts/stage4a-pipeline-audit.md — this script is kept for
# reproducibility of those findings, not as a pipeline component.

library(DBI)
library(RPostgres)
library(dplyr)

get_db_password <- function() {
  pw <- Sys.getenv("ANZTOX_DB_PASSWORD", unset = "")
  if (nzchar(pw)) {
    return(pw)
  }
  if (requireNamespace("keyring", quietly = TRUE)) {
    return(tryCatch(
      keyring::key_get("infogathering_postgres", username = "postgres"),
      error = function(e) NA_character_
    ))
  }
  NA_character_
}

pw <- get_db_password()
con <- NULL
connect_error <- NULL

if (is.na(pw)) {
  connect_error <- "No DB password available: ANZTOX_DB_PASSWORD unset and no keyring credential 'infogathering_postgres' found."
} else {
  con <- tryCatch(
    DBI::dbConnect(
      RPostgres::Postgres(),
      dbname = "infogathering",
      host = "localhost",
      port = 5432,
      user = "postgres",
      password = pw
    ),
    error = function(e) {
      connect_error <<- conditionMessage(e)
      NULL
    }
  )
}

if (!is.null(con)) {
  on.exit(
    {
      if (DBI::dbIsValid(con)) DBI::dbDisconnect(con)
    },
    add = TRUE
  )
}

cat("=== CONNECTION ===\n")
if (!is.null(con) && DBI::dbIsValid(con)) {
  cat("SUCCESS: connected to dbname=infogathering host=localhost port=5432 user=postgres\n")
} else {
  cat("FAILURE:", connect_error, "\n")
}

if (!is.null(con) && DBI::dbIsValid(con)) {
  # -----------------------------------------------------------------------
  # Q1: concentrationcode lookup table
  # -----------------------------------------------------------------------
  cat("\n=== concentrationcode table ===\n")
  print(dbReadTable(con, "concentrationcode"))

  # -----------------------------------------------------------------------
  # Q2: toxicityvalue2000 / toxicityvalue2016 schema + unit-adjacent columns
  # -----------------------------------------------------------------------
  for (tbl in c("toxicityvalue2000", "toxicityvalue2016")) {
    cat("\n=== ", tbl, " schema ===\n", sep = "")
    schema <- dbGetQuery(
      con,
      sprintf(
        "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '%s' ORDER BY ordinal_position",
        tbl
      )
    )
    print(schema)
    flagged <- schema$column_name[grepl("unit|conc", schema$column_name, ignore.case = TRUE)]
    cat("Flagged columns (unit/conc):", paste(flagged, collapse = ", "), "\n")
    for (col in flagged) {
      cat("\n--- distinct values:", tbl, ".", col, " ---\n", sep = "")
      print(dbGetQuery(
        con,
        sprintf(
          'SELECT "%s", COUNT(*) as n FROM "%s" GROUP BY "%s" ORDER BY n DESC LIMIT 20',
          col, tbl, col
        )
      ))
    }
  }

  # -----------------------------------------------------------------------
  # Q3: testtype lookup table
  # -----------------------------------------------------------------------
  cat("\n=== testtype table ===\n")
  print(dbReadTable(con, "testtype"))

  # -----------------------------------------------------------------------
  # Q4: majorgroup vocabulary — confirmed via DATASET.R that majorgroup is
  # carried in via a left_join on the species table (species_id), not a
  # separate FK'd lookup
  # -----------------------------------------------------------------------
  cat("\n=== species table schema ===\n")
  print(dbGetQuery(
    con,
    "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'species' ORDER BY ordinal_position"
  ))

  cat("\n=== distinct majorgroup values in species table ===\n")
  print(dbGetQuery(con, "SELECT majorgroup, COUNT(*) as n FROM species GROUP BY majorgroup ORDER BY n DESC"))

  cat("\n=== all table names in infogathering DB ===\n")
  print(dbListTables(con))

  # -----------------------------------------------------------------------
  # Q5 (follow-up): a "concentrationunit" lookup table exists and is keyed
  # off the RAW toxicityvalue.concentration field (concentrationunit_id),
  # not off concentrationused directly. Check whether concentrationused
  # tracks the raw concentration value 1:1 (i.e. is in the same unit), by
  # source unit and by dataset (2000 vs 2016).
  # -----------------------------------------------------------------------
  cat("\n=== concentrationunit table (full content) ===\n")
  print(dbReadTable(con, "concentrationunit"))

  cat("\n=== toxicityvalue base table schema ===\n")
  print(dbGetQuery(
    con,
    "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'toxicityvalue' ORDER BY ordinal_position"
  ))

  cat("\n=== concentrationunit_id distribution, restricted to toxicityvalue2000 ===\n")
  print(dbGetQuery(
    con,
    'SELECT cu.id, cu.name, COUNT(*) as n
     FROM toxicityvalue tv
     JOIN toxicityvalue2000 t2000 ON tv.id = t2000.toxicityvalue_id
     LEFT JOIN concentrationunit cu ON tv.concentrationunit_id = cu.id
     GROUP BY cu.id, cu.name
     ORDER BY n DESC'
  ))

  cat("\n=== concentrationunit_id distribution, restricted to toxicityvalue2016 ===\n")
  print(dbGetQuery(
    con,
    'SELECT cu.id, cu.name, COUNT(*) as n
     FROM toxicityvalue tv
     JOIN toxicityvalue2016 t2016 ON tv.id = t2016.toxicityvalue_id
     LEFT JOIN concentrationunit cu ON tv.concentrationunit_id = cu.id
     GROUP BY cu.id, cu.name
     ORDER BY n DESC'
  ))

  cat("\n-- ratio summary: concentrationused / raw concentration, by source unit (2000) --\n")
  q2000 <- dbGetQuery(
    con,
    'SELECT t2000.toxicityvalue_id, t2000.concentrationused, tv.concentration as concentration_raw,
            cu.name as unit_name
     FROM toxicityvalue2000 t2000
     JOIN toxicityvalue tv ON tv.id = t2000.toxicityvalue_id
     LEFT JOIN concentrationunit cu ON tv.concentrationunit_id = cu.id'
  )
  q2000_clean <- q2000 |>
    mutate(
      concentration_num = suppressWarnings(as.numeric(concentration_raw)),
      ratio = concentrationused / concentration_num
    ) |>
    filter(!is.na(concentration_num), !is.na(concentrationused), concentration_num > 0)
  print(
    q2000_clean |>
      group_by(unit_name) |>
      summarise(
        n = n(),
        median_ratio = median(ratio),
        min_ratio = min(ratio),
        max_ratio = max(ratio),
        pct_ratio_approx_1 = mean(abs(ratio - 1) < 0.01),
        .groups = "drop"
      ) |>
      arrange(desc(n))
  )

  cat("\n-- ratio summary: concentrationused / raw concentration, by source unit (2016) --\n")
  q2016 <- dbGetQuery(
    con,
    'SELECT t2016.toxicityvalue_id, t2016.concentrationused, tv.concentration as concentration_raw,
            cu.name as unit_name
     FROM toxicityvalue2016 t2016
     JOIN toxicityvalue tv ON tv.id = t2016.toxicityvalue_id
     LEFT JOIN concentrationunit cu ON tv.concentrationunit_id = cu.id'
  )
  q2016_clean <- q2016 |>
    mutate(
      concentration_num = suppressWarnings(as.numeric(concentration_raw)),
      ratio = concentrationused / concentration_num
    ) |>
    filter(!is.na(concentration_num), !is.na(concentrationused), concentration_num > 0)
  print(
    q2016_clean |>
      group_by(unit_name) |>
      summarise(
        n = n(),
        median_ratio = median(ratio),
        min_ratio = min(ratio),
        max_ratio = max(ratio),
        pct_ratio_approx_1 = mean(abs(ratio - 1) < 0.01),
        .groups = "drop"
      ) |>
      arrange(desc(n))
  )

  # -----------------------------------------------------------------------
  # Q6 (follow-up): does the majorgroup 2-letter/full-name split correlate
  # with whether the species is referenced by toxicityvalue2000 vs
  # toxicityvalue2016 records (species is a single shared table joined via
  # toxicityvalue.species_id from both)?
  # -----------------------------------------------------------------------
  is_two_letter_code <- function(x) grepl("^[A-Z]{2}$", x)

  q <- dbGetQuery(
    con,
    "SELECT sp.majorgroup,
            CASE WHEN t2000.toxicityvalue_id IS NOT NULL THEN TRUE ELSE FALSE END as in_2000,
            CASE WHEN t2016.toxicityvalue_id IS NOT NULL THEN TRUE ELSE FALSE END as in_2016
     FROM toxicityvalue tv
     JOIN species sp ON tv.species_id = sp.id
     LEFT JOIN toxicityvalue2000 t2000 ON t2000.toxicityvalue_id = tv.id
     LEFT JOIN toxicityvalue2016 t2016 ON t2016.toxicityvalue_id = tv.id
     WHERE t2000.toxicityvalue_id IS NOT NULL OR t2016.toxicityvalue_id IS NOT NULL"
  ) |>
    mutate(
      code_style = case_when(
        is.na(majorgroup) ~ "NA",
        is_two_letter_code(majorgroup) ~ "2-letter code",
        TRUE ~ "full name"
      ),
      dataset = case_when(
        in_2000 & in_2016 ~ "both",
        in_2000 ~ "2000 only",
        in_2016 ~ "2016 only"
      )
    )

  cat("\n-- cross-tab: majorgroup code_style x dataset-of-origin --\n")
  print(table(q$code_style, q$dataset))

  cat("\n-- majorgroup values + counts, species referenced by toxicityvalue2016 --\n")
  print(as.data.frame(q |> filter(dataset == "2016 only") |> count(majorgroup, code_style) |> arrange(majorgroup)))

  cat("\n-- majorgroup values + counts, species referenced by toxicityvalue2000 --\n")
  print(as.data.frame(q |> filter(dataset == "2000 only") |> count(majorgroup, code_style) |> arrange(majorgroup)))
}
