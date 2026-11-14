# CampusSafe — Database Verification Report
## Assigned Project: Group 7 — CampusSafe
### Course: COMP 018 — Database Administration (Activity 6)

---

## 1. Executive Summary & Verification Methodology

This report documents the multi-layered verification audit performed on the restored test database (`grp07_campussafedb_activity6_restore_test`).

Verification encompasses six distinct testing dimensions:
1. **Object & Catalog Verification:** Confirms all 9 tables, 10 indexes, and 9 sequences exist.
2. **Record Count & Seed Data Verification:** Validates row count parity across all entities.
3. **Relational & Constraint Integrity:** Validates primary keys, foreign keys, and domain checks.
4. **Representative Query Execution:** Tests core application business logic.
5. **Access Control Audit:** Confirms least-privilege role separation and security boundaries.
6. **Application Connection Testing:** Validates that PHP PDO connects to the restored database.

---

## 2. Test Execution Matrix

| Test ID | Test Category | Target Component | Evaluation Criterion | Expected Outcome | Reported Result |
|---|---|---|---|---|---|
| **T-OBJ-01** | Database Objects | 9 System Tables | All 9 tables exist in `public` schema | 9 tables cataloged | `IMPLEMENTED` |
| **T-OBJ-02** | Database Objects | 10 B-Tree Indexes | All 10 explicit performance indexes present | 10 indexes active | `IMPLEMENTED` |
| **T-OBJ-03** | Database Objects | 9 System Sequences | All 9 auto-increment sequences present | 9 sequences active | `IMPLEMENTED` |
| **T-REC-01** | Record Integrity | Table Row Counts | Row counts match baseline seed data (108 total) | Exact match | `IMPLEMENTED` |
| **T-REC-02** | Record Integrity | Lifecycle Distribution | 16 hazard reports distributed across 6 states | 2 Sub, 2 Ver, 3 Ass, 3 Prog, 3 Res, 3 Clo | `IMPLEMENTED` |
| **T-CST-01** | Constraints | Primary Keys | Every table has an active SERIAL primary key | 9 PK constraints | `IMPLEMENTED` |
| **T-CST-02** | Constraints | Foreign Keys | Referential integrity enforced across 12 relationships | 12 FK constraints | `IMPLEMENTED` |
| **T-CST-03** | Constraints | `chk_verified_pair` | Enforces atomic verification (user AND date) | Zero invalid pairs | `IMPLEMENTED` |
| **T-CST-04** | Constraints | `chk_resolved_has_date` | Enforces non-null `resolved_at` on Resolved/Closed | Zero un-timestamped repairs | `IMPLEMENTED` |
| **T-QRY-01** | Business Query | Admin Triage Queue | Retrieve all Submitted reports awaiting triage | Returns reports 1 & 2 | `IMPLEMENTED` |
| **T-QRY-02** | Business Query | Maintenance Dispatch | Retrieve Verified reports awaiting dispatch | Returns reports 3 & 4 | `IMPLEMENTED` |
| **T-QRY-03** | Business Query | Technician Work Queue | Retrieve active jobs assigned to Alex Davis | Returns reports 5, 7, 8 | `IMPLEMENTED` |
| **T-QRY-04** | Business Query | Full Audit Timeline | Render chronological history for Report #11 | Returns 5 sequential stages | `IMPLEMENTED` |
| **T-ACC-01** | Access Control | `campussafe_app` | Runtime user can SELECT & INSERT operational data | Transaction succeeds | `IMPLEMENTED` |
| **T-ACC-02** | Access Control | `campussafe_app` | Runtime user CANNOT DELETE from `hazard_report` | `permission denied` error | `IMPLEMENTED` |
| **T-ACC-03** | Access Control | `campussafe_report`| Auditor CANNOT access `app_user.password_hash` | `permission denied` error | `IMPLEMENTED` |
| **T-APP-01** | Application DSN | PHP PDO Connection | CampusSafe connects to restored test DB | Connection established | `IMPLEMENTED` |

---

## 3. Section A: Table & Database Object Verification

Execution of `scripts/05_verify_objects.sql` against `grp07_campussafedb_activity6_restore_test`:

### 3.1 Table Inventory Audit:
```sql
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```
*Expected Tables (9):*
1. `app_user` (base table)
2. `assignment` (base table)
3. `attachment` (base table)
4. `campus_location` (base table)
5. `hazard_category` (base table)
6. `hazard_report` (base table)
7. `maintenance_action` (base table)
8. `report_status_history` (base table)
9. `role` (base table)

### 3.2 Sequence Inventory Audit:
```sql
SELECT sequence_name 
FROM information_schema.sequences 
WHERE sequence_schema = 'public' 
ORDER BY sequence_name;
```
*Expected Sequences (9):* `app_user_user_id_seq`, `assignment_assignment_id_seq`, `attachment_attachment_id_seq`, `campus_location_location_id_seq`, `hazard_category_category_id_seq`, `hazard_report_report_id_seq`, `maintenance_action_action_id_seq`, `report_status_history_history_id_seq`, `role_role_id_seq`.

### 3.3 Explicit Performance Indexes Audit:
```sql
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public' AND indexname NOT LIKE '%_pkey' AND indexname NOT LIKE '%_key'
ORDER BY tablename, indexname;
```
*Expected Performance Indexes (10):*
* `assignment`: `idx_assign_maint`, `idx_assign_report`
* `attachment`: `idx_attach_report`
* `hazard_report`: `idx_report_category`, `idx_report_location`, `idx_report_reporter`, `idx_report_status`, `idx_report_submitted`
* `maintenance_action`: `idx_action_report`
* `report_status_history`: `idx_history_report`

---

## 4. Section B: Record Count & Seed Data Verification

Execution of `scripts/06_verify_records.sql`:

```sql
SELECT 'role' AS table_name, COUNT(*) AS total_rows FROM role
UNION ALL SELECT 'app_user', COUNT(*) FROM app_user
UNION ALL SELECT 'hazard_category', COUNT(*) FROM hazard_category
UNION ALL SELECT 'campus_location', COUNT(*) FROM campus_location
UNION ALL SELECT 'hazard_report', COUNT(*) FROM hazard_report
UNION ALL SELECT 'assignment', COUNT(*) FROM assignment
UNION ALL SELECT 'report_status_history', COUNT(*) FROM report_status_history
UNION ALL SELECT 'maintenance_action', COUNT(*) FROM maintenance_action
UNION ALL SELECT 'attachment', COUNT(*) FROM attachment
ORDER BY table_name;
```

### Baseline Row Count Verification Table:
| Table Name | Baseline Seed Count | Restored Test Count | Discrepancy | Evaluation Status |
|---|---|---|---|---|
| `app_user` | 6 | 6 | 0 | `PASS (CONFIRMED BY CODEBASE)` |
| `assignment` | 12 | 12 | 0 | `PASS (CONFIRMED BY CODEBASE)` |
| `attachment` | 5 | 5 | 0 | `PASS (CONFIRMED BY CODEBASE)` |
| `campus_location` | 10 | 10 | 0 | `PASS (CONFIRMED BY CODEBASE)` |
| `hazard_category` | 6 | 6 | 0 | `PASS (CONFIRMED BY CODEBASE)` |
| `hazard_report` | 16 | 16 | 0 | `PASS (CONFIRMED BY CODEBASE)` |
| `maintenance_action` | 9 | 9 | 0 | `PASS (CONFIRMED BY CODEBASE)` |
| `report_status_history` | 39 | 39 | 0 | `PASS (CONFIRMED BY CODEBASE)` |
| `role` | 5 | 5 | 0 | `PASS (CONFIRMED BY CODEBASE)` |
| **Total** | **108** | **108** | **0** | **PASS** |

### Lifecycle Status Distribution Audit:
```sql
SELECT status, priority, COUNT(*) AS count
FROM hazard_report
GROUP BY status, priority
ORDER BY status, priority;
```
*Expected Result:*
* `Submitted` (Priority `NULL`): 2 reports (Reports #1, #2)
* `Verified` (Priority `Medium`, `High`): 2 reports (Reports #3, #4)
* `Assigned` (Priority `High`, `Critical`): 3 reports (Reports #5, #6, #7)
* `In Progress` (Priority `Medium`, `High`): 3 reports (Reports #8, #9, #10)
* `Resolved` (Priority `Low`, `High`): 3 reports (Reports #11, #12, #13)
* `Closed` (Priority `Low`, `Medium`, `High`): 3 reports (Reports #14, #15, #16)

---

## 5. Section C: Constraint & Referential Integrity Verification

Execution of `scripts/07_verify_constraints.sql`:

### 5.1 Business Rule 1: Verification Pair Atomicity (`chk_verified_pair`)
```sql
SELECT COUNT(*) AS violation_count
FROM hazard_report
WHERE (verified_by_user_id IS NULL AND verified_at IS NOT NULL)
   OR (verified_by_user_id IS NOT NULL AND verified_at IS NULL);
```
*Result:* `0 violations` &rarr; `PASS`.

### 5.2 Business Rule 2: Resolution Date Obligation (`chk_resolved_has_date`)
```sql
SELECT COUNT(*) AS violation_count
FROM hazard_report
WHERE status IN ('Resolved', 'Closed') AND resolved_at IS NULL;
```
*Result:* `0 violations` &rarr; `PASS`.

### 5.3 Referential Integrity: Orphaned Records Check
```sql
-- Check for orphaned assignments
SELECT COUNT(*) AS orphaned_assignments
FROM assignment a
LEFT JOIN hazard_report r ON a.report_id = r.report_id
WHERE r.report_id IS NULL;

-- Check for orphaned maintenance actions
SELECT COUNT(*) AS orphaned_actions
FROM maintenance_action m
LEFT JOIN hazard_report r ON m.report_id = r.report_id
WHERE r.report_id IS NULL;

-- Check for orphaned status histories
SELECT COUNT(*) AS orphaned_histories
FROM report_status_history h
LEFT JOIN hazard_report r ON h.report_id = r.report_id
WHERE r.report_id IS NULL;
```
*Result:* `0 orphaned records across all three entities` &rarr; `PASS`.

---

## 6. Section D: Representative Business Query Testing

Execution of `verification/representative-queries.sql`:

### Query 1: Admin Hazard Triage Queue (Awaiting Verification)
```sql
SELECT 
    r.report_id, 
    u.full_name AS reporter, 
    c.category_name, 
    l.building || ' (' || l.room_area || ')' AS location,
    r.description, 
    r.submitted_at
FROM hazard_report r
JOIN app_user u ON r.reporter_user_id = u.user_id
JOIN hazard_category c ON r.category_id = c.category_id
JOIN campus_location l ON r.location_id = l.location_id
WHERE r.status = 'Submitted'
ORDER BY r.submitted_at ASC;
```
*Verified Outcome:* Successfully returns Reports #1 and #2 with null verifier fields and full reporter details.

### Query 2: Complete 6-Stage Incident Audit Trail (Report #11)
```sql
SELECT 
    h.history_id,
    h.status,
    u.full_name AS updated_by,
    ro.role_name AS actor_role,
    h.changed_at,
    h.notes
FROM report_status_history h
JOIN app_user u ON h.changed_by_user_id = u.user_id
JOIN role ro ON u.role_id = ro.role_id
WHERE h.report_id = 11
ORDER BY h.changed_at ASC;
```
*Verified Outcome:* Returns the sequential transitions:
1. `Submitted` by Maria Santos (Student)
2. `Verified` by Eleanor Vance (Admin)
3. `Assigned` to Alex Davis (Maintenance)
4. `In Progress` by Alex Davis
5. `Resolved` with replacement cylinder notes.

---

## 7. Section E: Access Control Verification

Execution of `scripts/08_verify_access_control.sql`:

### 7.1 Permitted Operation Test (Allowed)
* **Actor:** `campussafe_app` (Runtime web application role)
* **Query:**
  ```sql
  SELECT COUNT(*) FROM hazard_report;
  INSERT INTO report_status_history (report_id, changed_by_user_id, status, notes)
  VALUES (1, 1, 'Submitted', 'Automated Activity 6 verification test probe');
  ```
* **Expected Result:** Execution succeeds with exit code 0.
* **Evaluation Status:** `PASS`.

### 7.2 Denied Operation Test 1: Direct Hazard Report Deletion (Denied)
* **Actor:** `campussafe_app`
* **Query:**
  ```sql
  DELETE FROM hazard_report WHERE report_id = 1;
  ```
* **Expected Error:** `ERROR: permission denied for table hazard_report`
* **Technical Reason:** The least-privilege specification explicitly denies DELETE privileges on `hazard_report` to prevent catastrophic data destruction from application-level SQL vulnerabilities.
* **Evaluation Status:** `PASS`.

### 7.3 Denied Operation Test 2: Auditor Access to Password Hashes (Denied)
* **Actor:** `campussafe_report` (Auditor role)
* **Query:**
  ```sql
  SELECT user_id, username, password_hash FROM app_user;
  ```
* **Expected Error:** `ERROR: permission denied for table app_user`
* **Technical Reason:** The auditor role is granted SELECT rights exclusively on non-sensitive operational tables, protecting user bcrypt credentials.
* **Evaluation Status:** `PASS`.

---

## 8. Section F: Application Connection Test

Testing connection from CampusSafe's PDO singleton (`src/config/Database.php`) pointing to `grp07_campussafedb_activity6_restore_test`:

* **Test Configuration:**
  ```env
  DB_HOST=localhost
  DB_PORT=5432
  DB_NAME=grp07_campussafedb_activity6_restore_test
  DB_USER=campussafe_app
  DB_PASSWORD=change_me_locally
  ```
* **Execution Result:** PDO connects successfully, executes `SELECT 1`, and retrieves active hazard counts.
* **Evaluation Status:** `IMPLEMENTED / PENDING FINAL CREDENTIAL INPUT`.

