# COMP 018 – Database Administration
## Activity 3: System Development, Repository Deployment, and Progress Documentation
### Progress Report: iBarangay Community Services Portal

---

## 1. Cover and Team Information
- **Project Title**: iBarangay Community Services Portal
- **Group Name**: PPGG / Helix
- **Course**: COMP 018 – Database Administration
- **Git Repository**: [https://github.com/jeffersonorpesa2-ops/Helix-repo-](https://github.com/jeffersonorpesa2-ops/Helix-repo-)
- **Branch to Test**: `main`
- **Class Google Sheets Tracker**: [Class Activity 3 Tracker Row](https://github.com/jeffersonorpesa2-ops/Helix-repo-)
- **Team Members & Roles**:
  - **Jefferson Orpesa** - Database Administrator & Full-Stack Developer (Database Schema, Migration Scripts, Automation Scripts, GitHub Deployment)
  - **Team Member 2** - Backend & API Developer (Spring Boot REST Controllers, JPA Entities, Flyway Integration)
  - **Team Member 3** - Frontend Developer & UI/UX (HTML5/CSS3/Bootstrap Reconstructed Interface, Dynamic Form Handlers)
  - **Team Member 4** - QA, Testing & Technical Documentation (Data Dictionary, Setup Testing, Troubleshooting Guide)

---

## 2. System Overview
### Purpose and Scope
**iBarangay** is a localized digital governance platform designed to modernize and streamline resident requests for official barangay documents (Barangay Clearance, Certificate of Indigency, Certificate of Residency, and Barangay Business Clearance). The platform replaces paper-based queuing and disparate physical record books with an organized, relational PostgreSQL database and a responsive web application.

### Key Functional Features
1. **Document Services Catalog**: Dynamically displays available barangay certificates with processing durations, fees, and requirements.
2. **Resident Online Submission**: Citizens can submit applications with personal details, document type, and official purpose.
3. **Citizen Records Directory**: Barangay staff can register, look up, and manage verified constituents.
4. **Lifecycle Request Tracking**: Applications transition across statuses (`PENDING` -> `PROCESSING` -> `APPROVED` -> `RELEASED` / `REJECTED`).
5. **Immutable Audit Trail (`request_status_history`)**: Tracks every status transition, updating staff member, timestamp, and review remarks.
6. **Zero-Config Database Initialization**: Automatically creates the PostgreSQL database and applies Flyway migrations upon launch.

---

## 3. Application User Roles and Database Mapping
The system cleanly separates application-level authentication roles from PostgreSQL database-level privilege accounts.

| Application Role | Responsibilities in Application | Functions and Data Access | Intended Database Role |
| :--- | :--- | :--- | :--- |
| **Super Admin / Captain** | Overall barangay management, system configuration, admin accounts | Full CRUD on `admins`, `citizens`, `document_types`, `document_requests`, and audit views | `app_admin_grp` |
| **Barangay Staff / Clerk** | Review requests, update processing status, record citizen inquiries | CRUD on `citizens`, `document_requests`; INSERT into `request_status_history` | `app_runtime_grp` |
| **Auditor / Inspector** | Monitor performance metrics, verify clearance issuance logs | Read-only access to requests, citizens, and audit log tables | `app_readonly_grp` |
| **Application Runtime (Spring Boot)** | Connection pool runtime account (`HikariCP`) | Executes schema migrations and standard operational queries | `app_runtime_grp` |

---

## 4. Development Progress Log
- **Phase 1: Project Setup & Entity Modeling**
  - Configured Maven `pom.xml` with Spring Boot 4.1.2 and PostgreSQL JDBC driver.
  - Defined JPA entities: `Admin`, `Citizen`, `DocumentType`, `Requirement`, `DocumentRequest`, `RequestStatusHistory`.
  - Added `@GeneratedValue(strategy = GenerationType.IDENTITY)` to ensure auto-incrementing surrogate primary keys.
- **Phase 2: Database Schema & Migration Engineering**
  - Authored `V1__initial_schema.sql` defining baseline PostgreSQL tables and foreign key constraints.
  - Integrated `V2__improve_database_structure.sql` adding `tracking_number`, `phone_number`, indices, and nullable admin keys.
  - Authored `V3__sample_data.sql` populating realistic Philippine barangay constituents, sample document requests, and audit logs.
- **Phase 3: Controller & Service Implementation**
  - Developed `DocumentRequestController` with complete CRUD endpoints (`GET`, `POST`, `PUT`, `DELETE`).
  - Added `AdminController`, `CitizenController`, and `DocumentTypeController` endpoints.
  - Implemented automated database creation logic in `IbaranggayApplication.java` connecting via maintenance DB `postgres`.
- **Phase 4: Frontend Recreation & Polish**
  - Reconstructed responsive modern web frontend (`src/main/resources/static/index.html`) matching official UI specifications.
  - Linked frontend modals with REST API endpoints for seamless asynchronous submissions.
- **Phase 5: Portability & Cross-Group Validation**
  - Implemented `.env` environment loading and sanitized `application.properties`.
  - Authored robust `start.bat` and `setup_and_start.bat` scripts with auto-detection for Java and multi-drive PostgreSQL installations.
  - Prepared repository deployment and comprehensive documentation.

---

## 5. Database Implementation
### Target Database Details
- **DBMS**: PostgreSQL 16+ / 18
- **Database Name**: `PPGG_projectdb`
- **Default Schema**: `public`
- **Migration Tool**: Flyway (Automated on application start)

### Schema Overview (7 Tables)
1. `admins`: Administrative accounts and roles (`ADMIN`, `STAFF`).
2. `citizens`: Registered constituents with contact information and addresses.
3. `document_types`: Issuable certificates with turnaround times and fees.
4. `requirements`: Supporting prerequisites (e.g., Valid ID, Cedula).
5. `document_type_requirements`: Many-to-many junction table between document types and requirements.
6. `document_requests`: Core transaction records storing tracking code, purpose, current status, and timestamps.
7. `request_status_history`: Append-only audit log capturing every lifecycle status update.

---

## 6. Application Evidence
- **Web Portal Access**: Running at `http://localhost:8084/`
- **REST Endpoints Verified**:
  - `GET /api/document-types`: Returns active catalog items.
  - `GET /api/document-requests`: Returns all submitted requests with joined citizen and document information.
  - `POST /api/document-requests`: Creates new document requests with validation.
  - `PUT /api/document-requests/{id}`: Updates processing status and generates status history entries.
  - `GET /api/citizens`: Returns registered constituents.
- **Database Validation**: Verified via `psql` and Flyway migration schema history (`flyway_schema_history` table).

---

## 7. Setup and Configuration Guide
### Prerequisites
- Java Development Kit (JDK 21 or higher)
- PostgreSQL 14+ (running on port 5432)
- Modern Web Browser (Chrome, Edge, Firefox, Brave)

### Quick Start
1. Clone the repository:
   ```bash
   git clone https://github.com/jeffersonorpesa2-ops/Helix-repo-.git
   cd Helix-repo-
   ```
2. Configure credentials:
   - Copy `.env.example` to `.env`.
   - Update `DB_PASSWORD` to match your local PostgreSQL password.
3. Start the application:
   - Double-click `start.bat` (or execute `./mvnw spring-boot:run`).
4. Access the portal at:
   ```
   http://localhost:8084/
   ```

---

## 8. Issues Encountered and Resolutions
1. **Missing Initial Flyway Baseline (`V1`)**:
   - *Issue*: Applying `V2` on an empty database failed because baseline tables did not exist.
   - *Fix*: Created `V1__initial_schema.sql` containing complete DDL for all 7 tables.
2. **PostgreSQL Path Detection on Non-C Drives**:
   - *Issue*: `psql` was installed on drive `D:\Postgre` rather than standard `C:\Program Files`.
   - *Fix*: Enhanced automation batch scripts to search `D:\Postgre` and auto-source `pg_env.bat`.
3. **Database Pre-Existence Prerequisite**:
   - *Issue*: Fresh machines failed to boot if `PPGG_projectdb` was not manually created beforehand in pgAdmin.
   - *Fix*: Embedded automatic JDBC database creation in `IbaranggayApplication.java` using default `postgres` catalog.
4. **Port 8080 Conflicts**:
   - *Issue*: Previous Tomcat/JVM processes held port 8080.
   - *Fix*: Configured default port to 8084 and added automated process termination in batch runners.

---

## 9. Cross-Group Verification
- The project has been verified to start completely autonomously on clean local environments without manual database pre-creation.
- When tested by peer groups, only `git clone`, updating `.env`, and running `start.bat` are required to achieve full functionality.

---

## 10. AI Usage Declaration
- **AI Tool Used**: Google Antigravity / Gemini Advanced Agentic Coding Assistant.
- **Tasks Performed**:
  - Diagnosed Flyway migration order and schema dependency issues.
  - Reconstructed responsive HTML5/Bootstrap frontend matching Activity 3 UI specifications.
  - Created automated database creation routines and batch startup scripts.
  - Drafted comprehensive technical documentation, ERD mappings, and troubleshooting guides.
- **Validation & Verification**:
  - All generated code was verified by compiling against Spring Boot 4.1.2.
  - PostgreSQL schema integrity, foreign keys, and migration execution were tested and validated directly via SQL queries and REST API integration calls.
