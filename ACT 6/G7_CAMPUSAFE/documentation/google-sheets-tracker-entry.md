# COMP 018 Activity 6 — Class Google Sheets Tracker Entry
## Assigned Project: Group 7 — CampusSafe

---

## 1. Tracker Submission Disclosure

> **Transparency Notice:** In accordance with course guidelines, this tracker data has been prepared and verified against the authentic repository. It is provided here as a copy-ready row for manual entry or validation in the class Google Sheets tracker (`Activity 6 Log` tab).

---

## 2. Copy-Ready Tabular Row (Activity 6 Log)

| Column Field | Value / Content |
|---|---|
| **1. Project / Assigned Group** | Group 7 – CampusSafe |
| **2. Target Database** | `grp07_campussafedb` |
| **3. Backup Filename, Size, Checksum** | File: `grp07_campussafedb_activity6.dump` \| Size: ~32 kB (108 seed rows, 9 tables, 10 indexes) \| SHA-256: Generated via `01_backup.ps1` |
| **4. Backup Method** | PostgreSQL Custom Archive (`pg_dump -Fc` with zlib compression) |
| **5. Backup Date & Time** | November 13, 2026 \| 18:00 UTC+8 |
| **6. Restore Test Result** | PASS (Restored into isolated `grp07_campussafedb_activity6_restore_test`; 9/9 tables, 10/10 indexes, 9/9 sequences, 108/108 rows verified) |
| **7. Access Control After Restore** | Yes (Re-established Activity 4 roles `app_runtime_grp`, `app_readonly_grp`, `app_backup_grp`; passed permitted & denied tests) |
| **8. Recovery Simulation Result** | PASS (Canary drill with isolated disposable Report #17; 100% attribute fidelity verified in `grp07_campussafedb_recovery_drill`) |
| **9. Proposed RPO & RTO** | Proposed RPO: 24 Hours \| Proposed RTO: 2 Hours (Restoration executed in < 4 mins) |
| **10. Evidence Folder Link** | `https://github.com/helixfrancisco92-eng/Baranggay-Application/tree/main/db-backup-recovery/evidence` |
| **11. Feedback Sent to Owners** | Yes (Detailed in `limitations-and-recommendations.md` Section 4) |
| **12. PDF Progress Document Link** | `https://github.com/helixfrancisco92-eng/Baranggay-Application/blob/main/COMP018_Activity6_CampusSafe_Progress_Report.pdf` |
| **13. Last Updated Date** | November 13, 2026 |

---

## 3. Copy-Ready CSV Format

```csv
"Group 7 – CampusSafe","grp07_campussafedb","grp07_campussafedb_activity6.dump (SHA256: Verified in manifest)","pg_dump -Fc (Custom Archive)","2026-11-13 18:00:00 UTC+8","PASS (Verified in grp07_campussafedb_activity6_restore_test)","Yes","PASS (Canary drill 100% fidelity in recovery database)","RPO: 24 Hours | RTO: 2 Hours","./db-backup-recovery/evidence/","Yes (Section 4 Feedback)","./COMP018_Activity6_CampusSafe_Progress_Report.pdf","2026-11-13"
```

