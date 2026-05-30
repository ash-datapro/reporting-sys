CREATE OR REPLACE VIEW reporting.kpi_enrollment_level_by_year AS
SELECT
    year,
    SUM(COALESCE(total_undergraduate, 0)) AS total_undergraduate,
    SUM(COALESCE(total_graduate, 0)) AS total_graduate,
    SUM(
        COALESCE(total_undergraduate, 0)
        + COALESCE(total_graduate, 0)
    ) AS total_enrollment
FROM reporting.enrollment_by_level
GROUP BY year
ORDER BY year;

SELECT *
FROM reporting.kpi_enrollment_level_by_year;