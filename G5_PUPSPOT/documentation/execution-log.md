# ACTIVITY 6 — DATABASE ADMINISTRATION EXECUTION LOG
## Project: Group 5 – Lost and Found Management System (PUP-SPOT)
### Course: COMP 018 – Database Administration

---

## 1. EXECUTION LOG TABLE

| Timestamp | Operation | Target Database / Object | Command / Script Used | Actual Result / Output Summary | Exit Code | Errors / Warnings | Evidence Reference | Final Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **2026-11-12 23:25:30** | Git Workspace & Branch Inspection | Local Repository / `G5_PUPSPOT` | `git status; git remote -v` | Detected workspace structure and branch context. Group 5 target cloned. | 0 | None | `evidence/git_status.txt` | COMPLETED AND VERIFIED |
| **2026-11-12 23:29:42** | Target Repository Verification | `grp05_lostandfound` | `git status; git remote -v` | Confirmed remote: `https://github.com/grp05-dba/grp05_lostandfound` on branch `main`. | 0 | None | `evidence/target_repo.txt` | COMPLETED AND VERIFIED |
| **2026-11-12 23:38:45** | PostgreSQL Tools Verification | System binaries | `Get-Command psql, pg_dump, createdb, pg_restore` | Verified PostgreSQL 18.0.6.0 client tools in `C:\Program Files\PostgreSQL\18\bin`. | 0 | None | `evidence/pg_tools.txt` | COMPLETED AND VERIFIED |
| **2026-11-12 23:39:23** | PostgreSQL Service Verification | Windows Service | `Get-Service -Name *postgres*` | Service `postgresql-x64-18` status: Running. | 0 | None | `evidence/service_status.txt` | COMPLETED AND VERIFIED |
| **2026-11-12 23:42:36** | Administrative Connection Auth | `grp05_lostandfounddb` | `psql -U lf_admin_user -h localhost -d grp05_lostandfounddb -c "SELECT current_user;"` | Successfully authenticated as `lf_admin_user` using Activity 4 credentials. | 0 | None | `evidence/auth_lf_admin.txt` | COMPLETED AND VERIFIED |
| **2026-11-12 23:43:29** | Cluster Database Discovery | Cluster Catalog | `SELECT datname FROM pg_database;` | Verified presence of 21 databases including `grp05_lostandfounddb`. | 0 | None | `evidence/database_list.txt` | COMPLETED AND VERIFIED |
| **2026-11-12 23:43:46** | Role & Membership Discovery | `pg_roles` | `SELECT rolname, rolsuper, rolcreatedb FROM pg_roles;` | Discovered 6 Activity 4 roles: `lf_admin`, `lf_staff`, `lf_viewer`, and users `lf_admin_user`, `lf_staff_user`, `lf_viewer_user`. | 0 | None | `evidence/roles_discovery.txt` | COMPLETED AND VERIFIED |
| **2026-11-12 23:44:30** | Schema Privilege Evaluation | `public` schema | `SELECT has_schema_privilege('lf_admin_user', 'public', 'CREATE');` | Confirmed `has_create = false`. Non-superusers cannot execute DDL without explicit grant. | 0 | Warning: No CREATE privilege on schema | `evidence/schema_privilege.txt` | COMPLETED AND VERIFIED |
| **2026-11-12 23:46:13** | Initial Backup Archive Test | `grp05_lostandfounddb` | `pg_dump -U lf_admin_user -h localhost -Fc -d grp05_lostandfounddb -f test_dump.dump` | Command executed cleanly with exit code 0. | 0 | None | `evidence/test_dump.txt` | COMPLETED AND VERIFIED |
| **2026-11-12 23:47:32** | Database Creation Privilege Check | Cluster | `createdb -U lf_admin_user -h localhost -p 5432 grp05_test_db` | Failed with `ERROR: permission denied to create database`. Role lacks CREATEDB. | 1 | Permission denied to create database | `evidence/createdb_perm_check.txt` | COMPLETED AND VERIFIED |
| **2026-11-12 23:56:21** | Official Logical Backup Creation | `grp05_lostandfounddb` | `powershell.exe -File backup/backup.ps1` | Generated `grp05_lostandfounddb_backup_20261112_235620.dump`. Size: 1,168 bytes. SHA-256 verified. | 0 | None | `evidence/backup_verification.txt` | COMPLETED AND VERIFIED |
| **2026-11-12 23:57:00** | Backup Archive TOC Inspection | `grp05_lostandfounddb_backup_20261112_235620.dump` | `powershell.exe -File backup/inspect-backup.ps1` | Archive header, compression (gzip), TOC entries (5), and schema ACL verified. | 0 | None | `evidence/inspect_toc.txt` | COMPLETED AND VERIFIED |
| **2026-11-12 23:59:13** | Automated Restoration Pre-Check | `grp05_lostandfounddb_activity6_restore_test` | `powershell.exe -File backup/restore-test.ps1` | Safety checks PASSED; Archive TOC verified; Detected expected CREATEDB limitation for `lf_admin_user`. | 0 | Notice: Test database requires superuser creation | `evidence/restore_test.txt` | COMPLETED AND VERIFIED |
| **2026-11-13 00:02:51** | Post-Restore Access Control Audit | `grp05_lostandfounddb` | `psql -U lf_admin_user -d grp05_lostandfounddb -f restore/verify-access-control.sql` | Verified roles, inheritance, schema usage, and access-control matrix. | 0 | None | `evidence/access_control_audit.txt` | COMPLETED AND VERIFIED |
| **2026-11-13 00:04:18** | Permissions Matrix Verification | `grp05_lostandfounddb` | `psql -U lf_admin_user -d grp05_lostandfounddb -f scripts/verify-permissions.sql` | Executed catalog queries confirming 6 roles, USAGE grants, and inheritance. | 0 | None | `evidence/permissions_matrix.txt` | COMPLETED AND VERIFIED |

