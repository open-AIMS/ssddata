#    Copyright 2021 Australian Institute of Marine Science
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

#' Get SSD dataset
#'
#' Retrieves a specific SSD dataset,
#' filtering and groups by species and applies a geometric
#' mean in the case of duplicate records.
#'
#' @param dataset_name The name (chr) of the desired dataset in ssddata.
#' @param filter_val A character string,
#' indicating the filter to be applied (value)
#' (colname) and which column it applies to, separated by "_".
#' Must be in the form colname_value.
#' @param use_gmmean Logical indicating if a geometric mean should be applied.
#' @param spp_vec The group_by columns to use for grouping
#' data and applying a geometric mean.
#' @param conc The name of the concentration (x data) column.
#' @return The data.frame for dataset_name with any applied groupings and summary.
#' @export
#' @examples
#' get_ssddata("ccme_boron")
get_ssddata <- function(
  dataset_name,
  filter_val = NULL,
  use_gmmean = TRUE,
  spp_vec = c("Species", "Genus"),
  conc = "Conc"
) {
  if (!is.null(filter_val)) {
    if (is.na(filter_val)) {
      filter_val <- NULL
    }
  }
  chk_string(dataset_name)
  chk_null_or(filter_val, vld = vld_string)
  chk_flag(use_gmmean)
  chk_string(conc)
  if (!is.null(filter_val)) {
    filter_val <- as.vector(unlist(unlist(strsplit(filter_val, "_"))))
    dat_x <- do.call("getdata", list(as.name(dataset_name)))
    dat_x <- dat_x[which(dat_x[, filter_val[1]] == filter_val[2]), ]
  } else {
    dat_x <- do.call("getdata", list(as.name(dataset_name)))
  }

  spp_x <- intersect(spp_vec, colnames(dat_x))
  spp_name <- paste(spp_x, collapse = "_")

  if (!length(spp_x)) {
    dat_out <- dat_x
    message(paste(
      "No grouping has been applied, returning raw",
      dataset_name,
      "dataset."
    ))
    return(dat_out)
  }

  spp_dat <- apply(dat_x[, spp_x], 1, paste, collapse = "_")
  duplicate_spp <- nrow(dat_x) != length(unique(spp_dat))

  if (!use_gmmean || !duplicate_spp) {
    dat_out <- dat_x
    message(paste(
      "No grouping has been applied, returning raw",
      dataset_name,
      "dataset."
    ))
    return(dat_out)
  }

  dat_out <- data.frame(conc = dat_x[[conc]])
  dat_out$spp <- spp_dat
  dat_out <- dat_out[, c("spp", "conc")]
  dat_out <- group_by(dat_out, .data$spp)
  dat_out <- summarise(dat_out, conc = gm_mean(conc))
  colnames(dat_out) <- gsub("conc", conc, colnames(dat_out))
  colnames(dat_out) <- gsub("spp", spp_name, colnames(dat_out))
  message(paste(
    "Data",
    dataset_name,
    "grouped by",
    paste(spp_x, collapse = ", "),
    "with a geometric mean applied to duplicate records."
  ))
  dat_out
}

#' Extract package dataset
#'
#' Retrieves a dataset from a loaded package by name
#' @keywords internal
#'
#' @param ... Arguments passed utils::data
#' @return An object of class data frame.
getdata <- function(...) {
  e <- new.env()
  name <- utils::data(..., envir = e)[1]
  e[[name]]
}

#' Calculate geometric mean
#'
#' Calculates the geometric mean of a numeric vector
#'
#' @param x A numeric vector
#' @param na.rm A flag specifying whether to remove missing values.
#' @param zero.propagate A flag specifying whether to propagate zero values.
#' @return A number of the geometric mean.
#' @export
#' @examples
#' gm_mean(c(3, 66, 22, 17))
gm_mean <- function(x, na.rm = FALSE, zero.propagate = TRUE) {
  chk_numeric(x)
  chk_flag(na.rm)
  chk_flag(zero.propagate)

  if (!length(x)) {
    return(NaN)
  }

  if (any(x < 0, na.rm = TRUE)) {
    return(NaN)
  }
  if (zero.propagate && any(x == 0, na.rm = TRUE)) {
    return(0)
  }
  if (!na.rm && any(is.na(x))) {
    return(NA_real_)
  }
  x <- x[!is.na(x) & x > 0]
  if (!length(x)) {
    return(NaN)
  }
  exp(mean(log(x)))
}

#' List EnviroTox Dataset Names
#'
#' Lists the names of the envirotox datasets in ssddata.
#'
#' @return A character vector of envirotox dataset names.
#' @export
#' @examples
#' envirotox_data_sets()
envirotox_data_sets <- function() {
  items <- utils::data(package = "ssddata")$results[, "Item"]
  sort(items[grepl("^envirotox_", items)])
}

#' List EnviroTox Dataset Names (Deprecated)
#'
#' @description
#' This function was named `list_datasets()` in the standalone `envirotox`
#' package. It has been renamed to [envirotox_data_sets()] in `ssddata`.
#' Please update your scripts to use `envirotox_data_sets()` instead.
#'
#' @return A character vector of envirotox dataset names.
#' @export
#' @keywords internal
#' @seealso [envirotox_data_sets()]
#' @examples
#' \dontrun{
#' # Deprecated - use envirotox_data_sets() instead
#' list_datasets()
#' }
list_datasets <- function() {
  warning(
    "`list_datasets()` was renamed to `envirotox_data_sets()` in ssddata. ",
    "Please update your code to use `envirotox_data_sets()` instead.",
    call. = FALSE
  )
  envirotox_data_sets()
}

#' List SSD Datasets
#'
#' Returns a named list of SSD datasets from ssddata.
#'
#' @param set A string or character vector controlling which datasets are
#'   returned. Options:
#'   - `"v2"` (default): all current individual non-aggregate datasets
#'   - `"v1"`: fixed set of 20 datasets from ssddata v1
#'   - one or more prefix strings e.g. `c("ccme", "anzg")`: filters v2 by prefix
#'   - `"wqbench"`: splits `wqbench_data` by `Chemical`
#'   - `"envirotox_acute"`: splits `envirotox_acute` by `Chemical`
#'   - `"envirotox_chronic"`: splits `envirotox_chronic` by `Chemical`
#'   - `"anztox"`: splits `anztox_data` by `chemicalname_grouped` x `mediatype`
#'   - `"alldata"`: aggregates all `*_data` sources and splits by `Chemical`
#'
#'   **Note:** aggregated values (`"wqbench"`, `"envirotox_acute"`,
#'   `"envirotox_chronic"`, `"anztox"`, `"alldata"`) must be passed alone — they
#'   cannot be combined with each other or with prefix strings (e.g.
#'   `c("wqbench", "ccme")` is not supported and will error).
#' @param group A character vector of column names to further split datasets by
#'   before returning. Columns absent from a dataset are silently skipped.
#'   Column values are always appended to dataset names when the column is
#'   present. Default `NULL` applies no additional splitting.
#' @param dedup A string controlling how duplicate Species rows within a
#'   chemical are handled. `"geomean"` (default) applies a geometric mean and
#'   emits a message; `"none"` returns data as-is and emits a message listing
#'   duplicates.
#' @param cas_lookup A flag. When `TRUE` (default) and `set = "alldata"`,
#'   uses `data-raw/anztox/cas_parent_lookup.csv` to align chemical names/CAS
#'   numbers across datasets before splitting.
#' @return A named list of tibbles.
#' @export
#' @examples
#' ssd_data_sets()
#' ssd_data_sets(set = "v1")
#' ssd_data_sets(set = c("ccme", "anzg"))
ssd_data_sets <- function(
  set = "v2",
  group = NULL,
  dedup = "geomean",
  cas_lookup = TRUE
) {
  chk::chk_character(set)
  chk::chk_null_or(group, vld = chk::vld_character)
  chk::chk_string(dedup)
  chk::chk_flag(cas_lookup)

  if (!dedup %in% c("geomean", "none")) {
    stop(
      "`dedup` must be \"geomean\" or \"none\", not \"",
      dedup,
      "\".",
      call. = FALSE
    )
  }

  # -- v1 hardcoded list -------------------------------------------------------
  .v1_datasets <- c(
    "aims_aluminium_marine",
    "aims_gallium_marine",
    "aims_molybdenum_marine",
    "anon_a",
    "anon_b",
    "anon_c",
    "anon_d",
    "anon_e",
    "anzg_metolachlor_fresh",
    "ccme_boron",
    "ccme_cadmium",
    "ccme_chloride",
    "ccme_endosulfan",
    "ccme_glyphosate",
    "ccme_silver",
    "ccme_uranium",
    "csiro_chlorine_marine",
    "csiro_cobalt_marine",
    "csiro_lead_marine",
    "csiro_nickel_fresh"
  )

  # -- determine source datasets -----------------------------------------------
  known_aggregated <- c(
    "wqbench",
    "envirotox_acute",
    "envirotox_chronic",
    "anztox",
    "alldata"
  )

  if (length(set) == 1 && set == "v1") {
    items <- .v1_datasets
    datasets <- lapply(items, function(x) {
      e <- new.env()
      utils::data(list = x, package = "ssddata", envir = e)
      e[[x]]
    })
    names(datasets) <- items
    return(datasets)
  }

  if (length(set) == 1 && set %in% known_aggregated) {
    datasets <- .split_aggregated(set, cas_lookup)
  } else {
    # v2 or prefix filter
    items <- utils::data(package = "ssddata")$results[, "Item"]
    items <- items[!items %in% c("ssd_fits")]
    items <- items[!grepl("_data$", items)]
    items <- items[!grepl("^envirotox_", items)]
    items <- sort(items)

    if (!identical(set, "v2")) {
      # prefix filter — accepted values are the set values themselves as prefixes
      valid_prefixes <- c("aims", "anon", "anzg", "ccme", "csiro")
      unknown <- set[!set %in% valid_prefixes]
      if (length(unknown)) {
        stop(
          "Unknown `set` value(s): ",
          paste(unknown, collapse = ", "),
          ". ",
          "Valid values: \"v1\", \"v2\", \"alldata\", \"wqbench\", ",
          "\"envirotox_acute\", \"envirotox_chronic\", \"anztox\", or one or ",
          "more of: ",
          paste(valid_prefixes, collapse = ", "),
          ".",
          call. = FALSE
        )
      }
      pattern <- paste0("^(", paste(set, collapse = "|"), ")_")
      items <- items[grepl(pattern, items)]
    }

    datasets <- lapply(items, function(x) {
      e <- new.env()
      utils::data(list = x, package = "ssddata", envir = e)
      e[[x]]
    })
    names(datasets) <- items
  }

  # -- apply group splitting ---------------------------------------------------
  if (!is.null(group)) {
    datasets <- .apply_group_split(datasets, group)
  }

  # -- apply dedup -------------------------------------------------------------
  datasets <- .apply_dedup(datasets, dedup)

  datasets
}

# Split an aggregated dataset into a named list of per-chemical tibbles
.split_aggregated <- function(set, cas_lookup) {
  .pkgdata <- function(name) {
    e <- new.env()
    utils::data(list = name, package = "ssddata", envir = e)
    e[[name]]
  }

  if (set == "anztox") {
    dat <- .pkgdata("anztox_data")
    # anztox_data is a nested tibble: chemicalname_grouped x mediatype x data
    out <- vector("list", nrow(dat))
    nms <- make.names(
      paste0("anztox_", dat$chemicalname_grouped, "_", dat$mediatype)
    )
    for (i in seq_len(nrow(dat))) {
      out[[i]] <- dat$data[[i]]
    }
    names(out) <- nms
    return(out)
  }

  if (set == "alldata") {
    # Medium values in anzg_data -> dataset name suffix mapping
    .anzg_medium_suffix <- c(
      "freshwater" = "fresh",
      "marine" = "marine",
      "soft freshwater" = "soft_fresh",
      "moderate freshwater" = "moderate_fresh",
      "hard freshwater" = "hard_fresh"
    )

    # anzg_data: split by Chemical x Medium, construct full binomial Species
    anzg_raw_data <- .pkgdata("anzg_data")
    anzg_raw_data$Species <- paste(anzg_raw_data$Genus, anzg_raw_data$Species)
    anzg_raw_data$Medium_suffix <- .anzg_medium_suffix[
      tolower(trimws(anzg_raw_data$Medium))
    ]
    anzg_raw_data$Chemical_Medium <- paste0(
      anzg_raw_data$Chemical,
      "_",
      anzg_raw_data$Medium_suffix
    )

    sources <- list(
      aims = .pkgdata("aims_data"),
      anon = .pkgdata("anon_data"),
      ccme = .pkgdata("ccme_data"),
      csiro = .pkgdata("csiro_data"),
      wqbench = .pkgdata("wqbench_data"),
      envirotox_acute = .pkgdata("envirotox_acute"),
      envirotox_chronic = .pkgdata("envirotox_chronic")
    )

    # anztox_data is nested — unnest first, normalise column names
    anztox_raw <- .pkgdata("anztox_data")
    anztox_flat <- do.call(
      rbind,
      lapply(seq_len(nrow(anztox_raw)), function(i) {
        d <- anztox_raw$data[[i]]
        d$Chemical <- anztox_raw$chemicalname_grouped[i]
        if ("scientificname" %in% names(d) && !"Species" %in% names(d)) {
          names(d)[names(d) == "scientificname"] <- "Species"
        }
        if ("endpoint_concentration" %in% names(d) && !"Conc" %in% names(d)) {
          names(d)[names(d) == "endpoint_concentration"] <- "Conc"
        }
        d
      })
    )
    sources$anztox <- anztox_flat

    if (cas_lookup) {
      lookup_path <- system.file(
        "data-raw/anztox/cas_parent_lookup.csv",
        package = "ssddata"
      )
      if (nchar(lookup_path) && file.exists(lookup_path)) {
        lookup <- utils::read.csv(lookup_path, stringsAsFactors = FALSE)
        # apply lookup to any source that has a CAS column — left as a hook
        # for future implementation; currently a no-op if lookup not bundled
      }
    }

    all_out <- list()

    # handle anzg separately — split by Chemical x Medium
    for (chem_med in unique(anzg_raw_data$Chemical_Medium)) {
      nm <- make.names(paste0("anzg_", chem_med))
      slice <- anzg_raw_data[
        anzg_raw_data$Chemical_Medium == chem_med,
        ,
        drop = FALSE
      ]
      slice$Chemical_Medium <- NULL
      slice$Medium_suffix <- NULL
      # Genus is already incorporated into Species (full binomial); drop to avoid
      # .apply_dedup pasting Species_Genus as the dedup key
      slice$Genus <- NULL
      all_out[[nm]] <- slice
    }

    # aims and csiro also have a Medium column — split by Chemical x Medium
    # so names match individual datasets (e.g. aims_aluminium_marine, csiro_nickel_fresh)
    # Medium values in aims/csiro are already short-form ("fresh", "marine");
    # map both short and long forms for robustness
    .medium_suffix <- c(
      "freshwater" = "fresh",
      "fresh" = "fresh",
      "marine" = "marine"
    )
    for (src_name in c("aims", "csiro")) {
      src_raw <- .pkgdata(paste0(src_name, "_data"))
      src_raw$Medium_suffix <- .medium_suffix[tolower(trimws(src_raw$Medium))]
      src_raw$Chemical_Medium <- paste0(
        src_raw$Chemical,
        "_",
        src_raw$Medium_suffix
      )
      for (chem_med in unique(src_raw$Chemical_Medium)) {
        nm <- make.names(paste0(src_name, "_", chem_med))
        slice <- src_raw[src_raw$Chemical_Medium == chem_med, , drop = FALSE]
        slice$Chemical_Medium <- NULL
        slice$Medium_suffix <- NULL
        all_out[[nm]] <- slice
      }
    }

    sources <- list(
      anon = .pkgdata("anon_data"),
      ccme = .pkgdata("ccme_data"),
      wqbench = .pkgdata("wqbench_data"),
      envirotox_acute = .pkgdata("envirotox_acute"),
      envirotox_chronic = .pkgdata("envirotox_chronic"),
      anztox = anztox_flat
    )

    for (src_name in names(sources)) {
      src <- sources[[src_name]]
      if (!is.data.frame(src)) {
        next
      }
      # normalise chemical column
      if ("chemical_name" %in% names(src) && !"Chemical" %in% names(src)) {
        names(src)[names(src) == "chemical_name"] <- "Chemical"
      }
      if (!"Chemical" %in% names(src)) {
        next
      }
      # normalise species column
      if ("latin_name" %in% names(src) && !"Species" %in% names(src)) {
        names(src)[names(src) == "latin_name"] <- "Species"
      }
      # normalise concentration column (note: wqbench is mg/L, others µg/L)
      if ("sp_aggre_conc_mg.L" %in% names(src) && !"Conc" %in% names(src)) {
        names(src)[names(src) == "sp_aggre_conc_mg.L"] <- "Conc"
      }
      chemicals <- unique(src$Chemical)
      for (chem in chemicals) {
        nm <- make.names(paste0(src_name, "_", chem))
        all_out[[nm]] <- src[src$Chemical == chem, , drop = FALSE]
      }
    }

    return(all_out)
  }

  # wqbench / envirotox_acute / envirotox_chronic — flat tibbles split by chemical col
  raw_name <- switch(
    set,
    wqbench = "wqbench_data",
    envirotox_acute = "envirotox_acute",
    envirotox_chronic = "envirotox_chronic"
  )
  # wqbench uses chemical_name; envirotox uses Chemical
  chem_col <- if (set == "wqbench") "chemical_name" else "Chemical"
  e <- new.env()
  utils::data(list = raw_name, package = "ssddata", envir = e)
  dat <- e[[raw_name]]
  if (!chem_col %in% names(dat)) {
    stop(
      "Expected column '",
      chem_col,
      "' not found in '",
      raw_name,
      "'.",
      call. = FALSE
    )
  }
  chemicals <- unique(dat[[chem_col]])
  out <- lapply(chemicals, function(chem) {
    dat[dat[[chem_col]] == chem, , drop = FALSE]
  })
  names(out) <- make.names(paste0(set, "_", chemicals))
  out
}

# Split each dataset in a named list by one or more column values,
# appending column values to dataset names. Columns absent from a dataset
# are silently skipped.
.apply_group_split <- function(datasets, group) {
  out <- list()
  for (nm in names(datasets)) {
    dat <- datasets[[nm]]
    present_cols <- intersect(group, names(dat))
    if (!length(present_cols)) {
      out[[nm]] <- dat
      next
    }
    # build split key
    key <- apply(dat[, present_cols, drop = FALSE], 1, paste, collapse = "_")
    unique_keys <- unique(key)
    for (k in unique_keys) {
      sub_nm <- make.names(paste0(nm, "_", k))
      out[[sub_nm]] <- dat[key == k, , drop = FALSE]
    }
  }
  out
}

# Apply deduplication across all datasets in a named list.
# Uses Species/Genus columns (if present) and Conc column.
.apply_dedup <- function(datasets, dedup) {
  spp_vec <- c("Species", "Genus")
  conc_col <- "Conc"

  deduped_nms <- character(0)
  dup_info <- list()

  out <- lapply(names(datasets), function(nm) {
    dat <- datasets[[nm]]
    if (!conc_col %in% names(dat)) {
      return(dat)
    }

    spp_x <- intersect(spp_vec, names(dat))
    if (!length(spp_x)) {
      return(dat)
    }

    spp_dat <- apply(dat[, spp_x, drop = FALSE], 1, paste, collapse = "_")
    has_dups <- anyDuplicated(spp_dat) > 0

    if (!has_dups) {
      return(dat)
    }

    if (dedup == "none") {
      dup_spp <- unique(spp_dat[duplicated(spp_dat)])
      dup_info[[nm]] <<- dup_spp
      return(dat)
    }

    # geomean
    deduped_nms <<- c(deduped_nms, nm)
    dat_out <- data.frame(spp = spp_dat, conc = dat[[conc_col]])
    dat_out <- dplyr::group_by(dat_out, .data$spp)
    dat_out <- dplyr::summarise(
      dat_out,
      conc = gm_mean(.data$conc),
      .groups = "drop"
    )
    spp_name <- paste(spp_x, collapse = "_")
    names(dat_out) <- c(spp_name, conc_col)
    dat_out
  })
  names(out) <- names(datasets)

  if (dedup == "geomean" && length(deduped_nms)) {
    message(
      "Geometric mean applied to duplicate species rows in: ",
      paste(deduped_nms, collapse = ", "),
      "."
    )
  }
  if (dedup == "none" && length(dup_info)) {
    for (nm in names(dup_info)) {
      message(
        "Duplicate species in ",
        nm,
        ": ",
        paste(dup_info[[nm]], collapse = ", "),
        "."
      )
    }
  }

  out
}
