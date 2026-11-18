-- =============================================================================
-- PostgreSQL DBA Diagnostic Toolkit: 05_backup_and_recovery.sql
-- Purpose: Inspect sequence synchronization, WAL archiving status, and backup readiness
-- Execution: psql -U <user> -d <database> -f 05_backup_and_recovery.sql
-- =============================================================================

\echo '================================================================='
\echo ' 1. IDENTITY SEQUENCES SYNCHRONIZATION AUDIT                     '
\echo '================================================================='
-- Compares sequence current value with actual MAX(id) in corresponding table
SELECT c.relname AS sequence_name,
       t.relname AS table_name,
       a.attname AS column_name,
       pg_sequence_last_value(c.oid::regclass) AS current_seq_val,
       (xpath('/row/max/text()', xml_val))[1]::text::bigint AS max_table_id,
       CASE 
           WHEN pg_sequence_last_value(c.oid::regclass) >= COALESCE((xpath('/row/max/text()', xml_val))[1]::text::bigint, 0) THEN 'ALIGNED (HEALTHY)'
           ELSE 'OUT OF SYNC (COLLISION RISK!)'
       END AS sync_status
FROM pg_class c
JOIN pg_depend d ON d.objid = c.oid AND d.deptype = 'a'
JOIN pg_class t ON t.oid = d.refobjid
JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = d.refobjsubid
CROSS JOIN LATERAL (
    SELECT query_to_xml(format('SELECT MAX(%I) as max FROM public.%I', a.attname, t.relname), false, true, '') as xml_val
) x
WHERE c.relkind = 'S' AND t.relnamespace = 'public'::regnamespace
ORDER BY table_name;

\echo ''
\echo '================================================================='
\echo ' 2. WRITE-AHEAD LOG (WAL) & ARCHIVING STATUS                     '
\echo '================================================================='
SELECT name, setting, unit, short_desc
FROM pg_settings
WHERE name IN ('wal_level', 'archive_mode', 'archive_command', 'max_wal_size', 'min_wal_size')
ORDER BY name;

SELECT archived_count,
       last_archived_wal,
       last_archived_time,
       failed_count,
       last_failed_wal,
       last_failed_time
FROM pg_stat_archiver;

\echo ''
\echo '================================================================='
\echo ' 3. PUBLIC SCHEMA OBJECT COUNT INTEGRITY CHECK                   '
\echo '================================================================='
SELECT 
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE') AS total_tables,
    (SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public') AS total_indexes,
    (SELECT COUNT(*) FROM pg_constraint WHERE connamespace = 'public'::regnamespace) AS total_constraints,
    (SELECT COUNT(*) FROM pg_sequences WHERE schemaname = 'public') AS total_sequences;
