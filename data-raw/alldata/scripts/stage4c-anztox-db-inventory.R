# Stage 4c, Part 1 — read-only schema inventory against the live ANZTOX
# PostgreSQL database (infogathering), scoped to fields relevant for
# duplicate detection (test statistic type, effect/endpoint category,
# duration, life stage, study/reference). No tables are written to; no
# DATASET.R files, .rda files, or source CSVs are touched. Findings are
# written up in scripts/stage4c-schema-inventory.md — this script is kept
# for reproducibility only, mirroring the convention established by
# scripts/stage4a-supplementary-db-audit.R.
#
# Connection block copied verbatim (parameters only) from
# data-raw/anztox/DATASET.R.

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
  connect_error <- "No DB password available."
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
  stop("Cannot proceed without a DB connection.")
}

schema_of <- function(tbl) {
  dbGetQuery(
    con,
    sprintf(
      "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '%s' ORDER BY ordinal_position",
      tbl
    )
  )
}

distinct_vals <- function(tbl, col, limit = 40) {
  dbGetQuery(
    con,
    sprintf(
      'SELECT "%s", COUNT(*) as n FROM "%s" GROUP BY "%s" ORDER BY n DESC LIMIT %d',
      col, tbl, col, limit
    )
  )
}

# -----------------------------------------------------------------------
# Step 1a/1b — toxicityvalue2000 / toxicityvalue2016 full column lists
# -----------------------------------------------------------------------
cat("\n\n========== STEP 1a/1b: COLUMN LISTS ==========\n")

for (tbl in c("toxicityvalue", "toxicityvalue2000", "toxicityvalue2016")) {
  cat("\n=== ", tbl, " schema ===\n", sep = "")
  print(schema_of(tbl))
}

# -----------------------------------------------------------------------
# Candidate columns flagged by name (per task brief) plus columns
# identified from the TAG.Domain C# source (data-raw/anztox/raw/ANZTOX
# database/src/TAG.Domain/): effect_id, effectused_id, endpoint_id,
# duration_id, durationunit_id, durationhour_id, age_id, reference_id.
# -----------------------------------------------------------------------
cat("\n\n========== CANDIDATE COLUMN DISTINCT VALUES ==========\n")

cat("\n--- toxicityvalue.effect_id -> effect table (full content) ---\n")
cat("Per TAG.Domain/Models/Lookups/Effect.cs: 'Was Effect table in old\n")
cat("toxicology system. Should contain values like EC10 (10% effect\n")
cat("concentration)' -- i.e. this is documented as the STATISTIC-TYPE\n")
cat("table, distinct from the Endpoint table.\n")
print(dbReadTable(con, "effect"))

cat("\n--- toxicityvalue.endpoint_id -> endpoint table (full content) ---\n")
print(dbReadTable(con, "endpoint"))

cat("\n--- population of effect_id / endpoint_id on base toxicityvalue table ---\n")
print(dbGetQuery(
  con,
  "SELECT
     COUNT(*) AS n_total,
     COUNT(effect_id) AS n_effect_id_populated,
     COUNT(endpoint_id) AS n_endpoint_id_populated,
     COUNT(duration_id) AS n_duration_id_populated,
     COUNT(durationunit_id) AS n_durationunit_id_populated,
     COUNT(durationhour_id) AS n_durationhour_id_populated,
     COUNT(concentrationunit_id) AS n_concentrationunit_id_populated
   FROM toxicityvalue"
))

cat("\n--- population of effect_id/endpoint_id, split by 2000 vs 2016 membership ---\n")
print(dbGetQuery(
  con,
  "SELECT
     CASE WHEN t2000.toxicityvalue_id IS NOT NULL THEN '2000' ELSE '2016' END AS dataset,
     COUNT(*) AS n_total,
     COUNT(tv.effect_id) AS n_effect_id_populated,
     COUNT(tv.endpoint_id) AS n_endpoint_id_populated,
     COUNT(tv.duration_id) AS n_duration_id_populated,
     COUNT(tv.durationunit_id) AS n_durationunit_id_populated,
     COUNT(tv.durationhour_id) AS n_durationhour_id_populated
   FROM toxicityvalue tv
   LEFT JOIN toxicityvalue2000 t2000 ON t2000.toxicityvalue_id = tv.id
   LEFT JOIN toxicityvalue2016 t2016 ON t2016.toxicityvalue_id = tv.id
   WHERE t2000.toxicityvalue_id IS NOT NULL OR t2016.toxicityvalue_id IS NOT NULL
   GROUP BY dataset"
))

cat("\n--- distinct effect_id values actually used, joined to effect.name, by dataset ---\n")
print(dbGetQuery(
  con,
  "SELECT
     CASE WHEN t2000.toxicityvalue_id IS NOT NULL THEN '2000' ELSE '2016' END AS dataset,
     e.name AS effect_name, COUNT(*) AS n
   FROM toxicityvalue tv
   LEFT JOIN toxicityvalue2000 t2000 ON t2000.toxicityvalue_id = tv.id
   LEFT JOIN toxicityvalue2016 t2016 ON t2016.toxicityvalue_id = tv.id
   LEFT JOIN effect e ON e.id = tv.effect_id
   WHERE t2000.toxicityvalue_id IS NOT NULL OR t2016.toxicityvalue_id IS NOT NULL
   GROUP BY dataset, e.name
   ORDER BY dataset, n DESC"
))

cat("\n--- toxicityvalue2000.effectused_id -> effect table, distinct values + n ---\n")
print(dbGetQuery(
  con,
  "SELECT e.name AS effectused_name, COUNT(*) AS n
   FROM toxicityvalue2000 t2000
   LEFT JOIN effect e ON e.id = t2000.effectused_id
   GROUP BY e.name
   ORDER BY n DESC"
))

cat("\n--- toxicityvalue2000.effectused_id population ---\n")
print(dbGetQuery(
  con,
  "SELECT COUNT(*) AS n_total, COUNT(effectused_id) AS n_populated FROM toxicityvalue2000"
))

# -----------------------------------------------------------------------
# Duration / DurationUnit lookups (shared base toxicityvalue table)
# -----------------------------------------------------------------------
cat("\n\n========== DURATION ==========\n")

cat("\n--- duration table (full content, first 60 rows) ---\n")
print(head(dbReadTable(con, "duration"), 60))
cat("\n--- duration table row count ---\n")
print(dbGetQuery(con, "SELECT COUNT(*) AS n FROM duration"))

cat("\n--- durationunit table (full content) ---\n")
print(dbReadTable(con, "durationunit"))

cat("\n--- distinct duration_id values used (joined to duration.name), by dataset ---\n")
print(dbGetQuery(
  con,
  "SELECT
     CASE WHEN t2000.toxicityvalue_id IS NOT NULL THEN '2000' ELSE '2016' END AS dataset,
     d.name AS duration_name, COUNT(*) AS n
   FROM toxicityvalue tv
   LEFT JOIN toxicityvalue2000 t2000 ON t2000.toxicityvalue_id = tv.id
   LEFT JOIN toxicityvalue2016 t2016 ON t2016.toxicityvalue_id = tv.id
   LEFT JOIN duration d ON d.id = tv.duration_id
   WHERE t2000.toxicityvalue_id IS NOT NULL OR t2016.toxicityvalue_id IS NOT NULL
   GROUP BY dataset, d.name
   ORDER BY dataset, n DESC
   LIMIT 60"
))

cat("\n--- distinct durationunit_id values used (joined to durationunit.name), by dataset ---\n")
print(dbGetQuery(
  con,
  "SELECT
     CASE WHEN t2000.toxicityvalue_id IS NOT NULL THEN '2000' ELSE '2016' END AS dataset,
     du.name AS durationunit_name, COUNT(*) AS n
   FROM toxicityvalue tv
   LEFT JOIN toxicityvalue2000 t2000 ON t2000.toxicityvalue_id = tv.id
   LEFT JOIN toxicityvalue2016 t2016 ON t2016.toxicityvalue_id = tv.id
   LEFT JOIN durationunit du ON du.id = tv.durationunit_id
   WHERE t2000.toxicityvalue_id IS NOT NULL OR t2016.toxicityvalue_id IS NOT NULL
   GROUP BY dataset, du.name
   ORDER BY dataset, n DESC"
))

cat("\n--- distinct durationhour_id values used (joined to duration.name as 'hours' field), by dataset ---\n")
print(dbGetQuery(
  con,
  "SELECT
     CASE WHEN t2000.toxicityvalue_id IS NOT NULL THEN '2000' ELSE '2016' END AS dataset,
     dh.name AS durationhour_name, COUNT(*) AS n
   FROM toxicityvalue tv
   LEFT JOIN toxicityvalue2000 t2000 ON t2000.toxicityvalue_id = tv.id
   LEFT JOIN toxicityvalue2016 t2016 ON t2016.toxicityvalue_id = tv.id
   LEFT JOIN duration dh ON dh.id = tv.durationhour_id
   WHERE t2000.toxicityvalue_id IS NOT NULL OR t2016.toxicityvalue_id IS NOT NULL
   GROUP BY dataset, dh.name
   ORDER BY dataset, n DESC
   LIMIT 30"
))

# -----------------------------------------------------------------------
# Life stage: Age table, toxicityvalue2016-only per C# model
# -----------------------------------------------------------------------
cat("\n\n========== LIFE STAGE (Age, 2016 only per domain model) ==========\n")

cat("\n--- age table (full content) ---\n")
print(dbReadTable(con, "age"))

cat("\n--- toxicityvalue2016.age_id population + distinct values ---\n")
print(dbGetQuery(
  con,
  "SELECT a.name AS age_name, COUNT(*) AS n
   FROM toxicityvalue2016 t2016
   LEFT JOIN age a ON a.id = t2016.age_id
   GROUP BY a.name
   ORDER BY n DESC"
))

cat("\n--- confirm toxicityvalue2000 has no age_id column (expect query error or 0 cols) ---\n")
print(schema_of("toxicityvalue2000")$column_name[grepl("age", schema_of("toxicityvalue2000")$column_name, ignore.case = TRUE)])

# -----------------------------------------------------------------------
# Statistic lookup table: confirm orphaned / unused per domain model
# (not referenced by ToxicityValueMap, ToxicityValue2000Map, or
# ToxicityValue2016Map in the C# source)
# -----------------------------------------------------------------------
cat("\n\n========== STATISTIC TABLE (suspected orphaned per C# model) ==========\n")

cat("\n--- does a 'statistic' table exist, and what does it contain? ---\n")
all_tables <- dbListTables(con)
cat("'statistic' in dbListTables():", "statistic" %in% all_tables, "\n")
if ("statistic" %in% all_tables) {
  print(dbReadTable(con, "statistic"))
}

cat("\n--- any column across toxicityvalue/toxicityvalue2000/toxicityvalue2016 referencing statistic? ---\n")
for (tbl in c("toxicityvalue", "toxicityvalue2000", "toxicityvalue2016")) {
  cols <- schema_of(tbl)$column_name
  hits <- cols[grepl("stat", cols, ignore.case = TRUE)]
  cat(tbl, ": ", if (length(hits) == 0) "none" else paste(hits, collapse = ", "), "\n", sep = "")
}

# -----------------------------------------------------------------------
# Step 1d — Reference / study identifier join path
# -----------------------------------------------------------------------
cat("\n\n========== STUDY / REFERENCE ==========\n")

cat("\n--- reference table schema ---\n")
print(schema_of("reference"))

cat("\n--- toxicityvalue2000.reference_id population ---\n")
print(dbGetQuery(
  con,
  "SELECT COUNT(*) AS n_total, COUNT(reference_id) AS n_populated FROM toxicityvalue2000"
))

cat("\n--- toxicityvalue2016: datasource / record field population (no reference_id FK) ---\n")
print(dbGetQuery(
  con,
  "SELECT COUNT(*) AS n_total,
          COUNT(datasource) AS n_datasource_populated,
          COUNT(record) AS n_record_populated
   FROM toxicityvalue2016"
))

cat("\n--- guidelinegroup table (2016-only grouping FK) schema + row count ---\n")
print(schema_of("guidelinegroup"))
print(dbGetQuery(con, "SELECT COUNT(*) AS n_groups FROM guidelinegroup"))
print(dbGetQuery(
  con,
  "SELECT COUNT(*) AS n_total, COUNT(guidelinegroup_id) AS n_populated FROM toxicityvalue2016"
))
cat("\n--- distribution of toxicityvalue2016 rows per guidelinegroup_id (top 20) ---\n")
print(dbGetQuery(
  con,
  "SELECT guidelinegroup_id, COUNT(*) AS n
   FROM toxicityvalue2016
   GROUP BY guidelinegroup_id
   ORDER BY n DESC
   LIMIT 20"
))

# -----------------------------------------------------------------------
# ConcentrationType (already known to be a derivation-method flag, not a
# statistic type) -- re-confirm distinct values for completeness.
# -----------------------------------------------------------------------
cat("\n\n========== concentrationtype (derivation method, not statistic type) ==========\n")
print(dbReadTable(con, "concentrationtype"))

# -----------------------------------------------------------------------
# exposuretype (flagged by the "type" name-pattern candidate-column rule;
# 2000-only per C# model -- "Was Method table in old system")
# -----------------------------------------------------------------------
cat("\n\n========== exposuretype (2000 only; test exposure method, not statistic type) ==========\n")
print(dbReadTable(con, "exposuretype"))
cat("\n--- toxicityvalue2000.exposuretype_id population + distinct values ---\n")
print(dbGetQuery(
  con,
  "SELECT et.name AS exposuretype_name, COUNT(*) AS n
   FROM toxicityvalue2000 t2000
   LEFT JOIN exposuretype et ON et.id = t2000.exposuretype_id
   GROUP BY et.name
   ORDER BY n DESC"
))
print(dbGetQuery(
  con,
  "SELECT COUNT(*) AS n_total, COUNT(exposuretype_id) AS n_populated FROM toxicityvalue2000"
))

cat("\n\n========== DONE ==========\n")
