# DATABASE ACCESS-CONTROL PLAN
## OJT RMA System
**Course:** COMP 018 – Database Administration  
**Activity:** Activity 4 – Database Users, Roles, Privileges, and Access Control  
**Database Platform:** PostgreSQL  
**Project Repository:** https://github.com/swvenz/Project-OJT-RMA-System.git

---

## 1. Introduction

This access-control plan defines the database users, group roles, responsibilities, and privileges for the OJT RMA System.

The purpose of this plan is to protect the database from unauthorized access, prevent unnecessary modifications, and ensure that each account receives only the permissions required to perform its assigned responsibilities.

The implementation follows the Principle of Least Privilege, which means that users should only receive the database permissions necessary for their tasks.

## 2. Database Access-Control Structure

The PostgreSQL database will use group roles and individual login accounts to organize database permissions.

| Group Role | Description |
|---|---|
| rma_admin_grp | Group for authorized database administration tasks. |
| rma_runtime_grp | Group for normal application database operations. |
| rma_readonly_grp | Group for users who only need to view database records. |
| rma_entry_grp | Group for users responsible for entering new records. |

## 3. Login Accounts and Responsibilities

| Login Account | Group Role | Application Role Served | Responsibility |
|---|---|---|---|
| rma_dba | rma_admin_grp | Database Administrator | Maintains the database, manages database roles, and performs authorized administrative tasks. |
| rma_app_user | rma_runtime_grp | Application Runtime | Connects the OJT RMA application to PostgreSQL and performs normal application operations. |
| rma_report_user | rma_readonly_grp | Read-Only User | Views RMA records and retrieves information for reporting and inspection. |
| rma_encoder | rma_entry_grp | Data Entry User | Enters new RMA records and views relevant existing information. |

*Note: These are proposed database accounts and roles for Activity 4. They must be checked against the actual application roles and operations before implementation.*

## 4. Required Database Privileges

| Group Role | SELECT | INSERT | UPDATE | DELETE | CREATE |
|---|---|---|---|---|---|
| rma_admin_grp | As needed | As needed | As needed | As needed | As needed for authorized administration |
| rma_runtime_grp | Yes | Yes | Yes | Yes, if required | No |
| rma_readonly_grp | Yes | No | No | No | No |
| rma_entry_grp | Yes | Yes | No | No | No |

The CREATE permission for database administration should be limited to the specific administrative tasks required. Ordinary application accounts must not receive database creation or role-management privileges.

## 5. Database Access Restrictions

The following restrictions will be implemented:

1. Read-only accounts cannot insert, update, or delete database records.
2. Data entry accounts cannot modify or delete existing records unless specifically authorized.
3. Application runtime accounts cannot create new databases or PostgreSQL roles.
4. Ordinary application accounts cannot access unrelated application databases.
5. Only authorized database administrators can perform administrative operations.
6. Database passwords must be kept confidential and must not be committed to GitHub.
7. Users must not receive PostgreSQL SUPERUSER privileges for ordinary application operations.

## 6. Schema, Table, and Sequence Permissions

The following privileges will be considered when configuring PostgreSQL:

| Database Object | Required Access |
|---|---|
| Database | CONNECT for authorized accounts. |
| Schema | USAGE for accounts that need to access application objects. |
| Tables | SELECT, INSERT, UPDATE, and DELETE according to assigned responsibilities. |
| Sequences | USAGE and SELECT where required by generated identifiers and application operations. |
| Views | SELECT for approved reporting and inspection accounts. |

Privileges will be granted only on the database objects required by each account.

## 7. Security Implementation

The access-control structure will be implemented using PostgreSQL commands such as:

- CREATE ROLE – Creates group roles and login accounts.
- GRANT – Assigns privileges and role memberships.
- REVOKE – Removes unnecessary