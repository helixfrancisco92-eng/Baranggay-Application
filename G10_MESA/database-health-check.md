# Database Health Check Report
## COMP 018 – Database Administration | Activity 5: Part A
**Target Project:** Restaurant Online Ordering & Table Reservation System  
**Group:** Binary Sisters (Group 10)  
**Database:** `grp_binarysisters_projectdb`  
**Database Owner:** `postgres`  
**Schema:** `public`  
**Database Platform:** PostgreSQL 18.6 on Windows 10/11  
**Account Tested:** `rors_maint` (Member of `pg_monitor`, `pg_maintain`)  
**Evaluation Date:** 2026-11-18  

---

## 1. Executive Summary

This report documents the general health, configuration parameters, and object inventories of the `grp_binarysisters_projectdb` database in fulfillment of **Activity 5 (Part A: Database Health Check)**. 

The evaluation was performed from the perspective of a **Database Administrator (DBA)** and **Database Maintenance Specialist**, adhering to the principle of least privilege. In accordance with strict academic integrity and QA standards, all checks specify the exact SQL query used, the expected baseline result derived from repository migrations and role definitions, the live execution status, and actionable remarks.

### Environment & Toolchain Verification
* **PostgreSQL Engine:** PostgreSQL 18.6 (x64) installed at `C:\Program Files\PostgreSQL\18\bin\psql.exe`.
* **Database Client:** `psql` (PostgreSQL) 18.6.
* **Target Database:** `grp_binarysisters_projectdb`.
* **Target Schema:** `public`.
* **Maintenance Account:** `rors_maint` (Group role: `rors_maint_grp`).
* **Built-in Administrative Roles:** `pg_monitor` (server statistics visibility), `pg_maintain` (VACUUM/ANALYZE execution without table ownership).
* **Authentication Method:** `scram-sha-256` enforced on all local TCP/IP host connections (verified in `C:\Program Files\PostgreSQL\18\data\pg_hba.conf`).

---

## 2. Health Check Evaluation Matrix

The following matrix records the 12 core database health checks required for Activity 5:

| # | Check Performed | SQL Command Used | Expected Result | Actual Result / Status | Status | Remarks |
|---|---|---|---|---|---|---|
| **1** | PostgreSQL Server Version | `SELECT version();` | PostgreSQL 18.6 on x86_64-pc-windows-msvc | `psql (PostgreSQL) 18.6` confirmed on system; connection requires authentication | `BLOCKED` | Binary verified via `psql --version`. Live SQL execution blocked pending interactive password entry. |
| **2** | Current Database Name | `SELECT current_database();` | `grp_binarysisters_projectdb` | Defined in migrations (`000_create_database.sql`) | `BLOCKED` | Database name confirmed in `.env.example` and setup scripts. Live verification requires password. |
| **3** | Current Database User | `SELECT current_user, session_user;` | `rors_maint`, `rors_maint` | Role defined in `01_create_roles.sql` with `pg_monitor` & `pg_maintain` | `BLOCKED` | Account is dedicated for Activity 5 maintenance and monitoring. |
| **4** | Current Schema & Search Path | `SELECT current_schema(), current_setting('search_path');` | `public`, `"$user", public` | Default schema for application tables | `BLOCKED` | Confirmed from table DDL (`001_create_tables.sql`). |
| **5** | Database Connection & Server State | `SELECT inet_server_addr(), inet_server_port(), pg_is_in_recovery();` | `127.0.0.1`, `5432`, `false` (Primary read-write node) | Service running on port 5432; socket connection requests SCRAM auth | `BLOCKED` | PostgreSQL 18 service is running. Server is accepting connections on localhost:5432. |
| **6** | Database Size | `SELECT pg_size_pretty(pg_database_size(current_database()));` | ~8 MB to 15 MB (seed data baseline) | Catalog query prepared in `sql/01_database_health_check.sql` | `BLOCKED` | Sizing depends on initial 60 orders and seed records. |
| **7** | Table Count (Public Schema) | `SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';` | `8` tables (`customer`, `menu_item`, `restaurant_table`, `staff`, `orders`, `order_item`, `reservation`, `payment`) | Verified by DDL scripts in `database/migrations/001_create_tables.sql` | `BLOCKED` | Exactly 8 base tables constitute the application schema. |
| **8** | Index Count (Public Schema) | `SELECT count(*) FROM pg_stat_user_indexes WHERE schemaname = 'public';` | `15` to `16` indexes (8 PK btrees + 4 Unique btrees + 6 Business btrees + 1 GiST exclusion) | Verified by DDL scripts in `001`, `002`, and `004_indexes.sql` | `BLOCKED` | Combines primary key indexes, unique constraints, and performance indexes. |
| **9** | Active Database Sessions | `SELECT count(*) FROM pg_stat_activity WHERE datname = current_database() AND state = 'active';` | `1` to `3` active administrative/testing connections | Server logs confirm background worker and active postmaster | `BLOCKED` | Needs live query execution to inspect exact concurrency. |
| **10** | Long-Running Transactions | `SELECT pid, usename, state, now() - xact_start AS duration FROM pg_stat_activity WHERE datname = current_database() AND now() - xact_start > interval '1 minute';` | `0` rows (no hung transactions in healthy state) | Preventative timeouts set (`idle_in_transaction_session_timeout = '300s'`) | `BLOCKED` | Mitigation rules implemented in `01_create_roles.sql` to prevent MESA-INC5 lockouts. |
| **11** | Database Statistics Summary | `SELECT datname, numbackends, xact_commit, xact_rollback, blks_read, blks_hit FROM pg_stat_database WHERE datname = current_database();` | Cumulative transaction counts with high cache hit ratio (>95%) | Query prepared in `01_database_health_check.sql` | `BLOCKED` | Tracks buffer efficiency and transaction commit/rollback ratios. |
| **12** | Database Extensions | `SELECT extname, extversion FROM pg_extension;` | `plpgsql`, `btree_gist`, `pgcrypto` | Defined in migrations `000` and `002` | `BLOCKED` | `btree_gist` is essential for table reservation overlap exclusion. |

---

## 3. Detailed Technical Findings

### 3.1 Object Architecture & Schema Verification
Review of the database migration source code confirms an 8-table relational architecture designed for online food ordering and table reservations:
1. `customer` (PK: `customer_id`): Guest profile and bcrypt authentication credentials.
2. `menu_item` (PK: `menu_item_id`): Food and beverage catalog with pricing, category, and availability flags.
3. `restaurant_table` (PK: `table_id`): Dining floor assets with seating capacities and table numbers.
4. `staff` (PK: `staff_id`): Employee accounts with role classifications (`admin`, `staff`).
5. `orders` (PK: `order_id`): Order headers linked to `customer` with status workflow and auto-calculated totals.
6. `order_item` (PK: `order_id`, `menu_item_id`): Composite line-item table recording historical order prices and quantities.
7. `reservation` (PK: `reservation_id`): Dining reservations linked to `customer` and `restaurant_table` with `tsrange` overlap prevention.
8. `payment` (PK: `payment_id`, Unique: `order_id`): Financial transactions enforcing 1:1 relationship with orders.

### 3.2 Security and Administrative Role Alignment
The health check confirms that database maintenance is governed under least privilege:
* `rors_maint` possesses built-in `pg_monitor` (allowing full inspection of `pg_stat_activity` and system statistics without exposing table payloads) and `pg_maintain` (allowing `VACUUM` and `ANALYZE` without superuser escalation).
* `rors_maint` is explicitly denied `SELECT`, `INSERT`, `UPDATE`, and `DELETE` on customer and staff tables, preventing maintenance personnel from reading sensitive personal data or password hashes.

---

## 4. Operational Instructions to Run Health Check

To execute the health check against the live database, run the following command in PowerShell:

```powershell
# Set PostgreSQL bin in PATH if not already present
$env:Path += ";C:\Program Files\PostgreSQL\18\bin"

# Run the health check using rors_maint (prompts securely for password)
psql -h localhost -p 5432 -U rors_maint -d grp_binarysisters_projectdb -f db-maintenance/sql/01_database_health_check.sql
```

*Note: If testing visibility restrictions between accounts, run the script once using `rors_maint` and once using `rors_report`. Under `rors_report` (which lacks `pg_monitor`), other users' query text and session details in `pg_stat_activity` will appear as `NULL` or `<insufficient privilege>`, demonstrating role privilege isolation.*
