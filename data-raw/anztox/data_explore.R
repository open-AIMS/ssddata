library(DBI)
library(RSQLite)
sql_file <- "data-raw/anztox/raw/DBASE-setacorg_bolt942.sql"
sqlite_db <- "data-raw/anztox/anztox_inspection.sqlite"


con <- dbConnect(SQLite(), sqlite_db)
