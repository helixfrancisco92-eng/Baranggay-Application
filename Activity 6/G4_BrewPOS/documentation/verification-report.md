# BrewPOS — Database Restoration Verification Report
**Course:** COMP 018 — Database Administration  
**Activity:** Activity 6 — Database Backup, Restoration, and Recovery  
**Target Project:** BrewPOS — Café Point-of-Sale System  
**Verified Database:** `grp_brewposdb_restore_test`  
**Report Date:** November 12, 2026  
**Execution Status:** **PENDING MANUAL EXECUTION / SCRIPTS CREATED**  

---

## 1. Verification Scope & Method

The restoration verification process validates that the database restored from the custom-format backup (`pg_dump -Fc`) matches the architectural, referential, and relational specifications of the original BrewPOS database.

All assertions are encapsulated in:
- `sql/verification-queries.sql`
- `scripts/verify-restoration.ps1`

---

## 2. Structural & Relational Verification Matrix

| Verification Category | Target Database Object / Assertion | Expected Specification in BrewPOS | Verification Status |
|---|---|---|---|
| **Table Existence** | `public.staff` | Exists, BASE TABLE | **PENDING EXECUTION** |
| **Table Existence** | `public.menu_category` | Exists, BASE TABLE | **PENDING EXECUTION** |
| **Table Existence** | `public.menu_item` | Exists, BASE TABLE | **PENDING EXECUTION** |
| **Table Existence** | `public.order_ticket` | Exists, BASE TABLE | **PENDING EXECUTION** |
| **Table Existence** | `public.order_line_item` | Exists, BASE TABLE | **PENDING EXECUTION** |
| **Table Count** | Schema `public` | Strictly 5 application tables | **PENDING EXECUTION** |
| **Primary Key** | `staff_pkey` | `(staff_id)` | **PENDING EXECUTION** |
| **Primary Key** | `menu_category_pkey` | `(category_id)` | **PENDING EXECUTION** |
| **Primary Key** | `menu_item_pkey` | `(item_id)` | **PENDING EXECUTION** |
| **Primary Key** | `order_ticket_pkey` | `(order_id)` | **PENDING EXECUTION** |
| **Composite Primary Key** | `pk_order_line_item` | `(order_id, item_id)` — strictly composite | **PENDING EXECUTION** |
| **Foreign Key 1** | `fk_menu_item_category` | `category_id -> menu_category(category_id)`, RESTRICT | **PENDING EXECUTION** |
| **Foreign Key 2** | `fk_order_ticket_staff` | `staff_id -> staff(staff_id)`, RESTRICT | **PENDING EXECUTION** |
| **Foreign Key 3** | `fk_order_line_order` | `order_id -> order_ticket(order_id)`, RESTRICT | **PENDING EXECUTION** |
| **Foreign Key 4** | `fk_order_line_item` | `item_id -> menu_item(item_id)`, RESTRICT | **PENDING EXECUTION** |
| **Unique Constraint** | `uq_menu_category_name` | `UNIQUE (category_name)` | **PENDING EXECUTION** |
| **Unique Constraint** | `uq_menu_item_category_name` | `UNIQUE (category_id, item_name)` | **PENDING EXECUTION** |
| **Check Constraint** | `chk_staff_role` | `role IN ('CASHIER', 'MANAGER')` | **PENDING EXECUTION** |
| **Check Constraint** | `chk_menu_item_price` | `price >= 0` | **PENDING EXECUTION** |
| **Check Constraint** | `chk_order_ticket_payment` | `payment_method IN ('CASH', 'ONLINE')` | **PENDING EXECUTION** |
| **Check Constraint** | `chk_order_line_quantity` | `quantity > 0` | **PENDING EXECUTION** |
| **Check Constraint** | `chk_order_line_sold_price`| `sold_price >= 0` | **PENDING EXECUTION** |
| **Performance Index 1** | `idx_order_ticket_timestamp` | B-tree index on `order_ticket(order_timestamp)` | **PENDING EXECUTION** |
| **Performance Index 2** | `idx_order_line_item_item_id`| B-tree index on `order_line_item(item_id)` | **PENDING EXECUTION** |

---

## 3. Data Integrity & Financial Aggregation Check

### Baseline Data Expectations (from Seed Script):
- `staff`: Minimum 2 rows (`Demo Cashier`, `Demo Manager`).
- `menu_category`: Minimum 3 rows (`Coffee`, `Non-Coffee`, `Pastries`).
- `menu_item`: Minimum 11 rows (10 active, 1 inactive: `Pumpkin Spice Latte`).
- `order_ticket`: Sample historical orders.
- `order_line_item`: Itemized orders with unit `sold_price`.

### Core Business Rule Assertion: Calculated Totals
BrewPOS does **not** store order totals or subtotals as columns. Receipts must be dynamically validated:
```sql
SELECT t.order_id, t.order_timestamp, t.payment_method,
       SUM(l.quantity * l.sold_price) AS order_total
FROM public.order_ticket t
JOIN public.order_line_item l ON l.order_id = t.order_id
GROUP BY t.order_id, t.order_timestamp, t.payment_method;
```
*Expected Result:* All historical line items compute positive decimal sums matching original cashier charges.

---

## 4. Application Compatibility Test

- **Test Concept:** Pointing BrewPOS's Spring Boot backend to the restored test database (`grp_brewposdb_restore_test`) by temporarily setting `DB_URL=jdbc:postgresql://localhost:5432/grp_brewposdb_restore_test` in `.env`.
- **Validation Check:** Spring Boot starts up with `spring.jpa.hibernate.ddl-auto=validate` without throwing `SchemaManagementException`.
- **Status:** **PENDING LOCAL TEST** (Requires running `.\mvnw.cmd test` or starting application in PowerShell outside sandbox).

