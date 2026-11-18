# INCIDENT DESIGN SHEET #2 (PUBLIC INCIDENT BRIEF)

**Incident ID:** G07-INC2  
**Related Flaw ID:** G07-F2  
**Project Owner:** Group 7 – CAMPUSAFE  
**Designer Group:** Group 12 – iBarangay  
**Variant:** Schema Design, Referential Integrity & Audit Retention  
**Related Activity:** Activity 3 & 4 (Database Schema & Access Control)  
**Difficulty:** Medium  
**Estimated Investigation Time:** 25 Minutes  

---

### PUBLIC INCIDENT BRIEF

#### Incident Symptoms
A campus facilities manager executed a routine data cleanup operation in the administration panel to remove a duplicate or obsolete test hazard report. Shortly thereafter, the campus compliance officer discovered that all historical dispatch assignments, technician work logs, parts replacement entries, and uploaded photographic inspection evidence associated with that incident had completely disappeared from the system. When compliance auditors attempted to reconstruct the incident timeline, no trace of the historical maintenance actions or status transitions could be found anywhere in the database.

#### Expected Observable Behavior
When an investigator queries the database or reviews table relationships:
1. Executing a `DELETE` statement against an old record in `hazard_report` executes silently without triggering any foreign key violation, and immediately causes corresponding rows in `report_status_history`, `maintenance_action`, `assignment`, and `attachment` to be permanently removed.
2. Querying constraint definitions in `pg_constraint` reveals that foreign keys referencing `hazard_report(report_id)` specify cascading behavior rather than restrictive integrity rules.

#### Evidence Available to Owner Group
Investigators may inspect the following evidence sources:
- PostgreSQL system catalogs:
  - `pg_constraint` (inspecting `confdeltype` on foreign keys referencing `hazard_report`)
  - `information_schema.referential_constraints`
- Activity 3 Schema DDL and Activity 4 documentation:
  - `database/01_schema.sql` (Lines 105–160)
  - `progress-report/ACTIVITY_03_PROGRESS_REPORT.md`
  - `progress-report/ACTIVITY_04_ACCESS_CONTROL_REPORT.md`
- Row counts and transaction histories across child tables (`report_status_history`, `maintenance_action`, `assignment`, `attachment`).

---
*Note: This public document contains observable symptoms only. Technical root causes, fault scripts, and reset procedures are maintained privately in the instructor answer pack.*
