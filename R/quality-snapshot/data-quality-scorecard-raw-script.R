# ============================================================
# NCES RAW DATA QUALITY SCORECARD - KPI STYLE PNG
#
# Output only:
#   ~/Desktop/Project/reporting-sys/output/data_quality_scorecard.png
#
# No CSV or intermediate audit data files are written.
#
# Required packages:
# install.packages(c("readxl", "dplyr", "purrr", "stringr",
#                    "tidyr", "tibble", "ggplot2"))
# ============================================================

library(readxl)
library(dplyr)
library(purrr)
library(stringr)
library(tidyr)
library(tibble)
library(ggplot2)

# ------------------------------------------------------------
# 1. File locations
# ------------------------------------------------------------

project_root = "~/Desktop/Project/reporting-sys"
raw_root = file.path(project_root, "data", "raw_data")
output_dir = file.path(project_root, "output")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

png_path = file.path(output_dir, "data_quality_scorecard.png")

# ------------------------------------------------------------
# 2. Expected workbook inventory
#
# This matches the folders and years shown in your example.
# ------------------------------------------------------------

expected_inventory = tribble(
  ~dataset,              ~year,
  "awards_by_demo",      "18-19",
  "awards_by_demo",      "19-20",
  "awards_by_demo",      "20-21",
  "awards_by_demo",      "21-22",
  "awards_by_demo",      "22-23",
  "awards_by_demo",      "23-24",
  
  "enrollment_by_demo",  "18-19",
  "enrollment_by_demo",  "19-20",
  "enrollment_by_demo",  "20-21",
  "enrollment_by_demo",  "21-22",
  "enrollment_by_demo",  "22-23",
  
  "enrollment_by_level", "19-20",
  "enrollment_by_level", "20-21",
  "enrollment_by_level", "21-22",
  "enrollment_by_level", "22-23",
  "enrollment_by_level", "23-24",
  
  "financial_aid",       "18-19",
  "financial_aid",       "19-20",
  "financial_aid",       "20-21",
  "financial_aid",       "21-22",
  "financial_aid",       "22-23",
  "financial_aid",       "23-24",
  
  "graduation_rates",    "18-19",
  "graduation_rates",    "19-20",
  "graduation_rates",    "20-21",
  "graduation_rates",    "21-22",
  "graduation_rates",    "22-23",
  "graduation_rates",    "23-24",
  
  "retention_undergrad", "18-19",
  "retention_undergrad", "19-20",
  "retention_undergrad", "20-21",
  "retention_undergrad", "21-22",
  "retention_undergrad", "22-23",
  "retention_undergrad", "23-24"
)

# ------------------------------------------------------------
# 3. Find actual Excel workbooks
#
# This normalizes filenames such as:
# retention_undergrad_21_22.xlsx -> reporting year 21-22
# ------------------------------------------------------------

excel_paths = list.files(
  raw_root,
  pattern = "\\.xlsx$",
  full.names = TRUE,
  recursive = TRUE,
  ignore.case = TRUE
)

actual_files = tibble(path = excel_paths) |>
  mutate(
    filename = basename(path),
    dataset = basename(dirname(path)),
    year = str_extract(filename, "\\d{2}[-_]\\d{2}"),
    year = str_replace_all(year, "_", "-")
  ) |>
  filter(
    dataset %in% expected_inventory$dataset,
    !is.na(year)
  )

duplicate_dataset_year_files = actual_files |>
  count(dataset, year, name = "file_count") |>
  filter(file_count > 1) |>
  summarise(
    duplicate_count = sum(file_count - 1),
    .groups = "drop"
  ) |>
  pull(duplicate_count)

if (length(duplicate_dataset_year_files) == 0) {
  duplicate_dataset_year_files = 0
}

canonical_files = actual_files |>
  arrange(dataset, year, filename) |>
  distinct(dataset, year, .keep_all = TRUE)

missing_expected_workbooks = expected_inventory |>
  anti_join(
    canonical_files |> select(dataset, year),
    by = c("dataset", "year")
  ) |>
  nrow()

# ------------------------------------------------------------
# 4. General helper functions
# ------------------------------------------------------------

clean_text = function(x) {
  x |>
    as.character() |>
    str_replace_all("\u00a0", " ") |>
    str_replace_all("[\r\n]+", " ") |>
    str_squish() |>
    na_if("")
}

to_numeric = function(x) {
  cleaned = x |>
    clean_text() |>
    str_replace_all(",", "") |>
    str_replace_all("\\$", "") |>
    str_replace_all("%", "") |>
    str_replace_all("−", "-")
  
  suppressWarnings(as.numeric(cleaned))
}

safe_read_excel = function(path) {
  tryCatch(
    read_excel(
      path,
      sheet = 1,
      col_names = FALSE,
      .name_repair = "unique_quiet"
    ),
    error = function(e) NULL
  )
}

format_count = function(x) {
  format(
    round(x),
    big.mark = ",",
    scientific = FALSE,
    trim = TRUE
  )
}

format_rate = function(x) {
  paste0(
    format(
      round(100 * x, 1),
      nsmall = 1,
      trim = TRUE
    ),
    "%"
  )
}

# ------------------------------------------------------------
# 5. Extract the usable published-data area from one workbook
#
# The attached files contain:
# - title rows
# - multi-row headers
# - blank spacer rows
# - published numeric data rows
#
# This function excludes title/header/spacer rows and identifies
# only rows containing published numeric values.
# ------------------------------------------------------------

extract_data_area = function(raw_data) {
  
  if (is.null(raw_data) || nrow(raw_data) == 0 || ncol(raw_data) == 0) {
    return(NULL)
  }
  
  text_data = raw_data |>
    mutate(across(everything(), clean_text))
  
  numeric_data = text_data |>
    mutate(across(everything(), to_numeric))
  
  text_matrix = as.matrix(text_data)
  numeric_matrix = as.matrix(numeric_data)
  
  row_labels = text_matrix[, 1] |>
    clean_text() |>
    str_to_lower()
  
  candidate_columns = if (ncol(text_matrix) >= 3) {
    3:ncol(text_matrix)
  } else {
    seq_len(ncol(text_matrix))
  }
  
  numeric_count_by_row = rowSums(
    !is.na(numeric_matrix[, candidate_columns, drop = FALSE])
  )
  
  candidate_data_rows = which(numeric_count_by_row >= 2)
  
  if (length(candidate_data_rows) == 0) {
    return(NULL)
  }
  
  first_data_row = min(candidate_data_rows)
  
  footer_rows = which(
    seq_len(nrow(text_matrix)) > first_data_row &
      str_detect(
        coalesce(row_labels, ""),
        "^(note|notes|source|sources|definitions?|footnote)"
      )
  )
  
  last_data_row = if (length(footer_rows) > 0) {
    min(footer_rows) - 1
  } else {
    nrow(text_matrix)
  }
  
  body_rows = seq.int(first_data_row, last_data_row)
  
  data_rows = body_rows[
    numeric_count_by_row[body_rows] >= 2
  ]
  
  numeric_columns = candidate_columns[
    colSums(
      !is.na(numeric_matrix[data_rows, candidate_columns, drop = FALSE])
    ) > 0
  ]
  
  if (length(data_rows) == 0 || length(numeric_columns) == 0) {
    return(NULL)
  }
  
  list(
    text = text_matrix,
    numeric = numeric_matrix,
    row_labels = row_labels,
    data_rows = data_rows,
    numeric_columns = numeric_columns
  )
}

get_numeric_values = function(area) {
  area$numeric[
    area$data_rows,
    area$numeric_columns,
    drop = FALSE
  ]
}

get_text_values = function(area) {
  area$text[
    area$data_rows,
    area$numeric_columns,
    drop = FALSE
  ]
}

# ------------------------------------------------------------
# 6. Read canonical workbooks into memory
# ------------------------------------------------------------

workbooks = canonical_files |>
  mutate(
    raw = purrr::map(path, safe_read_excel),
    readable = purrr::map_lgl(raw, ~ !is.null(.x)),
    area = purrr::map(raw, extract_data_area)
  )

usable_workbooks = workbooks |>
  filter(!purrr::map_lgl(area, is.null))

unreadable_workbooks = sum(!workbooks$readable)

# ------------------------------------------------------------
# 7. General KPI metrics
# ------------------------------------------------------------

total_published_data_cells_processed = usable_workbooks |>
  pull(area) |>
  purrr::map_dbl(function(area) {
    length(get_text_values(area))
  }) |>
  sum()

total_numeric_values_found = usable_workbooks |>
  pull(area) |>
  purrr::map_dbl(function(area) {
    sum(!is.na(get_numeric_values(area)))
  }) |>
  sum()

numeric_data_cells_missing = usable_workbooks |>
  pull(area) |>
  purrr::map_dbl(function(area) {
    
    text_values = get_text_values(area)
    numeric_values = get_numeric_values(area)
    
    sum(
      is.na(numeric_values) &
        is.na(text_values)
    )
  }) |>
  sum()

missing_numeric_cell_rate = ifelse(
  total_published_data_cells_processed == 0,
  0,
  numeric_data_cells_missing / total_published_data_cells_processed
)

duplicate_workbook_rate = ifelse(
  nrow(actual_files) == 0,
  0,
  duplicate_dataset_year_files / nrow(actual_files)
)

missing_workbook_rate = ifelse(
  nrow(expected_inventory) == 0,
  0,
  missing_expected_workbooks / nrow(expected_inventory)
)

# ------------------------------------------------------------
# 8. Suppression or withheld-value checks
#
# Add additional symbols here when your source uses another
# published suppression notation.
# ------------------------------------------------------------

suppression_markers = c(
  "S",
  "Suppressed",
  "Withheld",
  "‡",
  "—",
  "--"
)

suppressed_or_withheld_cells = usable_workbooks |>
  pull(area) |>
  purrr::map_dbl(function(area) {
    
    text_values = as.vector(get_text_values(area))
    
    exact_marker = text_values %in% suppression_markers
    
    descriptive_marker = str_detect(
      coalesce(text_values, ""),
      regex("suppressed|withheld", ignore_case = TRUE)
    )
    
    sum(exact_marker | descriptive_marker, na.rm = TRUE)
  }) |>
  sum()

# ------------------------------------------------------------
# 9. Invalid value checks
# ------------------------------------------------------------

count_datasets = c(
  "awards_by_demo",
  "enrollment_by_demo",
  "enrollment_by_level"
)

cells_with_invalid_negative_counts = usable_workbooks |>
  mutate(
    invalid_count_cells = purrr::map2_dbl(
      area,
      dataset,
      function(area, dataset_name) {
        
        if (!dataset_name %in% count_datasets) {
          return(0)
        }
        
        numeric_values = get_numeric_values(area)
        
        sum(numeric_values < 0, na.rm = TRUE)
      }
    )
  ) |>
  summarise(total = sum(invalid_count_cells)) |>
  pull(total)

rate_cells_outside_valid_range = usable_workbooks |>
  mutate(
    invalid_rate_cells = purrr::map2_dbl(
      area,
      dataset,
      function(area, dataset_name) {
        
        numeric_matrix = area$numeric
        data_rows = area$data_rows
        
        if (dataset_name == "graduation_rates") {
          
          values = numeric_matrix[
            data_rows,
            area$numeric_columns,
            drop = FALSE
          ]
          
          return(
            sum(values < 0 | values > 100, na.rm = TRUE)
          )
        }
        
        if (dataset_name == "retention_undergrad") {
          
          rate_columns = intersect(
            c(5, 9),
            seq_len(ncol(numeric_matrix))
          )
          
          if (length(rate_columns) == 0) {
            return(0)
          }
          
          values = numeric_matrix[
            data_rows,
            rate_columns,
            drop = FALSE
          ]
          
          return(
            sum(values < 0 | values > 100, na.rm = TRUE)
          )
        }
        
        0
      }
    )
  ) |>
  summarise(total = sum(invalid_rate_cells)) |>
  pull(total)

# ------------------------------------------------------------
# 10. Awards reconciliation
#
# Validates:
#   Total/category row = Men row + Women row
#
# The NCES awards workbook may contain blank spacer rows,
# including between Total awards and Men/Women. This function
# uses the ordered numeric data rows rather than adjacent
# worksheet row numbers.
# ------------------------------------------------------------

count_awards_reconciliation_failures = function(area) {
  
  if (is.null(area)) {
    return(0)
  }
  
  data_rows = area$data_rows
  data_labels = area$row_labels[data_rows] |>
    coalesce("") |>
    str_to_lower()
  
  numeric_matrix = area$numeric
  comparison_columns = area$numeric_columns
  
  if (length(data_rows) < 3 || length(comparison_columns) == 0) {
    return(0)
  }
  
  candidate_positions = seq_len(length(data_rows) - 2)
  
  candidate_positions = candidate_positions[
    data_labels[candidate_positions + 1] == "men" &
      data_labels[candidate_positions + 2] == "women"
  ]
  
  if (length(candidate_positions) == 0) {
    return(0)
  }
  
  failures = purrr::map_lgl(
    candidate_positions,
    function(parent_position) {
      
      parent_row = data_rows[parent_position]
      men_row = data_rows[parent_position + 1]
      women_row = data_rows[parent_position + 2]
      
      total_values = numeric_matrix[parent_row, comparison_columns]
      men_values = numeric_matrix[men_row, comparison_columns]
      women_values = numeric_matrix[women_row, comparison_columns]
      
      usable = complete.cases(
        total_values,
        men_values,
        women_values
      )
      
      if (!any(usable)) {
        return(FALSE)
      }
      
      any(
        abs(
          total_values[usable] -
            men_values[usable] -
            women_values[usable]
        ) > 0
      )
    }
  )
  
  sum(failures)
}

awards_rows_failing_gender_reconciliation = usable_workbooks |>
  filter(dataset == "awards_by_demo") |>
  pull(area) |>
  purrr::map_dbl(count_awards_reconciliation_failures) |>
  sum()

# ------------------------------------------------------------
# 11. Enrollment-by-level reconciliation
#
# Validates:
#   All students =
#     Enrolled exclusively in distance education courses +
#     Enrolled in at least one, but not all, distance education courses +
#     Not enrolled in any distance education courses
# ------------------------------------------------------------

count_enrollment_level_reconciliation_failures = function(area) {
  
  if (is.null(area)) {
    return(0)
  }
  
  data_rows = area$data_rows
  data_labels = area$row_labels[data_rows] |>
    coalesce("") |>
    str_to_lower()
  
  numeric_matrix = area$numeric
  comparison_columns = area$numeric_columns
  
  if (length(data_rows) < 4 || length(comparison_columns) == 0) {
    return(0)
  }
  
  candidate_positions = seq_len(length(data_rows) - 3)
  
  candidate_positions = candidate_positions[
    str_detect(data_labels[candidate_positions], "^all students$") &
      str_detect(data_labels[candidate_positions + 1], "^enrolled exclusively") &
      str_detect(data_labels[candidate_positions + 2], "^enrolled in at least one") &
      str_detect(data_labels[candidate_positions + 3], "^not enrolled in any")
  ]
  
  if (length(candidate_positions) == 0) {
    return(0)
  }
  
  failures = purrr::map_lgl(
    candidate_positions,
    function(parent_position) {
      
      total_row = data_rows[parent_position]
      exclusively_row = data_rows[parent_position + 1]
      partially_row = data_rows[parent_position + 2]
      none_row = data_rows[parent_position + 3]
      
      total_values = numeric_matrix[total_row, comparison_columns]
      
      status_values =
        numeric_matrix[exclusively_row, comparison_columns] +
        numeric_matrix[partially_row, comparison_columns] +
        numeric_matrix[none_row, comparison_columns]
      
      usable = complete.cases(total_values, status_values)
      
      if (!any(usable)) {
        return(FALSE)
      }
      
      any(
        abs(total_values[usable] - status_values[usable]) > 0
      )
    }
  )
  
  sum(failures)
}

enrollment_rows_failing_distance_status_reconciliation = usable_workbooks |>
  filter(dataset == "enrollment_by_level") |>
  pull(area) |>
  purrr::map_dbl(count_enrollment_level_reconciliation_failures) |>
  sum()

# ------------------------------------------------------------
# 12. Financial aid reconciliation
#
# Validates each complete institution-type triplet:
#   Net price = Average cost of attendance -
#               Average grant/scholarship aid
#
# A tolerance of 1 is used because published averages can be
# affected by rounding.
# ------------------------------------------------------------

count_financial_aid_reconciliation_failures = function(area) {
  
  if (is.null(area)) {
    return(0)
  }
  
  numeric_matrix = area$numeric
  data_rows = area$data_rows
  
  value_triplets = list(
    c(3, 4, 5),
    c(7, 8, 9),
    c(11, 12, 13)
  )
  
  value_triplets = purrr::keep(
    value_triplets,
    function(columns) {
      all(columns <= ncol(numeric_matrix))
    }
  )
  
  if (length(value_triplets) == 0) {
    return(0)
  }
  
  purrr::map_dbl(
    value_triplets,
    function(columns) {
      
      cost = numeric_matrix[data_rows, columns[1]]
      aid = numeric_matrix[data_rows, columns[2]]
      reported_net_price = numeric_matrix[data_rows, columns[3]]
      
      usable = complete.cases(
        cost,
        aid,
        reported_net_price
      )
      
      if (!any(usable)) {
        return(0)
      }
      
      calculated_net_price = cost[usable] - aid[usable]
      
      sum(
        abs(calculated_net_price - reported_net_price[usable]) > 1
      )
    }
  ) |>
    sum()
}

financial_aid_rows_failing_net_price_reconciliation = usable_workbooks |>
  filter(dataset == "financial_aid") |>
  pull(area) |>
  purrr::map_dbl(count_financial_aid_reconciliation_failures) |>
  sum()

# ------------------------------------------------------------
# 13. Retention reconciliation
#
# Validates:
#   Retention rate =
#     Still enrolled / Adjusted cohort * 100
#
# The reported NCES rate is rounded to one decimal place.
# ------------------------------------------------------------

count_retention_reconciliation_failures = function(area) {
  
  if (is.null(area)) {
    return(0)
  }
  
  numeric_matrix = area$numeric
  data_rows = area$data_rows
  
  value_triplets = list(
    c(3, 4, 5),
    c(7, 8, 9)
  )
  
  value_triplets = purrr::keep(
    value_triplets,
    function(columns) {
      all(columns <= ncol(numeric_matrix))
    }
  )
  
  if (length(value_triplets) == 0) {
    return(0)
  }
  
  purrr::map_dbl(
    value_triplets,
    function(columns) {
      
      adjusted_cohort = numeric_matrix[data_rows, columns[1]]
      still_enrolled = numeric_matrix[data_rows, columns[2]]
      reported_rate = numeric_matrix[data_rows, columns[3]]
      
      usable = complete.cases(
        adjusted_cohort,
        still_enrolled,
        reported_rate
      ) &
        adjusted_cohort > 0
      
      if (!any(usable)) {
        return(0)
      }
      
      calculated_rate = round(
        100 * still_enrolled[usable] / adjusted_cohort[usable],
        digits = 1
      )
      
      sum(
        abs(calculated_rate - reported_rate[usable]) > 0.1
      )
    }
  ) |>
    sum()
}

retention_rows_failing_rate_reconciliation = usable_workbooks |>
  filter(dataset == "retention_undergrad") |>
  pull(area) |>
  purrr::map_dbl(count_retention_reconciliation_failures) |>
  sum()

# ------------------------------------------------------------
# 14. Construct KPI scorecard content
# ------------------------------------------------------------

scorecard_metrics = tibble(
  metric = c(
    "Total published data cells processed",
    "Total numeric values found",
    "Duplicate dataset-year workbooks found",
    "Duplicate workbook rate",
    "Expected workbooks missing",
    "Missing workbook rate",
    "Unreadable workbooks found",
    "Numeric data cells missing",
    "Missing numeric cell rate",
    "Suppressed or withheld cells found",
    "Cells with invalid negative counts",
    "Rate cells outside valid 0-100% range",
    "Awards rows failing gender reconciliation",
    "Enrollment rows failing distance-status reconciliation",
    "Financial aid rows failing net-price reconciliation",
    "Retention rows failing rate reconciliation"
  ),
  displayed_value = c(
    format_count(total_published_data_cells_processed),
    format_count(total_numeric_values_found),
    format_count(duplicate_dataset_year_files),
    format_rate(duplicate_workbook_rate),
    format_count(missing_expected_workbooks),
    format_rate(missing_workbook_rate),
    format_count(unreadable_workbooks),
    format_count(numeric_data_cells_missing),
    format_rate(missing_numeric_cell_rate),
    format_count(suppressed_or_withheld_cells),
    format_count(cells_with_invalid_negative_counts),
    format_count(rate_cells_outside_valid_range),
    format_count(awards_rows_failing_gender_reconciliation),
    format_count(enrollment_rows_failing_distance_status_reconciliation),
    format_count(financial_aid_rows_failing_net_price_reconciliation),
    format_count(retention_rows_failing_rate_reconciliation)
  ),
  metric_group = c(
    "Volume",
    "Volume",
    rep("Issue", 14)
  )
) |>
  mutate(
    display_line = paste0(metric, ": ", displayed_value),
    display_row = rev(seq_len(n()))
  )

# Optional console preview before creating the PNG
print(scorecard_metrics |> select(metric, displayed_value), n = Inf)

# ------------------------------------------------------------
# 15. Generate PNG scorecard
# ------------------------------------------------------------

scorecard_plot = ggplot(
  scorecard_metrics,
  aes(
    x = 0,
    y = display_row,
    label = display_line,
    color = metric_group
  )
) +
  geom_text(
    hjust = 0,
    size = 5.0,
    family = "sans",
    lineheight = 1.1
  ) +
  scale_color_manual(
    values = c(
      "Volume" = "#0F172A",
      "Issue" = "#334155"
    ),
    guide = "none"
  ) +
  annotate(
    geom = "text",
    x = 0,
    y = max(scorecard_metrics$display_row) + 2.2,
    label = "RAW DATA QUALITY SCORECARD",
    hjust = 0,
    size = 8,
    fontface = "bold",
    color = "#0F172A"
  ) +
  annotate(
    geom = "text",
    x = 0,
    y = max(scorecard_metrics$display_row) + 1.3,
    label = "Published NCES workbook validation summary",
    hjust = 0,
    size = 4.4,
    color = "#64748B"
  ) +
  annotate(
    geom = "segment",
    x = 0,
    xend = 1,
    y = max(scorecard_metrics$display_row) + 0.7,
    yend = max(scorecard_metrics$display_row) + 0.7,
    linewidth = 0.6,
    color = "#CBD5E1"
  ) +
  annotate(
    geom = "text",
    x = 0,
    y = -0.9,
    label = paste0("Source directory: ", raw_root),
    hjust = 0,
    size = 3.2,
    color = "#64748B"
  ) +
  coord_cartesian(
    xlim = c(0, 1),
    ylim = c(-1.5, max(scorecard_metrics$display_row) + 2.9),
    clip = "off"
  ) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    plot.margin = margin(
      t = 35,
      r = 45,
      b = 35,
      l = 45
    )
  )

ggsave(
  filename = png_path,
  plot = scorecard_plot,
  width = 13,
  height = 9.5,
  dpi = 300,
  bg = "white"
)

message("Created PNG scorecard: ", png_path)