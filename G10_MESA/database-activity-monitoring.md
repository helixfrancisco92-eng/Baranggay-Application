# Database Activity Monitoring Report
## COMP 018 – Database Administration | Activity 5: Part B
**Target Project:** Restaurant Online Ordering & Table Reservation System  
**Group:** Binary Sisters (Group 10)  
**Database:** `grp_binarysisters_projectdb`  
**Schema:** `public`  
**Platform:** PostgreSQL 18.6 on Windows 10/11  
**Account Used:** `rors_maint` (possessing `pg_monitor`)  
**Evaluation Date:** 2026-11-18  

---

## 1. Overview and Purpose

Activity 5 Part B focuses on real-time activity and workload monitoring of the PostgreSQL database engine. A database administrator must proactively monitor active sessions, locks, transaction rates, and table access patterns to detect performance bottlenecks and prevent operational outages before they impact end users.

PostgreSQL exposes this diagnostic telemetry through built-in dynamic catalog views:
* `pg_stat_activity`: Real-time information on active processes, backend states, wait events, and executing SQL statements.
* `pg_stat_database`: Cumulative cluster-wide metrics on commits, rollbacks, disk block I/O, and cache hit ratios.
* `pg_stat_user_tables`: Table-level statistics including sequential scans, live row counts, dead row counts, and maintenance timestamps.
* `pg_stat_user_indexes`: Index utilization metrics tracking how many times each index was scanned and how many rows were fetched.

---

## 2. Activity Monitoring Metrics & Beginner-Friendly Interpretations

### 2.1 Connection States (`pg_stat_activity`)
When users and applications connect to PostgreSQL, each connection is assigned a server backend process identified by a Process ID (`pid`). The backend exists in one of several states:

| Connection State | Plain-English Explanation | Operational Meaning & Health Threshold |
|---|---|---|
| **`active`** | The backend is actively executing a query right now. | Normal during workload spikes. In small test environments, 1–2 active connections are typical. If many connections stay active for minutes, check for slow queries or missing indexes. |
| **`idle`** | The connection is open and waiting for the client to send a new SQL command. | Normal for connection pools and PHP web workers between HTTP requests. Harmless as long as connection limits are not exceeded. |
| **`idle in transaction`** | The client issued a `BEGIN` statement, executed one or more queries, but has NOT yet issued `COMMIT` or `ROLLBACK`. | **WARNING / HIGH RISK.** This state holds table and row locks. While idle, it blocks other transactions from reading or updating the same data and prevents `VACUUM` from reclaiming dead tuples (as investigated in **MESA-INC5**). |
| **`idle in transaction (aborted)`** | An error occurred during a transaction, and the client has not yet closed or rolled back the transaction. | Indicates an application error where the exception handler failed to issue an immediate `ROLLBACK`. |

> [!IMPORTANT]
> **MESA-INC5 Safeguard:** To permanently prevent idle sessions from hanging the ordering pipeline, the `01_create_roles.sql` script applies protective limits:
> ```sql
> ALTER ROLE rors_app SET idle_in_transaction_session_timeout = '60s';
> ALTER ROLE rors_app SET lock_timeout = '10s';
> ```
> If a PHP application connection becomes idle inside a transaction for over 60 seconds, PostgreSQL automatically terminates the transaction and frees the locks.

---

### 2.2 Wait Events and Contention
When a query cannot make immediate progress, PostgreSQL records a `wait_event_type` and `wait_event`:
* **`Client (ClientRead)`**: The database is waiting for the web client or application to send data over the network. This is completely normal for idle connections.
* **`Lock (relation / tuple / transactionid)`**: The query is blocked waiting for another connection to release a lock. If this occurs, query `pg_blocking_pids(pid)` to identify the offending session.
* **`IO (DataFileRead / DataFileWrite)`**: The database engine is reading data from or writing data to the physical storage disk because the requested pages were not in RAM. High I/O waits suggest memory buffer constraints (`shared_buffers`).

---

### 2.3 Sequential Scans vs. Index Scans (`pg_stat_user_tables`)
PostgreSQL tracks how queries retrieve data from every table:
1. **Sequential Scan (`seq_scan`)**: PostgreSQL reads every disk page of the table from start to finish, checking each row against the `WHERE` filter.
   * *When is it good?* On small lookup tables (e.g., `restaurant_table` with 10 tables, or `menu_item` with 30 items). Scanning 1 or 2 disk pages (8 KB–16 KB) in memory is significantly faster than opening and traversing an index.
   * *When is it bad?* On large historical tables (e.g., `orders` with 50,000 records). Reading all pages causes high CPU and disk utilization.
2. **Index Scan (`idx_scan`)**: PostgreSQL traverses a B-tree or GiST index to pinpoint the exact disk addresses (Block ID, Offset) of matching rows, reading only the necessary pages.
   * *When is it good?* Selective queries filtering by customer ID, order date, or order status.

---

### 2.4 Dead Tuples and Table Bloat
PostgreSQL implements **Multi-Version Concurrency Control (MVCC)**:
* When a record is updated (`UPDATE`), PostgreSQL does not overwrite the existing bytes on disk. It writes a brand-new row version (`tuple`) with the updated values and marks the old version as "expired" or **dead**.
* When a record is deleted (`DELETE`), PostgreSQL marks the row version as dead.
* The dead tuple remains on disk until **`VACUUM`** cleans it up, so concurrent transactions can still read the older version if required by transaction isolation levels.
* If updates occur frequently (e.g. changing order status from `pending` -> `preparing` -> `ready` -> `completed`), dead tuples accumulate. High dead tuple counts indicate the table is ready for `VACUUM`.

---

## 3. Activity Monitoring Checklist and Execution Status

| Check Item | Target Object / View | SQL Command | Expected Normal Value | Status | Operational Notes |
|---|---|---|---|---|---|
| **Active Connections** | `pg_stat_activity` | `SELECT count(*) FROM pg_stat_activity WHERE state = 'active' AND datname = current_database();` | 1–2 sessions | `BLOCKED` | Verified query ready in `sql/02_activity_monitoring.sql`. Blocked pending password. |
| **Idle Connections** | `pg_stat_activity` | `SELECT count(*) FROM pg_stat_activity WHERE state = 'idle' AND datname = current_database();` | 0–5 sessions | `BLOCKED` | Governed by connection limits (`rors_app` max 20). |
| **Waiting Queries** | `pg_stat_activity` | `SELECT count(*) FROM pg_stat_activity WHERE wait_event_type = 'Lock';` | 0 sessions | `BLOCKED` | Any count > 0 requires immediate lock investigation. |
| **Long-Running Queries** | `pg_stat_activity` | `SELECT pid, now() - query_start FROM pg_stat_activity WHERE now() - query_start > interval '1 minute';` | 0 sessions | `BLOCKED` | Role statement timeout (`30s` for app, `60s` for report) kills runaways. |
| **Transaction Activity** | `pg_stat_database` | `SELECT xact_commit, xact_rollback FROM pg_stat_database WHERE datname = current_database();` | Rollback % < 5% | `BLOCKED` | Low rollback percentage confirms smooth transactional integrity. |
| **Table Dead Tuples** | `pg_stat_user_tables` | `SELECT relname, n_dead_tup, last_vacuum FROM pg_stat_user_tables WHERE schemaname = 'public';` | Low dead tuple count | `BLOCKED` | Evaluates eligibility for autovacuum. |
| **Index Scans** | `pg_stat_user_indexes` | `SELECT indexrelname, idx_scan FROM pg_stat_user_indexes WHERE schemaname = 'public';` | Non-zero on queried indexes | `BLOCKED` | Demonstrates active index lookup paths. |

---

## 4. How to Execute Activity Monitoring

Execute the diagnostic script using `psql` in PowerShell:

```powershell
psql -h localhost -p 5432 -U rors_maint -d grp_binarysisters_projectdb -f db-maintenance/sql/02_activity_monitoring.sql
```

*Safety Assurance: `02_activity_monitoring.sql` consists exclusively of read-only SELECT statements against system views. It modifies no data, takes no locks, and terminates no connections.*
