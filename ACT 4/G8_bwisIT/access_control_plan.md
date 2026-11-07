
# ACCESS CONTROL PLAN
## Campus Canteen Pre-Order and Queue Management System

**Project Name:** Campus Canteen Pre-Order and Queue Management System  
**Database Name:** grp08_bwisITdb  
**Schema:** public  
**Database Management System:** PostgreSQL  
**Activity:** Activity 4 – Database Users, Roles, Privileges, and Access Control

---

## 1. PROJECT OVERVIEW

The Campus Canteen Pre-Order and Queue Management System is designed to manage food ordering, customer transactions, and queue operations within the campus canteen.

This Access Control Plan establishes a Role-Based Access Control (RBAC) system using PostgreSQL. It defines database users, group roles, privileges, and restrictions to ensure that only authorized users can access or modify specific database resources.

The implementation follows the Principle of Least Privilege, where each user receives only the permissions necessary to perform their assigned responsibilities.

---

## 2. OBJECTIVES

The objectives of this Access Control Plan are:

1. Protect sensitive database information from unauthorized access.
2. Establish separate database accounts for different responsibilities.
3. Assign appropriate permissions based on user roles.
4. Prevent unauthorized insertion, modification, and deletion of records.
5. Maintain database integrity and security.
6. Provide controlled access to application data.
7. Verify that database permissions work correctly through testing.

---

## 3. DATABASE INFORMATION

| Item | Description |
|---|---|
| Project | Campus Canteen Pre-Order and Queue Management System |
| Database | grp08_bwisITdb |
| Schema | public |
| DBMS | PostgreSQL |
| Security Model | Role-Based Access Control (RBAC) |

---

## 4. DATABASE USERS AND ROLES

The system implements four PostgreSQL group roles and four corresponding login accounts.

### 4.1 Group Roles

| Role Name | Description |
|---|---|
| canteen_admin_role | Responsible for database administration and management. |
| canteen_app_role | Handles general application database operations. |
| canteen_cashier_role | Handles order and payment transactions. |
| canteen_readonly_role | Provides read-only access to database records. |

### 4.2 Database Login Users

| Username | Assigned Group Role | Responsibility |
|---|---|---|
| canteen_admin | canteen_admin_role | Database administrator |
| canteen_app | canteen_app_role | Application operations |
| canteen_cashier | canteen_cashier_role | Cashier and transaction operations |
| canteen_viewer | canteen_readonly_role | Read-only database access |

### 4.3 Role Assignment

Each login user is assigned to a corresponding group role using PostgreSQL GRANT statements.

This approach simplifies permission management because privileges can be assigned to group roles instead of individually granting permissions to every database user.

---

## 5. ACCESS CONTROL POLICY

The following policies define how users can interact with the database.

### 5.1 Administrator Policy

The administrator is responsible for maintaining the database and managing its records.

Permissions:
- View database records.
- Insert new records.
- Update existing records.
- Delete records.
- Manage database table and sequence privileges.

### 5.2 Application Policy

The application account handles normal database operations required by the system.

Permissions:
- View database records.
- Insert new records.
- Update existing records.

Restrictions:
- Cannot delete records.
- Cannot truncate tables.
- Cannot create objects in the public schema.

### 5.3 Cashier Policy

The cashier account handles customer orders and payment-related operations.

Permissions:
- View database records.
- Insert transaction records.
- Update transaction records.

Restrictions:
- Cannot delete records.
- Cannot truncate tables.
- Cannot create objects in the public schema.

Note: Cashier access should be further limited to relevant order and payment tables after reviewing the actual database schema.

### 5.4 Read-Only Policy

The viewer account is intended for users who only need to inspect database information.

Permissions:
- View database records using SELECT.

Restrictions:
- Cannot insert records.
- Cannot update records.
- Cannot delete records.
- Cannot truncate tables.
- Cannot create objects in the public schema.

---

## 6. PERMISSION MATRIX

The following matrix summarizes the permissions assigned to each group role.

| Database Operation | Admin | Application | Cashier | Viewer |
|---|---|---|---|---|
| SELECT | YES | YES | YES | YES |
| INSERT | YES | YES | YES | NO |
| UPDATE | YES | YES | YES | NO |
| DELETE | YES | NO | NO | NO |
| TRUNCATE | YES | NO | NO | NO |
| CREATE | Administrative control | NO | NO | NO |

Note: Administrative control does not automatically mean PostgreSQL SUPERUSER access. The administrator role receives privileges according to the database configuration and ownership.

---

## 7. DATABASE PRIVILEGES IMPLEMENTATION

The following SQL scripts are used to implement the access control system.

### 7.1 Database Inspection

File: 00_inspect_database.sql

Purpose:
- Identify existing database schemas.
- Retrieve existing table names.
- Inspect table columns and data types.
- Identify database sequences.
- Review existing PostgreSQL roles.

### 7.2 Create Database Roles and Users

File: 01_create_roles.sql

Purpose:
- Create four PostgreSQL group roles.
- Create four login accounts.
- Assign each login account to its corresponding group role.

### 7.3 Grant Database Privileges

File: 02_grant_privileges.sql

Purpose:
- Grant CONNECT privileges.
- Grant USAGE privileges on the public schema.
- Grant administrative privileges.
- Grant application privileges.
- Grant cashier privileges.
- Grant read-only privileges.

### 7.4 Revoke Unnecessary Privileges

File: 03_revoke_privileges.sql

Purpose:
- Prevent viewers from modifying database records.
- Prevent application users from deleting records.
- Restrict cashier operations.
- Prevent unauthorized schema object creation.

### 7.5 Test Database Privileges

File: 04_test_privileges.sql

Purpose:
- Identify the currently connected database user.
- Verify assigned table privileges.
- Verify sequence privileges.
- Check whether permissions were properly applied.

---

## 8. SECURITY MEASURES

The following security measures will be applied:

1. Every database login account must have an assigned role.
2. Ordinary users must not receive SUPERUSER privileges.
3. Ordinary users must not receive CREATEDB privileges.
4. Ordinary users must not receive CREATEROLE privileges.
5. Read-only users must only have SELECT permissions.
6. Application users must not have unnecessary deletion privileges.
7. Cashier accounts must only receive permissions necessary for transaction operations.
8. Database passwords must be kept confidential.
9. Database credentials must not be committed to public GitHub repositories.
10. Permissions must be reviewed regularly.

---

## 9. TESTING AND VERIFICATION

To verify the implementation, each database account will be tested independently.

### 9.1 Administrator Testing

Expected Results:
- SELECT operations: ALLOWED
- INSERT operations: ALLOWED
- UPDATE operations: ALLOWED
- DELETE operations: ALLOWED

### 9.2 Application Testing

Expected Results:
- SELECT operations: ALLOWED
- INSERT operations: ALLOWED
- UPDATE operations: ALLOWED
- DELETE operations: DENIED

### 9.3 Cashier Testing

Expected Results:
- SELECT operations: ALLOWED
- INSERT operations: ALLOWED
- UPDATE operations: ALLOWED
- DELETE operations: DENIED

### 9.4 Viewer Testing

Expected Results:
- SELECT operations: ALLOWED
- INSERT operations: DENIED
- UPDATE operations: DENIED
- DELETE operations: DENIED

Testing must be performed using separate database login accounts to verify that the assigned privileges are functioning correctly.

Screenshots of successful and denied database operations will be collected as implementation evidence.

---

## 10. EXPECTED SECURITY RESULTS

After implementing the RBAC system, the following results are expected:

- Database access is controlled through assigned group roles.
- Users can only perform authorized database operations.
- Unauthorized modifications are prevented.
- Database records are protected from unnecessary deletion.
- Privilege management becomes easier through group roles.
- Database security and integrity are improved.

---

## 11. CONCLUSION

The Access Control Plan for the Campus Canteen Pre-Order and Queue Management System establishes a structured database security mechanism using PostgreSQL Role-Based Access Control.

By creating separate database users and group roles, assigning appropriate privileges, and revoking unnecessary permissions, the system ensures that database access is controlled according to user responsibilities.

The implementation promotes database security, accountability, and integrity while reducing the risk of unauthorized access and modification of important canteen records.

---

## 12. IMPLEMENTATION FILES

The following files are included in the Activity 4 implementation:

database/activity4/
- 00_inspect_database.sql
- 01_create_roles.sql
- 02_grant_privileges.sql
- 03_revoke_privileges.sql
- 04_test_privileges.sql
- access_control_plan.md
- screenshots/

**End of Access Control Plan**
