# generate_OK_column_standards

# GENERATE COLUMN STANDARDS FOR DATA FRAMES AND EXCELSHEETS USED IN MANAGEMENT OF THE NORWEGIAN SURVEILLANCE (OK-) PROGRAMMES ----

# DESIGN ----
# Set up R-environment
# Read Excel sheet with column standars
# Select data for OK-programmes
# Transform data
# Save data to ./data/OK_column_standards.rds

library(openxlsx)
# library(dplyr)
library(tidyr)
library(purrr)
library(NVIdb)
library(usethis)


# READS AND TRANSFORMS EXCEL SHEET WITH COLUMN STANDARD INFORMATION ----
OK_column_standards <- read.xlsx(xlsxFile = paste0(set_dir_NVI("ProgrammeringR"), "standardization/colnames/colnames_translation_table.xlsx")) %>%
  # Selects only information used in OK-planning
  poorman::filter(db == "OK_planlegging") %>%
  # Generates column labels based on label and spec for no and en
  # Use exactly same transformations as for column_standards
  poorman::rename(label_no = collabel_no, label_en = collabel_en) %>%
  poorman::mutate(label_1_no = poorman::case_when(is.na(spec_no) ~ label_no,
                                              spec_no %in% c("dato", "geometrisk middel 3") ~ paste(label_no, spec_no),
                                              spec_no %in% c("kg", "kjennelse", "tid") ~ label_no,
                                              spec_no %in% c("antall undersøkt") ~ paste(spec_no, label_no),
                                              TRUE ~ spec_no)) %>%
  poorman::mutate(label_1_en = poorman::case_when(is.na(spec_en) ~ label_en,
                                              spec_en %in% c("date") ~ paste(label_en, spec_en),
                                              spec_en %in% c("kg", "time", "determination") ~ label_en,
                                              spec_en %in% c("No. tested") ~ paste(spec_en, label_en),
                                              TRUE ~ spec_en)) %>%
  # selects, renames and orders columns
  poorman::select(db, table_db, colname_db, colname, label_1_no, label_no, spec_no, label_1_en, label_en, spec_en,
                colwidth_Excel = colwidth_excel, colwidth_DT = colwidth_dt_tables, colclasses, colorder) %>%
  poorman::distinct()


# Generate data frame with all table names
db_tables <- as.data.frame(unique(OK_column_standards$table_db)) %>%
  poorman::rename(tables = 1) %>%
  dplyr::mutate(table = strsplit(tables, split = ",")) %>%
  dplyr::mutate_if(is.list, purrr::simplify_all) %>%    # flatten each list element internally
  tidyr::unnest(cols = "table")# expand

# Started alternative code without dplyr, purr and tidyr
# # Generate data frame with all table names
# db_tables <- as.data.frame(unique(OK_column_standards$table_db))
# colnames(db_tables) <- "tables"
# db_tables$table <- strsplit(db_tables$tables, split = ",")
#
# dplyr::mutate(table =  %>%
#   dplyr::mutate_if(is.list, purrr::simplify_all) %>%    # flatten each list element internally
#   tidyr::unnest(cols = "table")# expand

# Generate table with each table name on one line
OK_column_standards <- OK_column_standards %>%
  poorman::left_join(db_tables, by = c("table_db" = "tables")) %>%
  poorman::mutate(table_db = trimws(table)) %>%
  poorman::select(!table)

# unique_colnames <- unique(column_standards[, c("colname_db", "colname")]) %>%
#   poorman::add_count(colname_db, name = "unique_colnames") %>%
#   poorman::mutate(unique_colnames = poorman::case_when(unique_colnames == 1 ~ 1,
#                                                    TRUE ~ 0))
#
# OK_column_standards <- OK_column_standards %>%
#   poorman::left_join(unique_colnames, by = c("colname_db" = "colname_db", "colname" = "colname"))

# SAVE IN PACKAGE DATA ----
usethis::use_data(name = OK_column_standards, overwrite = TRUE, internal = FALSE)

# write.csv2(OK_column_standards,
#            file = paste0(set_dir_NVI("ProgrammeringR"), "standardization/OK_column_standards.csv"),
#            row.names = FALSE,
#            fileEncoding = "UTF-8")

