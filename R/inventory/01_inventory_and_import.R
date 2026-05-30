library(readxl)
library(dplyr)
library(stringr)
library(tibble)

# Project paths
project_dir = file.path(Sys.getenv("HOME"), "Desktop", "Project", "reporting-sys")
data_dir = file.path(project_dir, "data")
qa_dir = file.path(project_dir, "outputs", "qa_reports")

# Create output folder if it does not exist
dir.create(qa_dir, recursive = TRUE, showWarnings = FALSE)

# Find all Excel files recursively
excel_files = list.files(
  path = data_dir,
  pattern = "\\.xlsx$",
  recursive = TRUE,
  full.names = TRUE
)

records = lapply(excel_files, function(file_path) {
  file_name = basename(file_path)
  report_type = basename(dirname(file_path))
  
  # Extract academic year like 18-19, 21_22, etc.
  year_match = str_extract(file_name, "\\d{2}[-_]\\d{2}")
  
  academic_year = if (!is.na(year_match)) {
    str_replace(year_match, "_", "-")
  } else {
    NA_character_
  }
  
  # Get sheet names
  sheet_names = character(0)
  sheet_count = 0
  
  tryCatch({
    sheet_names = excel_sheets(file_path)
    sheet_count = length(sheet_names)
  }, error = function(error) {
    message(sprintf("Could not read sheets from %s: %s", file_name, error$message))
  })
  
  tibble(
    file_path = file_path,
    file_name = file_name,
    report_type = report_type,
    academic_year = academic_year,
    sheet_count = sheet_count,
    sheet_names = paste(sheet_names, collapse = "; ")
  )
})

file_inventory = bind_rows(records)

# Sort for readability
file_inventory = file_inventory %>%
  arrange(report_type, academic_year, file_name)

# Save inventory
output_path = file.path(qa_dir, "file_inventory.csv")
write.csv(file_inventory, output_path, row.names = FALSE)

cat(sprintf("File inventory saved to: %s\n\n", output_path))
print(file_inventory)