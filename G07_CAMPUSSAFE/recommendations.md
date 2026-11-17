# Activity 5: Database Maintenance, Health & Optimization Recommendations
## CampusSafe: Campus Hazard & Safety Reporting System

**Course:** COMP 018 — Database Administration  
**Group:** Group 7  
**Database Name:** `grp07_campussafedb`  
**Schema:** `public`  
**Evaluation Date:** November 17, 2026  
**Documented DBMS:** PostgreSQL 14+ (Verified Environment: PostgreSQL 14.24)  
**Host Runtime DBMS:** PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35228, 64-bit  
**Evaluator:** Senior Database Administrator & Strategic Planning Team (Group 7 DBA Team)  

---

## 1. Executive Summary & Purpose

This document synthesizes the operational, security, maintenance, and query performance findings from the Activity 5 evaluation of **CampusSafe** (`grp07_campussafedb`). Each recommendation is strictly supported by live catalog evidence, query plan benchmarking, and security audits.

Recommendations are structured using the formal COMP 018 analytical framework:
1. **Observation:** What was measured or detected in the live database.
2. **Technical Impact:** Why the observation matters for system reliability, performance, or security.
3. **Actionable Remediation:** Specific SQL, configuration, or operational procedure to implement.
4. **Implementation Urgency:** Categorized as **Immediate**, **Operational**, or **Future Growth Milestone**.

---

## 2. Categorized Recommendations Matrix

### 2.1 Database Health & Storage Management

#### Recommendation 1: Autovacuum Threshold Tuning for High-Churn Lifecycle Tables
- **Observation:** `hazard_report` and `app_user` accumulated dead tuples (2 dead tuples each) from administrative status transitions and user profile updates. While dead tuples were 100% reclaimed during this evaluation, the default PostgreSQL autovacuum threshold (`autovacuum_vacuum_scale_factor = 0.20`) requires a table to experience 20% tuple churn before triggering automatic cleanup.
- **Technical Impact:** On high-frequency tables like `hazard_report` and `report_status_history`, a 20% threshold allows significant page bloat to accumulate before autovacuum intervenes, degrading buffer hit ratios and increasing I/O cost.
- **Actionable Remediation:** Tune autovacuum scale factors specifically on active transaction tables to trigger cleanup at 5% churn:
  ```sql
  ALTER TABLE public.hazard_report SET (
      autovacuum_vacuum_scale_factor = 0.05,
      autovacuum_vacuum_threshold = 20,
      autovacuum_analyze_scale_factor = 0.02
  );

  ALTER TABLE public.report_status_history SET (
      autovacuum_vacuum_scale_factor = 0.05,
      autovacuum_vacuum_threshold = 50,
      autovacuum_analyze_scale_factor = 0.02
  );
  ```
- **Urgency:** **Operational (Recommended for Production Deployment)**.

---

### 2.2 Query Performance & Indexing Optimization

#### Recommendation 2: Postpone Composite Indexing Until Dataset Reaches Scale
- **Observation:** Query 1 (`SELECT * FROM hazard_report WHERE status = 'Submitted' ORDER BY submitted_at DESC`) currently uses a sequential scan taking 0.059 ms. Forcing an index scan via `idx_report_status` increased execution time to 0.104 ms.
- **Technical Impact:** On the current seed volume (17 rows), adding a composite index `(status, submitted_at DESC)` would consume extra disk space (32 kB) and add write overhead on every `INSERT` and `UPDATE` without delivering any measurable speedup.
- **Actionable Remediation:** Do not add composite indexes prematurely. Monitor `hazard_report` row volume. When active reports exceed **10,000 records**, apply the following concurrent index creation:
  ```sql
  CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_report_status_submitted 
  ON public.hazard_report (status, submitted_at DESC);
  ```
- **Urgency:** **Future Growth Milestone (Scale Dependent)**.

#### Recommendation 3: Add Covering Index on User Activity Audit Foreign Key
- **Observation:** Catalog analysis of `information_schema.table_constraints` revealed that while `report_status_history.report_id` is indexed via `idx_history_report`, the foreign key `report_status_history.changed_by_user_id` lacks a covering secondary B-tree index.
- **Technical Impact:** When compliance auditors query all status changes performed by a specific administrator or technician (`WHERE changed_by_user_id = :uid`), PostgreSQL must execute a sequential scan across all historical audit records.
- **Actionable Remediation:** Create a secondary index concurrently:
  ```sql
  CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_history_changed_by 
  ON public.report_status_history (changed_by_user_id);
  ```
- **Urgency:** **Operational (Medium-Term Enhancement)**.

---

### 2.3 Security & Access Control Enforcement

#### Recommendation 4: Maintain the Maintenance Privilege Boundary
- **Observation:** Running `VACUUM` or `ANALYZE` under the application runtime login account (`campussafe_app`) triggers a PostgreSQL permission warning (`permission denied to vacuum "hazard_report", skipping it`).
- **Technical Impact:** In PostgreSQL 14+, maintenance requires table ownership or superuser status. Elevating `campussafe_app` to table owner or superuser would severely violate the Principle of Least Privilege, granting the web application unrestricted capability to drop tables, alter schema, or bypass audit controls.
- **Actionable Remediation:** Keep `campussafe_app` strictly as a non-owner transactional user. Execute administrative maintenance exclusively via:
  1. The automated PostgreSQL `autovacuum` background worker daemon, OR
  2. A dedicated administrative cron task / scheduled script executing as `postgres` or an authorized DBA account during maintenance windows.
- **Urgency:** **Immediate & Architectural (Strictly Enforced)**.

#### Recommendation 5: Enforce Dynamic Database Passwords via `.env`
- **Observation:** `Database.php` securely loads credentials via `Env::get()`. However, local developer setups may default to placeholder passwords (`change_me_locally`).
- **Technical Impact:** Using default passwords across development and staging environments risks credential exposure.
- **Actionable Remediation:** Ensure `.env` is permanently excluded from version control in `.gitignore` (already verified) and enforce high-entropy SCRAM-SHA-256 passwords across all deployment instances.
- **Urgency:** **Immediate (Standard Practice)**.

---

### 2.4 Operational Maintenance Scheduling

#### Recommendation 6: Automated Nightly Maintenance Job
- **Observation:** While autovacuum handles normal operational churn, long-running database health benefits from routine statistics collection and bloat prevention.
- **Technical Impact:** Regular off-peak statistics updates guarantee that the query planner maintains accurate histograms even after large batch updates or archiving.
- **Actionable Remediation:** Configure a scheduled task (Windows Task Scheduler / Linux cron) running nightly at 02:00 AM:
  ```bat
  :: Nightly CampusSafe Maintenance Script
  "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d grp07_campussafedb -f "db-maintenance\sql\05_analyze.sql"
  "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d grp07_campussafedb -f "db-maintenance\sql\06_vacuum.sql"
  ```
- **Urgency:** **Operational Best Practice**.

---

## 3. Summary & Roadmap

| Recommendation | Scope | Implementation Method | Impact on CampusSafe | Urgency |
|---|---|---|---|---|
| **R1: Autovacuum Tuning** | Storage / Health | `ALTER TABLE ... SET (autovacuum_scale_factor = 0.05)` | Prevents table bloat on lifecycle tables | Operational |
| **R2: Future Composite Indexing** | Query Tuning | `CREATE INDEX CONCURRENTLY ... (status, submitted_at DESC)` | Eliminates Quicksort at 10,000+ reports | Milestone |
| **R3: History User FK Index** | Query Tuning | `CREATE INDEX CONCURRENTLY ... (changed_by_user_id)` | Accelerates user-specific audit queries | Operational |
| **R4: Maintenance Boundary** | Security / RBAC | Preserve `postgres` ownership; keep `campussafe_app` unprivileged | Protects schema against web exploits | Immediate |
| **R5: Environment Credentials** | Security | Enforce non-default SCRAM passwords in `.env` | Prevents credential compromise | Immediate |
| **R6: Nightly Scheduled Jobs** | Operations | Windows Task Scheduler / Cron executing SQL scripts | Maintains optimal query planner statistics | Operational |
