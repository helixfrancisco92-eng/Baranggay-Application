# OJT Management System: Activity 5 Evidence Catalog & Verification Guide

**Project:** OJT Management System (Project-OJT-RMA-System)  
**Course:** COMP 018 – Database Administration  
**Target Database:** `ojt_management` / `OJT_Managementdb`  
**Host Platform:** Windows 11 / PostgreSQL 18.6 / pgAdmin 4 / psql  
**Evaluator:** Senior PostgreSQL Database Administrator (COMP 018 Evaluation Team)  
**Date:** November 17, 2026  

---

## 1. Evidence Overview

This evidence catalog indexes all terminal command outputs, PostgreSQL 18.6 system catalog queries, query planner benchmarks, and log entries compiled during the COMP 018 Activity 5 database monitoring and maintenance evaluation.

### Academic Integrity & Verification Principles:
- All database metrics were gathered live from the running PostgreSQL 18.6 engine on `localhost:5432`.
- No hypothetical, simulated, or fabricated outputs were substituted for live findings.
- Real credentials and sensitive passwords are fully protected and never committed.
- Inconsistencies and flaws in the target repository's artifacts were verified via binary analysis (`pg_restore -l`) and optical code inspection.

---

## 2. Evidence Files & Artifact Mapping

| Evidence ID | Verification Scope | Corresponding Script / File | Source Command / Evidence Origin |
|---|---|---|---|
| **01_db_info** | PostgreSQL 18.6 compilation, database name, storage size, 12 domain tables | `health-inspection/database-information.sql` | `SELECT version(); pg_database_size(); information_schema.tables` |
| **02_connections** | Active/idle backend connections, connection pool limit, cache hit ratio (>99%) | `health-inspection/connection-monitoring.sql` | `SELECT * FROM pg_stat_activity; pg_stat_database` |
| **03_role_grants** | Activity 4 RBAC audit: `ojt_*` roles, table permissions, column-level grants | `health-inspection/database-roles.sql` | `information_schema.role_table_grants`, `role_column_grants` |
| **04_security_flaws** | Verified over-permissive UPDATE on `attendance` for `ojt_student`; missing profile INSERT for `ojt_admin` | `health-inspection/database-roles.sql` | Role audit against `Db.createUser()` and `Roles.java` |
| **05_log_findings** | Forensic analysis of server logs: auth rejections, unassigned passwords, syntax errors, vacuum warnings | `log-analysis/log-findings.md` | `C:\Program Files\PostgreSQL\18\data\log\` |
| **06_analyze_output** | Verbose table & database statistics refresh (`reltuples` updated from -1) | `maintenance/analyze.sql` | `ANALYZE (VERBOSE); pg_class.reltuples` |
| **07_vacuum_output** | Dead tuple cleanup on `attendance`, `ojt_placements`, freeze cutoff advance | `maintenance/vacuum.sql` | `VACUUM (VERBOSE, ANALYZE) public.attendance;` |
| **08_explain_plan** | Plan breakdown: Correlated scalar subquery (20 loops, 63 buffers) vs Optimized Left Join (6 buffers, 90.8% cost drop) | `performance/selected-query.sql` | `EXPLAIN (ANALYZE, BUFFERS)` on `Roles.placements()` |

---

## 3. Step-by-Step Screenshot Capture Guide (pgAdmin 4 & psql)

For students and DBAs preparing presentation slides, documentation portfolios, or technical defense submissions, execute the following commands and capture screenshots:

### A. Health & Activity Monitoring Screenshots
1. Open **pgAdmin 4**, expand **Servers** -> **PostgreSQL 18** -> **Databases** -> `ojt_management`.
2. Open **Tools -> Query Tool**.
3. Load and execute `health-inspection/database-information.sql`.
   - **Screenshot 1:** Output grid showing PostgreSQL 18.6 build, database size, and base table inventory.
4. Load and execute `health-inspection/connection-monitoring.sql`.
   - **Screenshot 2:** Output grid displaying active backend connections, session states, and `buffer_cache_hit_ratio_pct`.

### B. Access Control & Security Audit Screenshots
1. Load and execute `health-inspection/database-roles.sql`.
   - **Screenshot 3:** Role table grants showing permissions for the 5 application roles.
2. In the Query Tool, execute the security vulnerability verification queries:
   - **Screenshot 4:** Output highlighting `ojt_student` holding unconditional `UPDATE` on `attendance`, demonstrating the privilege flaw.
   - **Screenshot 5:** Output showing `ojt_admin` lacking `INSERT` on `students`, `academic_supervisors`, and `company_supervisors`.

### C. Routine Maintenance Screenshots
1. Open the Query Tool connected as `postgres` (Table Owner / DBA).
2. Execute `maintenance/analyze.sql`:
   - **Screenshot 6:** Messages tab showing verbose output: `INFO: analyzing "public.attendance" ... scanned pages ... containing live rows`.
3. Execute `maintenance/vacuum.sql` (standalone command):
   - **Screenshot 7:** Messages tab showing verbose output: `INFO: vacuuming "public.attendance" ... pages: 0 removed ... tuples: 0 dead ... new relfrozenxid`.

### D. Query Performance Benchmark Screenshots
1. Load `performance/selected-query.sql`.
2. Run Section 1.2 (Unoptimized Application Query with Correlated SubPlan):
   - **Screenshot 8:** Execution plan output displaying `SubPlan 1 -> Aggregate -> Seq Scan on attendance (loops=20)` with `Buffers: local hit=63`.
3. Run Section 4 (Optimized Restructured Query with Grouped Left Join):
   - **Screenshot 9:** Execution plan output displaying `Hash Left Join -> HashAggregate` with `Buffers: local hit=6` and cost drop from `120.06` to `11.07`.
