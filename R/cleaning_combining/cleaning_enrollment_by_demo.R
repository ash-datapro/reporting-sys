library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(readr)

data_dir = "~/Desktop/Project/reporting-sys/data/enrollment_by_demo/"

files = list.files(
  data_dir,
  pattern = "^enrollment_by_demo_\\d{2}-\\d{2}\\.xlsx$",
  full.names = TRUE
)

clean_text = function(x) {
  as.character(x) %>%
    str_replace_all("\\n", " ") %>%
    str_replace_all("’", "'") %>%
    str_replace_all("—", "-") %>%
    str_replace_all("–", "-") %>%
    str_squish()
}

clean_demo = function(x) {
  clean_text(x) %>%
    str_replace_all("Race/ ethnicity unknown", "Race/ethnicity unknown") %>%
    str_replace_all("Nonresident1", "Nonresident") %>%
    str_replace_all("U\\.S\\. nonresident|U\\.S\\. Nonresident", "Nonresident") %>%
    str_squish()
}

standardize_gender = function(x) {
  case_when(
    x %in% c("Male", "Men") ~ "Men",
    x %in% c("Female", "Women") ~ "Women",
    TRUE ~ x
  )
}

get_year_from_file = function(path) {
  str_extract(basename(path), "\\d{2}-\\d{2}")
}

read_enrollment_file = function(path) {
  
  year = get_year_from_file(path)
  
  raw = read_excel(
    path,
    sheet = 1,
    col_names = FALSE,
    .name_repair = "unique"
  )
  
  raw_clean = raw %>%
    mutate(across(everything(), clean_text))
  
  header_row = which(
    apply(
      raw_clean,
      1,
      function(row) {
        any(str_detect(row, "^State or jurisdiction$"), na.rm = TRUE) &&
          any(row == "All students", na.rm = TRUE)
      }
    )
  )[1]
  
  if (is.na(header_row)) {
    stop(paste("Could not find header row in", basename(path)))
  }
  
  demo_row = raw_clean[header_row, ] %>%
    unlist(use.names = FALSE) %>%
    clean_demo()
  
  gender_row = raw_clean[header_row + 1, ] %>%
    unlist(use.names = FALSE) %>%
    clean_text() %>%
    standardize_gender()
  
  state_col = which(str_detect(demo_row, "^State or jurisdiction$"))[1]
  
  # Fill merged demographic headers across columns
  demo_filled = demo_row
  
  for (i in seq_along(demo_filled)) {
    if (is.na(demo_filled[i]) || demo_filled[i] == "") {
      demo_filled[i] = demo_filled[i - 1]
    }
  }
  
  value_cols = which(gender_row %in% c("Men", "Women"))
  
  col_names = paste(demo_filled[value_cols], gender_row[value_cols], sep = "__")
  
  body = raw[(header_row + 2):nrow(raw), c(state_col, value_cols)]
  names(body) = c("State or jurisdiction", col_names)
  
  body = body %>%
    mutate(
      `State or jurisdiction` = clean_text(`State or jurisdiction`),
      across(
        -`State or jurisdiction`,
        ~ parse_number(as.character(.x))
      )
    ) %>%
    filter(
      !is.na(`State or jurisdiction`),
      `State or jurisdiction` != "",
      if_any(-`State or jurisdiction`, ~ !is.na(.x))
    ) %>%
    filter(
      !str_detect(`State or jurisdiction`, "^NOTE:"),
      !str_detect(`State or jurisdiction`, "^SOURCE:"),
      !str_detect(`State or jurisdiction`, "^Table "),
      !str_detect(`State or jurisdiction`, "^National Center")
    ) %>%
    mutate(Year = year) %>%
    select(Year, `State or jurisdiction`, everything())
  
  # Convert to long and back to wide so every year is ordered Men, Women
  body_long = body %>%
    pivot_longer(
      cols = -c(Year, `State or jurisdiction`),
      names_to = c("Race/ethnicity", "Gender"),
      names_sep = "__",
      values_to = "Enrollment"
    )
  
  body_wide = body_long %>%
    mutate(
      Gender = factor(Gender, levels = c("Men", "Women")),
      `Race/ethnicity` = factor(
        `Race/ethnicity`,
        levels = c(
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
    ) %>%
    arrange(Year, `State or jurisdiction`, `Race/ethnicity`, Gender) %>%
    pivot_wider(
      names_from = c(`Race/ethnicity`, Gender),
      values_from = Enrollment,
      names_glue = "{`Race/ethnicity`} {Gender}"
    )
  
  body_wide
}

combined_enrollment = map_dfr(files, read_enrollment_file)

desired_cols = c(
  "Year",
  "State or jurisdiction",
  "All students Men",
  "All students Women",
  "American Indian or Alaska Native Men",
  "American Indian or Alaska Native Women",
  "Asian Men",
  "Asian Women",
  "Black or African American Men",
  "Black or African American Women",
  "Hispanic or Latino Men",
  "Hispanic or Latino Women",
  "Native Hawaiian or Other Pacific Islander Men",
  "Native Hawaiian or Other Pacific Islander Women",
  "White Men",
  "White Women",
  "Two or more races Men",
  "Two or more races Women",
  "Race/ethnicity unknown Men",
  "Race/ethnicity unknown Women",
  "Nonresident Men",
  "Nonresident Women"
)

combined_enrollment = combined_enrollment %>%
  select(any_of(desired_cols), everything()) %>%
  arrange(Year, `State or jurisdiction`)

write_csv(
  combined_enrollment,
  file.path(data_dir, "enrollment_by_demo_2018_2024_combined.csv")
)