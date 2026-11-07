# CAMPUSSAFE – DATABASE ACCESS CONTROL PLAN

## 1. Project Overview

**Project Name:** CampusSafe  
**Repository:** https://github.com/jeffersonorpesa2-ops/grp07-campussafe  
**Database Platform:** PostgreSQL  
**Security Model:** Role-Based Access Control (RBAC)  
**Activity:** Activity 4 – Database Users, Roles, Privileges, and Access Control

### Description

CampusSafe is a campus safety management application. This access control plan establishes database permissions for different types of users and system components to protect sensitive information and prevent unauthorized database operations.

The implementation follows the principle of **Least Privilege**, ensuring that each database account receives only the permissions required to perform its responsibilities.

---

## 2. Database Access Control Objectives

The objectives of this access control implementation are:

1. Create separate PostgreSQL group roles and login accounts.
2. Assign appropriate database privileges to each role.
3. Restrict unauthorized access to database tables and records.
4. Prevent read-only users from modifying or deleting records.
5. Allow application accounts to perform necessary database operations.
6. Separate administrative privileges from normal application access.
7. Verify that permitted and restricted operations work correctly.

---

## 3. Database Roles and Responsibilities

The following PostgreSQL group roles are proposed for CampusSafe.

| Group Role | Responsibilities |
|---|---|
| campussafe_admin_role | Manages and maintains the database environment. |
| campussafe_app_role | Allows the application to perform normal database operations. |
| campussafe_auditor_role | Allows authorized users to view records without modifying them. |

### 3.1 Database Administrator

**Role:** `campussafe_admin_role`

Responsibilities:
- Manage database records and structures.
- Perform necessary database maintenance.
- View, insert, update, and delete records.
- Manage database objects when required.

### 3.2 Application Runtime

**Role:** `campussafe_app_role`

Responsibilities:
- Support normal CampusSafe application operations.
- Retrieve records from the database.
- Insert new records.
- Update existing records.
- Delete records when required by application functionality.

### 3.3 Auditor / Read-Only User

**Role:** `campussafe_auditor_role`

Responsibilities:
- View database records.
- Inspect information for auditing purposes.
- Generate reports using authorized data.
- Prevent unauthorized modification or deletion of records.

---

## 4. Database Login Accounts

The following login accounts will be created and assigned to their respective group roles.

| Login Account | Assigned Group Role | Account Purpose |
|---|---|---|
| campussafe_admin | campussafe_admin_role | Database administration |
| campussafe_app | campussafe_app_role | Application database access |
| campussafe_auditor | campussafe_auditor_role | Read-only database access |

Group roles are created using `NOLOGIN`, while individual login accounts use `LOGIN`.

---

## 5. Privilege Assignment Matrix

The following table describes the planned database permissions.

| Database Privilege | Admin | Application | Auditor |
|---|---|---|---|
| CONNECT | YES | YES | YES |
| USAGE on public schema | YES | YES | YES |
| CREATE on public schema | YES | NO | NO |
| SELECT | YES | YES | YES |
| INSERT | YES | YES | NO |
| UPDATE | YES | YES | NO |
| DELETE | YES | YES | NO |
| Sequence USAGE | YES | YES | NO |
| Sequence SELECT | YES | YES | NO |

**Note:** These are proposed permissions. Actual grants must be adjusted according to the database tables, sequences, and application operations identified during project assessment.

---

## 6. Access Control Implementation

The access control implementation is divided into four SQL scripts.

### 6.1 01_create_roles.sql

Purpose:
- Create PostgreSQL group roles.
- Create individual login accounts.
- Assign login accounts to their corresponding group roles.

### 6.2 02_grant_privileges.sql

Purpose:
- Grant database connection privileges.
- Grant schema access.
- Assign table privileges.
- Assign sequence privileges where necessary.

### 6.3 03_revoke_privileges.sql

Purpose:
- Remove unnecessary database permissions.
- Prevent auditors from modifying records.
- Prevent application accounts from creating unauthorized database objects.

### 6.4 04_test_privileges.sql

Purpose:
- Verify database permissions.
- Test authorized database operations.
- Test unauthorized database operations.
- Confirm that the least privilege principle is implemented.

---

## 7. Security Policies

The following security policies will be applied:

1. **Least Privilege:** Every database account receives only the permissions necessary for its assigned responsibilities.
2. **Account Separation:** Administrative, application, and auditing accounts must be separate.
3. **Read-Only Restrictions:** Auditors must not be allowed to insert, update, or delete records.
4. **Administrative Protection:** Administrative privileges must only be assigned to authorized accounts.
5. **Credential Protection:** Passwords must not be exposed in source code, GitHub repositories, or documentation.
6. **Permission Verification:** All assigned permissions must be tested using the appropriate PostgreSQL accounts.
7. **Database Isolation:** Database access must be restricted to authorized roles.

---

## 8. Testing and Verification Plan

The following operations will be tested to verify that the access control implementation works correctly.

| Test Case | Expected Result |
|---|---|
| Admin performs SELECT | ALLOWED |
| Admin performs INSERT | ALLOWED |
| Admin performs UPDATE | ALLOWED |
| Admin performs DELETE | ALLOWED |
| Application performs SELECT | ALLOWED |
| Application performs INSERT | ALLOWED |
| Application performs UPDATE | ALLOWED |
| Application performs DELETE | ALLOWED, if required |
| Auditor performs SELECT | ALLOWED |
| Auditor performs INSERT | DENIED |
| Auditor performs UPDATE | DENIED |
| Auditor performs DELETE | DENIED |
| Auditor attempts CREATE on public schema | DENIED |
| Application attempts CREATE on public schema | DENIED |

Testing must be performed using separate PostgreSQL login accounts instead of relying only on the administrator account.

The results will be documented through SQL execution outputs and screenshots.

---

## 9. Expected Security Outcomes

After implementing the access control plan, CampusSafe is expected to have:

- Properly separated database roles and login accounts.
- Controlled access to database resources.
- Restricted permissions for read-only accounts.
- Appropriate privileges for application operations.
- Protected database structures against unauthorized changes.
- Verified access restrictions through PostgreSQL testing.
- Improved database security through Role-Based Access Control.

---

## 10. Conclusion

The CampusSafe database access control plan establishes a structured approach to managing PostgreSQL users, roles, and privileges.

By implementing Role-Based Access Control and following the principle of Least Privilege, the system can reduce unauthorized database access and protect important campus safety information.

The implementation will be validated through role creation, privilege assignment, privilege revocation, and permission testing.

---

## 11. AI Usage Declaration

ChatGPT was used as an assistance tool in preparing the database access control plan and drafting PostgreSQL role and privilege management scripts.

The generated SQL commands and documentation must be reviewed, adjusted to match the actual CampusSafe database structure, and validated through PostgreSQL execution and permission testing.

All final implementation decisions and verification results will be reviewed by the group.