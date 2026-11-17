# Database Maintenance Report: VACUUM and ANALYZE
## COMP 018 – Database Administration | Activity 5: Parts C & D
**Target Project:** BoardTrack – Boarding House & Rental Management System  
**Target Database:** `boardtrack_db`  
**Schema:** `public`  
**Database Platform:** PostgreSQL 18.6 on Windows 10/11  
**Maintenance Scope:** 7 Core Business Tables (`property`, `room`, `tenant`, `lease`, `payment`, `utility_bill`, `app_user`)  

---

## 1. Theoretical Foundation of PostgreSQL Maintenance

### 1.1 The Role of `ANALYZE` in Query Optimization
PostgreSQL relies on a sophisticated **Cost-Based Optimizer (CBO)** to determine the most efficient execution plan for any SQL query (e.g., whether to use an Index Scan, a Sequential Scan, a Hash Join, or a Nested Loop).

The query planner does not read every table row before deciding how to execute a query. Instead, it consults internal statistical catalogs (`pg_statistic`, accessible via the `pg_stats` view). These statistics include:
* Estimated row counts (`reltuples`).
* Number of disk pages (`relpages`).
* Fraction of null values per column.
* Distinct value counts (`n_distinct`).
* Most Common Values (MCV) lists and frequencies.
* Histograms representing value distributions across data ranges.

When data is inserted, updated, or deleted, these statistics become outdated. The **`ANALYZE`** command samples rows from the target tables and refreshes these planner statistics.
> **Key Note:** `ANALYZE` does not alter table structures or reclaim disk storage; its sole purpose is providing accurate statistical profiles to the query planner. Running `ANALYZE` does not automatically make every query faster unless the planner previously chose an inefficient plan due to stale statistics.

### 1.2 The Role of `VACUUM` in Space Reclamation and MVCC Health
Because PostgreSQL uses Multi-Version Concurrency Control (MVCC):
* An `UPDATE` writes a new row version while leaving the older row version in place.
* A `DELETE` marks the existing row version as expired.
* Old versions become **dead tuples** once no active transaction needs to see them.

Without maintenance, dead tuples remain stored on disk pages, causing **table bloat** and degrading scan performance.
* **Standard `VACUUM`:** Scans data pages, marks dead tuple space as reusable for future `INSERT` or `UPDATE` operations, and updates the **Visibility Map** (which allows Index-Only Scans). Standard `VACUUM` runs **concurrently** with normal database operations and takes only a weak lock (`SHARE UPDATE EXCLUSIVE`), allowing users to continue reading and writing to tables.
* **`VACUUM FULL`:** Rewrites the entire table into a new disk file to physically return space to the OS filesystem. However, `VACUUM FULL` requires an **`ACCESS EXCLUSIVE`** lock, freezing all application access to the table. Therefore, in production environments and for Activity 5, `VACUUM FULL` is prohibited during online maintenance.

---

## 2. Pre-Maintenance Verification and Safety Protocol

Prior to executing maintenance commands:
1. **Target Database Check:** Confirm connection to `boardtrack_db` (or user's active database).
2. **User Authorization Check:** Maintenance commands require table ownership, superuser status (`postgres`), or membership in PostgreSQL 18's built-in **`pg_maintain`** role.
3. **Transaction Context Check:** `VACUUM` cannot run inside a transaction block. Commands must be run individually without `BEGIN` / `COMMIT`.
4. **Data Preservation Guarantee:** No data records may be deleted or modified to simulate maintenance.

---

## 3. Maintenance Execution Protocol

The maintenance script `sql/06_maintenance_operations.sql` executes the following sequence:

```sql
-- Step 1: Global statistics refresh
ANALYZE;

-- Step 2: Table-by-table concurrent vacuuming and analysis
VACUUM (VERBOSE, ANALYZE) public.property;
VACUUM (VERBOSE, ANALYZE) public.room;
VACUUM (VERBOSE, ANALYZE) public.tenant;
VACUUM (VERBOSE, ANALYZE) public.lease;
VACUUM (VERBOSE, ANALYZE) public.payment;
VACUUM (VERBOSE, ANALYZE) public.utility_bill;
VACUUM (VERBOSE, ANALYZE) public.app_user;
```

---

## 4. Maintenance Results and Observations

| Application Table | Live Tuples (Before) | Dead Tuples (Before) | Operation Performed | Expected Post-Maintenance Outcome | Status |
|---|---|---|---|---|---|
| `public.property` | 2 | 0 | `VACUUM (VERBOSE, ANALYZE)` | `last_vacuum` and `last_analyze` updated; 0 dead tuples | `BLOCKED` (Credential Required) |
| `public.room` | 6 | 0-2 (from trigger updates) | `VACUUM (VERBOSE, ANALYZE)` | Dead tuples from room status trigger reclaimed; stats refreshed | `BLOCKED` (Credential Required) |
| `public.tenant` | 4 | 0 | `VACUUM (VERBOSE, ANALYZE)` | Visibility map updated; planner statistics refreshed | `BLOCKED` (Credential Required) |
| `public.lease` | 4 | 0-1 (from seed/test updates)| `VACUUM (VERBOSE, ANALYZE)` | GiST exclusion index checked; stats updated | `BLOCKED` (Credential Required) |
| `public.payment` | 6 | 0 | `VACUUM (VERBOSE, ANALYZE)` | `idx_payment_lease` updated; free space marked reusable | `BLOCKED` (Credential Required) |
| `public.utility_bill`| 4 | 0 | `VACUUM (VERBOSE, ANALYZE)` | Date distribution histograms updated; dead tuples cleared | `BLOCKED` (Credential Required) |
| `public.app_user` | 3 | 0 | `VACUUM (VERBOSE, ANALYZE)` | Password hash storage maintained; stats refreshed | `BLOCKED` (Credential Required) |

---

## 5. Execution Instructions for Live Database

To execute the maintenance routine:

```powershell
# Set psql path
$env:Path += ";C:\Program Files\PostgreSQL\18\bin"

# Run maintenance operations (prompts securely for password)
psql -h localhost -p 5432 -U postgres -d boardtrack_db -f db-maintenance/sql/06_maintenance_operations.sql
```
