-- =============================================================================
-- CampusSafe (Group 7) — Deep Catalog & Object Inspection Suite
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp07_campussafedb_activity6_restore_test (or grp07_campussafedb)
-- =============================================================================

\echo '================================================================='
\echo ' CampusSafe Catalog & Object Verification Suite                  '
\echo '================================================================='

-- 1. Database & Schema Metadata
SELECT 
    current_database() AS database_name,
    current_schema() AS active_schema,
    version() AS postgresql_version;

-- 2. Complete User Table Catalog with On-Disk Sizes
SELECT 
    schemaname,
    tablename,
    tableowner,
    pg_size_pretty(pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename))) AS total_size,
    pg_size_pretty(pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename))) AS table_size,
    pg_size_pretty(pg_indexes_size(quote_ident(schemaname) || '.' || quote_ident(tablename))) AS index_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- 3. Comprehensive Column Data Dictionary
SELECT 
    c.table_name,
    c.ordinal_position,
    c.column_name,
    c.data_type,
    COALESCE(c.character_maximum_length::text, c.numeric_precision::text, 'N/A') AS max_length_precision,
    c.is_nullable,
    c.column_default
FROM information_schema.columns c
WHERE c.table_schema = 'public'
ORDER BY c.table_name, c.ordinal_position;

-- 4. Sequences and Association Audit
SELECT 
    s.sequence_schema,
    s.sequence_name,
    s.data_type,
    s.start_value,
    s.minimum_value,
    s.maximum_value,
    s.increment
FROM information_schema.sequences s
WHERE s.sequence_schema = 'public'
ORDER BY s.sequence_name;

-- 5. Complete Index Definitions Catalog
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 6. Constraint Summary by Table and Type
SELECT 
    table_name,
    constraint_type,
    COUNT(*) AS count
FROM information_schema.table_constraints
WHERE table_schema = 'public'
GROUP BY table_name, constraint_type
ORDER BY table_name, constraint_type;

