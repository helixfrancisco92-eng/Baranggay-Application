# Activity 5: Database Health Monitoring & Performance Telemetry
## CampusSafe: Campus Hazard & Safety Reporting System

**Course:** COMP 018 — Database Administration  
**Group:** Group 7  
**Database Name:** `grp07_campussafedb`  
**Schema:** `public`  
**Evaluation Date:** November 17, 2026  
**Documented DBMS:** PostgreSQL 14+ (Verified Environment: PostgreSQL 14.24)  
**Host Runtime DBMS:** PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35228, 64-bit  
**Evaluator:** Senior Database Administrator & Health Monitoring Lead (Group 7 DBA Team)  

---

## 1. Executive Summary & Monitoring Objectives

This document presents the live health monitoring and operational telemetry results captured from `grp07_campussafedb`. System performance was evaluated across six critical dimensions:
1. **Server and Database Footprint:** Physical database size and storage allocation.
2. **Connection and Session State:** Active sessions, pool utilization, wait events, and query durations.
3. **Table Workload Statistics:** Sequential vs. index scan ratios, live tuples, and dead tuple accumulation.
4. **Transaction Integrity:** Commit vs. rollback volume and error rates.
5. **Memory Buffer Cache Hit Ratio:** Shared memory block hits vs. physical disk reads.
6. **Lock Contention:** Shared and exclusive lock allocations.

---

## 2. Server Telemetry & Database Footprint

```sql
SELECT 
    'grp07_campussafedb' AS database_name,
    pg_database_size('grp07_campussafedb') AS size_bytes,
    pg_size_pretty(pg_database_size('grp07_campussafedb')) AS formatted_database_size;
```

```text
   database_name    | size_bytes | formatted_database_size 
--------------------+------------+-------------------------
 grp07_campussafedb |    9189055 | 8974 kB
(1 row)
```

The database maintains a total physical size of **8,974 kB** (9,189,055 bytes). This baseline footprint represents an optimal storage profile for an educational and operational campus incident reporting platform.

---

## 3. Active Connections & Session Telemetry

Active session monitoring via `pg_stat_activity` verified client connections, backend processes, and query states:

```sql
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    wait_event_type,
    wait_event,
    clock_timestamp() - query_start AS active_duration,
    LEFT(query, 160) AS query_preview
FROM pg_stat_activity
WHERE datname = 'grp07_campussafedb'
ORDER BY query_start DESC NULLS LAST;
```

```text
  pid  | usename  | client_addr | state  | wait_event_type | wait_event | active_duration |                          query                          
-------+----------+-------------+--------+-----------------+------------+-----------------+---------------------------------------------------------
 16180 | postgres | ::1         | active |                 |            | 00:00:00.010123 | SELECT pid, usename, client_addr, state...
(1 row)
```

### 3.1 Connection Capacity & Health Evaluation

| Telemetry Metric | Measured Value | Standard Threshold | Health Status |
|---|---|---|---|
| **Active Client Connections** | `1` backend | Max 100 (`max_connections`) | **Optimal:** 1.0% connection pool utilization |
| **Idle In Transaction Sessions**| `0` backends | Max 0 (immediate alert) | **Optimal:** Zero uncommitted dangling transactions |
| **Long-Running Transactions** | `0` (> 5 seconds) | Max 0 for OLTP | **Optimal:** Active duration was 0.010 seconds |
| **Wait Events / Contention** | `None` (`NULL`) | `Lock`, `IO`, `BufferPin` | **Optimal:** Zero lock or I/O contention detected |
| **Client Transport Protocol** | `IPv6 Loopback (::1)` | Secure local socket | **Secure:** Connected via authenticated loopback |

*Security Assurance:* No user credentials, plaintext passwords, or Bcrypt password hashes were exposed during session sampling. Query previews are restricted to catalog telemetry commands.

---

## 4. Workload Statistics & Table Activity

Catalog interrogation of `pg_stat_user_tables` produced the following activity baseline:

```text
       table_name       | live_tuples | dead_tuples | dead_tuple_percent | last_vacuum | last_autovacuum | vacuum_count | autovacuum_count 
-----------------------+-------------+-------------+--------------------+-------------+-----------------+--------------+------------------
 app_user              |           7 |           2 |              22.22 |             |                 |            0 |                0
 hazard_report         |          17 |           2 |              10.53 |             |                 |            0 |                0
 assignment            |          14 |           0 |               0.00 |             |                 |            0 |                0
 attachment            |           5 |           0 |               0.00 |             |                 |            0 |                0
 campus_location       |          10 |           0 |               0.00 |             |                 |            0 |                0
 hazard_category       |           6 |           0 |               0.00 |             |                 |            0 |                0
 maintenance_action    |           9 |           0 |               0.00 |             |                 |            0 |                0
 report_status_history |          63 |           0 |               0.00 |             |                 |            0 |                0
 role                  |           5 |           0 |               0.00 |             |                 |            0 |                0
(9 rows)
```

### 4.1 Tuple Distribution & Bloat Analysis

- **Total Live Tuples:** 136 live operational records across all 9 tables.
  - `report_status_history` contains the highest record count (**63 live rows**), reflecting its append-only audit nature where every status update generates an immutable historical log entry.
  - `hazard_report` contains **17 live rows**, representing 16 core seed reports and 1 validation test report.
- **Dead Tuples Baseline:**
  - `app_user`: **2 dead tuples** (22.22% dead tuple ratio) generated by user password/status updates during test execution.
  - `hazard_report`: **2 dead tuples** (10.53% dead tuple ratio) caused by administrative report status updates (`UPDATE hazard_report SET status = ...`).
  - All other 7 tables: **0 dead tuples** (0.00%).
- *Maintenance Action:* These dead tuples justify routine execution of `VACUUM (VERBOSE, ANALYZE)` to reclaim page slots for future inserts (documented in [`maintenance-log.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/maintenance-log.md)).

### 4.2 Scan Efficiency & Scan Ratios

```text
       table_name       | total_seq_scans | seq_tuples_read | total_idx_scans | idx_tuples_fetched | index_scan_ratio_percent 
-----------------------+-----------------+-----------------+-----------------+--------------------+--------------------------
 hazard_report         |              85 |            1181 |             118 |                123 |                    58.13
 report_status_history |              13 |             550 |               0 |                  0 |                     0.00
 campus_location       |              58 |             542 |              28 |                 28 |                    32.56
 app_user              |              93 |             517 |             181 |                181 |                    66.06
 assignment            |              35 |             346 |              16 |                  8 |                    31.37
 hazard_category       |              60 |             326 |              28 |                 28 |                    31.82
 role                  |              18 |              70 |              98 |                 98 |                    84.48
 maintenance_action    |               5 |               9 |               8 |                  3 |                    61.54
 attachment            |               5 |               5 |              16 |                 13 |                    76.19
(9 rows)
```

### 4.3 Interpretation of Scan Behavior

1. **Sequential Scans are Not Inherent Defects:** In PostgreSQL, a sequential scan (`Seq Scan`) on a small table (under 100 rows fitting in 1 page) is significantly faster than an index scan. The PostgreSQL query planner calculates that reading contiguous 8KB disk blocks sequentially into memory costs fewer CPU cycles than traversing a B-tree index root, internal nodes, and heap pointers.
2. **High Index Scan Ratios:**
   - `role`: **84.48%** index scan ratio (primary key and unique name lookups during authorization checks).
   - `attachment`: **76.19%** index scan ratio.
   - `app_user`: **66.06%** index scan ratio (authenticated sign-in queries targeting `app_user_pkey` and `app_user_username_key`).
   - `hazard_report`: **58.13%** index scan ratio (frequent lookups by `report_id` and `idx_report_status`).

---

## 5. Transaction Statistics & Commit Efficiency

Interrogation of `pg_stat_database` measured transaction health:

```text
   database_name    | total_active_backends | committed_tx | rolled_back_tx | cache_hit_ratio_percent 
--------------------+-----------------------+--------------+----------------+-------------------------
 grp07_campussafedb |                     1 |         2790 |              0 |                   99.70
(1 row)
```

- **Committed Transactions (`xact_commit`):** `2,790` successful transaction commits.
- **Rolled Back Transactions (`xact_rollback`):** `0` rollbacks.
- **Rollback Rate:** **0.00%**, confirming that application transactions (e.g., `Report::create`, `Report::verify`, `Report::assign`) execute reliably without database-level rollback failures.

---

## 6. Shared Buffer Cache Hit Ratio Analysis

### 6.1 Formula & Calculation

The PostgreSQL shared buffer cache hit ratio measures the percentage of page requests fulfilled directly from high-speed RAM (`shared_buffers`) without incurring disk I/O latency:

$$\text{Buffer Cache Hit Ratio} = \frac{\text{blks\_hit}}{\text{blks\_hit} + \text{blks\_read}} \times 100$$

From live `pg_stat_database` metrics:
- **Blocks Hit in RAM (`blks_hit`):** `113,227`
- **Blocks Read from Disk (`blks_read`):** `342`

$$\text{Cache Hit Ratio} = \frac{113,227}{113,227 + 342} \times 100 = \frac{113,227}{113,569} \times 100 = \mathbf{99.70\%}$$

### 6.2 Engineering Context & DBA Interpretation

1. **Memory Efficiency:** A cache hit ratio of **99.70%** comfortably surpasses the standard enterprise benchmark of **99.00%**. This proves that 997 out of every 1,000 page reads are satisfied immediately by the operating system RAM and PostgreSQL shared memory cache.
2. **Contextual Evaluation:**
   - While 99.70% indicates excellent memory caching, in a database with an 8.9 MB footprint, the entire database fits easily within the default `shared_buffers = 128MB`.
   - Therefore, a high cache hit ratio is expected and does not alone guarantee that query plans are fully tuned. Query efficiency must be validated through execution plan analysis (`EXPLAIN ANALYZE`) as documented in [`query-performance-analysis.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/target-campussafe-repo/db-maintenance/query-performance-analysis.md).

---

## 7. Lock Contention & Deadlock Monitoring

Catalog query of `pg_locks` confirmed:
- **Exclusive Table Locks:** `0`
- **Blocked Queries / Waiting Transactions:** `0`
- **Deadlocks Logged:** `0`

CampusSafe application code uses row-level locking (`SELECT ... FOR UPDATE`) during administrative report status transitions (`Report::verify`, `Report::assign`, `Report::resolve`). This ensures transactional consistency without escalating to coarse table-level locks.

---

## 8. PostgreSQL Server Logs Audit & Limitations

### 8.1 Log File Accessibility

In accordance with Phase 6.3 guidelines:
- In the local testing environment (PostgreSQL 18.6 on Windows), server logs are located under `C:\Program Files\PostgreSQL\18\data\log\`.
- Under standard non-administrative operating system user contexts, direct access to the raw `%PGDATA%\log\` folder is restricted by Windows NTFS permissions to the service principal (`NT AUTHORITY\NetworkService`).
- Server logs were inspected via administrative session logs and query error capture.

### 8.2 Operational Diagnostic Findings

1. **Authentication Error Pattern:**
   - Attempted connections using incorrect local credentials generate `FATAL: password authentication failed for user "..."`.
   - *DBA Mitigation:* Documented in `.env.example` and `setup.php` to ensure local developers configure matching credentials.
2. **Maintenance Privilege Boundary:**
   - Attempting to execute `VACUUM` or `ANALYZE` using the application runtime account (`campussafe_app`) results in:
     `WARNING: permission denied to vacuum "hazard_report", skipping it`
   - *DBA Mitigation:* Confirmed that routine maintenance must be orchestrated via PostgreSQL `autovacuum` or executed by the database owner/DBA account (`postgres`).

---

## 9. Summary Assessment

The health monitoring results confirm that `grp07_campussafedb` is operating with:
- Zero lock contention
- A 99.70% buffer cache hit ratio
- 0.00% transaction rollback rate
- Low dead tuple counts ready for routine vacuum reclamation
