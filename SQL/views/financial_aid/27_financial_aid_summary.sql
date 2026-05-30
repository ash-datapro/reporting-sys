CREATE OR REPLACE VIEW reporting.kpi_financial_aid_dashboard_summary AS
SELECT
    year,
    ROUND(AVG(avg_cost_of_attendance), 0) AS avg_cost_of_attendance,
    ROUND(AVG(avg_grant_scholarship_aid), 0) AS avg_grant_scholarship_aid,
    ROUND(AVG(avg_net_price), 0) AS avg_net_price
FROM reporting.kpi_affordability_by_year_sector
GROUP BY year
ORDER BY year;

SELECT *
FROM reporting.kpi_financial_aid_dashboard_summary;