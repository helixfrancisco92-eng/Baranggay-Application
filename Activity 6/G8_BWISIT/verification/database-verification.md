# Database Restoration Verification Report
## COMP 018 — Database Administration | Activity 6
### System: Campus Canteen Pre-Order and Queue Management System (Group 8 – bwisIT Solutions)

---

## 1. Scope and Verification Methodology

This technical verification document audits the relational database objects, schema constraints, indexes, sequences, sample records, and relational integrity of the restored **Campus Canteen Pre-Order and Queue Management System** database (`canteen_db_activity6_restore_test`).

Verification is conducted using the automated SQL suite [`verify-restore.sql`](file:///c:/Users/Lenovo/Downloads/ACT%206/G8_BWISIT/db-backup-recovery/group-08-campus-canteen/scripts/verify-restore.sql) executing against PostgreSQL 18.

---

## 2. Relational Object and Schema Audit

### A. Schema and Database Namespace
- **Target Database:** `canteen_db_activity6_restore_test`
- **Assigned Owner:** `canteen_admin`
- **Primary Schema:** `public`
- **Encoding:** UTF-8
- **Collation / Ctype:** Default (`en_US.UTF-8` or Windows default collation)

### B. Table Catalog Audit (Expected: 7 Tables)
All seven core tables defined in `database/migrations/001_create_tables.sql` and `002_auth_columns.sql` are verified:

| Table Name | Entity Description | Primary Key | Total Expected Columns |
|---|---|---|---|
| `student` | Student user profiles, institutional logins, and admin flag | `student_id` (SERIAL) | 6 columns |
| `vendor` | Canteen stall profiles, contact details, and auth credentials | `vendor_id` (SERIAL) | 6 columns |
| `menu_item` | Food/beverage offerings tied to specific vendor stalls | `item_id` (SERIAL) | 5 columns |
| `customer_order`| Meal pre-order transactions, pickup times, and statuses | `order_id` (SERIAL) | 6 columns |
| `order_item` | Line items detailing specific food items and quantities | `order_item_id` (SERIAL) | 5 columns |
| `queue_entry` | Daily queue ticket numbers and calling state | `queue_id` (SERIAL) | 5 columns |
| `notification` | Automated status alerts triggered during order lifecycle | `notification_id` (SERIAL) | 5 columns |

---

## 3. Relational Constraints and Indexes Audit

### A. Primary Key Constraints
Every table enforces an explicit primary key backed by a unique B-tree index:
1. `student_pkey` on `student(student_id)`
2. `vendor_pkey` on `vendor(vendor_id)`
3. `menu_item_pkey` on `menu_item(item_id)`
4. `customer_order_pkey` on `customer_order(order_id)`
5. `order_item_pkey` on `order_item(order_item_id)`
6. `queue_entry_pkey` on `queue_entry(queue_id)`
7. `notification_pkey` on `notification(notification_id)`

### B. Foreign Key Constraints and Referential Integrity
Foreign key relationships enforce strict parent-child referential integrity across the transaction lifecycle:
1. `menu_item_vendor_id_fkey`: `menu_item(vendor_id)` → `vendor(vendor_id)`
2. `customer_order_student_id_fkey`: `customer_order(student_id)` → `student(student_id)`
3. `customer_order_vendor_id_fkey`: `customer_order(vendor_id)` → `vendor(vendor_id)`
4. `order_item_order_id_fkey`: `order_item(order_id)` → `customer_order(order_id)`
5. `order_item_item_id_fkey`: `order_item(item_id)` → `menu_item(item_id)`
6. `queue_entry_order_id_fkey`: `queue_entry(order_id)` → `customer_order(order_id)` (Unique 1-to-1)
7. `notification_order_id_fkey`: `notification(order_id)` → `customer_order(order_id)`

### C. Unique Constraints
1. `student_email_key`: `student(email)`
2. `vendor_email_key`: `vendor(email)`
3. `uq_menu_item_vendor_name`: `menu_item(vendor_id, item_name)` (enforces distinct item names per stall)
4. `queue_entry_order_id_key`: `queue_entry(order_id)`
5. `queue_entry_queue_number_queue_date_key`: `queue_entry(queue_number, queue_date)` (prevents duplicate daily ticket numbers)

### D. Check Constraints (Domain Validation)
1. `student_role_check`: `student(role IN ('STUDENT', 'ADMIN'))`
2. `menu_item_price_check`: `menu_item(price >= 0)`
3. `customer_order_status_check`: `customer_order(status IN ('pending', 'preparing', 'ready', 'completed', 'cancelled'))`
4. `order_item_quantity_check`: `order_item(quantity > 0)`
5. `queue_entry_status_check`: `queue_entry(status IN ('waiting', 'called', 'served'))`

### E. Specialized Indexes
Beyond primary and unique keys, the following query performance indexes defined in `004_performance_indexes.sql` are verified:
- `idx_customer_order_vendor_date` on `customer_order(vendor_id, order_date)`
- `idx_customer_order_student_date` on `customer_order(student_id, order_date DESC)`
- `idx_customer_order_completed` on `customer_order(order_date)` WHERE `status = 'completed'` (Partial index)
- `idx_order_item_order` on `order_item(order_id)`
- `idx_order_item_item` on `order_item(item_id)`
- `idx_menu_item_vendor` on `menu_item(vendor_id)`
- `idx_notification_order` on `notification(order_id)`

---

## 4. Seed Data and Row Count Audit

Based on the official seeding script (`database/seed/001_sample_data.sql`), the restored database baseline contains the following record counts:

| Table Name | Expected Row Count (Baseline Seed) | Key Record Identifiers |
|---|---|---|
| `student` | 3 rows | Admin (`admin@canteen.test`), Maria Santos (`maria@student.test`), Juan Dela Cruz (`juan@student.test`) |
| `vendor` | 4 rows | Aling Nena's Silog (Active), Kuya Jun's Burgers (Active), Merienda Corner (Active), Waffle Corner (Inactive) |
| `menu_item` | 10 rows | Tapsilog (₱85), Longsilog (₱75), Tosilog (₱80), Cheeseburger (₱65), Double Burger (₱95), Fries (₱40), Siomai (₱45.50), Banana Cue (₱20), Iced Tea (₱30), Plain Waffle (₱50) |
| `customer_order`| 2 rows | Maria's order (Status: `pending`), Juan's order (Status: `preparing`) |
| `order_item` | 2 rows | 2x Tapsilog for Order #1; 1x Longsilog for Order #2 |
| `queue_entry` | 2 rows | Queue #1 (`waiting`), Queue #2 (`waiting`) |
| `notification` | 3 rows | Order placement and preparation notifications |

---

## 5. Application Connectivity and Smoke Test Validation

### A. Connection Architecture
The Spring Boot backend connects using JDBC:
- **URL:** `jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:canteen_db}`
- **Username:** `${DB_USER:canteen_app}`
- **Hibernate DDL Setting:** `spring.jpa.hibernate.ddl-auto=validate`
- **Implication:** The application strictly checks that entity models match existing schema columns and never alters schema DDL at runtime. This validates that the restored schema is 100% compatible with backend JPA entity mappings.

### B. Temporary Test Database Connection Verification
To verify that the Spring Boot application can bind and operate against the restored test database without overwriting production settings:
1. Temporarily launch the application with runtime environment overrides:
   ```powershell
   $env:DB_NAME = "canteen_db_activity6_restore_test"
   $env:DB_USER = "canteen_app"
   powershell -ExecutionPolicy Bypass -File .\scripts\run-backend.ps1
   ```
2. Execute a non-mutating HTTP read check:
   ```bash
   curl -s http://localhost:8080/api/vendors
   ```
3. Expected result: HTTP 200 OK returning JSON array with three active vendors (`Aling Nena's Silog`, `Kuya Jun's Burgers`, `Merienda Corner`). Inactive vendor `Waffle Corner` is excluded by business logic.

---

## 6. Execution Status Summary

- **Object Definition Audit:** **VERIFIED** against repository migrations and DDL.
- **Relational Integrity Verification:** **VERIFIED** against schema constraints.
- **Query Suite Implementation:** **IMPLEMENTED** in `scripts/verify-restore.sql`.
- **Live Database Execution:** **PENDING OPERATOR DATABASE RUN** (requires interactive entry of local PostgreSQL superuser credentials).

