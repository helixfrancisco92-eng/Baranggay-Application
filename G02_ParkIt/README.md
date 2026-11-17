# Activity 5 — Group 2: Park-It Smart Parking Lot Management System

This directory contains the Activity 5 database maintenance, health monitoring, log review, and query optimization audit conducted by **bwisIT Solutions (Group 8)** targeting the **Group 2 (Park-It)** PostgreSQL database (`grp_parkitdb`).

## Monitored System Summary

- **Target Group:** Group 2
- **Project Name:** Park It: Smart Parking Lot Management System
- **Repository URL:** `https://github.com/HelloP0/PARK-IT-DATABASE-MANAGEMENT-SYSTEM`
- **Database Name:** `grp_parkitdb` (Schema: `public`)
- **Database Engine:** PostgreSQL 18.6 on x86_64-windows (MSVC 64-bit)
- **Application Architecture:** PHP 8.2+ Backend with Native PDO PostgreSQL, HTML5/CSS3/JavaScript Frontend
- **Audited Roles:** `parkit_app` (Application Runtime / Member of `parkit_runtime_grp`), `postgres` (DBA Maintenance)
- **Physical Size:** 8,446 kB across 5 base tables, 9 B-tree indexes, and 5 serial sequences
- **Buffer Cache Hit Ratio:** 99.9964% (249,593 hits / 9 reads)
- **Transaction Efficiency:** 3,769 commits / 29 rollbacks (99.24% commit efficiency, 0 deadlocks)
- **Maintenance Outcome:** 100% dead tuple reclamation (40/40 dead tuples removed from `parking_zone` and `vehicle`) via standalone `VACUUM (VERBOSE, ANALYZE)`

## Directory Structure & Navigational Index

- [BLOCKERS.md](BLOCKERS.md) — Scope confirmation, authorization status, and environment boundary notes.
- [health-check.sql](health-check.sql) — Tailored diagnostic health check queries for `grp_parkitdb`.
- [health-evidence.txt](health-evidence.txt) — Live catalog telemetry, database size, object counts, and runtime permission boundary verification.
- [maintenance.sql](maintenance.sql) — Standardized, non-destructive routine maintenance procedure script.
- [maintenance-evidence.txt](maintenance-evidence.txt) — Detailed pre- and post-maintenance tuple statistics showing complete removal of 33 dead tuples on `parking_zone` and 7 dead tuples on `vehicle`.
- [query-plan.sql](query-plan.sql) — 4 real application queries profiled with `EXPLAIN (ANALYZE, BUFFERS)`, plus optimizer forced index diagnostic and foreign key audit.
- [query-plan-evidence.txt](query-plan-evidence.txt) — Execution plans, actual timing, buffer usage, optimizer diagnostic analysis, and foreign key indexing audit.
- [log-review.md](log-review.md) — PostgreSQL engine and PHP application log analysis (245 lines reviewed, 0 deadlocks).
- [report.md](report.md) — Comprehensive academic Activity 5 evaluation report.
- [recommendations.md](recommendations.md) — Prioritized, actionable architectural, indexing, and security recommendations.
- [evidence-index.md](evidence-index.md) — Comprehensive evidence catalog and artifact traceability matrix.
- [select-recount.sql](select-recount.sql) — Standalone single SELECT query file for verification automation runner.
