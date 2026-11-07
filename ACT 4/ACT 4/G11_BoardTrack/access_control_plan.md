# BOARDTRACK
# DATABASE ACCESS CONTROL PLAN

**Activity 4: Database Users, Roles, Privileges, and Access Control**

---

## 1. Project Information

| Description | Details |
|---|---|
| Project Name | BoardTrack |
| Activity | Activity 4 |
| Database Management System | PostgreSQL |
| Security Implementation | Role-Based Access Control (RBAC) |
| Repository | https://github.com/karlrobertc-art/BoardTrack |

## 2. Introduction

This Access Control Plan describes the implementation of Role-Based Access Control (RBAC) for the BoardTrack database using PostgreSQL.

The purpose of this plan is to establish secure database access by creating database users, assigning group roles, and providing appropriate privileges based on each user's responsibilities.

The implementation follows the Principle of Least Privilege, ensuring that each database user receives only the permissions necessary to perform their assigned tasks.

## 3. Objectives

The objectives of this access control implementation are:

1. Create database users and group roles for different responsibilities.
2. Assign appropriate permissions to each database role.
3. Control access to database tables and sequences.
4. Use GRANT commands to provide authorized privileges.
5. Use REVOKE commands to remove unnecessary privileges.
6. Prevent unauthorized database access and modifications.
7. Verify database permissions through PostgreSQL testing commands.

## 4. Database Users and Roles

The following database users and group roles are proposed for the BoardTrack system.

| Group Role | Database User | Description |
|---|---|---|
| boardtrack_admin_role | boardtrack_admin | Responsible for database administration and management. |
| boardtrack_app_role | boardtrack_app | Used by the application backend to perform database operations. |
| boardtrack_manager_role | boardtrack_manager | Responsible for managing and updating system records. |
| boardtrack_member_role | boardtrack_member | Allows members to view, insert, and update permitted records. |
| boardtrack_readonly_role | boardtrack_viewer | Provides read-only access to database records. |

## 5. Access Control Matrix

The following table describes the privileges assigned to each database role.

| Database Privilege | Admin | App | Manager | Member | Viewer |
|---|---|---|---|---|---|
| SELECT | YES | YES | YES | YES | YES |
| INSERT | YES | YES | YES | YES | NO |
| UPDATE | YES | YES | YES | YES | NO |
| DELETE | YES | YES | YES | NO | NO |
| TRUNCATE | YES | NO | NO | NO | NO |
| CREATE | YES | NO | NO | NO | NO |

### Role Descriptions

**1. Administrator Role**

The administrator has full privileges over the existing BoardTrack database tables and is responsible for database administration, maintenance, and security management.

**2. Application Role**

The application role is used by the BoardTrack backend application to perform SELECT, INSERT, UPDATE, and DELETE operations required by the system.

**3. Manager Role**

The manager role is responsible for managing system records. It can view, insert, update, and delete records but cannot truncate database tables.

**4. Member Role**

The member role has limited access to database records. It can view, insert, and update records but cannot delete or truncate them.

**5. Read-Only Role**

The read-only role is intended for users who only need to view database information. It cannot insert, update, or delete records.

## 6. Access Control Implementation

The BoardTrack database uses PostgreSQL commands to implement access control.

### A. CREATE ROLE

The CREATE ROLE command is used to create group roles and individual database login accounts.

Example:

    CREATE ROLE boardtrack_admin_role NOLOGIN;
    CREATE ROLE boardtrack_admin LOGIN;

### B. GRANT

The GRANT command assigns privileges to database roles.

Example:

    GRANT SELECT, INSERT, UPDATE
    ON ALL TABLES IN SCHEMA public
    TO boardtrack_member_role;

### C. REVOKE

The REVOKE command removes privileges that should not be available to specific users.

Example:

    REVOKE DELETE
    ON ALL TABLES IN SCHEMA public
    FROM boardtrack_member_role;

### D. ALTER DEFAULT PRIVILEGES

This command establishes default permissions for future database objects created by the configured object owner.

Example:

    ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT
    ON TABLES TO boardtrack_readonly_role;

## 7. Security Policies

The following security policies will be applied to the BoardTrack database:

**1. Principle of Least Privilege**

Each database user will receive only the permissions necessary for their responsibilities.

**2. Role Separation**

Administrative, application, management, member, and read-only responsibilities will be assigned to separate roles.

**3. Password Security**

All database login accounts must use strong and unique passwords.

**4. Restricted Database Operations**

Users will not be allowed to perform database operations outside their assigned privileges.

**5. Read-Only Restrictions**

The viewer account will only be permitted to retrieve database information.

**6. Database Protection**

Unauthorized deletion, modification, and administrative operations will be restricted.

**7. Access Verification**

Database permissions will be reviewed and tested to ensure that the assigned privileges work correctly.

## 8. Testing and Verification

The access control implementation will be tested using PostgreSQL privilege-checking functions and actual login accounts.

The following tests will be performed:

| Test Case | Expected Result |
|---|---|
| Administrator retrieves records | Allowed |
| Administrator inserts records | Allowed |
| Administrator updates records | Allowed |
| Administrator deletes records | Allowed |
| Manager updates records | Allowed |
| Member retrieves records | Allowed |
| Member inserts records | Allowed |
| Member updates records | Allowed |
| Member deletes records | Denied |
| Viewer retrieves records | Allowed |
| Viewer inserts records | Denied |
| Viewer updates records | Denied |
| Viewer deletes records | Denied |

Testing will confirm that database users can perform only the operations authorized by their assigned roles.

## 9. Monitoring and Maintenance

To maintain database security, the following activities should be performed regularly:

1. Review existing database users and group roles.
2. Check assigned privileges and role memberships.
3. Remove unnecessary permissions.
4. Update passwords when necessary.
5. Review access restrictions when system responsibilities change.
6. Verify that new database tables receive the appropriate privileges.

## 10. Conclusion

The BoardTrack Access Control Plan establishes a structured approach to database security through PostgreSQL Role-Based Access Control.

By implementing database users, group roles, GRANT and REVOKE commands, the system can restrict database operations according to user responsibilities.

The implementation follows the Principle of Least Privilege and helps maintain the confidentiality, integrity, and availability of BoardTrack database information.

This access control implementation provides a foundation for managing database permissions securely and efficiently.