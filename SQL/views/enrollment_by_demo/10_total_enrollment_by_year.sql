CREATE OR REPLACE VIEW reporting.kpi_enrollment_total_by_year AS
SELECT
    year,
    SUM(COALESCE(all_students_men, 0)) AS total_men,
    SUM(COALESCE(all_students_women, 0)) AS total_women,
    SUM(COALESCE(all_students_men, 0) + COALESCE(all_students_women, 0)) AS total_enrollment
FROM reporting.enrollment_by_demo
GROUP BY year
ORDER BY year;

SELECT *
FROM reporting.kpi_enrollment_total_by_year;