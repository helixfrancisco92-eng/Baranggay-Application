# CAMPUSAFE Repository Inventory & Architectural Inspection Report

**Auditing Group:** Group 12 — iBarangay  
**Target Repository:** `https://github.com/jeffersonorpesa2-ops/grp07-campussafe`  
**Target Project:** Group 7 — CampusSafe: Campus Hazard and Safety Reporting System  
**Inspection Date:** November 7, 2026  
**Assessment Phase:** Phase A — Peer Repository Inspection  

---

## 1. Executive System Profile

CampusSafe is a web-based incident reporting and physical safety management application developed for collegiate campuses. The application enables students, faculty, staff, and visitors to submit real-time reports of campus hazards (e.g., exposed electrical wiring, structural damage, water leaks, sanitation hazards), which are subsequently verified by campus safety administrators, dispatched to facility maintenance personnel, tracked through lifecycle states, and archived for safety compliance.

| Architectural Dimension | CAMPUSAFE Production Specification |
|---|---|
| **Application Framework** | Native PHP 8.2+ (MVC architecture, custom router, PDO database abstraction) |
| **Web Server / Runtime** | Apache 2.4 / PHP CLI built-in web server |
| **Database Management System** | PostgreSQL 14+ (production evaluated on PostgreSQL 18.6 x86_64) |
| **Database Name** | `grp07_campussafedb` |
| **Database Schema** | `public` |
| **Data Access Layer** | PHP Data Objects (PDO) with prepared statements (`PDO::ATTR_EMULATE_PREPARES => false`) |
| **Access Control Paradigm** | Role-Based Access Control (RBAC) utilizing PostgreSQL group roles (`NOLOGIN`) and dedicated login accounts |

---

## 2. Comprehensive Repository File Inventory

The following table catalogs every significant file in Group 7's repository, mapping its operational purpose to the corresponding COMP 018 assessment activity and extracting critical database parameters.

| File Path in `grp07-campussafe` | File Name | Assessment Activity Supported | Functional Description & Extracted Database Parameters | Status & Integrity Notes |
|---|---|:---:|---|---|
| `/` | `README.md` | Activity 3 / General | High-level system documentation, prerequisite list (PHP 8.2+, PostgreSQL 14+), and deployment overview. | Fully documented; links to installation instructions. |
| `/` | `HOW_IT_WORKS.md` | Activity 3 / General | Detailed workflow walkthrough of hazard reporting, administrative triage, technician dispatch, and resolution lifecycles. | Comprehensive; outlines business logic states. |
| `/` | `.env.example` | Activity 3 & 4 | Environment template defining database connection variables: `DB_HOST=localhost`, `DB_PORT=5432`, `DB_NAME=grp07_campussafedb`, `DB_USER=campussafe_app`. | Free of hardcoded production credentials. |
| `/` | `setup.bat` | Activity 3 | Windows batch script automating PHP discovery and launching `bin/setup.php`. | Operational 1-click deployment utility. |
| `/` | `start.bat` | Activity 3 | Windows batch script starting PHP built-in web server on `localhost:8000`. | Operational local launcher. |
| `bin/` | `setup.php` | Activity 3 | CLI setup wizard creating database, executing schema DDL, seeding initial records, and provisioning roles. | Automated bootstrap utility. |
| `database/` | `01_schema.sql` | Activity 3 | Primary DDL definition script creating 9 relational tables, 10 B-tree indexes, primary keys, and foreign keys. | Contains all core tables; uses `ON DELETE CASCADE` on 4 child relations. |
| `database/` | `02_seed.sql` | Activity 3 | SQL data seed script inserting default hazard categories, physical campus locations, demo users, sample reports, and assignments. | Provides realistic test baseline. |
| `database/` | `03_roles_and_privileges.sql` | Activity 4 | PostgreSQL RBAC script creating 3 group roles (`app_runtime_grp`, `app_readonly_grp`, `app_backup_grp`) and 3 login accounts (`campussafe_app`, `campussafe_report`, `campussafe_backup`). | Contains table-wide `UPDATE` grant on `app_user` (Flaw G07-F1). |
| `database/` | `99_reset.sql` | Activity 3 | Database teardown script dropping all 9 tables in reverse dependency order and resetting sequences. | Idempotent cleanup utility. |
| `database/` | `verify.sql` | Activity 3 & 4 | Validation script checking object counts, constraint catalogs (`pg_constraint`), and user permissions. | Used for post-installation sanity testing. |
| `database/` | `seed_users.php` | Activity 3 & 4 | PHP script generating bcrypt password hashes (`PASSWORD_BCRYPT`) for seeded administrative, reporter, and technician accounts. | Ensures passwords are not stored in plaintext. |
| `docs/` | `user-roles.md` | Activity 4 | Specification of system user personas (Reporter, Administrator, Maintenance, Auditor) and their database permission mappings. | Core baseline reference for Activity 4 access control. |
| `src/config/` | `Database.php` | Activity 3 & 4 | Singleton PDO database connection wrapper enforcing prepared statements, UTF-8 client encoding, and strict exception error modes. | Reads credentials strictly from `.env`. |
| `src/config/` | `Env.php` | Activity 3 | Lightweight `.env` parser loading environment variables into `$_ENV` and `getenv()`. | Operational utility. |
| `src/models/` | `User.php` | Activity 3 & 4 | Data model handling user authentication, session state, and password verification. | Interacts directly with `app_user`. |
| `src/models/` | `Report.php` | Activity 3 | Data model handling hazard report creation, status transitions, priority updates, and filtering. | Core operational entity. |
| `src/models/` | `Location.php` | Activity 3 | Master lookup model for campus buildings, floors, and room areas. | Interacts with `campus_location`. |
| `src/models/` | `Category.php` | Activity 3 | Master lookup model for hazard classifications. | Interacts with `hazard_category`. |
| `src/models/` | `Assignment.php` | Activity 3 | Dispatch model managing technician assignments to verified hazard reports. | Foreign key child of `hazard_report`. |
| `src/models/` | `MaintenanceAction.php`| Activity 3 | Work order model recording technician physical repairs, resolution notes, and repair timestamps. | Foreign key child of `hazard_report`. |
| `src/models/` | `Attachment.php` | Activity 3 | Metadata model managing photo evidence uploaded by reporters and maintenance staff. | Foreign key child of `hazard_report`. |
| `public/` | `index.php` | Activity 3 | Application entry point and router dispatching HTTP requests to controllers. | Standard PHP MVC pattern. |
| `public/` | `install.php` | Activity 3 | Browser-based interactive setup wizard performing database connectivity checks and table migrations. | User-friendly web installer. |
| `public/` | `login.php` / `logout.php` | Activity 3 & 4 | User authentication handlers enforcing credential verification and session destruction. | Application-level RBAC enforcement. |
| `public/admin/` | `*.php` (7 files) | Activity 3 & 4 | Administrative views for reviewing reports, assigning priorities, dispatching maintenance, and managing master lookups. | Restricted to admin role. |
| `public/maintenance/` | `*.php` (3 files) | Activity 3 & 4 | Technician views for viewing assigned work orders, logging maintenance actions, and marking reports resolved. | Restricted to maintenance role. |
| `public/reports/` | `*.php` (4 files) | Activity 3 | Public/reporter views for lodging new hazard reports, uploading photos, and tracking status progress. | Accessible to all active users. |
| `progress-report/` | `ACTIVITY_03_PROGRESS_REPORT.md` | Activity 3 | Group 7's Activity 3 submission documenting database schema, normalization, table structures, and entity-relationship models. | Authoritative baseline for schema design. |
| `progress-report/` | `ACTIVITY_04_ACCESS_CONTROL_REPORT.md`| Activity 4 | Group 7's Activity 4 submission documenting role architecture, privilege grants, and denial tests. | Authoritative baseline for access control. |
| `progress-report/` | `ACTIVITY_05_MAINTENANCE_MONITORING_REPORT.md`| Activity 5 | Group 7's Activity 5 submission documenting database metrics, bloat inspection, VACUUM/ANALYZE, and query profiling. | Authoritative baseline for maintenance. |
| `progress-report/` | `ACTIVITY_06_BACKUP_RECOVERY_REPORT.md` | Activity 6 | Group 7's Activity 6 submission documenting logical backup routines (`pg_dump -Fc`), restore drills, and recovery verification. | Authoritative baseline for recoverability. |

---

## 3. Database Schema, Tables, and Relational Architecture

Inspection of `database/01_schema.sql` confirms that `grp07_campussafedb` is structured into **9 relational tables**:

```
                       ┌──────────────┐
                       │     role     │
                       └──────┬───────┘
                              │ 1:N
                              ▼
                       ┌──────────────┐
                       │   app_user   │
                       └──────┬───────┘
                              │ 1:N (reporter, verifier)
                              ▼
┌──────────────────┐   ┌──────────────┐   ┌─────────────────┐
│ hazard_category  │──►│hazard_report │◄──│ campus_location │
└──────────────────┘   └──────┬───────┘   └─────────────────┘
                              │ 1:N (Cascading FKs)
          ┌───────────────────┼───────────────────┬───────────────────┐
          ▼                   ▼                   ▼                   ▼
┌──────────────────┐ ┌──────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│    assignment    │ │report_status_hist│ │maintenance_actn │ │   attachment    │
└──────────────────┘ └──────────────────┘ └─────────────────┘ └─────────────────┘
```

### Table Definitions & Key Properties

1. **`role` (Master Lookup):**
   - Columns: `role_id` (PK, SERIAL), `role_name` (VARCHAR(50), UNIQUE), `description` (TEXT).
   - Seeded Roles: Administrator, Safety Officer, Maintenance Staff, Campus Reporter.
2. **`app_user` (Authentication & Profile Catalog):**
   - Columns: `user_id` (PK, SERIAL), `role_id` (FK to `role`), `full_name` (VARCHAR(150)), `email` (VARCHAR(255), UNIQUE), `username` (VARCHAR(100), UNIQUE), `password_hash` (TEXT), `account_status` (VARCHAR(20), CHECK `IN ('active', 'inactive', 'suspended')`), `created_at` (TIMESTAMP).
3. **`hazard_category` (Master Lookup):**
   - Columns: `category_id` (PK, SERIAL), `category_name` (VARCHAR(80), UNIQUE), `description` (TEXT), `is_active` (BOOLEAN).
4. **`campus_location` (Master Lookup):**
   - Columns: `location_id` (PK, SERIAL), `building` (VARCHAR(120)), `floor` (VARCHAR(30)), `room_area` (VARCHAR(120)), `location_description` (TEXT), `is_active` (BOOLEAN).
   - *Observation:* Lacks composite candidate key uniqueness on `(building, floor, room_area)`.
5. **`hazard_report` (Core Transaction Entity):**
   - Columns: `report_id` (PK, SERIAL), `reporter_user_id` (FK to `app_user`), `location_id` (FK to `campus_location`), `category_id` (FK to `hazard_category`), `description` (TEXT), `priority` (VARCHAR(20), CHECK `IN ('Low', 'Medium', 'High', 'Critical')`, NULL allowed), `status` (VARCHAR(30), DEFAULT `'Submitted'`, CHECK `IN ('Submitted', 'Verified', 'Assigned', 'In Progress', 'Resolved', 'Closed')`), `submitted_at` (TIMESTAMP), `verified_by_user_id` (FK to `app_user`, NULL allowed), `verified_at` (TIMESTAMP), `resolved_at` (TIMESTAMP).
   - Constraints: `chk_verified_pair` enforces that `verified_by_user_id` and `verified_at` are either both NULL or both NOT NULL. `chk_resolved_has_date` enforces `resolved_at IS NOT NULL` when status is Resolved or Closed.
6. **`assignment` (Dispatch Association):**
   - Columns: `assignment_id` (PK, SERIAL), `report_id` (FK to `hazard_report` ON DELETE CASCADE), `maintenance_user_id` (FK to `app_user`), `assigned_by_user_id` (FK to `app_user`), `assigned_at` (TIMESTAMP), `assignment_status` (VARCHAR(20), DEFAULT `'Assigned'`).
   - Constraint: `UNIQUE (report_id, maintenance_user_id)`.
7. **`report_status_history` (Audit Log):**
   - Columns: `history_id` (PK, SERIAL), `report_id` (FK to `hazard_report` ON DELETE CASCADE), `changed_by_user_id` (FK to `app_user`), `status` (VARCHAR(30)), `changed_at` (TIMESTAMP), `notes` (TEXT).
8. **`maintenance_action` (Technician Work Log):**
   - Columns: `action_id` (PK, SERIAL), `report_id` (FK to `hazard_report` ON DELETE CASCADE), `maintenance_user_id` (FK to `app_user`), `action_details` (TEXT), `action_date` (TIMESTAMP), `is_resolution` (BOOLEAN), `notes` (TEXT).
9. **`attachment` (Evidence Files Metadata):**
   - Columns: `attachment_id` (PK, SERIAL), `report_id` (FK to `hazard_report` ON DELETE CASCADE), `uploaded_by_user_id` (FK to `app_user`), `file_name` (VARCHAR(255)), `file_path_or_url` (TEXT), `mime_type` (VARCHAR(100)), `uploaded_at` (TIMESTAMP).

---

## 4. Access Control Architecture (Activity 4 Baseline)

Group 7's Activity 4 implementation (`database/03_roles_and_privileges.sql`) provisions three non-login group roles and three concrete login accounts:

| Role / Account Name | Type | Inherits From | Intended Scope & Capabilities | Identified Privileges / Deficiencies |
|---|---|---|---|---|
| `app_runtime_grp` | Group (`NOLOGIN`) | N/A | General application runtime connectivity. | `CONNECT` on db; `USAGE` on schema `public`; `SELECT` on all tables; `INSERT` on operational tables; `UPDATE` on operational tables; `DELETE` on `attachment`, `assignment`. **Deficiency:** Granted full table-wide `UPDATE` on `app_user` (Flaw G07-F1). |
| `app_readonly_grp`| Group (`NOLOGIN`) | N/A | Compliance auditor and read-only reporting. | `CONNECT` on db; `USAGE` on schema `public`; `SELECT` on operational tables; explicitly denied access to `app_user` (protecting password hashes). |
| `app_backup_grp`  | Group (`NOLOGIN`) | N/A | Automated backup operator (`pg_dump`). | `CONNECT` on db; `USAGE` on schema `public`; `SELECT` on all tables & sequences. **Deficiency:** Lacks `pg_read_all_data` membership and lacks cluster-level role export (Flaw G07-F4). |
| `campussafe_app`   | Login User | `app_runtime_grp` | Web application connection user. | Primary runtime database account utilized by `Database.php`. |
| `campussafe_report`| Login User | `app_readonly_grp`| Auditor reporting account. | Used for non-destructive compliance inspection. |
| `campussafe_backup`| Login User | `app_backup_grp`  | Automated backup service account. | Executes scheduled `pg_dump` jobs. |

---

## 5. Performance, Maintenance & Recovery Overview (Activities 5 & 6)

1. **Performance Indexing (Activity 3 & 5):**
   - The schema creates 10 explicit B-tree indexes on foreign keys: `idx_report_reporter`, `idx_report_location`, `idx_report_category`, `idx_report_status`, `idx_report_submitted`, `idx_assign_report`, `idx_assign_maint`, `idx_history_report`, `idx_action_report`, `idx_attach_report`.
   - *Observation:* No partial indexes exist on high-frequency triage queues (`WHERE status = 'Submitted'`).
2. **Maintenance Procedures (Activity 5):**
   - Routine `VACUUM (VERBOSE, ANALYZE)` routines were documented in `ACTIVITY_05_MAINTENANCE_MONITORING_REPORT.md` to prune dead tuples from frequent status updates.
   - *Observation:* No database-level triggers automate status logging or dead-tuple tracking.
3. **Backup and Recovery (Activity 6):**
   - Backup scripts (`01_backup.ps1`, `01_backup.sh`) execute logical backups using `pg_dump -Fc` (custom compressed format).
   - Verification scripts (`05_verify_objects.sql`, `06_verify_records.sql`) validate object and record counts after restoration into a test database.
   - *Observation:* `pg_dump` captures only database-level objects, omitting global PostgreSQL users, role passwords, and cluster memberships stored in `pg_authid`.
