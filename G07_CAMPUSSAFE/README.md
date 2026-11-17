# Activity 5: Database Maintenance, Health Monitoring & Query Optimization
## CampusSafe: Campus Hazard & Safety Reporting System

**System:** CampusSafe: Campus Hazard & Safety Reporting System  
**Course:** COMP 018 — Database Administration &bull; Group 7  
**Database Name:** `grp07_campussafedb`  
**Schema:** `public`  
**Evaluation Date:** November 17, 2026  
**Documented DBMS:** PostgreSQL 14+ (Verified Environment: PostgreSQL 14.24)  
**Host Runtime DBMS:** PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35228, 64-bit  
**Backend:** PHP 8.2+ with PDO PostgreSQL  
**Frontend:** HTML5, CSS3, JavaScript  

---

## 1. Activity 5 Overview & Objectives

In Activity 5, Database Administrators inspect catalog health, monitor runtime metrics, execute routine maintenance (`ANALYZE` and `VACUUM`), and benchmark SQL execution plans using `EXPLAIN (ANALYZE, BUFFERS)` to diagnose bottlenecks, eliminate tuple bloat, and optimize query performance.

This package provides the complete, non-destructive, academically rigorous evaluation for **Group 7 (CampusSafe)**, linking live catalog findings with deep performance profiling and actionable recommendations.

---

## 2. CampusSafe System Description & Hazard Lifecycle

CampusSafe is an enterprise campus hazard and physical safety incident management platform designed for educational institutions. The platform empowers students, faculty, administrators, and maintenance personnel to report, triage, assign, track, and resolve physical safety and environmental hazards.

The database models a strict **6-stage hazard lifecycle**:

```text
[1. Submitted] ──> [2. Verified] ──> [3. Assigned] ──> [4. In Progress] ──> [5. Resolved] ──> [6. Closed]
  (Reporter)         (Admin)           (Admin)           (Technician)       (Technician)       (Admin)
```

1. **Submitted:** A student or faculty reporter files an initial incident report. Priority is `NULL` pending administrative review.
2. **Verified:** A Campus Safety Administrator reviews photographic evidence, assigns priority (`Low`, `Medium`, `High`, `Critical`), and records verification timestamps (`chk_verified_pair`).
3. **Assigned:** The administrator dispatches one or more maintenance technicians (`assignment`).
4. **In Progress:** The assigned technician arrives on-site, inspects the physical damage, and begins repairs.
5. **Resolved:** The technician finishes remediation, logs actions in `maintenance_action`, and sets `resolved_at` (`chk_resolved_has_date`).
6. **Closed:** The safety administrator inspects the completed repair, verifies safety compliance, and closes the incident. Every transition is immutably logged in `report_status_history`.

---

## 3. Database Environment & Catalog Health Inspection

- **PostgreSQL Version:** `PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35228, 64-bit`
- **Documented Compatibility:** PostgreSQL 14.24, 15, 16, 17, and 18.
- **Physical Database Footprint:** **8,974 kB** (9,189,055 bytes).
- **Core Base Tables:** Exactly **9 domain base tables** in schema `public`:
  `role`, `app_user`, `hazard_category`, `campus_location`, `hazard_report`, `assignment`, `report_status_history`, `maintenance_action`, `attachment`.
- **Serial Sequences:** Exactly 9 auto-incrementing serial sequences backing 32-bit surrogate integer keys.
- **Index Inventory:** Exactly **24 indexes** (9 primary keys, 5 unique constraints, 10 secondary performance indexes).
- **Relational Integrity:** Foreign keys enforce `ON DELETE CASCADE` on child incident records (`assignment`, `attachment`, `maintenance_action`, `report_status_history`) while restricting master table deletion. Domain consistency constraints `chk_verified_pair` and `chk_resolved_has_date` guarantee audit compliance.

*Supporting Documentation:* [`database-inspection.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/database-inspection.md) & [`sql/02_database_structure_inspection.sql`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/sql/02_database_structure_inspection.sql).

---

## 4. Server Health Check Suite & Monitoring Procedures

Connect to `grp07_campussafedb` using your Activity 4 account or DBA role:

```sql
-- 1. Verify PostgreSQL Version and OS build
SELECT version();

-- 2. Database disk footprint
SELECT pg_size_pretty(pg_database_size('grp07_campussafedb')) AS total_db_size;

-- 3. Table and index sizes
SELECT
    relname AS object_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_size_pretty(pg_indexes_size(relid)) AS index_size
FROM pg_catalog.pg_statio_user_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(relid) DESC;

-- 4. Active Connections and Running Queries
SELECT pid, usename, client_addr, state, query_start, LEFT(query, 160) AS query_preview
FROM pg_stat_activity
WHERE datname = 'grp07_campussafedb';

-- 5. Database Statistics & Cache Hit Ratio
SELECT
    numbackends,
    xact_commit,
    xact_rollback,
    blks_read,
    blks_hit,
    ROUND((blks_hit::numeric / (blks_hit + blks_read + 0.0001)) * 100, 2) AS buffer_cache_hit_pct
FROM pg_stat_database
WHERE datname = 'grp07_campussafedb';
```

---

## 5. Live Monitoring Findings & Operational Telemetry

- **Active Sessions:** 1 backend session active; 0 idle in transaction; 0 waiting backends (1.0% connection pool load).
- **Transaction Health:** `2,790` committed transactions, `0` rollbacks (**0.00% rollback rate**).
- **Buffer Cache Hit Ratio:** **`99.70%`** ($113,227 \text{ hits} / [113,227 \text{ hits} + 342 \text{ reads}]$), proving that 997 out of 1,000 page reads are served directly from RAM without disk I/O latency.
- **Lock Contention:** `0` exclusive locks; zero blocked queries in `pg_locks`.
- **Tuple Accumulation Baseline:** 136 live tuples; 4 dead tuples (2 in `app_user`, 2 in `hazard_report`) generated by update transactions.

*Supporting Documentation:* [`monitoring-results.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/monitoring-results.md) & [`sql/01_server_health_checks.sql`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/sql/01_server_health_checks.sql).

---

## 6. Access-Control Observations & Security Boundaries

- **Two-Tier Role Hierarchy:** 3 non-login group roles (`app_runtime_grp`, `app_readonly_grp`, `app_backup_grp`) granted to 3 login accounts (`campussafe_app`, `campussafe_report`, `campussafe_backup`).
- **Least-Privilege Enforcement (PoLP):**
  - `campussafe_app`: Holds `SELECT`, `INSERT`, `UPDATE` on operational tables; `DELETE` is strictly restricted to `assignment` and `attachment`. `DELETE` is blocked on `hazard_report`, `app_user`, and audit tables.
  - `campussafe_report`: Holds read-only `SELECT` on operational tables; strictly blocked from `app_user` and `role` to prevent exposure of Bcrypt `password_hash` strings.
- **Application Roles vs. Database Accounts:** Human roles (Student, Faculty, Maintenance, Admin, Auditor) are authenticated by the PHP session system; all application traffic connects via `campussafe_app`.
- **Maintenance Permission Boundary (PostgreSQL 14+):** `VACUUM` and `ANALYZE` require table ownership or superuser status. Attempting maintenance via `campussafe_app` safely raises a permission warning, ensuring application accounts cannot execute destructive DDL commands.

*Supporting Documentation:* [`access-control-review.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/access-control-review.md) & [`sql/03_access_control_monitoring.sql`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/sql/03_access_control_monitoring.sql).

---

## 7. Maintenance Procedures (`ANALYZE` & `VACUUM`)

> **PostgreSQL 14+ Note:** `VACUUM` and `ANALYZE` require table ownership or superuser status. When testing peer projects, document whether the account has ownership or if an administrative maintenance role is required.

```sql
-- 1. Gather fresh query planner statistics
ANALYZE;

-- 2. Clean dead tuples and update statistics without locking tables
VACUUM (VERBOSE, ANALYZE) public.hazard_report;
VACUUM (VERBOSE, ANALYZE) public.report_status_history;
VACUUM (VERBOSE, ANALYZE) public.maintenance_action;
VACUUM (VERBOSE, ANALYZE) public.assignment;
VACUUM (VERBOSE, ANALYZE) public.app_user;
VACUUM (VERBOSE, ANALYZE) public.campus_location;
VACUUM (VERBOSE, ANALYZE) public.hazard_category;
VACUUM (VERBOSE, ANALYZE) public.attachment;
VACUUM (VERBOSE, ANALYZE) public.role;
```

*Never run `VACUUM FULL` in production unless resolving severe disk bloat during scheduled maintenance, as it places an exclusive table lock (`AccessExclusiveLock`).*

### 7.1 Maintenance Execution Results

- **`ANALYZE` Execution:** Refreshed `pg_statistic` across all 9 tables; updated `reltuples` and logged `last_analyze` timestamps.
- **`VACUUM` Execution:** Successfully reclaimed **100% of dead tuples** (2 dead tuples in `app_user`, 2 dead tuples in `hazard_report` reduced to 0), freeing page slots for future inserts without locking tables.

*Supporting Documentation:* [`maintenance-log.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/maintenance-log.md), [`sql/05_analyze.sql`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/sql/05_analyze.sql), and [`sql/06_vacuum.sql`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/sql/06_vacuum.sql).

---

## 8. Query Plan Analysis (`EXPLAIN ANALYZE`)

The following real CampusSafe queries were benchmarked using `EXPLAIN (ANALYZE, BUFFERS)`:

### Query 1: Admin Filter by Status & Recency
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * 
FROM hazard_report 
WHERE status = 'Submitted' 
ORDER BY submitted_at DESC;
```

**Plan Summary:**
- **Execution Plan:** `Sort (quicksort) -> Seq Scan on hazard_report (Filter: status = 'Submitted')`
- **Actual Execution Time:** **0.059 ms**
- **Buffers:** `shared hit=1`, `shared read=0`
- **Analysis Goal Answered:** The planner appropriately selects a **Sequential Scan** rather than `idx_report_status`. Because `hazard_report` occupies a single 8KB page (17 rows), reading contiguous memory blocks in RAM costs **1.21**, whereas traversing `idx_report_status` and dereferencing pointers costs **8.15**. Forcing an index scan via `SET LOCAL enable_seqscan = off` increased execution time to 0.104 ms (43% slower). On small tables, sequential scanning is mathematically optimal.

### Query 2: Hazard Reports with Joined Categories and Locations
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT r.report_id, c.category_name, l.building, l.room_area, r.status, r.priority
FROM hazard_report r
JOIN hazard_category c ON c.category_id = r.category_id
JOIN campus_location l ON l.location_id = r.location_id
WHERE r.status = 'In Progress';
```

**Plan Summary:**
- **Execution Plan:** Two-level `Hash Join` hashing `hazard_category` (9 kB) and `campus_location` (9 kB).
- **Actual Execution Time:** **0.085 ms**
- **Buffers:** `shared hit=3`, `shared read=0`
- **Analysis Goal Answered:** The planner selects **Hash Joins** because in-memory hash tables of 6 categories and 10 locations fit entirely within L1/L2 CPU cache (9 kB each), providing $O(1)$ constant-time key lookups and sub-0.1ms execution.

*Supporting Documentation:* [`query-performance-analysis.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/query-performance-analysis.md) & [`sql/07_query_performance.sql`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/sql/07_query_performance.sql).

---

## 9. Performance Observations & Recommendations

1. **Autovacuum Scale Factor Tuning:** Lower `autovacuum_vacuum_scale_factor` from 0.20 to 0.05 on `hazard_report` and `report_status_history` to trigger automatic dead tuple reclamation earlier during high-frequency status transitions.
2. **Postpone Composite Indexing:** Avoid creating composite index `(status, submitted_at DESC)` on small seed data; implement concurrently when table volume surpasses **10,000 incident reports**.
3. **Add Covering Index on Audit User:** Create `idx_history_changed_by` ON `report_status_history(changed_by_user_id)` to optimize auditor queries tracking specific user actions.
4. **Automated Scheduled Maintenance:** Configure automated off-peak nightly maintenance via Task Scheduler/cron executing `05_analyze.sql` and `06_vacuum.sql`.

*Supporting Documentation:* [`recommendations.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/recommendations.md).

---

## 10. Limitations & Diagnostic Boundary Analysis

- **Maintenance Account Limitation:** Standard application runtime accounts (`campussafe_app`) cannot execute `VACUUM` or `ANALYZE` under PostgreSQL 14+. This is a deliberate security boundary protecting schema ownership.
- **Sequential Scan Cardinality Boundary:** Sequential scans on tables under 100 rows are expected and optimal; benchmark evaluations should not misidentify them as performance defects.
- **Log Accessibility:** Direct file inspection of raw server log directories (`%PGDATA%\log\`) is restricted by Windows NTFS ACLs to service accounts; monitoring is conducted through administrative session catalogs.

---

## 11. Evidence & Verification Checklist

The evidence checklist defines 16 visual verification captures covering server version, catalog structure, active connections, cache hit ratio, maintenance outputs, and `EXPLAIN ANALYZE` plans.

*Supporting Documentation:* [`evidence/README.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/evidence/README.md).

---

## 12. Directory Structure & References

```text
grp07-campussafe/
└── db-maintenance/
    ├── README.md                          # Master Activity 5 report and navigation hub
    ├── database-inspection.md             # Detailed catalog inspection and table sizing
    ├── monitoring-results.md              # Live session, transaction, and cache telemetry
    ├── access-control-review.md           # RBAC, PoLP, and maintenance boundary audit
    ├── maintenance-log.md                 # Live ANALYZE & VACUUM before/after execution log
    ├── query-performance-analysis.md      # Deep EXPLAIN ANALYZE execution plan benchmarks
    ├── recommendations.md                 # Categorized, evidence-based DBA recommendations
    ├── sql/
    │   ├── 01_server_health_checks.sql    # Engine version, database size, sessions, cache
    │   ├── 02_database_structure_inspection.sql # Tables, columns, constraints, sequences, indexes
    │   ├── 03_access_control_monitoring.sql # Roles, inheritance, table grants, sequence rights
    │   ├── 04_table_statistics.sql        # Live/dead tuples, scan ratios, mutation counters
    │   ├── 05_analyze.sql                 # Global and relation-specific ANALYZE commands
    │   ├── 06_vacuum.sql                  # Standalone VACUUM (VERBOSE, ANALYZE) commands
    │   └── 07_query_performance.sql      # EXPLAIN and EXPLAIN ANALYZE query benchmarks
    └── evidence/
        └── README.md                      # 16-point screenshot and evidence checklist
```
