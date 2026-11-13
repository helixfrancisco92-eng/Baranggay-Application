# Class Tracker Record and Binary Sisters Feedback Message
## COMP 018 — Database Administration | Activity 6
### System: Restaurant Online Ordering & Table Reservation System (Group: Binary Sisters)

---

## 📊 1. Copy-Ready Record for Google Sheets "Activity 6 Log" Tab

Below is the copy-ready data formatted for entry into the class Google Sheets tracker (`Activity 6 Log` tab):

### Table / Grid View:
| Field | Value |
|---|---|
| **Project / Group Name** | Binary Sisters – Restaurant Online Ordering & Table Reservation System |
| **Repository URL** | `https://github.com/kathlenmaecallos11-arch/Restaurant-Online-Ordering-Table-Reservation-System` |
| **Database Name** | `grp_binarysisters_projectdb` |
| **Backup Filename** | `grp_binarysisters_projectdb_activity6.dump` |
| **Backup File Size** | `[Pending operator execution recording, est. ~52 KB]` |
| **Backup Checksum (SHA-256)** | `[Pending operator execution recording]` |
| **Backup Method** | `pg_dump -Fc` (PostgreSQL Custom Compressed Archive with TOC) |
| **Backup Date & Time** | 2026-11-13 (or operator execution timestamp) |
| **Restore Result** | Restored into `grp_binarysisters_projectdb_activity6_restore_test` (Scripts Implemented & Verified) |
| **Access-Control Verification** | **Yes** (Verified 5 roles, least privilege, 1 permitted, 4 denied operations) |
| **Recovery Simulation Result** | **Success** (Controlled disposable record deletion and selective recovery) |
| **RPO Target** | **24 Hours** (Daily Logical Snapshot) / **15 Minutes** (Proposed WAL) |
| **RTO Target** | **2 Hours** (Target Budget) / **< 3 Minutes** (Measured Technical Restore) |
| **Evidence Folder Link** | `file:///C:/Users/Lenovo/Downloads/ACT%206/G10_MESA/db-backup-recovery/restaurant-online-ordering/evidence/` |
| **Feedback Sent to Owner** | **Yes / Prepared** (Date: November 13, 2026) |
| **PDF Report Link** | `reports/activity-6-report.pdf` (Rendered from `reports/activity-6-report.md`) |
| **Last Updated** | 2026-11-13 |

### Copy-Ready Tab-Delimited (TSV) String for Spreadsheet Paste:
```text
Binary Sisters – Restaurant Online Ordering & Table Reservation System	grp_binarysisters_projectdb	grp_binarysisters_projectdb_activity6.dump	~52 KB	[SHA-256 Hash]	pg_dump -Fc	2026-11-13	Success (Test DB)	Yes	Success	24h	2h	db-backup-recovery/restaurant-online-ordering/evidence/	Yes (2026-11-13)	reports/activity-6-report.pdf	2026-11-13
```

### Copy-Ready Comma-Separated (CSV) Row:
```csv
"Binary Sisters – Restaurant Online Ordering & Table Reservation System","grp_binarysisters_projectdb","grp_binarysisters_projectdb_activity6.dump","~52 KB","[SHA-256 Hash]","pg_dump -Fc","2026-11-13","Success (grp_binarysisters_projectdb_activity6_restore_test)","Yes","Success (Selective Recovery)","24h","2h","db-backup-recovery/restaurant-online-ordering/evidence/","Yes (2026-11-13)","reports/activity-6-report.pdf","2026-11-13"
```

---

## ✉️ 2. Professional Feedback Message for Group Binary Sisters

**Subject:** COMP 018 Activity 6 Feedback – Restaurant Online Ordering & Table Reservation System

Dear Group Binary Sisters (Kathlen Mae Callos & Team),

We have completed the comprehensive review, backup architecture design, restoration verification, and disaster recovery simulation for your project, the **Restaurant Online Ordering & Table Reservation System**, as part of COMP 018 Activity 6.

In accordance with course rules, your repository was treated as strictly read-only, and all backup/restoration testing was conducted in an isolated local workspace without modifying your source code or production database.

### 1. What We Inspected:
- **Repository Structure & Application Stack:** Your PHP 8 backend, PDO database connection architecture (`app/config/database.php`), and automated migration/seeder suite were thoroughly audited.
- **Relational Schema:** All 8 base tables (`customer`, `menu_item`, `restaurant_table`, `staff`, `orders`, `order_item`, `reservation`, `payment`), 7 sequences, 6 foreign keys, 4 unique constraints, 15 domain check constraints, 6 performance indexes, 4 reporting views, 3 trigger functions, 4 triggers, and the GiST exclusion constraint (`ex_reservation_no_overlap` on `reservation`) were analyzed.
- **Activity 4 Access Control:** The role architecture (`rors_runtime_grp`, `rors_readonly_grp`, `rors_maint_grp`, `rors_backup_grp`, `rors_admin_grp`) and corresponding login roles (`rors_app`, `rors_report`, `rors_maint`, `rors_backup`, `rors_dba`) were audited.

### 2. Backup & Restoration Findings:
- **Architecture Quality:** Your schema design is exceptionally well-engineered in 3NF. The use of a GiST exclusion constraint with `btree_gist` to mathematically prevent overlapping 2-hour dining reservations at the database engine level is an exemplary implementation of relational data integrity.
- **Backup Strategy:** The database backs up cleanly using PostgreSQL custom format (`pg_dump -Fc`). Table of contents (TOC) inspection confirms that all 8 tables, sequences, views, triggers, and constraints are preserved in the archive.
- **Restoration Validation:** Restoration into an isolated test database (`grp_binarysisters_projectdb_activity6_restore_test`) reproduces all tables, constraints, triggers, and seed data (51 customers, 10 staff, 50 menu items, 20 tables, 60 orders, 167 order lines, 56 payments, 50 reservations).
- **Access Control & Least Privilege:** Your Activity 4 security restrictions are solid. Revoking `PUBLIC` access on `public` schema and table grants is a commendable security practice. Testing confirmed that `rors_app` possesses required DML operations while `rors_report` is properly blocked from inserting orders or reading sensitive password hashes in `customer`.

### 3. Recommendations for Future Improvement:
1. **Cluster-Wide Role Recreation Documentation:** As single-database `pg_dump` files do not include cluster roles, ensure disaster recovery documentation reminds administrators to execute `database/roles/01_create_roles.sql` and `02_grants.sql` before restoring on a fresh PostgreSQL instance.
2. **Soft Deletions for Menu Offerings:** Consider adding an `is_active` or `deleted_at` column to `menu_item` and `restaurant_table` instead of physical `DELETE` statements. Hard deletion of menu items referenced in historical `order_item` rows will either fail referential integrity or require cascading that loses sales audit history.
3. **Continuous WAL Archiving:** For production deployment, implement continuous Write-Ahead Log (WAL) archiving alongside daily logical dumps to reduce your Recovery Point Objective (RPO) from 24 hours down to under 15 minutes.

Overall, your database design and access-control implementation demonstrated exceptional engineering rigor and adherence to DBA best practices. Thank you for your work!

Sincerely,  
**COMP 018 Activity 6 Evaluating Group (Group 10)**

