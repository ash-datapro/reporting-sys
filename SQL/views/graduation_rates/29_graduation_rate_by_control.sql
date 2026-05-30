CREATE OR REPLACE VIEW reporting.kpi_graduation_rate_by_control AS
SELECT
    year,
    level_of_institution,
    control_of_institution,
    ROUND(AVG(all_students::NUMERIC), 1) AS avg_graduation_rate
FROM reporting.graduation_rates
WHERE all_students IS NOT NULL
GROUP BY
    year,
    level_of_institution,
    control_of_institution
ORDER BY
    year,
    level_of_institution,
    control_of_institution;

SELECT *
FROM reporting.kpi_graduation_rate_by_control;