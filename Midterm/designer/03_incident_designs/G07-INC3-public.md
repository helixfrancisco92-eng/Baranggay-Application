# INCIDENT DESIGN SHEET #3 (PUBLIC INCIDENT BRIEF)

**Incident ID:** G07-INC3  
**Related Flaw ID:** G07-F3  
**Project Owner:** Group 7 – CAMPUSAFE  
**Designer Group:** Group 12 – iBarangay  
**Variant:** Database Triggers, State Auditing & Maintenance  
**Related Activity:** Activity 3 & 5 (Database Triggers & Maintenance Monitoring)  
**Difficulty:** Medium  
**Estimated Investigation Time:** 25 Minutes  

---

### PUBLIC INCIDENT BRIEF

#### Incident Symptoms
During a scheduled weekend maintenance window, a database administrator executed direct SQL update commands to transition a batch of pending hazard reports to "In Progress" status following an emergency facility dispatch. When the campus safety officer generated the weekly compliance audit report on Monday morning, none of the status transitions appeared in the incident timeline. The report history showed a blank gap between initial submission and eventual resolution, with no record of who modified the status or when the transition occurred.

#### Expected Observable Behavior
When investigators test status modifications:
1. Executing an `UPDATE` on `hazard_report.status` directly via `psql` modifies the status in `hazard_report`, but leaves `report_status_history` completely empty with zero new rows inserted.
2. Querying PostgreSQL trigger catalogs confirms that no active database triggers are attached to `hazard_report` to listen for column updates.
3. Reviewing table bloat metrics reveals dead tuple accumulation on `hazard_report` without automated change tracking or trigger-driven maintenance.

#### Evidence Available to Owner Group
Investigators may inspect the following evidence sources:
- PostgreSQL trigger catalogs:
  - `pg_trigger`
  - `information_schema.triggers`
- Table data and record transition timestamps:
  - `SELECT * FROM report_status_history WHERE report_id = ...;`
  - `SELECT report_id, status, submitted_at, resolved_at FROM hazard_report;`
- Application controller code and models:
  - `src/models/Report.php` (inspecting where status history inserts originate)
- Activity 5 Maintenance & Monitoring reports:
  - `progress-report/ACTIVITY_05_MAINTENANCE_MONITORING_REPORT.md`

---
*Note: This public document contains observable symptoms only. Technical root causes, fault scripts, and reset procedures are maintained privately in the instructor answer pack.*
