# OWNER INCIDENT INVESTIGATION #3

**Incident ID:** `[G12-INC3 — PENDING RELEASE]`  
**Project Owner:** Group 12 — iBarangay: Barangay Document Request System  
**Assigned Designer Group:** `[Assigned Peer Designer Group — Pending Midterm Assignment Release]`  
**Related Activity:** Activity 5 (Performance, Monitoring & Maintenance)  
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
| **Index Catalog** | Foreign key and identity primary key indexes active on all operational tables. | Documented in Activity 3 & 5. | None prior to incident release. | Primary focus for Activity 5 performance. |
| **Table Bloat & Dead Tuples** | Routine `VACUUM` and `ANALYZE` maintains `n_dead_tup` near 0 on operational tables. | Healthy baseline maintained. | None prior to incident release. | To be checked for artificial dead-tuple bloat. |
| **Query Plans** | Primary key joins and citizen lookups execute via Index Scan / Bitmap Scan under 2 ms. | Profiled in Activity 5. | None prior to incident release. | To be inspected via `EXPLAIN (ANALYZE, BUFFERS)`. |

---

### C. DIAGNOSTIC VERIFICATION PROTOCOL

Upon release of the official brief, the investigating DBA will execute targeted checks against:
1. **Query Plan Profiling (`EXPLAIN (ANALYZE, BUFFERS)`):**
   ```sql
   EXPLAIN (ANALYZE, BUFFERS)
   SELECT dr.request_id, c.first_name, c.last_name, dt.name, dr.status, dr.request_date
   FROM public.document_requests dr
   JOIN public.citizens c ON dr.citizen_id = c.citizen_id
   JOIN public.document_types dt ON dr.document_type_id = dt.document_type_id
   WHERE dr.status = 'PENDING';
   ```
2. **Table Statistics and Bloat (`pg_stat_user_tables`):**
   ```sql
   SELECT relname, n_live_tup, n_dead_tup, last_vacuum, last_analyze, vacuum_count, analyze_count
   FROM pg_stat_user_tables 
   WHERE schemaname = 'public' 
   ORDER BY n_dead_tup DESC;
   ```
3. **Index Usage and Missing Index Catalog (`pg_stat_user_indexes`):**
   ```sql
   SELECT relname, indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
   FROM pg_stat_user_indexes 
   WHERE schemaname = 'public';
   ```

---

### D. HYPOTHESES & ROOT-CAUSE MAPPING

*To be completed following symptom reproduction:*
- **Hypothesis 1:** Dropped or missing index forcing costly sequential scans (`Seq Scan`) on large operational tables.
- **Hypothesis 2:** Stale query planner statistics causing suboptimal join algorithms (e.g. nested loops instead of hash joins).
- **Hypothesis 3:** Severe dead-tuple accumulation resulting in I/O degradation and table bloat.

---

### E. TROUBLESHOOTING PLAN

1. **Ordered Diagnostic Steps:**
   - Step 1: Capture execution plan of slow dashboard query using `EXPLAIN (ANALYZE, BUFFERS)`.
   - Step 2: Query `pg_stat_user_tables` to inspect dead tuple counts and last analyze timestamps.
   - Step 3: Check `pg_indexes` for missing status or foreign key indexes.
   - Step 4: Formulate targeted index creation or `VACUUM ANALYZE` maintenance.
2. **Risk Assessment:** Re-indexing or vacuuming high-churn tables requires minimal locks; avoid `VACUUM FULL` during production traffic.
3. **Required Account:** `postgres` / `ibarangay_dba`.
4. **Rollback Protocol:** Drop newly created index if performance gain is not demonstrated.

---

### F. TESTING & EMPIRICAL EVIDENCE LOG

- **Command Executed:** `[Pending official incident brief and fault script release]`
- **Observed Database Result:** `[Pending release]`
- **Alternative Explanations Evaluated & Ruled Out:** `[Pending investigation]`

---

### G. CONFIRMED ROOT CAUSE

`[Pending official incident investigation. The verified root cause will be recorded here with supporting query plans.]`

---

### H. PROPORTIONATE CORRECTIVE ACTION

`[Pending official investigation. The exact SQL commands applied to PPGG_projectdb_disposable will be recorded here.]`

---

### I. VERIFICATION & REGRESSION TESTING AFTER FIX

- **Execution Plan Comparison:** `[To be documented with before/after execution times]`
- **Buffer Hit Verification:** `[To be documented]`
- **System Resource Metrics:** `[To be documented]`

---

### J. PREVENTIVE DBA RECOMMENDATION

`[To be documented based on root cause findings (e.g., autovacuum threshold tuning, automated index health monitoring).]`

---

### K. FINAL INVESTIGATION STATUS

**Status:** `WAITING FOR OFFICIAL INCIDENT BRIEF`  
*(Will transition to RESOLVED upon receipt and execution of the instructor-released incident).*
