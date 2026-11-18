# Designer Evidence Artifacts — Audit of Group 7 (CAMPUSAFE)

This directory stores evidence artifacts, terminal outputs, and catalog query logs collected by Group 12 during the static analysis and database auditing of Group 7's CAMPUSAFE project (`grp07-campussafe`).

### Evidence Index:
1. `G07_F1_privilege_evidence.txt`: `information_schema.table_privileges` output demonstrating table-wide `UPDATE` on `app_user` for `app_runtime_grp`.
2. `G07_F2_cascade_evidence.txt`: `pg_constraint` catalog output showing `confdeltype = 'c'` (`CASCADE`) on child audit tables (`report_status_history`, `maintenance_action`, `assignment`, `attachment`).
3. `G07_F3_trigger_evidence.txt`: `pg_trigger` catalog output confirming 0 user triggers on `hazard_report`.
4. `G07_F4_backup_privilege_evidence.txt`: `pg_roles` inspection showing missing `pg_read_all_data` pre-defined role for `campussafe_backup`.
5. `G07_F5_constraints_evidence.txt`: Catalog output showing missing candidate key `UNIQUE` constraint on `campus_location` and nullable unvalidated `priority` on verified hazard reports.
