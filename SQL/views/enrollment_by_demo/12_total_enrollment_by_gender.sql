CREATE OR REPLACE VIEW reporting.kpi_enrollment_gender_share AS
SELECT
    year,
    SUM(COALESCE(all_students_men, 0)) AS total_men,
    SUM(COALESCE(all_students_women, 0)) AS total_women,
    SUM(COALESCE(all_students_men, 0) + COALESCE(all_students_women, 0)) AS total_enrollment,

    ROUND(
        100.0 * SUM(COALESCE(all_students_men, 0))
        / NULLIF(SUM(COALESCE(all_students_men, 0) + COALESCE(all_students_women, 0)), 0),
        1
    ) AS pct_men,

    ROUND(
        100.0 * SUM(COALESCE(all_students_women, 0))
        / NULLIF(SUM(COALESCE(all_students_men, 0) + COALESCE(all_students_women, 0)), 0),
        1
    ) AS pct_women

FROM reporting.enrollment_by_demo
GROUP BY year
ORDER BY year;

SELECT *
FROM reporting.kpi_enrollment_gender_share;