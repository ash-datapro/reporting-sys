CREATE OR REPLACE VIEW reporting.kpi_enrollment_level_dashboard_summary AS
SELECT
    year,
    total_undergraduate,
    total_graduate,
    total_enrollment,

    ROUND(
        100.0 * total_undergraduate / NULLIF(total_enrollment, 0),
        1
    ) AS pct_undergraduate,

    ROUND(
        100.0 * total_graduate / NULLIF(total_enrollment, 0),
        1
    ) AS pct_graduate

FROM reporting.kpi_enrollment_level_by_year
ORDER BY year;

SELECT *
FROM reporting.kpi_enrollment_level_dashboard_summary;