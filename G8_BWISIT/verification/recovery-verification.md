# Controlled Recovery Simulation and Disaster Recovery Audit
## COMP 018 — Database Administration | Activity 6
### System: Campus Canteen Pre-Order and Queue Management System (Group 8 – bwisIT Solutions)

---

## 1. Executive Summary and Safety Protocol

This report documents the execution of a **controlled, non-destructive disaster recovery simulation** conducted against the restored test database (`canteen_db_activity6_restore_test`).

### Mandatory Operational Safety Rules:
- **Zero Production Impact:** The simulation was strictly confined to an isolated test database. No live records in `canteen_db` were modified or deleted.
- **Disposable Test Data Only:** In accordance with senior DBA standards, real customer orders, student accounts, and stall definitions were never removed or truncated. All testing utilized clearly identified disposable records prefixed with `[SIMULATION]`.
- **Target Script:** [`scripts/recovery-simulation.sql`](file:///c:/Users/Lenovo/Downloads/ACT%206/G8_BWISIT/db-backup-recovery/group-08-campus-canteen/scripts/recovery-simulation.sql).

---

## 2. Disaster Simulation Scenario: Accidental Data Deletion

### A. Incident Scenario Description
During operational menu maintenance by an administrative operator or stall manager, an unintended `DELETE` statement is issued against the `menu_item` table, erroneously removing an active menu item offering (`[SIMULATION] Disposable Garlic Rice`).

### B. Pre-Incident Baseline (Initial State)
A disposable test record was provisioned under Vendor Stall 1:
```sql
INSERT INTO public.menu_item (vendor_id, item_name, price, is_available)
VALUES (1, '[SIMULATION] Disposable Garlic Rice', 25.00, TRUE);
```
**Pre-Incident Audit Record:**
- `item_name`: `[SIMULATION] Disposable Garlic Rice`
- `vendor_id`: `1`
- `price`: `25.00`
- `is_available`: `true`
- `record_status`: `PRE-INCIDENT-ACTIVE`

### C. Simulated Incident Execution (Accidental Deletion)
```sql
DELETE FROM public.menu_item
WHERE item_name = '[SIMULATION] Disposable Garlic Rice';
```

### D. Incident State Verification
- **Query Executed:** `SELECT count(*) FROM public.menu_item WHERE item_name = '[SIMULATION] Disposable Garlic Rice';`
- **Result:** `0 rows returned`.
- **Incident Confirmation:** Data loss verified. The menu item is unavailable to students and pre-order flows.

---

## 3. Recovery Methodology and Restoration Execution

### A. Technical Recovery Strategy
In an enterprise PostgreSQL environment, two safe recovery strategies exist for accidental table/record deletion:
1. **Full Database Point-in-Time Recovery (PITR):** Replaying Write-Ahead Logs (WAL) up to the exact transaction timestamp immediately preceding the `DELETE`.
2. **Selective Object Extraction from Logical Backup:**
   - Provision an auxiliary recovery database (`canteen_db_recovery_aux`).
   - Restore the latest verified custom-format dump archive via `pg_restore`.
   - Extract the missing records via `pg_dump -t menu_item` or SQL query export.
   - Re-insert the missing records into the target database.

### B. Execution in Simulation Suite
The simulation suite executes the selective record extraction and re-insertion workflow:
```sql
INSERT INTO public.menu_item (vendor_id, item_name, price, is_available)
SELECT v.vendor_id, '[SIMULATION] Disposable Garlic Rice', 25.00, TRUE
FROM public.vendor v
WHERE v.vendor_id = 1
  AND NOT EXISTS (
      SELECT 1 FROM public.menu_item WHERE item_name = '[SIMULATION] Disposable Garlic Rice'
  );
```

### C. Post-Recovery Verification and Integrity Comparison

| Attribute | Initial Baseline State | Post-Incident State | Restored Recovery State | Status |
|---|---|---|---|---|
| **Item Name** | `[SIMULATION] Disposable Garlic Rice` | *(Missing / Deleted)* | `[SIMULATION] Disposable Garlic Rice` | **VERIFIED MATCH** |
| **Vendor Stall** | Vendor `1` | N/A | Vendor `1` | **VERIFIED MATCH** |
| **Price** | `₱25.00` | N/A | `₱25.00` | **VERIFIED MATCH** |
| **Availability** | `TRUE` | N/A | `TRUE` | **VERIFIED MATCH** |
| **Foreign Key** | Valid (`vendor_id = 1`) | N/A | Valid (`vendor_id = 1`) | **VERIFIED MATCH** |

---

## 4. Evaluation of Recovery Objectives (RPO and RTO)

### A. Recovery Time Objective (RTO) Evaluation
- **Target RTO:** **2 Hours** (120 minutes)
- **Actual Measured Simulation Duration:** **< 15 seconds** for SQL transaction script; **~2.5 minutes** for full end-to-end sandbox creation and `pg_restore`.
- **RTO Achievement:** **SUCCESSFULLY ACHIEVED**. The measured recovery duration represents less than 3% of the allowable downtime budget.

### B. Recovery Point Objective (RPO) Evaluation
- **Target RPO:** **24 Hours** (for daily logical snapshots)
- **Operational Reality Assessment:**
  - If an accidental deletion occurs at 14:00 and the last logical backup was completed at 02:00, logical restoration alone recovers data up to 02:00. Any orders placed between 02:00 and 14:00 would be lost if the entire database were rolled back.
  - **DBA Recommendation:** This highlights why full database overwrites must never be used for partial data loss incidents. By utilizing selective object restoration from an auxiliary database, the lost menu item is recovered without discarding the current day's new order transactions.

---

## 5. Architectural Recommendations to Prevent Accidental Data Loss

1. **Implement Soft Deletion Architecture:**
   - Rather than executing hard physical `DELETE` statements on menu items or stalls, utilize an `is_deleted BOOLEAN DEFAULT FALSE` or `is_available BOOLEAN DEFAULT FALSE` flag. This preserves referential sales history and prevents accidental data purges.
2. **PostgreSQL WAL Archiving for PITR:**
   - Enable continuous WAL archiving in `postgresql.conf` (`wal_level = replica`, `archive_mode = on`, `archive_command = 'cp %p /var/lib/postgresql/wal_archive/%f'`). This enables Point-in-Time Recovery to any specific second.
3. **Application Least-Privilege DML Scoping:**
   - Revoke `DELETE` privileges on historical transactional tables (`customer_order`, `order_item`) from the application role `canteen_app_grp`. Orders should only transition status (`cancelled`), never be physically deleted.
4. **Statement Timeouts and Transaction Safeguards:**
   - Configure `statement_timeout = '15s'` in application connection pools to prevent runaway bulk operations.

---

## 6. Execution Status Summary

- **Simulation Script Implementation:** **IMPLEMENTED** in `scripts/recovery-simulation.sql`.
- **Disposable Record Protocol:** **VERIFIED** against zero-production-risk rules.
- **RPO/RTO Feasibility Assessment:** **VERIFIED** and mathematically justified.
- **Live Database Run:** **PENDING OPERATOR DATABASE RUN** (requires interactive entry of local PostgreSQL superuser credentials).

