# FLAW #1: Excessive Table-Level UPDATE Privileges on app_user Relation

**Flaw ID:** G07-F1  
**Project Owner:** Group 7 – CAMPUSAFE  
**Reported By:** Group 12 – iBarangay  
**Affected Area:** Privileges & Role-Based Access Control (RBAC)  
**Related Activity:** Activity 4 (Access Control & Security Architecture)  

---

### Description

During inspection of Group 7's Activity 4 database initialization script (`database/03_roles_and_privileges.sql`), it was discovered that the application runtime group role `app_runtime_grp` (and its concrete login user `campussafe_app`) was granted unconstrained table-wide `UPDATE` privileges on the `app_user` catalog table. 

The `app_user` table contains security-critical columns, including:
- `role_id` (foreign key to `role(role_id)`, determining whether a user has Reporter, Maintenance, Safety Officer, or Administrator privileges).
- `account_status` (determining whether an account is `'active'`, `'inactive'`, or `'suspended'`).
- `password_hash` (the bcrypt authentication secret).

Because PostgreSQL table-level `UPDATE` privileges apply across all columns of a relation unless explicitly restricted, any database session connecting under `campussafe_app` possesses the relational authorization to modify `role_id` or `account_status` directly. If an application-level vulnerability (such as a mass assignment flaw, improper authorization check, or SQL injection) occurs in a public profile-update route, an unprivileged campus reporter can elevate their own account or other users' accounts to full Administrator status, or arbitrarily suspend administrative accounts.

---

### Evidence

- **Repository File:** `grp07-campussafe/database/03_roles_and_privileges.sql` (Lines 64–65)
  ```sql
  -- Granular UPDATE: Granted ONLY to mutable entities.
  -- Strictly excludes immutable audit history (report_status_history) and technician action logs (maintenance_action)
  GRANT UPDATE ON hazard_report, assignment, app_user, hazard_category, campus_location
      TO app_runtime_grp;
  ```
- **Actual Database Object:** Table `public.app_user` and role `app_runtime_grp`.
- **SQL Command / Inspection Method:**
  ```sql
  SELECT grantee, table_schema, table_name, privilege_type 
  FROM information_schema.table_privileges 
  WHERE table_name = 'app_user' AND grantee = 'app_runtime_grp';
  ```
- **Actual Result:**
  ```
   grantee         | table_schema | table_name | privilege_type 
  -----------------+--------------+------------+----------------
   app_runtime_grp | public       | app_user   | UPDATE
  (1 row)
  ```
  Inspection of `information_schema.column_privileges` confirms that `0 rows` exist for column-level restrictions on `app_user`, proving that `UPDATE` applies to all columns.
- **Screenshot / Evidence File:** Referenced in `midterm/evidence/designer/G07_F1_privilege_evidence.txt` and Activity 4 Access Control Report.
- **Baseline Comparison:** `docs/user-roles.md` specifies that administrative user management and role assignment must be strictly restricted to Administrators. Granting table-wide `UPDATE` to the general runtime service account contradicts the documented least-privilege architecture.

---

### Impact

- **Security & Authorization (Critical):** Direct violation of the Principle of Least Privilege. Allows horizontal and vertical privilege escalation. A compromised application endpoint or malicious query executed via `campussafe_app` can alter `app_user.role_id` to `1` (Administrator), granting full administrative control over the entire hazard reporting system.
- **Account Availability:** Malicious or erroneous updates can toggle `account_status` to `'suspended'` for emergency responders and safety officers, locking personnel out of critical campus safety operations.

---

### Severity

**High** (Confirmed Flaw)

---

### Recommended Fix

Revoke the broad table-level `UPDATE` privilege on `app_user` from `app_runtime_grp`, and replace it with granular, column-level `UPDATE` privileges granted strictly on legitimate, mutable user-profile attributes (`full_name`, `email`, `password_hash`).

```sql
-- Step 1: Connect as database administrator / owner
REVOKE UPDATE ON public.app_user FROM app_runtime_grp;

-- Step 2: Grant column-level UPDATE on safe profile attributes only
GRANT UPDATE (full_name, email, password_hash) ON public.app_user TO app_runtime_grp;
```

Administrative role assignments (`role_id`) and account status changes (`account_status`) must be performed exclusively by authorized administrative accounts or dedicated, security-defended stored procedures.

---

### Verification

Execute the following test suite under role `campussafe_app`:

1. **Negative Test (Must Fail with Permission Denied):**
   ```sql
   SET ROLE campussafe_app;
   UPDATE app_user SET role_id = 1 WHERE user_id = 2;
   ```
   *Expected Result:* `ERROR: permission denied for column "role_id" of relation "app_user" (SQLSTATE 42501)`.

2. **Negative Test 2 (Must Fail with Permission Denied):**
   ```sql
   SET ROLE campussafe_app;
   UPDATE app_user SET account_status = 'suspended' WHERE user_id = 2;
   ```
   *Expected Result:* `ERROR: permission denied for column "account_status" of relation "app_user" (SQLSTATE 42501)`.

3. **Positive Test (Must Succeed):**
   ```sql
   SET ROLE campussafe_app;
   UPDATE app_user SET full_name = 'Juan Dela Cruz Jr.' WHERE user_id = 2;
   ```
   *Expected Result:* `UPDATE 1` (Successfully modifies authorized user profile information).
