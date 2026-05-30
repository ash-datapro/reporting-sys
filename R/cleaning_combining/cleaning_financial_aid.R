library(readxl)
library(dplyr)
library(stringr)
library(purrr)
library(readr)

data_dir = "~/Desktop/Project/reporting-sys/data/raw_data/financial_aid/"

files = list.files(
  data_dir,
  pattern = "^financial_aid_\\d{2}-\\d{2}\\.xlsx$",
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

read_financial_aid_file = function(path) {
  
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
        any(str_detect(row, "^Level of institution, type of aid awarded"), na.rm = TRUE) &&
          any(str_detect(row, "^Public"), na.rm = TRUE) &&
          any(row == "Private", na.rm = TRUE)
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
  
  measure_row = raw_clean[header_row + 2, ] %>%
    unlist(use.names = FALSE) %>%
    clean_text()
  
  label_col = which(str_detect(sector_row, "^Level of institution, type of aid awarded"))[1]
  
  if (is.na(label_col)) {
    label_col = 1
  }
  
  value_cols = which(
    measure_row %in% c(
      "Average cost of attendance",
      "Average grant/ scholarship aid",
      "Average grant/scholarship aid",
      "Net price"
    )
  )
  
  if (length(value_cols) == 0) {
    stop(paste("Could not find financial aid value columns in", basename(path)))
  }
  
  sector_names = sector_row[value_cols] %>%
    str_replace_all("Public1", "Public")
  
  private_type_names = private_type_row[value_cols]
  
  measure_names = measure_row[value_cols] %>%
    str_replace_all("Average grant/ scholarship aid", "Average grant/scholarship aid")
  
  sector_names = case_when(
    sector_names == "Private" & private_type_names == "Nonprofit" ~ "Private Nonprofit",
    sector_names == "Private" & private_type_names == "For-profit" ~ "Private For-profit",
    TRUE ~ sector_names
  )
  
  column_names = paste(sector_names, measure_names)
  
  body = raw[(header_row + 3):nrow(raw), c(label_col, value_cols)]
  
  names(body) = c("label", column_names)
  
  body = body %>%
    mutate(
      label = clean_text(label),
      across(all_of(column_names), clean_number),
      row_order = row_number()
    ) %>%
    filter(
      !is.na(label),
      label != "",
      !str_detect(label, "^NOTE:"),
      !str_detect(label, "^SOURCE:"),
      !str_detect(label, "^Table "),
      !str_detect(label, "^National Center"),
      !str_detect(label, "^Ø")
    )
  
  level_values = c(
    "4-year",
    "2-year",
    "Less-than-2-year"
  )
  
  aid_values = c(
    "Students awarded any grant aid",
    "Students awarded Title IV aid"
  )
  
  income_values = c(
    "All family income levels",
    "$0-30,000",
    "$30,001-48,000",
    "$48,001-75,000",
    "$75,001-110,000",
    "$110,001 and more"
  )
  
  current_level = NA_character_
  current_aid = NA_character_
  
  output = list()
  
  for (i in seq_len(nrow(body))) {
    
    row = body[i, ]
    label = row$label
    has_values = any(!is.na(as.numeric(row[column_names])))
    
    if (label %in% level_values) {
      current_level = label
      current_aid = NA_character_
      next
    }
    
    if (label == "Students awarded any grant aid") {
      current_aid = label
      
      if (has_values) {
        output[[length(output) + 1]] = row %>%
          mutate(
            Year = year,
            `Level of institution` = current_level,
            `Type of aid awarded` = current_aid,
            `Family income level` = "All family income levels"
          ) %>%
          select(
            Year,
            row_order,
            `Level of institution`,
            `Type of aid awarded`,
            `Family income level`,
            all_of(column_names)
          )
      }
      
      next
    }
    
    if (label == "Students awarded Title IV aid") {
      current_aid = label
      next
    }
    
    if (label %in% income_values) {
      output[[length(output) + 1]] = row %>%
        mutate(
          Year = year,
          `Level of institution` = current_level,
          `Type of aid awarded` = current_aid,
          `Family income level` = label
        ) %>%
        select(
          Year,
          row_order,
          `Level of institution`,
          `Type of aid awarded`,
          `Family income level`,
          all_of(column_names)
        )
    }
  }
  
  bind_rows(output)
}

combined_financial_aid = map_dfr(files, read_financial_aid_file)

desired_cols = c(
  "Year",
  "row_order",
  "Level of institution",
  "Type of aid awarded",
  "Family income level",
  "Public Average cost of attendance",
  "Public Average grant/scholarship aid",
  "Public Net price",
  "Private Nonprofit Average cost of attendance",
  "Private Nonprofit Average grant/scholarship aid",
  "Private Nonprofit Net price",
  "Private For-profit Average cost of attendance",
  "Private For-profit Average grant/scholarship aid",
  "Private For-profit Net price"
)

combined_financial_aid = combined_financial_aid %>%
  select(any_of(desired_cols), everything()) %>%
  mutate(
    `Level of institution` = factor(
      `Level of institution`,
      levels = c("4-year", "2-year", "Less-than-2-year")
    ),
    `Type of aid awarded` = factor(
      `Type of aid awarded`,
      levels = c(
        "Students awarded any grant aid",
        "Students awarded Title IV aid"
      )
    ),
    `Family income level` = factor(
      `Family income level`,
      levels = c(
        "All family income levels",
        "$0-30,000",
        "$30,001-48,000",
        "$48,001-75,000",
        "$75,001-110,000",
        "$110,001 and more"
      )
    )
  ) %>%
  arrange(
    Year,
    `Level of institution`,
    `Type of aid awarded`,
    `Family income level`
  ) %>%
  mutate(
    `Level of institution` = as.character(`Level of institution`),
    `Type of aid awarded` = as.character(`Type of aid awarded`),
    `Family income level` = as.character(`Family income level`)
  ) %>%
  select(-row_order)

write_csv(
  combined_financial_aid,
  file.path(data_dir, "financial_aid_2018_2024_combined.csv")
)