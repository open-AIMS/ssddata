# data-raw/envirotox/DATASET.R
#
# Builds envirotox_acute, envirotox_chronic, envirotox_chemical, and
# envirotox_data from the raw EnviroTox database 2.0.0 spreadsheet.
#
# Modified from:
#   https://github.com/miinay/SSD_distribution_comparison/blob/main/Rcode.R
# and ported from:
#   https://github.com/poissonconsulting/envirotox/blob/main/data-raw/envirotox.R
#
# The source file envirotox.xlsx must be placed in data-raw/envirotox/ before
# running this script. It is not committed to the repository.
#
# Usage (from package root):
#   source("data-raw/envirotox/DATASET.R")

library(openxlsx)
library(dplyr)
library(tidyr)
library(EnvStats)
library(mousetrap)
library(stringr)

# ---------------------------------------------------------------------------
# 1. Read raw data
# ---------------------------------------------------------------------------

path <- file.path("data-raw", "envirotox", "envirotox.xlsx")

if (!file.exists(path)) {
  stop(
    "Source file not found: ",
    path,
    "\n",
    "Place envirotox.xlsx in data-raw/envirotox/ before running this script."
  )
}

EnviroTox_test <- read.xlsx(path, sheet = "test")
EnviroTox_chem <- read.xlsx(path, sheet = "substance")
EnviroTox_taxo <- read.xlsx(path, sheet = "taxonomy")

# ---------------------------------------------------------------------------
# 2. Select and process toxicity data
# ---------------------------------------------------------------------------

EnviroTox_test_selected <- EnviroTox_test %>%
  filter(
    (Test.statistic == "EC50" & Test.type == "A") |
      (Test.statistic == "LC50" & Test.type == "A") |
      (Test.statistic == "NOEC" & Test.type == "C") |
      (Test.statistic == "NOEL" & Test.type == "C")
  ) %>%
  filter(Effect.is.5X.above.water.solubility == "0") %>%
  mutate(
    original.CAS = EnviroTox_chem[
      match(.$CAS, EnviroTox_chem$CAS),
      "original.CAS"
    ]
  ) %>%
  mutate_at(vars(Effect.value), as.numeric) %>%
  # Convert mg/L to ug/L
  mutate(
    Effect.value = replace(
      .$Effect.value,
      !is.na(.$Effect.value),
      .$Effect.value * 10^3
    )
  ) %>%
  mutate(Unit = replace(Unit, Unit == "mg/L", "ug/L")) %>%
  mutate(
    Substance = EnviroTox_chem[
      match(.$original.CAS, EnviroTox_chem$original.CAS),
      "Chemical.name"
    ]
  ) %>%
  separate(Substance, into = c("Short_name"), sep = ";", extra = "drop")

# ---------------------------------------------------------------------------
# 3. Geometric mean per original.CAS x Test.type x Latin.name
# ---------------------------------------------------------------------------

EnviroTox_test_selected2 <- aggregate(
  EnviroTox_test_selected$Effect.value,
  by = list(
    original.CAS = EnviroTox_test_selected$original.CAS,
    Test.type = EnviroTox_test_selected$Test.type,
    Latin.name = EnviroTox_test_selected$Latin.name
  ),
  function(x) geoMean(x)
) %>%
  dplyr::rename(Effect.value = x) %>%
  mutate(
    Trophic.Level = EnviroTox_taxo[
      match(.$Latin.name, EnviroTox_taxo$Latin.name),
      "Trophic.Level"
    ]
  ) %>%
  mutate(
    Substance = EnviroTox_chem[
      match(.$original.CAS, EnviroTox_chem$original.CAS),
      "Chemical.name"
    ]
  ) %>%
  separate(Substance, into = c("Short_name"), sep = ";", extra = "drop") %>%
  group_by(original.CAS, Test.type) %>%
  filter(n() >= 6) %>%
  filter(var(Effect.value) > 0)

# ---------------------------------------------------------------------------
# 4. Summary statistics per chemical x test type (for flags)
# ---------------------------------------------------------------------------

EnviroTox_ssd <- aggregate(
  x = as.numeric(EnviroTox_test_selected2$Effect.value),
  by = list(
    original.CAS = EnviroTox_test_selected2$original.CAS,
    Test.type = EnviroTox_test_selected2$Test.type
  ),
  FUN = function(x) mean(log10(x))
) %>%
  mutate(
    sd = aggregate(
      EnviroTox_test_selected2$Effect.value,
      by = list(
        EnviroTox_test_selected2$original.CAS,
        EnviroTox_test_selected2$Test.type
      ),
      function(x) sd(log10(x))
    )[, 3]
  ) %>%
  dplyr::rename(mean = x) %>%
  mutate(HC5 = qlnorm(0.05, meanlog = log(10^mean), sdlog = log(10^sd))) %>%
  mutate(
    Substance = EnviroTox_chem[
      match(.$original.CAS, EnviroTox_chem$original.CAS),
      "Chemical.name"
    ]
  ) %>%
  mutate(
    No_species = aggregate(
      EnviroTox_test_selected2$Latin.name,
      by = list(
        EnviroTox_test_selected2$original.CAS,
        EnviroTox_test_selected2$Test.type
      ),
      function(x) length(unique(x))
    )[, 3]
  ) %>%
  mutate(
    No_trophic = aggregate(
      EnviroTox_test_selected2$Trophic.Level,
      by = list(
        EnviroTox_test_selected2$original.CAS,
        EnviroTox_test_selected2$Test.type
      ),
      function(x) length(unique(x))
    )[, 3]
  ) %>%
  filter(!is.na(sd)) %>%
  mutate(Test.type = replace(Test.type, Test.type == "A", "Acute")) %>%
  mutate(Test.type = replace(Test.type, Test.type == "C", "Chronic")) %>%
  pivot_wider(
    names_from = Test.type,
    values_from = c("mean", "sd", "HC5", "No_species", "No_trophic")
  ) %>%
  mutate(
    ConsensusMoA = EnviroTox_chem[
      match(.$original.CAS, EnviroTox_chem$original.CAS),
      "Consensus.MOA"
    ]
  ) %>%
  mutate(
    ASTER = EnviroTox_chem[
      match(.$original.CAS, EnviroTox_chem$original.CAS),
      "ASTER"
    ]
  )

# ---------------------------------------------------------------------------
# 5. Bimodality coefficients
# ---------------------------------------------------------------------------

BC_A <- EnviroTox_test_selected2 %>%
  filter(Test.type == "A") %>%
  group_by(original.CAS) %>%
  dplyr::summarize(
    BC = mousetrap::bimodality_coefficient(log10(Effect.value))
  ) %>%
  select(original.CAS, BC)

BC_C <- EnviroTox_test_selected2 %>%
  filter(Test.type == "C") %>%
  group_by(original.CAS) %>%
  dplyr::summarize(
    BC = mousetrap::bimodality_coefficient(log10(Effect.value))
  ) %>%
  select(original.CAS, BC)

# ---------------------------------------------------------------------------
# 6. Select qualifying chemicals and build flags
# ---------------------------------------------------------------------------

EnviroTox_ssd_HH_A <- EnviroTox_ssd %>%
  filter(No_trophic_Acute >= 2) %>%
  filter(No_species_Acute >= 6) %>%
  left_join(BC_A, by = "original.CAS") %>%
  separate(Substance, into = c("Short_name"), sep = ";", extra = "drop") %>%
  mutate(
    Yanagihara24 = No_species_Acute >= 10 & No_trophic_Acute >= 3 & BC <= 0.555,
    Iwasaki25 = No_species_Acute > 50 & No_trophic_Acute >= 3
  ) %>%
  select(original.CAS, Yanagihara24, Iwasaki25)

EnviroTox_ssd_HH_C <- EnviroTox_ssd %>%
  filter(No_trophic_Chronic >= 2) %>%
  filter(No_species_Chronic >= 6) %>%
  left_join(BC_C, by = "original.CAS") %>%
  separate(Substance, into = c("Short_name"), sep = ";", extra = "drop") %>%
  mutate(
    Yanagihara24 = No_species_Chronic >= 10 &
      No_trophic_Chronic >= 3 &
      BC <= 0.555
  ) %>%
  select(original.CAS, Yanagihara24)

# ---------------------------------------------------------------------------
# 7. Build envirotox_acute
# ---------------------------------------------------------------------------

envirotox_acute <- EnviroTox_test_selected2 %>%
  filter(Test.type == "A") %>%
  inner_join(EnviroTox_ssd_HH_A, by = "original.CAS") %>%
  mutate(
    Iwasaki25 = Iwasaki25 &
      !(Short_name %in%
        c(
          "Arsenic(III) sulfide",
          "Cadmium chloride",
          "Chromium trioxide",
          "Copper",
          "Cupric oxide",
          "Lead nitrate",
          "Mercuric nitrate",
          "Nickel chloride",
          "Silver sulfate",
          "Sodium selenite",
          "Zinc oxide"
        ))
  )

envirotox_acute <- envirotox_acute %>%
  ungroup() %>%
  select(
    Chemical = Short_name,
    Conc = Effect.value,
    Species = Latin.name,
    Group = Trophic.Level,
    OriginalCAS = original.CAS,
    Yanagihara24,
    Iwasaki25
  ) %>%
  as_tibble() %>%
  # Remove duplicates caused by duplicate chemical names with different CAS numbers
  filter(
    !(Chemical == "Acriflavine" & OriginalCAS == 65589700 & !Yanagihara24)
  ) %>%
  filter(
    !(Chemical == "Imidacloprid" & OriginalCAS == 105827789 & !Yanagihara24)
  )

# ---------------------------------------------------------------------------
# 8. Build envirotox_chronic
# ---------------------------------------------------------------------------

envirotox_chronic <- EnviroTox_test_selected2 %>%
  filter(Test.type == "C") %>%
  inner_join(EnviroTox_ssd_HH_C, by = "original.CAS")

envirotox_chronic <- envirotox_chronic %>%
  ungroup() %>%
  select(
    Chemical = Short_name,
    Conc = Effect.value,
    Species = Latin.name,
    Group = Trophic.Level,
    OriginalCAS = original.CAS,
    Yanagihara24
  ) %>%
  as_tibble()

# ---------------------------------------------------------------------------
# 9. Build envirotox_chemical lookup
# ---------------------------------------------------------------------------

envirotox_chemical <- envirotox_acute %>%
  bind_rows(envirotox_chronic) %>%
  distinct(Chemical, OriginalCAS) %>%
  mutate(OriginalCAS = as.integer(OriginalCAS)) %>%
  arrange(Chemical)

# ---------------------------------------------------------------------------
# 10. Normalise group labels and drop OriginalCAS from acute/chronic
# ---------------------------------------------------------------------------

normalise_group <- function(x) {
  x <- stringr::str_to_sentence(x)
  dplyr::case_when(
    x == "Invert" ~ "Invertebrate",
    x == "Amphib" ~ "Amphibian",
    TRUE ~ x
  )
}

envirotox_acute <- envirotox_acute %>%
  select(!OriginalCAS) %>%
  mutate(
    Group = normalise_group(Group),
    Medium = "Unknown"
  ) %>%
  arrange(Chemical, Species)

envirotox_chronic <- envirotox_chronic %>%
  select(!OriginalCAS) %>%
  mutate(
    Group = normalise_group(Group),
    Medium = "Unknown"
  ) %>%
  arrange(Chemical, Species)

# ---------------------------------------------------------------------------
# 11. Integrity checks
# ---------------------------------------------------------------------------

chk::check_key(envirotox_acute, c("Chemical", "Species"))
chk::check_key(envirotox_chronic, c("Chemical", "Species"))
chk::check_key(envirotox_chemical, "Chemical")
chk::check_key(envirotox_chemical, "OriginalCAS")

# ---------------------------------------------------------------------------
# 12. Build envirotox_data list and save all four objects
# ---------------------------------------------------------------------------

envirotox_data <- list(
  acute = envirotox_acute,
  chronic = envirotox_chronic,
  chemical = envirotox_chemical
)

usethis::use_data(envirotox_acute, overwrite = TRUE)
usethis::use_data(envirotox_chronic, overwrite = TRUE)
usethis::use_data(envirotox_chemical, overwrite = TRUE)
usethis::use_data(envirotox_data, overwrite = TRUE)
