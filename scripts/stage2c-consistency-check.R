# Stage 2c: consistency audit of the 587-row Stage 2b CAS parent lookup.
# Reporting only -- this script does not modify any lookup table.
#
# Inputs:
#   scripts/stage2b-full-results-combined.csv   (587-row Stage 2b output)
#   data-raw/anztox/cas_parent_lookup.csv       (original pre-Stage-2 lookup)
# Output:
#   scripts/stage2c-consistency-report.md is written by hand alongside this
#   script; this script prints/returns the same underlying tables so the
#   report can be regenerated/verified independently.

combined <- read.csv(
  "scripts/stage2b-full-results-combined.csv",
  stringsAsFactors = FALSE, colClasses = "character"
)
orig <- read.csv(
  "data-raw/anztox/cas_parent_lookup.csv",
  stringsAsFactors = FALSE, colClasses = "character"
)

stopifnot(nrow(combined) == 587)

is_na_or_blank <- function(x) is.na(x) | x == ""

# Canonical 4-way category, derived from proposed_match_rationale text.
# "direct" must anchor at the start of the string -- several "direct" rows
# use the word "mixture" descriptively (e.g. "alkyl chain mixture from
# coconut oil"), so a bare grepl("mixture") would wrongly double-count them
# against the literal "MIXTURE OR PSEUDO-CAS" category label.
is_direct    <- grepl("^direct", combined$proposed_match_rationale, ignore.case = TRUE)
is_mixture   <- grepl("MIXTURE OR PSEUDO-CAS", combined$proposed_match_rationale, ignore.case = TRUE)
is_uncertain <- grepl("UNCERTAIN", combined$proposed_match_rationale, ignore.case = TRUE)
is_transform <- !is_direct & !is_mixture & !is_uncertain
stopifnot(sum(is_direct, is_mixture, is_uncertain, is_transform) == nrow(combined))

category <- ifelse(is_direct, "direct - no simpler parent",
  ifelse(is_mixture, "MIXTURE OR PSEUDO-CAS - cannot resolve",
    ifelse(is_uncertain, "UNCERTAIN - needs human review",
      "transform -> simpler parent (salt/ester/oxide/etc.)"
    )
  )
)
combined$category <- category

## ---- Check 1: duplicate CAS with conflicting parents ----------------------

check1_dup_cas <- combined[duplicated(combined$casnumber) | duplicated(combined$casnumber, fromLast = TRUE), ]
check1_dup_cas <- check1_dup_cas[order(check1_dup_cas$casnumber), ]

## ---- Check 2: chemical-class consistency -----------------------------------

# 2a: alkali-metal halide salts
pat_2a <- "(?i)\\b(sodium|potassium|lithium|cesium|caesium|rubidium)\\s+(chloride|bromide|fluoride|iodide)\\b"
check2a <- combined[grepl(pat_2a, combined$chemicalname, perl = TRUE),
  c("casnumber", "chemicalname", "proposed_parent_name", "proposed_match_rationale", "confidence")]

# 2b: alkaline earth metal salts
pat_2b <- "(?i)\\b(calcium|magnesium|barium|strontium)\\b"
check2b <- combined[grepl(pat_2b, combined$chemicalname, perl = TRUE),
  c("casnumber", "chemicalname", "proposed_parent_name", "proposed_match_rationale", "confidence")]

# 2c: arsenic compounds
pat_2c <- "(?i)arsen"
check2c <- combined[grepl(pat_2c, combined$chemicalname, perl = TRUE),
  c("casnumber", "chemicalname", "proposed_parent_casnumber", "proposed_parent_name", "confidence")]
check2c$matches_speciation_convention <- check2c$proposed_parent_casnumber == "7440382"

# 2d: nutrient oxyanions -- bare-ion entries (chemicalname IS the ion, not a
# salt of it) that should read "direct", plus a broader scan for anything
# that resolved PAST the ion to the bare element (e.g. "-> Nitrogen" /
# "-> Phosphorus"), which would break convention.
check2d_bare_ions <- combined[combined$proposed_parent_name %in% c("Nitrate", "Nitrite", "Phosphate", "Sulfate") &
  is_direct,
  c("casnumber", "chemicalname", "proposed_parent_name", "proposed_match_rationale")]
pat_2d_broad <- "(?i)phosphate|sulfate|sulphate|nitrate|nitrite"
check2d_broad <- combined[grepl(pat_2d_broad, combined$chemicalname, perl = TRUE),
  c("casnumber", "chemicalname", "proposed_parent_name", "proposed_match_rationale")]
check2d_overshoot <- check2d_broad[check2d_broad$proposed_parent_name %in% c("Nitrogen", "Phosphorus", "Sulfur") &
  !is.na(check2d_broad$proposed_parent_name), ]

# 2e: organophosphate insecticides (active ingredients, not inorganic salts)
pat_2e <- "(?i)phosphorothioate|phosphorodithioate|phosphonothioate"
check2e_suffix <- combined[grepl(pat_2e, combined$chemicalname, perl = TRUE),
  c("casnumber", "chemicalname", "proposed_parent_name", "proposed_match_rationale")]
# Broader net: any phosphate-ester-looking pesticide active ingredient that
# was incorrectly collapsed to Phosphate/Phosphorus instead of staying direct.
check2e_broad <- combined[grepl("(?i)phosphate", combined$chemicalname, perl = TRUE) &
  combined$proposed_parent_name %in% c("Phosphate", "Phosphorus") &
  grepl("(?i)dimethyl |diethyl |insecticide|pesticide", combined$chemicalname, perl = TRUE),
  c("casnumber", "chemicalname", "proposed_parent_name", "proposed_match_rationale")]

# 2f: HCl / HBr salts of organic bases
pat_2f <- "(?i)hydrochloride|hydrobromide"
check2f <- combined[grepl(pat_2f, combined$chemicalname, perl = TRUE),
  c("casnumber", "chemicalname", "proposed_parent_name", "proposed_match_rationale", "confidence")]
check2f_direct <- check2f[grepl("^direct", check2f$proposed_match_rationale, ignore.case = TRUE), ]

# 2g: esters
pat_2g <- "(?i)\\bester\\b|ethyl ester|methyl ester|butyl ester|pentyl ester|propyl ester|isooctyl ester"
check2g <- combined[grepl(pat_2g, combined$chemicalname, perl = TRUE),
  c("casnumber", "chemicalname", "proposed_parent_name", "proposed_match_rationale", "confidence")]
# Esters of the documented registered-pesticide-acid set should resolve to
# the acid; all other esters (industrial phosphate/sulfate esters) should
# stay direct, and "mixt. with" combinations are unresolvable regardless of
# acid identity. Flag anything that breaks that split. The negative
# lookahead after "2,4-D" prevents "2,4-D" from matching inside the IUPAC
# fragment "2,4-Dichlorophenoxy", which is not a use of the herbicide code.
pesticide_acids <- c("2,4-D", "2,4,5-T", "MCPA", "Fenac", "NAA", "Paraquat dichloride")
check2g$is_pesticide_acid_name <- grepl("(?i)2,4-D(?![a-z])|2,4,5-T(?![a-z])|MCPA|Fenac|naphthaleneacetic", check2g$chemicalname, perl = TRUE) &
  !is_mixture[match(check2g$casnumber, combined$casnumber)]
check2g$resolved_to_pesticide_acid <- check2g$proposed_parent_name %in% pesticide_acids
check2g_inconsistent <- check2g[check2g$is_pesticide_acid_name != check2g$resolved_to_pesticide_acid, ]

## ---- Check 3: confidence distribution by category --------------------------

check3_crosstab <- table(combined$category, combined$confidence)

check3_direct_low <- combined[is_direct & combined$confidence == "low", ]
check3_transform_high_no_cas <- combined[is_transform & combined$confidence == "high" &
  is_na_or_blank(combined$proposed_parent_casnumber), ]

## ---- Check 4: missing parent CAS for resolved (transform) rows -------------

check4_missing_parent_cas <- combined[is_transform & is_na_or_blank(combined$proposed_parent_casnumber),
  c("casnumber", "chemicalname", "proposed_parent_name", "proposed_match_rationale", "confidence")]

## ---- Check 5: parent CAS format validation ----------------------------------

has_dashed <- !is_na_or_blank(combined$proposed_parent_cas_dashed)
cas_dash_pattern <- "^[0-9]{2,7}-[0-9]{2}-[0-9]$"
check5a_bad_format <- combined[has_dashed & !grepl(cas_dash_pattern, combined$proposed_parent_cas_dashed),
  c("casnumber", "chemicalname", "proposed_parent_cas_dashed", "proposed_parent_casnumber", "proposed_parent_name")]

both_present <- has_dashed & !is_na_or_blank(combined$proposed_parent_casnumber)
stripped <- gsub("-", "", combined$proposed_parent_cas_dashed)
check5b_mismatch <- combined[both_present & stripped != combined$proposed_parent_casnumber,
  c("casnumber", "chemicalname", "proposed_parent_cas_dashed", "proposed_parent_casnumber", "proposed_parent_name")]

## ---- Check 6: cross-reference against the original 41-row lookup -----------

m <- match(orig$casnumber, combined$casnumber)
check6_overlap <- data.frame(
  casnumber = orig$casnumber,
  chemicalname = orig$chemicalname,
  in_combined_587 = !is.na(m)
)
check6_divergence <- combined[m[!is.na(m)],
  c("casnumber", "chemicalname", "proposed_parent_casnumber", "proposed_parent_name")]

## ---- Console summary (re-run this script to reproduce report figures) -----

cat("Check 1 -- duplicate CAS rows:", nrow(check1_dup_cas), "\n")
cat("Check 2a -- alkali halide rows:", nrow(check2a), "\n")
cat("Check 2b -- alkaline earth rows:", nrow(check2b), "\n")
cat("Check 2c -- arsenic rows:", nrow(check2c), "/ matching convention:", sum(check2c$matches_speciation_convention), "\n")
cat("Check 2d -- bare nutrient-ion rows:", nrow(check2d_bare_ions), "/ overshoot to element:", nrow(check2d_overshoot), "\n")
cat("Check 2e -- OP-suffix rows:", nrow(check2e_suffix), "/ incorrectly collapsed:", nrow(check2e_broad), "\n")
cat("Check 2f -- HCl/HBr rows:", nrow(check2f), "/ marked direct:", nrow(check2f_direct), "\n")
cat("Check 2g -- ester rows:", nrow(check2g), "/ inconsistent acid-vs-direct split:", nrow(check2g_inconsistent), "\n")
print(check3_crosstab)
cat("Check 3 -- direct+low:", nrow(check3_direct_low), " transform+high+no-CAS:", nrow(check3_transform_high_no_cas), "\n")
cat("Check 4 -- transform rows missing parent CAS:", nrow(check4_missing_parent_cas), "\n")
cat("Check 5a -- bad dashed-CAS format:", nrow(check5a_bad_format), "\n")
cat("Check 5b -- dashed/nodash mismatch:", nrow(check5b_mismatch), "\n")
cat("Check 6 -- original rows found in 587-row file:", sum(check6_overlap$in_combined_587), "of", nrow(check6_overlap), "\n")
