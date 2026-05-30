CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS qa;
CREATE SCHEMA IF NOT EXISTS reporting;

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('raw', 'qa', 'reporting')
ORDER BY schema_name;