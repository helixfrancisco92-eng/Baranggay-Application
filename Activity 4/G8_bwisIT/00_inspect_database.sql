
-- ============================================
-- ACTIVITY 4: DATABASE INSPECTION
-- Campus Canteen Pre-Order and Queue Management
-- ============================================

-- 1. Display all schemas
SELECT schema_name
FROM information_schema.schemata
ORDER BY schema_name;

-- 2. Display all tables
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
  AND table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name;

-- 3. Display all columns
SELECT
    table_schema,
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name, ordinal_position;

-- 4. Display all sequences
SELECT
    sequence_schema,
    sequence_name
FROM information_schema.sequences
ORDER BY sequence_schema, sequence_name;

-- 5. Display existing PostgreSQL users and roles
SELECT
    rolname,
    rolsuper,
    rolcreatedb,
    rolcreaterole,
    rolcanlogin
FROM pg_roles
ORDER BY rolname;
