CREATE OR REPLACE VIEW reporting.kpi_awards_total_by_year AS
SELECT
    year,
    SUM(COALESCE(all_students, 0)) AS total_awards
FROM reporting.awards_by_demo
GROUP BY year
ORDER BY year;

SELECT *
FROM reporting.kpi_awards_total_by_year;