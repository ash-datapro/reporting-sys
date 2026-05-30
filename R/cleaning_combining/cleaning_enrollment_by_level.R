library(readxl)
library(dplyr)
library(stringr)
library(purrr)
library(readr)

data_dir = "~/Desktop/Project/reporting-sys/data/raw_data/enrollment_by_level/"

files = list.files(
  data_dir,
  pattern = "^enrollment_by_level_\\d{2}-\\d{2}\\.xlsx$",
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

fill_right = function(x) {
  x = clean_text(x)
  
  for (i in seq_along(x)) {
    if ((is.na(x[i]) || x[i] == "") && i > 1) {
      x[i] = x[i - 1]
    }
  }
  
  x
}

get_year_from_file = function(path) {
  str_extract(basename(path), "\\d{2}-\\d{2}")
}

clean_number = function(x) {
  x_clean = clean_text(x)
  
  case_when(
    is.na(x_clean) | x_clean == "" ~ NA_real_,
    x_clean %in% c("-", "—", "–", "‡", "†", "Ø", "---") ~ NA_real_,
    TRUE ~ parse_number(x_clean)
  )
}

read_enrollment_level_file = function(path) {
  
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
        any(str_detect(row, "^Level of institution"), na.rm = TRUE) &&
          any(row == "Total", na.rm = TRUE) &&
          any(row == "Public", na.rm = TRUE)
      }
    )
  )[1]
  
  if (is.na(header_row)) {
    stop(paste("Could not find header row in", basename(path)))
  }
  
  sector_row = raw_clean[header_row, ] %>%
    unlist(use.names = FALSE) %>%
    fill_right()
  
  private_type_row = raw_clean[header_row + 1, ] %>%
    unlist(use.names = FALSE) %>%
    fill_right()
  
  student_level_row = raw_clean[header_row + 2, ] %>%
    unlist(use.names = FALSE) %>%
    clean_text()
  
  label_col = which(str_detect(sector_row, "^Level of institution"))[1]
  
  if (is.na(label_col)) {
    label_col = 1
  }
  
  value_cols = which(student_level_row %in% c("Undergraduate", "Graduate"))
  
  if (length(value_cols) == 0) {
    stop(paste("Could not find Undergraduate/Graduate columns in", basename(path)))
  }
  
  sector_names = sector_row[value_cols]
  private_type_names = private_type_row[value_cols]
  student_level_names = student_level_row[value_cols]
  
  sector_names = case_when(
    sector_names == "Private" & private_type_names == "Nonprofit" ~ "Private Nonprofit",
    sector_names == "Private" & private_type_names == "For-profit" ~ "Private For-profit",
    TRUE ~ sector_names
  )
  
  column_names = paste(sector_names, student_level_names)
  
  body = raw[(header_row + 3):nrow(raw), c(label_col, value_cols)]
  
  names(body) = c("label", column_names)
  
  body = body %>%
    mutate(
      label = clean_text(label),
      across(-label, clean_number),
      row_order = row_number()
    ) %>%
    filter(
      !is.na(label),
      label != "",
      !str_detect(label, "^NOTE:"),
      !str_detect(label, "^SOURCE:"),
      !str_detect(label, "^Table "),
      !str_detect(label, "^National Center")
    ) %>%
    filter(if_any(-c(label, row_order), ~ !is.na(.x)))
  
  level_values = c(
    "All students",
    "4-year",
    "2-year",
    "Less-than-2-year"
  )
  
  distance_values = c(
    "Enrolled exclusively in distance education courses",
    "Enrolled in at least one, but not all, distance education courses",
    "Not enrolled in any distance education courses"
  )
  
  current_level = NA_character_
  output = list()
  
  for (i in seq_len(nrow(body))) {
    
    row = body[i, ]
    label = row$label
    
    if (label %in% level_values) {
      current_level = label
      distance_status = "All students"
    } else if (label %in% distance_values) {
      distance_status = label
    } else {
      next
    }
    
    output[[length(output) + 1]] = row %>%
      mutate(
        Year = year,
        `Level of institution` = current_level,
        `Distance education status of student` = distance_status
      ) %>%
      select(
        Year,
        row_order,
        `Level of institution`,
        `Distance education status of student`,
        all_of(column_names)
      )
  }
  
  bind_rows(output)
}

combined_enrollment_level = map_dfr(files, read_enrollment_level_file)

desired_cols = c(
  "Year",
  "row_order",
  "Level of institution",
  "Distance education status of student",
  "Total Undergraduate",
  "Total Graduate",
  "Public Undergraduate",
  "Public Graduate",
  "Private Nonprofit Undergraduate",
  "Private Nonprofit Graduate",
  "Private For-profit Undergraduate",
  "Private For-profit Graduate"
)

combined_enrollment_level = combined_enrollment_level %>%
  select(any_of(desired_cols), everything()) %>%
  mutate(
    `Level of institution` = factor(
      `Level of institution`,
      levels = c(
        "All students",
        "4-year",
        "2-year",
        "Less-than-2-year"
      )
    ),
    `Distance education status of student` = factor(
      `Distance education status of student`,
      levels = c(
        "All students",
        "Enrolled exclusively in distance education courses",
        "Enrolled in at least one, but not all, distance education courses",
        "Not enrolled in any distance education courses"
      )
    )
  ) %>%
  arrange(
    Year,
    `Level of institution`,
    `Distance education status of student`
  ) %>%
  mutate(
    `Level of institution` = as.character(`Level of institution`),
    `Distance education status of student` = as.character(`Distance education status of student`)
  ) %>%
  select(-row_order)

write_csv(
  combined_enrollment_level,
  file.path(data_dir, "enrollment_by_level_2018_2024_combined.csv")
)