# INCIDENT DESIGN SHEET #5 (PUBLIC INCIDENT BRIEF)

**Incident ID:** G07-INC5  
**Related Flaw ID:** G07-F5  
**Project Owner:** Group 7 – CAMPUSAFE  
**Designer Group:** Group 12 – iBarangay  
**Variant:** Schema Normalization, Check Constraints & Data Quality  
**Related Activity:** Activity 3 & 5 (Schema Normalization & Data Integrity Constraints)  
**Difficulty:** Easy  
**Estimated Investigation Time:** 15 Minutes  

---

### PUBLIC INCIDENT BRIEF

#### Incident Symptoms
Campus safety dispatchers report two recurring operational anomalies:
1. When creating new hazard reports or filtering incidents by location, administrators encounter duplicate entries in dropdown menus representing the exact same physical building, floor, and room (e.g. three identical entries for "Main Academic Building", "3rd Floor", "Room 302"), causing incidents in the same room to be split across different records.
2. Maintenance staff reviewing the dispatch queue report encountering verified hazard reports that completely lack priority ratings (`priority` is blank/empty). Without priority classifications, emergency response teams cannot determine which verified incidents represent urgent safety threats versus routine maintenance.

#### Expected Observable Behavior
When investigators inspect the database constraints and table data:
1. Inserting identical location values into `campus_location` succeeds without generating a duplicate key violation. Querying `campus_location` reveals duplicate physical rooms with distinct surrogate `location_id` keys.
2. Updating or transitioning a report status to `'Verified'` with `priority = NULL` succeeds without constraint error, leaving verified records without triage ratings.
3. Reviewing table constraints in `pg_constraint` reveals that `campus_location` lacks composite uniqueness on `(building, floor, room_area)`, and `hazard_report` lacks a conditional `CHECK` constraint enforcing priority on verified reports.

#### Evidence Available to Owner Group
Investigators may inspect the following evidence sources:
- PostgreSQL constraint and column catalogs:
  - `pg_constraint`
  - `information_schema.columns`
  - `information_schema.table_constraints`
- Table data inspection queries:
  - `SELECT building, floor, room_area, COUNT(*) FROM campus_location GROUP BY building, floor, room_area HAVING COUNT(*) > 1;`
  - `SELECT report_id, status, priority FROM hazard_report WHERE status = 'Verified' AND priority IS NULL;`
- Activity 3 Schema DDL:
  - `database/01_schema.sql` (Lines 66–73, 87–90)

---
*Note: This public document contains observable symptoms only. Technical root causes, fault scripts, and reset procedures are maintained privately in the instructor answer pack.*
