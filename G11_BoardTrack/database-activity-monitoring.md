# Database Activity Monitoring Report
## COMP 018 – Database Administration | Activity 5: Part B
**Target Project:** BoardTrack – Boarding House & Rental Management System  
**Target Database:** `boardtrack_db`  
**Schema:** `public`  
**Database Platform:** PostgreSQL 18.6 (x64) on Windows 10/11  
**Monitoring System Catalogs:** `pg_stat_activity`, `pg_stat_database`, `pg_stat_user_tables`, `pg_stat_user_indexes`  

---

## 1. Overview and Purpose of Activity Monitoring

Activity monitoring is an essential responsibility of a Database Administrator. It provides visibility into what the database engine is doing at any given moment. In PostgreSQL, dynamic activity and workload statistics are exposed through system views:

1. **`pg_stat_activity`**: Shows one row per server process, displaying client IP, connected username, current execution state, wait events, and the currently running SQL query.
2. **`pg_stat_database`**: Tracks database-wide metrics including committed vs. rolled-back transactions, blocks read from disk vs. hit in shared memory (cache hit ratio), and deadlock counts.
3. **`pg_stat_user_tables`**: Records table-level operational statistics: sequential scans, tuples inserted/updated/deleted, and dead tuples produced by PostgreSQL's Multi-Version Concurrency Control (MVCC).
4. **`pg_stat_user_indexes`**: Measures how many times each secondary or primary key index was scanned by the query planner.

---

## 2. Activity Metrics Analysis (Beginner-Friendly Explanation)

### 2.1 Connection States (`pg_stat_activity`)
When a client connects to PostgreSQL, its session transitions through different states:
* **`active`**: The backend process is actively executing a query or command right now. In a typical small-to-medium application, only a small fraction of connections are `active` at any given millisecond.
* **`idle`**: The client is connected, but no query is currently running. The client is waiting for the user or application code to send the next request. This is completely normal and healthy.
* **`idle in transaction`**: **Critical Warning State.** A transaction was opened with `BEGIN`, a query was executed, but neither `COMMIT` nor `ROLLBACK` was issued. The session is idle, but PostgreSQL must keep row locks, table locks, and older tuple snapshots open. If allowed to persist, it blocks other transactions and prevents autovacuum from cleaning dead tuples, leading to table bloat and freezing locks.
* **`idle in transaction (aborted)`**: An error occurred inside a transaction block, and the application has not yet sent `ROLLBACK`.

### 2.2 Waiting Queries and Contention
When a query attempts to access a table or row that is already locked by another transaction (for example, two administrators trying to update the same room row simultaneously without OCC), the waiting session enters a **wait state**:
* `wait_event_type = 'Lock'`: The session is paused waiting for a heavyweight table lock or row-level exclusive lock.
* `pg_blocking_pids(pid)`: Identifies the exact process ID (PID) of the blocking transaction.

### 2.3 Sequential Scans vs. Index Scans (`pg_stat_user_tables`)
* **Sequential Scan (`seq_scan`)**: PostgreSQL reads every page of the table from beginning to end to find matching rows. For small tables like `property` (e.g., 2 properties) or `room` (e.g., 6 rooms), a sequential scan is the fastest possible approach because reading a single 8 KB data block is much cheaper than traversing an index tree.
* **Index Scan (`idx_scan`)**: PostgreSQL navigates a B-tree or GiST index to look up only the specific disk blocks containing matching rows. For large transaction tables (`lease`, `payment`, `utility_bill`), index scans are vital to prevent queries from slowing down as the table grows to thousands of records.

### 2.4 Dead Tuples and MVCC
PostgreSQL uses **Multi-Version Concurrency Control (MVCC)** to handle concurrent read and write operations without locking:
* When a row is updated, PostgreSQL does not overwrite the existing data on disk. Instead, it marks the old row version as expired and writes a new row version.
* When a row is deleted, it is simply marked as deleted (dead).
* These expired row versions are called **dead tuples**. They occupy disk space until cleaned up by the `VACUUM` process. If dead tuples accumulate faster than they are vacuumed, the table suffers from **table bloat**.

---

## 3. Monitoring Verification Checklist

| Metric Checked | Catalog Source | Expected Baseline Result | Evaluation Status | Diagnostic Action & Remarks |
|---|---|---|---|---|
| **Active Sessions** | `pg_stat_activity` | 1-2 active sessions (the DBA running diagnostics) | `BLOCKED` (Credential Required) | Script ready: `sql/02_activity_monitoring.sql`. Verifies active vs. idle ratio. |
| **Idle Connections** | `pg_stat_activity` | Low count (Node.js connection pool idle connections) | `BLOCKED` (Credential Required) | Node.js `pg.Pool` maintains idle connections for fast reuse. |
| **Idle in Transaction** | `pg_stat_activity` | **0 sessions** | `BLOCKED` (Credential Required) | Confirms BoardTrack routes properly commit or roll back transactions. |
| **Waiting Queries** | `pg_stat_activity` | **0 waiting queries** | `BLOCKED` (Credential Required) | Proves no locking contention or deadlock stalls are active. |
| **Long-Running Queries**| `pg_stat_activity` | **0 queries > 30s** | `BLOCKED` (Credential Required) | Ensures no runaway analytical queries starve system resources. |
| **Transaction Commits** | `pg_stat_database` | Steady commit growth, high commit ratio (>98%) | `BLOCKED` (Credential Required) | Compares `xact_commit` to `xact_rollback`. |
| **Table Scan Statistics**| `pg_stat_user_tables` | Low `seq_scan` on transactional tables; normal on small catalogs | `BLOCKED` (Credential Required) | Detailed in `sql/03_table_statistics.sql`. |
| **Dead Tuples Count** | `pg_stat_user_tables` | Minimal dead tuples (<50 per table in fresh seed) | `BLOCKED` (Credential Required) | Evaluates autovacuum threshold readiness. |
| **Index Usage Ratios** | `pg_stat_user_tables` | Primary keys and FKs utilized during joins | `BLOCKED` (Credential Required) | Detailed in `sql/04_index_monitoring.sql`. |

---

## 4. Operational Instructions to Run Activity Monitoring

To execute the activity monitoring script on the live database:

```powershell
# Set psql path
$env:Path += ";C:\Program Files\PostgreSQL\18\bin"

# Run activity monitoring script
psql -h localhost -p 5432 -U postgres -d boardtrack_db -f db-maintenance/sql/02_activity_monitoring.sql
```
