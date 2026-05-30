CREATE OR REPLACE VIEW reporting.kpi_graduation_rate_by_year AS
SELECT
    year,
    ROUND(AVG(all_students::NUMERIC), 1) AS avg_graduation_rate
FROM reporting.graduation_rates
WHERE all_students IS NOT NULL
GROUP BY year
ORDER BY year;

SELECT *
FROM reporting.kpi_graduation_rate_by_year;