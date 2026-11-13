# CampusSafe — Database Restoration Report
## Assigned Project: Group 7 — CampusSafe
### Course: COMP 018 — Database Administration (Activity 6)

---

## 1. Safety Mandate & Cardinal Rule of Database Recovery

> [!CAUTION]
> **Cardinal Rule of Database Recovery:** NEVER restore a backup snapshot directly over an active production database (`grp07_campussafedb`). Doing so risks irreversible data loss, downtime, lock contention, and unintentional schema regression.
>
> All Activity 6 restoration testing must be executed strictly within an isolated, freshly provisioned test database.

---

## 2. Test Database Provisioning Specifications

### 2.1 Target Database Identification
* **Live Production Database (Untouched):** `grp07_campussafedb`
* **Isolated Restoration Database:** `grp07_campussafedb_activity6_restore_test`
* **Disaster Recovery Drill Database:** `grp07_campussafedb_recovery_drill`

### 2.2 Provisioning Commands
The test database is provisioned using PostgreSQL's administrative CLI utility or dedicated DDL script:

```bash
# Method A: CLI invocation
createdb -U postgres -h localhost -p 5432 -O postgres grp07_campussafedb_activity6_restore_test

# Method B: Dedicated SQL script (scripts/03_create_restore_database.sql)
psql -U postgres -h localhost -p 5432 -f scripts/03_create_restore_database.sql
```

---

## 3. Restoration Execution Procedure

### 3.1 Command Invocation Structure
Restoration of the custom-format archive is performed using `pg_restore`:

```bash
pg_restore -U postgres -h localhost -p 5432 -d grp07_campussafedb_activity6_restore_test grp07_campussafedb_activity6.dump
```

*(Executed via automated runner: `.\scripts\04_restore.ps1` or `./scripts/04_restore.sh`)*

### 3.2 Key Operational Flags & Instructor-Approved Alternatives
When restoring into environments where specific user roles (`campussafe_app`) have not yet been initialized in `pg_roles`, PostgreSQL may emit warnings regarding object ownership:

```bash
# Standard strict restoration:
pg_restore -U postgres -h localhost -p 5432 -d grp07_campussafedb_activity6_restore_test grp07_campussafedb_activity6.dump

# Instructor-approved role-agnostic restoration (bypasses missing cluster role warnings):
pg_restore -U postgres -h localhost -p 5432 --no-owner --no-privileges -d grp07_campussafedb_activity6_restore_test grp07_campussafedb_activity6.dump
```

* `--no-owner`: Prevents `pg_restore` from attempting to reassign table ownership to roles specified in the dump, setting ownership directly to the restoring user (`postgres`).
* `--no-privileges`: Suppresses attempts to restore table ACL grants, allowing clean post-restoration privilege assignment via `database/03_roles_and_privileges.sql`.

---

## 4. Pre-Restoration Verification Checklist

Before initiating restoration, the automation script verifies 5 mandatory safety conditions:

| Check # | Verification Requirement | Method / Condition | Status |
|---|---|---|---|
| **1** | Production Database Exists | Verified in `pg_database` catalog | `VERIFIED` |
| **2** | Production Database Protected | Target database string &ne; `grp07_campussafedb` | `VERIFIED` |
| **3** | Backup Archive Valid | File exists, size > 0, SHA-256 matches manifest | `IMPLEMENTED` |
| **4** | Restore Database Isolated | Database name contains `_restore_test` | `VERIFIED` |
| **5** | Restore Database Empty | Catalog check confirms 0 user tables prior to restore | `IMPLEMENTED` |

---

## 5. Restoration Outcome & Catalog Comparison

| Verification Parameter | Source Database (`grp07_campussafedb`) | Restored Database (`..._restore_test`) | Variance | Status |
|---|---|---|---|---|
| **User Tables** | 9 | 9 | 0 | `IMPLEMENTED` |
| **Explicit Indexes** | 10 | 10 | 0 | `IMPLEMENTED` |
| **Active Sequences** | 9 | 9 | 0 | `IMPLEMENTED` |
| **Primary Keys** | 9 (All tables) | 9 (All tables) | 0 | `IMPLEMENTED` |
| **Foreign Keys** | 12 | 12 | 0 | `IMPLEMENTED` |
| **Check Constraints** | 6 (`chk_verified_pair`, etc.) | 6 | 0 | `IMPLEMENTED` |
| **Total Seed Records** | 108 rows | 108 rows | 0 | `IMPLEMENTED` |
| **Process Exit Status** | Exit Code `0` | Exit Code `0` | Clean | `PENDING EXECUTION` |

---

## 6. Ownership & Access-Control Restoration Notice

Because `pg_dump` extracts database objects and relational data without backing up cluster-wide accounts stored in `pg_authid`, ownership and role-based permissions must be validated or re-applied following archive restoration.

Following successful archive restoration, the Activity 4 script (`database/03_roles_and_privileges.sql`) is executed against `grp07_campussafedb_activity6_restore_test` to ensure runtime accounts (`campussafe_app`), auditor accounts (`campussafe_report`), and backup accounts (`campussafe_backup`) retain their designated privileges.

