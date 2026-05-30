library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(readr)

data_dir = "~/Desktop/Project/reporting-sys/data/retention_undergrad/"

files = list.files(
  data_dir,
  pattern = "^retention_undergrad_\\d{2}[-_]\\d{2}\\.xlsx$",
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
  str_extract(basename(path), "\\d{2}[-_]\\d{2}") %>%
    str_replace("_", "-")
}

standardize_metric = function(x) {
  clean_text(x) %>%
    str_replace_all("Adjusted cohort, fall \\d{4}", "Adjusted cohort") %>%
    str_replace_all("Still enrolled fall \\d{4}", "Still enrolled") %>%
    str_replace_all("Retention rate", "Retention rate") %>%
    str_squish()
}

clean_number = function(x) {
  x_clean = clean_text(x)
  
  case_when(
    is.na(x_clean) | x_clean == "" ~ NA_real_,
    x_clean %in% c("-", "—", "–", "‡", "†", "Ø", "---") ~ NA_real_,
    TRUE ~ parse_number(x_clean)
  )
}

read_retention_file = function(path) {
  
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
          any(row == "Full-time", na.rm = TRUE) &&
          any(row == "Part-time", na.rm = TRUE)
      }
    )
  )[1]
  
  if (is.na(header_row)) {
    stop(paste("Could not find header row in", basename(path)))
  }
  
  enrollment_status_row = raw_clean[header_row, ] %>%
    unlist(use.names = FALSE) %>%
    fill_right()
  
  metric_row = raw_clean[header_row + 1, ] %>%
    unlist(use.names = FALSE) %>%
    standardize_metric()
  
  label_col = which(str_detect(enrollment_status_row, "^Level of institution"))[1]
  
  if (is.na(label_col)) {
    label_col = 1
  }
  
  value_cols = which(
    enrollment_status_row %in% c("Full-time", "Part-time") &
      metric_row %in% c("Adjusted cohort", "Still enrolled", "Retention rate")
  )
  
  if (length(value_cols) == 0) {
    stop(paste("Could not find value columns in", basename(path)))
  }
  
  column_names = paste(
    enrollment_status_row[value_cols],
    metric_row[value_cols],
    sep = "__"
  )
  
  body = raw[(header_row + 2):nrow(raw), c(label_col, value_cols)]
  
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
    "4-year",
    "2-year",
    "Less-than-2-year"
  )
  
  degree_status_values = c(
    "Degree-granting",
    "Non-degree-granting",
    "Non-degree granting"
  )
  
  control_values = c(
    "Public",
    "Private nonprofit",
    "Private non-profit",
    "Private for-profit",
    "Private for profit"
  )
  
  current_level = NA_character_
  current_degree_status = "All institutions"
  output = list()
  
  for (i in seq_len(nrow(body))) {
    
    row = body[i, ]
    label = row$label
    
    if (label %in% level_values) {
      current_level = label
      
      if (label %in% c("4-year", "Less-than-2-year")) {
        current_degree_status = "All institutions"
      }
      
      output[[length(output) + 1]] = row %>%
        mutate(
          Year = year,
          `Level of institution` = current_level,
          `Degree-granting status` = current_degree_status,
          `Control of institution` = "All institutions"
        )
      
    } else if (label %in% degree_status_values) {
      current_degree_status = case_when(
        label == "Non-degree granting" ~ "Non-degree-granting",
        TRUE ~ label
      )
      
      output[[length(output) + 1]] = row %>%
        mutate(
          Year = year,
          `Level of institution` = current_level,
          `Degree-granting status` = current_degree_status,
          `Control of institution` = "All institutions"
        )
      
    } else if (label %in% control_values) {
      control = case_when(
        label == "Private non-profit" ~ "Private nonprofit",
        label == "Private for profit" ~ "Private for-profit",
        TRUE ~ label
      )
      
      output[[length(output) + 1]] = row %>%
        mutate(
          Year = year,
          `Level of institution` = current_level,
          `Degree-granting status` = current_degree_status,
          `Control of institution` = control
        )
    }
  }
  
  bind_rows(output) %>%
    select(
      Year,
      row_order,
      `Level of institution`,
      `Degree-granting status`,
      `Control of institution`,
      all_of(column_names)
    ) %>%
    pivot_longer(
      cols = all_of(column_names),
      names_to = c("Enrollment status", "Metric"),
      names_sep = "__",
      values_to = "Value"
    ) %>%
    pivot_wider(
      names_from = Metric,
      values_from = Value
    ) %>%
    select(
      Year,
      row_order,
      `Level of institution`,
      `Degree-granting status`,
      `Control of institution`,
      `Enrollment status`,
      `Adjusted cohort`,
      `Still enrolled`,
      `Retention rate`
    )
}

combined_retention_undergrad = map_dfr(files, read_retention_file)

combined_retention_undergrad = combined_retention_undergrad %>%
  mutate(
    `Level of institution` = factor(
      `Level of institution`,
      levels = c("4-year", "2-year", "Less-than-2-year")
    ),
    `Degree-granting status` = factor(
      `Degree-granting status`,
      levels = c("All institutions", "Degree-granting", "Non-degree-granting")
    ),
    `Control of institution` = factor(
      `Control of institution`,
      levels = c("All institutions", "Public", "Private nonprofit", "Private for-profit")
    ),
    `Enrollment status` = factor(
      `Enrollment status`,
      levels = c("Full-time", "Part-time")
    )
  ) %>%
  arrange(
    Year,
    row_order,
    `Enrollment status`
  ) %>%
  mutate(
    `Level of institution` = as.character(`Level of institution`),
    `Degree-granting status` = as.character(`Degree-granting status`),
    `Control of institution` = as.character(`Control of institution`),
    `Enrollment status` = as.character(`Enrollment status`)
  ) %>%
  select(-row_order)

write_csv(
  combined_retention_undergrad,
  file.path(data_dir, "retention_undergrad_2018_2024_combined.csv")
)