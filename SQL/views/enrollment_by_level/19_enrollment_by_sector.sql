CREATE OR REPLACE VIEW reporting.kpi_enrollment_by_sector AS

SELECT
    year,
    'Public' AS institution_sector,
    SUM(COALESCE(public_undergraduate, 0)) AS undergraduate_enrollment,
    SUM(COALESCE(public_graduate, 0)) AS graduate_enrollment,
    SUM(
        COALESCE(public_undergraduate, 0)
        + COALESCE(public_graduate, 0)
    ) AS total_enrollment
FROM reporting.enrollment_by_level
GROUP BY year

UNION ALL

SELECT
    year,
    'Private nonprofit' AS institution_sector,
    SUM(COALESCE(private_nonprofit_undergraduate, 0)) AS undergraduate_enrollment,
    SUM(COALESCE(private_nonprofit_graduate, 0)) AS graduate_enrollment,
    SUM(
        COALESCE(private_nonprofit_undergraduate, 0)
        + COALESCE(private_nonprofit_graduate, 0)
    ) AS total_enrollment
FROM reporting.enrollment_by_level
GROUP BY year

UNION ALL

SELECT
    year,
    'Private for-profit' AS institution_sector,
    SUM(COALESCE(private_for_profit_undergraduate, 0)) AS undergraduate_enrollment,
    SUM(COALESCE(private_for_profit_graduate, 0)) AS graduate_enrollment,
    SUM(
        COALESCE(private_for_profit_undergraduate, 0)
        + COALESCE(private_for_profit_graduate, 0)
    ) AS total_enrollment
FROM reporting.enrollment_by_level
GROUP BY year;

SELECT *
FROM reporting.kpi_enrollment_by_sector
ORDER BY year, total_enrollment DESC;