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
#'   - `"all_chronic"`: returns `allchronic_data` as a named list keyed by the
#'     pre-computed `Set` column (`sanitised_chemical_medium_token`, e.g.
#'     `copper_marine`). Mixed-medium sets have keys ending `_mixed`.
#'     The `Set` column is dropped from each list element.
#'
#'   **Note:** aggregated values (`"wqbench"`, `"envirotox_acute"`,
#'   `"envirotox_chronic"`, `"anztox"`, `"all_chronic"`) must be passed alone -
#'   they cannot be combined with each other or with prefix strings (e.g.
#'   `c("wqbench", "ccme")` is not supported and will error).
#' @param split A character vector of column names to further split datasets by
#'   before returning. Columns absent from a dataset are silently skipped.
#'   Column values are appended to dataset names when the column is present.
#'   Default `NULL` applies no additional splitting.
#' @param summarize A string controlling how duplicate Species rows within a
#'   chemical are handled. `"geomean"` (default) applies a geometric mean and
#'   emits a message; `"none"` returns data as-is and emits a message listing
#'   duplicates.
#' @param cas_lookup Deprecated. Formerly used as a hook for CAS-based chemical
#'   name alignment when `set = "alldata"`. The `all_chronic` pipeline handles
#'   CAS alignment at build time; this parameter is ignored and will be removed
#'   in a future version.
#' @return A named list of tibbles. Every tibble is guaranteed to have
#'   `Species` as the first column and `Conc` as the second column.
#'   Datasets with no species information (`anon_*`) receive sequential species
#'   labels (`"sp. A"`, `"sp. B"`, ...). Additional columns follow in their
#'   original order.
#' @export
#' @examples
#' ssd_data_sets()
#' ssd_data_sets(set = "v1")
#' ssd_data_sets(set = c("ccme", "anzg"))
ssd_data_sets <- function(
  set = "v2",
  split = NULL,
  summarize = "geomean",
  cas_lookup = TRUE
) {
  chk::chk_character(set)
  chk::chk_null_or(split, vld = chk::vld_character)
  chk::chk_string(summarize)
  chk::chk_flag(cas_lookup)

  if (!summarize %in% c("geomean", "none")) {
    stop(
      "`summarize` must be \"geomean\" or \"none\", not \"",
      summarize,
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
    "all_chronic"
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
      valid_prefixes <- c("aims", "anon", "anzg", "ccme", "csiro")
      unknown <- set[!set %in% valid_prefixes]
      if (length(unknown)) {
        stop(
          "Unknown `set` value(s): ",
          paste(unknown, collapse = ", "),
          ". ",
          "Valid values: \"v1\", \"v2\", \"all_chronic\", \"wqbench\", ",
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
  if (!is.null(split)) {
    datasets <- .apply_group_split(datasets, split)
  }

  # -- apply dedup -------------------------------------------------------------
  datasets <- .apply_dedup(datasets, summarize)

  # -- harmonise columns: ensure Species and Conc are present and first --------
  datasets <- .harmonise_columns(datasets)

  datasets
}

# Harmonise columns across all datasets so every tibble has Species and Conc
# as the first two columns, ready for use with ssdtools.
# All source-specific column names are now standardised in data-raw/ build
# scripts, so this function only needs to:
#   - assign sequential labels to anon_* (genuinely species-anonymous)
#   - reorder so Species and Conc are always the first two columns
.harmonise_columns <- function(datasets) {
  .seq_species <- function(n) {
    LETTERS_ext <- c(LETTERS, as.vector(outer(LETTERS, LETTERS, paste0)))
    paste("sp.", LETTERS_ext[seq_len(n)])
  }

  lapply(datasets, function(dat) {
    # assign sequential species labels for genuinely anonymous datasets
    if (!"Species" %in% names(dat) && "Conc" %in% names(dat)) {
      dat$Species <- .seq_species(nrow(dat))
    }
    # reorder: Species and Conc first, all other columns after
    other_cols <- setdiff(names(dat), c("Species", "Conc"))
    if ("Species" %in% names(dat) && "Conc" %in% names(dat)) {
      dat <- dat[, c("Species", "Conc", other_cols), drop = FALSE]
    }
    dat
  })
}

# Split an aggregated dataset into a named list of per-chemical tibbles.
# All column names are now standardised (Species, Conc, Chemical, Medium)
# in the data-raw/ build scripts.
.split_aggregated <- function(set, cas_lookup) {
  .pkgdata <- function(name) {
    e <- new.env()
    utils::data(list = name, package = "ssddata", envir = e)
    e[[name]]
  }

  if (set == "anztox") {
    dat <- .pkgdata("anztox_data")
    # anztox_data is a nested tibble: chemicalname_grouped x mediatype x data
    # inner tibbles already have Species, Conc, Chemical, Medium columns
    nms <- make.names(
      paste0("anztox_", dat$chemicalname_grouped, "_", dat$mediatype)
    )
    out <- dat$data
    names(out) <- nms
    return(out)
  }

  if (set == "all_chronic") {
    dat <- .pkgdata("allchronic_data")
    # allchronic_data carries a Set column with pre-computed keys.
    # Return a named list, one element per Set, with Set dropped from each element.
    sets <- split(dat, dat$Set)
    sets <- lapply(sets, function(d) {
      d$Set <- NULL
      d
    })
    return(sets)
  }

  # wqbench / envirotox_acute / envirotox_chronic - flat tibbles, split by Chemical
  raw_name <- switch(
    set,
    wqbench = "wqbench_data",
    envirotox_acute = "envirotox_acute",
    envirotox_chronic = "envirotox_chronic"
  )
  e <- new.env()
  utils::data(list = raw_name, package = "ssddata", envir = e)
  dat <- e[[raw_name]]
  if (!"Chemical" %in% names(dat)) {
    stop(
      "Expected column 'Chemical' not found in '",
      raw_name,
      "'.",
      call. = FALSE
    )
  }
  chemicals <- unique(dat$Chemical)
  out <- lapply(chemicals, function(chem) {
    dat[dat$Chemical == chem, , drop = FALSE]
  })
  names(out) <- make.names(paste0(set, "_", chemicals))
  out
}

# Split each dataset in a named list by one or more column values,
# appending column values to dataset names. Columns absent from a dataset
# are silently skipped.
.apply_group_split <- function(datasets, split) {
  out <- list()
  for (nm in names(datasets)) {
    dat <- datasets[[nm]]
    present_cols <- intersect(split, names(dat))
    if (!length(present_cols)) {
      out[[nm]] <- dat
      next
    }
    key <- apply(dat[, present_cols, drop = FALSE], 1, paste, collapse = "_")
    for (k in unique(key)) {
      sub_nm <- make.names(paste0(nm, "_", k))
      out[[sub_nm]] <- dat[key == k, , drop = FALSE]
    }
  }
  out
}

# Apply deduplication across all datasets in a named list.
.apply_dedup <- function(datasets, summarize) {
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

    if (summarize == "none") {
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

  if (summarize == "geomean" && length(deduped_nms)) {
    message(
      "Geometric mean applied to duplicate species rows in: ",
      paste(deduped_nms, collapse = ", "),
      "."
    )
  }
  if (summarize == "none" && length(dup_info)) {
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
