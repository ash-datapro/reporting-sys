CREATE OR REPLACE VIEW reporting.kpi_retention_by_enrollment_status AS
SELECT
    year,
    enrollment_status,
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
    enrollment_status
ORDER BY
    year,
    enrollment_status;

SELECT *
FROM reporting.kpi_retention_by_enrollment_status;