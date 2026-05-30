CREATE OR REPLACE VIEW reporting.kpi_retention_yoy_change AS
WITH annual_retention AS (
    SELECT
        year,
        adjusted_cohort,
        still_enrolled,
        retention_rate
    FROM reporting.kpi_retention_dashboard_summary
),

prior_year AS (
    SELECT
        year,
        adjusted_cohort,
        still_enrolled,
        retention_rate,
        LAG(retention_rate) OVER (ORDER BY year) AS prior_year_retention_rate
    FROM annual_retention
)

SELECT
    year,
    adjusted_cohort,
    still_enrolled,
    retention_rate,
    prior_year_retention_rate,
    ROUND(
        retention_rate - prior_year_retention_rate,
        1
    ) AS year_over_year_point_change
FROM prior_year
ORDER BY year;

SELECT *
FROM reporting.kpi_retention_yoy_change;