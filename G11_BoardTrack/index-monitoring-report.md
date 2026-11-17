# Index Monitoring and Inventory Report
## COMP 018 – Database Administration | Activity 5: Part E
**Target Project:** BoardTrack – Boarding House & Rental Management System  
**Target Database:** `boardtrack_db`  
**Schema:** `public`  
**Database Platform:** PostgreSQL 18.6 on Windows 10/11  
**Monitoring Catalogs:** `pg_stat_user_indexes`, `pg_index`, `pg_class`, `pg_am`  

---

## 1. Index Architecture Overview

Indexes are critical database structures that allow the PostgreSQL query engine to locate matching rows rapidly without performing expensive sequential scans across full table heaps.

In BoardTrack, indexes serve two distinct and equally vital roles:
1. **Performance Optimization:** B-tree indexes defined on foreign keys (`idx_lease_room`, `idx_lease_tenant`, `idx_payment_lease`, `idx_utility_lease`) accelerate `JOIN` conditions, foreign key checks, and filter clauses.
2. **Data Integrity Enforcement:**
   - **Primary Key & Unique Indexes:** Automatically created B-tree indexes enforcing entity identity and uniqueness (`property_pkey`, `room_pkey`, `uq_room_per_property`, `tenant_pkey`, `tenant_email_key`, `lease_pkey`, `payment_pkey`, `utility_bill_pkey`, `app_user_pkey`, `app_user_username_key`, `schema_migrations_pkey`).
   - **Exclusion Constraint Index:** A specialized **GiST (Generalized Search Tree)** index enforcing business rule 2 (`ex_lease_no_overlap`), preventing two active leases for the same room from overlapping in time.

---

## 2. Complete Index Inventory (Schema: `public`)

The following inventory details all 12 user indexes defined across the BoardTrack database schema:

| Table | Index Name | Index Type | Indexed Columns / Definition | Architectural Purpose & Category |
|---|---|---|---|---|
| `property` | `property_pkey` | `btree` | `(property_id)` | Primary Key (Integrity Enforcement) |
| `room` | `room_pkey` | `btree` | `(room_id)` | Primary Key (Integrity Enforcement) |
| `room` | `uq_room_per_property` | `btree` | `(property_id, room_number)` | Unique Constraint (Integrity: no duplicate room numbers in same building) |
| `tenant` | `tenant_pkey` | `btree` | `(tenant_id)` | Primary Key (Integrity Enforcement) |
| `tenant` | `tenant_email_key` | `btree` | `(email)` | Unique Constraint (Integrity: unique login email) |
| `lease` | `lease_pkey` | `btree` | `(lease_id)` | Primary Key (Integrity Enforcement) |
| `lease` | `idx_lease_room` | `btree` | `(room_id)` | Foreign Key Index (Accelerates room lease lookups and trigger room sync) |
| `lease` | `idx_lease_tenant` | `btree` | `(tenant_id)` | Foreign Key Index (Accelerates tenant rental history queries) |
| `lease` | `ex_lease_no_overlap` | `gist` | `(room_id WITH =, daterange(start_date, end_date, '[]') WITH &&) WHERE status = 'ACTIVE'` | Exclusion Constraint Index (Enforces Business Rule 2) |
| `payment` | `payment_pkey` | `btree` | `(payment_id)` | Primary Key (Integrity Enforcement) |
| `payment` | `idx_payment_lease` | `btree` | `(lease_id)` | Foreign Key Index (Accelerates lease balance calculation in `v_lease_summary`) |
| `utility_bill` | `utility_bill_pkey` | `btree` | `(utility_bill_id)` | Primary Key (Integrity Enforcement) |
| `utility_bill` | `idx_utility_lease` | `btree` | `(lease_id)` | Foreign Key Index (Accelerates utility balance aggregation) |
| `app_user` | `app_user_pkey` | `btree` | `(user_id)` | Primary Key (Integrity Enforcement) |
| `app_user` | `app_user_username_key` | `btree` | `(username)` | Unique Constraint (Integrity: unique login usernames) |
| `schema_migrations` | `schema_migrations_pkey` | `btree` | `(name)` | Primary Key (Migration Tracking Integrity) |

---

## 3. Index Sizing and Scan Metrics

| Index Name | Table | Expected Disk Size | Scan Count (`idx_scan`) | Index Status | Evaluation Remarks |
|---|---|---|---|---|---|
| `property_pkey` | `property` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | Small table; PK lookup during room edits. |
| `room_pkey` | `room` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | Scanned during room detail lookups and trigger validations. |
| `uq_room_per_property` | `room` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | Unique index checked on room creation/update. |
| `tenant_pkey` | `tenant` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | Scanned on tenant profile access and lease joins. |
| `tenant_email_key` | `tenant` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | Scanned on tenant creation to prevent duplicate emails. |
| `lease_pkey` | `lease` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | Scanned on lease editing and payment FK lookups. |
| `idx_lease_room` | `lease` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | Critical FK index for checking active leases per room. |
| `idx_lease_tenant` | `lease` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | Critical FK index for tenant dashboard lookups. |
| `ex_lease_no_overlap` | `lease` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | GiST tree scanned on every lease INSERT/UPDATE where status='ACTIVE'. |
| `payment_pkey` | `payment` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | Scanned on payment reconciliation and edits. |
| `idx_payment_lease` | `payment` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | Essential for `v_lease_summary` subquery (`SUM(amount)`). |
| `utility_bill_pkey` | `utility_bill` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | Scanned on utility billing edits. |
| `idx_utility_lease` | `utility_bill` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | Essential for `v_lease_summary` subquery (`SUM(amount)`). |
| `app_user_pkey` | `app_user` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | Primary key for authentication account records. |
| `app_user_username_key` | `app_user` | 16 kB | 0 - Baseline | `BLOCKED` (Credential Required) | Critical index for user login (`SELECT * FROM app_user WHERE username = $1`). |

---

## 4. Underutilized Index Evaluation & DBA Insights

### 4.1 Why Low Scan Counts Do Not Mean an Index Should Be Dropped
In database administration, especially in newly initialized or lower-volume environments, an index may exhibit a scan count of zero (`idx_scan = 0`). **A low scan count alone NEVER justifies dropping an index without thorough root cause analysis:**

1. **Integrity Constraints:** Indexes supporting `PRIMARY KEY`, `UNIQUE`, and `EXCLUDE` constraints exist primarily to enforce business rules and relational consistency. Even if a SELECT query never scans them, PostgreSQL consults them during every `INSERT` or `UPDATE` to enforce uniqueness. Dropping them would violate database integrity.
2. **Small Table Optimizer Choice:** In small tables (e.g., BoardTrack's seed dataset containing 6 rooms and 4 leases), PostgreSQL's cost-based optimizer deliberately chooses a **Sequential Scan** over an Index Scan. Loading one 8 KB disk block into memory and reading 6 rows sequentially requires fewer I/O cycles than descending a B-tree index and then fetching the heap block.
3. **Workload Maturity:** Foreign key indexes (`idx_lease_room`, `idx_payment_lease`) become indispensable when the application reaches hundreds or thousands of tenant records. Retaining them prevents sudden catastrophic query degradation as the database scales.

### 4.2 Recommendation
* **All existing indexes must be retained.** No index should be dropped or modified.
* Continue monitoring `idx_scan` and `idx_tup_fetch` after production transaction volume accumulates.

---

## 5. Execution Instructions

```powershell
# Set psql path
$env:Path += ";C:\Program Files\PostgreSQL\18\bin"

# Run index monitoring script
psql -h localhost -p 5432 -U postgres -d boardtrack_db -f db-maintenance/sql/04_index_monitoring.sql
```
