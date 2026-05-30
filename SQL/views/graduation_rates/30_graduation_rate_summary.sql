CREATE OR REPLACE VIEW reporting.kpi_graduation_rate_dashboard_summary AS
WITH annual_rates AS (
    SELECT
        year,
        avg_graduation_rate
    FROM reporting.kpi_graduation_rate_by_year
),

prior_year AS (
    SELECT
        year,
        avg_graduation_rate,
        LAG(avg_graduation_rate) OVER (ORDER BY year) AS prior_year_graduation_rate
    FROM annual_rates
)

SELECT
    year,
    avg_graduation_rate,
    prior_year_graduation_rate,
    ROUND(
        avg_graduation_rate - prior_year_graduation_rate,
        1
    ) AS year_over_year_point_change
FROM prior_year
ORDER BY year;

SELECT *
FROM reporting.kpi_graduation_rate_dashboard_summary;