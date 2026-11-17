# Database Maintenance & Monitoring (Activity 5)
## BoardTrack – Boarding House & Rental Management System
**Course:** COMP 018 – Database Administration | **Activity:** 5  
**Target System:** BoardTrack (Boarding House & Rental Management System)  
**Target Database:** `boardtrack_db` (configurable via `DATABASE_URL`)  
**Schema:** `public` | **Database Engine:** PostgreSQL 18.6 (x64) on Windows 10/11  
**Application Stack:** Node.js 20.12+, Express, EJS, `pg`  

---

## 1. Directory Structure and Deliverables

This directory contains the complete maintenance, diagnostic monitoring, index performance, and query execution evaluation framework for the **BoardTrack** project.

```text
db-maintenance/
│
├── README.md                           # Master navigation and execution overview (this document)
├── database-health-check.md            # Part A: Comprehensive 14-point database health audit
├── database-activity-monitoring.md     # Part B: Active sessions, locks, wait events & contention
├── vacuum-analyze-report.md            # Parts C & D: VACUUM and ANALYZE operations & dead tuples
├── index-monitoring-report.md          # Part E: Complete index inventory, scan counts & bloat audit
├── query-performance-report.md         # Part F: EXPLAIN & EXPLAIN ANALYZE for core application queries
├── before-after-comparison.md          # Section 7: Before-and-after maintenance comparison table
├── run-activity5.ps1                   # Automated PowerShell test runner with transcript logging
│
├── sql/                                # Validated SQL diagnostic & maintenance scripts
│   ├── 01_database_health_check.sql    # Read-only health check & object catalog query
│   ├── 02_activity_monitoring.sql      # Read-only session & contention monitoring
│   ├── 03_table_statistics.sql         # Read-only table bloat & scan statistics
│   ├── 04_index_monitoring.sql         # Read-only index inventory & scan counts
│   ├── 05_query_performance.sql        # Read-only EXPLAIN / EXPLAIN ANALYZE queries
│   └── 06_maintenance_operations.sql   # Maintenance: Schema ANALYZE + Table-by-Table VACUUM
│
└── evidence/                           # Evidence transcripts and capture guide
    ├── README.md                       # Security, confidentiality & evidence guidelines
    └── evidence-checklist.md           # Step-by-step screenshot and transcript capture guide
```

---

## 2. Safety Protocols and Operational Directives

Database maintenance in a production or academic evaluation setting requires strict adherence to safety standards:

1. **Non-Destructive Operations Only:** Routine maintenance maintains and optimizes existing data; it does not destroy it.
   - **NEVER** run `DROP DATABASE`, `DROP TABLE`, `TRUNCATE`, `ALTER TABLE`, or unauthorized `DELETE`/`UPDATE`.
   - **NEVER** run `VACUUM FULL` during online operations. `VACUUM FULL` takes an `ACCESS EXCLUSIVE` lock, preventing all concurrent queries and writes. Only standard online `VACUUM (VERBOSE, ANALYZE)` is permitted.
   - **NEVER** run `npm run db:reset` against an active target database, as this command completely drops the public schema and purges all live records.
2. **Transaction Block Restriction:** `VACUUM` commands **cannot** be executed inside an active transaction block. They must never be enclosed within `BEGIN ... COMMIT` statements.
3. **Least Privilege & Role Isolation:**
   - Routine monitoring should use non-superuser accounts where possible.
   - In PostgreSQL 18, dedicated administrative monitoring and maintenance privileges can be granted through built-in system roles: `pg_monitor` (inspecting activity and system catalogs) and `pg_maintain` (executing `VACUUM` and `ANALYZE` without requiring superuser escalation).
4. **Credential Security:** Never commit `.env` files, plaintext database passwords, or session secrets to version control.

---

## 3. Quick Execution Guide

The diagnostic and maintenance tasks can be executed easily using PowerShell:

### Option A: Using the Automated PowerShell Runner (`run-activity5.ps1`)

```powershell
# Navigate to the BoardTrack repository directory
cd C:\Users\franc\.gemini\antigravity\scratch\BoardTrack

# Run health check (Part A)
.\db-maintenance\run-activity5.ps1 -Step health -Database boardtrack_db -User postgres

# Run activity and session monitoring (Part B)
.\db-maintenance\run-activity5.ps1 -Step activity -Database boardtrack_db -User postgres

# Run table statistics and bloat evaluation (Part C)
.\db-maintenance\run-activity5.ps1 -Step stats -Database boardtrack_db -User postgres

# Run index monitoring (Part E)
.\db-maintenance\run-activity5.ps1 -Step index -Database boardtrack_db -User postgres

# Run query performance analysis (Part F)
.\db-maintenance\run-activity5.ps1 -Step query -Database boardtrack_db -User postgres

# Execute routine maintenance (ANALYZE and VACUUM) (Parts C & D)
.\db-maintenance\run-activity5.ps1 -Step maintain -Database boardtrack_db -User postgres
```

### Option B: Manual Execution via `psql`

```powershell
# Set psql in PATH if not already accessible
$env:Path += ";C:\Program Files\PostgreSQL\18\bin"

# 1. Health Check
psql -h localhost -p 5432 -U postgres -d boardtrack_db -f db-maintenance/sql/01_database_health_check.sql

# 2. Activity Monitoring
psql -h localhost -p 5432 -U postgres -d boardtrack_db -f db-maintenance/sql/02_activity_monitoring.sql

# 3. Table Statistics
psql -h localhost -p 5432 -U postgres -d boardtrack_db -f db-maintenance/sql/03_table_statistics.sql

# 4. Index Monitoring
psql -h localhost -p 5432 -U postgres -d boardtrack_db -f db-maintenance/sql/04_index_monitoring.sql

# 5. Query Performance
psql -h localhost -p 5432 -U postgres -d boardtrack_db -f db-maintenance/sql/05_query_performance.sql

# 6. Maintenance Operations
psql -h localhost -p 5432 -U postgres -d boardtrack_db -f db-maintenance/sql/06_maintenance_operations.sql
```

---

## 4. Status Definitions Used in Activity 5 Reports

In strict accordance with QA auditing and database administration best practices:

* **`PASS`**: The check or command was executed against the live database, and the output strictly satisfied the expected technical criteria.
* **`FAIL`**: The operation was executed against the database and produced an unexpected syntax error, constraint failure, or anomalous result.
* **`BLOCKED`**: The operation could not be completed on the live database due to missing authentication credentials, lack of role privileges, or an inaccessible database service. (A credential prompt is reported as `BLOCKED`, never as a database defect).
* **`NOT RUN`**: The operation has not yet been attempted.
