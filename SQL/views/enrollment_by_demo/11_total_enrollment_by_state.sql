CREATE OR REPLACE VIEW reporting.kpi_enrollment_by_state AS
SELECT
    year,
    state_or_jurisdiction,
    COALESCE(all_students_men, 0) AS total_men,
    COALESCE(all_students_women, 0) AS total_women,
    COALESCE(all_students_men, 0) + COALESCE(all_students_women, 0) AS total_enrollment
FROM reporting.enrollment_by_demo
ORDER BY year, state_or_jurisdiction;

SELECT *
FROM reporting.kpi_enrollment_by_state
LIMIT 25;