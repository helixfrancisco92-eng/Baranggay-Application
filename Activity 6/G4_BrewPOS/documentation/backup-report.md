# BrewPOS — Database Backup and Inspection Report
**Course:** COMP 018 — Database Administration  
**Activity:** Activity 6 — Database Backup, Restoration, and Recovery  
**Target Project:** BrewPOS — Café Point-of-Sale System  
**Database:** PostgreSQL 18.6 / 16+ (`grp_brewposdb`)  
**Report Date:** November 12, 2026  
**Execution Status:** **PENDING MANUAL EXECUTION / ENVIRONMENT ACCESS BLOCKED**  

---

## 1. Overview and Operational Parameters

This report documents the logical custom-format backup procedure for the BrewPOS database (`grp_brewposdb`) and the subsequent archive integrity inspection.

| Parameter | Specification / Expected Configuration |
|---|---|
| **Target Database Engine** | PostgreSQL 18.6 (compatible with 16+) |
| **Source Database Name** | `grp_brewposdb` |
| **Schema Name** | `public` |
| **Database Host & Port** | `localhost:5432` |
| **Backup Utility** | PostgreSQL native client `pg_dump` |
| **Backup Format** | Custom Archive Format (`-Fc` with built-in zlib compression) |
| **Inspection Utility** | PostgreSQL native client `pg_restore --list` |
| **Automated Runner Script** | `scripts/backup-database.ps1` / `scripts/backup-database` |
| **Inspection Runner Script** | `scripts/inspect-backup.ps1` / `scripts/inspect-backup` |

---

## 2. Backup Command & Specification

The exact command template engineered and encapsulated within `scripts/backup-database.ps1` is:

```bash
pg_dump -U postgres -h localhost -p 5432 -Fc -v -d grp_brewposdb -f ../backups/brewpos_grp_brewposdb_<timestamp>.dump
```

### Justification for `-Fc`
1. Enables structured Table of Contents (TOC) inspection without database alteration.
2. Applies internal compression, minimizing storage requirements for transaction tables.
3. Allows granular object-level restoration and parallel restore jobs (`pg_restore -j`).
4. Avoids plain-text credential/data exposure common to `.sql` plain-text dumps.

---

## 3. Execution Record & Environment Status

| Metric / Attribute | Execution Result / Value | Status Label |
|---|---|---|
| **Backup Execution Date/Time** | *Pending execution against live host* | **PENDING** |
| **Generated Backup Filename** | Pattern: `brewpos_grp_brewposdb_YYYYMMDD_HHMMSS.dump` | **CREATED – NOT EXECUTED** |
| **Backup File Size** | *Pending generation* | **PENDING** |
| **SHA-256 Cryptographic Checksum** | *Pending generation via `Get-FileHash`* | **PENDING** |
| **Exit Code** | *Pending* | **PENDING** |
| **Backup Creation Status** | **PENDING** | Requires live DB credentials & host loopback access |
| **Archive Inspection Status** | **PENDING** | Awaits generated `.dump` file |

> **Authenticity Note:** In compliance with COMP 018 Activity 6 safety rules, no fabricated SHA-256 checksums, mock file sizes, or falsified terminal outputs are recorded.

---

## 4. Archive Inspection Command & Procedure

The inspection procedure uses `pg_restore --list` to parse the archive's internal Table of Contents (TOC):

```bash
pg_restore --list ../backups/<backup_filename>.dump
```

### Expected Verified Objects in Table of Contents (TOC):
- **Core Tables (5/5):**
  - `TABLE DATA public staff`
  - `TABLE DATA public menu_category`
  - `TABLE DATA public menu_item`
  - `TABLE DATA public order_ticket`
  - `TABLE DATA public order_line_item`
- **Sequences (4/4):**
  - `SEQUENCE public staff_staff_id_seq`
  - `SEQUENCE public menu_category_category_id_seq`
  - `SEQUENCE public menu_item_item_id_seq`
  - `SEQUENCE public order_ticket_order_id_seq`
- **Primary & Composite Keys:**
  - `staff_pkey` (`staff_id`)
  - `menu_category_pkey` (`category_id`)
  - `menu_item_pkey` (`item_id`)
  - `order_ticket_pkey` (`order_id`)
  - `pk_order_line_item` (`order_id, item_id` composite PK)
- **Foreign Key Constraints (RESTRICT):**
  - `fk_menu_item_category`
  - `fk_order_ticket_staff`
  - `fk_order_line_order`
  - `fk_order_line_item`
- **Performance B-tree Indexes:**
  - `idx_order_ticket_timestamp`
  - `idx_order_line_item_item_id`

---

## 5. Errors, Warnings, and Exact Blockers

During static environment verification, the following execution conditions were established:

1. **PostgreSQL Tool Availability:**
   - Both `pg_dump (PostgreSQL) 18.6` and `psql (PostgreSQL) 18.6` are installed on the local Windows workstation.
2. **Execution Blocker (AppContainer Socket Isolation):**
   - Direct execution of `psql` or `pg_dump` targeting `localhost:5432` from within the sandboxed environment results in:
     ```text
     psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: Permission denied (0x0000271D/10013)
     ```
   - Windows socket error `10013` (`WSAEACCES`) occurs because standard sandbox isolation forbids loopback TCP connections to system daemons.
3. **Missing Credentials:**
   - No plaintext passwords exist in the repository (in accordance with credential security standards).
4. **Resolution Path:**
   - Run `scripts/backup-database.ps1` in an external Windows PowerShell session where host socket access is permitted.

