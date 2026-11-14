
# HABALGO DATABASE ACCESS CONTROL PLAN

**Project Name:** HabalGo  
**Activity:** Activity 4 – Database Access Control  
**Database Management System:** PostgreSQL  
**Security Model:** Role-Based Access Control (RBAC)

---

## 1. INTRODUCTION

This Access Control Plan describes the implementation of
Role-Based Access Control (RBAC) for the HabalGo database.

The purpose of this implementation is to ensure that
only authorized users can access and manage database
information based on their assigned responsibilities.

PostgreSQL roles and privileges are used to control
database access and protect important application data.

## 2. OBJECTIVES

The objectives of this access control implementation
are the following:

- Protect the HabalGo database from unauthorized access.
- Assign database permissions based on user responsibilities.
- Prevent unauthorized modification and deletion of records.
- Apply the Principle of Least Privilege.
- Improve database security and accountability.
- Ensure that users only access the information
  necessary for their tasks.

## 3. ACCESS CONTROL MODEL

HabalGo uses Role-Based Access Control (RBAC).

Under this model, permissions are assigned to roles
rather than directly assigning individual permissions
to every user.

Users are assigned roles, and each role receives
specific database privileges.

The following roles are implemented:

### 3.1 Database Administrator

**Role Name:** `habalgo_admin_role`

**Login Account:** `habalgo_admin_user`

**Description:**

The Database Administrator is responsible for
managing the HabalGo database.

**Permissions:**
- SELECT
- INSERT
- UPDATE
- DELETE
- CREATE
- Other granted database object privileges

**Responsibilities:**
- Manage database records.
- Maintain database information.
- Insert, update, and delete records.
- Manage database objects within assigned privileges.
- Maintain database security.

### 3.2 Application User

**Role Name:** `habalgo_app_role`

**Login Account:** `habalgo_app_user`

**Description:**

The Application User represents the database access
used by the HabalGo application backend.

**Permissions:**
- SELECT
- INSERT
- UPDATE

**Restrictions:**
- Cannot DELETE records.
- Cannot CREATE database objects.

**Responsibilities:**
- Retrieve application information.
- Insert new application records.
- Update existing records.
- Process database operations required by the application.

### 3.3 Database Auditor

**Role Name:** `habalgo_auditor_role`

**Login Account:** `habalgo_auditor_user`

**Description:**

The Database Auditor is responsible for viewing
and inspecting database information.

**Permissions:**
- SELECT

**Restrictions:**
- Cannot INSERT records.
- Cannot UPDATE records.
- Cannot DELETE records.
- Cannot CREATE database objects.

**Responsibilities:**
- View database records.
- Inspect stored information.
- Perform read-only database auditing.
- Review information without modifying records.

## 4. PERMISSION MATRIX

The following table presents the permissions
assigned to each database role.

| Database Permission | Admin | Application | Auditor |
|---------------------|-------|-------------|---------|
| SELECT              | YES   | YES         | YES     |
| INSERT              | YES   | YES         | NO      |
| UPDATE              | YES   | YES         | NO      |
| DELETE              | YES   | NO          | NO      |
| CREATE              | YES   | NO          | NO      |

## 5. ROLE AND USER MANAGEMENT

The following PostgreSQL roles and login accounts
are created:

| Role Name | Login Account | Purpose |
|-----------|---------------|---------|
| habalgo_admin_role | habalgo_admin_user | Database administration |
| habalgo_app_role | habalgo_app_user | Application operations |
| habalgo_auditor_role | habalgo_auditor_user | Read-only auditing |

Each login account is assigned to its corresponding
group role using PostgreSQL GRANT statements.

This makes permission management easier and more
organized.

## 6. PRIVILEGE IMPLEMENTATION

The access control implementation consists of
four SQL scripts.

### 6.1 01_create_roles.sql

This script creates the PostgreSQL group roles
and login accounts.

It also assigns each login account to its
corresponding group role.

### 6.2 02_grant_privileges.sql

This script grants database privileges to
the different roles.

The administrator receives broad database object
privileges, the application role receives
SELECT, INSERT, and UPDATE permissions, and
the auditor receives SELECT permission only.

### 6.3 03_revoke_privileges.sql

This script removes unnecessary permissions
from selected roles.

The application role is restricted from
deleting records, while the auditor is restricted
from modifying database information.

### 6.4 04_test_privileges.sql

This script verifies the permissions assigned
to each role.

It checks whether the roles have the correct
SELECT, INSERT, UPDATE, DELETE, and CREATE
privileges.

It also verifies role memberships.

## 7. SECURITY POLICIES

The following security policies are applied
to the HabalGo database:

### 7.1 Principle of Least Privilege

Every database role receives only the permissions
necessary to perform its assigned responsibilities.

### 7.2 Restricted Database Operations

Users are prevented from performing unauthorized
database operations.

For example, application users cannot delete
records, and auditors cannot modify information.

### 7.3 Role-Based Permission Assignment

Permissions are assigned through PostgreSQL
roles to make database access management
more organized.

### 7.4 Database Access Verification

Database privileges are checked using SQL
queries to ensure that the assigned permissions
are correct.

### 7.5 Account Security

Each login account should have a secure password.
Database credentials must not be shared or
exposed in public repositories.

## 8. EXPECTED SECURITY RESULTS

After implementing the access control plan,
the following results are expected:

- The administrator can manage database records.
- The application user can retrieve, insert,
  and update database information.
- The application user cannot delete records.
- The auditor can only view database information.
- The auditor cannot insert, update, or delete records.
- Unauthorized database operations are restricted.

## 9. CONCLUSION

The HabalGo Database Access Control Plan provides
a structured method of managing database access
through Role-Based Access Control (RBAC).

By creating separate administrator, application,
and auditor roles, the system ensures that database
permissions are assigned according to user
responsibilities.

The implementation of GRANT and REVOKE commands
helps prevent unauthorized database operations
and improves the security of the HabalGo database.

Overall, this access control implementation
promotes confidentiality, integrity, and proper
management of application data.
