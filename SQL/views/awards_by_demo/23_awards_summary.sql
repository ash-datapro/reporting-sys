CREATE OR REPLACE VIEW reporting.kpi_awards_dashboard_summary AS
WITH annual_totals AS (
    SELECT
        year,
        total_awards
    FROM reporting.kpi_awards_total_by_year
),

prior_year AS (
    SELECT
        year,
        total_awards,
        LAG(total_awards) OVER (ORDER BY year) AS prior_year_awards
    FROM annual_totals
)

SELECT
    year,
    total_awards,
    prior_year_awards,
    total_awards - prior_year_awards AS year_over_year_change,
    ROUND(
        100.0 * (total_awards - prior_year_awards)
        / NULLIF(prior_year_awards, 0),
        1
    ) AS year_over_year_pct_change
FROM prior_year
ORDER BY year;

SELECT *
FROM reporting.kpi_awards_dashboard_summary;