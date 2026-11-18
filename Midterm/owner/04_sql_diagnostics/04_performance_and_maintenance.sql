-- =============================================================================
-- PostgreSQL DBA Diagnostic Toolkit: 04_performance_and_maintenance.sql
-- Purpose: Monitor buffer cache hit ratio, dead tuple bloat, and vacuum statistics
-- Execution: psql -U <user> -d <database> -f 04_performance_and_maintenance.sql
-- =============================================================================

\echo '================================================================='
\echo ' 1. DATABASE BUFFER CACHE HIT RATIO (TARGET: > 99%)              '
\echo '================================================================='
SELECT datname,
       blks_read,
       blks_hit,
       ROUND((blks_hit::numeric / NULLIF(blks_hit + blks_read, 0)::numeric) * 100, 2) AS cache_hit_pct
FROM pg_stat_database
WHERE datname = current_database();

\echo ''
\echo '================================================================='
\echo ' 2. TABLE BLOAT & DEAD TUPLE METRICS (pg_stat_user_tables)       '
\echo '================================================================='
SELECT relname AS table_name,
       n_live_tup AS live_tuples,
       n_dead_tup AS dead_tuples,
       ROUND((n_dead_tup::numeric / NULLIF(n_live_tup + n_dead_tup, 0)::numeric) * 100, 2) AS dead_tuple_pct,
       last_vacuum,
       last_autovacuum,
       last_analyze,
       vacuum_count,
       analyze_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC;

\echo ''
\echo '================================================================='
\echo ' 3. INDEX USAGE EFFICIENCY & UNUSED INDEX DETECTION              '
\echo '================================================================='
SELECT relname AS table_name,
       indexrelname AS index_name,
       idx_scan AS number_of_scans,
       idx_tup_read AS tuples_read,
       idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan ASC, relname;

\echo ''
\echo '================================================================='
\echo ' 4. AUTOVACUUM ENGINE CONFIGURATION                              '
\echo '================================================================='
SELECT name, setting, unit, short_desc
FROM pg_settings
WHERE name LIKE 'autovacuum%' OR name IN ('vacuum_cost_limit', 'maintenance_work_mem')
ORDER BY name;
