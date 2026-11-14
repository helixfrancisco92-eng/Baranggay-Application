# COMP 018 — Activity 6 Implementation Summary
## Database Backup, Restoration, and Recovery Lifecycle
### Project: Park-It Database Management System (`grp_parkitdb`)

---

## 📌 Implementation Status Dashboard

| Activity 6 Phase | Deliverable / Task | Target Implementation | Status |
|---|---|---|---|
| **Phase 1** | Repository Inspection | Schema, tables, roles, and seed analysis | **COMPLETED** |
| **Phase 2** | Directory Structure Creation | `db-backup-recovery/` layout | **COMPLETED** |
| **Phase 3** | Part A: Backup Planning | `01-backup-plan.md` | **COMPLETED** |
| **Phase 4** | Part B: Backup Creation Script | `02-backup.sh` | **COMPLETED** |
| **Phase 5** | Part B: Backup Archive Inspection | `03-inspect-backup.sh` | **COMPLETED** |
| **Phase 6** | Part C: Test Database Restoration | `04-restore-test.sh` | **COMPLETED** |
| **Phase 7** | Part C: Restoration Verification | `05-verify-restoration.sql` | **COMPLETED** |
| **Phase 8** | Part C: Access Control Verification | `06-verify-access-control.sql` | **COMPLETED** |
| **Phase 9** | Part D: Controlled Recovery Simulation | `07-recovery-simulation.sql` | **COMPLETED** |
| **Phase 10** | Part E: Academic Recovery Report | `08-recovery-report.md` | **COMPLETED** |
| **Phase 11** | Part F: Evidence Checklist & Summary | `09-evidence-checklist.md`, `10-activity6-summary.md` | **COMPLETED** |
| **Phase 12** | Tracking Log Template | `templates/activity6-log-template.csv` | **COMPLETED** |
| **Phase 13** | Progress Documentation Template | `templates/progress-documentation-template.md` | **COMPLETED** |
| **Phase 14** | Git & Security Configuration | `.gitignore` rule update | **COMPLETED** |
| **Phase 15** | Validation & Quality Assurance | Syntax check, schema consistency, safety audits | **COMPLETED** |

---

## 🔍 Detailed Requirement-by-Requirement Audit

### Part A: Backup Planning
- [x] **Database Identification:** Identified `grp_parkitdb` on PostgreSQL 18.6 with host `localhost:5432` and schema `public`.
- [x] **Database Objects Inventory:** Audited all 5 tables (`parking_zone`, `vehicle`, `staff_user`, `transaction`, `payment`), 5 sequences, and relational constraints.
- [x] **Backup Method & Justification:** Selected `pg_dump` with custom archive format (`-Fc`), justifying compression, TOC inspection, selective restoration, and multi-threading.
- [x] **Utility Syntax & Parameters:** Defined `pg_dump -U postgres -h localhost -p 5432 -Fc -b -v -d grp_parkitdb -f <filename>.dump`.
- [x] **Storage Location & Security:** Segregated backup directory to `db-backup-recovery/backups/`, outside XAMPP webroot.
- [x] **Authorized Roles:** Distinguished superuser `postgres` for backup execution from runtime least-privilege role `parkit_app`.
- [x] **Multi-tier Verification:** Defined 5-tier verification gate (exit code, non-zero byte size, SHA-256 hash, TOC listing, test restoration).
- [x] **Operational Policies:** Formulated proposed daily GFS backup schedule, retention rules, RPO (1 hr commercial / 24 hr logical), and RTO (30 minutes).

### Part B: Backup Creation & Archive Inspection
- [x] **Automated Backup Script (`02-backup.sh`):**
  - Checks `pg_dump` binary availability in PATH and standard Windows PostgreSQL directories.
  - Interactive parameter prompts with sensible defaults (`grp_parkitdb`, `localhost`, `5432`, `postgres`).
  - Secure, silent password acquisition (zero hardcoded secrets).
  - Protected backup directory creation with restricted permissions.
  - Custom format archive generation (`-Fc`).
  - Timestamped output filename (`grp_parkitdb_YYYYMMDD_HHMMSS.dump`) to prevent accidental overwrite.
  - Exit code and non-zero byte size validation.
  - Automated SHA-256 checksum calculation saved to `.sha256` and logged to `backup_execution.log`.
  - Zero automatic deletion of legacy backups.
- [x] **Archive Inspection Script (`03-inspect-backup.sh`):**
  - Accepts backup path or detects canonical / latest dump file.
  - Re-computes and validates SHA-256 checksum against recorded hash.
  - Extracts and logs Table of Contents via `pg_restore --list`.
  - Explains and categorizes archive TOC objects (tables, sequences, constraints, data blocks).
  - Includes educational guidance on why backup existence does not equal restorability.

### Part C: Test Database Restoration & Verification
- [x] **Restoration Script (`04-restore-test.sh`):**
  - Verifies archive integrity before restoration.
  - Requires isolated test database (`grp_parkitdb_restore_test`).
  - **Critical Safety Guard:** Immediately aborts if target equals production database `grp_parkitdb`.
  - Never automatically drops existing databases; prompts for timestamped alternative.
  - Provisions target test database via `createdb` and executes `pg_restore`.
  - Captures execution logs and supplies explicit post-restore connection instructions.
- [x] **Restoration Verification Suite (`05-verify-restoration.sql`):**
  - **Section A:** Audits 5 core tables, 5 sequences, indexes, views (0 expected), triggers (0 expected), and schemas.
  - **Section B:** Audits record counts, seed data (`Main Parking Lot` with capacity 50, `admin`/`staff` accounts), and capacity synchronization.
  - **Section C:** Audits 5 PK constraints, 3 FK constraints (`transaction_vehicle_id_fkey`, `transaction_zone_id_fkey`, `payment_transaction_id_fkey`), unique/check constraints, and orphan record absence.
  - **Section D:** Executes realistic business queries: Live parking capacity monitor, active parking transactions join, completed settlements join, and staff directory audit with masked password hashes.
  - **Section E:** Final audit summary outputting structured pass/fail results.
- [x] **Access Control Verification Suite (`06-verify-access-control.sql`):**
  - Addresses cluster-wide nature of PostgreSQL roles.
  - Idempotently provisions Activity 4 roles `parkit_runtime_grp` (`NOLOGIN`) and `parkit_app` (`LOGIN`).
  - Audits role catalogs, inheritance, schema usage, and table grants.
  - Verifies zero `DELETE` privileges granted to runtime roles.
  - Conducts functional security testing: confirms permitted `SELECT`/`INSERT` operations and enforces blocks on `DELETE` and unauthorized `UPDATE`.

### Part D: Controlled Recovery Simulation
- [x] **Recovery Simulation (`07-recovery-simulation.sql`):**
  - **Strict Safety:** Never deletes live customer or parking records; never drops tables.
  - **Step 1:** Inserts synthetic test vehicle `SIM-RECOV-888` and transaction.
  - **Step 2:** Simulates accidental deletion and confirms record loss.
  - **Step 3:** Provides out-of-place restore instructions to `grp_parkitdb_recovery_sim`.
  - **Step 4:** Verifies data recovery principle and evaluates pre-backup vs post-backup delta loss.
  - **Step 5:** Formulates disaster recovery evaluation matrix with RPO/RTO analysis.

### Part E & F: Reporting, Templates, and Git Safety
- [x] **Complete Academic Recovery Report (`08-recovery-report.md`):** Complete 22-section report with evidence placeholders and standardized status labels.
- [x] **Evidence Checklist (`09-evidence-checklist.md`):** 18-point verification matrix with commands and capture guidelines.
- [x] **Google Sheets Log Template (`activity6-log-template.csv`):** Standard CSV import template with all 11 required columns.
- [x] **Progress Documentation Template (`progress-documentation-template.md`):** Formal academic document formatted for PDF export.
- [x] **Git Safety (`.gitignore`):** Configured to ignore all binary `.dump`, `.backup`, `.log`, and credential artifacts.

