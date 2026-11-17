# Index Monitoring and Inventory Report
## COMP 018 – Database Administration | Activity 5: Part E
**Target Project:** Restaurant Online Ordering & Table Reservation System  
**Group:** Binary Sisters (Group 10)  
**Database:** `grp_binarysisters_projectdb`  
**Schema:** `public`  
**Engine:** PostgreSQL 18.6 on Windows 10/11  
**Account Tested:** `rors_maint` (possessing `pg_monitor`)  
**Evaluation Date:** 2026-11-18  

---

## 1. Executive Summary & Index Architecture

Indexes are specialized data structures that accelerate data retrieval by allowing the PostgreSQL query engine to locate target records directly without performing full table sequential scans. However, every index imposes a trade-off: each `INSERT`, `UPDATE`, and `DELETE` on the indexed table incurs **write amplification** because the database engine must synchronously update both the heap table pages and all associated index B-trees or GiST trees.

In accordance with least-overhead design principles documented in `004_indexes.sql`:
> *"Every index costs write time and disk space, so only queries that exist in the app are covered."*

This report audits all indexes present in the `public` schema of `grp_binarysisters_projectdb`, categorized into:
1. **Application-Specific Performance Indexes** (created in `004_indexes.sql`).
2. **Integrity & Constraint-Enforcing Indexes** (Primary Keys, Unique Constraints, and GiST Exclusion Constraints).

---

## 2. Inventory of Schema Indexes

### 2.1 Application Business Performance Indexes (6 Indexes)
The application defines six tailored secondary indexes designed to optimize high-traffic web routes:

| # | Index Name | Target Table | Indexed Column(s) | Index Type | Business / Feature Justification |
|---|---|---|---|---|---|
| **1** | `idx_orders_customer_date` | `orders` | `(customer_id, order_date DESC)` | B-tree | **Customer "My Orders" Route:** Enables direct index range scan filtering orders by logged-in customer ID and delivers pre-sorted chronological results without requiring an in-memory sort operation. |
| **2** | `idx_orders_status` | `orders` | `(order_status)` | B-tree | **Kitchen & Waiter Queue:** Speeds up queries filtering for active orders (`pending`, `confirmed`, `preparing`, `ready`) to drive kitchen display monitors and cashier order queues. |
| **3** | `idx_order_item_menu_item` | `order_item` | `(menu_item_id)` | B-tree | **Foreign Key & Item Reporting:** PostgreSQL automatically indexes PKs, but NOT foreign keys. This index accelerates joins from `menu_item` to `order_item` and supports item sales reporting and cascade checks. |
| **4** | `idx_reservation_customer` | `reservation` | `(customer_id, reservation_date)` | B-tree | **Customer "My Reservations":** Supports the guest profile portal, allowing fast lookups of upcoming or historical reservations for a specific customer. |
| **5** | `idx_reservation_date` | `reservation` | `(reservation_date)` | B-tree | **Staff Daily Schedule Dashboard:** Powers the front-of-house host dashboard to retrieve all reservations scheduled for a given calendar date. |
| **6** | `idx_menu_item_category` | `menu_item` | `(category)` | B-tree | **Customer Menu Browsing:** Filters food catalog items by menu category (e.g. `Appetizer`, `Main Course`, `Dessert`, `Beverage`). |

---

### 2.2 Constraint & Integrity-Enforcing Indexes (10 Indexes)
PostgreSQL automatically constructs unique B-tree indexes to enforce primary key and unique constraints, as well as a GiST index for the reservation exclusion constraint:

| # | Index Name | Target Table | Columns | Access Method | Constraint Enforced |
|---|---|---|---|---|---|
| **7** | `customer_pkey` | `customer` | `customer_id` | B-tree | Primary Key (Unique, Not Null) |
| **8** | `customer_email_key` | `customer` | `email` | B-tree | Unique Email (Prevents duplicate registrations) |
| **9** | `menu_item_pkey` | `menu_item` | `menu_item_id` | B-tree | Primary Key |
| **10** | `restaurant_table_pkey` | `restaurant_table` | `table_id` | B-tree | Primary Key |
| **11** | `restaurant_table_table_number_key`| `restaurant_table` | `table_number` | B-tree | Unique Table Number (Floor layout integrity) |
| **12** | `staff_pkey` | `staff` | `staff_id` | B-tree | Primary Key |
| **13** | `staff_email_key` | `staff` | `email` | B-tree | Unique Staff Email |
| **14** | `orders_pkey` | `orders` | `order_id` | B-tree | Primary Key |
| **15** | `order_item_pkey` | `order_item` | `(order_id, menu_item_id)` | B-tree | Composite Primary Key |
| **16** | `ex_reservation_no_overlap` | `reservation` | `table_id, tsrange(...)` | **GiST** | **Overlapping Reservation Exclusion Constraint (`btree_gist`):** Guarantees a table cannot be double-booked within a 2-hour window. |
| **17** | `payment_pkey` | `payment` | `payment_id` | B-tree | Primary Key |
| **18** | `payment_order_id_key` | `payment` | `order_id` | B-tree | 1:1 Relationship Enforcer (One payment per order) |

---

## 3. Index Usage Metrics & Status Evaluation

The diagnostic query in `sql/04_index_monitoring.sql` queries `pg_stat_user_indexes` to evaluate live utilization:

| Index Name | Table Name | Scan Count (`idx_scan`) | Tuples Read (`idx_tup_read`) | Tuples Fetched (`idx_tup_fetch`) | Status | DBA Evaluation & Recommendation |
|---|---|---|---|---|---|---|
| `idx_orders_customer_date` | `orders` | Evaluated via script | — | — | `BLOCKED` | **RETAIN.** Essential for customer order history pagination and sorting. |
| `idx_orders_status` | `orders` | Evaluated via script | — | — | `BLOCKED` | **RETAIN.** Speeds up active kitchen display lookups as orders accumulate. |
| `idx_order_item_menu_item` | `order_item` | Evaluated via script | — | — | `BLOCKED` | **RETAIN.** Crucial FK index preventing sequential scans during parent deletes/updates. |
| `idx_reservation_customer` | `reservation` | Evaluated via script | — | — | `BLOCKED` | **RETAIN.** Customer self-service reservation tracking. |
| `idx_reservation_date` | `reservation` | Evaluated via script | — | — | `BLOCKED` | **RETAIN.** Daily host schedule filtering by `CURRENT_DATE`. |
| `idx_menu_item_category` | `menu_item` | Evaluated via script | — | — | `BLOCKED` | **RETAIN.** Menu category browsing. |
| `customer_pkey` | `customer` | Evaluated via script | — | — | `BLOCKED` | **MANDATORY.** Primary key lookup. |
| `orders_pkey` | `orders` | Evaluated via script | — | — | `BLOCKED` | **MANDATORY.** Order checkout and lookup. |
| `ex_reservation_no_overlap` | `reservation` | Evaluated via script | — | — | `BLOCKED` | **MANDATORY.** GiST exclusion constraint protecting against double-booking. |

---

## 4. Underutilized Index Analysis (DBA Best Practice)

A critical rule in database administration:
> [!WARNING]
> **A low or zero index scan count does NOT automatically mean the index is useless or should be dropped.**

When reviewing index statistics on development or newly seeded databases, low scan counts frequently occur for legitimate reasons:
1. **Workload Variation:** Certain business operations (such as end-of-month reporting, order cancellations, or off-peak reservations) may not have been triggered during a short testing period.
2. **Small Table Size Optimization:** For tables occupying only a few 8 KB disk pages (e.g. `menu_item` with 30 items or `restaurant_table` with 10 tables), the query optimizer intentionally chooses a Sequential Scan because loading 1 page into RAM is faster than traversing an index B-tree and performing random heap lookups. As table data expands in production, the planner will automatically switch to the index.
3. **Foreign Key Integrity Protection:** Indexes on foreign key columns (like `idx_order_item_menu_item`) are vital to prevent share-row locks and sequential table scans during updates or deletions of primary key records in parent tables.
4. **Constraint Enforcement:** Primary key and unique indexes must remain active regardless of scan counts because they enforce business integrity rules.

**Recommendation:** Retain all current indexes. Re-evaluate index scan statistics only after realistic end-to-end load testing or production traffic has been active for an extended period.

---

## 5. How to Run Index Monitoring

Execute the index monitoring script in PowerShell:

```powershell
psql -h localhost -p 5432 -U rors_maint -d grp_binarysisters_projectdb -f db-maintenance/sql/04_index_monitoring.sql
```
