-- ==========================================
-- BOARDTRACK - DATABASE INSPECTION
-- Activity 4
-- ==========================================

-- Display current database
SELECT current_database();

-- Display current user
SELECT current_user;

-- List all tables in public schema
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Display table columns
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- Display sequences
SELECT
    sequence_schema,
    sequence_name
FROM information_schema.sequences
WHERE sequence_schema = 'public';

-- Display existing roles
SELECT
    rolname,
    rolsuper,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin
FROM pg_roles
ORDER BY rolname;