CREATE OR REPLACE VIEW reporting.kpi_affordability_by_year_sector AS
SELECT
    year,
    institution_sector,
    ROUND(AVG(average_cost_of_attendance), 0) AS avg_cost_of_attendance,
    ROUND(AVG(average_grant_scholarship_aid), 0) AS avg_grant_scholarship_aid,
    ROUND(AVG(net_price), 0) AS avg_net_price
FROM reporting.kpi_financial_aid_by_sector
GROUP BY
    year,
    institution_sector
ORDER BY
    year,
    institution_sector;

SELECT *
FROM reporting.kpi_affordability_by_year_sector;