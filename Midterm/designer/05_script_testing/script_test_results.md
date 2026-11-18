# Script Testing & Disposable Database Execution Results

**Course:** COMP 018 — Database Administration  
**Designer Group:** Group 12 — iBarangay  
**Evaluated Project:** Group 7 — CAMPUSAFE  
**Target Disposable Database:** `campussafe_midterm_test` (cloned from `grp07_campussafedb`)  
**PostgreSQL Version:** 18.6 on x86_64 Windows  
**Test Date:** November 7, 2026  

---

## 1. Disposable Database Spin-Up Protocol

In strict compliance with assessment safety directives, all fault injection, diagnostic querying, and reset procedures were tested exclusively on an isolated disposable database instance. The production and original databases were never modified.

### Provisioning Command:
```powershell
# Cloned using template flag (-T) to create an exact, disposable copy
createdb -U postgres -h localhost -p 5432 -T grp07_campussafedb campussafe_midterm_test
```
*Baseline Status:* Successfully cloned schema, 9 relational tables, 10 B-tree indexes, check constraints, sequences, and sample seed records.

---

## 2. Test Execution Log per Incident Scenario

### Scenario 1: G07-INC1 (Role Privilege Tampering on `app_user`)
- **Initial Baseline:** `app_runtime_grp` held table-wide `UPDATE` on `public.app_user` with zero column-level restrictions.
- **Fault Script Executed:** `G07-INC1-fault.sql`
  - Output: `UPDATE 1` for role escalation (`user_id = 2` set to `role_id = 1`); `UPDATE 1` for suspension (`user_id = 1` set to `'suspended'`).
  - Fault Reproduction: **CONFIRMED**. Regular runtime user successfully tampered with user roles and account statuses.
- **Reset Script Executed:** `G07-INC1-reset.sql`
  - Output: `REVOKE UPDATE`, `GRANT UPDATE (full_name, email, password_hash)`. User roles and statuses reverted to baseline.
  - Post-Reset Negative Test: `SET ROLE campussafe_app; UPDATE app_user SET role_id = 1 WHERE user_id = 2;` $\rightarrow$ `ERROR: permission denied for column "role_id" of relation "app_user" (SQLSTATE 42501)`.
  - Post-Reset Positive Test: `SET ROLE campussafe_app; UPDATE app_user SET full_name = 'Juan Dela Cruz' WHERE user_id = 2;` $\rightarrow$ `UPDATE 1`.
- **Verdict:** **PASS (100% Verified on Disposable DB)**.

---

### Scenario 2: G07-INC2 (Cascading Deletions Purging Audit History)
- **Initial Baseline:** Foreign keys from child tables referencing `hazard_report` configured with `ON DELETE CASCADE`.
- **Fault Script Executed:** `G07-INC2-fault.sql`
  - Output: Inserted test report `report_id = 9999` with status history and attachment. Executed `DELETE FROM hazard_report WHERE report_id = 9999;`.
  - Fault Reproduction: **CONFIRMED**. Query returned `count = 0` for both child tables; child records vanished.
- **Reset Script Executed:** `G07-INC2-reset.sql`
  - Output: Altered 4 foreign keys to `ON DELETE RESTRICT`. Added `is_deleted` and `deleted_at` columns.
  - Post-Reset Negative Test: `DELETE FROM hazard_report WHERE report_id = 1;` $\rightarrow$ `ERROR: update or delete on table "hazard_report" violates foreign key constraint "fk_status_history_report" on table "report_status_history" (SQLSTATE 23503)`.
  - Post-Reset Positive Test: `UPDATE hazard_report SET is_deleted = TRUE, deleted_at = NOW() WHERE report_id = 1;` $\rightarrow$ Succeeded cleanly; child rows remained intact.
- **Verdict:** **PASS (100% Verified on Disposable DB)**.

---

### Scenario 3: G07-INC3 (Missing Database Trigger for Status History Auditing)
- **Initial Baseline:** `pg_trigger` catalog showed `0 rows` for user triggers on `hazard_report`. Status logging relied on PHP.
- **Fault Script Executed:** `G07-INC3-fault.sql`
  - Output: Dropped any existing trigger; executed direct `UPDATE hazard_report SET status = 'In Progress' WHERE report_id = 1;`.
  - Fault Reproduction: **CONFIRMED**. Report status updated, but `report_status_history` count remained unchanged (0 audit rows generated).
- **Reset Script Executed:** `G07-INC3-reset.sql`
  - Output: Created trigger function `trg_log_hazard_status_change()` and trigger `trg_hazard_report_status_audit`. Reconciled missing history row. Ran `VACUUM (ANALYZE)`.
  - Post-Reset Test: Direct SQL update `UPDATE hazard_report SET status = 'Resolved', resolved_at = NOW() WHERE report_id = 1;` $\rightarrow$ Automatically inserted historical audit row showing transition to `'Resolved'`.
- **Verdict:** **PASS (100% Verified on Disposable DB)**.

---

### Scenario 4: G07-INC4 (Backup Operator Privilege Fragility & Recovery Gap)
- **Initial Baseline:** `campussafe_backup` held standard `SELECT` on existing public tables, but lacked `pg_read_all_data` pre-defined role.
- **Fault Script Executed:** `G07-INC4-fault.sql`
  - Output: Revoked `SELECT` on `report_status_history` and `attachment` from `app_backup_grp`.
  - Fault Reproduction: **CONFIRMED**. Running `pg_dump -U campussafe_backup -Fc -d campussafe_midterm_test` produced:
    `pg_dump: error: query failed: ERROR: permission denied for table report_status_history`. Exit code: `1`.
- **Reset Script Executed:** `G07-INC4-reset.sql`
  - Output: Restored `SELECT` on all tables/sequences, configured default privileges, granted `pg_read_all_data`.
  - Post-Reset Test: Executed `pg_dump -U campussafe_backup -Fc -f test.dump campussafe_midterm_test` $\rightarrow$ Exit code `0`. `pg_restore --list test.dump` successfully verified TOC integrity.
- **Verdict:** **PASS (100% Verified on Disposable DB)**.

---

### Scenario 5: G07-INC5 (Duplicate Physical Locations & Unenforced Verification Priority)
- **Initial Baseline:** `campus_location` had no candidate key constraint; `hazard_report` had no conditional check on priority.
- **Fault Script Executed:** `G07-INC5-fault.sql`
  - Output: Dropped unique and check constraints; inserted duplicate rows for "Main Academic Building, 3rd Floor, Room 302"; updated report to `'Verified'` with `priority = NULL`.
  - Fault Reproduction: **CONFIRMED**. Duplicate locations created; untriaged verified report created.
- **Reset Script Executed:** `G07-INC5-reset.sql`
  - Output: Re-pointed foreign keys, purged duplicate locations, added `UNIQUE (building, floor, room_area)`, backfilled NULL priorities, added `CHECK (status NOT IN ('Verified', ...) OR priority IS NOT NULL)`.
  - Post-Reset Negative Test 1: Duplicate location insert failed with `ERROR: duplicate key value violates unique constraint "uq_campus_location_bldg_floor_room" (SQLSTATE 23505)`.
  - Post-Reset Negative Test 2: `UPDATE hazard_report SET status = 'Verified', priority = NULL WHERE report_id = 1;` failed with `ERROR: new row violates check constraint "chk_verified_report_requires_priority" (SQLSTATE 23514)`.
  - Post-Reset Positive Test: Valid verification update with `priority = 'High'` succeeded with `UPDATE 1`.
- **Verdict:** **PASS (100% Verified on Disposable DB)**.

---

## 3. Summary of Test Results

| Incident ID | Test Copy Database | Fault Reproduction Result | Reset Execution Result | Verification Status |
|:---:|:---:|:---:|:---:|:---:|
| **G07-INC1** | `campussafe_midterm_test` | **CONFIRMED** | **CONFIRMED** | **VERIFIED (PASS)** |
| **G07-INC2** | `campussafe_midterm_test` | **CONFIRMED** | **CONFIRMED** | **VERIFIED (PASS)** |
| **G07-INC3** | `campussafe_midterm_test` | **CONFIRMED** | **CONFIRMED** | **VERIFIED (PASS)** |
| **G07-INC4** | `campussafe_midterm_test` | **CONFIRMED** | **CONFIRMED** | **VERIFIED (PASS)** |
| **G07-INC5** | `campussafe_midterm_test` | **CONFIRMED** | **CONFIRMED** | **VERIFIED (PASS)** |

All 5 fault scripts, reset scripts, negative verification tests, and positive regression tests completed cleanly with 100% success on the disposable testing environment.
