# ============================================================
# One-Page Executive Memo PNG
# Based on reporting_executive_brief_findings output
# ============================================================

# Install once if needed:
# install.packages(c("ggplot2", "grid", "stringr", "ragg"))

library(ggplot2)
library(grid)
library(stringr)
library(ragg)

# -----------------------------
# User-editable settings
# -----------------------------
institution_name = "Institutional Reporting Executive Brief"
report_period = "Academic Years 2018-19 through 2023-24"
output_file = "~/Desktop/Project/reporting-sys/reports/executive_memo.png"

page_width = 8.5
page_height = 11
dpi = 300

# -----------------------------
# Findings from uploaded output
# -----------------------------
findings = data.frame(
  category = c(
    "Data Coverage",
    "Retention",
    "Distance Education Enrollment",
    "Financial Aid Data Quality",
    "Graduation Rate Data Quality"
  ),
  finding = c(
    "Processed 1,177 IPEDS aggregated reporting rows across six institutional reporting tables covering 2018-19 through 2023-24.",
    "Undergraduate retention was 67.6% overall, with a 28.7 percentage-point difference between full-time and part-time enrollment-status groups.",
    "Students not enrolled in any distance education courses declined from 24.7% of reported enrollment in 2019-20 to 18.2% in 2023-24, a 6.5 percentage-point decrease.",
    "Validation flagged 2 financial-aid records (1.6%) with missing private nonprofit grant-aid or net-price values. Affected values were excluded from metric calculations.",
    "American Indian or Alaska Native graduation-rate measures had the highest missingness rate at 10.0% (24 of 240 rate records). Missing values were excluded from subgroup summaries."
  ),
  stringsAsFactors = FALSE
)

# -----------------------------
# Color palette
# -----------------------------
navy = "#17324D"
blue = "#356A92"
light_blue = "#EAF2F7"
slate = "#4B5563"
border = "#D8DEE5"
white = "#FFFFFF"
amber = "#A76700"
light_amber = "#FFF4E5"

# -----------------------------
# Helper functions
# -----------------------------
draw_text = function(
    label,
    x,
    y,
    width = NULL,
    gp = gpar(),
    just = c("left", "top")
) {
  if (!is.null(width)) {
    label = str_wrap(label, width = width)
  }
  
  grid.text(
    label = label,
    x = unit(x, "npc"),
    y = unit(y, "npc"),
    just = just,
    gp = gp
  )
}

draw_card = function(
    x,
    y,
    width,
    height,
    fill,
    line = NA,
    radius = unit(0.08, "in")
) {
  grid.roundrect(
    x = unit(x, "npc"),
    y = unit(y, "npc"),
    width = unit(width, "npc"),
    height = unit(height, "npc"),
    just = c("left", "top"),
    r = radius,
    gp = gpar(fill = fill, col = line, lwd = 1)
  )
}

draw_metric = function(x, y, width, value, label) {
  draw_card(
    x = x,
    y = y,
    width = width,
    height = 0.082,
    fill = light_blue,
    line = NA
  )
  
  draw_text(
    label = value,
    x = x + 0.018,
    y = y - 0.018,
    gp = gpar(
      fontfamily = "Arial",
      fontsize = 19,
      fontface = "bold",
      col = navy
    )
  )
  
  draw_text(
    label = label,
    x = x + 0.018,
    y = y - 0.054,
    width = 24,
    gp = gpar(
      fontfamily = "Arial",
      fontsize = 8.2,
      col = slate,
      lineheight = 1.05
    )
  )
}

draw_finding = function(number, category, finding, x, y, width, height, alert = FALSE) {
  fill_color = ifelse(alert, light_amber, white)
  accent_color = ifelse(alert, amber, blue)
  
  draw_card(
    x = x,
    y = y,
    width = width,
    height = height,
    fill = fill_color,
    line = border
  )
  
  grid.circle(
    x = unit(x + 0.028, "npc"),
    y = unit(y - 0.029, "npc"),
    r = unit(0.015, "npc"),
    gp = gpar(fill = accent_color, col = NA)
  )
  
  grid.text(
    label = number,
    x = unit(x + 0.028, "npc"),
    y = unit(y - 0.029, "npc"),
    gp = gpar(
      fontfamily = "Arial",
      fontsize = 8,
      fontface = "bold",
      col = white
    )
  )
  
  draw_text(
    label = toupper(category),
    x = x + 0.057,
    y = y - 0.018,
    gp = gpar(
      fontfamily = "Arial",
      fontsize = 7.5,
      fontface = "bold",
      col = accent_color
    )
  )
  
  draw_text(
    label = finding,
    x = x + 0.057,
    y = y - 0.041,
    width = 82,
    gp = gpar(
      fontfamily = "Arial",
      fontsize = 8.5,
      col = navy,
      lineheight = 1.15
    )
  )
}

# -----------------------------
# Build PNG
# -----------------------------
agg_png(
  filename = output_file,
  width = page_width,
  height = page_height,
  units = "in",
  res = dpi,
  background = white
)

grid.newpage()

# Background
grid.rect(gp = gpar(fill = white, col = NA))

# Header band
grid.rect(
  x = unit(0, "npc"),
  y = unit(1, "npc"),
  width = unit(1, "npc"),
  height = unit(0.145, "npc"),
  just = c("left", "top"),
  gp = gpar(fill = navy, col = NA)
)

draw_text(
  label = "EXECUTIVE MEMO",
  x = 0.06,
  y = 0.955,
  gp = gpar(
    fontfamily = "Arial",
    fontsize = 10,
    fontface = "bold",
    col = "#B8D2E5"
  )
)

draw_text(
  label = institution_name,
  x = 0.06,
  y = 0.919,
  gp = gpar(
    fontfamily = "Arial",
    fontsize = 22,
    fontface = "bold",
    col = white
  )
)

draw_text(
  label = report_period,
  x = 0.06,
  y = 0.878,
  gp = gpar(
    fontfamily = "Arial",
    fontsize = 9.5,
    col = "#D8E5EF"
  )
)

# Executive summary
draw_text(
  label = "EXECUTIVE SUMMARY",
  x = 0.06,
  y = 0.822,
  gp = gpar(
    fontfamily = "Arial",
    fontsize = 9,
    fontface = "bold",
    col = blue
  )
)

summary_text = paste(
  "Institutional reporting results indicate stable multi-year data coverage with a notable",
  "retention disparity by enrollment status and a measurable decline in students reporting",
  "no distance education enrollment. Data-quality exceptions were limited but should remain",
  "visible in downstream interpretation of financial-aid and demographic graduation-rate results."
)

draw_text(
  label = summary_text,
  x = 0.06,
  y = 0.795,
  width = 116,
  gp = gpar(
    fontfamily = "Arial",
    fontsize = 9.8,
    col = navy,
    lineheight = 1.25
  )
)

# Metric cards
draw_metric(
  x = 0.06,
  y = 0.715,
  width = 0.273,
  value = "1,177",
  label = "Aggregated reporting rows processed"
)

draw_metric(
  x = 0.363,
  y = 0.715,
  width = 0.273,
  value = "67.6%",
  label = "Overall undergraduate retention"
)

draw_metric(
  x = 0.666,
  y = 0.715,
  width = 0.273,
  value = "28.7 pts",
  label = "Retention difference by enrollment status"
)

# Key findings title
draw_text(
  label = "KEY FINDINGS",
  x = 0.06,
  y = 0.602,
  gp = gpar(
    fontfamily = "Arial",
    fontsize = 9,
    fontface = "bold",
    col = blue
  )
)

# Findings cards
draw_finding(
  number = "1",
  category = findings$category[1],
  finding = findings$finding[1],
  x = 0.06,
  y = 0.578,
  width = 0.88,
  height = 0.071
)

draw_finding(
  number = "2",
  category = findings$category[2],
  finding = findings$finding[2],
  x = 0.06,
  y = 0.493,
  width = 0.88,
  height = 0.078
)

draw_finding(
  number = "3",
  category = findings$category[3],
  finding = findings$finding[3],
  x = 0.06,
  y = 0.401,
  width = 0.88,
  height = 0.091
)

draw_finding(
  number = "4",
  category = findings$category[4],
  finding = findings$finding[4],
  x = 0.06,
  y = 0.296,
  width = 0.88,
  height = 0.093,
  alert = TRUE
)

draw_finding(
  number = "5",
  category = findings$category[5],
  finding = findings$finding[5],
  x = 0.06,
  y = 0.189,
  width = 0.88,
  height = 0.100,
  alert = TRUE
)

# Footer
draw_text(
  label = paste0(
    "Source: reporting_executive_brief_findings  |  Generated: ",
    format(Sys.Date(), "%B %d, %Y")
  ),
  x = 0.06,
  y = 0.037,
  gp = gpar(
    fontfamily = "Arial",
    fontsize = 7.5,
    col = slate
  )
)

dev.off()

message("Executive memo PNG created: ", normalizePath(output_file))