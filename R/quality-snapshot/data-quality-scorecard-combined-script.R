# ============================================================
# COMBINED CSV DATA QUALITY SCORECARD - KPI STYLE PNG
#
# Files expected:
#   awards_by_demo_2018_2024_combined*.csv
#   enrollment_by_demo_2018_2023_combined*.csv
#   enrollment_by_level_2019_2024_combined*.csv
#   financial_aid_2018_2024_combined*.csv
#   graduation_rates_2018_2024_combined*.csv
#   retention_undergrad_2018_2024_combined*.csv
#
# Output only:
#   ~/Desktop/Project/reporting-sys/output/data_quality_scorecard.png
#
# Required packages:
# install.packages(c(
#   "readr", "dplyr", "purrr", "stringr",
#   "tidyr", "tibble", "ggplot2"
# ))
# ============================================================

library(readr)
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

data_root = file.path(
  project_root,
  "data",
  "combined_data"
)

output_dir = file.path(project_root, "output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

png_path = file.path(output_dir, "data_quality_scorecard_combined.png")

# ------------------------------------------------------------
# 2. Locate the six combined CSV files
#
# Using stems allows filenames such as:
#   awards_by_demo_2018_2024_combined.csv
#   awards_by_demo_2018_2024_combined(1).csv
# ------------------------------------------------------------

file_stems = c(
  awards_by_demo = "awards_by_demo_2018_2024_combined",
  enrollment_by_demo = "enrollment_by_demo_2018_2023_combined",
  enrollment_by_level = "enrollment_by_level_2019_2024_combined",
  financial_aid = "financial_aid_2018_2024_combined",
  graduation_rates = "graduation_rates_2018_2024_combined",
  retention_undergrad = "retention_undergrad_2018_2024_combined"
)

find_combined_file = function(file_stem) {
  
  file_pattern = paste0(
    "^",
    file_stem,
    ".*\\.csv$"
  )
  
  matches = list.files(
    path = data_root,
    pattern = file_pattern,
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )
  
  if (length(matches) == 0) {
    stop(
      paste0(
        "No file found for: ",
        file_stem,
        "\nSearched below: ",
        data_root
      )
    )
  }
  
  if (length(matches) > 1) {
    warning(
      paste0(
        "Multiple files found for ",
        file_stem,
        ". Using: ",
        matches[1]
      )
    )
  }
  
  matches[1]
}

file_paths = purrr::map_chr(
  file_stems,
  find_combined_file
)

# ------------------------------------------------------------
# 3. Read CSVs as character data
#
# Reading values as character preserves published NA and
# suppression codes for quality checks before numeric parsing.
# ------------------------------------------------------------

tables = purrr::imap(
  file_paths,
  function(file_path, dataset_name) {
    
    readr::read_csv(
      file = file_path,
      col_types = readr::cols(.default = readr::col_character()),
      na = c("", "NA", "N/A"),
      show_col_types = FALSE
    )
  }
)

# ------------------------------------------------------------
# 4. Define table keys and numeric columns
# ------------------------------------------------------------

key_columns = list(
  awards_by_demo = c(
    "Year",
    "Level of award",
    "Gender"
  ),
  enrollment_by_demo = c(
    "Year",
    "State or jurisdiction"
  ),
  enrollment_by_level = c(
    "Year",
    "Level of institution",
    "Distance education status of student"
  ),
  financial_aid = c(
    "Year",
    "Level of institution",
    "Type of aid awarded",
    "Family income level"
  ),
  graduation_rates = c(
    "Year",
    "Level of institution",
    "Control of institution",
    "Gender"
  ),
  retention_undergrad = c(
    "Year",
    "Level of institution",
    "Degree-granting status",
    "Control of institution",
    "Enrollment status"
  )
)

numeric_columns = purrr::imap(
  tables,
  function(data, dataset_name) {
    setdiff(
      names(data),
      key_columns[[dataset_name]]
    )
  }
)

# ------------------------------------------------------------
# 5. Utility functions
# ------------------------------------------------------------

as_number = function(x) {
  
  suppression_values = c(
    "",
    "NA",
    "N/A",
    "S",
    "Suppressed",
    "Withheld",
    "—",
    "--",
    "‡",
    "*"
  )
  
  suppressWarnings(
    readr::parse_number(
      as.character(x),
      na = suppression_values
    )
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

count_duplicate_records = function(data, keys) {
  sum(
    duplicated(
      data[, keys, drop = FALSE]
    )
  )
}

# ------------------------------------------------------------
# 6. Build a cell-level numeric inventory
# ------------------------------------------------------------

numeric_cells = purrr::imap_dfr(
  tables,
  function(data, dataset_name) {
    
    data |>
      select(all_of(numeric_columns[[dataset_name]])) |>
      pivot_longer(
        cols = everything(),
        names_to = "variable",
        values_to = "raw_value"
      ) |>
      mutate(
        dataset = dataset_name,
        raw_text = str_squish(coalesce(raw_value, "")),
        numeric_value = as_number(raw_value),
        is_suppression_marker =
          raw_text %in% c(
            "S",
            "Suppressed",
            "Withheld",
            "—",
            "--",
            "‡",
            "*"
          ) |
          str_detect(
            raw_text,
            regex(
              "suppressed|withheld",
              ignore_case = TRUE
            )
          )
      )
  }
)

# ------------------------------------------------------------
# 7. Volume, duplicate, missingness, and validity metrics
# ------------------------------------------------------------

total_files_processed = length(tables)

total_records_processed = tables |>
  purrr::map_int(nrow) |>
  sum()

duplicate_reporting_records_found = purrr::imap_dbl(
  tables,
  function(data, dataset_name) {
    count_duplicate_records(
      data,
      key_columns[[dataset_name]]
    )
  }
) |>
  sum()

duplicate_record_rate = ifelse(
  total_records_processed == 0,
  0,
  duplicate_reporting_records_found / total_records_processed
)

total_numeric_cells_processed = nrow(numeric_cells)

numeric_cells_coded_na = sum(
  is.na(numeric_cells$raw_value)
)

numeric_na_rate = ifelse(
  total_numeric_cells_processed == 0,
  0,
  numeric_cells_coded_na / total_numeric_cells_processed
)

graduation_rate_cells_coded_na = numeric_cells |>
  filter(dataset == "graduation_rates") |>
  summarise(total = sum(is.na(raw_value))) |>
  pull(total)

financial_aid_cells_coded_na = numeric_cells |>
  filter(dataset == "financial_aid") |>
  summarise(total = sum(is.na(raw_value))) |>
  pull(total)

explicit_suppression_marker_cells_found = sum(
  numeric_cells$is_suppression_marker,
  na.rm = TRUE
)

unexpected_nonnumeric_cells_found = numeric_cells |>
  filter(
    !is.na(raw_value),
    !is_suppression_marker,
    is.na(numeric_value)
  ) |>
  nrow()

numeric_cells_with_invalid_negative_values = sum(
  numeric_cells$numeric_value < 0,
  na.rm = TRUE
)

# ------------------------------------------------------------
# 8. Rate validity checks
#
# Graduation-rate numeric measures and retention rates should
# remain within the inclusive range 0 to 100.
# ------------------------------------------------------------

graduation_rate_values = tables$graduation_rates |>
  select(all_of(numeric_columns$graduation_rates)) |>
  unlist(use.names = FALSE) |>
  as_number()

retention_rate_values = as_number(
  tables$retention_undergrad$`Retention rate`
)

rate_cells_outside_valid_range = sum(
  graduation_rate_values < 0 |
    graduation_rate_values > 100,
  na.rm = TRUE
) +
  sum(
    retention_rate_values < 0 |
      retention_rate_values > 100,
    na.rm = TRUE
  )

# ------------------------------------------------------------
# 9. Awards-by-demographic reconciliation
#
# Natural row key:
#   Year + Level of award + Gender
#
# Check:
#   All students = Men + Women
#
# Each Year / Level of award group is counted once when any
# published race/ethnicity value fails reconciliation.
# ------------------------------------------------------------

count_awards_gender_failures = function(data) {
  
  value_columns = numeric_columns$awards_by_demo
  
  grouped_data = split(
    data,
    interaction(
      data$Year,
      data$`Level of award`,
      drop = TRUE
    )
  )
  
  failed_groups = purrr::map_lgl(
    grouped_data,
    function(group_data) {
      
      required_gender_rows = c(
        "All students",
        "Men",
        "Women"
      )
      
      if (!all(required_gender_rows %in% group_data$Gender)) {
        return(TRUE)
      }
      
      total_values = group_data |>
        filter(Gender == "All students") |>
        select(all_of(value_columns)) |>
        slice(1) |>
        unlist(use.names = FALSE) |>
        as_number()
      
      men_values = group_data |>
        filter(Gender == "Men") |>
        select(all_of(value_columns)) |>
        slice(1) |>
        unlist(use.names = FALSE) |>
        as_number()
      
      women_values = group_data |>
        filter(Gender == "Women") |>
        select(all_of(value_columns)) |>
        slice(1) |>
        unlist(use.names = FALSE) |>
        as_number()
      
      checkable_values =
        !is.na(total_values) &
        !is.na(men_values) &
        !is.na(women_values)
      
      if (!any(checkable_values)) {
        return(FALSE)
      }
      
      any(
        total_values[checkable_values] !=
          men_values[checkable_values] +
          women_values[checkable_values]
      )
    }
  )
  
  sum(failed_groups)
}

awards_groups_failing_gender_reconciliation =
  count_awards_gender_failures(
    tables$awards_by_demo
  )

# ------------------------------------------------------------
# 10. Enrollment-by-demographic reconciliation
#
# Natural row key:
#   Year + State or jurisdiction
#
# Check separately for men and women:
#   All students =
#     sum of race/ethnicity and nonresident categories
#
# Each state-year row is counted once when either gender fails.
# ------------------------------------------------------------

count_enrollment_demographic_failures = function(data) {
  
  men_component_columns = names(data)[
    str_ends(names(data), " Men") &
      names(data) != "All students Men"
  ]
  
  women_component_columns = names(data)[
    str_ends(names(data), " Women") &
      names(data) != "All students Women"
  ]
  
  failed_rows = purrr::map_lgl(
    seq_len(nrow(data)),
    function(row_number) {
      
      reported_men_total = as_number(
        data$`All students Men`[row_number]
      )
      
      reported_women_total = as_number(
        data$`All students Women`[row_number]
      )
      
      men_components = data[
        row_number,
        men_component_columns,
        drop = FALSE
      ] |>
        unlist(use.names = FALSE) |>
        as_number()
      
      women_components = data[
        row_number,
        women_component_columns,
        drop = FALSE
      ] |>
        unlist(use.names = FALSE) |>
        as_number()
      
      required_values = c(
        reported_men_total,
        reported_women_total,
        men_components,
        women_components
      )
      
      if (any(is.na(required_values))) {
        return(FALSE)
      }
      
      reported_men_total != sum(men_components) |
        reported_women_total != sum(women_components)
    }
  )
  
  sum(failed_rows)
}

enrollment_demographic_rows_failing_reconciliation =
  count_enrollment_demographic_failures(
    tables$enrollment_by_demo
  )

# ------------------------------------------------------------
# 11. Enrollment-by-level reconciliation
#
# Natural row key:
#   Year + Level of institution +
#   Distance education status of student
#
# Check:
#   All students =
#     Enrolled exclusively in distance education courses +
#     Enrolled in at least one, but not all, courses +
#     Not enrolled in any distance education courses
#
# Each Year / Level of institution group is counted once when
# any published undergraduate or graduate value fails.
# ------------------------------------------------------------

count_enrollment_level_failures = function(data) {
  
  status_column = "Distance education status of student"
  value_columns = numeric_columns$enrollment_by_level
  
  expected_statuses = c(
    "All students",
    "Enrolled exclusively in distance education courses",
    "Enrolled in at least one, but not all, distance education courses",
    "Not enrolled in any distance education courses"
  )
  
  grouped_data = split(
    data,
    interaction(
      data$Year,
      data$`Level of institution`,
      drop = TRUE
    )
  )
  
  failed_groups = purrr::map_lgl(
    grouped_data,
    function(group_data) {
      
      if (!all(expected_statuses %in% group_data[[status_column]])) {
        return(TRUE)
      }
      
      ordered_rows = group_data[
        match(
          expected_statuses,
          group_data[[status_column]]
        ),
        value_columns,
        drop = FALSE
      ]
      
      value_matrix = matrix(
        as_number(
          as.vector(
            as.matrix(ordered_rows)
          )
        ),
        nrow = length(expected_statuses),
        ncol = length(value_columns)
      )
      
      reported_total = value_matrix[1, ]
      
      calculated_total = colSums(
        value_matrix[2:4, , drop = FALSE],
        na.rm = FALSE
      )
      
      checkable_values =
        !is.na(reported_total) &
        !is.na(calculated_total)
      
      if (!any(checkable_values)) {
        return(FALSE)
      }
      
      any(
        reported_total[checkable_values] !=
          calculated_total[checkable_values]
      )
    }
  )
  
  sum(failed_groups)
}

enrollment_level_groups_failing_status_reconciliation =
  count_enrollment_level_failures(
    tables$enrollment_by_level
  )

# ------------------------------------------------------------
# 12. Financial-aid reconciliation
#
# Natural row key:
#   Year + Level of institution +
#   Type of aid awarded + Family income level
#
# Check for each institution control:
#   Net price =
#     Average cost of attendance -
#     Average grant/scholarship aid
#
# Published rounded averages are allowed a tolerance of $1.
# Each source row is counted once when any available control
# triplet fails reconciliation.
# ------------------------------------------------------------

count_financial_aid_failures = function(data) {
  
  value_triplets = list(
    c(
      "Public Average cost of attendance",
      "Public Average grant/scholarship aid",
      "Public Net price"
    ),
    c(
      "Private Nonprofit Average cost of attendance",
      "Private Nonprofit Average grant/scholarship aid",
      "Private Nonprofit Net price"
    ),
    c(
      "Private For-profit Average cost of attendance",
      "Private For-profit Average grant/scholarship aid",
      "Private For-profit Net price"
    )
  )
  
  failed_rows = purrr::map_lgl(
    seq_len(nrow(data)),
    function(row_number) {
      
      triplet_failures = purrr::map_lgl(
        value_triplets,
        function(columns) {
          
          values = data[
            row_number,
            columns,
            drop = FALSE
          ] |>
            unlist(use.names = FALSE) |>
            as_number()
          
          if (any(is.na(values))) {
            return(FALSE)
          }
          
          abs(
            values[1] -
              values[2] -
              values[3]
          ) > 1
        }
      )
      
      any(triplet_failures)
    }
  )
  
  sum(failed_rows)
}

financial_aid_rows_failing_net_price_reconciliation =
  count_financial_aid_failures(
    tables$financial_aid
  )

# ------------------------------------------------------------
# 13. Retention reconciliation
#
# Natural row key:
#   Year + Level of institution +
#   Degree-granting status +
#   Control of institution +
#   Enrollment status
#
# Check:
#   Retention rate =
#     Still enrolled / Adjusted cohort * 100
#
# Rates are compared at one decimal place.
# Rows with zero or negative cohort values are counted as
# denominator exclusions rather than reconciliation failures.
# ------------------------------------------------------------

retention_data = tables$retention_undergrad |>
  mutate(
    adjusted_cohort_numeric = as_number(`Adjusted cohort`),
    still_enrolled_numeric = as_number(`Still enrolled`),
    retention_rate_numeric = as_number(`Retention rate`)
  )

retention_rows_excluded_from_denominator = retention_data |>
  filter(
    !is.na(adjusted_cohort_numeric),
    adjusted_cohort_numeric <= 0
  ) |>
  nrow()

retention_rows_failing_rate_reconciliation = retention_data |>
  filter(
    !is.na(adjusted_cohort_numeric),
    !is.na(still_enrolled_numeric),
    !is.na(retention_rate_numeric),
    adjusted_cohort_numeric > 0
  ) |>
  mutate(
    calculated_retention_rate = round(
      100 * still_enrolled_numeric / adjusted_cohort_numeric,
      digits = 1
    ),
    reconciliation_failure =
      abs(
        calculated_retention_rate -
          retention_rate_numeric
      ) > 0.1
  ) |>
  summarise(total = sum(reconciliation_failure)) |>
  pull(total)

# ------------------------------------------------------------
# 14. KPI scorecard text
# ------------------------------------------------------------

scorecard_metrics = tibble(
  metric = c(
    "Files processed",
    "Total records processed",
    "Duplicate reporting records found",
    "Duplicate record rate",
    "Total numeric cells processed",
    "Numeric cells coded NA",
    "Numeric NA rate",
    "Graduation rate cells coded NA",
    "Financial aid cells coded NA",
    "Explicit suppression-marker cells found",
    "Unexpected nonnumeric cells found",
    "Numeric cells with invalid negative values",
    "Rate cells outside valid 0-100% range",
    "Awards groups failing gender reconciliation",
    "Enrollment-demographic rows failing reconciliation",
    "Enrollment-level groups failing status reconciliation",
    "Financial aid rows failing net-price reconciliation",
    "Retention rows excluded from denominator",
    "Retention rows failing rate reconciliation"
  ),
  value = c(
    total_files_processed,
    total_records_processed,
    duplicate_reporting_records_found,
    duplicate_record_rate,
    total_numeric_cells_processed,
    numeric_cells_coded_na,
    numeric_na_rate,
    graduation_rate_cells_coded_na,
    financial_aid_cells_coded_na,
    explicit_suppression_marker_cells_found,
    unexpected_nonnumeric_cells_found,
    numeric_cells_with_invalid_negative_values,
    rate_cells_outside_valid_range,
    awards_groups_failing_gender_reconciliation,
    enrollment_demographic_rows_failing_reconciliation,
    enrollment_level_groups_failing_status_reconciliation,
    financial_aid_rows_failing_net_price_reconciliation,
    retention_rows_excluded_from_denominator,
    retention_rows_failing_rate_reconciliation
  ),
  display_type = c(
    "count",
    "count",
    "count",
    "rate",
    "count",
    "count",
    "rate",
    "count",
    "count",
    "count",
    "count",
    "count",
    "count",
    "count",
    "count",
    "count",
    "count",
    "count",
    "count"
  )
) |>
  mutate(
    displayed_value = if_else(
      display_type == "rate",
      format_rate(value),
      format_count(value)
    ),
    display_line = paste0(
      metric,
      ": ",
      displayed_value
    ),
    display_row = rev(seq_len(n()))
  )

# Optional console preview
print(
  scorecard_metrics |>
    select(metric, displayed_value),
  n = Inf
)

# ------------------------------------------------------------
# 15. Generate PNG scorecard
# ------------------------------------------------------------

scorecard_plot = ggplot(
  scorecard_metrics,
  aes(
    x = 0,
    y = display_row,
    label = display_line
  )
) +
  geom_text(
    hjust = 0,
    size = 4.9,
    family = "sans",
    color = "#1E293B",
    lineheight = 1.1
  ) +
  annotate(
    geom = "text",
    x = 0,
    y = max(scorecard_metrics$display_row) + 2.25,
    label = "DATA QUALITY SCORECARD",
    hjust = 0,
    size = 8,
    fontface = "bold",
    color = "#0F172A"
  ) +
  annotate(
    geom = "text",
    x = 0,
    y = max(scorecard_metrics$display_row) + 1.35,
    label = "Combined NCES reporting tables validation summary",
    hjust = 0,
    size = 4.4,
    color = "#64748B"
  ) +
  annotate(
    geom = "segment",
    x = 0,
    xend = 1,
    y = max(scorecard_metrics$display_row) + 0.75,
    yend = max(scorecard_metrics$display_row) + 0.75,
    linewidth = 0.6,
    color = "#CBD5E1"
  ) +
  annotate(
    geom = "text",
    x = 0,
    y = -0.9,
    label = paste0(
      "Source directory: ",
      data_root
    ),
    hjust = 0,
    size = 3.1,
    color = "#64748B"
  ) +
  coord_cartesian(
    xlim = c(0, 1),
    ylim = c(
      -1.5,
      max(scorecard_metrics$display_row) + 3
    ),
    clip = "off"
  ) +
  theme_void() +
  theme(
    plot.background = element_rect(
      fill = "white",
      color = NA
    ),
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
  width = 14,
  height = 10.5,
  dpi = 300,
  bg = "white"
)

message("Created PNG scorecard: ", png_path)