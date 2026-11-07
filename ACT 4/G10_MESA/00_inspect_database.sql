
-- 00_inspect_database.sql
-- Check the current database
SELECT current_database();

-- Check available schemas
SELECT schema_name
FROM information_schema.schemata
ORDER BY schema_name;

-- List all tables in the public schema
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- List all columns and their data types
SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- List all sequences
SELECT sequence_name
FROM information_schema.sequences
WHERE sequence_schema = 'public'
ORDER BY sequence_name;

-- List all views
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;
