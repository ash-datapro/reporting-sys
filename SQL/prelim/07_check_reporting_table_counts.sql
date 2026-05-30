SELECT 'awards_by_demo' AS table_name, COUNT(*) AS row_count
FROM reporting.awards_by_demo

UNION ALL

SELECT 'enrollment_by_demo', COUNT(*)
FROM reporting.enrollment_by_demo

UNION ALL

SELECT 'enrollment_by_level', COUNT(*)
FROM reporting.enrollment_by_level

UNION ALL

SELECT 'financial_aid', COUNT(*)
FROM reporting.financial_aid

UNION ALL

SELECT 'graduation_rates', COUNT(*)
FROM reporting.graduation_rates

UNION ALL

SELECT 'retention_undergrad', COUNT(*)
FROM reporting.retention_undergrad

ORDER BY table_name;