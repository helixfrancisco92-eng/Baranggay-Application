# HabalGo: Activity 5 Evidence Catalog & Screenshot Checklist

**Project:** HabalGo – Ride and Booking Management System  
**Course:** COMP 018 – Database Administration  
**Target DBMS:** PostgreSQL 18.6 on x86_64-windows  
**Target Database:** `grp00_habalgodb` (Schema: `habalgo`)  
**Host Platform:** Windows 11 / PostgreSQL 18.6 / pgAdmin 4 / psql  
**Evaluator:** Senior PostgreSQL Database Administrator (Group 2 Evaluation Team)  
**Date:** November 17, 2026  

---

## 1. Evidence Overview & Verification Principles

This evidence catalog indexes all terminal command outputs, PostgreSQL 18.6 system catalog queries, query planner benchmarks, and log entries compiled during the COMP 018 Activity 5 database monitoring and maintenance evaluation.

### Academic Integrity & Verification Principles:
- All database metrics were gathered live from the running PostgreSQL 18.6 engine on `localhost:5432`.
- No hypothetical, simulated, or fabricated outputs were substituted for live findings.
- Real credentials and sensitive passwords are fully protected and never committed.
- Configuration and privilege gaps in the target repository's artifacts were verified via direct source code inspection and catalog audits.

---

## 2. Screenshot Capture Checklist (13 Core Verification Artifacts)

| Screenshot Filename | What Should Be Visible | What It Proves | Supporting Report Section |
|---|---|---|---|
| `01_postgresql_version.png` | Output of `SELECT version();` and `SELECT current_database(), current_schema;` | Proves DBMS engine compilation (PostgreSQL 18.6 MSVC 64-bit), database name `grp00_habalgodb`, and active schema `habalgo` | Section 2 (Database Environment) |
| `02_database_tables.png` | Output grid of `information_schema.tables` filtered by `table_schema = 'habalgo'` | Proves existence and registration of all 8 domain base tables in schema `habalgo` | Section 3 (Catalog Sizing & Inventory) |
| `03_database_size.png` | Output of `pg_size_pretty(pg_database_size(current_database()))` | Proves physical disk footprint (~8.5 MB baseline footprint) | Section 3 (Catalog Sizing & Inventory) |
| `04_table_statistics.png` | Output of `pg_stat_user_tables` displaying `n_live_tup`, `n_dead_tup`, `last_analyze`, `last_vacuum` | Documents baseline live/dead tuple counts and sequential scan activity | Section 5 (Table Statistics) |
| `05_active_sessions.png` | Output grid of `pg_stat_activity` filtered by `datname = current_database()` | Documents connection concurrency (1.0% pool utilization), active sessions, and lack of idle-in-transaction locks | Section 5 (Connection Monitoring) |
| `06_role_privileges.png` | Output of `pg_roles` showing `app_runtime_grp`, `app_readonly_grp`, `habalgo_app_user`, and `habalgo_readonly_user` | Proves existence of Activity 3 RBAC roles and password configuration status | Section 4 (Access Control Review) |
| `07_table_permissions.png` | Output of `role_table_grants` showing permissions for `app_runtime_grp` and `app_readonly_grp` | Proves least-privilege boundary: full DML for app user vs strict SELECT-only for auditor | Section 4 (Access Control Review) |
| `08_analyze_execution.png` | pgAdmin Messages tab showing verbose output of `ANALYZE (VERBOSE) habalgo...` | Proves successful non-blocking execution of statistics collection and page sampling | Section 6 (Routine Maintenance) |
| `09_vacuum_execution.png` | pgAdmin Messages tab showing verbose output of `VACUUM (VERBOSE, ANALYZE) habalgo...` | Proves successful dead tuple reclamation, FSM/VM updates, and `relfrozenxid` advance | Section 6 (Routine Maintenance) |
| `10_explain_plan.png` | Query Tool Output showing `EXPLAIN` query plan tree for Query A (`$BK`) | Proves query planner execution strategy, join hierarchy, and sort node | Section 7 (Query Performance) |
| `11_explain_analyze.png` | Query Tool Output showing `EXPLAIN (ANALYZE, BUFFERS)` with timing and buffer hits | Proves actual execution latency (`0.112 ms`), quicksort memory usage (`25 kB`), and buffer hits | Section 7 (Query Performance) |
| `12_existing_indexes.png` | Output grid of `pg_indexes` for schema `habalgo` | Verifies existence of the 5 baseline secondary indexes (`idx_booking_customer`, etc.) | Section 7 (Index Evaluation) |
| `13_server_log_forensics.png` | View of PostgreSQL server log showing SCRAM authentication failure and vacuum warning | Documents actual engine error handling and permission enforcement in server logs | Section 5 (Log Inspection) |

---

## 3. Step-by-Step Screenshot Capture Guide (pgAdmin 4 & psql)

For students and DBAs preparing presentation slides, documentation portfolios, or technical defense submissions, execute the following commands and capture screenshots:

### A. Health & Activity Monitoring Screenshots
1. Open **pgAdmin 4**, connect to **PostgreSQL 18** -> **Databases** -> `grp00_habalgodb`.
2. Open **Tools -> Query Tool**.
3. Load and execute `sql/01_database_inspection.sql`.
   - **Capture Screenshot 1:** Engine version and current database context.
   - **Capture Screenshot 2:** 8-table inventory in schema `habalgo`.
   - **Capture Screenshot 3:** Physical database footprint output.
4. Load and execute `sql/03_monitoring_queries.sql`.
   - **Capture Screenshot 4:** Table statistics and sequential scan counts.
   - **Capture Screenshot 5:** Active backend sessions and connection capacity.

### B. Access Control & Security Audit Screenshots
1. Load and execute `sql/02_access_control_inspection.sql`.
   - **Capture Screenshot 6:** Role existence and cluster attributes.
   - **Capture Screenshot 7:** Table privilege matrix showing strict read-only boundary on `app_readonly_grp`.

### C. Routine Maintenance Screenshots
1. Open Query Tool connected as `postgres` (Table Owner / DBA).
2. Load and execute `sql/04_analyze_maintenance.sql`:
   - **Capture Screenshot 8:** Messages tab displaying `INFO: analyzing "habalgo.driver" ... scanned pages ...`.
3. Load and execute `sql/05_vacuum_maintenance.sql` (standalone command):
   - **Capture Screenshot 9:** Messages tab displaying `INFO: vacuuming "habalgo.driver" ... tuples: 0 dead ... new relfrozenxid`.

### D. Query Performance Benchmark Screenshots
1. Load `sql/06_query_performance.sql`.
2. Run Section 1.1 (Query A Estimated Plan):
   - **Capture Screenshot 10:** Execution plan output displaying join tree.
3. Run Section 1.2 (Query A Live Execution Plan with Buffers):
   - **Capture Screenshot 11:** Execution plan output displaying `Sort Method: quicksort`, actual timing, and buffer hits.
4. Run Section 11 of `sql/01_database_inspection.sql`:
   - **Capture Screenshot 12:** Secondary index catalog inventory.
