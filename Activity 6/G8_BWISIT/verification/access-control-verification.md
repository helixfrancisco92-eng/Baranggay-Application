# Access Control and Least Privilege Verification Report
## COMP 018 — Database Administration | Activity 6
### System: Campus Canteen Pre-Order and Queue Management System (Group 8 – bwisIT Solutions)

---

## 1. Scope and RBAC Architecture Overview

This report documents the verification of the **Activity 4 Role-Based Access Control (RBAC)** configuration within the restored database environment (`canteen_db_activity6_restore_test`).

Group 8 implemented a strict least-privilege security model separating administrative DDL ownership, application runtime DML transactions, and reporting analytics into distinct login and group roles:

```text
               [ PostgreSQL Cluster Superuser: postgres ]
                                  │
                 ┌────────────────┴────────────────┐
                 │                                 │
         [ canteen_admin ]                 [ pg_auth_members ]
        (Database Owner / DDL)                     │
                 │                ┌────────────────┴────────────────┐
                 │                │                                 │
                 │         [ canteen_app_grp ]             [ canteen_readonly_grp ]
                 │          (Group Role / NOLOGIN)          (Group Role / NOLOGIN)
                 │                ▲                                 ▲
                 │                │ (inherits)                      │ (inherits)
                 │         [ canteen_app ]                 [ canteen_readonly ]
                 │        (App Runtime Login)              (Reporting Login)
                 │
                 ▼
    [ Database Objects: 7 Tables, 7 Sequences ]
    (Schema: public | PUBLIC privileges REVOKED)
```

---

## 2. Role and Membership Inventory Audit

### A. Role Definitions and Attributes
Verified from `db-access-control/01-create-roles.sql`:

| Role Name | Login Allowed? | Superuser? | Create DB? | Create Role? | Primary Responsibility |
|---|---|---|---|---|---|
| `canteen_admin` | **YES** | NO | NO | **YES** | Database and schema owner; executes migrations, DDL, and backup/restore. |
| `canteen_app_grp` | **NO** (Group) | NO | NO | NO | Container for application DML table/sequence grants. |
| `canteen_readonly_grp` | **NO** (Group) | NO | NO | NO | Container for column-level reporting grants. |
| `canteen_app` | **YES** | NO | NO | NO | Application runtime connection user (used by Spring Boot). |
| `canteen_readonly` | **YES** | NO | NO | NO | Reporting connection user (used by BI / sales queries). |

### B. Role Membership Hierarchy
Verified from `db-access-control/02-role-memberships.sql`:
- `GRANT canteen_app_grp TO canteen_app WITH INHERIT TRUE, SET TRUE, ADMIN FALSE;`
- `GRANT canteen_readonly_grp TO canteen_readonly WITH INHERIT TRUE, SET TRUE, ADMIN FALSE;`
- Unexpected inherited memberships from superuser or administrative roles are programmatically revoked by dynamic loop.

---

## 3. Granted Schema, Table, and Sequence Privileges

### A. Schema-Level Privileges on `public`
- `REVOKE ALL ON SCHEMA public FROM PUBLIC;`
- `GRANT USAGE ON SCHEMA public TO canteen_app_grp, canteen_readonly_grp;`
- Public access is completely eliminated. Users cannot create objects in `public`.

### B. Table-Level Grants for Application Runtime (`canteen_app_grp`)
Verified from `db-access-control/04-schema-and-table-privileges.sql`:

| Table Name | Granted Table Privileges | Technical Justification |
|---|---|---|
| `public.student` | `SELECT, INSERT` | Students can register and log in; student rows are never updated/deleted by app. |
| `public.vendor` | `SELECT, INSERT, UPDATE` | Stall profiles can be created, edited, and toggled active/inactive. |
| `public.menu_item` | `SELECT, INSERT, UPDATE, DELETE` | Stalls have full CRUD over their menu offerings. |
| `public.customer_order` | `SELECT, INSERT, UPDATE` | Orders are created and lifecycle status transitioned (`pending` → `completed`). |
| `public.order_item` | `SELECT, INSERT` | Order line items are created during checkout; line history is immutable. |
| `public.queue_entry` | `SELECT, INSERT, UPDATE` | Daily queue numbers are issued and called. |
| `public.notification` | `SELECT, INSERT, UPDATE` | Alerts are generated and marked `is_read = TRUE`. |

### C. Column-Level Least Privilege for Reporting (`canteen_readonly_grp`)
To protect student privacy and cryptographic credentials, `canteen_readonly_grp` has zero access to `student`, `queue_entry`, or `notification`. Grants on sales tables are strictly restricted to specific columns:
- `menu_item`: `SELECT (item_id, vendor_id, item_name, price, is_available)`
- `customer_order`: `SELECT (order_id, vendor_id, order_date, status)`
- `order_item`: `SELECT (order_id, item_id, quantity, price_at_order)`
- `vendor`: `SELECT (vendor_id, vendor_name)`
- **Excluded Columns:** Password hashes (`password_hash`), student identities (`full_name`, `email`), student roles.

### D. Sequence Grants
- `USAGE, SELECT, UPDATE` on all 7 sequences in `public` granted to `canteen_app_grp` to support `SERIAL` column auto-increment during `INSERT`.

---

## 4. Privilege Verification and Security Boundary Testing

The verification suite [`verify-access-control.sql`](file:///c:/Users/Lenovo/Downloads/ACT%206/G8_BWISIT/db-backup-recovery/group-08-campus-canteen/scripts/verify-access-control.sql) executes both positive (permitted) and negative (denied) security tests.

### A. Permitted Operation: Application DML Test
- **Tested Role:** `canteen_app` (via `canteen_app_grp`)
- **Executed Action:** Read active vendor menu items:
  ```sql
  SET ROLE canteen_app;
  SELECT item_id, item_name, price, is_available FROM public.menu_item LIMIT 3;
  RESET ROLE;
  ```
- **Expected Result:** **SUCCESS (200 OK)**. Returns 3 records (`Tapsilog`, `Longsilog`, `Tosilog`).

### B. Denied Operation 1: Unauthorized Mutation by Reporting User
- **Tested Role:** `canteen_readonly` (via `canteen_readonly_grp`)
- **Executed Action:** Attempt to insert an order record:
  ```sql
  SET ROLE canteen_readonly;
  INSERT INTO public.customer_order (student_id, vendor_id, pickup_time, status)
  VALUES (1, 1, '13:00', 'pending');
  ```
- **Expected Result:** **DENIED (PostgreSQL Error `42501`: `permission denied for table customer_order`)**.
- **Verification:** Trapped by `insufficient_privilege` exception handler. Confirms read-only isolation.

### C. Denied Operation 2: Unauthorized Column Access by Reporting User
- **Tested Role:** `canteen_readonly` (via `canteen_readonly_grp`)
- **Executed Action:** Attempt to query student credential hashes:
  ```sql
  SET ROLE canteen_readonly;
  SELECT full_name, email, password_hash FROM public.student;
  ```
- **Expected Result:** **DENIED (PostgreSQL Error `42501`: `permission denied for table student`)**.
- **Verification:** Trapped by exception handler. Confirms personal identifiable information protection.

### D. Denied Operation 3: Unauthorized DDL Modification by Application User
- **Tested Role:** `canteen_app`
- **Executed Action:** Attempt to drop the `notification` table:
  ```sql
  SET ROLE canteen_app;
  DROP TABLE public.notification;
  ```
- **Expected Result:** **DENIED (PostgreSQL Error `42501`: `must be owner of table notification`)**.
- **Verification:** Confirms separation of administrative ownership (`canteen_admin`) from runtime execution.

---

## 5. Restoration Considerations for Cluster-Wide Roles

> [!IMPORTANT]
> **PostgreSQL Logical Backup Limitation:**  
> A single-database `pg_dump` archive (`-Fc`) stores database-level schemas, tables, and permissions, but **does not contain cluster-wide role definitions** (`pg_authid`).  
> If restoring into a brand new or secondary PostgreSQL cluster where the roles `canteen_admin`, `canteen_app`, and `canteen_readonly` do not yet exist, `pg_restore` will emit warnings regarding missing owners and privileges.  
> **Standard Remediation Procedure:**  
> 1. Execute `db-access-control/01-create-roles.sql` and `02-role-memberships.sql` under cluster superuser `postgres`.
> 2. Execute `pg_restore -U postgres -d canteen_db_activity6_restore_test <backup_file>.dump`.
> 3. Verify all role grants using `scripts/verify-access-control.sql`.

---

## 6. Execution Status Summary

- **RBAC Audit:** **VERIFIED** against repository SQL definitions.
- **Grant Matrix:** **VERIFIED** for schema, tables, columns, and sequences.
- **Verification Suite:** **IMPLEMENTED** in `scripts/verify-access-control.sql`.
- **Live Database Run:** **PENDING OPERATOR DATABASE RUN** (requires interactive entry of local PostgreSQL superuser credentials).

