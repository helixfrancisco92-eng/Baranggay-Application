# COMP 018 Midterm Examination — Private Instructor Answer Key

**Course:** COMP 018 — Database Administration  
**Designer Group:** Group 12 — iBarangay (Amoranto, Denielle; & Francisco, Helix)  
**Target Owner Group:** Group 7 — CAMPUSAFE (Alba, Arreza, Orpesa, Robiso, Santos)  
**Target Repository:** `https://github.com/jeffersonorpesa2-ops/grp07-campussafe`  
**Target Database:** `grp07_campussafedb` (Disposable Test Target: `campussafe_midterm_test`)  
**Security Classification:** **STRICTLY PRIVATE — INSTRUCTOR ONLY**  
*(Do not publish or distribute to owner groups prior to completion of the technical defense).*

---

## Executive Summary of Incident Scenarios

| Incident ID | Linked Flaw | Variant & Activity Area | Difficulty | Estimated Time | Key Technical Principle |
|:---:|:---:|---|:---:|:---:|---|
| **G07-INC1** | `G07-F1` | Role Privileges & Least-Privilege (Activity 4) | **Easy** | 15 min | Column-level privilege restriction on authentication catalogs (`app_user`). |
| **G07-INC2** | `G07-F2` | Schema Referential Integrity & Audit Retention (Act 3/4) | **Medium** | 25 min | Preventing cascading destruction of regulatory audit and repair logs (`ON DELETE RESTRICT`). |
| **G07-INC3** | `G07-F3` | Database Triggers, State Auditing & Bloat (Act 3/5) | **Medium** | 25 min | Automated transition auditing at the database engine level via `AFTER UPDATE` triggers. |
| **G07-INC4** | `G07-F4` | Backup Operator Privileges & Recovery (Activity 6) | **Hard** | 30 min | Non-superuser logical dump permissions (`pg_read_all_data`) and global cluster role archiving. |
| **G07-INC5** | `G07-F5` | Schema Normalization & Check Constraints (Act 3/5) | **Easy** | 15 min | Candidate key uniqueness on composite locations and conditional state completeness constraints. |

---

## SCENARIO 1: G07-INC1 (Excessive UPDATE Privileges on app_user)

1. **Incident ID:** `G07-INC1`
2. **Related Flaw ID:** `G07-F1`
3. **Intended Symptoms:** Campus safety administrators discover that standard student reporters and maintenance technicians can have their role assignments escalated to Administrator, or their account statuses suspended, even though application web controllers attempt to restrict user management features.
4. **Expected Root Cause:** In `database/03_roles_and_privileges.sql` (lines 64–65), the runtime group role `app_runtime_grp` (and its login user `campussafe_app`) was granted table-wide `UPDATE` on `public.app_user`. PostgreSQL enforces permissions at the table level unless column-level grants are specified; therefore, the runtime database account holds relational permission to update security-critical columns (`role_id`, `account_status`, `password_hash`).
5. **Evidence Proving Root Cause:**
   - Querying `information_schema.table_privileges`:
     ```sql
     SELECT grantee, table_name, privilege_type 
     FROM information_schema.table_privileges 
     WHERE table_name = 'app_user' AND grantee = 'app_runtime_grp';
     ```
     *Output:* `grantee: app_runtime_grp | privilege_type: UPDATE`.
   - Querying `information_schema.column_privileges`:
     ```sql
     SELECT column_name, privilege_type 
     FROM information_schema.column_privileges 
     WHERE table_name = 'app_user' AND grantee = 'app_runtime_grp';
     ```
     *Output:* `(0 rows)` — confirms no column-level restrictions exist.
6. **Expected Troubleshooting Steps:**
   - Step 1: Connect to disposable database under DBA account (`postgres` / `campussafe_owner`).
   - Step 2: Query `information_schema.table_privileges` and `column_privileges` for `app_user`.
   - Step 3: Test direct UPDATE under `campussafe_app` to verify whether `role_id` and `account_status` can be changed.
   - Step 4: Rule out application-only filtering; identify that the database engine lacks defense-in-depth.
7. **Safest Corrective Action:** Revoke the whole-table `UPDATE` privilege on `app_user` from `app_runtime_grp`, and grant column-level `UPDATE` privileges strictly on non-sensitive user profile attributes (`full_name`, `email`, `password_hash`).
8. **SQL Correction:**
   ```sql
   REVOKE UPDATE ON public.app_user FROM app_runtime_grp;
   GRANT UPDATE (full_name, email, password_hash) ON public.app_user TO app_runtime_grp;
   ```
9. **Verification Commands:**
   ```sql
   -- Test as runtime user
   SET ROLE campussafe_app;
   -- Must fail:
   UPDATE public.app_user SET role_id = 1 WHERE user_id = 2;
   -- Must succeed:
   UPDATE public.app_user SET full_name = 'Verified User Name' WHERE user_id = 2;
   RESET ROLE;
   ```
10. **Expected Successful Results:** Updating `full_name` under `campussafe_app` succeeds with `UPDATE 1`.
11. **Expected Denied / Unsuccessful Tests:** Attempting to update `role_id` or `account_status` under `campussafe_app` fails with:
    `ERROR: permission denied for column "role_id" of relation "app_user" (SQLSTATE 42501)`.
12. **Rollback Instructions:**
    ```sql
    REVOKE UPDATE (full_name, email, password_hash) ON public.app_user FROM app_runtime_grp;
    GRANT UPDATE ON public.app_user TO app_runtime_grp;
    ```
13. **Alternative Explanations Considered & Ruled Out:**
    - *Alternative A: Front-end authorization bypass or session hijacking.* Ruled out because direct SQL execution using `campussafe_app` succeeds independently of PHP sessions.
    - *Alternative B: Database user has superuser privileges.* Ruled out by checking `rolsuper` in `pg_roles` (evaluates to `false`).
14. **Safety Considerations:** Applying column-level privileges must include all mutable fields required by the user profile page (`full_name`, `email`, `password_hash`); omitting any of these breaks legitimate profile editing.

---

## SCENARIO 2: G07-INC2 (Cascading Deletions Purging Audit & Compliance History)

1. **Incident ID:** `G07-INC2`
2. **Related Flaw ID:** `G07-F2`
3. **Intended Symptoms:** An administrator deletes a test or old hazard report, and subsequently discovers that all historical status transitions, technician repair logs, work order dispatches, and uploaded inspection photographs associated with that incident have permanently vanished from the database.
4. **Expected Root Cause:** In `database/01_schema.sql` (lines 110, 125, 139, 153), foreign keys referencing `hazard_report(report_id)` on tables `assignment`, `report_status_history`, `maintenance_action`, and `attachment` are configured with `ON DELETE CASCADE`. When a parent report is deleted, the database automatically deletes all dependent audit and historical evidence rows.
5. **Evidence Proving Root Cause:**
   - Inspecting `pg_constraint` catalog:
     ```sql
     SELECT conname, conrelid::regclass AS child_table, confrelid::regclass AS parent_table, confdeltype 
     FROM pg_constraint 
     WHERE confrelid = 'public.hazard_report'::regclass;
     ```
     *Output:* Foreign keys `assignment_report_id_fkey`, `report_status_history_fkey`, `maintenance_action_fkey`, and `attachment_report_id_fkey` all display `confdeltype = 'c'` (`CASCADE`).
6. **Expected Troubleshooting Steps:**
   - Step 1: Query `pg_constraint` for all foreign keys referencing `hazard_report`.
   - Step 2: Identify `confdeltype = 'c'` across all 4 dependent tables.
   - Step 3: Insert a test report with child audit rows on the disposable database, run `DELETE FROM hazard_report`, and verify child row loss.
   - Step 4: Rule out application triggers by inspecting `pg_trigger` (verifying no `BEFORE/AFTER DELETE` triggers exist).
7. **Safest Corrective Action:** Drop the cascading foreign keys and recreate them with `ON DELETE RESTRICT` (blocking hard deletion while dependent audit records exist). Implement a **Soft Delete** mechanism (`is_deleted BOOLEAN DEFAULT FALSE`, `deleted_at TIMESTAMP`) on `hazard_report`.
8. **SQL Correction:**
   ```sql
   ALTER TABLE public.assignment DROP CONSTRAINT IF EXISTS assignment_report_id_fkey;
   ALTER TABLE public.assignment ADD CONSTRAINT fk_assignment_report 
       FOREIGN KEY (report_id) REFERENCES public.hazard_report(report_id) ON DELETE RESTRICT;

   ALTER TABLE public.report_status_history DROP CONSTRAINT IF EXISTS report_status_history_fkey;
   ALTER TABLE public.report_status_history ADD CONSTRAINT fk_status_history_report 
       FOREIGN KEY (report_id) REFERENCES public.hazard_report(report_id) ON DELETE RESTRICT;

   ALTER TABLE public.maintenance_action DROP CONSTRAINT IF EXISTS maintenance_action_fkey;
   ALTER TABLE public.maintenance_action ADD CONSTRAINT fk_maintenance_report 
       FOREIGN KEY (report_id) REFERENCES public.hazard_report(report_id) ON DELETE RESTRICT;

   ALTER TABLE public.attachment DROP CONSTRAINT IF EXISTS attachment_report_id_fkey;
   ALTER TABLE public.attachment ADD CONSTRAINT fk_attachment_report 
       FOREIGN KEY (report_id) REFERENCES public.hazard_report(report_id) ON DELETE RESTRICT;

   ALTER TABLE public.hazard_report ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE;
   ALTER TABLE public.hazard_report ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;
   ```
9. **Verification Commands:**
   ```sql
   -- Negative Test (Hard delete blocked):
   DELETE FROM public.hazard_report WHERE report_id = 1;
   -- Positive Test (Soft delete):
   UPDATE public.hazard_report SET is_deleted = TRUE, deleted_at = CURRENT_TIMESTAMP WHERE report_id = 1;
   SELECT is_deleted, deleted_at FROM public.hazard_report WHERE report_id = 1;
   SELECT COUNT(*) FROM public.report_status_history WHERE report_id = 1;
   ```
10. **Expected Successful Results:** Soft delete flags report as deleted while 100% of child rows in `report_status_history`, `assignment`, `maintenance_action`, and `attachment` remain intact.
11. **Expected Denied / Unsuccessful Tests:** Attempting hard delete fails with:
    `ERROR: update or delete on table "hazard_report" violates foreign key constraint "fk_status_history_report" on table "report_status_history" (SQLSTATE 23503)`.
12. **Rollback Instructions:** Re-add foreign keys with `ON DELETE CASCADE`.
13. **Alternative Explanations Considered & Ruled Out:**
    - *Alternative: Application code explicitly deleted child rows in a loop.* Ruled out because direct SQL delete in psql reproduced the exact same cascade.
14. **Safety Considerations:** Applying `ON DELETE RESTRICT` will prevent deleting reports that have child rows; application queries must be updated to filter `WHERE is_deleted = FALSE`.

---

## SCENARIO 3: G07-INC3 (Missing Database Trigger for Status History Auditing)

1. **Incident ID:** `G07-INC3`
2. **Related Flaw ID:** `G07-F3`
3. **Intended Symptoms:** An administrator updates hazard report statuses directly via database management tools or during batch maintenance, but the corresponding status changes do not appear in `report_status_history`. The audit trail shows untracked gaps in incident lifecycles.
4. **Expected Root Cause:** The database lacks database-level triggers to record status changes. The system relies entirely on application-level PHP controller logic (`src/models/Report.php`) to insert audit rows. Direct SQL updates, batch scripts, and maintenance tasks bypass history logging completely.
5. **Evidence Proving Root Cause:**
   - Querying `pg_trigger`:
     ```sql
     SELECT tgname, tgtype, tgenabled, tgrelid::regclass 
     FROM pg_trigger 
     WHERE tgrelid = 'hazard_report'::regclass AND NOT tgisinternal;
     ```
     *Output:* `(0 rows)` — zero user-defined triggers exist on `hazard_report`.
   - Updating `hazard_report.status` directly via SQL leaves `report_status_history` count unchanged.
6. **Expected Troubleshooting Steps:**
   - Step 1: Query `pg_trigger` to verify whether an update trigger is attached to `hazard_report`.
   - Step 2: Execute an `UPDATE hazard_report SET status = 'In Progress' WHERE report_id = ...` via psql.
   - Step 3: Query `report_status_history` and confirm that zero new records were inserted.
   - Step 4: Inspect `src/models/Report.php` to verify that status logging is handled only at the application layer.
7. **Safest Corrective Action:** Create an `AFTER UPDATE OF status` trigger `trg_hazard_report_status_audit` on `hazard_report` that invokes a PL/pgSQL function `trg_log_hazard_status_change()` to write transition rows automatically.
8. **SQL Correction:**
   ```sql
   CREATE OR REPLACE FUNCTION public.trg_log_hazard_status_change()
   RETURNS TRIGGER AS $$
   BEGIN
       IF (OLD.status IS DISTINCT FROM NEW.status) THEN
           INSERT INTO public.report_status_history (
               report_id,
               changed_by_user_id,
               status,
               changed_at,
               notes
           ) VALUES (
               NEW.report_id,
               COALESCE(NEW.verified_by_user_id, OLD.reporter_user_id, 1),
               NEW.status,
               CURRENT_TIMESTAMP,
               'Automated database trigger audit log'
           );
       END IF;
       RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;

   DROP TRIGGER IF EXISTS trg_hazard_report_status_audit ON public.hazard_report;
   CREATE TRIGGER trg_hazard_report_status_audit
   AFTER UPDATE OF status ON public.hazard_report
   FOR EACH ROW
   EXECUTE FUNCTION public.trg_log_hazard_status_change();
   ```
9. **Verification Commands:**
   ```sql
   UPDATE public.hazard_report SET status = 'In Progress' WHERE report_id = 1;
   SELECT history_id, report_id, status, changed_at, notes 
   FROM public.report_status_history 
   WHERE report_id = 1 
   ORDER BY history_id DESC LIMIT 1;
   ```
10. **Expected Successful Results:** A new historical audit row appears immediately in `report_status_history` showing the new status and current timestamp.
11. **Expected Denied / Unsuccessful Tests:** N/A (Functional audit enforcement).
12. **Rollback Instructions:**
    ```sql
    DROP TRIGGER IF EXISTS trg_hazard_report_status_audit ON public.hazard_report;
    DROP FUNCTION IF EXISTS public.trg_log_hazard_status_change();
    ```
13. **Alternative Explanations Considered & Ruled Out:**
    - *Alternative: Trigger exists but is disabled (`tgenabled = 'D'`).* Ruled out by catalog check showing zero rows in `pg_trigger`.
14. **Safety Considerations:** Ensure trigger checks `(OLD.status IS DISTINCT FROM NEW.status)` so that updates to other columns (e.g. `description`) do not create duplicate status history rows.

---

## SCENARIO 4: G07-INC4 (Backup Operator Privilege Fragility & Recovery Gap)

1. **Incident ID:** `G07-INC4`
2. **Related Flaw ID:** `G07-F4`
3. **Intended Symptoms:** Nightly automated backup jobs fail with exit code 1; generated archive files are 0 bytes or corrupted; restore drills onto clean PostgreSQL clusters fail due to missing cluster-level roles.
4. **Expected Root Cause:** The backup service account `campussafe_backup` (`app_backup_grp`) lacks the PostgreSQL pre-defined role `pg_read_all_data`. Revoking `SELECT` or creating new objects without updating default privileges causes `pg_dump` to fail midway. Furthermore, backup procedures omit cluster-level role archiving (`pg_dumpall --globals-only`).
5. **Evidence Proving Root Cause:**
   - Scheduled task log: `pg_dump: error: query failed: ERROR: permission denied for table report_status_history`.
   - Querying `pg_roles`:
     ```sql
     SELECT rolname FROM pg_roles WHERE pg_has_role('campussafe_backup', oid, 'member');
     ```
     *Output:* `pg_read_all_data` is absent from memberships.
6. **Expected Troubleshooting Steps:**
   - Step 1: Check automated backup logs and archive file size in `backups/`.
   - Step 2: Execute `pg_dump -U campussafe_backup -Fc -d grp07_campussafedb` manually; capture error text.
   - Step 3: Inspect `information_schema.table_privileges` and role memberships for `campussafe_backup`.
   - Step 4: Identify that non-superuser backups require complete read grants and cluster globals export.
7. **Safest Corrective Action:** Restore `SELECT` on all tables/sequences in `public` to `app_backup_grp`. Grant pre-defined role `pg_read_all_data` to `app_backup_grp`. Augment backup scripts with `pg_dumpall --globals-only`.
8. **SQL & Script Correction:**
   ```sql
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_backup_grp;
   GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO app_backup_grp;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO app_backup_grp;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO app_backup_grp;
   GRANT pg_read_all_data TO app_backup_grp;
   ```
   *PowerShell Routine:*
   ```powershell
   pg_dumpall.exe -U postgres -h localhost -p 5432 --globals-only -f "backups/globals.sql"
   pg_dump.exe -U campussafe_backup -h localhost -p 5432 -Fc -d grp07_campussafedb -f "backups/grp07_campussafedb.dump"
   ```
9. **Verification Commands:**
   ```powershell
   pg_dump.exe -U campussafe_backup -h localhost -p 5432 -Fc -d grp07_campussafedb -f "backups/test.dump"
   pg_restore.exe --list "backups/test.dump"
   ```
10. **Expected Successful Results:** `pg_dump` exits with return code `0`. Archive size is > 0 bytes. `pg_restore --list` displays all 9 tables, indexes, constraints, and sequences.
11. **Expected Denied / Unsuccessful Tests:** Attempting DDL or `INSERT/UPDATE` under `campussafe_backup` continues to fail with `permission denied`.
12. **Rollback Instructions:** Revoke `pg_read_all_data` from `app_backup_grp`.
13. **Alternative Explanations Considered & Ruled Out:**
    - *Alternative: PostgreSQL service was down or port blocked.* Ruled out because other database connections succeeded.
14. **Safety Considerations:** Never grant `SUPERUSER` to the backup account; use `pg_read_all_data` to adhere strictly to least-privilege principles.

---

## SCENARIO 5: G07-INC5 (Duplicate Physical Locations & Unenforced Verification Priority)

1. **Incident ID:** `G07-INC5`
2. **Related Flaw ID:** `G07-F5`
3. **Intended Symptoms:** Administrators encounter duplicate dropdown menu entries for the exact same physical campus location (e.g. multiple entries for "Main Building", "3rd Floor", "Room 302"). Concurrently, maintenance personnel encounter verified hazard reports that lack priority ratings, making it impossible to prioritize urgent safety repairs.
4. **Expected Root Cause:**
   - `campus_location` defines surrogate primary key `location_id SERIAL PRIMARY KEY` but lacks a composite `UNIQUE` constraint on natural candidate key `(building, floor, room_area)`.
   - `hazard_report.priority` is nullable and lacks a conditional check constraint enforcing priority once `status = 'Verified'`.
5. **Evidence Proving Root Cause:**
   - Querying `pg_constraint` for `campus_location`: confirms only `campus_location_pkey` exists.
   - Querying duplicates: `SELECT building, floor, room_area, COUNT(*) FROM campus_location GROUP BY building, floor, room_area HAVING COUNT(*) > 1;` returns multiple duplicate rows.
   - Querying verified reports: `SELECT COUNT(*) FROM hazard_report WHERE status = 'Verified' AND priority IS NULL;` returns unclassified verified reports.
6. **Expected Troubleshooting Steps:**
   - Step 1: Query duplicate rows in `campus_location`.
   - Step 2: Query `hazard_report` for verified reports holding NULL priority.
   - Step 3: Inspect `database/01_schema.sql` constraint definitions.
   - Step 4: Plan de-duplication of existing location records before adding the unique constraint.
7. **Safest Corrective Action:** Re-point foreign keys in `hazard_report` to the lowest primary `location_id`, delete redundant location rows, and add `UNIQUE(building, floor, room_area)` to `campus_location`. Backfill existing NULL priorities with `'Medium'` and add `CHECK (status NOT IN ('Verified', 'Assigned', 'In Progress', 'Resolved', 'Closed') OR priority IS NOT NULL)` to `hazard_report`.
8. **SQL Correction:**
   ```sql
   -- Step 1: Re-point foreign keys
   WITH ranked_locations AS (
       SELECT location_id,
              FIRST_VALUE(location_id) OVER (PARTITION BY building, floor, room_area ORDER BY location_id) AS keep_id,
              ROW_NUMBER() OVER (PARTITION BY building, floor, room_area ORDER BY location_id) AS rn
       FROM public.campus_location
   )
   UPDATE public.hazard_report hr
   SET location_id = rl.keep_id
   FROM ranked_locations rl
   WHERE hr.location_id = rl.location_id AND rl.rn > 1;

   -- Step 2: Delete duplicate locations
   WITH duplicates AS (
       SELECT location_id,
              ROW_NUMBER() OVER (PARTITION BY building, floor, room_area ORDER BY location_id) AS rn
       FROM public.campus_location
   )
   DELETE FROM public.campus_location
   WHERE location_id IN (SELECT location_id FROM duplicates WHERE rn > 1);

   -- Step 3: Add composite UNIQUE constraint
   ALTER TABLE public.campus_location 
       ADD CONSTRAINT uq_campus_location_bldg_floor_room 
       UNIQUE (building, floor, room_area);

   -- Step 4: Backfill priority and add conditional CHECK
   UPDATE public.hazard_report 
   SET priority = 'Medium' 
   WHERE status IN ('Verified', 'Assigned', 'In Progress', 'Resolved', 'Closed') AND priority IS NULL;

   ALTER TABLE public.hazard_report 
       ADD CONSTRAINT chk_verified_report_requires_priority 
       CHECK (status NOT IN ('Verified', 'Assigned', 'In Progress', 'Resolved', 'Closed') OR priority IS NOT NULL);
   ```
9. **Verification Commands:**
   ```sql
   -- Negative Test 1 (Duplicate location blocked):
   INSERT INTO public.campus_location (building, floor, room_area) VALUES ('Engineering Building', '1st Floor', 'Room 101');
   INSERT INTO public.campus_location (building, floor, room_area) VALUES ('Engineering Building', '1st Floor', 'Room 101');
   -- Negative Test 2 (Verified report with NULL priority blocked):
   UPDATE public.hazard_report SET status = 'Verified', priority = NULL WHERE report_id = 1;
   -- Positive Test:
   UPDATE public.hazard_report SET status = 'Verified', priority = 'High' WHERE report_id = 1;
   ```
10. **Expected Successful Results:** Updating verified report with `'High'` succeeds with `UPDATE 1`.
11. **Expected Denied / Unsuccessful Tests:**
    - Duplicate location insert fails with `ERROR: duplicate key value violates unique constraint "uq_campus_location_bldg_floor_room" (SQLSTATE 23505)`.
    - Updating verified report with `priority = NULL` fails with `ERROR: new row for relation "hazard_report" violates check constraint "chk_verified_report_requires_priority" (SQLSTATE 23514)`.
12. **Rollback Instructions:**
    ```sql
    ALTER TABLE public.campus_location DROP CONSTRAINT IF EXISTS uq_campus_location_bldg_floor_room;
    ALTER TABLE public.hazard_report DROP CONSTRAINT IF EXISTS chk_verified_report_requires_priority;
    ```
13. **Alternative Explanations Considered & Ruled Out:**
    - *Alternative: Frontend select box caching bug.* Ruled out because duplicate rows physically existed in `campus_location`.
14. **Safety Considerations:** Foreign keys in `hazard_report` must be updated prior to deleting duplicate rows in `campus_location`; otherwise, foreign key constraint violations will abort the transaction.
