# Stage 2b: LLM-assisted CAS parent lookup pilot.
#
# Pilot test of using the Anthropic API (claude-sonnet-4-6) to propose
# parent-compound mappings for a 30-row sample of the cas_parent_lookup_all.csv
# rows flagged match_rationale == "NEEDS HUMAN REVIEW". Saves proposals to
# scripts/stage2b-pilot-results.csv for human review. Does not modify
# data-raw/cas_parent_lookup_all.csv.
#
# Requires ANTHROPIC_API_KEY (see ~/.Renviron). Run with:
#   Rscript scripts/stage2b-cas-llm-pilot.R

library(readr)
library(dplyr)
library(tibble)
library(httr2)
library(jsonlite)

if (Sys.getenv("ANTHROPIC_API_KEY") == "") {
  stop(
    "ANTHROPIC_API_KEY is not set. Add it to ~/.Renviron as ",
    "ANTHROPIC_API_KEY=<key> and restart R."
  )
}

# --- 1. Test batch -----------------------------------------------------------
# 30 rows hand-selected from the 587 rows in data-raw/cas_parent_lookup_all.csv
# where match_rationale == "NEEDS HUMAN REVIEW" (see prompts/stage2b-cas-llm-pilot.md
# and scripts/stage2b-pilot-report.md for the full selection rationale). Groups:
#   - salts_oxides (10): simple metal chloride/oxide/sulfate salts where the
#     element is the expected parent -- mostly lanthanides and metals not
#     covered by the original 41-row cas_parent_lookup.csv, to test whether the
#     model generalises the "salt/oxide -> element" convention to new metals.
#   - organics_pesticides (10): organophosphate insecticides (expected to have
#     no simpler parent), two esters of the same acid (2,4-D), and two
#     hydrochloride salts of an organic base -- relationship types not present
#     in the original 41-row examples.
#   - mixtures (5): rows containing "mixt." / "compd. with ... mixt. with ..."
#     -- should resolve to MIXTURE OR PSEUDO-CAS, not a single parent.
#   - already_parent (5): simple inorganic ions/oxyanions that are plausibly
#     already the parent form (tests whether the model over-resolves, e.g.
#     Arsenite -> Arsenic by analogy with the existing Sodium arsenite entry).
test_batch <- tribble(
  ~casnumber,  ~chemicalname,                                                                                                                                  ~group,
  "10024938",  "Neodymium(III) chloride;Neodymium trichloride",                                                                                                "salts_oxides",
  "10025748",  "Dysprosium(III) chloride;Dysprosium trichloride",                                                                                               "salts_oxides",
  "10099588",  "Lanthanum chloride;Lanthanum trichloride",                                                                                                      "salts_oxides",
  "12055628",  "Holmium oxide (Ho2O3)",                                                                                                                         "salts_oxides",
  "12060581",  "Samarium oxide (Sm2O3)",                                                                                                                        "salts_oxides",
  "1305788",   "Calcium oxide;(Oxido)calcium",                                                                                                                  "salts_oxides",
  "1306383",   "Ceric oxide;Bis(oxido)cerium",                                                                                                                  "salts_oxides",
  "13510491",  "Beryllium sulfate;Beryllium sulfate",                                                                                                           "salts_oxides",
  "14644612",  "Zirconium(IV) sulfate;Zirconium(4+) disulfate",                                                                                                 "salts_oxides",
  "7720787",   "Iron(II) sulfate;Iron(2+) sulfate",                                                                                                             "salts_oxides",
  "13171216",  "Phosphamidon;3-Chloro-4-(diethylamino)-4-oxobut-2-en-2-yl dimethyl phosphate",                                                                  "organics_pesticides",
  "6923224",   "Monocrotophos;Dimethyl (2E)-4-(methylamino)-4-oxobut-2-en-2-yl phosphate",                                                                      "organics_pesticides",
  "62737",     "Dichlorvos;2,2-Dichloroethenyl dimethyl phosphate",                                                                                             "organics_pesticides",
  "300765",    "Naled;1,2-Dibromo-2,2-dichloroethyl dimethyl phosphate",                                                                                        "organics_pesticides",
  "470906",    "Chlorfenvinphos;2-Chloro-1-(2,4-dichlorophenyl)ethenyl diethyl phosphate",                                                                      "organics_pesticides",
  "1928434",   "2,4-D 2-EHE;2-Ethylhexyl (2,4-dichlorophenoxy)acetate",                                                                                         "organics_pesticides",
  "94804",     "2,4-D 1-butyl ester;Butyl (2,4-dichlorophenoxy)acetate",                                                                                        "organics_pesticides",
  "19750959",  "Chlordimeform hydrochloride;N'-(4-Chloro-2-methylphenyl)-N,N-dimethylmethanimidamide--hydrogen chloride (1/1)",                                "organics_pesticides",
  "56296787",  "Fluoxetine hydrochloride;N-Methyl-3-phenyl-3-[4-(trifluoromethyl)phenoxy]propan-1-amine--hydrogen chloride (1/1)",                              "organics_pesticides",
  "141517217", "Trifloxystrobin;Methyl (methoxyimino)(2-{[({1-[3-(trifluoromethyl)phenyl]ethylidene}amino)oxy]methyl}phenyl)acetate",                           "organics_pesticides",
  "145607530", "Metalaxyl-cuprous oxide mixt.",                                                                                                                 "mixtures",
  "96300957",  "Triphenyl phosphate-isodecyl diphenyl phosphate mixt.",                                                                                        "mixtures",
  "37287164",  "Aluminum oxide (Al2O3) mixt. with silica",                                                                                                      "mixtures",
  "76930580",  "Sulfuric acid diammonium salt mixt. with diammonium hydrogen phosphate",                                                                       "mixtures",
  "8067558",   "4-Amino-3,5,6-trichloro-2-pyridinecarboxylic acid compd. with 1,1',1''-nitrilotris[2-propanol] (1:1) mixt. with 1,1',1''-nitrilotris[2-propanol] (2,4-dichlorophenoxy)acetate (1:1)", "mixtures",
  "14265442",  "Phosphate;Phosphate",                                                                                                                           "already_parent",
  "14808798",  "Sulfate;Sulfate",                                                                                                                               "already_parent",
  "16887006",  "Chloride",                                                                                                                                      "already_parent",
  "14797650",  "Nitrite",                                                                                                                                       "already_parent",
  "15502746",  "Arsenite (AsO3)",                                                                                                                               "already_parent"
)

stopifnot(nrow(test_batch) == 30)

# Sanity check against the current source file, in case it has changed since
# this batch was selected.
lookup <- read_csv("data-raw/cas_parent_lookup_all.csv", show_col_types = FALSE)
review_rows <- lookup |> filter(match_rationale == "NEEDS HUMAN REVIEW")
missing <- setdiff(test_batch$casnumber, review_rows$casnumber)
if (length(missing) > 0) {
  warning(
    "These selected CAS numbers are no longer NEEDS HUMAN REVIEW in the ",
    "current lookup file: ", paste(missing, collapse = ", ")
  )
}

# --- 2. Prompts ----------------------------------------------------------------
system_prompt <- "You are an expert chemist specialising in ecotoxicology and environmental
chemistry. Your task is to identify the parent compound for each chemical
in a list, following the conventions of regulatory ecotoxicology databases.

Rules:
- If the chemical is a salt or oxide of a simpler parent element or compound,
  identify the parent (e.g. Cadmium chloride -> Cadmium, CAS 7440-43-9).
- If the chemical IS already the parent form (a pure element, a registered
  active ingredient, a simple inorganic ion), set parent fields equal to the
  input CAS and name, and set relationship to 'direct - no simpler parent'.
- If the chemical is a mixture, formulation, or pseudo-CAS substance that
  cannot be resolved to a single parent, set parent fields to null and set
  relationship to 'MIXTURE OR PSEUDO-CAS - cannot resolve'.
- If you are uncertain, set relationship to 'UNCERTAIN - needs human review'
  and provide your best guess for parent fields with a note.
- Always provide a CAS number for the parent where you are confident.
- Respond only with a JSON array. No preamble, no markdown, no explanation
  outside the JSON."

chemicals_json <- test_batch |>
  select(casnumber, chemicalname) |>
  toJSON(auto_unbox = TRUE)

user_prompt <- paste0(
  "Here are the chemicals to process, provided as a JSON array with fields ",
  "casnumber and chemicalname:\n\n",
  chemicals_json,
  "\n\nFor each chemical in the array, return an object with this exact JSON structure:\n",
  '{\n',
  '  "casnumber": "<input>",\n',
  '  "chemicalname": "<input>",\n',
  '  "proposed_parent_cas_dashed": "<dashed CAS or null>",\n',
  '  "proposed_parent_casnumber": "<nodash CAS or null>",\n',
  '  "proposed_parent_name": "<name or null>",\n',
  '  "proposed_match_rationale": "<rationale string>",\n',
  '  "confidence": "high | medium | low"\n',
  '}\n\nReturn a JSON array of 30 such objects, one per chemical, in the same order as the input.'
)

# --- 3. Call the API and time it ----------------------------------------------
t0 <- Sys.time()

resp <- request("https://api.anthropic.com/v1/messages") |>
  req_headers(
    "x-api-key" = Sys.getenv("ANTHROPIC_API_KEY"),
    "anthropic-version" = "2023-06-01",
    "content-type" = "application/json"
  ) |>
  req_body_json(list(
    model = "claude-sonnet-4-6",
    max_tokens = 4096,
    system = system_prompt,
    messages = list(list(role = "user", content = user_prompt))
  )) |>
  req_perform()

elapsed_sec <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
cat(sprintf("API call took %.1f seconds\n", elapsed_sec))

raw_text <- resp_body_json(resp)$content[[1]]$text

# --- 4. Parse the response ----------------------------------------------------
# Try the whole array first; if that fails (truncated output, stray preamble),
# fall back to extracting individual {...} objects so a partial response still
# yields partial results instead of an all-or-nothing failure.
parsed <- tryCatch(
  fromJSON(raw_text, simplifyDataFrame = TRUE),
  error = function(e) NULL
)

if (is.null(parsed)) {
  obj_matches <- regmatches(raw_text, gregexpr("\\{[^{}]*\\}", raw_text))[[1]]
  rows <- lapply(obj_matches, function(x) tryCatch(fromJSON(x), error = function(e) NULL))
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (length(rows) > 0) {
    parsed <- bind_rows(rows)
  }
}

required_cols <- c(
  "casnumber", "chemicalname", "proposed_parent_cas_dashed",
  "proposed_parent_casnumber", "proposed_parent_name",
  "proposed_match_rationale", "confidence"
)

if (is.null(parsed) || !all(required_cols %in% names(parsed))) {
  # Total parse failure: record every input row against the raw response, flagged.
  results <- test_batch |>
    select(casnumber, chemicalname) |>
    mutate(
      proposed_parent_cas_dashed = NA_character_,
      proposed_parent_casnumber = NA_character_,
      proposed_parent_name = NA_character_,
      proposed_match_rationale = raw_text,
      confidence = NA_character_,
      parse_error = TRUE
    )
} else {
  results <- parsed |>
    select(all_of(required_cols)) |>
    mutate(parse_error = FALSE)

  missing_cas <- setdiff(test_batch$casnumber, results$casnumber)
  if (length(missing_cas) > 0) {
    extra <- test_batch |>
      filter(casnumber %in% missing_cas) |>
      select(casnumber, chemicalname) |>
      mutate(
        proposed_parent_cas_dashed = NA_character_,
        proposed_parent_casnumber = NA_character_,
        proposed_parent_name = NA_character_,
        proposed_match_rationale = "Row missing from API response",
        confidence = NA_character_,
        parse_error = TRUE
      )
    results <- bind_rows(results, extra)
  }
}

write_csv(results, "scripts/stage2b-pilot-results.csv")

cat(sprintf(
  "Parsed %d / %d rows successfully (%.0f%% parse success). Elapsed: %.1fs\n",
  sum(!results$parse_error), nrow(test_batch),
  100 * sum(!results$parse_error) / nrow(test_batch),
  elapsed_sec
))
