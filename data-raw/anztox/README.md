# ANZTOX / ANZEEC toxicity database (raw source)

This folder contains the upstream ANZTOX SQL database used as the primary
machine-readable source for toxicity values.

## Files

- `DBASE-setacorg_bolt942.sql`  
  SQL dump of the ANZTOX database used for the SETAC website.

## Provenance

- Source: SETAC / ANZTOX
- Accessed: YYYY-MM-DD
- Used as the authoritative raw data source
- Cross-checked against: QLD Government Mercury DGV project consolidation files
- The SQL file is intentionally ignored by Git due to size

## Notes

The SQL dump is loaded into a local SQLite database during data preparation
scripts in this folder. Extracted and processed datasets are stored as R data
objects elsewhere in the package.