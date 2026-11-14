# CampusSafe — Access Control & Role Recovery Report
## Assigned Project: Group 7 — CampusSafe
### Course: COMP 018 — Database Administration (Activity 6)

---

## 1. Architectural Foundations: PostgreSQL Cluster Roles vs. Single-Database Dumps

A foundational reality of PostgreSQL administration is the architectural separation between **cluster-level globals** and **database-level objects**:

1. **Cluster-Wide Global Entities (`pg_authid`):**
   * Login roles (users), group roles, passwords, global memberships, and tablespace definitions exist at the cluster level.
   * `pg_dump` operates strictly against a single database (`grp07_campussafedb`). Consequently, **single-database pg_dump custom archives do NOT export global roles or users**.
2. **Database-Level Objects (`public` schema):**
   * Schemas, tables, sequences, indexes, constraints, and Access Control Lists (ACLs) referencing existing roles exist inside the database catalog.
3. **The Disaster Recovery Impact:**
   * If an archive is restored into a clean PostgreSQL cluster where the Activity 4 roles do not exist, `pg_restore` will emit warnings (`role "campussafe_app" does not exist`) and fail to bind table ownership or ACL grants.

Therefore, an enterprise disaster recovery plan **must include a documented procedure to re-establish roles, group memberships, and least-privilege permissions**.

---

## 2. Activity 4 RBAC Architecture Overview

From Group 7's `database/03_roles_and_privileges.sql`, CampusSafe enforces a 3-tier Role-Based Access Control model founded on the Principle of Least Privilege (PoLP):

```
PostgreSQL Cluster (pg_roles)
├── app_runtime_grp (NOLOGIN)
│   └── campussafe_app (LOGIN) — Web Application (PHP PDO)
├── app_readonly_grp (NOLOGIN)
│   └── campussafe_report (LOGIN) — Safety Compliance Auditor / BI
└── app_backup_grp (NOLOGIN)
    └── campussafe_backup (LOGIN) — Disaster Recovery & Backup Operator
```

---

## 3. Post-Restoration Access Control Re-Establishment Script

To re-establish cluster roles and re-apply database privileges following archive restoration into a new host or cluster, execute `scripts/08_verify_access_control.sql` (or `database/03_roles_and_privileges.sql`):

```sql
-- Connect as PostgreSQL Superuser (postgres) to the restored database
\c grp07_campussafedb_activity6_restore_test postgres

-- 1. Create Group Roles (NOLOGIN)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_runtime_grp') THEN
        CREATE ROLE app_runtime_grp NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_readonly_grp') THEN
        CREATE ROLE app_readonly_grp NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_backup_grp') THEN
        CREATE ROLE app_backup_grp NOLOGIN;
    END IF;

    -- 2. Create Login Accounts with Local Passwords
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

-- 3. Bind Role Memberships
GRANT app_runtime_grp  TO campussafe_app;
GRANT app_readonly_grp TO campussafe_report;
GRANT app_backup_grp   TO campussafe_backup;

-- 4. Lock down PUBLIC permissions
REVOKE ALL ON DATABASE grp07_campussafedb_activity6_restore_test FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- 5. Grant Connection and Schema Usage
GRANT CONNECT ON DATABASE grp07_campussafedb_activity6_restore_test TO app_runtime_grp, app_readonly_grp, app_backup_grp;
GRANT USAGE ON SCHEMA public TO app_runtime_grp, app_readonly_grp, app_backup_grp;

-- 6. Application Runtime Permissions (Least Privilege)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_runtime_grp;
GRANT INSERT ON hazard_report, attachment, assignment, report_status_history,
                maintenance_action, app_user, hazard_category, campus_location
    TO app_runtime_grp;

-- Mutable entities allow UPDATE; immutable audit histories strictly exclude UPDATE
GRANT UPDATE ON hazard_report, assignment, app_user, hazard_category, campus_location
    TO app_runtime_grp;

-- Narrow DELETE: Never allow deleting users or hazard reports directly
GRANT DELETE ON attachment, assignment TO app_runtime_grp;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_runtime_grp;

-- 7. Auditor Permissions (Excludes app_user to protect bcrypt hashes)
GRANT SELECT ON hazard_report, hazard_category, campus_location,
                report_status_history, maintenance_action, assignment, attachment
    TO app_readonly_grp;

-- 8. Backup Operator Permissions (Activity 6 pg_dump)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_backup_grp;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO app_backup_grp;

-- 9. Future Default Privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE ON TABLES TO app_runtime_grp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO app_runtime_grp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO app_backup_grp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON SEQUENCES TO app_backup_grp;
```

---

## 4. Comprehensive Privilege Audit Matrix

| Database Object | `campussafe_app` (`app_runtime_grp`) | `campussafe_report` (`app_readonly_grp`) | `campussafe_backup` (`app_backup_grp`) | Technical Security Justification |
|---|---|---|---|---|
| `role` | `SELECT` | Denied | `SELECT` | System metadata; read-only for application logic |
| `app_user` | `SELECT, INSERT, UPDATE` | **DENIED** | `SELECT` | Auditor denied SELECT to protect bcrypt password hashes |
| `hazard_category` | `SELECT, INSERT, UPDATE` | `SELECT` | `SELECT` | Master data; protected against unverified deletion |
| `campus_location` | `SELECT, INSERT, UPDATE` | `SELECT` | `SELECT` | Master data; protected against unverified deletion |
| `hazard_report` | `SELECT, INSERT, UPDATE` | `SELECT` | `SELECT` | **DELETE DENIED** to prevent destruction of legal incident records |
| `assignment` | `SELECT, INSERT, UPDATE, DELETE` | `SELECT` | `SELECT` | Technicians may be reassigned; allows unlinking assignments |
| `report_status_history`| `SELECT, INSERT` | `SELECT` | `SELECT` | **UPDATE & DELETE DENIED** (Immutable chronological audit log) |
| `maintenance_action` | `SELECT, INSERT` | `SELECT` | `SELECT` | **UPDATE & DELETE DENIED** (Immutable technician action log) |
| `attachment` | `SELECT, INSERT, DELETE` | `SELECT` | `SELECT` | Allows unlinking invalid or oversized uploaded evidence files |
| **All Sequences (9)** | `USAGE, SELECT` | Denied | `SELECT` | Runtime requires USAGE/SELECT for auto-incrementing SERIAL keys |

---

## 5. Verification Test Suite: Permitted vs. Denied Operations

To confirm that the access-control model functions identically in the restored test database as in production:

### Test Case 1: Runtime Insertion of Status History (Permitted)
```sql
\c grp07_campussafedb_activity6_restore_test campussafe_app
INSERT INTO report_status_history (report_id, changed_by_user_id, status, notes)
VALUES (1, 1, 'Submitted', 'Access control restoration verification');
```
*Expected Result:* `INSERT 0 1` (Operation Allowed).

### Test Case 2: Runtime Deletion of Hazard Report (Denied)
```sql
\c grp07_campussafedb_activity6_restore_test campussafe_app
DELETE FROM hazard_report WHERE report_id = 1;
```
*Expected Result:* `ERROR: permission denied for table hazard_report` (Operation Blocked).

### Test Case 3: Auditor Modification of Incident Priority (Denied)
```sql
\c grp07_campussafedb_activity6_restore_test campussafe_report
UPDATE hazard_report SET priority = 'Critical' WHERE report_id = 1;
```
*Expected Result:* `ERROR: permission denied for table hazard_report` (Operation Blocked).

### Test Case 4: Auditor Querying User Credentials (Denied)
```sql
\c grp07_campussafedb_activity6_restore_test campussafe_report
SELECT user_id, username, password_hash FROM app_user;
```
*Expected Result:* `ERROR: permission denied for table app_user` (Operation Blocked).

