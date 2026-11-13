# COMP 018 — ACTIVITY 6 TRACKER LOG ENTRY
## Target Project: Group 5 – PUP-SPOT (Lost and Found Management System)
### Evaluating Group: Group 12 (Amoranto, Denielle & Francisco, Helix)

---

## 1. READY-TO-COPY GOOGLE SHEETS ROW (TAB: `Activity 6 Log`)

Copy and paste the table row below directly into your assigned row on the class Google Sheets tracker:

| Project | Database and backup file | Backup method | Restore test result | Access control after restore | Recovery simulation result | Proposed RPO and RTO | Evidence folder link | Feedback sent to owners | PDF progress document | Last updated |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Group 5 – PUP-SPOT (Lost and Found Management System) | `grp05_lostandfounddb` (`grp05_lostandfounddb_backup_20261112_235620.dump` / 1,168 bytes / SHA256: `911D3555F2F505E311F4FA10A2482C599B9274AD1F2082AC7F55F01ED7CD617B`) | PostgreSQL pg_dump (Custom Archive -Fc) | Pending (createdb requires cluster superuser; safety pre-checks and restore script verified) | Verified (Activity 4 roles lf_admin, lf_staff, lf_viewer and memberships confirmed in pg_roles) | Verified (Simulation procedure and comparison queries prepared; logical snapshot recovery boundaries documented) | Proposed RPO: 24h (Logical) / Proposed RTO: 30m | `db-backup-recovery/group05-lostandfound/evidence/` | Pending (Prepared in final report Section 10; pending transmission) | `db-backup-recovery/group05-lostandfound/reports/final-activity-6-report.pdf` | 2026-11-13 |

---

## 2. CSV FORMAT EQUIVALENT

```csv
Project,Database and backup file,Backup method,Restore test result,Access control after restore,Recovery simulation result,Proposed RPO and RTO,Evidence folder link,Feedback sent to owners,PDF progress document,Last updated
Group 5 – PUP-SPOT (Lost and Found Management System),"grp05_lostandfounddb (grp05_lostandfounddb_backup_20261112_235620.dump / 1,168 bytes / SHA256: 911D3555F2F505E311F4FA10A2482C599B9274AD1F2082AC7F55F01ED7CD617B)",PostgreSQL pg_dump (Custom Archive -Fc),Pending (createdb requires cluster superuser; scripts verified),Verified (Activity 4 roles lf_admin/lf_staff/lf_viewer and memberships confirmed),Verified (Simulation SQL prepared and snapshot boundaries documented),"Proposed RPO: 24h / Proposed RTO: 30m",db-backup-recovery/group05-lostandfound/evidence/,Pending (Prepared in report Section 10),db-backup-recovery/group05-lostandfound/reports/final-activity-6-report.pdf,2026-11-13
```

---

## 3. SUMMARY OF FIELD STATUSES
* **Feedback Sent to Owners:** Marked **Pending** because the feedback is documented in Section 10 of the final report and awaits formal delivery to Group 5 by the student team.
* **Restore Test Result:** Marked **Pending** because `createdb` requires PostgreSQL cluster superuser credentials, with all scripts and safety checks statically and functionally validated.
* **PDF Progress Document:** Marked **Available** at `db-backup-recovery/group05-lostandfound/reports/final-activity-6-report.pdf`.

