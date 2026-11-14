# Access Control and Database Role Verification
## COMP 018 — Database Administration | Activity 6
### Assigned Project: BoardTrack — Boarding House & Rental Management System (Group 11)

---

## 1. Access-Control Architecture Overview

BoardTrack implements a two-tier defense-in-depth access control model:
1. **Application Layer (Node.js/Express):** User authentication via bcrypt hashes in `app_user` and fine-grained authorization implemented in the permission table at the top of `src/auth.js`.
2. **Database Engine Layer (PostgreSQL RBAC):** Database roles, role inheritance, and object privileges as defined in the Activity 4 specification (`docs/user-roles.md`).

### Critical Architectural Finding on PostgreSQL Single-Database Restores
**PostgreSQL roles, passwords, and group memberships are cluster-wide global objects stored in `pg_authid` and `pg_auth_members`. A standard logical database dump (`pg_dump -Fc -d boardtrack_db`) extracts ONLY database-specific objects (schemas, tables, views, triggers, sequences, data) and does NOT include cluster roles.**

Consequently, when restoring `boardtrack_db_activity6.dump` into a fresh PostgreSQL instance, database roles must either be:
- Pre-provisioned using the Activity 4 DDL script (`CREATE ROLE ...`).
- Restored from a cluster-wide globals dump (`pg_dumpall --globals-only`).

---

## 2. PostgreSQL Role Inventory and Hierarchy

The Activity 4 specification establishes five primary database roles structured under the principle of least privilege, supplemented by the Activity 6 dedicated backup account:

| Role Name | Role Type | Superuser? | Login Allowed? | Member Of | Intended Responsibilities |
|---|---|:---:|:---:|---|---|
| **`boardtrack_owner`** | Individual User | No | Yes | *(None)* | Owns the database and schema objects; executes migrations and DDL. Never used by the web app. |
| **`boardtrack_admin_grp`** | Group Role | No | No (`NOLOGIN`) | *(None)* | Administrative group role granted `ALL` DML privileges on all business tables. |
| **`app_runtime_grp`** | Group Role | No | No (`NOLOGIN`) | *(None)* | Application runtime group role granted `SELECT`, `INSERT`, `UPDATE`, `DELETE` on tables, `USAGE` on sequences. |
| **`app_readonly_grp`** | Group Role | No | No (`NOLOGIN`) | *(None)* | Read-only reporting group granted `SELECT` on business tables and `v_lease_summary`. |
| **`boardtrack_app`** | Service Account | No | Yes | `app_runtime_grp` | Dedicated web runtime login role utilized by Node.js (`DATABASE_URL`). |
| **`boardtrack_backup`** | Service Account | No | Yes | `app_readonly_grp` | Dedicated backup account for `pg_dump` operations; no DDL or DML write permissions. |

---

## 3. Privilege Grants Matrix

| Database Object | `boardtrack_owner` | `boardtrack_admin_grp` | `app_runtime_grp` / `boardtrack_app` | `app_readonly_grp` / `boardtrack_backup` |
|---|:---:|:---:|:---:|:---:|
| **Schema `public`** | `ALL` | `USAGE`, `CREATE` | `USAGE` | `USAGE` |
| **`property`** | `ALL` | `ALL` | `SELECT`, `INSERT`, `UPDATE`, `DELETE` | `SELECT` |
| **`room`** | `ALL` | `ALL` | `SELECT`, `INSERT`, `UPDATE`, `DELETE` | `SELECT` |
| **`tenant`** | `ALL` | `ALL` | `SELECT`, `INSERT`, `UPDATE`, `DELETE` | `SELECT` |
| **`lease`** | `ALL` | `ALL` | `SELECT`, `INSERT`, `UPDATE`, `DELETE` | `SELECT` |
| **`payment`** | `ALL` | `ALL` | `SELECT`, `INSERT`, `UPDATE`, `DELETE` | `SELECT` |
| **`utility_bill`** | `ALL` | `ALL` | `SELECT`, `INSERT`, `UPDATE`, `DELETE` | `SELECT` |
| **`app_user`** | `ALL` | `ALL` | `SELECT`, `INSERT`, `UPDATE` | `NONE` (or sanitized view) |
| **`v_lease_summary`**| `ALL` | `SELECT` | `SELECT` | `SELECT` |
| **All Sequences** | `ALL` | `USAGE`, `SELECT` | `USAGE`, `SELECT` | `SELECT` |

### Architectural Privilege Alignment Note
As documented in `docs/user-roles.md` and remediated in the flaw report:
> `app_runtime_grp` **must** include `DELETE` on public tables because the application's administrative web routes execute deletions on properties, rooms, tenants, leases, payments, and bills. Narrower role access (e.g., preventing staff and tenant users from deleting records) is enforced in the application authorization layer (`src/auth.js`). If `DELETE` were omitted at the PostgreSQL role level, legitimate administrative deletions would trigger `SQLSTATE 42501 (insufficient_privilege)`.

---

## 4. Functional Access-Control Enforcement Tests

The following tests verify that database-level privilege boundaries are strictly enforced:

### Test 1: Permitted Operation (Authorized Application Runtime Query)
- **Actor Role:** `boardtrack_app` (via `app_runtime_grp`)
- **Action:** Query financial reporting view `v_lease_summary`
- **SQL Executed:**
  ```sql
  SELECT lease_id, tenant, total_paid, utilities_billed 
  FROM v_lease_summary 
  LIMIT 5;
  ```
- **Observed / Expected Result:** **SUCCESS** — Query executes cleanly and returns summarized lease financial aggregates without error.

### Test 2: Denied Operation 1 (Unauthorized DELETE by Read-Only Role)
- **Actor Role:** `app_readonly_grp` (or `boardtrack_backup`)
- **Action:** Attempt to execute a `DELETE` statement against `payment`
- **SQL Executed:**
  ```sql
  SET LOCAL ROLE app_readonly_grp;
  DELETE FROM payment WHERE payment_id = 1;
  ```
- **Observed / Expected Result:** **BLOCKED (DENIED)**
  ```text
  ERROR: permission denied for table payment
  SQLSTATE: 42501 (insufficient_privilege)
  ```
- **Security Validation:** Confirms that read-only accounts and backup roles cannot modify, purge, or alter transaction records.

### Test 3: Denied Operation 2 (Unauthorized DDL by Application Runtime Role)
- **Actor Role:** `boardtrack_app` (via `app_runtime_grp`)
- **Action:** Attempt to drop the `payment` table
- **SQL Executed:**
  ```sql
  SET LOCAL ROLE boardtrack_app;
  DROP TABLE payment CASCADE;
  ```
- **Observed / Expected Result:** **BLOCKED (DENIED)**
  ```text
  ERROR: must be owner of table payment
  SQLSTATE: 42501 (insufficient_privilege)
  ```
- **Security Validation:** Confirms that runtime accounts cannot execute destructive DDL operations even if the web application is compromised by an SQL injection attack.

---

## 5. Discovered Limitations and Remediation Recommendations

1. **Role Portability Blocker:**
   - *Issue:* Restoring into an empty cluster creates tables owned by the restoring superuser (`postgres`) because `boardtrack_owner` does not exist by default.
   - *Recommendation:* Maintain a cluster-level initialization script (`db/000_create_roles.sql`) in the repository and run it prior to database restoration:
     ```sql
     CREATE ROLE boardtrack_owner WITH LOGIN PASSWORD '<SECURE_PASS>';
     CREATE ROLE app_runtime_grp NOLOGIN;
     CREATE ROLE app_readonly_grp NOLOGIN;
     CREATE ROLE boardtrack_app WITH LOGIN PASSWORD '<SECURE_PASS>' IN ROLE app_runtime_grp;
     ```
2. **Password Security in `app_user`:**
   - *Finding:* Application passwords use bcrypt (`crypt(..., gen_salt('bf'))`) in `app_user`. While strong, direct `SELECT` on `app_user.password_hash` should be restricted to authentication functions only, with general views masking this column.

