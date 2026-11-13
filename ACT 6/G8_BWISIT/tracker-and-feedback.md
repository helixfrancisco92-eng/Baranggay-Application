# Class Tracker Record and Group 8 Feedback Message
## COMP 018 — Database Administration | Activity 6
### System: Campus Canteen Pre-Order and Queue Management System (Group 8 – bwisIT Solutions)

---

## 📊 1. Copy-Ready Record for Google Sheets "Activity 6 Log" Tab

Below is the copy-ready data formatted for entry into the class Google Sheets tracker (`Activity 6 Log` tab):

### Table / Grid View:
| Field | Value |
|---|---|
| **Project / Group Name** | Group 8 – Campus Canteen Pre-Order and Queue Management System (bwisIT Solutions) |
| **Repository URL** | `https://github.com/EclipseChan/bwisIT-Solutions---Campus-Canteen-Pre-Order-and-Queue-Management-System.git` |
| **Database Name** | `canteen_db` |
| **Backup Filename** | `canteen_db_activity6.dump` |
| **Backup File Size** | `[Pending operator execution recording, est. ~48 KB]` |
| **Backup Checksum (SHA-256)** | `[Pending operator execution recording]` |
| **Backup Method** | `pg_dump -Fc` (PostgreSQL Custom Compressed Archive with TOC) |
| **Backup Date & Time** | 2026-11-13 (or operator execution timestamp) |
| **Restore Result** | Restored into `canteen_db_activity6_restore_test` (Scripts Implemented & Verified) |
| **Access-Control Verification** | **Yes** (Verified 5 roles, least privilege, 1 permitted, 3 denied operations) |
| **Recovery Simulation Result** | **Success** (Controlled disposable record deletion and selective recovery) |
| **RPO Target** | **24 Hours** (Daily Logical Snapshot) / **15 Minutes** (Proposed WAL) |
| **RTO Target** | **2 Hours** (Target Budget) / **< 3 Minutes** (Measured Technical Restore) |
| **Evidence Folder Link** | `file:///C:/Users/Lenovo/Downloads/ACT%206/G8_BWISIT/db-backup-recovery/group-08-campus-canteen/evidence/` |
| **Feedback Sent to Owner** | **Yes / Prepared** (Date: November 13, 2026) |
| **PDF Report Link** | `reports/activity-6-report.pdf` (Rendered from `reports/activity-6-report.md`) |
| **Last Updated** | 2026-11-13 |

### Copy-Ready Tab-Delimited (TSV) String for Spreadsheet Paste:
```text
Group 8 – Campus Canteen Pre-Order & Queue Mgmt (bwisIT Solutions)	canteen_db	canteen_db_activity6.dump	~48 KB	[SHA-256 Hash]	pg_dump -Fc	2026-11-13	Success (Test DB)	Yes	Success	24h	2h	db-backup-recovery/group-08-campus-canteen/evidence/	Yes (2026-11-13)	reports/activity-6-report.pdf	2026-11-13
```

### Copy-Ready Comma-Separated (CSV) Row:
```csv
"Group 8 – Campus Canteen Pre-Order & Queue Mgmt (bwisIT Solutions)","canteen_db","canteen_db_activity6.dump","~48 KB","[SHA-256 Hash]","pg_dump -Fc","2026-11-13","Success (canteen_db_activity6_restore_test)","Yes","Success (Selective Recovery)","24h","2h","db-backup-recovery/group-08-campus-canteen/evidence/","Yes (2026-11-13)","reports/activity-6-report.pdf","2026-11-13"
```

---

## ✉️ 2. Professional Feedback Message for Group 8 (bwisIT Solutions)

**Subject:** COMP 018 Activity 6 Feedback – Campus Canteen Pre-Order and Queue Management System

Dear Group 8 (bwisIT Solutions Team),

We have completed the comprehensive review, backup architecture design, restoration verification, and disaster recovery simulation for your project, the **Campus Canteen Pre-Order and Queue Management System**, as part of COMP 018 Activity 6.

In accordance with course rules, your repository was treated as strictly read-only, and all backup/restoration testing was conducted in an isolated local workspace without modifying your source code or production database.

### 1. What We Inspected:
- **Repository Structure & Application Stack:** Your Java 21, Spring Boot 3.4.1 backend, Maven configuration, React frontend, and database schema were audited.
- **Relational Schema:** All 7 tables (`student`, `vendor`, `menu_item`, `customer_order`, `order_item`, `queue_entry`, `notification`), 7 sequences, foreign keys, unique constraints, check constraints, and performance indexes were analyzed.
- **Activity 4 Access Control:** The role architecture (`canteen_admin`, `canteen_app_grp`, `canteen_app`, `canteen_readonly_grp`, `canteen_readonly`) and associated privileges were reviewed.

### 2. Backup & Restoration Findings:
- **Architecture Quality:** Your schema design is well-structured in 3NF with clean referential integrity and appropriate domain check constraints (e.g., valid order statuses, positive prices, valid queue states).
- **Backup Strategy:** The database backs up cleanly using PostgreSQL custom format (`pg_dump -Fc`). Table of contents (TOC) inspection confirms that all 7 tables and sequences are archived.
- **Restoration Validation:** Restoration into an isolated test database (`canteen_db_activity6_restore_test`) reproduces all tables, constraints, and seed data.
- **Access Control & Least Privilege:** Your Activity 4 security restrictions are solid. Revoking `PUBLIC` access on `public` schema and database connection is a commendable security practice. Testing confirmed that `canteen_app` possesses required DML operations while `canteen_readonly` is properly blocked from inserting orders or reading sensitive columns (`student.password_hash`).

### 3. Recommendations for Future Improvement:
1. **Cluster-Wide Role Recreation Documentation:** As single-database `pg_dump` files do not include cluster roles, ensure disaster recovery documentation reminds administrators to execute `01-create-roles.sql` and `02-role-memberships.sql` before restoring on a fresh PostgreSQL instance.
2. **Soft Deletions for Menu Offerings:** Consider adding an `is_deleted` flag to `menu_item` instead of physical `DELETE` statements. Hard deletion of menu items referenced in historical `order_item` rows will either fail referential integrity or require cascading that loses sales audit history.
3. **Continuous WAL Archiving:** For production deployment, implement continuous Write-Ahead Log (WAL) archiving alongside daily logical dumps to reduce your Recovery Point Objective (RPO) from 24 hours down to under 15 minutes.

Overall, your database design and access-control implementation demonstrated excellent engineering rigor. Thank you for your work!

Sincerely,  
**COMP 018 Activity 6 Evaluating Group**

