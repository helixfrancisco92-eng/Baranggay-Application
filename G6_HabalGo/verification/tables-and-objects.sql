-- ==============================================================================
-- HabalGo (Group 6) — Database Objects Verification Script
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp00_habalgodb_activity6_restore_test
-- Schema: habalgo
-- ==============================================================================

\set ON_ERROR_STOP on
SET search_path TO habalgo, public;

SELECT '=================================================================' AS header;
SELECT ' AUDIT: SCHEMAS, TABLES, SEQUENCES, AND INDEXES                  ' AS header;
SELECT ' Database: ' || current_database() || ' | User: ' || current_user AS session_info;
SELECT '=================================================================' AS header;

-- 1. Verify Schemas
SELECT 
    nspname AS schema_name,
    pg_get_userbyid(nspowner) AS owner_name,
    'VERIFIED SCHEMA' AS status
FROM pg_namespace
WHERE nspname IN ('habalgo', 'public')
ORDER BY nspname;

-- 2. Verify All 8 Restored Tables
SELECT 
    table_schema,
    table_name,
    table_type,
    is_insertable_into,
    'VERIFIED BASE TABLE' AS audit_status
FROM information_schema.tables
WHERE table_schema = 'habalgo'
ORDER BY table_name;

-- 3. Detailed Column Specification for Each Table
SELECT 
    table_name,
    ordinal_position AS pos,
    column_name,
    data_type,
    character_maximum_length AS max_len,
    numeric_precision AS num_prec,
    numeric_scale AS num_scale,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'habalgo'
ORDER BY table_name, ordinal_position;

-- 4. Verify Sequences and Auto-Incrementing Counters
SELECT 
    sequence_schema,
    sequence_name,
    data_type,
    start_value,
    minimum_value,
    maximum_value,
    increment,
    cycle_option
FROM information_schema.sequences
WHERE sequence_schema = 'habalgo'
ORDER BY sequence_name;

-- 5. Verify Indexes (Performance and Relational)
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'habalgo'
ORDER BY tablename, indexname;

-- 6. Storage Footprint of Restored Relations
SELECT 
    relname AS relation_name,
    relkind AS object_type,
    pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
    pg_size_pretty(pg_indexes_size(c.oid)) AS index_size,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_relation_size
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'habalgo'
  AND c.relkind IN ('r', 'S', 'v', 'm')
ORDER BY pg_total_relation_size(c.oid) DESC;

