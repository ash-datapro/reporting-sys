CREATE OR REPLACE VIEW reporting.kpi_retention_by_control AS
SELECT
    year,
    level_of_institution,
    degree_granting_status,
    control_of_institution,
    SUM(COALESCE(adjusted_cohort, 0)) AS adjusted_cohort,
    SUM(COALESCE(still_enrolled, 0)) AS still_enrolled,
    ROUND(
        100.0 * SUM(COALESCE(still_enrolled, 0))
        / NULLIF(SUM(COALESCE(adjusted_cohort, 0)), 0),
        1
    ) AS retention_rate
FROM reporting.retention_undergrad
GROUP BY
    year,
    level_of_institution,
    degree_granting_status,
    control_of_institution
ORDER BY
    year,
    level_of_institution,
    degree_granting_status,
    control_of_institution;

SELECT *
FROM reporting.kpi_retention_by_control;