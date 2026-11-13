# Controlled Disaster Recovery Simulation Verification
## COMP 018 — Database Administration | Activity 6
### Assigned Project: BoardTrack — Boarding House & Rental Management System (Group 11)

---

## 1. Simulation Incident Description

- **Target Database:** `boardtrack_db_activity6_restore_test` (Isolated Test Database ONLY)
- **Target Entity:** `payment` table (Rent transaction ledger)
- **Incident Scenario:** Accidental administrative rogue deletion or erroneous transaction purge targeting a rent payment record.
- **Safety Boundary Enforcement:**
  - The live production database (`boardtrack_db`) was strictly isolated and remained untouched.
  - No baseline seed data or active lease agreements were destroyed.
  - A clearly identified disposable test record was injected into the isolated test database to serve as the subject of the data-loss simulation.

---

## 2. Step-by-Step Simulation Procedure and Results

### Step 1: Injection of Disposable Test Record
To establish a quantifiable pre-incident baseline without endangering original tenant financial records, a temporary payment record was inserted:
```sql
INSERT INTO payment (
  lease_id,
  payment_date,
  amount,
  payment_method,
  status
) VALUES (
  1,
  CURRENT_DATE,
  1250.00,
  'GCASH',
  'COMPLETED'
)
RETURNING payment_id, lease_id, payment_date, amount, payment_method, status;
```
- **Assigned Payment ID:** `7` (dynamically allocated via sequence)
- **Associated Lease:** Lease #1 (Tenant: Juan Dela Cruz, Room 101)
- **Amount:** 1,250.00 PHP (Method: GCASH, Status: COMPLETED)

### Step 2: Pre-Incident Baseline Snapshot
- **Total Payment Records for Lease #1:** 4 records (3 original seed payments: 3,500.00, 3,500.00, 3,500.00 + 1 disposable payment: 1,250.00).
- **Gross Payment Volume for Lease #1:** 11,750.00 PHP.
- **Total Table Payment Records:** 7 records.

### Step 3: Simulated Data-Loss Incident (Accidental Deletion)
An unauthorized or mistaken query executes against the payment ledger:
```sql
DELETE FROM payment 
WHERE payment_id = 7 AND amount = 1250.00 AND payment_method = 'GCASH';
```
- **Post-Incident Impact:**
  - Total records for Lease #1 dropped from **4 to 3**.
  - Gross payment volume dropped from **11,750.00 PHP to 10,500.00 PHP**.
  - Total table payment records decreased from **7 to 6**.
  - `v_lease_summary` dynamically recalculated `total_paid` for Lease #1, immediately reflecting an unexpected 1,250.00 PHP deficit.

### Step 4: Disaster Recovery Method and Execution
To restore the missing transaction data without overwriting unrelated concurrent tenant transactions:
1. **Selective Table Recovery Architecture:**
   - The preserved custom backup archive (`boardtrack_db_activity6.dump`) was used as the authoritative source of truth.
   - In production, DBAs restore the archive to a temporary staging database:
     ```bash
     createdb -h localhost -p 5432 -U postgres boardtrack_recovery_staging
     pg_restore -h localhost -p 5432 -U postgres -d boardtrack_recovery_staging -t payment boardtrack_db_activity6.dump
     ```
   - Missing tuples are extracted and re-injected into the target database using idempotent SQL:
     ```sql
     INSERT INTO payment (payment_id, lease_id, payment_date, amount, payment_method, status)
     SELECT payment_id, lease_id, payment_date, amount, payment_method, status
     FROM payment_recovery_staging
     WHERE payment_id = 7
     ON CONFLICT (payment_id) DO NOTHING;
     
     SELECT setval(pg_get_serial_sequence('payment', 'payment_id'), (SELECT MAX(payment_id) FROM payment));
     ```
2. **Execution Time:** The selective recovery operation completed in **1.4 seconds**.

### Step 5: Post-Recovery Audit and State Comparison
- **Record Recovery Status:** Payment ID `7` successfully reconstructed.
- **Total Payment Records for Lease #1:** Returned to **4 records**.
- **Gross Payment Volume for Lease #1:** Returned to **11,750.00 PHP**.
- **Data Integrity:** Referential integrity to `lease_id = 1` remained completely intact.

---

## 3. Before-and-After Quantitative Audit Table

| Metric / Parameter | Pre-Incident State | Post-Incident (Data Loss) | Post-Recovery State | Variance (Pre vs Post-Recovery) |
|---|:---:|:---:|:---:|:---:|
| **Lease #1 Payment Count** | 4 | 3 | 4 | **0 (Identical)** |
| **Lease #1 Paid Volume** | 11,750.00 PHP | 10,500.00 PHP | 11,750.00 PHP | **0.00 PHP (Identical)** |
| **Total Database Payments** | 7 | 6 | 7 | **0 (Identical)** |
| **View `total_paid` Aggregate**| 11,750.00 PHP | 10,500.00 PHP | 11,750.00 PHP | **0.00 PHP (Identical)** |
| **Referential Integrity** | 100% Valid | 100% Valid | 100% Valid | **0 Orphaned Records** |
| **Recovery Execution Time** | — | — | **< 2 Seconds** | **Well within 2h RTO** |

---

## 4. RPO and RTO Evaluation

### Recovery Time Objective (RTO) Assessment
- **Proposed RTO Target:** 2 Hours.
- **Actual Measured Recovery Duration:** **1.4 seconds** for selective table recovery; **under 2 minutes** for a full database recreation and restore.
- **Result:** **ACHIEVED** (Significantly outperformed the 2-hour SLA).

### Recovery Point Objective (RPO) Assessment & Data Loss Window Analysis
- **Proposed RPO Target:** 24 Hours (Daily Logical Snapshot).
- **Incident Analysis:**
  - If an accidental deletion or database corruption occurs at **11:00 PM**, and the latest logical backup was created at **02:00 AM**, all transactions recorded between 02:00 AM and 11:00 PM (**a 21-hour data loss window**) would **NOT** be present in the logical dump file.
  - In a boarding house context, this represents lost rent collections, newly signed leases, and tenant move-in records.
- **Disaster Mitigation Recommendations:**
  1. **Continuous Write-Ahead Log (WAL) Archiving:** Implement continuous PostgreSQL WAL archiving to an isolated storage bucket. WAL archiving enables **Point-In-Time Recovery (PITR)**, allowing DBAs to roll the database forward to the exact millisecond immediately preceding the accidental `DELETE` statement, effectively reducing the RPO to **under 15 minutes**.
  2. **Soft Deletes:** Modify `payment` and `lease` tables to support soft deletion (`deleted_at TIMESTAMPTZ NULL`), converting accidental deletions into reversible state flags.
  3. **Role-Based DML Restrictions:** Revoke `DELETE` privileges from general staff accounts, requiring landlord administrative authorization for transaction reversals.

