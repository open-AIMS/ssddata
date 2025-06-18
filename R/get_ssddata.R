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
get_ssddata <- function(dataset_name, filter_val = NULL,
                        use_gmmean = TRUE,
                        spp_vec = c("Species", "Genus"),
                        conc = "Conc") {
  if (!is.null(filter_val)) {
    if (is.na(filter_val)) { filter_val <-  NULL }
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
      dataset_name, "dataset."
    ))
    return(dat_out)
  }

  spp_dat <- apply(dat_x[, spp_x], 1, paste, collapse = "_")
  duplicate_spp <- nrow(dat_x) != length(unique(spp_dat))

  if (!use_gmmean || !duplicate_spp) {
    dat_out <- dat_x
    message(paste(
      "No grouping has been applied, returning raw",
      dataset_name, "dataset."
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
    "Data", dataset_name, "grouped by", paste(spp_x, collapse = ", "),
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
