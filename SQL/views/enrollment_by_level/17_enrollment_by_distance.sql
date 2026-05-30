CREATE OR REPLACE VIEW reporting.kpi_enrollment_by_distance_status AS
SELECT
    year,
    distance_education_status_of_student,
    SUM(COALESCE(total_undergraduate, 0)) AS total_undergraduate,
    SUM(COALESCE(total_graduate, 0)) AS total_graduate,
    SUM(
        COALESCE(total_undergraduate, 0)
        + COALESCE(total_graduate, 0)
    ) AS total_enrollment
FROM reporting.enrollment_by_level
GROUP BY
    year,
    distance_education_status_of_student
ORDER BY
    year,
    distance_education_status_of_student;

SELECT *
FROM reporting.kpi_enrollment_by_distance_status;