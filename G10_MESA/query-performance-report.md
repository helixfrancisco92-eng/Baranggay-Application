# Query Performance and Execution Plan Report
## COMP 018 – Database Administration | Activity 5: Part F
**Target Project:** Restaurant Online Ordering & Table Reservation System  
**Group:** Binary Sisters (Group 10)  
**Database:** `grp_binarysisters_projectdb`  
**Schema:** `public`  
**Engine:** PostgreSQL 18.6 on Windows 10/11  
**Account Tested:** `rors_report` (Auditor/reporting) / `rors_maint`  
**Evaluation Date:** 2026-11-18  

---

## 1. Executive Summary & Methodology

Query performance analysis evaluates how efficiently PostgreSQL retrieves application data. In Activity 5 Part F, real application queries are inspected using the PostgreSQL query plan visualizer:
1. **`EXPLAIN` (Estimated Execution Plan):**
   * Shows the execution plan chosen by the query planner without running the query.
   * Reports estimated startup cost, estimated total cost, expected row count, and average row width.
   * Completely safe to run on any query.
2. **`EXPLAIN (ANALYZE, BUFFERS)` (Actual Execution Plan):**
   * **Actually executes** the query in real time on the database engine.
   * Measures actual startup time, actual total execution time (in milliseconds), loop iterations, actual rows returned, and memory/buffer statistics (`shared hit` vs `read`).
   * **Mandatory Safety Rule:** Must **only** be executed on safe, read-only `SELECT` statements in test databases. Never use `EXPLAIN ANALYZE` on `DELETE`, `UPDATE`, or `INSERT` statements because it will commit data changes.

---

## 2. Core Concepts: Estimated Cost vs. Actual Execution Time

| Metric | What It Represents | Units / Format | How PostgreSQL Derives It |
|---|---|---|---|
| **Estimated Cost** | The theoretical work required to fetch the data, as estimated by the query optimizer. | Arbitrary planner units (`cost=startup..total`) | Calculated relative to `seq_page_cost` (default 1.0, representing one disk block read). Incorporates `random_page_cost` (4.0), `cpu_tuple_cost` (0.01), and `cpu_operator_cost` (0.0025). |
| **Actual Time** | The real wall-clock elapsed time taken to execute the step. | Milliseconds (`time=startup..total ms`) | Measured by the database engine timer during query execution. |
| **Planning Time** | Time taken by the optimizer to parse the query, evaluate statistics, and select the optimal plan. | Milliseconds (`ms`) | Measured before execution begins. |
| **Execution Time** | Total time taken to execute the plan and output rows. | Milliseconds (`ms`) | Includes executor time, node execution, and buffer cache retrievals. |
| **Shared Buffers Hit vs. Read** | Memory cache effectiveness. | Block count (8 KB per block) | `shared hit`: Data was already in RAM cache (`shared_buffers`). `read`: Data had to be read from the physical disk/OS page cache. |

---

## 3. Query Analysis Matrix

### 3.1 Query 1: Customer Order History
* **Feature:** "My Orders" customer portal page.
* **Objective:** Retrieve historical orders for a specific customer (`customer_id = 1`) sorted newest first.
* **SQL Statement:**
  ```sql
  SELECT
      o.order_id,
      o.order_date,
      o.order_status,
      o.total_amount
  FROM public.orders AS o
  WHERE o.customer_id = 1
  ORDER BY o.order_date DESC;
  ```
* **Supporting Index:** `idx_orders_customer_date` on `orders (customer_id, order_date DESC)`.

#### Evaluation Details:
* **Execution Plan Structure:**
  * *On Small / Seeded Database:* The optimizer may choose `Seq Scan on orders` followed by a `Sort` node if the entire table fits inside one 8 KB disk page.
  * *On Scaled / Production Database:* The optimizer executes an **`Index Scan using idx_orders_customer_date on orders`**.
* **Index Usage:** The index covers both the filter (`customer_id = 1`) and the sorting requirement (`order_date DESC`), eliminating the need for an expensive in-memory QuickSort or Top-N Sort node.
* **Status:** `BLOCKED` (Script prepared in `sql/05_query_performance.sql`; execution pending live password entry).
* **Optimization Assessment:** Optimal. The composite index perfectly matches the query predicate and sort order.

---

### 3.2 Query 2: Reservation Schedule with Table Details
* **Feature:** Restaurant Staff daily floor and table management dashboard.
* **Objective:** Retrieve all upcoming table reservations from today forward, joined with table seating capacity, ordered chronologically.
* **SQL Statement:**
  ```sql
  SELECT
      r.reservation_id,
      r.reservation_date,
      r.reservation_time,
      r.number_of_guests,
      r.reservation_status,
      rt.table_number,
      rt.capacity
  FROM public.reservation AS r
  JOIN public.restaurant_table AS rt
      ON r.table_id = rt.table_id
  WHERE r.reservation_date >= CURRENT_DATE
  ORDER BY r.reservation_date, r.reservation_time;
  ```
* **Supporting Indexes:** `idx_reservation_date` on `reservation (reservation_date)` and `restaurant_table_pkey` on `restaurant_table (table_id)`.

#### Evaluation Details:
* **Execution Plan Structure:**
  * Join Type: **`Hash Join`** or **`Nested Loop`**. Because `restaurant_table` is a small table (10–20 rows), PostgreSQL either loads it into an in-memory hash table or performs a nested loop lookup using `restaurant_table_pkey`.
  * Scan on `reservation`: Scanned using `idx_reservation_date` with range filter (`reservation_date >= CURRENT_DATE`).
  * Sort Node: `Sort Key: r.reservation_date, r.reservation_time`.
* **Status:** `BLOCKED` (Prepared in `sql/05_query_performance.sql`).
* **Optimization Assessment:** Highly efficient. The primary key on `restaurant_table` guarantees $O(1)$ table metadata lookups.

---

### 3.3 Query 3: Manager / Reporting View (`v_order_summary`)
* **Feature:** Real-time Order Summary Dashboard for Cashiers, Waiters, and Auditors.
* **Objective:** Retrieve the 20 most recent orders with full customer name, line item count, and payment status.
* **SQL Statement:**
  ```sql
  SELECT 
      order_id,
      customer_name,
      order_date,
      order_status,
      total_amount,
      line_items,
      payment_method,
      payment_status
  FROM public.v_order_summary
  ORDER BY order_date DESC
  LIMIT 20;
  ```
* **Supporting Objects:** View `v_order_summary` defined in `003_views.sql` joining `orders`, `customer`, and `payment` with correlated subquery `(SELECT count(*) FROM order_item oi WHERE oi.order_id = o.order_id)`.

#### Evaluation Details:
* **Execution Plan Structure:**
  * Limit Node (`Limit 20`).
  * Subquery / Aggregate on `order_item` using `idx_order_item_menu_item` or `order_item_pkey`.
  * Joins on `customer.customer_id = o.customer_id` (`customer_pkey`) and `payment.order_id = o.order_id` (`payment_order_id_key`).
* **Status:** `BLOCKED` (Prepared in `sql/05_query_performance.sql`).
* **Optimization Assessment:** Very solid. The `LIMIT 20` clause combined with `idx_orders_customer_date` allows the executor to short-circuit execution early once 20 rows are found.

---

## 4. Query Performance Evaluation Summary

| Query # | Query Description | Supported Role | Target Tables / Views | Planned Scan Type | Supporting Index | Execution Status | Recommendation |
|---|---|---|---|---|---|---|---|
| **Query 1** | Customer Order History | Customer (`rors_app`) / Report (`rors_report`) | `orders` | Index Scan / Seq Scan (small data) | `idx_orders_customer_date` | `BLOCKED` | Keep existing composite index; no rewrite needed. |
| **Query 2** | Reservation Schedule | Waiter (`rors_app`) / Admin (`rors_dba`) | `reservation`, `restaurant_table` | Index Scan + PK Hash Join | `idx_reservation_date`, `restaurant_table_pkey` | `BLOCKED` | Retain; efficient index-assisted join. |
| **Query 3** | Order Summary Dashboard | Cashier, Manager (`rors_app`), Auditor (`rors_report`) | `v_order_summary` | Nested Loop / Hash Join with Limit | `orders_pkey`, `customer_pkey`, `payment_order_id_key` | `BLOCKED` | Well-optimized view definition; hides passwords. |

---

## 5. How to Run Query Performance Analysis

Execute the queries using `psql` in PowerShell:

```powershell
psql -h localhost -p 5432 -U rors_report -d grp_binarysisters_projectdb -f db-maintenance/sql/05_query_performance.sql
```

The output prints both the estimated plan (`EXPLAIN`) and the verified execution metrics (`EXPLAIN ANALYZE, BUFFERS`).
