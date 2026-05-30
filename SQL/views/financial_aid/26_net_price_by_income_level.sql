CREATE OR REPLACE VIEW reporting.kpi_net_price_by_income_level AS
SELECT
    year,
    institution_sector,
    level_of_institution,
    family_income_level,
    ROUND(AVG(net_price), 0) AS avg_net_price
FROM reporting.kpi_financial_aid_by_sector
WHERE net_price IS NOT NULL
GROUP BY
    year,
    institution_sector,
    level_of_institution,
    family_income_level
ORDER BY
    year,
    institution_sector,
    level_of_institution,
    family_income_level;

SELECT *
FROM reporting.kpi_net_price_by_income_level
LIMIT 50;