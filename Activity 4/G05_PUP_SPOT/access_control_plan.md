# ACCESS CONTROL PLAN
## Lost and Found Management System
### Activity 4 – Database Users, Roles, Privileges, and Access Control

---

## 1. Introduction

The Lost and Found Management System uses Role-Based Access Control (RBAC) to manage database access and protect important information stored in the PostgreSQL database.

This access control plan defines the different database users, their assigned roles, and the permissions they are allowed to perform.

The implementation follows the Principle of Least Privilege, which ensures that each database user receives only the permissions necessary to perform their assigned responsibilities.

## 2. Objectives

The objectives of this access control plan are:

- To control access to the Lost and Found database.
- To create different database users and roles.
- To assign appropriate permissions to each role.
- To prevent unauthorized database operations.
- To protect important records from unauthorized modification or deletion.
- To verify that database permissions are correctly implemented.

## 3. Access Control Model

The system implements Role-Based Access Control (RBAC).

Under this model, permissions are assigned to database roles instead of directly assigning individual privileges to every user.

The database users inherit their permissions through their assigned roles.

The following roles are implemented:

| Role | Description |
|---|---|
| lf_admin | Database administrator with full table privileges. |
| lf_staff | Staff member who can view, insert, and update records. |
| lf_viewer | User who can only view database records. |

## 4. Database Users and Role Assignments

The following database accounts are created:

| Database User | Assigned Role | Responsibility |
|---|---|---|
| lf_admin_user | lf_admin | Manages database operations and administration. |
| lf_staff_user | lf_staff | Handles lost and found records. |
| lf_viewer_user | lf_viewer | Views available database information. |

Each database user receives permissions through role membership.

## 5. Access Privilege Matrix

The following table defines the privileges assigned to each database role.

| Database Operation | Admin | Staff | Viewer |
|---|---|---|---|
| SELECT | ALLOWED | ALLOWED | ALLOWED |
| INSERT | ALLOWED | ALLOWED | DENIED |
| UPDATE | ALLOWED | ALLOWED | DENIED |
| DELETE | ALLOWED | DENIED | DENIED |

### Explanation of Permissions

**Administrator (lf_admin)**

- Can view database records.
- Can insert new records.
- Can update existing records.
- Can delete records.
- Has full privileges on existing tables and sequences in the public schema.

**Staff (lf_staff)**

- Can view lost and found records.
- Can insert new records.
- Can update existing records.
- Cannot delete records.

**Viewer (lf_viewer)**

- Can view database records.
- Cannot insert new records.
- Cannot update existing records.
- Cannot delete records.

## 6. Privilege Assignment

The GRANT command in PostgreSQL is used to assign database permissions to the roles.

The following permissions are implemented:

- Administrator receives ALL PRIVILEGES on existing tables and sequences in the public schema.
- Staff receives SELECT, INSERT, and UPDATE privileges on existing tables in the public schema.
- Viewer receives SELECT privileges on existing tables in the public schema.

The schema USAGE privilege is also granted to all three roles so they can access objects within the public schema.

## 7. Privilege Revocation

The REVOKE command is used to remove permissions that are not appropriate for specific roles.

The following restrictions are implemented:

- DELETE privilege is revoked from staff.
- INSERT, UPDATE, and DELETE privileges are revoked from viewers.
- SELECT access is retained for viewers.
- Staff retains SELECT, INSERT, and UPDATE privileges.

These restrictions help prevent unauthorized modifications and deletion of database records.

## 8. Security Policies

The following security policies are applied:

### 8.1 Principle of Least Privilege

Every database user receives only the permissions required for their responsibilities.

### 8.2 Role-Based Access Control

Database permissions are managed through predefined roles rather than assigning permissions individually to every user.

### 8.3 Separation of Responsibilities

Administrator, staff, and viewer accounts have different access levels to reduce unauthorized database operations.

### 8.4 Password Protection

Each database login account must use a secure password. Passwords should not be shared or stored in publicly accessible files.

### 8.5 Unauthorized Access Prevention

Users are prevented from performing database operations that are not included in their assigned permissions.

## 9. Testing and Verification

The access control implementation is verified using PostgreSQL privilege-checking commands and separate database login accounts.

The following tests are performed:

1. Verify that the database roles and users exist.
2. Check the privileges assigned to each role.
3. Verify that the administrator can perform all required table operations.
4. Verify that staff can SELECT, INSERT, and UPDATE records but cannot DELETE records.
5. Verify that viewers can only SELECT records.
6. Confirm that unauthorized operations are denied by PostgreSQL.

The results are recorded through SQL query outputs and screenshots.

## 10. Expected Security Results

The expected results of the access control implementation are:

| User | Expected Access |
|---|---|
| lf_admin_user | Full table access |
| lf_staff_user | Read, insert, and update access |
| lf_viewer_user | Read-only access |

The implementation is considered successful when each database account can perform its authorized operations and is prevented from performing unauthorized operations.

## 11. Conclusion

The Access Control Plan establishes a structured approach to protecting the Lost and Found Management System database through PostgreSQL Role-Based Access Control.

By implementing administrator, staff, and viewer roles, the system provides different levels of database access based on user responsibilities.

The use of GRANT and REVOKE commands ensures that permissions are properly assigned and restricted.

Overall, this implementation improves database security, prevents unauthorized operations, and follows the Principle of Least Privilege.