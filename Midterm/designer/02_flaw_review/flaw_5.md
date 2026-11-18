# FLAW #5: Missing Candidate Key Uniqueness on Physical Locations & Unenforced Verification Priority

**Flaw ID:** G07-F5  
**Project Owner:** Group 7 – CAMPUSAFE  
**Reported By:** Group 12 – iBarangay  
**Affected Area:** Schema Normalization, Check Constraints & Data Quality  
**Related Activity:** Activity 3 & 5 (Schema Normalization & State Machine Verification)  

---

### Description

During an exhaustive schema integrity review of `database/01_schema.sql`, two related data quality and schema constraint omissions were identified:

1. **Missing Candidate Key Uniqueness on `campus_location`:**
   In `database/01_schema.sql` (lines 66–73), the master table `campus_location` defines a surrogate primary key: `location_id SERIAL PRIMARY KEY`. However, the schema completely omits a composite `UNIQUE` constraint on the natural candidate key `(building, floor, room_area)`.
   Because no business-level uniqueness is enforced by PostgreSQL, multiple distinct rows representing the exact same physical campus location (e.g., three separate records for "Engineering Building", "2nd Floor", "Room 204") can be repeatedly inserted into the database with different `location_id` values. This leads to duplicate entries in user dropdown menus, fragmented reporting, and inconsistent maintenance histories for physical rooms.

2. **Unenforced Verification Priority on `hazard_report`:**
   In `database/01_schema.sql` (lines 87–90), column `priority` is declared as nullable `VARCHAR(20) CHECK (priority IN ('Low', 'Medium', 'High', 'Critical'))`.
   While leaving `priority` nullable at initial submission (`status = 'Submitted'`) is valid because reporters do not assign priority, the schema contains **no conditional check constraint** requiring `priority` to be populated once a report transitions to `'Verified'`, `'Assigned'`, or `'In Progress'`. Consequently, an administrator or API call can mark a report as `'Verified'` while leaving `priority` as `NULL`. This creates untriaged verified work orders that fail to appear in priority dispatch queues.

---

### Evidence

- **Repository File:** `grp07-campussafe/database/01_schema.sql` (Lines 66–73, 87–90)
  ```sql
  -- Lines 66-73
  CREATE TABLE campus_location (
      location_id          SERIAL PRIMARY KEY,
      building             VARCHAR(120) NOT NULL,
      floor                VARCHAR(30),
      room_area            VARCHAR(120) NOT NULL,
      location_description TEXT,
      is_active            BOOLEAN NOT NULL DEFAULT TRUE
  );

  -- Lines 87-90
  priority VARCHAR(20)
      CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')),
  status VARCHAR(30) NOT NULL DEFAULT 'Submitted'
      CHECK (status IN ('Submitted', 'Verified', 'Assigned', 'In Progress', 'Resolved', 'Closed')),
  ```
- **Actual Database Object:** Tables `campus_location` and `hazard_report`.
- **SQL Command / Inspection Method 1 (Duplicate Locations):**
  ```sql
  SELECT conname, contype, pg_get_constraintdef(oid) 
  FROM pg_constraint 
  WHERE conrelid = 'campus_location'::regclass;
  ```
  *Actual Result:* Only `campus_location_pkey (PRIMARY KEY (location_id))` is present. Zero `UNIQUE` constraints exist for `(building, floor, room_area)`.
- **SQL Command / Inspection Method 2 (Verified Reports with NULL Priority):**
  ```sql
  SELECT report_id, status, priority, submitted_at 
  FROM hazard_report 
  WHERE status = 'Verified' AND priority IS NULL;
  ```
  *Actual Result:* Query executes and returns reports that bypassed triage categorization without triggering any constraint violation.
- **Screenshot / Evidence File:** Referenced in `midterm/evidence/designer/G07_F5_constraints_evidence.txt`.
- **Baseline Comparison:** `HOW_IT_WORKS.md` Section 3 mandates that verification by an administrator consists of assigning an official severity priority to guide maintenance response times. The database schema fails to enforce this requirement at the engine level.

---

### Impact

- **Data Quality & Relational Anomaly:** Duplicate physical locations fragment incident histories. Technicians reviewing reports for "Room 204" will see only a subset of tickets because other reports point to alternate duplicate `location_id` records.
- **Operational Dispatch Failure:** Verified hazard reports with `NULL` priority cannot be sorted or prioritized in technician dispatch queues, leaving critical life-safety hazards (e.g. gas leaks, structural fractures) unaddressed alongside minor cosmetic issues.

---

### Severity

**Medium** (Confirmed Flaw)

---

### Recommended Fix

1. **Location Uniqueness Remediation:**
   - De-duplicate existing records in `campus_location` by updating references in `hazard_report` to the lowest primary `location_id`.
   - Purge redundant duplicate rows from `campus_location`.
   - Add a composite `UNIQUE (building, floor, room_area)` constraint.
2. **Conditional Priority Constraint Remediation:**
   - Backfill existing verified reports holding `NULL` priority with default `'Medium'`.
   - Add a conditional check constraint: `CHECK (status NOT IN ('Verified', 'Assigned', 'In Progress', 'Resolved', 'Closed') OR priority IS NOT NULL)`.

```sql
-- Step 1: Re-point foreign keys in hazard_report to master location ID
WITH ranked_locations AS (
    SELECT location_id,
           FIRST_VALUE(location_id) OVER (PARTITION BY building, floor, room_area ORDER BY location_id) AS keep_id,
           ROW_NUMBER() OVER (PARTITION BY building, floor, room_area ORDER BY location_id) AS rn
    FROM campus_location
)
UPDATE hazard_report hr
SET location_id = rl.keep_id
FROM ranked_locations rl
WHERE hr.location_id = rl.location_id AND rl.rn > 1;

-- Step 2: Remove duplicate location rows
WITH duplicates AS (
    SELECT location_id,
           ROW_NUMBER() OVER (PARTITION BY building, floor, room_area ORDER BY location_id) AS rn
    FROM campus_location
)
DELETE FROM campus_location
WHERE location_id IN (SELECT location_id FROM duplicates WHERE rn > 1);

-- Step 3: Enforce composite UNIQUE constraint
ALTER TABLE campus_location 
ADD CONSTRAINT uq_campus_location_bldg_floor_room 
UNIQUE (building, floor, room_area);

-- Step 4: Backfill existing NULL priorities on verified reports
UPDATE hazard_report 
SET priority = 'Medium' 
WHERE status IN ('Verified', 'Assigned', 'In Progress', 'Resolved', 'Closed') AND priority IS NULL;

-- Step 5: Enforce conditional CHECK constraint on priority
ALTER TABLE hazard_report 
ADD CONSTRAINT chk_verified_report_requires_priority 
CHECK (status NOT IN ('Verified', 'Assigned', 'In Progress', 'Resolved', 'Closed') OR priority IS NOT NULL);
```

---

### Verification

1. **Negative Test 1 (Duplicate Location Blocked):**
   ```sql
   INSERT INTO campus_location (building, floor, room_area) VALUES ('Science Building', '3rd Floor', 'Room 305');
   INSERT INTO campus_location (building, floor, room_area) VALUES ('Science Building', '3rd Floor', 'Room 305');
   ```
   *Expected Result:* `ERROR: duplicate key value violates unique constraint "uq_campus_location_bldg_floor_room" (SQLSTATE 23505)`.
2. **Negative Test 2 (Verified Report without Priority Blocked):**
   ```sql
   UPDATE hazard_report SET status = 'Verified', priority = NULL WHERE report_id = 1;
   ```
   *Expected Result:* `ERROR: new row for relation "hazard_report" violates check constraint "chk_verified_report_requires_priority" (SQLSTATE 23514)`.
3. **Positive Test (Valid Verification with Priority):**
   ```sql
   UPDATE hazard_report SET status = 'Verified', priority = 'High' WHERE report_id = 1;
   ```
   *Expected Result:* `UPDATE 1` (Operation succeeds cleanly).
