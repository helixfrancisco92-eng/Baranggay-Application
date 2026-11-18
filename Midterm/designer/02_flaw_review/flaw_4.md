# FLAW #4: Backup Operator Role Privilege Fragility & Missing Global Cluster Role Archiving

**Flaw ID:** G07-F4  
**Project Owner:** Group 7 – CAMPUSAFE  
**Reported By:** Group 12 – iBarangay  
**Affected Area:** Backup, Recovery & Disaster Readiness  
**Related Activity:** Activity 6 (Backup and Recovery Procedures)  

---

### Description

In `database/03_roles_and_privileges.sql` (lines 80–97), Group 7 configured a dedicated non-superuser backup role: `app_backup_grp` and login account `campussafe_backup`. The permissions granted are:
```sql
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_backup_grp;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO app_backup_grp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO app_backup_grp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO app_backup_grp;
```

While this follows least-privilege principles, two critical technical deficiencies exist:
1. **Privilege Fragility for Non-Superuser Logical Dumps:** Group 7 did not grant the pre-defined PostgreSQL system role `pg_read_all_data` to `app_backup_grp`. In modern PostgreSQL (v14+), executing `pg_dump -Fc` under a non-superuser account requires complete read access across all existing and future database tables, views, large objects, and schemas. If a future migration or administrator creates a new table or view under a different owner (e.g. `campussafe_owner` vs `postgres`) without explicitly running `ALTER DEFAULT PRIVILEGES` for that creator role, `campussafe_backup` is denied read access on that table. During scheduled nightly execution, `pg_dump` aborts midway with `pg_dump: error: query failed: ERROR: permission denied for table ...`, generating a corrupted or 0-byte dump archive.
2. **Omission of Global Cluster Roles (`pg_dumpall --globals-only`):** Group 7's automated backup scripts (`01_backup.ps1` and `01_backup.sh`) only execute database-level logical dumps (`pg_dump -Fc -d grp07_campussafedb`). PostgreSQL `pg_dump` exports only schema objects within that specific database; it **does not** export cluster-wide roles, password hashes, or role memberships stored in the global catalog `pg_authid`. In a disaster recovery scenario requiring bare-metal restoration onto a newly provisioned PostgreSQL instance, `pg_restore` throws hundreds of fatal errors during object ownership and privilege assignment (`ERROR: role "app_runtime_grp" does not exist`, `ERROR: role "campussafe_app" does not exist`).

---

### Evidence

- **Repository File:** `grp07-campussafe/database/03_roles_and_privileges.sql` (Lines 80–97)
- **Repository File:** `Baranggay-Application/Activity 6/G7_CAMPUSAFE/campusafe/01_backup.ps1` (Line 86)
- **Actual Database Object:** Role `app_backup_grp`, `campussafe_backup`, and PostgreSQL catalog `pg_roles`.
- **SQL Command / Inspection Method:**
  ```sql
  SELECT r.rolname, r.rolsuper, r.rolcanlogin,
         ARRAY(SELECT b.rolname FROM pg_auth_members m JOIN pg_roles b ON (m.roleid = b.oid) WHERE m.member = r.oid) as member_of
  FROM pg_roles r 
  WHERE r.rolname IN ('app_backup_grp', 'campussafe_backup');
  ```
- **Actual Result:**
  ```
       rolname       | rolsuper | rolcanlogin |    member_of     
  -------------------+----------+-------------+------------------
   app_backup_grp    | f        | f           | {}
   campussafe_backup | f        | t           | {app_backup_grp}
  (2 rows)
  ```
  *(Neither role is a member of `pg_read_all_data` or `pg_read_all_settings`).*
- **Disaster Recovery Observation:** Restoring `grp07_campussafedb` onto an empty PostgreSQL cluster produces:
  `pg_restore: error: could not execute query: ERROR: role "campussafe_app" does not exist`
- **Screenshot / Evidence File:** Referenced in `midterm/evidence/designer/G07_F4_backup_privilege_evidence.txt` and Activity 6 Documentation.
- **Baseline Comparison:** `progress-report/ACTIVITY_06_BACKUP_RECOVERY_REPORT.md` claims complete system recoverability. However, the documented procedures assume roles already exist on the target cluster, omitting automated role catalog export.

---

### Impact

- **Disaster Recovery RTO / Availability (High):** In a catastrophic hardware crash where the server must be rebuilt from scratch, database restoration fails or stalls indefinitely until DBAs manually reverse-engineer and recreate all 6 roles, memberships, and passwords.
- **Backup Invalidation Risk:** If permissions on any operational table are modified, nightly `pg_dump` tasks silently fail or produce incomplete dumps, leaving the institution without valid recovery snapshots.

---

### Severity

**Risk / Medium** (Architectural Risk & Flaw)

---

### Recommended Fix

1. Grant the PostgreSQL 14+ pre-defined administrative role `pg_read_all_data` to `app_backup_grp`, providing comprehensive, read-only visibility across all current and future relations regardless of schema or table owner.
2. Update the automated backup routine to export global roles and passwords prior to executing the database snapshot using `pg_dumpall --globals-only`.

```sql
-- Step 1: Assign pre-defined read-all role to backup group
GRANT pg_read_all_data TO app_backup_grp;
GRANT pg_read_all_settings TO app_backup_grp;
```

```powershell
# Step 2: Augment automated backup script (PowerShell)
# Export global roles, users, and passwords first
pg_dumpall.exe -U postgres -h localhost -p 5432 --globals-only -f "backups/globals_cluster_roles.sql"

# Export database custom archive
pg_dump.exe -U campussafe_backup -h localhost -p 5432 -Fc -d grp07_campussafedb -f "backups/grp07_campussafedb.dump"
```

---

### Verification

1. **Verify Role Membership:**
   ```sql
   SELECT rolname FROM pg_roles WHERE pg_has_role('campussafe_backup', oid, 'member');
   ```
   *Expected Result:* Includes `pg_read_all_data` and `app_backup_grp`.
2. **Verify Backup Execution:**
   Execute `pg_dump -U campussafe_backup -Fc -f test.dump grp07_campussafedb`; exit code is `0`.
3. **Verify Table of Contents:**
   Execute `pg_restore --list test.dump`; confirms all 9 tables, indexes, constraints, and sequences are captured.
4. **Verify Bare-Metal Restore Protocol:**
   Restoring `globals_cluster_roles.sql` followed by `test.dump` on a clean PostgreSQL cluster succeeds with zero "role does not exist" errors.
