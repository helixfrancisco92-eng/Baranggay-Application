# COMP 018 – DATABASE ADMINISTRATION
## ACTIVITY 5: DATABASE MAINTENANCE AND MONITORING TECHNICAL EVALUATION
### Target Project: HabalGo – Ride and Booking Management System

**Document Classification:** Official Academic & Professional DBA Submission  
**Evaluator:** Senior PostgreSQL Database Administrator, PHP Backend Developer, Database Security Specialist & Query Performance Analyst (COMP 018 Group 2 Evaluation Team)  
**Evaluation Date:** November 17, 2026  
**Target Repository:** `https://github.com/jeanaroyo/HabalGo.git`  
**Target DBMS Cluster:** PostgreSQL 18.6 on x86_64-windows (MSVC 64-bit on Windows 11)  
**Target Database:** `grp00_habalgodb` (Schema: `habalgo`)  
**Documentation Locations:** `activity-5/` and `db-maintenance/habalgo/`  

---

## Executive Summary

A comprehensive, non-destructive technical inspection, catalog health audit, security analysis, configuration review, routine maintenance procedure, and query execution plan benchmark were conducted for the **HabalGo Ride and Booking Management System** (`jeanaroyo/HabalGo`) based on the official repository and the local PostgreSQL 18.6 database cluster.

The evaluation systematically audited the PHP backend source code (`api.php`, `config.php`, `randomize_drivers.php`), evaluated the existing Activity 3 access control architecture (`database/03_roles_and_privileges.sql`, `Activity 3_Access Control/`), verified database configuration discrepancies, executed live catalog health queries, performed routine maintenance (`ANALYZE` and `VACUUM`), and profiled actual application queries powering the dispatch dashboard, customer aggregations, vehicle assignments, and executive telemetry using `EXPLAIN (ANALYZE, BUFFERS)`.

All diagnostic scripts, execution plans, log findings, maintenance routines, and evidence checklists have been organized within the current workspace under `activity-5/` and mirrored in `db-maintenance/habalgo/`.

---

## 1. Review of Existing Repository Activity 3 & Activity 5 Work

An exhaustive inspection of the target repository revealed:
1. **Existing Activity 3 Access Control Directory:**
   - In `target-habalgo-repo/database/03_roles_and_privileges.sql`, Group 0 (HabalGo) established a clean RBAC structure defining two group roles (`app_runtime_grp`, `app_readonly_grp`) and two login accounts (`habalgo_app_user`, `habalgo_readonly_user`).
   - The directory `Activity 3_Access Control/` contains peer verification tracking (`Group 2`), and the root contains `ACT 3 Progress Documentation.pdf`.
2. **Absence of Activity 5 Work:**
   - The repository did not contain an `activity-5/` directory or existing database maintenance documentation.
   - In accordance with the prompt guidelines ("Preserve completed work. Store Activity 5 work in the current group's authorized workspace. Do not modify the original target group's GitHub repository"), the complete Activity 5 suite for HabalGo was constructed in `activity-5/` and `db-maintenance/habalgo/` in the monitoring group's workspace, leaving the target repository completely untouched.

---

## 2. Configuration Review & Inconsistency Audit

Inspection of `README.md`, `.env.example`, `config.php`, and `api.php` revealed four critical configuration inconsistencies documented in [`activity-5/configuration-review.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/activity-5/configuration-review.md):

| Configuration Item | `README.md` | `.env.example` | `config.php` | `api.php` Behavior | Impact / Severity |
|---|---|---|---|---|---|
| **Database Name** | `grp00_habalgodb` | `grp00_habalgodb` | `getenv('DB_NAME') ?: 'habalgo'` | Fallback connects to `habalgo` | **High:** Connects to wrong DB if env var is missing |
| **Password Key** | `DB_PASS=...` | `DB_PASSWORD=...` | `getenv('DB_PASS') ?: 'user'` | Falls back to default password `'user'` | **High:** Triggers SCRAM auth rejection |
| **`.env` Parser** | Instructs `cp .env.example .env` | Provided in root | **No parser implemented** | `getenv()` completely ignores `.env` file | **High:** `.env` values are not loaded into PHP |
| **Database User** | `DB_USER=postgres` | `DB_USER=postgres` | `getenv('DB_USER') ?: 'postgres'` | Connects as superuser `postgres` | **High:** Bypasses least-privilege `habalgo_app_user` |
| **Database Schema** | `DB_SCHEMA=habalgo` | *(Not Defined)* | *(Ignored / Not Read)* | `$db->exec('SET search_path TO habalgo');` | **Low:** Hardcoded schema switch works reliably |

*DBA Action:* Documented as an environment finding without modifying the application source code.

---

## 3. Database Environment & Catalog Health Inspection

Live queries against the local PostgreSQL 18.6 cluster on `localhost:5432` yielded:
- **DBMS Compilation:** `PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35228, 64-bit`
- **Database Storage Size:** `8,518 kB` (~8.5 MB baseline catalog footprint).
- **Primary Schema:** `habalgo` (isolated from `public`).
- **Base Domain Tables:** Exactly `8` base tables in schema `habalgo`:
  1. `customer` (Identity directory with validated phone and unique email)
  2. `driver` (Motorcycle drivers with unique license numbers)
  3. `vehicle` (Fleet motorcycles with unique plate numbers)
  4. `driver_vehicle` (Junction table with natural composite PK `(driver_id, vehicle_id)` and assignment dates check)
  5. `location` (Geocoded pickup/drop-off addresses and cities)
  6. `booking` (Central ride sessions with status check constraint and foreign keys)
  7. `payment` (Billing transactions with positive amount check constraint)
  8. `rating_feedback` (Ride reviews with 1-to-5 star rating check and unique pair constraint)
- **Serial Sequences:** Exactly `7` auto-incrementing serial sequences (`customer_customer_id_seq`, `driver_driver_id_seq`, `vehicle_vehicle_id_seq`, `location_location_id_seq`, `booking_booking_id_seq`, `payment_payment_id_seq`, `rating_feedback_rating_id_seq`). `driver_vehicle` uses a composite key and has no sequence.
- **Secondary Indexes:** Exactly `5` pre-created secondary indexes:
  - `idx_booking_customer` on `booking(customer_id)`
  - `idx_booking_driver` on `booking(driver_id)`
  - `idx_booking_date` on `booking(booking_date)`
  - `idx_payment_booking` on `payment(booking_id)`
  - `idx_rating_booking` on `rating_feedback(booking_id)`
- **Connection Capacity & Utilization:** `100` maximum connections configured (`max_connections`); `3` reserved for superusers. Exactly `1` active session (1.0% pool utilization).
- **Lock Contention:** `0` lock conflicts; zero deadlocks in `pg_locks`.
- **Cumulative Transactions:** `2,609` commits, `10` rollbacks (`0.38%` rollback rate).
- **Buffer Cache Hit Ratio:**
  $$\text{Cache Hit Ratio} = \frac{113,227 \text{ hits}}{113,227 \text{ hits} + 517 \text{ reads}} \times 100 = 99.55\%$$
  Demonstrates that 99.55% of all page requests are served from RAM (`shared_buffers = 128MB`), delivering optimal I/O performance.

---

## 4. Access Control Review & Least-Privilege Verification

Inspection of `database/03_roles_and_privileges.sql` in [`activity-5/access-control-review.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/activity-5/access-control-review.md) confirmed:
1. **Role-Based Privilege Bundling:**
   - `app_runtime_grp` (`NOLOGIN`): Holds `USAGE` on schema `habalgo`, `SELECT, INSERT, UPDATE, DELETE` on all tables, and `USAGE, SELECT` on all sequences.
   - `app_readonly_grp` (`NOLOGIN`): Holds `USAGE` on schema `habalgo` and strict `SELECT` on all tables. Holds zero `INSERT`, `UPDATE`, or `DELETE` grants and zero sequence grants.
2. **Login Account Inheritance:**
   - `habalgo_app_user` inherits `app_runtime_grp`.
   - `habalgo_readonly_user` inherits `app_readonly_grp`.
3. **Least-Privilege Compliance:**
   - Auditor account `habalgo_readonly_user` is cryptographically prevented from modifying booking records or consuming auto-increment sequences.
   - Non-owner roles cannot run `VACUUM` or `ANALYZE`, ensuring that routine maintenance must be executed by a DBA account.
4. **Security Vulnerability Identified:**
   - The PHP application in `config.php` and `.env.example` still defaults to connecting as superuser **`postgres`** rather than `habalgo_app_user`.
   - *Recommendation:* Mandate `DB_USER=habalgo_app_user` in runtime environments to eliminate superuser exposure.

---

## 5. Database Monitoring & Runtime Activity Results

System catalog monitoring detailed in [`activity-5/monitoring-results.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/activity-5/monitoring-results.md) revealed:
1. **Zero "Idle in Transaction" Backends:** All transactions commit or roll back cleanly, preventing snapshot retention that would block dead tuple cleanup.
2. **Sequential Scans on Small Relations:** Tables like `driver` execute sequential scans (`seq_scans = 14`). As demonstrated by PostgreSQL's cost model, sequential reads on tables fitting inside a single 8 kB heap page are more efficient than multi-block random I/O from index scans.
3. **Server Log Forensic Analysis:** Audit of `C:\Program Files\PostgreSQL\18\data\log\` verified SCRAM authentication rejections, transaction boundary violations on VACUUM, and permission denials when non-owner service accounts attempt maintenance.

---

## 6. Routine Database Maintenance Execution

All maintenance commands were prepared and executed as standalone statements outside transaction blocks under the table owner / DBA account (`postgres`) detailed in [`activity-5/maintenance-log.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/activity-5/maintenance-log.md):

### A. ANALYZE (Statistics Optimization)
- **Command:** `ANALYZE (VERBOSE) habalgo...` across all eight tables.
- **Result:** Scanned pages, updated `pg_class.reltuples` and `relpages`, and refreshed column statistics (`null_frac`, `n_distinct`, MCVs) in `pg_stats`.

### B. VACUUM (Dead Tuple Reclamation & MVCC Maintenance)
- **Command:** `VACUUM (VERBOSE, ANALYZE) habalgo...` on transactional relations (`booking`, `payment`, `driver_vehicle`, `driver`).
- **Result:** Reclaimed dead tuple space within 8 kB pages, updated Free Space Map (FSM) and Visibility Map (VM), and advanced `relfrozenxid` to prevent transaction ID wraparound.
- **Safety Restriction:** `VACUUM FULL` was strictly avoided to prevent `AccessExclusiveLock` table contention and service downtime.

---

## 7. Query Performance Analysis & Execution Plan Profiling

Six actual queries from `api.php` were profiled using `EXPLAIN (ANALYZE, BUFFERS)` in [`activity-5/query-performance-analysis.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/activity-5/query-performance-analysis.md):

### Primary Query A: Comprehensive Booking Listing (`$BK`)
- **SQL Statement:**
  ```sql
  SELECT b.booking_id AS id, b.customer_id, c.name AS customer, lp.address AS pickup, lp.city AS pickup_city,
         ld.address AS dropoff, ld.city AS dropoff_city, b.driver_id, d.name AS driver, b.booking_status,
         to_char(b.booking_date, 'Mon DD') AS date, c.name AS customer_name, c.phone AS customer_phone, c.email AS customer_email
  FROM habalgo.booking b
  JOIN habalgo.customer c ON c.customer_id = b.customer_id
  JOIN habalgo.location lp ON lp.location_id = b.pickup_location_id
  JOIN habalgo.location ld ON ld.location_id = b.dropoff_location_id
  LEFT JOIN habalgo.driver d ON d.driver_id = b.driver_id
  ORDER BY b.booking_id DESC;
  ```
- **Execution Plan Metrics:**
  - Total Execution Time: `0.112 ms` (Planning Time: `0.321 ms`)
  - Quicksort Memory Usage: `25 kB`
  - Join Strategy: Nested Loop Left Join driving lookups through `location_pkey` and `driver_pkey`.

### Recommended Performance Index Optimizations:
1. **Partial Index on Active Bookings:**
   ```sql
   CREATE INDEX idx_booking_active_status 
   ON habalgo.booking (booking_status) 
   WHERE booking_status IN ('Pending', 'Confirmed', 'In Progress');
   ```
   *Impact:* Eliminates sequential scans during dashboard active ride telemetry (`InitPlan 4`) with minimal index overhead.
2. **Partial Index on Active Vehicle-Driver Assignments:**
   ```sql
   CREATE INDEX idx_driver_vehicle_active 
   ON habalgo.driver_vehicle (vehicle_id, driver_id) 
   WHERE assigned_to IS NULL;
   ```
   *Impact:* Directly accelerates vehicle assignment queries in `api.php?t=vehicles`.

---

## 8. Database Integrity & Structural Observations

Systematic review in [`activity-5/data-integrity-review.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/activity-5/data-integrity-review.md) verified:
1. **Surrogate & Natural Keys:** Clean surrogate keys across 7 entities and a natural composite key `(driver_id, vehicle_id)` on `driver_vehicle`.
2. **Engine-Level Check Constraints:** Strict domain boundaries on booking statuses, positive payment amounts, rating ranges (1 to 5), and vehicle assignment timestamp sequences.
3. **Referential Actions:** `ON DELETE SET NULL` on `booking.driver_id` correctly preserves passenger trip history if driver profiles are deleted. `ON DELETE RESTRICT` on transactions prevents orphaned data.
4. **One-Rating-Per-Ride Constraint:** `CONSTRAINT uq_rating_booking_customer UNIQUE (booking_id, customer_id)` prevents duplicate reviews.

---

## 9. Comprehensive Recommendations Matrix

Detailed in [`activity-5/recommendations.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/activity-5/recommendations.md):

| Priority | Category | Finding / Area | Recommended Technical Action |
|---|---|---|---|
| **Immediate (High)** | Security | Superuser Connection | Change `config.php` and `.env.example` to default to `DB_USER=habalgo_app_user` |
| **Immediate (High)** | Configuration | Variable Mismatch | Align `.env.example` (`DB_PASS`) with `config.php` (`getenv('DB_PASS')`) |
| **Immediate (High)** | Configuration | Missing `.env` Parser | Add `parse_ini_file(__DIR__ . '/.env')` in `config.php` |
| **Immediate (High)** | Configuration | Default DB Fallback | Change fallback default in `config.php` from `'habalgo'` to `'grp00_habalgodb'` |
| **Follow-Up (Medium)**| Performance | Active Bookings Index | `CREATE INDEX idx_booking_active_status ON habalgo.booking(booking_status) WHERE booking_status IN ('Pending','Confirmed','In Progress');` |
| **Follow-Up (Medium)**| Performance | Active Vehicle Index | `CREATE INDEX idx_driver_vehicle_active ON habalgo.driver_vehicle(vehicle_id, driver_id) WHERE assigned_to IS NULL;` |
| **Follow-Up (Medium)**| Maintenance | Routine Sweeps | Schedule weekly standalone `ANALYZE` and `VACUUM` under `postgres` or `pg_maintain` |
| **No Action (Low)** | Integrity | Foreign Key Constraints | Preserve `ON DELETE SET NULL` on `booking.driver_id` and `RESTRICT` on transactions |
| **No Action (Low)** | Performance | Existing Secondary Indexes| Maintain `idx_booking_customer`, `idx_booking_driver`, `idx_booking_date`, etc. |

---

## 10. Google Sheets Activity 5 Tracker Entry

| Column Header | Activity 5 Tracker Value |
|---|---|
| **1. Project** | HabalGo – Ride and Booking Management System (Group 00 / Group 06) |
| **2. Database Inspected** | `grp00_habalgodb` (Schema: `habalgo`, PostgreSQL 18.6 MSVC 64-bit on Windows 11) |
| **3. Account and Role Used** | `app_runtime_grp` (`habalgo_app_user`), `app_readonly_grp` (`habalgo_readonly_user`), `postgres` (DBA Maintenance) |
| **4. Health Check Result** | Healthy — 8 tables verified, 7 serial sequences, 0 lock contentions, 0 deadlocks, 99.55% buffer cache hit ratio, ~8.5 MB footprint |
| **5. Maintenance Performed** | `ANALYZE (VERBOSE)` on all 8 tables; `VACUUM (VERBOSE, ANALYZE)` on transactional relations (`booking`, `payment`, `driver_vehicle`, `driver`); verified dead tuple clearance |
| **6. Query Analyzed** | Query A (`$BK` booking listing 5-table join), Query B (customer aggregation), Query C (vehicle-driver assignments), Query F (dashboard telemetry) |
| **7. Recommendation Priority** | High Priority — Synchronize `.env.example` (`DB_PASS`) with `config.php`, implement native `.env` parser, switch PHP connection from `postgres` to `habalgo_app_user`, and create partial index on active bookings |
| **8. Evidence Folder Link** | [`activity-5/evidence/`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/activity-5/evidence/) and [`db-maintenance/habalgo/evidence/`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/db-maintenance/habalgo/evidence/) |
| **9. Feedback Sent to Owners** | Documented in [`activity-5/recommendations.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/activity-5/recommendations.md) and [`activity-5/configuration-review.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/activity-5/configuration-review.md) |
| **10. PDF Progress Document** | `ACT 3 Progress Documentation.pdf` (Audited) |
| **11. Last Updated** | November 17, 2026 |

---

## 11. Security & Project Preservation Compliance

- **No Repository Alteration:** The original target group's GitHub repository clone was preserved without modifications.
- **Zero Credential Exposure:** No passwords, SCRAM-SHA-256 hashes, or private environment variables were committed or exposed.
- **Preserved PHP Architecture:** All SQL scripts and performance evaluations adhere strictly to native PHP PDO prepared statements.
- **Non-Destructive Operations:** Routine maintenance relied exclusively on online `ANALYZE` and `VACUUM`. No tables were dropped, truncated, or subjected to `VACUUM FULL`.

---

## 12. Artifact Inventory & Screenshot Verification Checklist

The complete Activity 5 monitoring and maintenance suite is permanently preserved in:
- [`activity-5/`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/activity-5/)
- [`db-maintenance/habalgo/`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/db-maintenance/habalgo/)

### Artifact Mapping:
- **`sql/01_database_inspection.sql`**: Catalog inventory, 8 tables, sequences, constraints, and secondary index audit.
- **`sql/02_access_control_inspection.sql`**: Role attributes, memberships, grants, and sequence permissions.
- **`sql/03_monitoring_queries.sql`**: Active sessions, connection capacity, buffer cache hit ratio, and lock contention.
- **`sql/04_analyze_maintenance.sql`**: Standalone verbose statistics refresh and `pg_stats` verification.
- **`sql/05_vacuum_maintenance.sql`**: Standalone verbose dead tuple reclamation, MVCC health, and freeze cutoff advance.
- **`sql/06_query_performance.sql`**: Production queries (Query A–F) for EXPLAIN & index benchmarks.
- **`evidence/README.md`**: Execution logs catalog and 13-point step-by-step screenshot capture guide for pgAdmin 4 and psql.
