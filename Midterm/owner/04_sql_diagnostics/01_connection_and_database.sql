-- =============================================================================
-- PostgreSQL DBA Diagnostic Toolkit: 01_connection_and_database.sql
-- Purpose: Inspect active database metadata, connection concurrency, and server state
-- Execution: psql -U <user> -d <database> -f 01_connection_and_database.sql
-- =============================================================================

\echo '================================================================='
\echo ' 1. CURRENT DATABASE & POSTGRESQL VERSION PROFILE                '
\echo '================================================================='
SELECT current_database() AS database_name,
       current_user AS session_user,
       inet_server_addr() AS server_ip,
       inet_server_port() AS server_port,
       version() AS postgresql_version;

\echo ''
\echo '================================================================='
\echo ' 2. DATABASE STORAGE FOOTPRINT                                   '
\echo '================================================================='
SELECT datname AS database_name,
       pg_size_pretty(pg_database_size(datname)) AS storage_size,
       pg_database_size(datname) AS bytes
FROM pg_database
WHERE datname = current_database();

\echo ''
\echo '================================================================='
\echo ' 3. ACTIVE SESSIONS & CONNECTION CONCURRENCY                    '
\echo '================================================================='
SELECT pid,
       usename AS database_user,
       client_addr AS client_ip,
       state,
       wait_event_type,
       wait_event,
       NOW() - state_change AS state_duration,
       SUBSTRING(query FROM 1 FOR 60) AS active_query_snippet
FROM pg_stat_activity
WHERE datname = current_database()
ORDER BY state_change DESC;

\echo ''
\echo '================================================================='
\echo ' 4. KEY SERVER CONNECTION SETTINGS                               '
\echo '================================================================='
SELECT name, setting, unit, short_desc
FROM pg_settings
WHERE name IN ('max_connections', 'shared_buffers', 'work_mem', 'listen_addresses', 'port')
ORDER BY name;
