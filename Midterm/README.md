# COMP 018 — Database Administration: Midterm Examination

## Integrated Database Administration Challenge
**Review, Design, Investigate, Troubleshoot, and Defend**

---

### Project Information & Course Metadata

| Field | Details |
|---|---|
| **Course** | COMP 018 — Database Administration |
| **Academic Term** | Midterm Examination |
| **Evaluating / Defending Group** | **Group 12 — iBarangay: Barangay Document Request System** |
| **Group Members** | Amoranto, Denielle & Francisco, Helix |
| **Our Repository** | [https://github.com/helixfrancisco92-eng/Baranggay-Application](https://github.com/helixfrancisco92-eng/Baranggay-Application) |
| **Our Database Platform** | PostgreSQL 18.6 / Spring Boot JPA (Flyway Migrations V1–V3) |
| **Our Primary Database** | `PPGG_projectdb` |
| **Assigned Evaluation Target (Designer Role)** | **Group 7 — CAMPUSAFE: Campus Hazard & Safety Reporting System** |
| **Group 7 Repository** | [https://github.com/jeffersonorpesa2-ops/grp07-campussafe](https://github.com/jeffersonorpesa2-ops/grp07-campussafe) |
| **Group 7 Database Platform** | PostgreSQL 14+ / PHP 8+ PDO |
| **Group 7 Primary Database** | `grp07_campussafedb` |
| **Class Google Sheets Tracker** | `[BSIT 3-1] - PROJECT TRACKER.xlsx` (Midterm Tab, Rows 8 & 12) |

---

### Executive Overview & Dual Role Structure

This midterm assessment evaluates operational proficiency, security enforcement, relational modeling, and incident troubleshooting under realistic database administration workflows. In compliance with the course syllabus and official midterm guidelines, Group 12 executes two operational roles:

```
                          ┌────────────────────────────────────────────────────────┐
                          │         COMP 018 MIDTERM DUAL-ROLE WORKFLOW           │
                          └────────────────────────────────────────────────────────┘
                                                       │
                     ┌─────────────────────────────────┴─────────────────────────────────┐
                     ▼                                                                   ▼
       ┌───────────────────────────┐                                       ┌───────────────────────────┐
       │   ROLE 1: DESIGNER GROUP  │                                       │    ROLE 2: OWNER GROUP    │
       │   (Auditing Group 7)      │                                       │   (Defending Group 12)    │
       ├───────────────────────────┤                                       ├───────────────────────────┤
       │ 1. Inspect CAMPUSAFE repo │                                       │ 1. Establish DB baseline  │
       │ 2. Document 5 real flaws  │                                       │    (Activities 3, 4, 5, 6)│
       │ 3. Design 5 safe incidents│                                       │ 2. Receive official briefs│
       │ 4. Build fault/reset SQL  │                                       │ 3. 8-step investigation   │
       │ 5. Private answer key     │                                       │ 4. Disposable DB fixes    │
       │ 6. Review owner results   │                                       │ 5. Verification & prevent │
       └───────────────────────────┘                                       └───────────────────────────┘
```

#### Role 1 — Designer Group (Auditing Group 7 – CAMPUSAFE)
1. **Codebase & Schema Inspection:** Thoroughly reviewed Group 7's repository (`grp07-campussafe`), database setup scripts (`01_schema.sql`, `02_seed.sql`, `03_roles_and_privileges.sql`), configuration (`Database.php`, `.env.example`), and Activity 3–6 progress documentation.
2. **Flaw Identification:** Identified and documented five evidence-based flaws and realistic risks (`G07-F1` through `G07-F5`) spanning role privileges, cascading referential integrity, trigger-based audit logging, schema normalization constraints, and conditional state completeness.
3. **Incident Design:** Designed five safe, reproducible, and solvable incident scenarios (`G07-INC1` through `G07-INC5`) strictly balanced by difficulty (2 Easy, 2 Medium, 1 Hard) and covering all required activity areas.
4. **Fault & Reset Scripts:** Authored idempotent, commented, and safe PostgreSQL fault and reset scripts for isolated execution on disposable database copies (`campussafe_midterm_test`).
5. **Private Instructor Pack:** Compiled a private instructor-only answer key with comprehensive root-cause proof, expected commands, negative/positive verification tests, and rollback instructions.
6. **Designer Review:** Evaluated Group 7's owner investigation response against our answer key, validating that Group 7 resolved the incidents with high technical precision.

#### Role 2 — Owner Group (Investigating & Defending iBarangay)
1. **Baseline Establishment:** Established the authoritative database baseline for iBarangay (`PPGG_projectdb`) across Activities 3, 4, 5, and 6, documenting all 7 relational tables, Flyway migrations, identity sequences, and least-privilege RBAC policies (`ibarangay_runtime_grp`).
2. **Official Incident Handling:** Prepared the official owner investigation suite. In adherence to assessment instructions, official incident briefs designed by the assigned peer designer group are tracked through the instructor. Structured investigation templates are maintained and marked pending instructor release.
3. **Troubleshooting & Remediation Protocol:** Established an 8-step DBA troubleshooting procedure (*Observe $\rightarrow$ Verify $\rightarrow$ Hypothesize $\rightarrow$ Test $\rightarrow$ Act $\rightarrow$ Verify $\rightarrow$ Document $\rightarrow$ Prevent*) for disposable test databases.
4. **Diagnostic SQL Toolkit:** Built a production-grade PostgreSQL diagnostic suite for database inspection, catalog querying, sequence synchronization, bloat monitoring, and access-control verification.

---

### Midterm Workspace Directory Structure

```
midterm/
│
├── README.md                                   # Root project overview and role navigation
├── submission_checklist.md                     # Assessment compliance checklist
├── defense_preparation_guide.md                # Comprehensive technical defense Q&A and SQL drills
│
├── designer/                                   # ROLE 1: Group 12 auditing Group 7 (CAMPUSAFE)
│   ├── 01_repository_inspection/
│   │   ├── campussafe_repository_inventory.md  # Detailed catalog of all Group 7 files & components
│   │   └── campussafe_baseline_comparison.md   # Comparison between documented design and implementation
│   │
│   ├── 02_flaw_review/
│   │   ├── flaw_register.md                    # Master Flaw Register (G07-F1 through G07-F5)
│   │   ├── flaw_1.md                           # Excessive UPDATE privileges on app_user (Activity 4)
│   │   ├── flaw_2.md                           # ON DELETE CASCADE destroying compliance audit trail (Act 3/4)
│   │   ├── flaw_3.md                           # Missing trigger for automated status history logging (Act 3/5)
│   │   ├── flaw_4.md                           # Backup role privilege omission & global catalog gap (Act 6)
│   │   └── flaw_5.md                           # Missing candidate key & conditional priority check (Act 3/5)
│   │
│   ├── 03_incident_designs/                    # Public incident briefs (symptoms only, no root causes)
│   │   ├── G07-INC1-public.md                  # Scenario 1: Privilege Escalation & Role Tampering (Easy, 15m)
│   │   ├── G07-INC2-public.md                  # Scenario 2: Historical Audit Trail Purge Anomaly (Medium, 25m)
│   │   ├── G07-INC3-public.md                  # Scenario 3: Bypassed State Transition Audit Logging (Med, 25m)
│   │   ├── G07-INC4-public.md                  # Scenario 4: Automated Backup Service Extraction Failure (Hard, 30m)
│   │   └── G07-INC5-public.md                  # Scenario 5: Duplicate Physical Locations & Untriaged Reports (Easy, 15m)
│   │
│   ├── 04_private_instructor_pack/             # INSTRUCTOR ONLY: Hidden until post-defense
│   │   ├── answer_key.md                       # Comprehensive 14-section answer key for all 5 scenarios
│   │   ├── G07-INC1-fault.sql                  # Fault injection script for Scenario 1
│   │   ├── G07-INC1-reset.sql                  # Safe baseline reset script for Scenario 1
│   │   ├── G07-INC2-fault.sql                  # Fault injection script for Scenario 2
│   │   ├── G07-INC2-reset.sql                  # Safe baseline reset script for Scenario 2
│   │   ├── G07-INC3-fault.sql                  # Fault injection script for Scenario 3
│   │   ├── G07-INC3-reset.sql                  # Safe baseline reset script for Scenario 3
│   │   ├── G07-INC4-fault.sql                  # Fault injection script for Scenario 4
│   │   ├── G07-INC4-reset.sql                  # Safe baseline reset script for Scenario 4
│   │   ├── G07-INC5-fault.sql                  # Fault injection script for Scenario 5
│   │   └── G07-INC5-reset.sql                  # Safe baseline reset script for Scenario 5
│   │
│   ├── 05_script_testing/
│   │   └── script_test_results.md              # Disposable database test execution log & pre-requisites
│   │
│   └── 06_designer_review/
│       └── designer_review.md                  # Evaluation of Group 7's investigation results & peer feedback
│
├── owner/                                      # ROLE 2: Group 12 defending iBarangay
│   ├── 01_ibarangay_baseline/
│   │   └── ibarangay_database_baseline.md      # Authoritative database baseline (Activities 3 to 6)
│   │
│   ├── 02_official_incident_briefs/
│   │   └── README.md                           # Official incident intake repository & assignment verification
│   │
│   ├── 03_investigations/
│   │   ├── incident_1_investigation.md         # Owner Investigation Template 1 (Waiting Official Brief)
│   │   ├── incident_2_investigation.md         # Owner Investigation Template 2 (Waiting Official Brief)
│   │   ├── incident_3_investigation.md         # Owner Investigation Template 3 (Waiting Official Brief)
│   │   ├── incident_4_investigation.md         # Owner Investigation Template 4 (Waiting Official Brief)
│   │   └── incident_5_investigation.md         # Owner Investigation Template 5 (Waiting Official Brief)
│   │
│   ├── 04_sql_diagnostics/
│   │   ├── README.md                           # Diagnostic toolkit guide & usage instructions
│   │   ├── 01_connection_and_database.sql      # Connection, database size, active sessions, and version
│   │   ├── 02_schema_and_catalog.sql           # Tables, columns, constraints, foreign keys, and indexes
│   │   ├── 03_access_control_and_roles.sql     # Roles, memberships, table grants, and column privileges
│   │   ├── 04_performance_and_maintenance.sql  # Buffer cache hit ratio, dead tuples, bloat, and statistics
│   │   └── 05_backup_and_recovery.sql          # WAL archiving status, sequence max synchronization, and TOC
│   │
│   └── 05_verification/
│       └── verification_results.md             # Baseline verification evidence & integrity test suite
│
├── tracker/
│   ├── flaw_register.csv                       # Class tracker-ready CSV for Flaw Register tab
│   └── incident_register.csv                   # Class tracker-ready CSV for Incident Register tab
│
├── evidence/
│   ├── designer/                               # Evidence artifacts from CAMPUSAFE audit
│   │   └── README.md
│   └── owner/                                  # Evidence artifacts from iBarangay baseline & tests
│       └── README.md
│
└── reports/
    ├── midterm_report.md                       # Comprehensive markdown report (Phases A–L)
    └── COMP018_Midterm_Group12_Report.pdf       # Formatted PDF report for submission
```

---

### Safety and Compliance Guidelines

1. **Read-Only Peer Policy:** Group 7's repository (`grp07-campussafe`) and original database (`grp07_campussafedb`) are treated strictly as read-only. No commits, branches, or database modifications were ever directed at Group 7's assets.
2. **Disposable Test Environment:** All destructive testing, fault simulation, and reset validation must be executed exclusively on isolated disposable database instances (e.g., `campussafe_midterm_test` or `ibarangay_midterm_test`).
3. **No Superuser Crutches:** Corrective actions and verifications adhere strictly to the principle of least privilege, using dedicated runtime, maintenance, or audit accounts rather than bypassing controls with `postgres` superuser.
4. **Credential Isolation:** No live passwords, private connection strings, or real citizen personal data are stored in this repository or generated reports.
5. **Academic Integrity:** All peer findings and baseline data are grounded in reproducible SQL outputs, verifiable source code lines, and authoritative activity documentation.
