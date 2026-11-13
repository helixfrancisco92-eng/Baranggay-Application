# COMP 018 — ACTIVITY 6: EVIDENCE CHECKLIST
## Target Project: Group 5 – Lost and Found Management System (PUP-SPOT)
### Course: COMP 018 – Database Administration

---

## 1. EVIDENCE CHECKLIST & STATUS MATRIX

| # | Evidence Item Description | Verification Method / Command | Status | Evidence File / Output Reference |
| :-: | :--- | :--- | :--- | :--- |
| **1** | Project repository inspection | Git remote inspection & directory survey | **PASS** | `reports/execution-log.md` (Row 1-2), `database-inspection.md` |
| **2** | Database & schema identification | Catalog queries & repository SQL inspection | **PASS** | `database-inspection.md`, `grp05_lostandfounddb` / `public` |
| **3** | Backup command execution | Native PowerShell & pg_dump -Fc execution | **PASS** | `backup/backup.ps1` (Exit code: 0) |
| **4** | Backup file information | System file validation & timestamping | **PASS** | `grp05_lostandfounddb_backup_20261112_235620.dump` |
| **5** | Backup file size | File length query | **PASS** | `1,168 bytes` (1.14 KB) |
| **6** | SHA-256 cryptographic checksum | `Get-FileHash -Algorithm SHA256` | **PASS** | `911D3555F2F505E311F4FA10A2482C599B9274AD1F2082AC7F55F01ED7CD617B` |
| **7** | Backup archive listing (TOC) | `pg_restore --list <backup_file>` | **PASS** | `backup/inspect-backup.ps1` (Exit code: 0) |
| **8** | Test database creation | `createdb -U lf_admin_user ...` | **BLOCKED** | Documented limitation: `lf_admin_user` lacks `CREATEDB` privilege |
| **9** | Restore command execution | `pg_restore -d <restore_test_db> ...` | **PENDING** | Automated script prepared; requires prior createdb provisioning |
| **10** | Restoration outcome or exact error | Script exception handling & status capture | **PASS** | Logged exact error: `permission denied to create database` |
| **11** | Table and object verification | `restore/verify-restored-database.sql` | **CREATED** | SQL suite prepared; 8 tables, sequences, views audited |
| **12** | Record-count verification | `restore/verify-restored-database.sql` | **CREATED** | SQL queries prepared across all 8 base tables |
| **13** | Constraint verification | PK, FK, Check, and Unique catalog queries | **CREATED** | SQL catalog queries prepared and statically validated |
| **14** | Representative SELECT queries | Realistic multi-table JOIN SELECTs | **CREATED** | 4 multi-table join queries prepared with actual schema fields |
| **15** | Role and membership verification | Catalog query against `pg_roles`, `pg_auth_members` | **PASS** | Verified 6 Activity 4 roles and inheritance bindings |
| **16** | Allowed permission test | Query via read-authorized role | **PASS** | Verified `USAGE` on schema public for all Activity 4 roles |
| **17** | Denied permission test | Query via restricted role | **PASS** | Verified `CREATE` denied on schema public for `lf_admin_user` |
| **18** | Recovery simulation before/after | `restore/recovery-simulation.sql` | **CREATED** | Disposable record lifecycle (INSERT, SELECT, DELETE) scripted |
| **19** | Recovery outcome documented | Simulation comparison and limitation report | **PASS** | RPO/RTO analysis and snapshot recovery boundaries documented |
| **20** | Errors, warnings, and troubleshooting | Systematic limitation & blocker analysis | **PASS** | Documented in `reports/final-activity-6-report.md` (Section 9) |

---

## 2. MANUAL CAPTURE GUIDELINES FOR STUDENTS

For students preparing visual screenshot submissions for instructor review, capture the following terminal windows:

1. **Screenshot 1 — Backup Execution:**
   * Run: `powershell.exe -ExecutionPolicy Bypass -File backup/backup.ps1`
   * Target Output: The green completion banner displaying Target Database, File Size (1,168 bytes), and SHA-256 Checksum.
2. **Screenshot 2 — Archive Inspection:**
   * Run: `powershell.exe -ExecutionPolicy Bypass -File backup/inspect-backup.ps1`
   * Target Output: The Table of Contents output displaying `Archive created at... dbname: grp05_lostandfounddb` and `Compression: gzip`.
3. **Screenshot 3 — Restoration Safety Pre-Check:**
   * Run: `powershell.exe -ExecutionPolicy Bypass -File backup/restore-test.ps1`
   * Target Output: The safety checks confirming separate source and test database names, and the logged permission check.
4. **Screenshot 4 — Role Catalog & Membership Verification:**
   * Run: `psql -U lf_admin_user -h localhost -d grp05_lostandfounddb -f restore/verify-access-control.sql`
   * Target Output: The tables displaying `lf_admin`, `lf_staff`, `lf_viewer`, their login users, and the role inheritance table.

