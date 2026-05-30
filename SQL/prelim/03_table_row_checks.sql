SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'raw'
ORDER BY table_name;

SELECT 'awards_by_demo' AS table_name, COUNT(*) AS row_count
FROM raw.awards_by_demo

UNION ALL

SELECT 'enrollment_by_demo' AS table_name, COUNT(*) AS row_count
FROM raw.enrollment_by_demo

UNION ALL

SELECT 'enrollment_by_level' AS table_name, COUNT(*) AS row_count
FROM raw.enrollment_by_level

UNION ALL

SELECT 'financial_aid' AS table_name, COUNT(*) AS row_count
FROM raw.financial_aid

UNION ALL

SELECT 'graduation_rates' AS table_name, COUNT(*) AS row_count
FROM raw.graduation_rates

UNION ALL

SELECT 'retention_undergrad' AS table_name, COUNT(*) AS row_count
FROM raw.retention_undergrad

ORDER BY table_name;

SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'raw'
ORDER BY table_name, ordinal_position;

