# PostgreSQL DBA Troubleshooting SQL Toolkit

**Course:** COMP 018 — Database Administration  
**Project:** Group 12 — iBarangay: Barangay Document Request System  
**PostgreSQL Version:** 14+ / 18.6  
**Security Policy:** Read-Only Diagnostic Scripts (Non-Destructive)  

---

## 1. Overview and Operational Philosophy

This directory contains production-grade PostgreSQL diagnostic scripts designed to support rapid, disciplined incident investigation during database administration duties. All queries in this toolkit are strictly read-only and inspect PostgreSQL system catalogs (`pg_catalog`) and standard information schema views (`information_schema`).

These scripts adhere to the **8-Step DBA Troubleshooting Workflow**:
`Observe` $\rightarrow$ `Verify` $\rightarrow$ `Hypothesize` $\rightarrow$ `Test` $\rightarrow$ `Act` $\rightarrow$ `Verify` $\rightarrow$ `Document` $\rightarrow$ `Prevent`.

---

## 2. Diagnostic Toolkit Index

| Script Name | Functional Category | Primary Catalogs Inspected | Key Diagnostic Capabilities |
|---|---|---|---|
| `01_connection_and_database.sql` | Connection & Database Profile | `pg_database`, `pg_stat_activity`, `pg_settings` | Active client connections, connection states, database physical size, transaction age, and server parameters. |
| `02_schema_and_catalog.sql` | Schema & Constraint Integrity | `pg_class`, `pg_constraint`, `pg_attribute`, `information_schema.tables` | Table definitions, primary keys, foreign key delete rules (`CASCADE` vs `RESTRICT`), check constraints, and column nullability. |
| `03_access_control_and_roles.sql` | Access Control & RBAC | `pg_roles`, `pg_auth_members`, `information_schema.table_privileges`, `column_privileges` | Role attributes (`rolsuper`, `rolcanlogin`), group memberships, table-level grants, and column-level update/insert privileges. |
| `04_performance_and_maintenance.sql` | Performance & Table Maintenance | `pg_stat_user_tables`, `pg_statio_user_tables`, `pg_stat_user_indexes` | Buffer cache hit ratio, dead tuple accumulation, table bloat, last vacuum/analyze timestamps, index scan efficiency. |
| `05_backup_and_recovery.sql` | Backup, Sequences & Recovery | `pg_sequences`, `pg_depend`, `pg_stat_archiver` | Identity sequence synchronization vs table `MAX(id)`, WAL archiving activity, and object count verification. |

---

## 3. Execution Instructions

Execute any diagnostic script via `psql`:

```bash
# Example: Inspecting access control and role grants
psql -U ibarangay_dba -h localhost -p 5432 -d PPGG_projectdb -f 03_access_control_and_roles.sql

# Or inside an active psql session:
\i 03_access_control_and_roles.sql
```
