# Install once if needed:
# install.packages(c("patchwork", "scales"))

library(tidyverse)
library(patchwork)
library(scales)

# -----------------------------
# 1. Set reporting year order
# -----------------------------

year_levels = c("18-19", "19-20", "20-21", "21-22", "22-23", "23-24")

# -----------------------------
# 2. Prepare national snapshot measures
# -----------------------------

retention = retention_undergrad |>
  filter(
    level_of_institution == "4-year",
    degree_granting_status == "All institutions",
    control_of_institution == "All institutions",
    enrollment_status == "Full-time"
  ) |>
  transmute(
    year = factor(year, levels = year_levels),
    metric = retention_rate
  ) |>
  arrange(year)

graduation = graduation_rates |>
  filter(
    str_detect(level_of_institution, "^All 4-year institutions"),
    control_of_institution == "Total",
    gender == "Total"
  ) |>
  transmute(
    year = factor(year, levels = year_levels),
    metric = all_students
  ) |>
  arrange(year)

enrollment = enrollment_by_level |>
  filter(
    level_of_institution == "All students",
    distance_education_status_of_student == "All students"
  ) |>
  transmute(
    year = factor(year, levels = year_levels),
    metric = total_undergraduate
  ) |>
  arrange(year)

awards = awards_by_demo |>
  filter(
    level_of_award == "Total awards",
    gender == "All students"
  ) |>
  transmute(
    year = factor(year, levels = year_levels),
    metric = all_students
  ) |>
  arrange(year)

net_price = financial_aid |>
  filter(
    level_of_institution == "4-year",
    type_of_aid_awarded == "Students awarded Title IV aid",
    family_income_level == "All family income levels"
  ) |>
  select(
    year,
    Public = public_net_price,
    `Private nonprofit` = private_nonprofit_net_price,
    `Private for-profit` = private_for_profit_net_price
  ) |>
  pivot_longer(
    cols = -year,
    names_to = "sector",
    values_to = "metric"
  ) |>
  mutate(
    year = factor(year, levels = year_levels),
    sector = factor(
      sector,
      levels = c("Public", "Private nonprofit", "Private for-profit")
    )
  ) |>
  arrange(sector, year)

women_share = enrollment_by_demo |>
  group_by(year) |>
  summarise(
    men = sum(all_students_men, na.rm = TRUE),
    women = sum(all_students_women, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    year = factor(year, levels = year_levels),
    metric = women / (men + women) * 100
  ) |>
  arrange(year)

# -----------------------------
# 3. Label functions
# -----------------------------

percent_label = function(x) {
  paste0(number(x, accuracy = 0.1), "%")
}

million_label = function(x) {
  paste0(number(x / 1000000, accuracy = 0.01), "M")
}

dollar_k_label = function(x) {
  paste0("$", number(x / 1000, accuracy = 0.1), "k")
}

change_label = function(first_value, last_value, format = "percent") {
  
  change = last_value - first_value
  
  if (format == "percent") {
    paste0(
      if_else(change >= 0, "+", ""),
      number(change, accuracy = 0.1),
      " pts"
    )
  } else {
    pct_change = change / first_value * 100
    
    paste0(
      if_else(pct_change >= 0, "+", ""),
      number(pct_change, accuracy = 0.1),
      "%"
    )
  }
}

# -----------------------------
# 4. Create summary callouts
# -----------------------------

snapshot_summary = tibble(
  indicator = c(
    "4-year full-time retention",
    "4-year graduation rate",
    "Undergraduate enrollment",
    "Total awards",
    "Women share of enrollment"
  ),
  latest_value = c(
    percent_label(last(retention$metric)),
    percent_label(last(graduation$metric)),
    million_label(last(enrollment$metric)),
    million_label(last(awards$metric)),
    percent_label(last(women_share$metric))
  ),
  change = c(
    change_label(first(retention$metric), last(retention$metric), "percent"),
    change_label(first(graduation$metric), last(graduation$metric), "percent"),
    change_label(first(enrollment$metric), last(enrollment$metric), "volume"),
    change_label(first(awards$metric), last(awards$metric), "volume"),
    change_label(first(women_share$metric), last(women_share$metric), "percent")
  )
)

snapshot_summary

# -----------------------------
# 5. Reusable trend plot function
# -----------------------------

make_single_trend_plot = function(data, title, subtitle, formatter, colour) {
  
  latest = data |>
    filter(!is.na(metric)) |>
    slice_tail(n = 1) |>
    mutate(label = formatter(metric))
  
  ggplot(data, aes(x = year, y = metric, group = 1)) +
    geom_line(linewidth = 1.1, colour = colour) +
    geom_point(size = 2.6, colour = colour) +
    geom_label(
      data = latest,
      aes(x = year, y = metric, label = label),
      inherit.aes = FALSE,
      hjust = 0,
      nudge_x = 0.12,
      size = 3.2,
      label.size = 0,
      fill = "white",
      colour = colour
    ) +
    scale_y_continuous(
      labels = formatter,
      expand = expansion(mult = c(0.08, 0.28))
    ) +
    coord_cartesian(clip = "off") +
    labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = NULL
    ) +
    theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold", size = 12),
      plot.subtitle = element_text(size = 9, colour = "grey35"),
      panel.grid.minor = element_blank(),
      axis.text.x = element_text(size = 9),
      plot.margin = margin(8, 42, 8, 8)
    )
}

# -----------------------------
# 6. Build six snapshot panels
# -----------------------------

p_retention = make_single_trend_plot(
  retention,
  "Retention rate",
  "4-year, full-time students",
  percent_label,
  "#1B6CA8"
)

p_graduation = make_single_trend_plot(
  graduation,
  "Graduation rate",
  "All 4-year institutions",
  percent_label,
  "#2E8B57"
)

p_enrollment = make_single_trend_plot(
  enrollment,
  "Undergraduate enrollment",
  "All institutions",
  million_label,
  "#A23E48"
)

p_awards = make_single_trend_plot(
  awards,
  "Total awards",
  "All award levels",
  million_label,
  "#7A5195"
)

latest_prices = net_price |>
  group_by(sector) |>
  slice_tail(n = 1) |>
  ungroup() |>
  mutate(label = dollar_k_label(metric))

p_price = ggplot(
  net_price,
  aes(x = year, y = metric, colour = sector, group = sector)
) +
  geom_line(linewidth = 1.05) +
  geom_point(size = 2.3) +
  geom_label(
    data = latest_prices,
    aes(label = label),
    hjust = 0,
    nudge_x = 0.10,
    size = 3,
    label.size = 0,
    fill = "white",
    show.legend = FALSE
  ) +
  scale_colour_manual(
    values = c(
      "Public" = "#1B6CA8",
      "Private nonprofit" = "#2E8B57",
      "Private for-profit" = "#A23E48"
    )
  ) +
  scale_y_continuous(
    labels = dollar_k_label,
    expand = expansion(mult = c(0.08, 0.30))
  ) +
  coord_cartesian(clip = "off") +
  labs(
    title = "Net price by sector",
    subtitle = "4-year Title IV recipients, all incomes",
    x = NULL,
    y = NULL,
    colour = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 9, colour = "grey35"),
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    legend.text = element_text(size = 8.5),
    axis.text.x = element_text(size = 9),
    plot.margin = margin(8, 42, 8, 8)
  )

p_women = make_single_trend_plot(
  women_share,
  "Women share of enrollment",
  "Summed across states and jurisdictions",
  percent_label,
  "#D17C0B"
)

# -----------------------------
# 7. Combine plot
# -----------------------------

snapshot_plot = (
  p_retention + p_graduation +
    p_enrollment + p_awards +
    p_price + p_women
) +
  plot_layout(ncol = 2) +
  plot_annotation(
    title = "Higher Education Data Snapshot",
    subtitle = "National topline indicators, academic years 2018–19 through 2023–24",
    caption = paste(
      "Source: reporting system data files.",
      "Undergraduate enrollment begins in 2019–20;",
      "demographic enrollment ends in 2022–23."
    )
  ) &
  theme(
    plot.title = element_text(face = "bold"),
    plot.caption = element_text(colour = "grey40", size = 9)
  )

snapshot_plot

# -----------------------------
# 8. Export snapshot
# -----------------------------

ggsave(
  filename = "~/Desktop/Project/reporting-sys/output/higher_education_data_snapshot.png",
  plot = snapshot_plot,
  width = 14,
  height = 11,
  dpi = 320,
  bg = "white"
)