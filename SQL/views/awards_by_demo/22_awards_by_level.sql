CREATE OR REPLACE VIEW reporting.kpi_awards_by_level AS
SELECT
    year,
    level_of_award,
    SUM(COALESCE(all_students, 0)) AS total_awards
FROM reporting.awards_by_demo
GROUP BY
    year,
    level_of_award
ORDER BY
    year,
    total_awards DESC;

SELECT *
FROM reporting.kpi_awards_by_level;