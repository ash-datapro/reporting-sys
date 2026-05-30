CREATE OR REPLACE VIEW reporting.kpi_enrollment_dashboard_summary AS
WITH totals AS (
    SELECT
        year,
        total_enrollment,
        total_men,
        total_women
    FROM reporting.kpi_enrollment_total_by_year
),

gender_share AS (
    SELECT
        year,
        pct_men,
        pct_women
    FROM reporting.kpi_enrollment_gender_share
)

SELECT
    t.year,
    t.total_enrollment,
    t.total_men,
    t.total_women,
    g.pct_men,
    g.pct_women
FROM totals t
JOIN gender_share g
    ON t.year = g.year
ORDER BY t.year;

SELECT *
FROM reporting.kpi_enrollment_dashboard_summary;