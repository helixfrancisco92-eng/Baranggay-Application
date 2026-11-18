# OWNER INCIDENT INVESTIGATION #4

**Incident ID:** `[G12-INC4 — PENDING RELEASE]`  
**Project Owner:** Group 12 — iBarangay: Barangay Document Request System  
**Assigned Designer Group:** `[Assigned Peer Designer Group — Pending Midterm Assignment Release]`  
**Related Activity:** Activity 6 (Backup and Recovery Procedures)  
**Assigned Difficulty:** `[Pending Official Brief]`  
**Target Investigation Database:** `PPGG_projectdb_disposable` (PostgreSQL 18.6 on localhost:5432)  
**Investigation Status:** **WAITING FOR OFFICIAL INCIDENT BRIEF — PENDING RELEASE BY INSTRUCTOR**  

---

### A. INCIDENT OBSERVATION

- **Exact Incident Brief:**  
  `[Awaiting official symptoms-only brief from the assigned peer designer group upon instructor approval.]`
- **Reported Symptoms:**  
  `[Pending official submission. No unauthorized incident fabrication permitted under COMP 018 Midterm Assessment Rules.]`
- **Date & Time Investigated:** Pending release (Workspace initialized November 7, 2026).
- **Database Copy Used:** `PPGG_projectdb_disposable` (Cloned from `PPGG_projectdb`).
- **Account Used for Investigation:** `ibarangay_dba` / `postgres`.

---

### B. BASELINE COMPARISON (Activities 3 to 6 Documentation)

| Baseline Component | Expected Documented Baseline | Actual Current State | Identified Deviation | Operational Relevance |
|---|---|---|---|:---:|
| **Backup Archive Integrity** | `pg_dump -Fc` produces valid custom compressed archive files with size > 0 bytes. | Documented in Activity 6. | None prior to incident release. | Primary focus for Activity 6 recovery. |
| **Restore Verification** | `pg_restore` into a test database reconstructs all 7 tables and sequence states without error. | Documented in Activity 6 report. | None prior to incident release. | To be tested against recovery drills. |
| **Backup Operator Account** | Non-superuser account holds complete read privileges on all tables and sequences. | Defined in `iBarangay-user-role.md`. | None prior to incident release. | To be checked for permission denials. |

---

### C. DIAGNOSTIC VERIFICATION PROTOCOL

Upon release of the official brief, the investigating DBA will execute targeted checks against:
1. **Backup File Catalog & Header Inspection (`pg_restore --list`):**
   ```powershell
   pg_restore.exe --list "backups/PPGG_projectdb_backup.dump"
   ```
2. **Backup Operator Permissions Check:**
   ```sql
   SELECT grantee, table_name, privilege_type 
   FROM information_schema.table_privileges 
   WHERE grantee = 'ibarangay_app' 
   ORDER BY table_name;
   ```
3. **Database Size and Table Counts:**
   ```sql
   SELECT pg_size_pretty(pg_database_size('PPGG_projectdb')) AS db_size;
   SELECT table_name, (xpath('/row/cnt/text()', xml_count))[1]::text::int as row_count
   FROM (
     SELECT table_name, query_to_xml(format('select count(*) as cnt from public.%I', table_name), false, true, '') as xml_count
     FROM information_schema.tables WHERE table_schema = 'public'
   ) t;
   ```

---

### D. HYPOTHESES & ROOT-CAUSE MAPPING

*To be completed following symptom reproduction:*
- **Hypothesis 1:** Backup operator lacks `SELECT` on newly added relations, causing `pg_dump` to fail midway.
- **Hypothesis 2:** Corrupted, truncated, or zero-byte archive file resulting from disk exhaustion or script interruption.
- **Hypothesis 3:** Incompatible target database encoding or missing pre-existing roles during `pg_restore`.

---

### E. TROUBLESHOOTING PLAN

1. **Ordered Diagnostic Steps:**
   - Step 1: Inspect automated backup execution logs and examine generated archive file size.
   - Step 2: Run `pg_restore --list` to inspect table of contents integrity.
   - Step 3: Perform test restore into an isolated disposable database.
   - Step 4: Resolve permission denials or script defects.
2. **Risk Assessment:** Never restore backup archives over live production databases; always test on disposable targets.
3. **Required Account:** `postgres` / `ibarangay_dba`.
4. **Rollback Protocol:** Re-provision clean disposable database copy.

---

### F. TESTING & EMPIRICAL EVIDENCE LOG

- **Command Executed:** `[Pending official incident brief and fault script release]`
- **Observed Database Result:** `[Pending release]`
- **Alternative Explanations Evaluated & Ruled Out:** `[Pending investigation]`

---

### G. CONFIRMED ROOT CAUSE

`[Pending official incident investigation. The verified root cause will be recorded here with supporting logs.]`

---

### H. PROPORTIONATE CORRECTIVE ACTION

`[Pending official investigation. The exact commands applied to PPGG_projectdb_disposable will be recorded here.]`

---

### I. VERIFICATION & REGRESSION TESTING AFTER FIX

- **Dump Execution Return Code:** `[To be documented]`
- **TOC Inspection Verification:** `[To be documented]`
- **Restoration Record Parity:** `[To be documented]`

---

### J. PREVENTIVE DBA RECOMMENDATION

`[To be documented based on root cause findings (e.g., automated restore drills, 3-2-1 backup verification).]`

---

### K. FINAL INVESTIGATION STATUS

**Status:** `WAITING FOR OFFICIAL INCIDENT BRIEF`  
*(Will transition to RESOLVED upon receipt and execution of the instructor-released incident).*
