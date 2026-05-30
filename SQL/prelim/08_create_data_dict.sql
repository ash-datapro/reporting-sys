CREATE OR REPLACE VIEW qa.data_dictionary AS
SELECT
    table_schema,
    table_name,
    column_name,
    ordinal_position,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema IN ('raw', 'reporting')
ORDER BY table_schema, table_name, ordinal_position;

SELECT *
FROM qa.data_dictionary;