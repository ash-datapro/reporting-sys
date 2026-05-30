# data_dir = "~/Desktop/Project/reporting-sys/data/cleaned_data/"
# 
# awards_by_demo_2018_2024_combined =
#   read.csv(file.path(data_dir, "awards_by_demo_2018_2024_combined.csv"))
# 
# enrollment_by_demo_2018_2024_combined =
#   read.csv(file.path(data_dir, "enrollment_by_demo_2018_2024_combined.csv"))
# 
# enrollment_by_level_2019_2024_combined =
#   read.csv(file.path(data_dir, "enrollment_by_level_2019_2024_combined.csv"))
# 
# financial_aid_2018_2024_combined =
#   read.csv(file.path(data_dir, "financial_aid_2018_2024_combined.csv"))
# 
# graduation_rates_2018_2024_combined =
#   read.csv(file.path(data_dir, "graduation_rates_2018_2024_combined.csv"))
# 
# retention_undergrad_2018_2024_combined =
#   read.csv(file.path(data_dir, "retention_undergrad_2018_2024_combined.csv"))

library(readr)
library(dplyr)
library(stringr)
library(janitor)

input_dir = "~/Desktop/Project/reporting-sys/data/combined_data/"
output_dir = "~/Desktop/Project/reporting-sys/data/db_ready_data/"

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

files = list.files(
  input_dir,
  pattern = "\\.csv$",
  full.names = TRUE
)

clean_one_file = function(path) {
  
  df = read_csv(path, na = c("", "NA", "N/A", "na", "null", "NULL"), show_col_types = FALSE)
  
  # 1. Standardize column names
  names(df) = make_clean_names(names(df))
  
  # 2. Remove footnote markers from character columns
  char_cols = names(df)[sapply(df, is.character)]
  
  for (col in char_cols) {
    
    footnote_col = paste0(col, "_footnote")
    footnotes = str_extract(df[[col]], "(?<=[A-Za-z\\)])\\d+$")
    
    if (any(!is.na(footnotes))) {
      df[[footnote_col]] = footnotes
    }
    
    df[[col]] = df[[col]] |>
      str_remove("(?<=[A-Za-z\\)])\\d+$") |>
      str_squish()
  }
  
  # 3. Use true NA values, not string "NA"
  df = df |>
    mutate(across(
      everything(),
      ~ ifelse(.x %in% c("NA", "N/A", "na", "null", "NULL", ""), NA, .x)
    ))
  
  # 4. Round messy decimals in numeric columns
  numeric_cols = names(df)[sapply(df, is.numeric)]
  
  df = df |>
    mutate(across(
      all_of(numeric_cols),
      ~ round(.x, 2)
    ))
  
  output_path = file.path(output_dir, basename(path))
  
  # Write blanks for missing values, not the string "NA"
  write_csv(df, output_path, na = "")
}

for (file in files) {
  clean_one_file(file)
}