
#' Create data and data documentation for a long data set
#'
#' Creates .rda files and .R files to generate .Rd files for documentation,
#' using the information contained
#' in the supplied data and template
#'
#' @param data A data frame or tibble.
#' @param col_desc_list A names list containing the column names
#' and associated
#' desired description text (excluding the col class information) for all
#' columns of data that are to be used in the packaged dataset.
#' @param ref_col A character string indicating the column to be used for
#' extracting references for the dataset.
#' @param chem_col A character string indicating the column to be used for
#' extracting the chemical names for the dataset.
#' @param ref_data An optional data frame containing the reference and
#' chemical information for the data.
#' Columns must match ref_col and chem_col if supplied.
#' @param template The filename (including relative path) of the template
#' .Rd file.
#' @param prefix A character string to be used on the dataset name to
#' identify the dataset.
#'
#' @details This function is experimental and currently tailored to meet
#' the existing use requirements.
#' It requires considerable further development to be of
#' broader generalised use.
#'
#' @return Writes out a .R and .rda file for package processing.

create_data <- function(data, template, prefix, col_desc_list,
                        ref_col = "Reference",
                        chem_col = "Chemical", ref_dat) {
  df_name <- paste(prefix, "data", sep = "_")
  data_use <- data %>%
    dplyr::select(names(col_desc_list))
  col_desc <- col_desc_list[stats::na.omit(match(
    colnames(data_use),
    names(col_desc_list)
  ))]
  col_type_dat <- lapply(data_use, pillar::type_sum)[names(col_desc)]

  if (missing(ref_dat)) {
    ref_dat <- ref_dat <- unique(data[, c(chem_col, ref_col)]) %>%
      data.frame()
  }

  descr_dat <- paste(paste0(paste("\\\n#'\\\t\\\\item{",
    ref_dat[, chem_col], "}{\\\\insertRef{",
    ref_dat[, ref_col], "}{ssddata}}",
    sep = ""
  ), collapse = ""), "\\\n#'")
  descr_col_dat <- paste(paste0(paste("\\\n#'\\\\item{",
    names(col_desc), "}{", col_desc,
    " (", col_type_dat, ").}",
    sep = ""
  ), collapse = ""), "\\\n#'")
  hl_doc_text <- Rd2roxygen::create_roxygen(Rd2roxygen::parse_file(template))
  # Encoding(hl_doc_text) <- "UTF-8"
  hl_doc_text <- stringr::str_replace(
    hl_doc_text, " XX ",
    descr_dat
  )
  hl_doc_text <- stringr::str_replace(
    hl_doc_text, "COLDATA",
    descr_col_dat
  )
  hl_doc_text <- stringr::str_replace(
    hl_doc_text, "XNRX",
    as.character(nrow(data_use))
  )
  hl_doc_text <- stringr::str_replace(
    hl_doc_text, "XNCX",
    as.character(ncol(data_use))
  )
  hl_doc_text <- stringr::str_replace(hl_doc_text, "DATANAME", df_name)
  hl_doc_text <- stringr::str_replace(
    hl_doc_text, "NULL",
    paste('"', df_name, '"', sep = "")
  )
  readr::write_lines(hl_doc_text, paste("R/", df_name, ".R", sep = ""), append = FALSE)
  assign(df_name, data_use)
  do.call("use_data", list(as.name(df_name), overwrite = TRUE))
}

#' Create data and data documentation for all subsets of a long data set
#'
#' Creates .rda files and .R files to generate .Rd files for documentation,
#' using the information contained in the supplied data and template.
#' Unique levels of the column identified in chem_col are used
#' to loop through
#' data to generate individual
#' .rda data subsets and the
#' appropriate documentation.
#'
#' @param data A data frame or tibble.
#' @param col_desc_list A names list containing the column names
#' and associated
#' desired description text (excluding the col class information)
#' for all columns of data that
#' are to be used in the packaged dataset.
#' @param ref_col A character string indicating the column to be used for
#' extracting references for the dataset.
#' @param chem_col A character string indicating the column to be used for
#' extracting the chemical names for the dataset.
#' @param ref_data An optional data frame containing the reference and
#' chemical information for the data.
#' Columns must match ref_col and chem_col if supplied.
#' @param template The filename (including relative path) of the template
#' .Rd file.
#' @param prefix A character string to be used on the
#' dataset name to identify the dataset.
#'
#' @details This function is experimental and currently tailored to meet
#' the existing use requirements.
#' It requires considerable further development to be of
#' broader generalised use.
#'
#' @return Writes out a .R and .rda file for package processing.

create_data_subset <- function(data, template, prefix, col_desc_list,
                               ref_col = "Reference",
                               chem_col = "Chemical", ref_dat) {
  dat_vec <- unlist(unique(data[chem_col]))
  col_desc <- col_desc_list[stats::na.omit(match(
    colnames(data),
    names(col_desc_list)
  ))]

  for (item in dat_vec) {
    dat_i <- data[which(data[, chem_col] == item), ] %>%
      dplyr::select(names(col_desc)) %>%
      dplyr::select_if(~ sum(!is.na(.)) > 0)
    df_name <- paste(prefix, item, sep = "_")
    chem_name <- item
    chem <- unlist(strsplit(item, split = "_"))[1]
    medium <- unlist(strsplit(item, split = "_"))[2]
    ref_key <- data[which(data[, chem_col] == item), ] %>%
      dplyr::select(tidyselect::all_of(ref_col)) %>%
      unique()
    ref_string <- paste("\n#'\\\\insertRef{", ref_key,
      "}{ssddata} \n#'",
      sep = ""
    )
    col_desc_i <- col_desc[stats::na.omit(match(
      colnames(dat_i),
      names(col_desc)
    ))]
    col_type_dat_i <- lapply(dat_i, pillar::type_sum)[names(col_desc_i)]
    descr_col_dat_i <- paste(paste0(paste("\\\n#'\\\\item{",
      names(col_desc_i), "}{", col_desc_i, " (",
      col_type_dat_i, ").}",
      sep = ""
    ), collapse = ""), "\\\n#'")
    assign(df_name, dat_i)

    do.call("use_data", list(as.name(df_name), overwrite = TRUE))
    # documentation
    doc_text <- Rd2roxygen::create_roxygen(Rd2roxygen::parse_file(template))
    doc_text <- stringr::str_replace(doc_text, "DATANAME", df_name)
    doc_text <- stringr::str_replace(doc_text, "CHEMNAME", chem_name)
    doc_text <- stringr::str_replace(doc_text, "CHEMSHORT", chem)
    doc_text <- stringr::str_replace(doc_text, "MEDIUM", medium)
    doc_text <- stringr::str_replace(
      doc_text, "XNRX",
      as.character(nrow(dat_i))
    )
    doc_text <- stringr::str_replace(
      doc_text, "XNCX",
      as.character(ncol(dat_i))
    )
    doc_text <- stringr::str_replace(doc_text, "DD", ref_string)
    doc_text <- stringr::str_replace(doc_text, "COLDATA", descr_col_dat_i)
    doc_text <- stringr::str_replace(
      doc_text, "NULL",
      paste('"', df_name, '"', sep = "")
    )
    readr::write_lines(doc_text, paste("R/", df_name, ".R", sep = ""), append = FALSE)
  }
}
