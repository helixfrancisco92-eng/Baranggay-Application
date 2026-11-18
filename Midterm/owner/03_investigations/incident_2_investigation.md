# OWNER INCIDENT INVESTIGATION #2

**Incident ID:** `[G12-INC2 — PENDING RELEASE]`  
**Project Owner:** Group 12 — iBarangay: Barangay Document Request System  
**Assigned Designer Group:** `[Assigned Peer Designer Group — Pending Midterm Assignment Release]`  
**Related Activity:** Activities 3 to 5 (Missing or Incorrect Object, Configuration, or Connection)  
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
| **Schema Objects** | All 7 tables, primary key constraints, foreign key constraints, and default timestamps active. | Verified active via Flyway V1–V3. | None prior to incident release. | Primary focus for Activity 3 object scenarios. |
| **Connection Configuration** | Spring Boot connects to `localhost:5432/PPGG_projectdb` via `org.postgresql.Driver`. | Configured in `application.properties`. | None prior to incident release. | Baseline intact. |
| **Referential Integrity** | `document_requests` maintains valid foreign keys to `citizens`, `document_types`, and `admins`. | Documented in `V1__initial_schema.sql`. | None prior to incident release. | Baseline intact. |

---

### C. DIAGNOSTIC VERIFICATION PROTOCOL

Upon release of the official brief, the investigating DBA will execute targeted checks against:
1. **Object Catalog Verification (`information_schema.tables`, `pg_class`):**
   ```sql
   SELECT table_name, table_type 
   FROM information_schema.tables 
   WHERE table_schema = 'public' 
   ORDER BY table_name;
   ```
2. **Foreign Key and Constraint Metadata (`pg_constraint`):**
   ```sql
   SELECT conname, conrelid::regclass, confrelid::regclass, contype, confdeltype 
   FROM pg_constraint 
   WHERE connamespace = 'public'::regnamespace;
   ```
3. **Connection Parameter Inspection (`pg_settings`):**
   ```sql
   SELECT name, setting, unit, context FROM pg_settings WHERE name IN ('listen_addresses', 'port', 'max_connections');
   ```

---

### D. HYPOTHESES & ROOT-CAUSE MAPPING

*To be completed following symptom reproduction:*
- **Hypothesis 1:** Schema object (view, constraint, or foreign key) dropped, corrupted, or missing.
- **Hypothesis 2:** Database connection failure resulting from port, host, or credential misconfiguration.
- **Hypothesis 3:** Incompatible column definition or missing default expression.

---

### E. TROUBLESHOOTING PLAN

1. **Ordered Diagnostic Steps:**
   - Step 1: Attempt to reproduce application connection or query error on disposable copy.
   - Step 2: Query `information_schema.tables` and `pg_constraint` to identify missing or altered objects.
   - Step 3: Compare discovered state with `V1__initial_schema.sql` and `V2__improve_database_structure.sql`.
   - Step 4: Prepare non-destructive DDL correction.
2. **Risk Assessment:** Applying schema DDL must avoid dropping existing citizen or request records.
3. **Required Account:** `postgres` (Schema modification authority).
4. **Rollback Protocol:** Revert DDL changes via inverse SQL statements.

---

### F. TESTING & EMPIRICAL EVIDENCE LOG

- **Command Executed:** `[Pending official incident brief and fault script release]`
- **Observed Database Result:** `[Pending release]`
- **Alternative Explanations Evaluated & Ruled Out:** `[Pending investigation]`

---

### G. CONFIRMED ROOT CAUSE

`[Pending official incident investigation. The verified root cause will be recorded here with supporting catalog evidence.]`

---

### H. PROPORTIONATE CORRECTIVE ACTION

`[Pending official investigation. The exact SQL commands applied to PPGG_projectdb_disposable will be recorded here.]`

---

### I. VERIFICATION & REGRESSION TESTING AFTER FIX

- **Object Existence Verification:** `[To be documented]`
- **Application Workflow Test:** `[To be documented]`
- **Data Integrity Preservation:** `[To be documented]`

---

### J. PREVENTIVE DBA RECOMMENDATION

`[To be documented based on root cause findings (e.g., Flyway migration validation in CI/CD, foreign key drift detection).]`

---

### K. FINAL INVESTIGATION STATUS

**Status:** `WAITING FOR OFFICIAL INCIDENT BRIEF`  
*(Will transition to RESOLVED upon receipt and execution of the instructor-released incident).*
