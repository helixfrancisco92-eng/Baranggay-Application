# OWNER INCIDENT INVESTIGATION #5

**Incident ID:** `[G12-INC5 — PENDING RELEASE]`  
**Project Owner:** Group 12 — iBarangay: Barangay Document Request System  
**Assigned Designer Group:** `[Assigned Peer Designer Group — Pending Midterm Assignment Release]`  
**Related Activity:** Activities 2 to 5 (Free Choice: Primary Key Sequences, Constraints & Data Integrity)  
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
| **Identity Sequence Alignment** | All identity sequences (`admins_admin_id_seq`, `citizens_citizen_id_seq`, etc.) synchronized with `MAX(id)`. | Configured per Flyway V2. | None prior to incident release. | Primary candidate for sequence desynchronization. |
| **Check Constraints** | Rejection remarks required when status is `REJECTED`; valid request statuses enforced. | Documented in `V1__initial_schema.sql`. | None prior to incident release. | To be checked for constraint violations. |
| **Data Completeness** | Document requests require valid citizen and document type associations. | Enforced by foreign keys. | None prior to incident release. | Baseline intact. |

---

### C. DIAGNOSTIC VERIFICATION PROTOCOL

Upon release of the official brief, the investigating DBA will execute targeted checks against:
1. **Sequence State & Alignment (`pg_sequences`, `last_value`):**
   ```sql
   SELECT schemaname, sequencename, last_value 
   FROM pg_sequences 
   WHERE schemaname = 'public';

   -- Compare sequence last_value against table MAX(id):
   SELECT 'citizens' AS tbl, MAX(citizen_id) AS max_id, 
          (SELECT last_value FROM public.citizens_citizen_id_seq) AS seq_val 
   FROM public.citizens
   UNION ALL
   SELECT 'document_requests', MAX(request_id), 
          (SELECT last_value FROM public.document_requests_request_id_seq) 
   FROM public.document_requests;
   ```
2. **Constraint Definitions & Validation (`pg_constraint`):**
   ```sql
   SELECT conname, contype, pg_get_constraintdef(oid) 
   FROM pg_constraint 
   WHERE conrelid IN ('document_requests'::regclass, 'citizens'::regclass);
   ```

---

### D. HYPOTHESES & ROOT-CAUSE MAPPING

*To be completed following symptom reproduction:*
- **Hypothesis 1:** Sequence desynchronization causing `duplicate key value violates unique constraint` on primary keys (`SQLSTATE 23505`).
- **Hypothesis 2:** Unenforced or conflicting check constraint causing transaction abortion on valid workflow transitions.
- **Hypothesis 3:** Orphaned foreign key references or missing parent records.

---

### E. TROUBLESHOOTING PLAN

1. **Ordered Diagnostic Steps:**
   - Step 1: Attempt to insert a test citizen or document request; capture error output.
   - Step 2: If unique violation occurs on PK, inspect sequence `last_value` vs `MAX(id)`.
   - Step 3: Resynchronize sequence via `SELECT setval(..., (SELECT MAX(id) FROM ...), true);`.
   - Step 4: Verify insertion without specifying primary key ID.
2. **Risk Assessment:** Sequence adjustments must only increment values forward; setting sequence values below `MAX(id)` causes duplicate key collisions.
3. **Required Account:** `postgres` / `ibarangay_dba`.
4. **Rollback Protocol:** Re-set sequence value to previous known state.

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

- **Sequence Auto-Increment Test:** `[To be documented]`
- **Duplicate Insertion Negative Test:** `[To be documented]`
- **Application Workflow End-to-End Test:** `[To be documented]`

---

### J. PREVENTIVE DBA RECOMMENDATION

`[To be documented based on root cause findings (e.g., sequence synchronization triggers, automated migration hooks).]`

---

### K. FINAL INVESTIGATION STATUS

**Status:** `WAITING FOR OFFICIAL INCIDENT BRIEF`  
*(Will transition to RESOLVED upon receipt and execution of the instructor-released incident).*
