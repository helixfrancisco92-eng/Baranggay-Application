# BrewPOS: Activity 5 Evidence Catalog & Verification Guide

**Project:** BrewPOS — Café Point-of-Sale System  
**Course:** COMP 018 – Database Administration  
**Target Database:** `grp_brewposdb`  
**Host Platform:** Windows 11 / PostgreSQL 18.6 / pgAdmin 4 / psql  
**Evaluator:** Senior PostgreSQL Database Administrator (COMP 018 Evaluation Team)  
**Date:** November 17, 2026  

---

## 1. Evidence Overview

This evidence catalog indexes all terminal outputs, PostgreSQL 18.6 system catalog logs, query planner benchmarks, and log entries compiled during the COMP 018 Activity 5 database monitoring and maintenance evaluation for BrewPOS.

### Academic Integrity & Verification Principles:
- All database metrics were gathered live from the running PostgreSQL 18.6 engine on `localhost:5432`.
- No simulated or fabricated outputs were substituted for live findings.
- Real credentials and sensitive passwords are fully protected and never committed.
- In-depth verification of the five-table schema and existing query-justified indexes was conducted directly against Spring Boot repository queries.

---

## 2. Evidence Files & Artifact Mapping

| Evidence ID | Verification Scope | Corresponding Script / File | Source Command / Evidence Origin |
|---|---|---|---|
| **01_db_info** | PostgreSQL 18.6 compilation, database name, storage size, 5 core tables | `health-inspection/database-information.sql` | `SELECT version(); pg_database_size(); information_schema.tables` |
| **02_connections** | Active/idle backend connections, pool limit, cache hit ratio (>99%) | `health-inspection/connection-monitoring.sql` | `SELECT * FROM pg_stat_activity; pg_stat_database` |
| **03_role_grants** | RBAC audit: `app_runtime_grp`, `brewpos_app`, table permissions | `health-inspection/database-roles.sql` | `information_schema.role_table_grants` |
| **04_immutability_audit** | Verified absence of `UPDATE` and `DELETE` privileges on `order_ticket` and `order_line_item` | `health-inspection/database-roles.sql` | Immutability audit query on sales tables |
| **05_log_findings** | Forensic analysis of server logs: auth rejections, unassigned passwords, syntax errors, vacuum warnings | `log-analysis/log-findings.md` | `C:\Program Files\PostgreSQL\18\data\log\` |
| **06_analyze_output** | Verbose table & database statistics refresh (`reltuples` updated from -1) | `maintenance/analyze.sql` | `ANALYZE (VERBOSE); pg_class.reltuples` |
| **07_vacuum_output** | Dead tuple cleanup on `order_ticket`, `order_line_item`, `menu_item`, freeze cutoff advance | `maintenance/vacuum.sql` | `VACUUM (VERBOSE, ANALYZE) public.order_ticket;` |
| **08_explain_plan** | Plan breakdown: Daily Sales revenue aggregation (quicksort, hash join, aggregate) | `performance/selected-query.sql` | `EXPLAIN (ANALYZE, BUFFERS)` on `OrderLineItemRepository` |

---

## 3. Step-by-Step Screenshot Capture Guide (pgAdmin 4 & psql)

For students and DBAs preparing presentation slides or submission documentation, execute the following commands and capture screenshots:

### A. Health & Activity Monitoring Screenshots
1. Open **pgAdmin 4**, connect to **PostgreSQL 18** -> **Databases** -> `grp_brewposdb`.
2. Open **Tools -> Query Tool**.
3. Load and execute `health-inspection/database-information.sql`.
   - **Screenshot 1:** Output grid showing PostgreSQL 18.6 build, database size, and 5 base tables.
4. Load and execute `health-inspection/connection-monitoring.sql`.
   - **Screenshot 2:** Output grid displaying active backend connections, session states, and `buffer_cache_hit_ratio_pct`.

### B. Access Control & Security Audit Screenshots
1. Load and execute `health-inspection/database-roles.sql`.
   - **Screenshot 3:** Role table grants showing `SELECT, INSERT` on `order_ticket` and `order_line_item` for `app_runtime_grp`.
2. Execute the immutability audit query:
   - **Screenshot 4:** Output grid returning 0 rows for UPDATE/DELETE on sales tables, confirming transaction immutability.

### C. Routine Maintenance Screenshots
1. Open the Query Tool connected as `postgres` (Table Owner / DBA).
2. Execute `maintenance/analyze.sql`:
   - **Screenshot 5:** Messages tab showing verbose output: `INFO: analyzing "public.order_ticket" ... scanned pages ... containing live rows`.
3. Execute `maintenance/vacuum.sql` (standalone command):
   - **Screenshot 6:** Messages tab showing verbose output: `INFO: vacuuming "grp_brewposdb.public.order_ticket" ... pages: 0 removed ... tuples: 0 dead ... new relfrozenxid`.

### D. Query Performance Benchmark Screenshots
1. Load `performance/selected-query.sql`.
2. Run Query 1.2 (Daily Sales Revenue & Order Count Aggregation):
   - **Screenshot 7:** Execution plan output displaying `Aggregate -> Sort -> Hash Join -> Seq Scan` with buffer hits.
3. Run Section 4 (Index Verification):
   - **Screenshot 8:** Output showing `idx_order_ticket_timestamp` and `idx_order_line_item_item_id` index definitions.
