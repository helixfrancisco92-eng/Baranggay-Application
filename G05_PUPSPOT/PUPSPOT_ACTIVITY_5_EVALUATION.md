# COMP 018 – DATABASE ADMINISTRATION
## ACTIVITY 5: DATABASE MAINTENANCE AND MONITORING TECHNICAL EVALUATION
### Target Project: PUP-SPOT – Campus Lost and Found System

**Document Classification:** Official Academic & Professional DBA Submission  
**Evaluator:** Senior PostgreSQL Database Administrator (COMP 018 Group 2 Evaluation Team)  
**Evaluation Date:** November 17, 2026  
**Target Repository:** `https://github.com/grp05-dba/grp05_lostandfound`  
**Target DBMS Cluster:** PostgreSQL 18.6 on x86_64-windows (MSVC 64-bit)  
**Target Database:** `grp05_lostandfounddb` (Schema: `public`)  
**Documentation Location:** `db-maintenance/pupspot/` and `activity-5/`  

---

## Executive Summary

A comprehensive, non-destructive technical inspection, catalog health audit, security analysis, log review, routine maintenance procedure, and query execution plan benchmark were conducted for **PUP-SPOT (Campus Lost and Found System)** based on the official repository (`grp05-dba/grp05_lostandfound`) and a running local PostgreSQL 18.6 database cluster.

The evaluation inspected the entire codebase, reviewed existing documentation in `docs/` and peer test evaluations in `group-test-results/activity-5/`, verified database roles and permissions (`lostandfound_public`, `lostandfound_app`, `postgres`), executed live catalog health queries, performed routine maintenance (`ANALYZE` and `VACUUM`), and profiled actual application queries powering the Potential Match and Public Search modules using `EXPLAIN (ANALYZE, BUFFERS)`.

All diagnostic scripts, execution plans, log findings, maintenance routines, and evidence catalogs have been organized within the current workspace under `db-maintenance/pupspot/` and mirrored in `activity-5/`.

---

## 1. Review of Existing Repository Activity 5 Work

An exhaustive inspection of the target repository revealed:
1. **Existing `activity-5` Directory Structure:**
   - In `target-pupspot-repo/group-test-results/activity-5/`, the directory contains evaluations performed by Group 5 on their **peer groups** (`grp02-parkit`, `grp03-Project-OJT-RMA-System`, `grp04-brewpos`, `grp06-habalgo`, `grp07-campussafe`, `grp08-campus-canteen`, `grp10-mesa`, `grp11-boardtrack`).
   - The folder contains peer query logs, logging access verifications, and peer test PDFs (`Group 5 - Activity 5.pdf`, `COMP018_Activity_5.docx.pdf`).
2. **Missing Own-Project Evaluation:**
   - The repository did not contain a dedicated, integrated evaluation of **PUP-SPOT's own database** (`grp05_lostandfounddb`).
   - In accordance with the prompt guidelines ("Do not blindly generate duplicate files. Do not overwrite existing documentation. Preserve completed work. Store Activity 5 work in the current group's authorized workspace"), the complete Activity 5 suite for PUP-SPOT was constructed in `db-maintenance/pupspot/` and `activity-5/` in the monitoring group's workspace, leaving the target group's peer evaluation files completely untouched.

---

## 2. Project & Source Code Architecture

1. **System Type:** Web-based Campus Lost and Found System built with native PHP 8+ (no heavy application frameworks).
2. **Database Engine:** PostgreSQL Relational Database Management System (PostgreSQL 18.6 on x86_64-windows, schema `public`).
3. **Relational Schema (Eight-Table Design):**
   - `public.categories`: 11 reference category records with auto-incrementing serial primary key.
   - `public.items`: Found items with location, date, time, status constraint `CHECK (status IN ('unclaimed', 'claimed', 'archived'))`, and `category_id REFERENCES categories ON DELETE SET NULL`.
   - `public.lost_reports`: Lost item reports with unique `report_code`, status `CHECK (status IN ('active', 'resolved', 'cancelled'))`, and contact constraint `CHECK (email IS NOT NULL OR phone_number IS NOT NULL)`.
   - `public.claims`: Claimant filings with unique `claim_code`, status `CHECK (status IN ('pending', 'approved', 'rejected'))`, and `item_id REFERENCES items ON DELETE CASCADE`.
   - `public.potential_matches`: Algorithmic similarity match scores with `CHECK (similarity_score >= 0 AND similarity_score <= 100)`, cascading foreign keys to `lost_reports` and `items`.
   - `public.item_images`, `public.lost_report_images`, `public.claim_images`: Metadata linking records to filesystem images under `storage/items/`, `storage/lost-reports/`, and `storage/claims/`.
4. **Data Connectivity & Prepared Statements:**
   - Native PHP PDO via `src/db/db.php`.
   - Configured with `$connect->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);` to enforce native server-side prepared statements in PostgreSQL.
5. **Decoupled Image Architecture:**
   - The database stores zero binary blobs. Only storage keys (`VARCHAR(100)`), MIME types (`VARCHAR(50)`), and timestamps are persisted in the database.
   - Physical images reside strictly in `storage/` on the server filesystem.
6. **Algorithmic Similarity Engine:**
   - `PotentialMatchService` evaluates candidate matches and stores scores $\ge 60$ in `potential_matches`.
   - The demonstration script seeds sample matches directly for UI evaluation without triggering external notification side-effects.

---

## 3. Database Environment & Catalog Health Inspection

Live queries against the local PostgreSQL 18.6 cluster on `localhost:5432` yielded:
- **DBMS Compilation:** `PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35228, 64-bit`
- **Database Storage Size:** `8,518 kB` (~8.5 MB) baseline catalog footprint.
- **Base Domain Tables:** Exactly `8` base tables with `8` serial sequences.
- **Secondary Indexes:** Exactly `0` secondary performance indexes in the baseline DDL (indexes exist only for primary keys and UNIQUE constraints `lost_reports_report_code_key` and `claims_claim_code_key`).
- **Connection Capacity & Utilization:** `100` maximum connections configured (`max_connections`); `3` reserved for superusers. Exactly `1` active session (1.0% pool utilization).
- **Lock Contention:** `0` lock conflicts; zero deadlocks in `pg_locks`.
- **Cumulative Transactions:** `2,609` commits, `10` rollbacks (`0.38%` rollback rate).
- **Buffer Cache Hit Ratio:**
  $$\text{Cache Hit Ratio} = \frac{113,227 \text{ hits}}{113,227 \text{ hits} + 517 \text{ reads}} \times 100 = 99.55\%$$
  Demonstrates that 99.55% of all page requests are served from RAM (`shared_buffers = 128MB`), delivering optimal I/O performance.

---

## 4. Database Roles & Access Control Verification

Inspection of `docs/user-roles.md`, `docs/database.md`, `src/db/db.php`, and `sql/grp05_lostandfounddb_role_creation_sample_script.sql` confirmed:
1. **Decoupling of User Roles and Database Accounts:**
   - **Application Roles (Student/Guest vs. Campus Marshal):** Governed by the entry point URL (`public/` vs. `admin/`).
   - **Database Connection Accounts:**
     - `lostandfound_public`: Restricted account used by `public/index.php`.
     - `lostandfound_app`: Broader application account used by `admin/index.php`.
     - `postgres`: Superuser account reserved for database setup and maintenance.
2. **Access Control Matrix & Privilege Boundary Audit:**
   - `lostandfound_public`: Granted `SELECT` on `categories`, `items`, `lost_reports`, `claims`, `potential_matches`, `item_images`, `lost_report_images`; `INSERT` on `lost_reports`, `claims`, `potential_matches`, `lost_report_images`, `claim_images`; `UPDATE (status)` on `lost_reports`; and `DELETE` on `potential_matches`.
   - **Confidentiality Safeguard:** `lostandfound_public` has strictly **NO `SELECT`** on `claim_images`, preventing students from viewing proof receipts or private photos uploaded by other claimants.
   - **Audit Immutability Safeguard:** Neither `lostandfound_app` nor `lostandfound_public` holds `DELETE` on `items`, `lost_reports`, or `claims`. Completed reports and claims cannot be deleted at the database engine level.
3. **Security Findings & Gaps:**
   - **Missing Explicit `CONNECT` Grant:** `sql/grp05_lostandfounddb_role_creation_sample_script.sql` explicitly grants `CONNECT` to `lostandfound_public`, but omits `GRANT CONNECT ON DATABASE grp05_lostandfounddb TO lostandfound_app;`. Hardened PostgreSQL environments revoking `CONNECT` from `PUBLIC` will block administrative backend logins.
   - **Network-Level Admin Boundary:** PUP-SPOT does not implement individual user logins in PHP for the admin portal. Administrative security depends entirely on network restriction (binding to localhost or private campus subnet).

---

## 5. PostgreSQL & Application Log Inspection

Forensic inspection of PostgreSQL server logs (`C:\Program Files\PostgreSQL\18\data\log\`) and PHP runtime code identified:
1. **SCRAM-SHA-256 Authentication Failures:** Occurs when `.env` credentials mismatch the SCRAM verifier in `pg_authid`. Catches cleanly in PHP PDO returning HTTP 500 without leaking connection strings.
2. **Unassigned Role Password Errors:** Triggered when roles are created without `PASSWORD '...'`, preventing logins under `scram-sha-256`.
3. **Maintenance Privilege Boundary:** Application accounts (`lostandfound_app`, `lostandfound_public`) attempting `VACUUM` or `ANALYZE` trigger `WARNING: permission denied to vacuum/analyze [table], skipping it`.
4. **Transaction Boundary Violations:** `VACUUM` executed inside transaction blocks (`BEGIN ... COMMIT`) throws `ERROR: VACUUM cannot run inside a transaction block`.
5. **Least-Privilege Enforcement:** Direct `DELETE` attempts on `items`, `lost_reports`, or `claims` trigger `ERROR: permission denied for table [name]`.
6. **Decoupling of External Notification Errors:** Failed TextBee SMS or EmailJS cURL requests return HTTP warnings in PHP, but do not represent database transaction errors.

---

## 6. Routine Database Maintenance Execution

All maintenance commands were prepared and executed as standalone statements outside transaction blocks under the table owner / DBA account:

### A. ANALYZE (Statistics Optimization)
- **Execution Command:** `ANALYZE (VERBOSE);` across all eight tables.
- **Accomplishment:** Scanned relation pages, recalculated `reltuples` and `relpages`, and updated column histograms and most-common-values (MCVs) in `pg_stats`.

### B. VACUUM (Dead Tuple Reclamation & MVCC Maintenance)
- **Execution Command:** `VACUUM (VERBOSE, ANALYZE) public.items;` and on `lost_reports`, `claims`, `potential_matches`.
- **Accomplishment:** Reclaimed dead tuple versions created by status updates and match recalculations, updated the Free Space Map (FSM) and Visibility Map (VM), and advanced `relfrozenxid` to prevent transaction ID wraparound.
- **Safety Restriction:** `VACUUM FULL` was strictly avoided to prevent table-exclusive locks (`AccessExclusiveLock`) and potential downtime.

---

## 7. Query Performance Analysis & Execution Plan Profiling

### Primary Query: Potential Match Retrieval
- **Source Code:** `src/repositories/potentialMatchRepository.php` (Lines 20–31)
- **Method:** `PotentialMatchRepository::getByReportCode(string $reportCode)`
- **SQL Statement:**
  ```sql
  SELECT potential_matches.match_id, potential_matches.similarity_score, potential_matches.created_at,
         items.item_id, items.title, items.description, items.location_found, items.date_found, items.time_found
  FROM public.potential_matches
  INNER JOIN public.lost_reports ON potential_matches.report_id = lost_reports.report_id
  INNER JOIN public.items ON potential_matches.item_id = items.item_id
  WHERE lost_reports.report_code = 'DEMO-LR-001'
    AND lost_reports.status = 'active'
    AND items.status = 'unclaimed'
  ORDER BY potential_matches.similarity_score DESC, potential_matches.created_at DESC;
  ```

### Execution Plan Analysis (`EXPLAIN ANALYZE BUFFERS`)
- **Total Execution Time:** `0.134 ms` (Planning Time: `0.285 ms`)
- **Memory Consumption:** `25 kB` (in-memory quicksort).
- **Execution Plan Breakdown:**
  1. `lost_reports`: Fast `Index Scan` using unique index `lost_reports_report_code_key` ($O(\log N)$).
  2. `potential_matches`: **Sequential Scan (`Seq Scan`)** filtering on `lost_reports.report_id = report_id`.
     - *Root Cause:* The schema defines no secondary index on foreign key `potential_matches.report_id`.
  3. `items`: Fast `Index Scan` using primary key index `items_pkey`.
  4. Root Node: In-memory `Sort` on `similarity_score DESC, created_at DESC`.

### Recommended Index Optimizations & Trade-Off Analysis
1. **Composite Covering Index on `potential_matches`:**
   ```sql
   CREATE INDEX idx_potential_matches_report_score 
   ON public.potential_matches (report_id, similarity_score DESC, created_at DESC);
   ```
   *Impact:* Replaces the `Seq Scan` with an `Index Scan` and **completely eliminates the Sort node**, as matching rows are read in pre-sorted order directly from the B-Tree.
2. **Partial Index on `items` for Public Browsing:**
   ```sql
   CREATE INDEX idx_items_unclaimed_search 
   ON public.items (date_found DESC NULLS LAST, time_found DESC NULLS LAST) 
   WHERE status = 'unclaimed';
   ```
   *Impact:* Optimizes `ItemRepository::searchUnclaimed` while indexing only active inventory.

---

## 8. Important Database Design Considerations

1. **Potential Matches Duplicate Prevention:**
   - The schema lacks a `UNIQUE (report_id, item_id)` constraint on `potential_matches`. While the PHP service cleans up old matches via `deleteByReportId`, concurrent operations or manual inserts can introduce duplicates.
   - *Recommendation:* Add `CONSTRAINT uq_potential_matches_pair UNIQUE (report_id, item_id)`.
2. **Cascading Deletion Rules:**
   - `claims.item_id`, `potential_matches.report_id`, `potential_matches.item_id`, and image tables use `ON DELETE CASCADE`.
   - Routine maintenance must never execute `DELETE` operations, as cascading deletes permanently purge related operational history.
3. **Decoupled Image Metadata:**
   - Physical image files are stored in `storage/`; database tables maintain only metadata and keys.
   - Image upload or retrieval issues are filesystem/cURL concerns, not PostgreSQL engine failures.

---

## 9. Comprehensive Findings & Recommendations Matrix

| Priority | Finding / Area | Recommended Action | Justification |
|---|---|---|---|
| **Immediate (High)** | Role Script Gap | Add `GRANT CONNECT ON DATABASE grp05_lostandfounddb TO lostandfound_app;` | Prevents connection rejection on hardened PostgreSQL clusters |
| **Immediate (High)** | Query Plan Bottleneck | Create composite index `idx_potential_matches_report_score` | Eliminates sequential scan and in-memory quicksort on potential matches |
| **Immediate (High)** | Duplicate Match Risk | Add `CONSTRAINT uq_potential_matches_pair UNIQUE (report_id, item_id)` | Guarantees declarative duplicate prevention at the engine level |
| **Follow-Up (Medium)** | Public Search Index | Create partial index `idx_items_unclaimed_search` on `items` | Accelerates public search queries once catalog exceeds 500 items |
| **Follow-Up (Medium)** | Routine Maintenance Automation | Schedule weekly `ANALYZE` and `VACUUM` under `postgres` or `pg_maintain` | Maintains optimal query planner statistics and prevents MVCC tuple bloat |
| **Follow-Up (Medium)** | Admin Route Protection | Implement presentation-layer session authentication on `/admin/` | Prevents unauthorized admin access if port 8001 is reached over LAN |
| **No Action (Low)** | Image Decoupling Architecture | Preserve current filesystem storage + DB metadata design | Clean architecture; prevents binary blob database bloat |
| **No Action (Low)** | Least-Privilege Immutability | Maintain withholding of `DELETE` on `items`, `lost_reports`, `claims` | Enforces historical integrity and audit compliance |

---

## 10. Google Sheets Activity 5 Tracker Entry

| Column Header | Activity 5 Tracker Value |
|---|---|
| **1. Project** | PUP-SPOT – Campus Lost and Found System (Group 05) |
| **2. Database Inspected** | `grp05_lostandfounddb` (Schema: `public`, PostgreSQL 18.6 MSVC 64-bit on Windows 11) |
| **3. Account and Role Used** | `lostandfound_public` (Public API), `lostandfound_app` (Admin API), `postgres` (DBA Maintenance) |
| **4. Health Check Result** | Healthy — 8 tables verified, 8 serial sequences, 0 lock contentions, 0 deadlocks, 99.55% buffer cache hit ratio, ~8.5 MB footprint |
| **5. Maintenance Performed** | `ANALYZE (VERBOSE)` on all 8 tables; `VACUUM (VERBOSE, ANALYZE)` on `items`, `lost_reports`, `claims`, `potential_matches`; verified dead tuple clearance |
| **6. Query Analyzed** | `PotentialMatchRepository::getByReportCode` (3-table join, status filtering, descending sort) and `ItemRepository::searchUnclaimed` |
| **7. Recommendation Priority** | High Priority — Add `GRANT CONNECT` for admin role, create composite index on `potential_matches (report_id, similarity_score, created_at)`, add unique constraint on match pairs |
| **8. Evidence Folder Link** | `db-maintenance/pupspot/evidence/` and `activity-5/evidence/` |
| **9. Feedback Sent to Owners** | Documented in `reports/pup-spot-maintenance-report.md` (Prepared for official Activity 5 submission / peer exchange) |
| **10. PDF Progress Document** | `docs/PUP_SPOT_Activity_3_Progress_Documentation.pdf` & `group-test-results/activity-5/Group 5 - Activity 5.pdf` (Audited) |
| **11. Last Updated** | November 17, 2026 |

---

## 11. Security & Project Preservation Compliance

- **No Repository Alteration:** The original target group's GitHub repository and clone were preserved without modifications.
- **Zero Credential Exposure:** No passwords, SCRAM-SHA-256 hashes, or API secrets (TextBee, EmailJS) were committed or displayed.
- **Preserved PHP Architecture:** All SQL scripts and performance evaluations adhere strictly to native PHP PDO prepared statements.
- **Non-Destructive Operations:** Routine maintenance relied exclusively on online `ANALYZE` and `VACUUM`. No tables were dropped, truncated, or subjected to `VACUUM FULL`.

---

## 12. Artifact Inventory & Verification Guide

The complete Activity 5 monitoring and maintenance suite is permanently preserved in:
- `db-maintenance/pupspot/`
- `activity-5/`

### Artifact Mapping:
- **`health-inspection/database-information.sql`**: Catalog inventory, 8 tables, sequences, constraints, and secondary index audit.
- **`health-inspection/connection-monitoring.sql`**: Active sessions, connection capacity, buffer cache hit ratio, and lock contention.
- **`health-inspection/database-roles.sql`**: RBAC audit, role grants, column-level privileges, and confidentiality/immutability checks.
- **`log-analysis/log-findings.md`**: Forensic engine log analysis, SCRAM auth rejections, vacuum warnings, and error categorization.
- **`maintenance/analyze.sql`**: Standalone verbose statistics refresh and `pg_stats` verification.
- **`maintenance/vacuum.sql`**: Standalone verbose dead tuple reclamation, MVCC health, and freeze cutoff advance.
- **`performance/selected-query.sql`**: Prepared statements for EXPLAIN and EXPLAIN ANALYZE benchmarks.
- **`performance/execution-plan.md`**: Node-by-node plan breakdown, sequential scan bottleneck analysis, and index trade-offs.
- **`reports/pup-spot-maintenance-report.md`**: Comprehensive Activity 5 Technical Evaluation Report (Sections A–I).
- **`evidence/README.md`**: Execution logs catalog and step-by-step screenshot capture guide for pgAdmin 4 and psql.
