-- =============================================================================
-- CampusSafe (Group 7) — Isolated Test Database Provisioning Script
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Test Database: grp07_campussafedb_activity6_restore_test
-- Target Drill Database: grp07_campussafedb_recovery_drill
-- 
-- Execute while connected to the administrative default database 'postgres'
-- =============================================================================

\echo '================================================================='
\echo ' Provisioning Isolated Restoration Test Databases for CampusSafe '
\echo '================================================================='

-- Safety Check: Confirm we are connected to default postgres, not production!
SELECT current_database() AS current_conn_db;

-- 1. Provision Primary Restoration Test Database
-- Disconnect any active connections to test database if re-running
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'grp07_campussafedb_activity6_restore_test'
  AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS grp07_campussafedb_activity6_restore_test;

CREATE DATABASE grp07_campussafedb_activity6_restore_test
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'C'
    LC_CTYPE = 'C'
    TEMPLATE = template0;

COMMENT ON DATABASE grp07_campussafedb_activity6_restore_test IS 
'COMP 018 Activity 6 isolated test database for CampusSafe (Group 7) backup verification';

-- 2. Provision Secondary Disaster Recovery Drill Database (Phase 7 Canary Simulation)
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'grp07_campussafedb_recovery_drill'
  AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS grp07_campussafedb_recovery_drill;

CREATE DATABASE grp07_campussafedb_recovery_drill
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'C'
    LC_CTYPE = 'C'
    TEMPLATE = template0;

COMMENT ON DATABASE grp07_campussafedb_recovery_drill IS 
'COMP 018 Activity 6 isolated disaster recovery drill database for CampusSafe (Group 7)';

\echo '================================================================='
\echo ' Target test databases provisioned successfully:                 '
\echo '   1. grp07_campussafedb_activity6_restore_test (Restoration Test)'
\echo '   2. grp07_campussafedb_recovery_drill (Data-Loss Simulation Drill)'
\echo '================================================================='

SELECT datname, pg_size_pretty(pg_database_size(datname)) AS db_size, datistemplate
FROM pg_database
WHERE datname IN ('grp07_campussafedb', 'grp07_campussafedb_activity6_restore_test', 'grp07_campussafedb_recovery_drill');

