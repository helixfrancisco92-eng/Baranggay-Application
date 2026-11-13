-- =============================================================================
-- CampusSafe (Group 7) — Access Control Re-application & Audit (08_verify_access_control.sql)
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp07_campussafedb_activity6_restore_test
-- =============================================================================

\echo '================================================================='
\echo ' Re-applying & Auditing Activity 4 Access Control on Restored DB '
\echo ' Target: grp07_campussafedb_activity6_restore_test               '
\echo '================================================================='

-- 1. Re-establish Group and Login Roles
DO $$
BEGIN
    -- Group Roles (NOLOGIN)
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_runtime_grp') THEN
        CREATE ROLE app_runtime_grp NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_readonly_grp') THEN
        CREATE ROLE app_readonly_grp NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_backup_grp') THEN
        CREATE ROLE app_backup_grp NOLOGIN;
    END IF;

    -- Login Roles
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'campussafe_app') THEN
        CREATE ROLE campussafe_app LOGIN PASSWORD 'change_me_locally';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'campussafe_report') THEN
        CREATE ROLE campussafe_report LOGIN PASSWORD 'change_me_locally';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'campussafe_backup') THEN
        CREATE ROLE campussafe_backup LOGIN PASSWORD 'change_me_locally';
    END IF;
END $$;

-- 2. Bind Memberships
GRANT app_runtime_grp  TO campussafe_app;
GRANT app_readonly_grp TO campussafe_report;
GRANT app_backup_grp   TO campussafe_backup;

-- 3. Lock down PUBLIC permissions
REVOKE ALL ON DATABASE grp07_campussafedb_activity6_restore_test FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- 4. Connection and Usage Grants
GRANT CONNECT ON DATABASE grp07_campussafedb_activity6_restore_test TO app_runtime_grp, app_readonly_grp, app_backup_grp;
GRANT USAGE ON SCHEMA public TO app_runtime_grp, app_readonly_grp, app_backup_grp;

-- 5. Application Runtime Role Permissions (Least Privilege)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_runtime_grp;
GRANT INSERT ON hazard_report, attachment, assignment, report_status_history,
                maintenance_action, app_user, hazard_category, campus_location
    TO app_runtime_grp;

-- Mutable tables allow UPDATE; immutable audit tables exclude UPDATE
GRANT UPDATE ON hazard_report, assignment, app_user, hazard_category, campus_location
    TO app_runtime_grp;

-- Restrict DELETE: Never allow deleting reports or users directly
GRANT DELETE ON attachment, assignment TO app_runtime_grp;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_runtime_grp;

-- 6. Read-Only / Auditor Role Permissions
GRANT SELECT ON hazard_report, hazard_category, campus_location,
                report_status_history, maintenance_action, assignment, attachment
    TO app_readonly_grp;

-- 7. Backup Operator Role Permissions
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_backup_grp;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO app_backup_grp;

-- 8. Future Default Privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE ON TABLES TO app_runtime_grp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO app_runtime_grp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO app_backup_grp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO app_backup_grp;

\echo '--- 9. AUDIT CONFIGURED ROLES AND LOGIN STATUS ---'
SELECT 
    r.rolname,
    r.rolcanlogin,
    r.rolsuper,
    ARRAY(SELECT b.rolname FROM pg_auth_members m JOIN pg_roles b ON m.roleid = b.oid WHERE m.member = r.oid) AS member_of
FROM pg_roles r
WHERE r.rolname IN ('app_runtime_grp', 'app_readonly_grp', 'app_backup_grp',
                    'campussafe_app', 'campussafe_report', 'campussafe_backup')
ORDER BY r.rolcanlogin, r.rolname;

\echo '--- 10. TABLE PRIVILEGE AUDIT MATRIX (PUBLIC SCHEMA) ---'
SELECT 
    grantee,
    table_name,
    string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privileges_granted
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND grantee IN ('app_runtime_grp', 'app_readonly_grp', 'app_backup_grp')
GROUP BY grantee, table_name
ORDER BY grantee, table_name;

