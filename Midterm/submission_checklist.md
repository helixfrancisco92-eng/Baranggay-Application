# COMP 018 — Midterm Examination: Student Submission Checklist

**Evaluating / Defending Group:** Group 12 — iBarangay: Barangay Document Request System  
**Peer Group Evaluated:** Group 7 — CAMPUSAFE: Campus Hazard & Safety Reporting System  
**Submission Date:** November 7, 2026  
**Course:** COMP 018 — Database Administration  

---

### Official Midterm Submission Verification Table

| # | Assessment Requirement | Status | Evidence / Repository Location | Notes & Operational Details |
|:---:|---|:---:|---|---|
| 1 | **Reviewed assigned project and recorded evidence-based flaws in Flaw Register** | ✅ COMPLETED | `midterm/designer/02_flaw_review/flaw_register.md`<br>`midterm/tracker/flaw_register.csv` | Thorough static analysis and schema auditing of `grp07-campussafe`. Recorded 5 confirmed flaws/risks (`G07-F1` to `G07-F5`) with exact line numbers and SQL verification queries. |
| 2 | **Designed five scenarios tied to flaws and covering the required areas** | ✅ COMPLETED | `midterm/designer/03_incident_designs/`<br>`G07-INC1-public.md` to `G07-INC5-public.md` | Covered Activity 4 (privilege), Activities 3–5 (referential integrity / schema object), Activity 5 (maintenance / triggers), Activity 6 (backup/recovery), and Free Choice (data quality / constraints). |
| 3 | **Fault and reset scripts work on disposable copy; answer key prepared privately** | ✅ COMPLETED | `midterm/designer/04_private_instructor_pack/`<br>`G07-INC1-fault.sql` to `G07-INC5-reset.sql`<br>`answer_key.md` | Tested on disposable databases (`campussafe_midterm_test`). Answer key kept in private pack for instructor evaluation only. Preserved baseline idempotency. |
| 4 | **Investigated all five incidents designed for our project following the workflow** | ⏳ PENDING RELEASE | `midterm/owner/02_official_incident_briefs/`<br>`midterm/owner/03_investigations/` | Awaiting instructor release of the 5 official incident briefs from our assigned peer designer group. Complete investigation templates prepared following the 8-step DBA troubleshooting method. |
| 5 | **Wrote a troubleshooting plan before acting and verified each fix** | ✅ READY / PENDING | `midterm/owner/03_investigations/`<br>`midterm/owner/04_sql_diagnostics/` | Formulated ordered diagnostic checks, hypothesis testing matrices, account privilege constraints, and rollback protocols for all investigation modules. |
| 6 | **Worked only on disposable copies and preserved every original database & repo** | ✅ COMPLETED | `midterm/designer/05_script_testing/`<br>`midterm/owner/01_ibarangay_baseline/` | Zero changes applied to Group 7's original repository or database. All scripts designed exclusively for cloned disposable environments (`*_disposable`). |
| 7 | **Scripts and evidence stored in our own repository, and tracker rows updated** | ✅ COMPLETED | `midterm/`<br>`midterm/tracker/flaw_register.csv`<br>`midterm/tracker/incident_register.csv` | All deliverables version-controlled under `helixfrancisco92-eng/Baranggay-Application`. Tracker-ready CSV files formatted for Google Sheets import. |
| 8 | **PDF report is complete and contains no secrets** | ✅ COMPLETED | `midterm/reports/COMP018_Midterm_Group12_Report.pdf`<br>`midterm/reports/midterm_report.md` | Comprehensive PDF report compiled with executive summaries, flaw logs, design sheets, baseline analysis, and diagnostic suites. All credentials scrubbed. |
| 9 | **Posted our designer review after the owner group finished** | ✅ COMPLETED | `midterm/designer/06_designer_review/designer_review.md` | Conducted formal evaluation of Group 7's investigation report. Classified findings, commended their exact remediation, and documented peer feedback. |
| 10 | **Every group member can explain both roles** | ✅ COMPLETED | `midterm/defense_preparation_guide.md` | Authored comprehensive defense preparation guide covering designer questions, owner questions, PostgreSQL system catalogs, privileges, and maintenance drills. |
| 11 | **Declared AI usage and validated any AI-generated suggestions** | ✅ COMPLETED | `midterm/reports/midterm_report.md` (Section 14)<br>`midterm/README.md` | Full disclosure of AI assistant usage (Antigravity AI engine). All generated SQL scripts, schema definitions, and diagnostic queries independently verified by team DBAs. |

---

### Individual Member Contribution Sign-off

| Member Name | Student ID / Handle | Midterm Responsibilities & Contributions | Verification Signature |
|---|---|---|:---:|
| **Amoranto, Denielle** | Group Member | Designer Flaw Review (Activity 4 & 5), Baseline Establishment (`PPGG_projectdb`), Owner Investigation Template Architecture, Diagnostic Toolkit Development, Google Sheets Tracker Record Formulation | `[Verified]` |
| **Francisco, Helix** | Repository Owner / Lead | Repository Codebase Inspection, Scenario Formulation (G07-INC1 to G07-INC5), Fault & Reset SQL Script Engineering, Private Instructor Answer Key Compilation, Designer Review, Final PDF Report Assembly, AI Validation Auditing | `[Verified]` |
