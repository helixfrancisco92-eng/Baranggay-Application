# CAMPUSAFE Baseline Comparison Report: Approved Design vs. Implementation

**Auditing Group:** Group 12 — iBarangay  
**Target Project:** Group 7 — CampusSafe: Campus Hazard and Safety Reporting System  
**Target Database:** `grp07_campussafedb`  
**Inspection Date:** November 7, 2026  
**Assessment Phase:** Phase A — Peer Baseline Comparison  

---

## 1. Purpose and Methodology

This baseline comparison rigorously evaluates Group 7's implemented database schema, access control definitions, maintenance routines, and backup procedures against their documented architectural proposals and activity reports (Activities 3 through 6).

The evaluation methodology compares:
1. **Documented Design:** The specifications laid out in `docs/user-roles.md`, `README.md`, `HOW_IT_WORKS.md`, and the Activity 3–6 progress documentation in `progress-report/`.
2. **Actual Implementation:** The physical DDL scripts (`database/01_schema.sql`), privilege assignments (`database/03_roles_and_privileges.sql`), seed data (`database/02_seed.sql`), and model queries (`src/models/*.php`).
3. **Variance & Risk Analysis:** Discrepancies that introduce operational risks, data anomalies, security escalations, or compliance violations.

---

## 2. Detailed Dimension-by-Dimension Comparison

### 2.1 Schema Architecture & Relational Constraints (Activity 3)

| Architectural Component | Documented Approved Design | Actual Physical Implementation | Variance Classification | Detailed Risk & Impact Assessment |
|---|---|---|:---:|---|
| **Child Record Retention** | Audit records and historical repair logs must be permanently preserved for campus safety compliance and liability tracking. | `assignment`, `report_status_history`, `maintenance_action`, and `attachment` all reference `hazard_report(report_id)` with `ON DELETE CASCADE`. | **CONFIRMED FLAW (G07-F2)** | Deleting or archiving a parent hazard report automatically cascades and permanently erases the entire immutable audit log, technician repair records, and evidence metadata. |
| **Physical Location Master** | Each distinct physical location on campus must be uniquely identifiable to avoid duplicate ticket routing. | `campus_location` defines surrogate primary key `location_id SERIAL PRIMARY KEY`, but lacks a composite `UNIQUE` constraint on `(building, floor, room_area)`. | **CONFIRMED FLAW (G07-F5)** | Multiple identical location entries (e.g., three separate records for "Science Complex", "3rd Floor", "Lab 301") can be created, fragmenting incident analytics. |
| **Hazard Report Verification** | Reports must be verified and prioritized by safety administrators before technician dispatch. | Column `priority` is declared as nullable `VARCHAR(20) CHECK (priority IN ('Low', 'Medium', 'High', 'Critical'))`. No constraint requires priority on verified reports. | **CONFIRMED FLAW (G07-F5)** | Reports can transition to status `'Verified'` with `priority IS NULL`, preventing maintenance dispatchers from sorting work orders by urgency. |
| **Status Transition Auditing** | All report status changes must be logged immutably with timestamp and changing user. | Table `report_status_history` exists, but zero database triggers are defined on `hazard_report`. Logging depends solely on application PHP controller code. | **CONFIRMED FLAW (G07-F3)** | Direct SQL updates, batch imports, or database maintenance operations bypass status logging completely, creating untracked state transitions. |
| **Verification Consistency** | A report cannot be marked verified without recording who verified it and when. | Implemented via table check constraint `chk_verified_pair`: `(verified_by_user_id IS NULL AND verified_at IS NULL) OR (verified_by_user_id IS NOT NULL AND verified_at IS NOT NULL)`. | **CONFORMS** | Properly guarantees relational consistency for administrative verification pairs at the engine level. |
| **Resolution Timestamps** | Reports marked Resolved or Closed must record resolution timestamps. | Implemented via table check constraint `chk_resolved_has_date`: `status NOT IN ('Resolved', 'Closed') OR resolved_at IS NOT NULL`. | **CONFORMS** | Robustly enforces progressive completion of lifecycle timestamps. |

---

### 2.2 Access Control & Role Privileges (Activity 4)

| Role / Security Dimension | Documented Access-Control Policy | Actual Granted Privileges | Variance Classification | Detailed Risk & Impact Assessment |
|---|---|---|:---:|---|
| **Runtime Role Privileges on `app_user`** | Runtime service account must update standard operational data while strictly restricting administrative account management and role modifications. | `database/03_roles_and_privileges.sql` lines 64–65 executes `GRANT UPDATE ON hazard_report, assignment, app_user, hazard_category, campus_location TO app_runtime_grp;`. | **CONFIRMED FLAW (G07-F1)** | Full table-level `UPDATE` grants write access to sensitive columns `role_id` and `account_status`. Any compromised application endpoint can elevate accounts to Administrator. |
| **Auditor / Read-Only Role** | Auditor needs complete read-only visibility into campus hazard reports and actions, but must be barred from user authentication secrets. | `GRANT SELECT ON hazard_report, hazard_category, campus_location, report_status_history, maintenance_action, assignment, attachment TO app_readonly_grp;`. No access granted to `app_user`. | **CONFORMS** | Exemplary implementation of credential isolation; prevents exposure of bcrypt password hashes to compliance auditors. |
| **Public Schema Lockdown** | Default public permissions must be revoked to prevent unauthorized access. | Revokes all database access and schema creation from `PUBLIC`: `REVOKE ALL ON DATABASE grp07_campussafedb FROM PUBLIC; REVOKE CREATE ON SCHEMA public FROM PUBLIC;`. | **CONFORMS** | Adheres to strict PostgreSQL defense-in-depth principles. |
| **Sequence Identity Grants** | Auto-incrementing SERIAL primary keys require sequence permissions for record creation. | `GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_runtime_grp;`. Default privileges also configured. | **CONFORMS** | Allows standard runtime insertions without generating permission faults on sequences. |

---

### 2.3 Performance, Indexing & Maintenance (Activity 5)

| Maintenance Dimension | Documented Standard | Actual Implementation | Variance Classification | Detailed Risk & Impact Assessment |
|---|---|---|:---:|---|
| **Foreign Key Indexing** | Foreign keys must be indexed to eliminate sequential scans during relational joins and cascade checks. | Ten explicit B-tree indexes defined on foreign keys (`idx_report_reporter`, `idx_report_location`, `idx_assign_report`, etc.). | **CONFORMS** | Excellent performance baseline; ensures join queries between reports, users, and locations run in sub-millisecond time. |
| **Dead Tuple Accumulation** | High-churn tables experiencing continuous status updates must undergo routine vacuuming. | Manual `VACUUM (VERBOSE, ANALYZE)` routines documented in Activity 5 report, but no automated maintenance cron/daemon configured. | **RISK** | Prolonged operation without scheduled autovacuum tuning or maintenance tasks leads to table bloat in `hazard_report` and stale query planner statistics. |
| **Status Queue Indexing** | Dashboard queries frequently filter for unassigned or pending hazard reports. | Table `hazard_report` indexes `status` (`idx_report_status`), but lacks a partial index (e.g. `WHERE status IN ('Submitted', 'Verified')`). | **RISK** | As closed reports accumulate over years, indexing the entire status column causes index bloat compared to an optimal partial index on active tickets. |

---

### 2.4 Backup, Recovery & Disaster Readiness (Activity 6)

| Recovery Dimension | Documented Recovery Policy | Actual Implementation | Variance Classification | Detailed Risk & Impact Assessment |
|---|---|---|:---:|---|
| **Backup Operator Privileges** | Automated backups must be executed by a non-superuser account with read-only access to all database objects. | `campussafe_backup` granted `SELECT` on all existing tables/sequences, but lacks `pg_read_all_data` pre-defined role or schema-level `USAGE` on non-public schemas. | **CONFIRMED FLAW / RISK (G07-F4)** | Adding new tables or schemas without manual privilege refresh causes automated `pg_dump` jobs to fail with exit code 1 (`permission denied`). |
| **Cluster Roles & Passwords** | Disaster recovery must enable bare-metal server restoration. | `01_backup.ps1` runs `pg_dump -Fc` on `grp07_campussafedb` only. It does not export global roles (`pg_dumpall --globals-only`). | **CONFIRMED RISK (G07-F4)** | In a disaster recovery failover to a new PostgreSQL server, restoring the database dump fails during object ownership and privilege assignment because roles do not exist. |
| **Physical File Attachments** | Photo evidence attached to hazard reports must be recoverable alongside the relational data. | Database stores metadata in `attachment`, but binary photo files reside in host directory `uploads/`. No backup script backs up `uploads/`. | **CONFIRMED RISK** | Restoring the PostgreSQL backup recovers database rows, but leaves all uploaded incident photographs broken (HTTP 404) if the server disk fails. |

---

## 3. Summary of Identified Findings for Incident Formulation

From the baseline comparison above, Group 12 extracts the following five primary flaws and risks to formulate the official Flaw Register (`G07-F1` through `G07-F5`):

1. **G07-F1 (Activity 4 — Confirmed Flaw):** Excessive Table-Level `UPDATE` Privileges on `app_user` for Runtime Account.
2. **G07-F2 (Activity 3/4 — Confirmed Flaw):** `ON DELETE CASCADE` Foreign Keys Erasing Compliance Audit & Repair Trails.
3. **G07-F3 (Activity 3/5 — Confirmed Flaw):** Missing Database Triggers for Automated Status History Logging.
4. **G07-F4 (Activity 6 — Confirmed Risk / Flaw):** Backup Operator Role Privilege Fragility & Missing Global Cluster Role Archiving.
5. **G07-F5 (Activity 3/5 — Confirmed Flaw):** Missing Candidate Key Uniqueness on Physical Locations & Unenforced Verification Priority.
