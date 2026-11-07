# Application User Roles & Database Role Mapping
**COMP 018 – Database Administration | Activity 3 Specification**

This document establishes the user roles within the **iBarangay** application and specifies their mapping to PostgreSQL database roles and privileges (as required for Activity 3 and in preparation for Activity 4).

---

## 👥 1. Application User Roles vs. Database Roles

In modern web applications, individual citizens and staff members interact through the application interface, while the application itself connects to PostgreSQL via designated runtime database roles with strictly bounded privileges.

| Application Role | Responsibilities in the Application | Functions and Data Access | Intended Database Role (PostgreSQL) | Intended Privileges |
|---|---|---|---|---|
| **Barangay Administrator (Captain / Chairman)** | Full oversight of barangay records, system configurations, and staff assignments. | • Create, read, update, and delete on all tables.<br>• Manage system settings and view audit history.<br>• Full access to `admins`, `citizens`, `document_requests`, and `request_status_history`. | `app_admin_grp` | `SELECT, INSERT, UPDATE, DELETE` on all application tables. |
| **Barangay Staff / Data Encoder** | Front-desk operations: receiving walk-in residents, encoding document requests, updating request statuses. | • Register new citizens (`citizens`).<br>• Create and update document requests (`document_requests`).<br>• Insert status audit logs (`request_status_history`).<br>• Read-only on `document_types` and `requirements`. | `app_staff_grp` | `SELECT` on all tables;<br>`INSERT, UPDATE` on `citizens`, `document_requests`, and `request_status_history`. |
| **Auditor / Council Member (Viewer)** | Internal review of community records, verification of fee collections, and request turnaround time analysis. | • Read-only access to citizens, document requests, and audit history logs.<br>• No modification or deletion privileges. | `app_readonly_grp` | `SELECT` only on all tables and views. |
| **Citizen / Resident (Applicant)** | Public portal user: filing document applications and tracking real-time status. | • Create document requests (`document_requests`).<br>• Register personal details (`citizens`).<br>• Read document types and requirements.<br>• View own request status. | `app_runtime_grp` | Application-level restricted data access mediated by Spring Boot backend. |
| **Application Runtime (System Service Account)** | The technical service account used by Spring Boot / HikariCP to communicate with PostgreSQL. | • Connection pool execution of all operational SQL queries dictated by the services. | `app_runtime_grp` | Connection login with `USAGE` on schema `public` and required CRUD on application tables. |

---

## 🔒 2. PostgreSQL Role Definition Scripts (For Activity 4)

Below are the intended DDL statements for creating the group roles and accounts in PostgreSQL:

```sql
-- 1. Create Group Roles
CREATE ROLE app_admin_grp NOLOGIN;
CREATE ROLE app_staff_grp NOLOGIN;
CREATE ROLE app_readonly_grp NOLOGIN;
CREATE ROLE app_runtime_grp NOLOGIN;

-- 2. Assign Table Privileges to Groups
-- Read-Only Group
GRANT USAGE ON SCHEMA public TO app_readonly_grp;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly_grp;

-- Staff Group
GRANT USAGE ON SCHEMA public TO app_staff_grp;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_staff_grp;
GRANT INSERT, UPDATE ON public.citizens, public.document_requests, public.request_status_history TO app_staff_grp;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_staff_grp;

-- Administrator Group
GRANT USAGE ON SCHEMA public TO app_admin_grp;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_admin_grp;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_admin_grp;

-- Runtime Application Group
GRANT USAGE ON SCHEMA public TO app_runtime_grp;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_runtime_grp;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO app_runtime_grp;

-- 3. Create Specific Database Login Users
CREATE USER ibarangay_app WITH PASSWORD 'AppSecurePassword123!';
GRANT app_runtime_grp TO ibarangay_app;

CREATE USER auditor_user WITH PASSWORD 'AuditSecret2026!';
GRANT app_readonly_grp TO auditor_user;
```
