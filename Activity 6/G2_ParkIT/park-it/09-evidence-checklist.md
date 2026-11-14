# Activity 6 Evidence and Submission Checklist
## COMP 018 — Database Administration
### Project: Park-It Database Management System (`grp_parkitdb`)

---

## 📋 Submission Evidence Matrix

Use this checklist to ensure all required terminal command outputs, log files, and visual screenshots are captured and cataloged prior to submitting the Activity 6 deliverables.

| Item # | Evidence Requirement | Expected Command / Source | Target Output / Key Elements | Status |
|---|---|---|---|---|
| **01** | Repository Structure | `tree /F db-backup-recovery` or `Get-ChildItem -Recurse` | Shows clean layout with all 10 files in `park-it/` and 2 in `templates/` | `[ ] PENDING` |
| **02** | Backup Command Execution | `./02-backup.sh` | Terminal showing utility detection, parameter prompts, and execution start | `[ ] PENDING` |
| **03** | Successful Backup Creation | Output of `02-backup.sh` | Green success banner, target file path, and zero exit code | `[ ] PENDING` |
| **04** | Backup File Size Verification | `ls -lh ../backups/*.dump` or `Get-Item` | Shows non-zero byte size (e.g. ~35-50 KB) | `[ ] PENDING` |
| **05** | SHA-256 Checksum Generation | `cat ../backups/*.sha256` or `sha256sum` | 64-character hexadecimal SHA-256 hash | `[ ] PENDING` |
| **06** | pg_restore Archive TOC Listing | `./03-inspect-backup.sh` | TOC entries showing 5 core tables, sequences, constraints, and data blocks | `[ ] PENDING` |
| **07** | Creation of Test Database | Output of `./04-restore-test.sh` | `createdb` creating `grp_parkitdb_restore_test` with zero exit code | `[ ] PENDING` |
| **08** | Successful Restoration Output | Output of `./04-restore-test.sh` | Clean restore confirmation or non-fatal warning code (0 or 1) | `[ ] PENDING` |
| **09** | Restored Database Tables | `05-verify-restoration.sql` (Section A.2) | Table listing showing `parking_zone`, `vehicle`, `staff_user`, `transaction`, `payment` all marked PASSED | `[ ] PENDING` |
| **10** | Sample Record Verification | `05-verify-restoration.sql` (Section B.2) | Confirmed default seed for 'Main Parking Lot' (capacity 50) and Admin/Staff accounts | `[ ] PENDING` |
| **11** | Constraint & Integrity Verification| `05-verify-restoration.sql` (Section C) | All 5 PKs, 3 FKs, Unique, and Check constraints marked PASSED with 0 orphan rows | `[ ] PENDING` |
| **12** | Access Control Catalog Verification| `06-verify-access-control.sql` (Steps 2-4) | `parkit_runtime_grp` and `parkit_app` present, member hierarchy confirmed | `[ ] PENDING` |
| **13** | Permitted Operation Verification | `06-verify-access-control.sql` (Step 7) | `parkit_app` successfully executing `SELECT` on `parking_zone` and `INSERT` on `vehicle` | `[ ] PENDING` |
| **14** | Denied Operation Verification | `06-verify-access-control.sql` (Step 8) | `parkit_app` correctly blocked with `insufficient_privilege` on `DELETE` and `UPDATE` | `[ ] PENDING` |
| **15** | Recovery Simulation: Baseline State | `07-recovery-simulation.sql` (Step 1) | Query displaying disposable record `SIM-RECOV-888` actively inserted in `vehicle` & `transaction` | `[ ] PENDING` |
| **16** | Recovery Simulation: Data Loss | `07-recovery-simulation.sql` (Step 2) | Query confirming `SIM-RECOV-888` is missing (count = 0) following simulated incident | `[ ] PENDING` |
| **17** | Recovery Database Verification | `07-recovery-simulation.sql` (Step 4) | Query against recovery database confirming state recovery | `[ ] PENDING` |
| **18** | Final Academic Report Completed | `08-recovery-report.md` | All 22 report sections populated with measured data and conclusions | `[ ] PENDING` |

---

## 📸 Recommended Screenshot Capture Guidelines

When capturing terminal outputs for inclusion in your submission:
1. **Window Header:** Include the window title or shell prompt showing your current directory (`park-it-database/db-backup-recovery/park-it`).
2. **Command and Output:** Ensure the exact executed command is visible at the top of each screenshot.
3. **High Contrast:** Use dark background with high-contrast text or standard terminal colors.
4. **Naming Convention:** Save your screenshots into an `evidence/` folder using standardized filenames:
   - `01_repo_structure.png`
   - `02_backup_execution.png`
   - `03_backup_success.png`
   - `04_filesize_check.png`
   - `05_sha256_checksum.png`
   - `06_inspect_toc_listing.png`
   - `07_test_db_creation.png`
   - `08_restore_success.png`
   - `09_tables_verification.png`
   - `10_seed_data_verification.png`
   - `11_constraints_verification.png`
   - `12_rbac_roles_verification.png`
   - `13_permitted_operation.png`
   - `14_denied_operation.png`
   - `15_sim_baseline_state.png`
   - `16_sim_data_loss.png`
   - `17_sim_recovery_verified.png`
   - `18_final_report_pdf.png`

