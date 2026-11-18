# INCIDENT DESIGN SHEET #1 (PUBLIC INCIDENT BRIEF)

**Incident ID:** G07-INC1  
**Related Flaw ID:** G07-F1  
**Project Owner:** Group 7 – CAMPUSAFE  
**Designer Group:** Group 12 – iBarangay  
**Variant:** Role Privileges & Least-Privilege Access Control  
**Related Activity:** Activity 4 (Access Control & Security Architecture)  
**Difficulty:** Easy  
**Estimated Investigation Time:** 15 Minutes  

---

### PUBLIC INCIDENT BRIEF

#### Incident Symptoms
Campus safety supervisors report that during an internal routine audit of user accounts, several standard student reporter profiles and maintenance technician accounts unexpectedly appeared in administrative management screens with elevated Administrator privileges. In addition, an administrative account was found unexpectedly set to "suspended" status, locking out a safety officer during duty hours. The system development team insists that end users do not have access to administrative user management pages in the web interface.

#### Expected Observable Behavior
When a database administrator or auditor inspects user records or attempts to simulate application updates:
1. Executing an update query against `app_user.role_id` or `app_user.account_status` using the web application's standard runtime database credentials (`campussafe_app`) succeeds immediately with `UPDATE 1` instead of being rejected with a permission denial error.
2. Checking database catalog privileges reveals that the runtime service account possesses broad modification rights across columns that should be restricted to database administrators.

#### Evidence Available to Owner Group
Investigators may inspect the following evidence sources:
- PostgreSQL system catalogs and information schema:
  - `information_schema.table_privileges`
  - `information_schema.column_privileges`
  - `pg_roles` and `pg_auth_members`
- Activity 4 Access Control documentation:
  - `docs/user-roles.md`
  - `database/03_roles_and_privileges.sql`
- Application database configuration:
  - `src/config/Database.php`
  - `.env.example`
- Simulated psql query execution under role `campussafe_app` / `app_runtime_grp`.

---
*Note: This public document contains observable symptoms only. Technical root causes, fault scripts, and reset procedures are maintained privately in the instructor answer pack.*
