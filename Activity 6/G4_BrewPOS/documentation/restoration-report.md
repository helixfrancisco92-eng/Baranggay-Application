# BrewPOS — Database Restoration Test Report
**Course:** COMP 018 — Database Administration  
**Activity:** Activity 6 — Database Backup, Restoration, and Recovery  
**Target Project:** BrewPOS — Café Point-of-Sale System  
**Report Date:** November 12, 2026  
**Execution Status:** **PENDING MANUAL EXECUTION / ENVIRONMENT ACCESS BLOCKED**  

---

## 1. Safety and Isolation Declarations

> [!IMPORTANT]
> **Safety Rule Adherence:** In accordance with Activity 6 rules, the restoration procedure is strictly configured to restore into a separate, disposable test database (`grp_brewposdb_restore_test`). Under NO circumstances is the original database (`grp_brewposdb`) overwritten, modified, or dropped.

| Environment Role | Database Name | Purpose | Action Permitted |
|---|---|---|---|
| **Primary Production / Reference** | `grp_brewposdb` | Application data source | **READ-ONLY / PROTECTED** |
| **Disposable Restoration Sandbox** | `grp_brewposdb_restore_test` | Restoration test verification | **FULL DDL / DROP & RESTORE** |

---

## 2. Restoration Operational Parameters

| Parameter | Specification |
|---|---|
| **Original Database** | `grp_brewposdb` |
| **Target Test Database** | `grp_brewposdb_restore_test` |
| **Target Host & Port** | `localhost:5432` |
| **DBA User Account** | `postgres` |
| **Restoration Utility** | PostgreSQL native `pg_restore` (v18.6) |
| **Backup Archive Selected** | Most recent custom-format dump in `backups/` |
| **Script Automation** | `scripts/restore-database.ps1` / `scripts/restore-database` |

---

## 3. Restoration Commands & Procedure

### Step 1: Provision Clean Test Database
```bash
createdb -U postgres -h localhost -p 5432 -E UTF8 -O postgres grp_brewposdb_restore_test
```

### Step 2: Restore from Custom-Format Dump
```bash
pg_restore -U postgres -h localhost -p 5432 -d grp_brewposdb_restore_test --no-owner -v <backup_file.dump>
```

*Flags Explained:*
- `-d grp_brewposdb_restore_test`: Explicitly binds restoration to the disposable sandbox.
- `--no-owner`: Prevents object ownership errors when restoring on environments where original object owners differ.
- `-v`: Outputs comprehensive verbose diagnostics of each restored table, constraint, and index.

---

## 4. Restoration Execution Record & Status

| Attribute | Recorded Value | Status Label |
|---|---|---|
| **Restoration Date and Time** | *Pending host execution* | **PENDING** |
| **Backup File Used** | Pattern: `backups/brewpos_grp_brewposdb_*.dump` | **PENDING** |
| **Restoration Command Exit Code** | *Pending* | **PENDING** |
| **Restoration Test Result** | **PENDING** | **PENDING** |
| **Objects Restored Count** | Target: 5 tables, 4 sequences, 2 custom indexes | **PENDING** |
| **Warnings / Errors Logged** | None logged (Awaiting run) | **PENDING** |

---

## 5. Objects to be Verified Post-Restoration

Upon running `scripts/restore-database.ps1` in the local terminal, the following schema inventory must be verified in `grp_brewposdb_restore_test`:

1. **Tables (5/5):**
   - `public.staff`
   - `public.menu_category`
   - `public.menu_item`
   - `public.order_ticket`
   - `public.order_line_item`
2. **Composite Primary Keys:**
   - `order_line_item` composite PK on `(order_id, item_id)`
3. **Foreign Key Integrity:**
   - `fk_menu_item_category` (`menu_item` -> `menu_category`)
   - `fk_order_ticket_staff` (`order_ticket` -> `staff`)
   - `fk_order_line_order` (`order_line_item` -> `order_ticket`)
   - `fk_order_line_item` (`order_line_item` -> `menu_item`)
4. **Performance Indexes:**
   - `idx_order_ticket_timestamp`
   - `idx_order_line_item_item_id`

---

## 6. Known Limitations & Technical Blockers

1. **Loopback Socket Access in Sandbox:**
   - The test environment sandbox restricts raw TCP loopback socket connections (`WSAEACCES 10013`), preventing automated direct execution from this subshell.
2. **Zero Fabrication Policy:**
   - Per course requirements, successful execution results are not fabricated. Once executed by the student using the provided PowerShell scripts, real terminal output logs and screenshot evidence will be collected in `evidence/`.

