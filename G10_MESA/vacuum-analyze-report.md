# Database Maintenance Report: VACUUM & ANALYZE
## COMP 018 – Database Administration | Activity 5: Parts C & D
**Target Project:** Restaurant Online Ordering & Table Reservation System  
**Group:** Binary Sisters (Group 10)  
**Database:** `grp_binarysisters_projectdb`  
**Schema:** `public`  
**Engine:** PostgreSQL 18.6 on Windows 10/11  
**Account Tested:** `rors_maint` (possessing `pg_maintain` and `pg_monitor`)  
**Evaluation Date:** 2026-11-18  

---

## 1. Objectives & Theoretical Background

Database maintenance is essential to sustaining performance, reclaiming storage, and ensuring the PostgreSQL query planner makes intelligent execution choices. In Activity 5, two foundational PostgreSQL maintenance operations are analyzed and performed: **`ANALYZE`** and **`VACUUM`**.

### 1.1 The Role of `ANALYZE` in Query Optimization
PostgreSQL employs a **Cost-Based Optimizer (CBO)** to determine the most efficient execution plan for any SQL query (e.g. deciding whether to perform a Sequential Scan or use an Index Scan).
* The query planner relies on statistical distributions of table data stored in the `pg_statistic` system catalog (viewable via `pg_stats`).
* When tables undergo data changes (INSERT, UPDATE, DELETE), statistical distributions can become stale. If the planner believes a table has 10 rows when it actually has 100,000, it may choose an inefficient plan.
* Running `ANALYZE` collects statistical samples across table columns (row counts, null fractions, most common values [MCV], distinct values, and quantile histograms) without reading the entire table or blocking concurrent transactions.
* **Lock Level:** Takes a minimal `ShareUpdateExclusiveLock`, which permits concurrent `SELECT`, `INSERT`, `UPDATE`, and `DELETE` operations.

### 1.2 The Role of `VACUUM` in Storage Reclaim & MVCC
Because PostgreSQL utilizes Multi-Version Concurrency Control (MVCC), updated or deleted rows leave behind expired row versions known as **dead tuples**.
* **Storage Space Reuse:** Ordinary `VACUUM` scans table pages, marks space occupied by dead tuples as reusable for subsequent inserts, and updates the **Free Space Map (FSM)**.
* **Visibility Map (VM) Updates:** `VACUUM` marks pages where all rows are visible to all current transactions. This enables PostgreSQL to execute high-speed **Index-Only Scans** (reading data entirely from index pages without fetching table heap blocks).
* **Transaction ID Wraparound Protection:** `VACUUM` freezes old transaction IDs to prevent 32-bit transaction counter wraparound failure.
* **Lock Level:** Ordinary `VACUUM` takes a `ShareUpdateExclusiveLock`, allowing normal application reading and writing to proceed uninterrupted.

---

## 2. Mandatory Safety Directives

To safeguard production data and adhere to academic grading guidelines, the following safety constraints are strictly observed:

1. **Transaction Block Prohibition:**
   `VACUUM` commands **cannot** run inside a transaction block. Attempting to execute `BEGIN; VACUUM ...; COMMIT;` results in a fatal syntax error (`ERROR: VACUUM cannot run inside a transaction block`). All commands are executed as standalone statements.
2. **Strict Prohibition of `VACUUM FULL`:**
   `VACUUM FULL` rewrites the entire table to a new disk file. It requires an **`AccessExclusiveLock`**, which completely blocks all incoming queries and inserts, causing application downtime. It is strictly prohibited in routine maintenance.
3. **No Synthetic Data Deletions:**
   No application records were deleted merely to manufacture artificial dead tuples.
4. **Least-Privilege Maintenance Account (`rors_maint`):**
   Maintenance is performed using the dedicated `rors_maint` account, which is granted the PostgreSQL 18 built-in `pg_maintain` role. The maintenance specialist does not require superuser privileges (`postgres`) or access to table records (`SELECT`).

---

## 3. Maintenance Execution Plan & Commands

The maintenance operations target the 8 public application tables:

```sql
-- Step 1: Database-wide statistics refresh
ANALYZE;

-- Step 2: Online VACUUM and ANALYZE per application table
VACUUM (VERBOSE, ANALYZE) public.customer;
VACUUM (VERBOSE, ANALYZE) public.menu_item;
VACUUM (VERBOSE, ANALYZE) public.restaurant_table;
VACUUM (VERBOSE, ANALYZE) public.staff;
VACUUM (VERBOSE, ANALYZE) public.orders;
VACUUM (VERBOSE, ANALYZE) public.order_item;
VACUUM (VERBOSE, ANALYZE) public.reservation;
VACUUM (VERBOSE, ANALYZE) public.payment;
```

---

## 4. Maintenance Execution Matrix

The following table summarizes the status and monitoring metrics before and after the maintenance procedure:

| Table Name | Operations Planned | Target Schema | Account Role | Pre-Check Metrics | Post-Check Metrics | Execution Status | Operational Remarks |
|---|---|---|---|---|---|---|---|
| `public.customer` | `VACUUM (VERBOSE, ANALYZE)` | `public` | `rors_maint` (`pg_maintain`) | `n_dead_tup`, `last_vacuum`, `last_analyze` | Updated timestamps; dead tuples reclaimed | `BLOCKED` | Script prepared in `sql/06_maintenance_operations.sql`. Awaiting password entry. |
| `public.menu_item` | `VACUUM (VERBOSE, ANALYZE)` | `public` | `rors_maint` (`pg_maintain`) | Initial dead tuples from price/availability updates | Updated `last_vacuum` & `last_analyze` | `BLOCKED` | Refreshes planner stats for category search queries. |
| `public.restaurant_table` | `VACUUM (VERBOSE, ANALYZE)` | `public` | `rors_maint` (`pg_maintain`) | Seating status update dead tuples | Updated `last_vacuum` & `last_analyze` | `BLOCKED` | Reclaims dead tuples from table status changes (`available` -> `occupied`). |
| `public.staff` | `VACUUM (VERBOSE, ANALYZE)` | `public` | `rors_maint` (`pg_maintain`) | Baseline tuple counts | Updated `last_vacuum` & `last_analyze` | `BLOCKED` | Maintenance succeeds without reading sensitive password hashes. |
| `public.orders` | `VACUUM (VERBOSE, ANALYZE)` | `public` | `rors_maint` (`pg_maintain`) | Dead tuples from status transitions | Updated `last_vacuum` & `last_analyze` | `BLOCKED` | Critical transactional table. Reclaims dead tuples from workflow updates. |
| `public.order_item` | `VACUUM (VERBOSE, ANALYZE)` | `public` | `rors_maint` (`pg_maintain`) | Insert modifications | Updated `last_vacuum` & `last_analyze` | `BLOCKED` | High insert volume table; updates statistics for order line aggregation. |
| `public.reservation` | `VACUUM (VERBOSE, ANALYZE)` | `public` | `rors_maint` (`pg_maintain`) | Status modifications (`confirmed` -> `seated`) | Updated `last_vacuum` & `last_analyze` | `BLOCKED` | Ensures visibility maps and GiST exclusion index are synchronized. |
| `public.payment` | `VACUUM (VERBOSE, ANALYZE)` | `public` | `rors_maint` (`pg_maintain`) | Payment status updates (`pending` -> `paid`) | Updated `last_vacuum` & `last_analyze` | `BLOCKED` | Reclaims dead tuples from checkout completion workflow. |

---

## 5. Privilege & Permission Verification (`pg_maintain`)

In PostgreSQL 16 and earlier, executing `VACUUM` or `ANALYZE` on a table required either:
1. Owning the table (being the table owner or a member of the owning role).
2. Being a superuser (`postgres`).

In **PostgreSQL 17 and 18**, PostgreSQL introduced the built-in predefined role **`pg_maintain`**:
```sql
GRANT pg_maintain TO rors_maint_grp;
```
* **Privilege Scope:** Members of `pg_maintain` can execute `VACUUM`, `ANALYZE`, `REINDEX`, and `CLUSTER` across **all tables and schemas** in the database without owning the tables.
* **Security Isolation:** `pg_maintain` does **NOT** grant data access. `rors_maint` cannot execute `SELECT * FROM customer` or view customer passwords.
* This represents the highest standard of least-privilege database operations.

---

## 6. How to Run Maintenance Operations

Execute the maintenance script using `psql`:

```powershell
psql -h localhost -p 5432 -U rors_maint -d grp_binarysisters_projectdb -f db-maintenance/sql/06_maintenance_operations.sql
```

The script prints the before-and-after states from `pg_stat_user_tables`, showing the updated `last_vacuum` and `last_analyze` timestamps and confirmed dead tuple clearance.
