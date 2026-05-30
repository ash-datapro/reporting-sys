CREATE OR REPLACE VIEW reporting.kpi_financial_aid_by_sector AS

SELECT
    year,
    level_of_institution,
    type_of_aid_awarded,
    family_income_level,
    'Public' AS institution_sector,
    public_average_cost_of_attendance::NUMERIC AS average_cost_of_attendance,
    public_average_grant_scholarship_aid::NUMERIC AS average_grant_scholarship_aid,
    public_net_price::NUMERIC AS net_price
FROM reporting.financial_aid

UNION ALL

SELECT
    year,
    level_of_institution,
    type_of_aid_awarded,
    family_income_level,
    'Private nonprofit' AS institution_sector,
    private_nonprofit_average_cost_of_attendance::NUMERIC AS average_cost_of_attendance,
    private_nonprofit_average_grant_scholarship_aid::NUMERIC AS average_grant_scholarship_aid,
    private_nonprofit_net_price::NUMERIC AS net_price
FROM reporting.financial_aid

UNION ALL

SELECT
    year,
    level_of_institution,
    type_of_aid_awarded,
    family_income_level,
    'Private for-profit' AS institution_sector,
    private_for_profit_average_cost_of_attendance::NUMERIC AS average_cost_of_attendance,
    private_for_profit_average_grant_scholarship_aid::NUMERIC AS average_grant_scholarship_aid,
    private_for_profit_net_price::NUMERIC AS net_price
FROM reporting.financial_aid;

SELECT *
FROM reporting.kpi_financial_aid_by_sector
ORDER BY
    year,
    level_of_institution,
    institution_sector,
    family_income_level
LIMIT 50;