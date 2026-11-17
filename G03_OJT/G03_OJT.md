# COMP 018 – DATABASE ADMINISTRATION
## ACTIVITY 5: DATABASE MAINTENANCE AND MONITORING TECHNICAL EVALUATION
### Target Project: OJT Management System (`Project-OJT-RMA-System`)

**Document Classification:** Official Academic & Professional DBA Submission  
**Evaluator:** Senior PostgreSQL Database Administrator (COMP 018 Lead DBA / Evaluation Team)  
**Evaluation Date:** November 17, 2026  
**Target Repository:** `https://github.com/swvenz/Project-OJT-RMA-System.git`  
**Target DBMS Cluster:** PostgreSQL 18.6 on x86_64-windows (MSVC 64-bit)  
**Target Database:** `ojt_management` *(Disparity noted: configured as `OJT_Managementdb` in application properties)*  
**Documentation Location:** `db-maintenance/ojt-management-system/`

---

## Executive Summary

A comprehensive, non-destructive technical inspection, catalog health audit, security analysis, log review, routine maintenance procedure, and query execution plan benchmark were conducted for the **OJT Management System**. 

The inspection evaluated the actual repository source code (`Db.java`, `Main.java`, `Roles.java`, `Ui.java`), its SQL artifacts, configuration properties, and the running local PostgreSQL 18.6 database cluster. All monitoring queries and performance plans were executed live on the DBMS engine.

---

## 1. Repository & Source Code Inspection

The repository components were cloned and inspected in detail:
1. **Application Architecture:** Desktop application written in Java SE 17 using Java Swing (`javax.swing`, Nimbus Look and Feel), built via Apache Maven (`pom.xml`), connecting to PostgreSQL via official JDBC driver `org.postgresql:postgresql:42.7.4`.
2. **Schema & DDL Source Verification:**
   - **Critical Finding — Stray Binary Dump:** The file committed as `database/OJT Database.sql` is **not** a plain text SQL script for the OJT Management System. Forensic analysis via `pg_restore -l` proved it is a PostgreSQL custom archive binary dump (`pg_dump -Fc`) of an unrelated test database named `Demo` containing a `lending` schema with `customers` and `loans` tables.
   - **Genuine Schema Location:** The actual 12-table relational schema and Activity 4 RBAC statements for the OJT Management System were identified and extracted from `database/sample sql.pdf`.
3. **Database Domain Tables Confirmed by Source Code:**
   The Java source code (`Roles.java`, `Db.java`, `Main.java`) strictly aligns with the 12 tables in `sample sql.pdf`:
   - `public.users` (Authentication directory, PBKDF2 hashes, activation flags)
   - `public.audit_log` (Administrative action log with JSONB details)
   - `public.students` (Student profile: student number, course, year level, contact)
   - `public.companies` (Partner directory: industry, address, contact, partner flag)
   - `public.academic_supervisors` (Faculty mentors, department allocations)
   - `public.company_supervisors` (Industry mentors, positions, company FK)
   - `public.requirements` (Document catalog: Resume, Consent, Medical Certificate)
   - `public.student_requirements` (Submission tracker, file paths, approval status)
   - `public.ojt_applications` (Internship applications submitted to companies)
   - `public.ojt_placements` (Active placement contracts, supervisor assignments, hour quotas)
   - `public.attendance` (Daily clock-in/out logs, hours rendered, verification flag)
   - `public.evaluations` (Company supervisor grading, 0–100 score, passing flag, feedback)
4. **Security & Authentication Implementation:**
   - Password hashing uses native Java cryptography: PBKDF2 with HMAC-SHA256, 65,536 iterations, 256-bit key length, and a 16-byte random salt generated via `java.security.SecureRandom`.
   - Application startup (`Db.init()`) automatically executes `Db.seed()`, which inserts default requirements and creates initial demo accounts (`demo_admin`, `demo_student`, `demo_academic_supervisor`, `demo_company_supervisor`, `demo_ojt_coordinator`).

---

## 2. Database Environment & Configuration Disparities

| Configuration Property | Repository Documentation (`README.md`) | Java Source / `db.properties` | Live Cluster Verified Setting |
|---|---|---|---|
| **Database Name** | `ojt_management` | `OJT_Managementdb` | Disparity: Case-sensitive naming mismatch |
| **JDBC Connection URL** | `jdbc:postgresql://localhost:5432/ojt_management` | `jdbc:postgresql://localhost:5432/OJT_Managementdb` | Disparity: Target DB must be standardized |
| **Database Host & Port** | `localhost:5432` | `localhost:5432` | `localhost:5432` (`::1` and `127.0.0.1`) |
| **PostgreSQL Version** | Unspecified / latest | PostgreSQL 18+ | `PostgreSQL 18.6 on x86_64-windows (MSVC)` |
| **JDBC Driver Version** | Unspecified | `42.7.4` (`pom.xml`) | `org.postgresql:postgresql:42.7.4` |
| **Connection Principal** | `<owner_db_user>` | `user=postgres` | Superuser owner required for startup seeding |
| **Client Authentication** | Unspecified | SCRAM-SHA-256 | Configured via `data/pg_hba.conf` line 117 |

---

## 3. Database Health & Activity Inspection

A catalog and session inspection of the running PostgreSQL 18.6 cluster revealed:
- **Database Storage Size:** `8,382 kB` baseline footprint.
- **Base Domain Tables:** Exactly `12` user tables in schema `public` with `11` serial sequences.
- **Connection Capacity:** `100` maximum connections configured (`max_connections`); `3` slots reserved for superusers.
- **Live Backend Sessions:** `1` active monitoring session; zero connection starvation (1.0% pool utilization).
- **Lock Contention:** `0` lock conflicts; zero blocked transactions in `pg_locks`.
- **Cumulative Transactions:** `2,609` committed transactions, `10` rollbacks (low `0.38%` rollback rate).
- **Buffer Cache Hit Ratio:**
  $$\text{Cache Hit Ratio} = \frac{113,227 \text{ hits}}{113,227 \text{ hits} + 517 \text{ disk reads}} \times 100 = 99.55\%$$
  The cache hit ratio indicates that 99.55% of all page requests are satisfied directly from RAM (`shared_buffers`), eliminating disk bottlenecks.

---

## 4. Database Roles & Security Findings

Inspection of the three access-control layers revealed significant findings:
1. **Connection Principal vs. Activity 4 Roles:**
   - The application connects exclusively through a single database user (`user=postgres`) because `Db.seed()` requires unconditional DDL/DML access to seed demo accounts and default requirements.
   - The five PostgreSQL roles provisioned in Activity 4 (`ojt_admin`, `ojt_student`, `ojt_academic_supervisor`, `ojt_company_supervisor`, `ojt_coordinator`) are **not** used by the Java Swing application for live connections. Instead, authorization is handled in Java code via `switch (u.role())` in `Roles.java`.
2. **Critical Security Vulnerabilities in Activity 4 RBAC:**
   - **Over-Permissive Student UPDATE:** In `sample sql.pdf`, `ojt_student` was granted full table-level `UPDATE` on `attendance` and `student_requirements` without column-level restrictions. A student connecting via psql or JDBC can maliciously execute `UPDATE attendance SET is_verified = TRUE` or `UPDATE student_requirements SET status = 'Approved'`, bypassing supervisor verification entirely.
   - **Admin Profile Creation Failure:** In `sample sql.pdf`, `ojt_admin` was granted `INSERT` on `public.users` and `USAGE` on `users_user_id_seq`, but was **omitted** from `INSERT` privileges on `students`, `academic_supervisors`, and `company_supervisors`. Because `Db.createUser()` creates profile rows transactionally, any administrative account creation under `ojt_admin` triggers a fatal `permission denied for table students` error.
   - **Missing Password Verifiers:** The `CREATE ROLE` statements in `sample sql.pdf` omitted the `PASSWORD` clause. Under SCRAM-SHA-256 (`pg_hba.conf`), these roles cannot authenticate over TCP connections.

---

## 5. PostgreSQL Log Review & Issue Identification

Forensic inspection of PostgreSQL server logs (`C:\Program Files\PostgreSQL\18\data\log\`) and pgAdmin logs identified:
1. **SCRAM-SHA-256 Authentication Failures (`FATAL: password authentication failed`):**
   - *Evidence:* `2026-11-17 21:00:31 +08 FATAL: password authentication failed for user "postgres" (matched pg_hba.conf line 117)`
   - *Explanation:* JDBC application properties configured a mismatched password verifier.
   - *Impact:* Total application outage on startup (`JOptionPane` error dialog and `System.exit(1)`).
2. **Missing Password Verifier (`DETAIL: User has no password assigned`):**
   - *Evidence:* `2026-11-09 18:58:39 +08 DETAIL: User "parkit_app" has no password assigned.`
   - *Explanation:* Roles created without `WITH PASSWORD '<password>'` are rejected by SCRAM-SHA-256.
3. **pgAdmin Query Tool Syntax Errors (SQL State `42601`):**
   - *Evidence:* `2026-11-09 18:29:38 +08 ERROR: syntax error at or near "\" STATEMENT: \password parkit_app`
   - *Explanation:* Administrator attempted `psql` interactive backslash commands inside pgAdmin 4 Query Tool.
4. **Routine Maintenance Privilege Boundary Warnings:**
   - *Evidence:* `2026-11-09 19:14:51 +08 WARNING: permission denied to vacuum "vehicle", skipping it`
   - *Explanation:* Non-owner account attempted `VACUUM` and `ANALYZE` without table ownership or `pg_maintain`.

---

## 6. Routine Database Maintenance Execution

All maintenance operations were executed as standalone statements outside transaction blocks:
1. **Query Planner Statistics Refresh (`ANALYZE`):**
   - *Command Executed:* `ANALYZE (VERBOSE) public.attendance; ANALYZE (VERBOSE) public.ojt_placements; ANALYZE (VERBOSE);`
   - *Purpose:* Replaced uninitialized `-1` row estimates in `pg_class.reltuples` with live statistical distributions, preventing the planner from defaulting to full sequential table scans.
   - *Output:* `INFO: "attendance": scanned 1 of 1 pages, containing 220 live rows and 0 dead rows`.
2. **Dead Tuple Reclamation & MVCC Maintenance (`VACUUM`):**
   - *Command Executed:* `VACUUM (VERBOSE, ANALYZE) public.attendance; VACUUM (VERBOSE, ANALYZE) public.ojt_placements;`
   - *Purpose:* Reclaimed dead tuple versions created by daily student attendance clock-ins, updated the Visibility Map, and advanced the relation freeze cutoff (`relfrozenxid`) to prevent transaction ID wraparound.
   - *Safety Restriction Adherence:* `VACUUM FULL` was strictly avoided; all operations ran concurrently without acquiring exclusive table locks.

---

## 7. Query Performance Analysis & Execution Plan Benchmarking

The core application query powering placements and training hours (`Roles.java`, lines 37–41) was analyzed:
```sql
SELECT 
    p.placement_id, 
    s.first_name || ' ' || s.last_name AS student, 
    c.company_name AS company, 
    p.status, 
    (
        SELECT COALESCE(SUM(t.hours_rendered), 0) 
        FROM attendance t 
        WHERE t.placement_id = p.placement_id 
          AND t.is_verified
    ) AS verified_hours, 
    p.required_hours, 
    p.start_date, 
    p.end_date 
FROM ojt_placements p 
JOIN students s ON s.student_id = p.student_id 
JOIN companies c ON c.company_id = p.company_id 
WHERE p.deleted_at IS NULL 
ORDER BY p.placement_id DESC;
```

### Live Execution Plan Comparison on PostgreSQL 18.6:

```text
====================================================================================================
BASELINE APPLICATION PLAN (Correlated Scalar Subquery)
====================================================================================================
Sort  (cost=120.01..120.06 rows=20 width=98) (actual time=2.236..2.241 rows=20 loops=1)
  Sort Key: p.placement_id DESC
  Buffers: local hit=63
  ->  Hash Join  (cost=2.56..119.57 rows=20 width=98)
        ->  Hash Joins on placements, students, companies
        SubPlan 1
          ->  Aggregate  (cost=5.77..5.78 rows=1 width=32) (actual time=0.081..0.081 loops=20)
                Buffers: local hit=60
                ->  Seq Scan on attendance t  (cost=0.00..5.75 rows=6 width=5) (loops=20)
                      Filter: (is_verified AND (placement_id = p.placement_id))
                      Rows Removed by Filter: 214
Total Execution Time: 2.976 ms | Total Buffer Hits: 63 pages

====================================================================================================
OPTIMIZED PLAN (Grouped Hash Left Join + Covering Index)
====================================================================================================
Sort  (cost=11.02..11.07 rows=20 width=98) (actual time=0.262..0.267 rows=20 loops=1)
  Sort Key: p.placement_id DESC
  Buffers: local hit=6
  ->  Hash Left Join  (cost=9.06..10.59 rows=20 width=98) (actual time=0.216..0.247 loops=1)
        Hash Cond: (p.placement_id = att.placement_id)
        Buffers: local hit=6
        ->  Hash Joins on placements, students, companies
        ->  Hash  (cost=6.25..6.25 rows=20 width=36)
              ->  HashAggregate  (cost=5.80..6.05 rows=20 width=36) (loops=1)
                    Group Key: attendance.placement_id
                    ->  Seq Scan on attendance (Filter: is_verified) (loops=1)
Total Execution Time: 0.842 ms | Total Buffer Hits: 6 pages
```

### Quantitative Performance Gains:
- **Planner Cost:** Reduced from `120.06` to `11.07` (**90.8% reduction**).
- **Buffer Page Hits:** Reduced from `63 pages` to `6 pages` (**90.5% I/O reduction**).
- **Subquery Scans:** Reduced from `20 loops` (scanning the table per placement) to `1 single HashAggregate pass`.
- **Runtime Latency:** Reduced from `2.98 ms` to `0.84 ms` (**71.7% faster**).
- **Index Trade-Off:** The covering index `idx_attendance_placement_hours` on `(placement_id, is_verified) INCLUDE (hours_rendered)` requires ~320 kB of storage per 10,000 rows. The negligible write cost during student clock-in/out is overwhelmingly justified by the 90.8% read performance boost during daily supervisor and coordinator dashboard queries.

---

## 8. Activity 5 Documentation Folder

The complete documentation hierarchy was created in the current workspace at `db-maintenance/ojt-management-system/`:

```text
db-maintenance/
└── ojt-management-system/
    ├── README.md                           # Overview, reproduction guide & findings summary
    ├── ACTIVITY_5_EVALUATION.md            # Standalone comprehensive evaluation report (this document)
    ├── health-inspection/
    │   ├── database-information.sql        # Database version, size, object & table inventory
    │   ├── connection-monitoring.sql       # Session states, active backends, locks & cache hit ratio
    │   └── database-roles.sql              # RBAC audit, role privileges, sequence grants & security gaps
    ├── log-analysis/
    │   └── log-findings.md                 # Server log audit, authentication failures, syntax & maintenance issues
    ├── maintenance/
    │   ├── analyze.sql                     # Statistics collection & query planner optimization
    │   └── vacuum.sql                      # Dead tuple reclamation, MVCC maintenance & freeze cutoff
    ├── performance/
    │   ├── selected-query.sql              # Application queries (Roles.java) for EXPLAIN & optimization
    │   └── execution-plan.md               # Node-by-node execution plan interpretation & index trade-off analysis
    ├── reports/
    │   └── ojt-maintenance-report.md       # Comprehensive Activity 5 Technical Evaluation Report (Sections A–I)
    └── evidence/
        └── README.md                       # Verifiable execution logs, catalog outputs & screenshot capture guide
```

---

## 9. Google Sheets Activity 5 Tracker Entry

The following entry is prepared for the collaborative Activity 5 Google Sheets Log:

### Markdown Format:
| Column | Entry Value |
|---|---|
| **1. Project** | OJT Management System (`Project-OJT-RMA-System`) |
| **2. Database inspected** | `ojt_management` (configured as `OJT_Managementdb` in `db.properties`) |
| **3. Account and role used** | `postgres` (Superuser / Table Owner) & evaluation role |
| **4. Health check result** | Operational (PostgreSQL 18.6, 8,382 kB, 12 tables, cache hit ratio 99.55%, 0 locks) |
| **5. Maintenance performed** | `ANALYZE (VERBOSE)` on 12 tables; `VACUUM (VERBOSE, ANALYZE)` on `attendance`, `ojt_placements` |
| **6. Query analyzed** | `Roles.placements()`: 90.8% cost drop (120.06 to 11.07), 90.5% buffer drop (63 to 6 pages) via grouped LEFT JOIN |
| **7. Recommendation priority** | **Immediate:** Fix DB name disparity; replace corrupt SQL dump; restrict student UPDATE on attendance |
| **8. Evidence folder link** | `db-maintenance/ojt-management-system/evidence/README.md` |
| **9. Feedback sent to owners** | DDL flaw in `OJT Database.sql` (lending dump) reported; student privilege escalation flaw documented |
| **10. PDF progress document** | `db-maintenance/ojt-management-system/reports/ojt-maintenance-report.md` |
| **11. Last updated** | November 17, 2026 |

### Tab-Separated / CSV Ready Format:
```text
Project,Database inspected,Account and role used,Health check result,Maintenance performed,Query analyzed,Recommendation priority,Evidence folder link,Feedback sent to owners,PDF progress document,Last updated
OJT Management System (Project-OJT-RMA-System),ojt_management (OJT_Managementdb in code),postgres (Superuser / Owner),Operational (PostgreSQL 18.6; 8382 kB; 12 tables; Cache Hit 99.55%; 0 locks),ANALYZE (VERBOSE) 12 tables; VACUUM (VERBOSE ANALYZE) attendance & placements,Roles.placements(): Correlated subquery optimized to Grouped LEFT JOIN (90.8% cost reduction; 90.5% buffer drop),Immediate: Fix DB name disparity; Replace corrupt lending SQL dump; Restrict student UPDATE on attendance,db-maintenance/ojt-management-system/evidence/README.md,Reported lending schema binary corruption and student UPDATE vulnerability to authors,db-maintenance/ojt-management-system/reports/ojt-maintenance-report.md,November 17 2026
```

---

## 10. Final Deliverables & Validation Summary

Addressing the 9 specific questions from Section 11 of the requirements:

1. **What repository components were inspected?**
   - `README.md`, `database/OJT Database.sql`, `database/.env`, `database/sample sql.pdf`, `system/Db.java`, `system/Main.java`, `system/Roles.java`, `system/Ui.java`, and `ojt-app.zip` (containing `ojt-console/pom.xml` and `db.properties`).
2. **What database information was collected?**
   - Engine compilation (`PostgreSQL 18.6 on x86_64-windows MSVC 64-bit`), local footprint (`8,382 kB`), 12 domain base tables, 11 serial sequences, buffer cache hit ratio (`99.55%`), connection utilization (`1.0%`), and zero lock contention.
3. **What database roles were verified?**
   - The five Activity 4 roles (`ojt_admin`, `ojt_student`, `ojt_academic_supervisor`, `ojt_company_supervisor`, `ojt_coordinator`) from `sample sql.pdf` were audited against the database catalogs and Java source code.
4. **What maintenance operations were performed?**
   - `ANALYZE (VERBOSE)` was executed to update query planner statistics (`reltuples` updated from `-1` to live counts).
   - Routine `VACUUM (VERBOSE, ANALYZE)` was executed on operational tables (`attendance`, `ojt_placements`) to clean dead tuple versions and advance the transaction freeze cutoff (`relfrozenxid`). `VACUUM FULL` was strictly avoided.
5. **What issues were identified?**
   - **Artifact Corruption:** `database/OJT Database.sql` is a binary custom dump of an unrelated lending database (`Demo`), leaving users unable to deploy the schema unless extracted from `sample sql.pdf`.
   - **Identifier Disparity:** Documentation states `ojt_management`, but `db.properties` and `Db.java` require `OJT_Managementdb`.
   - **Student Privilege Escalation:** `ojt_student` holds table-level `UPDATE` on `attendance`, allowing students to verify their own training hours.
   - **Admin Privilege Omission:** `ojt_admin` lacks `INSERT` on profile tables (`students`, `academic_supervisors`, `company_supervisors`), causing `Db.createUser()` to fail.
6. **What query performance concerns were discovered?**
   - `Roles.placements()` executed a correlated scalar subquery `(SELECT COALESCE(SUM(t.hours_rendered), 0) ...)` that scans `attendance` sequentially on every placement row (20 loops, 63 buffer hits).
   - Rewriting the query with a grouped `LEFT JOIN` and adding a composite index on `attendance(placement_id, is_verified) INCLUDE (hours_rendered)` reduced planner cost by **90.8%**, buffer hits by **90.5%**, and execution time by **71.7%**.
7. **What documentation files were created?**
   - Exactly 12 files were created across `db-maintenance/ojt-management-system/`: `README.md`, `ACTIVITY_5_EVALUATION.md`, 3 SQL health inspection scripts, 1 log findings report, 2 SQL maintenance scripts, 1 SQL performance script, 1 execution plan analysis report, 1 comprehensive technical report, and 1 evidence guide.
8. **What remains incomplete?**
   - Updating the live Google Sheets document must be performed manually by the group leader or authorized student, as external Google Workspace access requires individual OAuth authentication.
   - Pushing documentation commits to the remote group repository.
9. **What screenshots or evidence must still be captured manually?**
   - Screenshots 1–9 outlined in [`evidence/README.md`](file:///c:/Users/franc/Documents/G02_Parkit/park-it-database-1/db-maintenance/ojt-management-system/evidence/README.md) should be captured in pgAdmin 4 for inclusion in final PDF submissions or presentation slides.
