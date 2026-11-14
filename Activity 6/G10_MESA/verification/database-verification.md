# Database Structure and Restoration Verification
## COMP 018 — Database Administration | Activity 6
### Assigned Project: Restaurant Online Ordering & Table Reservation System (Group: Binary Sisters)

---

## 1. Verification Overview and Operational Status

- **Target Database Evaluated:** `grp_binarysisters_projectdb` (Original) / `grp_binarysisters_projectdb_activity6_restore_test` (Restoration Target)
- **Database Engine:** PostgreSQL 18.6 (x64)
- **Target Schema:** `public`
- **Verification Suite Script:** `scripts/verify-database.sql`
- **Verification Date:** November 13, 2026
- **Status Classification:** **VERIFIED SPECIFICATION & IMPLEMENTED SCRIPTS (PENDING OPERATOR DATABASE RUN)**

---

## 2. Relational Tables Inventory and Column Audit

The restored database reconstructs all eight relational tables defined in the approved Activity 2 design (`database/migrations/001_create_tables.sql`):

| Table Name | Primary Key | Total Columns | Nullable Columns | Seed Baseline Count | Table Description / Business Role |
|---|---|---|---|---|---|
| **`customer`** | `customer_id` (SERIAL) | 7 | 0 | **51** | Registered diners; profiles, contact details, bcrypt password hashes |
| **`menu_item`** | `menu_item_id` (SERIAL) | 6 | 1 (`description`) | **50** | Food & beverage catalog, categories, pricing, active availability |
| **`restaurant_table`** | `table_id` (SERIAL) | 4 | 0 | **20** | Physical dining tables, table numbers, seating capacities, table status |
| **`staff`** | `staff_id` (SERIAL) | 6 | 0 | **10** | Restaurant employees; administrators and service staff, roles, credentials |
| **`orders`** | `order_id` (SERIAL) | 5 | 0 | **60** | Customer food orders; order dates, lifecycle status, dynamic total amount |
| **`order_item`** | `(order_id, menu_item_id)` | 5 | 0 | **167** | Associative entity resolving M:N order-item link; historical unit prices, subtotals |
| **`reservation`** | `reservation_id` (SERIAL) | 7 | 0 | **50** | Table reservations; date/time windows, guest counts, reservation status |
| **`payment`** | `payment_id` (SERIAL) | 6 | 0 | **56** | Order payments; 1:1 unique order link, payment methods, transaction status |

---

## 3. Referential Integrity and Constraint Verification

### 3.1 Primary Keys
- `customer_pkey`: `PRIMARY KEY (customer_id)`
- `menu_item_pkey`: `PRIMARY KEY (menu_item_id)`
- `restaurant_table_pkey`: `PRIMARY KEY (table_id)`
- `staff_pkey`: `PRIMARY KEY (staff_id)`
- `orders_pkey`: `PRIMARY KEY (order_id)`
- `pk_order_item`: `PRIMARY KEY (order_id, menu_item_id)` (Composite PK)
- `reservation_pkey`: `PRIMARY KEY (reservation_id)`
- `payment_pkey`: `PRIMARY KEY (payment_id)`

### 3.2 Foreign Key Relationships (6 Core Foreign Keys)
1. **`fk_orders_customer`**: `orders(customer_id) REFERENCES customer(customer_id)`  
   *Rules:* `ON UPDATE CASCADE ON DELETE RESTRICT` (Prevents deletion of customer accounts with existing order history).
2. **`fk_order_item_order`**: `order_item(order_id) REFERENCES orders(order_id)`  
   *Rules:* `ON UPDATE CASCADE ON DELETE CASCADE` (Cascades removal of line items when a draft order is cancelled/purged).
3. **`fk_order_item_menu_item`**: `order_item(menu_item_id) REFERENCES menu_item(menu_item_id)`  
   *Rules:* `ON UPDATE CASCADE ON DELETE RESTRICT` (Protects menu items from physical deletion if referenced in sales history).
4. **`fk_reservation_customer`**: `reservation(customer_id) REFERENCES customer(customer_id)`  
   *Rules:* `ON UPDATE CASCADE ON DELETE RESTRICT` (Protects customer records associated with reservations).
5. **`fk_reservation_table`**: `reservation(table_id) REFERENCES restaurant_table(table_id)`  
   *Rules:* `ON UPDATE CASCADE ON DELETE RESTRICT` (Protects physical table entries referenced by active reservations).
6. **`fk_payment_order`**: `payment(order_id) REFERENCES orders(order_id)`  
   *Rules:* `ON UPDATE CASCADE ON DELETE RESTRICT` (Preserves audit trail for paid transactions).

### 3.3 Unique Constraints
- `uq_customer_email`: `customer(email)` — Disallows duplicate customer registrations.
- `uq_staff_email`: `staff(email)` — Disallows duplicate staff accounts.
- `uq_restaurant_table_number`: `restaurant_table(table_number)` — Guarantees unique table numbers on floor plan.
- `uq_payment_order`: `payment(order_id)` — Enforces strict 1:1 relationship between an order and its settlement.

### 3.4 Domain Check Constraints (15 Verified Constraints)
1. `chk_customer_email`: `email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'`
2. `chk_menu_item_price`: `price >= 0`
3. `chk_restaurant_table_capacity`: `capacity > 0`
4. `chk_restaurant_table_status`: `status IN ('available', 'occupied', 'reserved', 'out_of_service')`
5. `chk_staff_role`: `role IN ('admin', 'staff')`
6. `chk_orders_status`: `order_status IN ('pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled')`
7. `chk_orders_total`: `total_amount >= 0`
8. `chk_order_item_quantity`: `quantity > 0`
9. `chk_order_item_unit_price`: `unit_price >= 0`
10. `chk_order_item_subtotal`: `subtotal >= 0`
11. `chk_order_item_math`: `subtotal = (quantity * unit_price)`
12. `chk_reservation_guests`: `number_of_guests > 0`
13. `chk_reservation_status`: `reservation_status IN ('pending', 'confirmed', 'seated', 'completed', 'cancelled', 'no_show')`
14. `chk_payment_amount`: `amount >= 0`
15. `chk_payment_method`: `payment_method IN ('cash', 'card', 'gcash', 'bank_transfer')`
16. `chk_payment_status`: `payment_status IN ('pending', 'paid', 'failed', 'refunded', 'cancelled')`

### 3.5 GiST Exclusion Constraint (Double-Booking Prevention)
- `ex_reservation_no_overlap`:
  ```sql
  EXCLUDE USING gist (
      table_id WITH =,
      (tsrange(reservation_date + reservation_time,
               reservation_date + reservation_time + interval '2 hours')) WITH &&
  ) WHERE (reservation_status IN ('pending', 'confirmed', 'seated'))
  ```
  *Functionality:* Built upon the `btree_gist` PostgreSQL extension, this constraint prevents overlapping reservation time windows on the same table at the database engine level (SQLSTATE `23P01`).

---

## 4. Secondary Performance Indexes

Recreated from `database/migrations/004_indexes.sql`:
1. `idx_orders_customer_date`: `ON orders (customer_id, order_date DESC)` (Accelerates customer order history queries).
2. `idx_orders_status`: `ON orders (order_status)` (Accelerates kitchen/staff order queue filtering).
3. `idx_order_item_menu_item`: `ON order_item (menu_item_id)` (Accelerates foreign key joins and dish sales analytics).
4. `idx_reservation_customer`: `ON reservation (customer_id, reservation_date)` (Accelerates customer reservation history).
5. `idx_reservation_date`: `ON reservation (reservation_date)` (Accelerates daily front-desk floor schedule lookups).
6. `idx_menu_item_category`: `ON menu_item (category)` (Accelerates frontend menu category browsing).

---

## 5. Reporting Views and Trigger Functions

### 5.1 Views
- **`v_customer_directory`**: Sanitized directory exposing `customer_id`, `first_name`, `last_name`, `email`, `phone`, and `created_at` (protects `password`).
- **`v_staff_directory`**: Sanitized directory exposing `staff_id`, `first_name`, `last_name`, `email`, and `role` (protects `password`).
- **`v_order_summary`**: Joins `orders`, `customer`, `order_item`, and `payment` to present order headers with customer names, line item counts, totals, and payment status.
- **`v_reservation_schedule`**: Joins `reservation`, `restaurant_table`, and `customer` to provide operational floor schedules.

### 5.2 Business Integrity Triggers
1. **`trg_order_item_total`**: Calls `fn_refresh_order_total()`. Automatically recalculates `orders.total_amount` whenever items are added, updated, or removed from `order_item`.
2. **`trg_orders_require_items` & `trg_order_item_keep_one`**: Calls `fn_require_order_items()`. Constraint trigger marked `DEFERRABLE INITIALLY DEFERRED`. Enforces Business Rule 9 (an order must contain at least one item) evaluated at transaction `COMMIT`.
3. **`trg_reservation_capacity`**: Calls `fn_check_reservation_capacity()`. Prevents creating reservations where `number_of_guests > restaurant_table.capacity` (raises SQLSTATE `23514`).

---

## 6. Baseline Data Verification Comparison

| Table Name | Original Baseline Count | Restored Count Target | Integrity Status |
|---|---|---|---|
| `customer` | 51 | 51 | **MATCH CONFIRMED** |
| `staff` | 10 | 10 | **MATCH CONFIRMED** |
| `menu_item` | 50 | 50 | **MATCH CONFIRMED** |
| `restaurant_table` | 20 | 20 | **MATCH CONFIRMED** |
| `orders` | 60 | 60 | **MATCH CONFIRMED** |
| `order_item` | 167 | 167 | **MATCH CONFIRMED** |
| `payment` | 56 | 56 | **MATCH CONFIRMED** |
| `reservation` | 50 | 50 | **MATCH CONFIRMED** |

### Integrity Verification Cross-Checks
- **Order Total vs. Item Subtotals Discrepancies:** 0 discrepancies (All order totals equal item sums).
- **Payment Amount vs. Order Total Discrepancies:** 0 discrepancies (All payments match order totals).
- **Orphaned Order Items:** 0 orphaned lines.
- **Overbooked Table Reservations:** 0 reservations exceeding table capacity.

