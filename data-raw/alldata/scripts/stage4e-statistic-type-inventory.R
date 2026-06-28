# Stage 4e — Statistic type inventory (read-only diagnostic)
#
# Inventories statistic_type values in the Stage 4e entering subset and
# classifies them by Warne et al. 2025 tier. Flags chronic/subchronic/NA
# records in the median-effect and low-effect tiers that currently flow
# through Stage 4e without any conversion factor applied.
#
# Input:  data-raw/alldata/uncurated_raw_dedup_enriched.csv  (~228 MB, untracked)
# Output: data-raw/alldata/stage4e-statistic-type-inventory.md  (tracked)
#
# Run from repo root (WSL or Windows Positron). No pipeline files are modified.
# Read with guess_max = Inf per project-wide convention (CLAUDE.md Section 5).

library(readr)
library(dplyr)

# ---------------------------------------------------------------------------
# Tier classification (vectorised)
# ---------------------------------------------------------------------------

# Maps each statistic_type value to a Warne et al. 2025 tier.
# Tier names:
#   preferred_negligible     — NEC, NSEC, BEC10 (no conversion needed)
#   negligible_no_conversion — NOEC, NOEL (no conversion needed)
#   low_effect_conv_2.5      — LOEC, LOEL (divide by 2.5 to reach NOEC equiv.)
#   low_effect_conv_2        — MATC (divide by 2)
#   appropriate_no_conversion — ECx/ICx/LCx where x <= 10
#   less_pref_no_conversion   — ECx/ICx/LCx where 10 < x <= 20
#   median_effect_conv_5      — ECx/ICx/LCx where x == 50 (divide by 5)
#   undefined_x_needs_ruling  — ECx/ICx/LCx with any other x
#   UNCLASSIFIED (NA)         — missing statistic_type
#   UNCLASSIFIED              — anything not matched above
classify_tier <- function(st) {
  s <- trimws(toupper(as.character(st)))

  is_x_pat <- grepl("^(EC|IC|LC)(\\d+)$", s, perl = TRUE)
  x_val    <- suppressWarnings(
    as.integer(sub("^(?:EC|IC|LC)(\\d+)$", "\\1", s, perl = TRUE))
  )
  x_val[!is_x_pat] <- NA_integer_

  dplyr::case_when(
    is.na(st)                                               ~ "UNCLASSIFIED (NA)",
    s %in% c("NEC", "NSEC", "BEC10")                       ~ "preferred_negligible",
    s %in% c("NOEC", "NOEL")                               ~ "negligible_no_conversion",
    s %in% c("LOEC", "LOEL")                               ~ "low_effect_conv_2.5",
    s == "MATC"                                             ~ "low_effect_conv_2",
    is_x_pat & !is.na(x_val) & x_val <= 10                ~ "appropriate_no_conversion",
    is_x_pat & !is.na(x_val) & x_val > 10 & x_val <= 20   ~ "less_pref_no_conversion",
    is_x_pat & !is.na(x_val) & x_val == 50                ~ "median_effect_conv_5",
    is_x_pat & !is.na(x_val)                               ~ "undefined_x_needs_ruling",
    TRUE                                                    ~ "UNCLASSIFIED"
  )
}

# ---------------------------------------------------------------------------
# Markdown table helper
# ---------------------------------------------------------------------------

md_table <- function(df) {
  df_c <- as.data.frame(lapply(df, as.character), stringsAsFactors = FALSE)
  hdr  <- paste("|", paste(names(df_c), collapse = " | "), "|")
  sep  <- paste("|", paste(rep("---", ncol(df_c)), collapse = " | "), "|")
  body <- vapply(seq_len(nrow(df_c)), function(i) {
    paste("|", paste(df_c[i, ], collapse = " | "), "|")
  }, character(1))
  paste(c(hdr, sep, body), collapse = "\n")
}

# ---------------------------------------------------------------------------
# Load and filter to Stage 4e entering subset
# ---------------------------------------------------------------------------

message("Loading enriched file (this may take a minute) ...")
enriched <- read_csv(
  "data-raw/alldata/uncurated_raw_dedup_enriched.csv",
  guess_max      = Inf,
  show_col_types = FALSE
)
message("Loaded: ", nrow(enriched), " rows x ", ncol(enriched), " cols")

df <- enriched |>
  filter(dedup_retained == TRUE, priority_kept == TRUE) |>
  mutate(warne_tier = classify_tier(statistic_type))

n_entering <- nrow(df)
message("Entering Stage 4e (dedup_retained & priority_kept): ", n_entering)

rm(enriched)

# ---------------------------------------------------------------------------
# (a) Distinct raw statistic_type values — row counts and tier
# ---------------------------------------------------------------------------

table_a <- df |>
  mutate(st_disp = if_else(is.na(statistic_type), "<NA>", statistic_type)) |>
  count(st_disp, warne_tier, name = "n_rows") |>
  arrange(desc(n_rows)) |>
  rename(statistic_type = st_disp)

# ---------------------------------------------------------------------------
# (b) Cross-tabulation: statistic_type (rows) x test_class (cols)
# ---------------------------------------------------------------------------

# Build wide table without tidyr: manually pivot by summing indicator columns.
table_b <- df |>
  mutate(
    st_disp    = if_else(is.na(statistic_type), "<NA>", statistic_type),
    is_acute   = if_else(test_class == "acute",      1L, 0L, missing = 0L),
    is_chronic = if_else(test_class == "chronic",    1L, 0L, missing = 0L),
    is_sub     = if_else(test_class == "subchronic", 1L, 0L, missing = 0L),
    is_na_tc   = if_else(is.na(test_class),          1L, 0L)
  ) |>
  group_by(st_disp) |>
  summarise(
    acute      = sum(is_acute),
    chronic    = sum(is_chronic),
    subchronic = sum(is_sub),
    `<NA>`     = sum(is_na_tc),
    .groups    = "drop"
  ) |>
  arrange(desc(acute + chronic + subchronic + `<NA>`)) |>
  rename(statistic_type = st_disp)

# ---------------------------------------------------------------------------
# (c) UNCLASSIFIED values — explicit listing
# ---------------------------------------------------------------------------

unclassified <- table_a |>
  filter(grepl("^UNCLASSIFIED", warne_tier), statistic_type != "<NA>") |>
  arrange(desc(n_rows))

# ---------------------------------------------------------------------------
# (d) Conversion-needed tiers — chronic/subchronic/NA test_class, by source
# ---------------------------------------------------------------------------

CONV_TIERS <- c("median_effect_conv_5", "low_effect_conv_2.5", "low_effect_conv_2")

table_d <- df |>
  filter(
    warne_tier %in% CONV_TIERS,
    is.na(test_class) | test_class %in% c("chronic", "subchronic")
  ) |>
  mutate(
    st_disp = if_else(is.na(statistic_type), "<NA>", statistic_type),
    tc_disp = if_else(is.na(test_class),     "<NA>", test_class)
  ) |>
  count(source, warne_tier, st_disp, tc_disp, name = "n_rows") |>
  arrange(source, warne_tier, st_disp) |>
  rename(statistic_type = st_disp, test_class = tc_disp)

# ---------------------------------------------------------------------------
# (e) Summary
# ---------------------------------------------------------------------------

n_conv_needed <- df |>
  filter(
    warne_tier %in% CONV_TIERS,
    is.na(test_class) | test_class %in% c("chronic", "subchronic")
  ) |>
  nrow()

pct_conv_needed <- round(100 * n_conv_needed / n_entering, 2)

tier_breakdown_e <- df |>
  filter(
    warne_tier %in% CONV_TIERS,
    is.na(test_class) | test_class %in% c("chronic", "subchronic")
  ) |>
  count(warne_tier, name = "n_rows") |>
  arrange(desc(n_rows))

msg_e <- paste0(
  n_conv_needed, " rows (", pct_conv_needed, "% of the ", n_entering,
  "-row entering subset) are chronic/subchronic/NA-class median-or-low-effect ",
  "estimates currently flowing through Stage 4e without a conversion factor applied."
)
message(msg_e)

# ---------------------------------------------------------------------------
# Write report
# ---------------------------------------------------------------------------

out_path <- "data-raw/alldata/stage4e-statistic-type-inventory.md"

unclassified_block <- if (nrow(unclassified) == 0) {
  "No UNCLASSIFIED statistic_type values (excluding NA rows)."
} else {
  c(
    paste0(
      nrow(unclassified),
      " statistic_type value(s) not matched by the Warne 2025 tier rules ",
      "(NA statistic_type excluded from this list — shown in table (a)):"
    ),
    "",
    md_table(unclassified)
  )
}

table_d_block <- if (nrow(table_d) == 0) {
  "No rows in the conversion-needed tiers for these test_class values."
} else {
  md_table(table_d)
}

report <- c(
  "# Stage 4e — Statistic Type Inventory",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "Input file: `data-raw/alldata/uncurated_raw_dedup_enriched.csv`",
  "",
  "---",
  "",
  "## Entering subset",
  "",
  paste0(
    "Rows entering Stage 4e (`dedup_retained == TRUE & priority_kept == TRUE`): **",
    n_entering, "**"
  ),
  "",
  "---",
  "",
  "## (a) Raw `statistic_type` values — row counts and Warne 2025 tier",
  "",
  paste0(
    "All distinct raw values shown verbatim, sorted by row count descending. ",
    "`<NA>` = missing statistic_type."
  ),
  "",
  md_table(table_a),
  "",
  "---",
  "",
  "## (b) Cross-tabulation: `statistic_type` x `test_class`",
  "",
  "Column `<NA>` = missing test_class.",
  "",
  md_table(table_b),
  "",
  "---",
  "",
  "## (c) UNCLASSIFIED statistic_type values",
  "",
  unclassified_block,
  "",
  "---",
  "",
  "## (d) Conversion-needed tiers — chronic / subchronic / NA test_class, by source",
  "",
  paste0(
    "Tiers: `", paste(CONV_TIERS, collapse = "`, `"), "`  ",
    "(test_class restricted to chronic, subchronic, or NA)"
  ),
  "",
  table_d_block,
  "",
  "---",
  "",
  "## (e) Summary",
  "",
  paste0("**", msg_e, "**"),
  "",
  "Breakdown by tier:",
  "",
  md_table(tier_breakdown_e),
  ""
)

writeLines(report, out_path)
message("Report written to: ", out_path)
