# Activity 5 Evidence Checklist & Capture Guide
## BoardTrack – Boarding House & Rental Management System

This checklist guides the Database Administrator, QA tester, or student in capturing all required visual screenshots and console logs for the COMP 018 Activity 5 academic submission.

---

## Evidence Mapping Matrix

| # | Evidence Item | Suggested Filename | What Must Be Visible | Associated SQL Command / Script | Supporting Report Section | Status |
|---|---|---|---|---|---|---|
| **1** | PostgreSQL Version & Client | `A5-01_PostgreSQL_Version.png` | `psql (PostgreSQL) 18.6` output and server version string | `psql --version` and `SELECT version();` | Section A (Health Check #1, #2) | `BLOCKED` (Pending interactive psql run) |
| **2** | Database Health Check Output | `A5-02_Database_Health_Check.png` | Object counts (7 base tables, 12 indexes, 1 view, 2 triggers, 2 extensions), database size | `sql/01_database_health_check.sql` | Section A: Database Health Check | `BLOCKED` (Pending interactive psql run) |
| **3** | Active Sessions & Contention | `A5-03_Active_Sessions_Activity.png` | `pg_stat_activity` session list, states (active/idle), wait events, 0 lock blockers | `sql/02_activity_monitoring.sql` | Section B: Database Activity Monitoring | `BLOCKED` (Pending interactive psql run) |
| **4** | Table Statistics & Dead Tuples | `A5-04_Table_Statistics_Bloat.png` | Table names, live tuples, dead tuples, sequential scans, index scans, bloat % | `sql/03_table_statistics.sql` | Section B & C: Table Statistics & Bloat | `BLOCKED` (Pending interactive psql run) |
| **5** | Database Roles & Permissions | `A5-05_Database_Role_Privileges.png` | Intended roles (`boardtrack_owner`, `app_runtime_grp`, `boardtrack_app`) vs actual catalog | Catalog query on `pg_roles` and `pg_auth_members` | Section 5 & Part A: Role Alignment | `BLOCKED` (Pending interactive psql run) |
| **6** | ANALYZE Execution Results | `A5-06_Analyze_Execution.png` | Output of `ANALYZE;` command updating PostgreSQL cost-based statistics | `ANALYZE;` in `sql/06_maintenance_operations.sql` | Section C: Database Maintenance Using ANALYZE | `BLOCKED` (Pending interactive psql run) |
| **7** | VACUUM Execution Results | `A5-07_Vacuum_Execution.png` | Output of `VACUUM (VERBOSE, ANALYZE)` on `property`, `room`, `lease`, `payment`, etc. | `sql/06_maintenance_operations.sql` | Section D: Database Maintenance Using VACUUM | `BLOCKED` (Pending interactive psql run) |
| **8** | Index Monitoring & Audit | `A5-08_Index_Inventory_Scans.png` | Complete index table: `idx_lease_room`, `idx_lease_tenant`, `idx_payment_lease`, `ex_lease_no_overlap` | `sql/04_index_monitoring.sql` | Section E: Index Monitoring | `BLOCKED` (Pending interactive psql run) |
| **9** | Query 1 Execution Plan | `A5-09_Query1_Lease_History_Plan.png` | `EXPLAIN` and `EXPLAIN (ANALYZE, BUFFERS)` output for 3-table join (`lease`, `tenant`, `room`) | Query 1 in `sql/05_query_performance.sql` | Section F: Query Performance (Query 1) | `BLOCKED` (Pending interactive psql run) |
| **10** | Query 2 Execution Plan | `A5-10_Query2_Payment_History_Plan.png` | `EXPLAIN` and `EXPLAIN (ANALYZE, BUFFERS)` for payments ordered by date | Query 2 in `sql/05_query_performance.sql` | Section F: Query Performance (Query 2) | `BLOCKED` (Pending interactive psql run) |
| **11** | Query 3 Execution Plan | `A5-11_Query3_Lease_Summary_Plan.png` | `EXPLAIN` and `EXPLAIN (ANALYZE, BUFFERS)` for reporting view `v_lease_summary` | Query 3 in `sql/05_query_performance.sql` | Section F: Query Performance (Query 3) | `BLOCKED` (Pending interactive psql run) |
| **12** | Before & After Maintenance | `A5-12_Before_After_Comparison.png` | Tabular comparison of `last_vacuum`, `last_analyze`, dead tuples, and query timing | `db-maintenance/before-after-comparison.md` | Section 7: Before-and-After Comparison | `BLOCKED` (Pending interactive psql run) |

---

## Detailed Step-by-Step Capture Instructions

### Step 1: Health Check and Engine Version
1. Open PowerShell or Command Prompt.
2. Execute:
   ```powershell
   .\db-maintenance\run-activity5.ps1 -Step health -Database boardtrack_db -User postgres
   ```
3. Capture the console terminal showing:
   - Connected user and database
   - Server version (`PostgreSQL 18.6`)
   - 7 base tables (`app_user`, `lease`, `payment`, `property`, `room`, `tenant`, `utility_bill`)
   - 2 extensions (`btree_gist`, `pgcrypto`)
4. Save screenshot as `evidence/A5-01_Database_Health_Check.png`.

### Step 2: Activity and Session Monitoring
1. Execute:
   ```powershell
   .\db-maintenance\run-activity5.ps1 -Step activity -Database boardtrack_db -User postgres
   ```
2. Verify that `pg_stat_activity` outputs connected sessions, states, and confirms 0 blocking locks or unhandled contention.
3. Save screenshot as `evidence/A5-03_Active_Sessions_Activity.png`.

### Step 3: Index Inventory and Scan Audit
1. Execute:
   ```powershell
   .\db-maintenance\run-activity5.ps1 -Step index -Database boardtrack_db -User postgres
   ```
2. Confirm the display of:
   - `idx_lease_room`, `idx_lease_tenant`, `idx_payment_lease`, `idx_utility_lease`
   - Primary key and unique indexes
   - GiST exclusion constraint index `ex_lease_no_overlap`
3. Save screenshot as `evidence/A5-08_Index_Inventory_Scans.png`.

### Step 4: Query Plans and Execution Metrics
1. Execute:
   ```powershell
   .\db-maintenance\run-activity5.ps1 -Step query -Database boardtrack_db -User postgres
   ```
2. Capture the cost estimates and actual runtimes (planning time, execution time, buffers read/hit) for Query 1, Query 2, and Query 3.
3. Save screenshots as `evidence/A5-09_Query1_Lease_History_Plan.png`, `A5-10_Query2_Payment_History_Plan.png`, and `A5-11_Query3_Lease_Summary_Plan.png`.

### Step 5: Routine Maintenance (ANALYZE and VACUUM)
1. Execute:
   ```powershell
   .\db-maintenance\run-activity5.ps1 -Step maintain -Database boardtrack_db -User postgres
   ```
2. Verify that:
   - `last_analyze_before` and `last_vacuum_before` are updated to fresh post-maintenance timestamps.
   - Any dead tuples in application tables are reclaimed.
   - No error occurs and commands succeed cleanly.
3. Save screenshot as `evidence/A5-06_Analyze_and_Vacuum_Maintenance.png`.
