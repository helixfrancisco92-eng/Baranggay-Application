
# ACCESS CONTROL PLAN
## Restaurant Online Ordering and Table Reservation System

---

## 1. PROJECT INFORMATION

**Project Name:** Restaurant Online Ordering and Table Reservation System

**Database Management System:** PostgreSQL

**Access Control Model:** Role-Based Access Control (RBAC)

**Repository:** https://github.com/kathlenmaecallos11-arch/Restaurant-Online-Ordering-Table-Reservation-System

**Activity:** Activity 4 – Database Users, Roles, Privileges, and Access Control

---

## 2. PURPOSE OF ACCESS CONTROL

The purpose of this Access Control Plan is to establish
a secure and organized database permission system for
the Restaurant Online Ordering and Table Reservation
System.

This plan ensures that each database user has access
only to the information and operations necessary for
their assigned responsibilities.

The system implements Role-Based Access Control (RBAC)
using PostgreSQL to manage database users, roles, and
privileges.

---

## 3. ACCESS CONTROL MODEL

The system uses Role-Based Access Control (RBAC).

Under this model, permissions are assigned to roles
rather than directly assigning individual permissions
to every user.

Each user receives a role based on their responsibilities
within the restaurant system.

This approach simplifies permission management and
reduces the possibility of unauthorized database access.

---

## 4. DATABASE ROLES AND RESPONSIBILITIES

### 4.1 Restaurant Administrator

**Role Name:** restaurant_admin

**Responsibilities:**
- Manage the restaurant database.
- Access all database tables.
- Create, update, and delete database records.
- Manage database users and permissions.
- Monitor database operations.

**Access Level:** Full database access.

### 4.2 Restaurant Manager

**Role Name:** restaurant_manager

**Responsibilities:**
- View restaurant records.
- Monitor customer orders.
- Monitor table reservations.
- Access relevant restaurant information.
- Manage restaurant operations according to assigned permissions.

**Access Level:** Limited management access.

### 4.3 Restaurant Staff

**Role Name:** restaurant_staff

**Responsibilities:**
- View customer orders.
- Handle restaurant reservations.
- Access information needed for daily operations.
- Process assigned restaurant transactions.

**Access Level:** Limited operational access.

### 4.4 Restaurant Customer

**Role Name:** restaurant_customer

**Responsibilities:**
- Access customer-related information.
- View permitted restaurant records.
- Use customer-facing system features.

**Access Level:** Restricted customer access.

### 4.5 Read-Only User

**Role Name:** restaurant_readonly

**Responsibilities:**
- View permitted database records.
- Access information for monitoring and reporting.
- Review records without modifying them.

**Access Level:** Read-only access.

---

## 5. DATABASE USER ACCOUNTS

The following database accounts are created and
assigned to their corresponding roles.

| Username | Assigned Role |
|---|---|
| admin_user | restaurant_admin |
| manager_user | restaurant_manager |
| staff_user | restaurant_staff |
| customer_user | restaurant_customer |
| viewer_user | restaurant_readonly |

Each database user is assigned a specific role to
ensure that database operations follow the principle
of least privilege.

---

## 6. ACCESS CONTROL MATRIX

The following matrix describes the intended permissions
for each database role.

| Database Operation | Admin | Manager | Staff | Customer | Read-Only |
|---|---|---|---|---|---|
| SELECT | YES | YES | YES | YES* | YES |
| INSERT | YES | As assigned | As assigned | NO* | NO |
| UPDATE | YES | As assigned | As assigned | NO* | NO |
| DELETE | YES | As assigned | NO | NO | NO |
| TRUNCATE | YES | NO | NO | NO | NO |
| Database Management | YES | NO | NO | NO | NO |

*Customer access must be restricted to appropriate
customer-related records and operations. Direct database
access is not recommended for ordinary application users.

The actual privileges must match the PostgreSQL GRANT
and REVOKE statements implemented in the SQL scripts.

---

## 7. ACCESS CONTROL POLICIES

The following policies must be followed:

1. Every database user must have an assigned role.
2. Users must only access information required for
   their responsibilities.
3. Administrators are responsible for managing database
   permissions.
4. Managers receive only the privileges necessary for
   restaurant management.
5. Staff members must not perform unauthorized deletion
   of database records.
6. Customer accounts must not have unrestricted access
   to database tables.
7. Read-only users must not modify or delete records.
8. Unnecessary privileges must be revoked.
9. Database passwords must be protected.
10. User permissions must be reviewed regularly.

---

## 8. IMPLEMENTATION IN POSTGRESQL

The access control system is implemented through
PostgreSQL SQL commands.

The following SQL files are used:

### 8.1 00_inspect_database.sql

Identifies the database structure, including existing
tables, columns, schemas, and sequences.

### 8.2 01_create_roles.sql

Creates the database roles and login users.

It also assigns each user to the appropriate role.

### 8.3 02_grant_privileges.sql

Assigns database permissions to the created roles
using PostgreSQL GRANT statements.

### 8.4 03_revoke_privileges.sql

Removes unnecessary permissions using PostgreSQL
REVOKE statements.

### 8.5 04_test_privileges.sql

Checks whether the assigned database permissions
are working correctly.

---

## 9. SECURITY MEASURES

To maintain database security, the following measures
are implemented:

- Role-Based Access Control (RBAC).
- Principle of Least Privilege.
- Individual database login accounts.
- Password protection.
- Restricted database operations.
- Regular privilege verification.
- Revocation of unnecessary permissions.
- Monitoring of database access.

These measures help prevent unauthorized access,
accidental data modification, and improper database
operations.

---

## 10. TESTING AND VERIFICATION

The database access control implementation is tested
to verify that each role can only perform its permitted
operations.

The following tests are performed:

| Test Case | Expected Result |
|---|---|
| Administrator views records | Successful |
| Administrator modifies records | Successful |
| Staff views permitted records | Successful |
| Staff attempts unauthorized DELETE | Denied |
| Customer attempts unauthorized INSERT | Denied |
| Read-only user views records | Successful |
| Read-only user attempts UPDATE | Denied |

Testing is performed using PostgreSQL privilege-checking
functions and actual database operations.

Screenshots of successful and denied operations are
collected as evidence.

---

## 11. MAINTENANCE AND REVIEW

Database administrators are responsible for maintaining
the access control system.

The following activities should be performed regularly:

- Review existing database users.
- Check role memberships.
- Review granted privileges.
- Revoke unnecessary access.
- Update account passwords.
- Verify database security configurations.
- Test access permissions after database changes.

---

## 12. CONCLUSION

The Access Control Plan establishes a structured
security framework for the Restaurant Online Ordering
and Table Reservation System.

By implementing Role-Based Access Control in PostgreSQL,
the system can manage database users, assign appropriate
permissions, and restrict unauthorized operations.

The implementation of database roles, GRANT and REVOKE
statements, and privilege testing helps maintain the
confidentiality, integrity, and security of restaurant
database records.
