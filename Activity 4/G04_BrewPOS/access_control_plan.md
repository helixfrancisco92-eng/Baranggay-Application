BREWPOS – DATABASE ACCESS CONTROL PLAN
COMP 018 – Database Administration | Activity 4
1. Project Information
Information	Details
Project Name	BrewPOS
Repository	Nycri/brewpos
Database Platform	PostgreSQL
Database Name	brewpos_db (proposed)
Security Model	Role-Based Access Control (RBAC)
Access Principle	Least Privilege

2. Objective
The purpose of this access control plan is to secure the BrewPOS database by implementing Role-Based Access Control (RBAC) using PostgreSQL.

This plan defines the database login accounts, group roles, responsibilities, and privileges required by different users of the BrewPOS application.

The implementation follows the principle of least privilege, ensuring that each database account receives only the permissions necessary to perform its assigned tasks.
3. Database User and Group Role Plan
The following table identifies the proposed PostgreSQL login accounts and their corresponding group roles.
Login Account	Group Role	Application Role
brewpos_admin	brewpos_admin_grp	Administrator
brewpos_app	brewpos_runtime_grp	Application System
brewpos_cashier	brewpos_cashier_grp	Cashier
brewpos_auditor	brewpos_readonly_grp	Auditor

4. Role Responsibilities and Privileges
Group Role	Responsibilities	Required Privileges
brewpos_admin_grp	Manage database configuration, users, and database security	Administrative privileges appropriate to assigned tasks
brewpos_runtime_grp	Allow the application to perform normal database operations	SELECT, INSERT, UPDATE, DELETE
brewpos_cashier_grp	Process sales transactions and view relevant records	SELECT, INSERT on approved tables
brewpos_readonly_grp	View database records for monitoring and auditing	SELECT on approved tables or views

5. Access Control Matrix
The following matrix describes the proposed database permissions.
Database Operation	Admin	Runtime	Cashier	Auditor
SELECT	✓	✓	✓	✓
INSERT	✓	✓	✓	✗
UPDATE	✓	✓	✗	✗
DELETE	✓	✓	✗	✗
CREATE	As needed	✗	✗	✗
DROP	As needed	✗	✗	✗

Note: These are proposed permissions. Cashier access should be limited to approved sales-related tables. Admin privileges should be granted separately according to actual administrative requirements.
6. PostgreSQL Role Implementation
The following SQL commands will be used to implement the access-control structure.

A. Create Group Roles
CREATE ROLE brewpos_admin_grp NOLOGIN;
CREATE ROLE brewpos_runtime_grp NOLOGIN;
CREATE ROLE brewpos_cashier_grp NOLOGIN;
CREATE ROLE brewpos_readonly_grp NOLOGIN;


B. Create Login Accounts
CREATE ROLE brewpos_admin LOGIN PASSWORD 'CHANGE_ME';
CREATE ROLE brewpos_app LOGIN PASSWORD 'CHANGE_ME';
CREATE ROLE brewpos_cashier LOGIN PASSWORD 'CHANGE_ME';
CREATE ROLE brewpos_auditor LOGIN PASSWORD 'CHANGE_ME';


C. Assign Group Memberships
GRANT brewpos_admin_grp TO brewpos_admin;
GRANT brewpos_runtime_grp TO brewpos_app;
GRANT brewpos_cashier_grp TO brewpos_cashier;
GRANT brewpos_readonly_grp TO brewpos_auditor;


7. Security Restrictions
To prevent unauthorized database operations, the following restrictions will be implemented:
1. Cashiers are not allowed to delete database records.
2. Auditors are only allowed to view approved records.
3. Auditors cannot insert, update, or delete records.
4. Application runtime accounts cannot create or drop database objects.
5. Administrative privileges are reserved for authorized administrators.
6. Database passwords must not be exposed in public repositories.
7. Each account must only receive the privileges necessary for its responsibilities.
8. Privilege Verification Plan
The following tests will verify whether the assigned privileges work correctly.
Test Case	Expected Result
Runtime account performs SELECT	PASS – Allowed
Runtime account performs INSERT	PASS – Allowed
Cashier performs INSERT on approved sales table	PASS – Allowed
Cashier performs DELETE	PASS – Denied
Auditor performs SELECT	PASS – Allowed
Auditor performs UPDATE	PASS – Denied
Auditor performs DELETE	PASS – Denied

The tests will be performed using separate PostgreSQL login accounts to confirm that the database correctly enforces the assigned permissions.
9. Conclusion
The proposed BrewPOS database access-control plan establishes a structured security system using PostgreSQL Role-Based Access Control.

By separating login accounts from group roles and assigning permissions according to responsibilities, the database can prevent unauthorized operations and protect important business records.

The implementation will be verified through SQL privilege checks and actual database operations to ensure that permitted actions succeed and restricted actions are denied.

10. Recommended folder structure
Save the access control plan in your repository:
Activity-4/
│
├── sql/
│   ├── 01_create_roles.sql
│   ├── 02_grant_privileges.sql
│   ├── 03_revoke_privileges.sql
│   └── 04_test_privileges.sql
│
├── documentation/
│   └── access_control_plan.md
│
├── screenshots/
│
└── README.md