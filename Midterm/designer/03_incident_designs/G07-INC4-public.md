# INCIDENT DESIGN SHEET #4 (PUBLIC INCIDENT BRIEF)

**Incident ID:** G07-INC4  
**Related Flaw ID:** G07-F4  
**Project Owner:** Group 7 – CAMPUSAFE  
**Designer Group:** Group 12 – iBarangay  
**Variant:** Backup Operator Privileges & Disaster Recovery Inaccessibility  
**Related Activity:** Activity 6 (Backup and Recovery Procedures)  
**Difficulty:** Hard  
**Estimated Investigation Time:** 30 Minutes  

---

### PUBLIC INCIDENT BRIEF

#### Incident Symptoms
The automated nightly database backup task scheduled at 01:00 AM failed unexpectedly with exit code 1. System monitoring alerts flagged that the generated backup archive file in the backup destination directory was either 0 bytes in size or corrupted. When the backup operator attempted a test restoration into a verification database, the recovery utility aborted immediately with a syntax or permission failure. Concurrently, a disaster recovery simulation on a secondary server failed completely during role recreation, putting the institution at risk of total data loss in the event of hardware failure.

#### Expected Observable Behavior
When an investigator attempts to execute the scheduled backup script or inspect operator privileges:
1. Running `pg_dump` under the dedicated backup service account (`campussafe_backup`) produces permission denial errors (`ERROR: permission denied for relation ...` or `query failed`).
2. The generated custom archive file (`.dump`) fails integrity inspection via `pg_restore --list`.
3. An audit of PostgreSQL roles reveals that the backup user lacks comprehensive pre-defined reading roles (`pg_read_all_data`), and disaster recovery scripts lack an export of cluster-wide authentication catalogs.

#### Evidence Available to Owner Group
Investigators may inspect the following evidence sources:
- Automated backup execution logs:
  - Task scheduler logs and PowerShell console output
  - Backup archive files in `backups/` or Activity 6 directories
- PostgreSQL role catalog and group memberships:
  - `pg_roles`
  - `information_schema.table_privileges` (inspecting `campussafe_backup` / `app_backup_grp`)
- Activity 6 Backup & Recovery scripts and documentation:
  - `campusafe/01_backup.ps1`
  - `campusafe/04_restore.ps1`
  - `database/03_roles_and_privileges.sql` (Lines 80–97)
  - `progress-report/ACTIVITY_06_BACKUP_RECOVERY_REPORT.md`

---
*Note: This public document contains observable symptoms only. Technical root causes, fault scripts, and reset procedures are maintained privately in the instructor answer pack.*
