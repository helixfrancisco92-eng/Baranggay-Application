# Evidence Checklist & Capture Guide
## COMP 018 – Database Administration | Activity 5: Section 10
**Target Project:** Restaurant Online Ordering & Table Reservation System  
**Group:** Binary Sisters (Group 10)  
**Database:** `grp_binarysisters_projectdb`  
**Evaluation Date:** 2026-11-18  

---

## 1. Overview

This checklist specifies the exact visual screenshots and command transcript files required to substantiate the Activity 5 submission. Every item maps directly to a section in the Activity 5 report, identifies the SQL script or terminal command that produces it, and outlines what must be clearly visible in the captured artifact.

> [!CAUTION]
> **Credential Protection Reminder:**
> Never capture or commit screenshots showing passwords, `.env` file contents, or connection strings containing authentication secrets. Use interactive password prompts or obscured inputs.

---

## 2. Activity 5 Evidence Capture Matrix

| # | Evidence Item | Suggested Screenshot / Log Filename | Command / Script Used | What Must Be Visible | Report Section Supported |
|---|---|---|---|---|---|
| **1** | PostgreSQL Version & Database Connection | `ev_01_pg_version_connection.png` | `psql -h localhost -p 5432 -U rors_maint -d grp_binarysisters_projectdb -c "SELECT version(); SELECT current_database(), current_user;"` | Terminal showing PostgreSQL 18.6, database `grp_binarysisters_projectdb`, and user `rors_maint`. | Part A: Health Check (§1, §2) |
| **2** | Database Health Check Output | `ev_02_database_health_check.txt` / `.png` | `psql ... -f db-maintenance/sql/01_database_health_check.sql` | Output of the 10 diagnostic checks: table counts (8), index count, extensions (`btree_gist`, `pgcrypto`), and database size. | Part A: Health Check Matrix |
| **3** | Active Session Monitoring | `ev_03_active_sessions.png` | `psql ... -f db-maintenance/sql/02_activity_monitoring.sql` | `pg_stat_activity` table listing connected backends, states (`active`, `idle`), and wait events. | Part B: Activity Monitoring |
| **4** | Table Statistics & Dead Tuples | `ev_04_table_statistics.png` | `psql ... -f db-maintenance/sql/03_table_statistics.sql` | Table listing with `n_live_tup`, `n_dead_tup`, `seq_scan`, and `idx_scan` for all 8 application tables. | Part B & C: Table Statistics |
| **5** | Database Role & Privilege Verification | `ev_05_role_verification.png` | `psql ... -c "SELECT rolname, rolconnlimit FROM pg_roles WHERE rolname LIKE 'rors_%';"` | The 5 project roles (`rors_app`, `rors_report`, `rors_maint`, `rors_backup`, `rors_dba`) with connection limits. | Activity 4 & 5 Role Alignment |
| **6** | ANALYZE Execution Results | `ev_06_analyze_execution.png` | `psql -U rors_maint ... -c "ANALYZE;"` | Successful execution message `ANALYZE` without errors or permission denials. | Part C: Maintenance (ANALYZE) |
| **7** | VACUUM Execution Results | `ev_07_vacuum_verbose.png` | `psql -U rors_maint ... -f db-maintenance/sql/06_maintenance_operations.sql` | Verbose output of `VACUUM (VERBOSE, ANALYZE)` showing pages scanned, dead tuples removed, and execution completion. | Part D: Maintenance (VACUUM) |
| **8** | Index Inventory & Usage | `ev_08_index_monitoring.png` | `psql ... -f db-maintenance/sql/04_index_monitoring.sql` | Complete list of 16+ indexes, index sizes, scan counts, and specific verification of the 6 application indexes. | Part E: Index Monitoring |
| **9** | Query 1 Plan (EXPLAIN) | `ev_09_query1_explain.png` | `psql ... -f db-maintenance/sql/05_query_performance.sql` (Section 1) | Estimated execution plan for Customer Order History showing cost and scan type. | Part F: Query Performance |
| **10** | Query 1 Plan (EXPLAIN ANALYZE) | `ev_10_query1_analyze_buffers.png` | `psql ... -f db-maintenance/sql/05_query_performance.sql` (Section 1) | Actual execution time in milliseconds (`actual time=...`), buffers hit (`Buffers: shared hit=...`), and row counts. | Part F: Query Performance |
| **11** | Query 2 Plan (EXPLAIN ANALYZE) | `ev_11_query2_reservation_plan.png`| `psql ... -f db-maintenance/sql/05_query_performance.sql` (Section 2) | Join execution plan between `reservation` and `restaurant_table`. | Part F: Query Performance |
| **12** | Before-and-After Comparison | `ev_12_before_after_comparison.png`| Comparison queries from `06_maintenance_operations.sql` | Side-by-side terminal output showing updated `last_vacuum` and `last_analyze` timestamps. | Section 6: Before & After |

---

## 3. Recommended Command to Capture All Evidence Transcripts

To automatically capture text transcripts of all SQL maintenance scripts into the `evidence/` folder:

```powershell
# Navigate to the project root
cd C:\path\to\restaurant-ordering-reservation-system

# Ensure evidence directory exists
if (-not (Test-Path "db-maintenance\evidence")) { New-Item -ItemType Directory -Force "db-maintenance\evidence" }

# Capture Health Check
psql -h localhost -p 5432 -U rors_maint -d grp_binarysisters_projectdb -f db-maintenance\sql\01_database_health_check.sql > db-maintenance\evidence\01_health_check_output.txt 2>&1

# Capture Activity Monitoring
psql -h localhost -p 5432 -U rors_maint -d grp_binarysisters_projectdb -f db-maintenance\sql\02_activity_monitoring.sql > db-maintenance\evidence\02_activity_monitoring_output.txt 2>&1

# Capture Table Statistics (Before)
psql -h localhost -p 5432 -U rors_maint -d grp_binarysisters_projectdb -f db-maintenance\sql\03_table_statistics.sql > db-maintenance\evidence\03_table_statistics_before.txt 2>&1

# Capture Index Monitoring
psql -h localhost -p 5432 -U rors_maint -d grp_binarysisters_projectdb -f db-maintenance\sql\04_index_monitoring.sql > db-maintenance\evidence\04_index_monitoring_output.txt 2>&1

# Capture Maintenance Operations (VACUUM & ANALYZE)
psql -h localhost -p 5432 -U rors_maint -d grp_binarysisters_projectdb -f db-maintenance\sql\06_maintenance_operations.sql > db-maintenance\evidence\06_maintenance_operations_output.txt 2>&1

# Capture Query Performance
psql -h localhost -p 5432 -U rors_report -d grp_binarysisters_projectdb -f db-maintenance\sql\05_query_performance.sql > db-maintenance\evidence\05_query_performance_output.txt 2>&1

Write-Host "All evidence transcripts successfully captured to db-maintenance\evidence\" -ForegroundColor Green
```
