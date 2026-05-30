library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(readr)

data_dir = "~/Desktop/Project/reporting-sys/data/awards_by_demo/"

files = c(
  "awards_by_demo_18-19.xlsx",
  "awards_by_demo_19-20.xlsx",
  "awards_by_demo_20-21.xlsx",
  "awards_by_demo_21-22.xlsx",
  "awards_by_demo_22-23.xlsx",
  "awards_by_demo_23-24.xlsx"
)

files = file.path(data_dir, files)

clean_text = function(x) {
  x = as.character(x)
  x %>%
    str_replace_all("\\n", " ") %>%
    str_replace_all("’", "'") %>%
    str_replace_all("—", "-") %>%
    str_replace_all("–", "-") %>%
    str_squish()
}

clean_header = function(x) {
  clean_text(x) %>%
    str_replace_all("U\\.S\\. nonresident|U\\.S\\. Nonresident|Nonresident1", "Nonresident") %>%
    str_replace_all("Race/ ethnicity unknown", "Race/ethnicity unknown") %>%
    str_squish()
}

get_year_from_file = function(path) {
  str_extract(basename(path), "\\d{2}-\\d{2}")
}

read_awards_file = function(path) {
  
  year = get_year_from_file(path)
  
  raw = read_excel(
    path,
    sheet = 1,
    col_names = FALSE,
    .name_repair = "unique"
  )
  
  # Find the header row dynamically
  raw_clean = raw %>%
    mutate(across(everything(), clean_text))
  
  header_row = which(
    apply(
      raw_clean,
      1,
      function(row) {
        any(row == "All students", na.rm = TRUE) &&
          any(str_detect(row, "^Asian$"), na.rm = TRUE)
      }
    )
  )[1]
  
  if (is.na(header_row)) {
    stop(paste("Could not find header row in", basename(path)))
  }
  
  headers = raw_clean[header_row, ] %>%
    unlist(use.names = FALSE) %>%
    clean_header()
  
  label_col = which(str_detect(headers, "^Level of award"))[1]
  
  demo_cols = which(
    headers %in% c(
      "All students",
      "American Indian or Alaska Native",
      "Asian",
      "Black or African American",
      "Hispanic or Latino",
      "Native Hawaiian or Other Pacific Islander",
      "White",
      "Two or more races",
      "Race/ethnicity unknown",
      "Nonresident"
    )
  )
  
  if (is.na(label_col)) {
    label_col = 1
  }
  
  if (length(demo_cols) == 0) {
    stop(paste("Could not find demographic columns in", basename(path)))
  }
  
  demo_headers = headers[demo_cols]
  
  body = raw[(header_row + 1):nrow(raw), c(label_col, demo_cols)]
  names(body) = c("label", demo_headers)
  
  body = body %>%
    mutate(
      label = clean_text(label),
      across(
        -label,
        ~ parse_number(as.character(.x))
      )
    ) %>%
    filter(!is.na(label), label != "") %>%
    filter(if_any(-label, ~ !is.na(.x))) %>%
    filter(
      !str_detect(label, "^NOTE:"),
      !str_detect(label, "^SOURCE:"),
      !str_detect(label, "^Table "),
      !str_detect(label, "^National Center")
    )
  
  gender_values = c("Men", "Women", "Male", "Female")
  
  body = body %>%
    mutate(
      is_gender_row = label %in% gender_values,
      award_temp = if_else(is_gender_row, NA_character_, label)
    ) %>%
    fill(award_temp, .direction = "down") %>%
    mutate(
      Year = year,
      `Level of award` = award_temp,
      Gender = case_when(
        label %in% c("Men", "Male") ~ "Men",
        label %in% c("Women", "Female") ~ "Women",
        TRUE ~ "All students"
      )
    ) %>%
    select(
      Year,
      `Level of award`,
      Gender,
      all_of(demo_headers)
    )
  
  body
}

combined_awards = map_dfr(files, read_awards_file)

combined_awards = combined_awards %>%
  mutate(
    `Level of award` = `Level of award` %>%
      str_replace_all("Post-baccalaureate", "Postbaccalaureate") %>%
      str_replace_all("\\d+$", "") %>%
      str_squish()
  )

write_csv(combined_awards, "~/Desktop/Project/reporting-sys/awards_by_demo_2018_2024_combined.csv")