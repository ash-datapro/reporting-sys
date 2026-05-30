library(readxl)
library(dplyr)
library(stringr)
library(purrr)
library(readr)

data_dir = "~/Desktop/Project/reporting-sys/data/raw_data/graduation_rates/"

files = list.files(
  data_dir,
  pattern = "^graduation_rates_\\d{2}-\\d{2}\\.xlsx$",
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
    str_replace_all("U\\.S\\. nonresident|U\\.S\\. Nonresident|Nonresident1", "Nonresident") %>%
    str_replace_all("Race/ ethnicity unknown", "Race/ethnicity unknown") %>%
    str_squish()
}

clean_rate_value = function(x) {
  x_clean = clean_text(x)
  
  out = rep(NA_real_, length(x_clean))
  
  valid = !is.na(x_clean) &
    x_clean != "" &
    !x_clean %in% c("-", "—", "–", "‡", "†", "Ø", "---")
  
  out[valid] = parse_number(x_clean[valid])
  
  out
}

get_year_from_file = function(path) {
  str_extract(basename(path), "\\d{2}-\\d{2}")
}

standardize_gender = function(x) {
  case_when(
    x %in% c("Male", "Men") ~ "Men",
    x %in% c("Female", "Women") ~ "Women",
    x == "Total" ~ "Total",
    TRUE ~ x
  )
}

standardize_control = function(x) {
  case_when(
    x == "Private non-profit" ~ "Private nonprofit",
    x == "Private for profit" ~ "Private for-profit",
    TRUE ~ x
  )
}

is_section_header = function(label, has_values) {
  !has_values &&
    str_detect(
      label,
      regex(
        "institution|institutions|degree-seekers|bachelor|cohort year",
        ignore_case = TRUE
      )
    )
}

read_graduation_rates_file = function(path) {
  
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
        any(str_detect(row, "^Level and control of institution"), na.rm = TRUE) &&
          any(row == "All students", na.rm = TRUE) &&
          any(row == "Asian", na.rm = TRUE)
      }
    )
  )[1]
  
  if (is.na(header_row)) {
    stop(paste("Could not find header row in", basename(path)))
  }
  
  headers = raw_clean[header_row, ] %>%
    unlist(use.names = FALSE) %>%
    clean_demo()
  
  label_col = which(str_detect(headers, "^Level and control of institution"))[1]
  
  if (is.na(label_col)) {
    label_col = 1
  }
  
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
  
  if (length(demo_cols) == 0) {
    stop(paste("Could not find demographic columns in", basename(path)))
  }
  
  demo_headers = headers[demo_cols]
  
  body = raw[(header_row + 1):nrow(raw), c(label_col, demo_cols)]
  
  names(body) = c("label", demo_headers)
  
  body = body %>%
    mutate(
      label = clean_text(label),
      across(all_of(demo_headers), clean_rate_value),
      row_order = row_number()
    ) %>%
    filter(
      !is.na(label),
      label != "",
      !str_detect(label, "^NOTE:"),
      !str_detect(label, "^SOURCE:"),
      !str_detect(label, "^Table "),
      !str_detect(label, "^National Center")
    )
  
  control_values = c(
    "Total",
    "Public",
    "Private nonprofit",
    "Private non-profit",
    "Private for-profit",
    "Private for profit"
  )
  
  gender_values = c("Total", "Men", "Women", "Male", "Female")
  
  current_level = NA_character_
  current_control = NA_character_
  output = list()
  
  for (i in seq_len(nrow(body))) {
    
    row = body[i, ]
    label = row$label
    
    has_values = any(!is.na(as.numeric(row[demo_headers])))
    
    if (is_section_header(label, has_values)) {
      current_level = label
      current_control = NA_character_
      next
    }
    
    if (!has_values) {
      next
    }
    
    if (label %in% control_values) {
      current_control = standardize_control(label)
      gender = "Total"
    } else if (label %in% gender_values) {
      gender = standardize_gender(label)
      
      if (is.na(current_control) || current_control == "") {
        current_control = "Total"
      }
    } else {
      next
    }
    
    if (is.na(current_level) || current_level == "") {
      stop(
        paste(
          "Data row found before level header in",
          basename(path),
          "at body row",
          row$row_order,
          "label:",
          label
        )
      )
    }
    
    output[[length(output) + 1]] = row %>%
      mutate(
        Year = year,
        `Level of institution` = current_level,
        `Control of institution` = current_control,
        Gender = gender
      ) %>%
      select(
        Year,
        row_order,
        `Level of institution`,
        `Control of institution`,
        Gender,
        all_of(demo_headers)
      )
  }
  
  bind_rows(output)
}

combined_graduation_rates = map_dfr(files, read_graduation_rates_file)

desired_cols = c(
  "Year",
  "row_order",
  "Level of institution",
  "Control of institution",
  "Gender",
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

combined_graduation_rates = combined_graduation_rates %>%
  select(any_of(desired_cols), everything()) %>%
  arrange(Year, row_order)

duplicate_keys = combined_graduation_rates %>%
  count(
    Year,
    `Level of institution`,
    `Control of institution`,
    Gender,
    name = "n"
  ) %>%
  filter(n > 1)

if (nrow(duplicate_keys) > 0) {
  print(duplicate_keys)
  stop("Duplicate natural keys found. Check level/control/gender parsing.")
}

combined_graduation_rates = combined_graduation_rates %>%
  select(-row_order)

write_csv(
  combined_graduation_rates,
  file.path(data_dir, "graduation_rates_2018_2024_combined.csv")
)