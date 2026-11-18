-- =============================================================================
-- PostgreSQL DBA Diagnostic Toolkit: 02_schema_and_catalog.sql
-- Purpose: Comprehensive schema inventory, constraints, foreign keys, and indexes
-- Execution: psql -U <user> -d <database> -f 02_schema_and_catalog.sql
-- =============================================================================

\echo '================================================================='
\echo ' 1. PUBLIC SCHEMA TABLE INVENTORY & ESTIMATED ROW COUNTS         '
\echo '================================================================='
SELECT c.relname AS table_name,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
       pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
       pg_size_pretty(pg_indexes_size(c.oid)) AS indexes_size,
       c.reltuples::bigint AS estimated_rows
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'r'
ORDER BY c.relname;

\echo ''
\echo '================================================================='
\echo ' 2. PRIMARY KEYS & UNIQUE CONSTRAINTS                            '
\echo '================================================================='
SELECT conrelid::regclass AS table_name,
       conname AS constraint_name,
       CASE contype
           WHEN 'p' THEN 'PRIMARY KEY'
           WHEN 'u' THEN 'UNIQUE'
           WHEN 'c' THEN 'CHECK'
       END AS constraint_type,
       pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace AND contype IN ('p', 'u', 'c')
ORDER BY table_name, constraint_type;

\echo ''
\echo '================================================================='
\echo ' 3. FOREIGN KEY RELATIONSHIPS & DELETE ACTIONS                   '
\echo '================================================================='
SELECT conrelid::regclass AS child_table,
       conname AS fk_constraint_name,
       confrelid::regclass AS parent_table,
       CASE confdeltype
           WHEN 'a' THEN 'NO ACTION'
           WHEN 'r' THEN 'RESTRICT'
           WHEN 'c' THEN 'CASCADE'
           WHEN 'n' THEN 'SET NULL'
           WHEN 'd' THEN 'SET DEFAULT'
       END AS on_delete_action,
       pg_get_constraintdef(oid) AS full_definition
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace AND contype = 'f'
ORDER BY child_table;

\echo ''
\echo '================================================================='
\echo ' 4. B-TREE & SECONDARY INDEXES                                   '
\echo '================================================================='
SELECT tablename,
       indexname,
       indexdef AS index_definition
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
