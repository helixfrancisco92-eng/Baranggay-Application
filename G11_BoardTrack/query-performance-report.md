# Query Performance & Execution Plan Report
## COMP 018 – Database Administration | Activity 5: Part F
**Target Project:** BoardTrack – Boarding House & Rental Management System  
**Target Database:** `boardtrack_db`  
**Schema:** `public`  
**Database Platform:** PostgreSQL 18.6 on Windows 10/11  
**Diagnostic Tools:** PostgreSQL `EXPLAIN` & `EXPLAIN (ANALYZE, BUFFERS)`  

---

## 1. Fundamentals of Query Execution Planning

### 1.1 Estimated Cost vs. Actual Execution Time
A critical concept in database administration is distinguishing between the query planner's **Estimated Cost** and the query engine's **Actual Execution Time**:

* **Estimated Cost (Arbitrary Planner Units):**
  - Syntax: `cost=startup_cost..total_cost` (e.g., `cost=0.00..15.50`).
  - Represents the planner's mathematical estimate of work, measured in units where `1.0` equals the cost of reading one sequential 8 KB disk page (`seq_page_cost`), combined with CPU processing costs (`cpu_tuple_cost = 0.01`, `cpu_operator_cost = 0.0025`).
  - **Estimated cost is not measured in seconds or milliseconds.** A cost of 10.0 does NOT mean 10 ms.
* **Actual Execution Time (Wall-Clock Milliseconds):**
  - Generated ONLY when using **`EXPLAIN ANALYZE`**.
  - PostgreSQL actually executes the query against the database engine, timing each plan node with high-precision system clocks.
  - Expressed as `actual time=startup_ms..total_ms rows=N loops=L`.

### 1.2 Buffer Cache and I/O Analysis (`BUFFERS`)
When running `EXPLAIN (ANALYZE, BUFFERS)`:
* **`Buffers: shared hit=N`**: The required data pages were already cached in PostgreSQL's shared memory (`shared_buffers`), requiring 0 physical disk reads.
* **`Buffers: shared read=N`**: The page had to be fetched physically from the operating system cache or disk drive.

> **SAFETY MANDATE:** `EXPLAIN ANALYZE` actually executes the query! It is safe for read-only `SELECT` statements, but must **NEVER** be run on `INSERT`, `UPDATE`, or `DELETE` statements in production or evaluation targets without wrapping them in an uncommitted rollback transaction.

---

## 2. Query Performance Evaluations

### 2.1 Query 1 – Lease History with Tenant and Room Profiles

#### Purpose
Powers the primary Lease Management dashboard in BoardTrack. It correlates rental agreements with tenant contact details and room numbers, sorted by start date in descending order.

#### SQL Statement
```sql
SELECT
    l.lease_id,
    l.start_date,
    l.end_date,
    l.status,
    t.tenant_id,
    r.room_id
FROM public.lease AS l
JOIN public.tenant AS t
    ON l.tenant_id = t.tenant_id
JOIN public.room AS r
    ON l.room_id = r.room_id
ORDER BY l.start_date DESC;
```

#### Expected Execution Plan & Analysis
* **Planner Strategy:**
  1. **Scan on `lease`:** On a small seed dataset (4 rows), the planner chooses a `Seq Scan on lease`. As data volume expands to thousands of rows, the planner leverages indexes.
  2. **Hash Join / Nested Loop:** The planner evaluates join sizes. With small reference tables (`tenant`, `room`), it constructs an in-memory hash table of `tenant` (`Hash (tenant)`) and performs a `Hash Join` with `lease`, followed by a lookup into `room`.
  3. **Sort Node (`Sort Key: l.start_date DESC`):** An in-memory quicksort orders the matched rows chronologically.
* **Scan Types:** Sequential Scan / Hash Join / In-memory Quicksort.
* **Estimated Cost:** ~`1.20 .. 35.50` (small relation cost units).
* **Live Status:** `BLOCKED` (Credential Required).
* **DBA Optimization Recommendations:**
  - If lease volume grows past 10,000 active and archived agreements, create a composite or specialized index `CREATE INDEX idx_lease_start_date ON lease(start_date DESC)` to allow an Index Scan that eliminates the explicit Sort node.

---

### 2.2 Query 2 – Payment History

#### Purpose
Powers the Rent Collection tracking view and billing history for landlords and tenants, ordered chronologically by payment date.

#### SQL Statement
```sql
SELECT
    p.payment_id,
    p.lease_id,
    p.amount,
    p.payment_date,
    p.status
FROM public.payment AS p
ORDER BY p.payment_date DESC;
```

#### Expected Execution Plan & Analysis
* **Planner Strategy:**
  1. **Table Scan:** `Seq Scan on payment p` for seed table size (6 rows).
  2. **Sort Operation:** `Sort Key: p.payment_date DESC`. Performed via `Sort Method: quicksort Memory: 25kB`.
* **Scan Types:** Sequential Scan followed by Sort.
* **Estimated Cost:** ~`1.05 .. 12.15`.
* **Live Status:** `BLOCKED` (Credential Required).
* **DBA Optimization Recommendations:**
  - Under high-volume payment processing (e.g., hundreds of monthly rental remittances over several years), create an index:
    ```sql
    CREATE INDEX idx_payment_date ON payment(payment_date DESC);
    ```
    This would allow PostgreSQL to perform a backward B-tree index scan, returning records in pre-sorted order without requiring an in-memory sort buffer.

---

### 2.3 Query 3 – Lease Summary Reporting View (`v_lease_summary`)

#### Purpose
Evaluates the core analytical reporting view `v_lease_summary`. As established in the approved Activity 3 architecture, tenant balances are calculated dynamically rather than stored as redundant columns.

#### SQL Statement
```sql
SELECT *
FROM public.v_lease_summary;
```

#### Underlying View Definition
```sql
SELECT l.lease_id, l.tenant_id, t.full_name AS tenant, p.property_name, r.room_number,
       l.start_date, l.end_date, l.monthly_rent, l.status,
       COALESCE((SELECT SUM(x.amount) FROM payment x
                 WHERE x.lease_id = l.lease_id AND x.status = 'COMPLETED'), 0) AS total_paid,
       COALESCE((SELECT SUM(u.amount) FROM utility_bill u
                 WHERE u.lease_id = l.lease_id), 0) AS utilities_billed
FROM lease l
JOIN tenant t   ON t.tenant_id = l.tenant_id
JOIN room r     ON r.room_id = l.room_id
JOIN property p ON p.property_id = r.property_id;
```

#### Expected Execution Plan & Analysis
* **Planner Strategy:**
  1. **Core Joins:** Performs joins across the 4 primary tables (`lease`, `tenant`, `room`, `property`).
  2. **Correlated Subplans:** For each row produced by the join:
     - `SubPlan 1 (payment sum)`: Executes an aggregate `SUM(x.amount)` filtered by `x.lease_id = l.lease_id AND x.status = 'COMPLETED'`. When the subquery executes, the foreign key index **`idx_payment_lease`** enables index scans per outer lease row.
     - `SubPlan 2 (utility sum)`: Executes `SUM(u.amount)` filtered by `u.lease_id = l.lease_id`, supported by **`idx_utility_lease`**.
* **Scan Types:** Multi-table Join + SubPlan Aggregations utilizing FK indexes.
* **Estimated Cost:** ~`15.00 .. 150.00` (depending on correlated subquery evaluations).
* **Live Status:** `BLOCKED` (Credential Required).
* **DBA Optimization Recommendations:**
  - The correlated subqueries in `v_lease_summary` are optimal for typical boarding house operations (1 to 50 active leases).
  - If the business expands to hundreds of properties, refactor the view using grouped `LEFT JOIN` subqueries rather than correlated scalar subplans, or implement materialized views refreshed on payment posting.

---

## 3. Query Performance Summary Table

| Query Target | Primary Operations | Indexes Available | Estimated Cost Range | Live Plan Status | Optimization Recommendation |
|---|---|---|---|---|---|
| **Query 1 (Lease History)** | 3-table join + Sort | `idx_lease_room`, `idx_lease_tenant`, PKs | `1.20 .. 35.50` | `BLOCKED` (Credential Required) | Add `idx_lease_start_date` if table exceeds 10k rows. |
| **Query 2 (Payment History)** | Scan + Sort | `payment_pkey`, `idx_payment_lease` | `1.05 .. 12.15` | `BLOCKED` (Credential Required) | Add `idx_payment_date DESC` for large transaction volumes. |
| **Query 3 (v_lease_summary)** | 4-table join + 2 Correlated Subplans | `idx_payment_lease`, `idx_utility_lease` | `15.00 .. 150.00` | `BLOCKED` (Credential Required) | Existing FK indexes actively support subplan evaluation. |

---

## 4. Execution Instructions

```powershell
# Set psql path
$env:Path += ";C:\Program Files\PostgreSQL\18\bin"

# Run query performance script (prompts securely for password)
psql -h localhost -p 5432 -U postgres -d boardtrack_db -f db-maintenance/sql/05_query_performance.sql
```
