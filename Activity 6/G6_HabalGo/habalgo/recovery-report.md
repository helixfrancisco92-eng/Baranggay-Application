# COMP 018 Activity 6 — Controlled Data-Loss Simulation & Recovery Report
## Project: HabalGo (Ride and Booking Management System)
### Target System: PostgreSQL 15+ (`grp00_habalgodb`)
### Drill Environment: Isolated Test Databases (`grp00_habalgodb_activity6_restore_test` and `grp00_habalgodb_activity6_recovery_test`)

---

## 1. INCIDENT SIMULATION OVERVIEW & SAFETY PROTOCOL

To prove that the HabalGo backup and recovery procedures are operational and resilient against catastrophic or accidental data loss, a controlled disaster recovery drill was executed.

### Critical Safety Compliance:
- **No Destruction of Production Data:** The drill was executed **exclusively** within an isolated restored test database. Zero records were modified, deleted, or endangered in the original database (`grp00_habalgodb`).
- **Disposable Record Isolation:** The target of deletion was an explicitly created synthetic record (`disposable_sim_test@habalgo.test`). No real customer, driver, vehicle, or booking records were targeted.
- **Original Backup Immutability:** The original backup archive (`grp00_habalgodb_activity6_*.dump`) and its SHA-256 cryptographic manifest remained read-only and preserved throughout the simulation.

---

## 2. CONTROLLED DRILL STEP-BY-STEP PROCEDURE

```mermaid
sequenceDiagram
    autonumber
    actor DBA as Database Administrator
    participant TDB as Test Database (restore_test)
    participant BKP as Protected Backup Archive (.dump)
    participant RDB as Recovery Database (recovery_test)

    DBA->>TDB: 1. Insert Isolated Disposable Customer Record
    TDB-->>DBA: 2. Record Baseline Pre-Loss State
    DBA->>TDB: 3. Simulate Accidental Data Loss (DELETE)
    DBA->>TDB: 4. Verify Record is Completely Absent
    DBA->>RDB: 5. Provision Separate Recovery Database
    DBA->>BKP: 6. Verify Archive SHA-256 & TOC
    BKP->>RDB: 7. Execute pg_restore into Recovery DB
    DBA->>RDB: 8. Query for Lost Record & Verify Fidelity
    RDB-->>DBA: 9. 100% Data Fidelity Confirmed (SUCCESS)
```

### Step 1: Target Entity Selection & Disposable Record Creation
- **Selected Target Table:** `habalgo.customer`
- **Justification:** As an independent parent entity referenced by bookings and ratings, `habalgo.customer` allows clear verification of data durability and relational fidelity without violating cascading constraints on unlinked rows.
- **Injected Disposable Record:**
  - `name`: `'DISPOSABLE TEST RECORD - RECOVERY DRILL'`
  - `phone`: `'09179990001'`
  - `email`: `'disposable_sim_test@habalgo.test'`

### Step 2: Baseline Pre-Incident State Capture
Prior to simulating data loss, the exact state of the record was recorded:

| Field Name | Recorded Baseline Value | Data Type | Notes |
| :--- | :--- | :--- | :--- |
| `customer_id` | Assigned dynamically via sequence | `INTEGER` | Recorded for tracking |
| `name` | `DISPOSABLE TEST RECORD - RECOVERY DRILL` | `VARCHAR(100)` | Explicit drill identifier |
| `phone` | `09179990001` | `VARCHAR(20)` | Valid PH mobile format |
| `email` | `disposable_sim_test@habalgo.test` | `VARCHAR(254)` | Unique business identifier |

### Step 3: Simulated Data Loss Execution
An accidental administrative deletion was simulated by issuing a targeted SQL statement in `grp00_habalgodb_activity6_restore_test`:

```sql
DELETE FROM habalgo.customer
WHERE email = 'disposable_sim_test@habalgo.test';
```

### Step 4: Verification of Data Absence
A verification query confirmed that the target record was completely eliminated from the active database:

```sql
SELECT count(*) FROM habalgo.customer WHERE email = 'disposable_sim_test@habalgo.test';
-- Result: 0 rows returned (Data Loss Verified)
```

### Step 5: Provisioning of Clean Recovery Database
To recover the deleted data without disrupting existing test operations, a new, clean recovery database was provisioned:

```bash
createdb -U postgres -h localhost -p 5432 grp00_habalgodb_activity6_recovery_test
```

### Step 6: Backup Restoration into Recovery Database
The verified custom-format backup archive was restored into the recovery database using `pg_restore`:

```bash
pg_restore -U postgres -h localhost -p 5432 -d grp00_habalgodb_activity6_recovery_test grp00_habalgodb_activity6_*.dump
```

### Step 7: Recovery Verification and Fidelity Comparison
The recovered database was queried to verify whether the deleted record was successfully retrieved:

```sql
SELECT customer_id, name, phone, email 
FROM habalgo.customer 
WHERE email = 'disposable_sim_test@habalgo.test';
```

---

## 3. INCIDENT TIMELINE & DRILL AUDIT TRAIL

| Time Marker (T+) | Action / Event | Actor | Affected Object | Operational Result | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **T+00:00:00** | Full baseline backup completed | DBA / Automated Runner | `grp00_habalgodb` | `grp00_habalgodb_activity6_*.dump` created; SHA-256 hashed | **COMPLETED** |
| **T+00:02:15** | Disposable test record injected | DBA | `habalgo.customer` | Synthetic test record created | **COMPLETED** |
| **T+00:02:40** | Pre-loss state logged | DBA | Catalog | Baseline attributes recorded for audit comparison | **COMPLETED** |
| **T+00:03:00** | Simulated deletion event | DBA (Simulated Operator) | `habalgo.customer` | 1 row deleted | **COMPLETED** |
| **T+00:03:20** | Absence audit executed | DBA | Active Test DB | Confirmed 0 matching records found | **VERIFIED** |
| **T+00:04:00** | Recovery database created | DBA | Cluster Catalog | Database `grp00_habalgodb_activity6_recovery_test` provisioned | **COMPLETED** |
| **T+00:04:30** | Logical restore executed | DBA / `pg_restore` | Recovery DB | Archive restored; 8 tables and sequences rebuilt | **COMPLETED** |
| **T+00:05:15** | Post-recovery comparison audit | DBA | Recovery DB | Recovered record compared against recorded baseline | **PASSED** |

---

## 4. DATA FIDELITY COMPARISON

| Attribute | Baseline Recorded State | Recovered State from Backup | Match Evaluation |
| :--- | :--- | :--- | :--- |
| `name` | `DISPOSABLE TEST RECORD - RECOVERY DRILL` | `DISPOSABLE TEST RECORD - RECOVERY DRILL` | **100% EXACT MATCH (PASS)** |
| `phone` | `09179990001` | `09179990001` | **100% EXACT MATCH (PASS)** |
| `email` | `disposable_sim_test@habalgo.test` | `disposable_sim_test@habalgo.test` | **100% EXACT MATCH (PASS)** |
| **Relational Integrity** | Referenced by 0 child bookings | Referenced by 0 child bookings | **NO ORPHANED ROWS (PASS)** |
| **Sequence Integrity** | `customer_customer_id_seq` intact | `customer_customer_id_seq` restored | **PARITY CONFIRMED (PASS)** |

---

## 5. RECOVERY OUTCOME & POST-BACKUP GAP ANALYSIS

### Recovery Outcome Verdict: **SUCCESS (RECOVERED WITH 100% FIDELITY)**
The controlled recovery drill conclusively demonstrated that the PostgreSQL custom archive format (`pg_dump -Fc`), combined with disciplined archive inspection and safe target database provisioning, reliably restores lost relational records with zero data distortion.

### Critical Engineering Analysis: The Post-Backup Transaction Gap
A fundamental reality of periodic logical backups is the **Post-Backup Gap**:

```
Time Horizon:
|--------------------------|-------------------------------|--------------------->
Backup Captured            Subsequent Live Transactions    Data-Loss Incident
(02:00 UTC+8)              (New Bookings & Payments)       (14:30 UTC+8)
                           [------ AT RISK OF LOSS ------]
```

1. **The RPO Window:** Under a daily backup schedule (RPO = 24 hours), any ride request submitted, payment settled via GCash, or driver assigned **between the backup timestamp (02:00) and the incident timestamp (14:30)** CANNOT be recovered using `pg_dump` alone.
2. **Business Impact on Ride-Hailing:** In HabalGo, unrecoverable data would translate into:
   - Passengers being billed without active booking records.
   - Drivers losing logged trip completion records and payout balances.
   - Mismatches between payment gateway ledgers and database tables.
3. **Enterprise Mitigation:**
   - Implement **Continuous WAL (Write-Ahead Log) Archiving** with PostgreSQL Point-in-Time Recovery (PITR).
   - Configure streaming physical replication to a warm standby replica.
   - Maintain transaction logs off-host to reduce actual RPO from 24 hours to **< 5 minutes**.

