# PARK-IT DATABASE SYSTEM
# DATABASE ACCESS CONTROL PLAN
## COMP 018 – Database Administration | Activity 4

**Project Name:** Park-It Database System  
**Repository:** https://github.com/millerdevera6-glitch/park-it-database.git  
**Activity:** Database Users, Roles, Privileges, and Access Control

---

## 1. PROJECT OVERVIEW

The Park-It Database System is designed to manage parking-related information and database operations.

This Access Control Plan establishes the security structure of the PostgreSQL database by defining database users, group roles, permissions, and restrictions.

The implementation follows Role-Based Access Control (RBAC), ensuring that each database account receives only the permissions necessary to perform its assigned responsibilities.

## 2. OBJECTIVES

The objectives of this access control plan are:

- Establish appropriate PostgreSQL database users and group roles.
- Assign permissions based on user responsibilities.
- Prevent unauthorized database access and modifications.
- Implement the principle of least privilege.
- Protect parking-related database records.
- Verify that permitted and restricted database operations work correctly.

## 3. DATABASE USER ACCOUNTS

The following login accounts are proposed for the Park-It Database System.

| Login Account | Group Role | Responsibility |
|---|---|---|
| park_admin | park_admin_grp | Database administration |
| park_app | park_runtime_grp | Application database operations |
| park_viewer | park_viewer_grp | View parking information |
| park_staff | park_staff_grp | Manage parking-related records |
| park_auditor | park_auditor_grp | Inspect database records |

These accounts are PostgreSQL database accounts and are separate from application-level user accounts.

## 4. GROUP ROLES AND PRIVILEGES

| Group Role | Privileges | Description |
|---|---|---|
| park_admin_grp | Administrative privileges | Maintains and manages the database environment. |
| park_runtime_grp | SELECT, INSERT, UPDATE, DELETE | Performs normal application database operations. |
| park_viewer_grp | SELECT | Views approved parking information without modifying records. |
| park_staff_grp | SELECT, INSERT, UPDATE | Manages parking-related information without deleting records. |
| park_auditor_grp | SELECT | Inspects records for auditing and verification. |

Administrative privileges will be assigned only when necessary. The administrator account should not be used for normal application operations.

## 5. ACCESS CONTROL MATRIX

The following matrix describes the permissions assigned to each group role.

| Database Operation | Admin | Runtime | Viewer | Staff | Auditor |
|---|---|---|---|---|---|
| SELECT | Allowed | Allowed | Allowed | Allowed | Allowed |
| INSERT | As needed | Allowed | Denied | Allowed | Denied |
| UPDATE | As needed | Allowed | Denied | Allowed | Denied |
| DELETE | As needed | Allowed | Denied | Denied | Denied |

**Legend:**
- Allowed – The role is permitted to perform the operation.
- Denied – The role is restricted from performing the operation.
- As needed – Administrative access is limited to authorized database maintenance tasks.

## 6. ROLE MEMBERSHIP STRUCTURE

The following PostgreSQL role memberships will be implemented:

- park_admin belongs to park_admin_grp.
- park_app belongs to park_runtime_grp.
- park_viewer belongs to park_viewer_grp.
- park_staff belongs to park_staff_grp.
- park_auditor belongs to park_auditor_grp.

Group roles are created using NOLOGIN, while individual database accounts are created using LOGIN.

This separates database privileges from individual authentication accounts.

## 7. DATABASE AND SCHEMA ACCESS

The following database-level and schema-level permissions will be implemented:

**Database Access**
- Grant CONNECT to application-related group roles.
- Restrict unnecessary database access.
- Avoid granting CREATEDB and CREATEROLE to ordinary application accounts.

**Schema Access**
- Grant USAGE on the public schema to approved group roles.
- Grant CREATE only to authorized administrative accounts when necessary.

**Table Access**
- Runtime accounts receive the permissions needed for application operations.
- Viewer accounts receive SELECT privileges only.
- Staff accounts receive SELECT, INSERT, and UPDATE privileges.
- Auditor accounts receive read-only access.

**Sequence Access**
- Grant necessary sequence privileges to roles that insert records using PostgreSQL sequences.
- Do not grant sequence modification privileges unnecessarily.

## 8. SECURITY PRINCIPLES

The Park-It Database System will follow these security principles:

**8.1 Least Privilege**

Every database account receives only the permissions necessary to perform its assigned responsibilities.

**8.2 Role-Based Access Control**

Permissions are assigned to group roles instead of granting individual privileges separately to every login account.

**8.3 Separation of Duties**

Database administration, application operations, staff management, viewing, and auditing are separated into different roles.

**8.4 Restricted Access**

Users who only need to inspect records cannot insert, update, or delete database information.

**8.5 Accountability**

Separate database accounts allow database activities and access permissions to be reviewed.

## 9. PRIVILEGE VERIFICATION AND TESTING

The following tests will be conducted to verify the implemented permissions.

| Test Case | Account | Expected Result |
|---|---|---|
| View database records | park_viewer | Successful |
| Insert a database record | park_viewer | Permission denied |
| Update a database record | park_viewer | Permission denied |
| Delete a database record | park_viewer | Permission denied |
| View database records | park_auditor | Successful |
| Update a database record | park_auditor | Permission denied |
| Insert a database record | park_staff | Successful |
| Update a database record | park_staff | Successful |
| Delete a database record | park_staff | Permission denied |
| Perform application operations | park_app | Successful, subject to required table privileges |

Testing will be performed using the actual PostgreSQL login accounts to confirm that the configured permissions are enforced.

## 10. EXPECTED SECURITY OUTCOME

After implementing the access control plan:

- Database accounts will have clearly defined responsibilities.
- Group roles will manage common database permissions.
- Unauthorized database modifications will be restricted.
- Application operations will be performed using appropriate database accounts.
- Read-only users will be prevented from modifying database records.
- Database privileges will be verified through SQL testing.

## 11. CONCLUSION

The Park-It Database System Access Control Plan establishes a structured PostgreSQL security configuration using Role-Based Access Control.

By implementing group roles, login accounts, role memberships, database privileges, and access restrictions, the system can protect its parking-related information against unauthorized operations.

The implementation also supports the principle of least privilege, ensuring that database users receive only the permissions required for their responsibilities.

## 12. AI USAGE DECLARATION

ChatGPT was used as an AI assistance tool to help prepare the PostgreSQL access control plan, role definitions, privilege assignments, and testing procedures.

The generated SQL scripts and access control configurations must be reviewed and validated against the actual Park-It database structure before submission.

All database permissions and test results should be verified using PostgreSQL.
