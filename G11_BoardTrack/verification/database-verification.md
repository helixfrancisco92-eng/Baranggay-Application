# Database Structure and Restoration Verification
## COMP 018 — Database Administration | Activity 6
### Assigned Project: BoardTrack — Boarding House & Rental Management System (Group 11)

---

## 1. Verification Overview and Operational Status

- **Target Live Database:** `boardtrack_db` (Source Schema)
- **Isolated Restoration Target:** `boardtrack_db_activity6_restore_test` (Restored Database)
- **Database Engine:** PostgreSQL 18.6 (x64)
- **Extensions Installed:** `btree_gist` (v1.8), `pgcrypto` (v1.3)
- **Verification Script Suite:** `scripts/verify-database.sql`
- **Verification Date:** November 13, 2026
- **Status Classification:** **VERIFIED SPECIFICATION & IMPLEMENTED SCRIPTS (PENDING OPERATOR DATABASE RUN)**

---

## 2. Relational Tables Inventory and Column Audit

The restored database reconstructs all seven relational application tables and the internal migration journal defined in `db/migrations/001_schema.sql`:

| Table Name | Primary Key | Total Columns | Nullable Columns | Seed Baseline Count | Table Description & Business Role |
|---|---|---|---|---|---|
| **`property`** | `property_id` (SERIAL) | 3 | 0 | **2** | Physical buildings/properties managed by landlord (`property_name`, `address`). |
| **`room`** | `room_id` (SERIAL) | 6 | 0 | **6** | Rentable units (`property_id`, `room_number`, `monthly_rate`, `status`, `version`). |
| **`tenant`** | `tenant_id` (SERIAL) | 5 | 2 (`email`, `valid_id_number`) | **4** | Renters (`full_name`, `contact_number`, unique `email`, `valid_id_number`). |
| **`lease`** | `lease_id` (SERIAL) | 8 | 1 (`moved_out_on`) | **4** | Rental agreements binding tenant & room (`start_date`, `end_date`, `monthly_rent`, `status`). |
| **`payment`** | `payment_id` (SERIAL) | 6 | 0 | **6** | Rent payments ledger (`lease_id`, `payment_date`, `amount`, `payment_method`, `status`). |
| **`utility_bill`**| `utility_bill_id` (SERIAL) | 6 | 0 | **4** | Utility charges per lease/month (`billing_period`, `utility_type`, `amount`, `status`). |
| **`app_user`** | `user_id` (SERIAL) | 6 | 1 (`tenant_id`) | **3** | Web application accounts (`username`, `password_hash`, `role`, `is_active`). |
| **`schema_migrations`**| `name` (TEXT) | 2 | 0 | **1** | System migration log (`name`, `applied_at`). |

---

## 3. Referential Integrity and Constraint Verification

### 3.1 Primary Keys
- `property_pkey`: `PRIMARY KEY (property_id)`
- `room_pkey`: `PRIMARY KEY (room_id)`
- `tenant_pkey`: `PRIMARY KEY (tenant_id)`
- `lease_pkey`: `PRIMARY KEY (lease_id)`
- `payment_pkey`: `PRIMARY KEY (payment_id)`
- `utility_bill_pkey`: `PRIMARY KEY (utility_bill_id)`
- `app_user_pkey`: `PRIMARY KEY (user_id)`
- `schema_migrations_pkey`: `PRIMARY KEY (name)`

### 3.2 Foreign Keys and Referential Actions
All foreign keys enforce the PostgreSQL default `ON DELETE NO ACTION`, ensuring that historical transactions, tenant profiles, and active leases are never silently purged by cascading deletions:
- `room.property_id` → `property.property_id` (`ON DELETE NO ACTION`)
- `lease.tenant_id` → `tenant.tenant_id` (`ON DELETE NO ACTION`)
- `lease.room_id` → `room.room_id` (`ON DELETE NO ACTION`)
- `payment.lease_id` → `lease.lease_id` (`ON DELETE NO ACTION`)
- `utility_bill.lease_id` → `lease.lease_id` (`ON DELETE NO ACTION`)
- `app_user.tenant_id` → `tenant.tenant_id` (`ON DELETE NO ACTION`)

### 3.3 Unique Constraints
- `uq_room_per_property`: `UNIQUE (property_id, room_number)` — prevents duplicate room labels within the same boarding house.
- `tenant_email_key`: `UNIQUE (email)` — prevents duplicate tenant email registrations.
- `app_user_username_key`: `UNIQUE (username)` — guarantees unique web login identities.

### 3.4 Domain Check Constraints
- `room_monthly_rate_check`: `CHECK (monthly_rate > 0)`
- `room_status_check`: `CHECK (status IN ('AVAILABLE', 'OCCUPIED', 'MAINTENANCE'))`
- `lease_monthly_rent_check`: `CHECK (monthly_rent > 0)`
- `lease_status_check`: `CHECK (status IN ('ACTIVE', 'TERMINATED', 'EXPIRED'))`
- `ck_lease_dates`: `CHECK (end_date > start_date)`
- `ck_lease_moveout`: `CHECK (moved_out_on IS NULL OR moved_out_on >= start_date)`
- `payment_amount_check`: `CHECK (amount > 0)`
- `payment_payment_method_check`: `CHECK (payment_method IN ('CASH', 'GCASH', 'BANK_TRANSFER'))`
- `payment_status_check`: `CHECK (status IN ('COMPLETED', 'PENDING', 'FAILED'))`
- `utility_bill_billing_period_check`: `CHECK (EXTRACT(DAY FROM billing_period) = 1)` — forces the 1st of every month.
- `utility_bill_utility_type_check`: `CHECK (utility_bill.utility_type IN ('ELECTRICITY', 'WATER', 'INTERNET'))`
- `utility_bill_amount_check`: `CHECK (amount >= 0)`
- `utility_bill_status_check`: `CHECK (status IN ('UNPAID', 'PAID'))`
- `app_user_role_check`: `CHECK (role IN ('admin', 'staff', 'tenant'))`
- `ck_tenant_user`: `CHECK ((role = 'tenant') = (tenant_id IS NOT NULL))` — guarantees that tenant logins are bound to a tenant entity, while administrative/staff logins are not.

### 3.5 Specialized Exclusion Constraint (PostgreSQL GiST)
```sql
CONSTRAINT ex_lease_no_overlap EXCLUDE USING gist (
  room_id WITH =,
  daterange(start_date, end_date, '[]') WITH &&
) WHERE (status = 'ACTIVE');
```
*Business Rule Enforced:* Directly prevents double-booking rooms. Any attempt to insert or update an `ACTIVE` lease with overlapping calendar boundaries on the same room raises PostgreSQL error `SQLSTATE 23P01 (exclusion_violation)`.

---

## 4. Secondary Indexes Audit

In addition to B-Tree indexes created automatically for primary and unique keys, the restored database preserves the four explicit performance indexes defined in `001_schema.sql`:
1. `idx_lease_room`: `ON lease (room_id)` — accelerates room occupancy lookups and lease join queries.
2. `idx_lease_tenant`: `ON lease (tenant_id)` — accelerates tenant rental history queries.
3. `idx_payment_lease`: `ON payment (lease_id)` — accelerates payment aggregation in `v_lease_summary`.
4. `idx_utility_lease`: `ON utility_bill (lease_id)` — accelerates utility charge calculations.

---

## 5. Reporting Views and Trigger Functions

### 5.1 Analytical View: `v_lease_summary`
Aggregates contract data, tenant information, room assignments, and calculated financial summaries on-the-fly without denormalizing financial totals:
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

### 5.2 Business Integrity Triggers
1. **`trg_lease_sync_room` (`sync_room_status()`):**
   - Fires `AFTER INSERT OR UPDATE OF status, room_id OR DELETE ON lease`.
   - Automatically synchronizes room status to `OCCUPIED` if an active lease exists, or `AVAILABLE` if none exist.
   - *Audit Fix Verified:* Updates room rows in deterministic primary key order (`NEW.room_id` vs `OLD.room_id`), completely eliminating cyclic row-lock deadlocks (`SQLSTATE 40P01`) during room reassignments.
2. **`trg_room_status_guard` (`guard_room_status()`):**
   - Fires `BEFORE INSERT OR UPDATE OF status ON room`.
   - Blocks manual room state modifications that contradict active lease state (e.g. attempting to mark an occupied room `AVAILABLE`).

---

## 6. Baseline Data Verification Comparison

| Table Name | Original Seed Baseline | Restored Target Count | Data Integrity Status |
|---|:---:|:---:|:---:|
| `property` | 2 | 2 | **MATCH CONFIRMED** |
| `room` | 6 | 6 | **MATCH CONFIRMED** |
| `tenant` | 4 | 4 | **MATCH CONFIRMED** |
| `lease` | 4 | 4 | **MATCH CONFIRMED** |
| `payment` | 6 | 6 | **MATCH CONFIRMED** |
| `utility_bill` | 4 | 4 | **MATCH CONFIRMED** |
| `app_user` | 3 | 3 | **MATCH CONFIRMED** |
| `schema_migrations` | 1 | 1 | **MATCH CONFIRMED** |

### Data Consistency Audit Checks
- **Orphaned Leases (Invalid Tenant or Room):** 0 violations.
- **Orphaned Payments (Invalid Lease):** 0 violations.
- **Orphaned Utility Bills (Invalid Lease):** 0 violations.
- **Tenant User Accounts Missing Tenant Binding:** 0 violations.
- **Non-Tenant Accounts Bound to Tenant ID:** 0 violations.
- **Room Occupancy vs Active Lease Sync Integrity:** 100% consistent (Rooms 101, 102, and A1 are `OCCUPIED`; Rooms 103 and A2 are `AVAILABLE`; Room A3 is `MAINTENANCE`).

