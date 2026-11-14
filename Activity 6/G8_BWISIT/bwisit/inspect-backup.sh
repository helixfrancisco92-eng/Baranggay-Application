#!/usr/bin/env bash
# ==============================================================================
# COMP 018 - Database Administration | Activity 6
# Script: inspect-backup.sh
# Purpose: Inspect Table-of-Contents (TOC) of PostgreSQL custom dump archive
# Utility: pg_restore --list
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOGS_DIR="${WORKSPACE_ROOT}/logs"
BACKUP_DIR="${WORKSPACE_ROOT}/backups"

mkdir -p "${LOGS_DIR}"

# Determine backup file: accept argument or take newest in backups directory
if [ $# -ge 1 ]; then
    BACKUP_FILE="$1"
else
    BACKUP_FILE=$(find "${BACKUP_DIR}" -maxdepth 1 -name "*.dump" -type f 2>/dev/null | sort -r | head -n 1 || true)
fi

if [ -z "${BACKUP_FILE:-}" ] || [ ! -f "${BACKUP_FILE}" ]; then
    echo "ERROR: No backup dump file found. Provide path as argument or place dump in ${BACKUP_DIR}." >&2
    echo "Usage: ./inspect-backup.sh [/path/to/canteen_db.dump]" >&2
    exit 1
fi

# Locate pg_restore
if ! command -v pg_restore >/dev/null 2>&1; then
    if [ -x "/c/Program Files/PostgreSQL/18/bin/pg_restore.exe" ]; then
        PG_RESTORE="/c/Program Files/PostgreSQL/18/bin/pg_restore.exe"
    elif [ -x "/c/Program Files/PostgreSQL/16/bin/pg_restore.exe" ]; then
        PG_RESTORE="/c/Program Files/PostgreSQL/16/bin/pg_restore.exe"
    else
        echo "ERROR: pg_restore utility not found on PATH or standard PostgreSQL install paths." >&2
        exit 1
    fi
else
    PG_RESTORE="pg_restore"
fi

TOC_LOG="${LOGS_DIR}/archive-toc.txt"
INSPECT_LOG="${LOGS_DIR}/inspect-backup.log"

echo "=============================================================================="
echo " COMP 018 Activity 6 - PostgreSQL Archive Inspection & TOC Verification"
echo " Target Archive: ${BACKUP_FILE}"
echo "=============================================================================="

# Checksum Verification
CHECKSUM_FILE="${BACKUP_FILE}.sha256"
if [ -f "${CHECKSUM_FILE}" ]; then
    echo "Verifying SHA-256 cryptographic checksum against ${CHECKSUM_FILE}..."
    RECORDED_HASH=$(awk '{print $1}' "${CHECKSUM_FILE}")
    if command -v sha256sum >/dev/null 2>&1; then
        CURRENT_HASH=$(sha256sum "${BACKUP_FILE}" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        CURRENT_HASH=$(shasum -a 256 "${BACKUP_FILE}" | awk '{print $1}')
    else
        CURRENT_HASH="UNKNOWN"
    fi

    if [ "${RECORDED_HASH}" = "${CURRENT_HASH}" ]; then
        echo "[OK] Checksum verified: ${CURRENT_HASH} matches recorded value."
    else
        echo "WARNING: Checksum mismatch! Recorded: ${RECORDED_HASH}, Computed: ${CURRENT_HASH}" >&2
    fi
fi

echo "Extracting Table of Contents (TOC) using pg_restore --list..."
"${PG_RESTORE}" --list "${BACKUP_FILE}" > "${TOC_LOG}"

TOTAL_ENTRIES=$(wc -l < "${TOC_LOG}")
echo "[OK] TOC extracted successfully: ${TOTAL_ENTRIES} entries documented in ${TOC_LOG}."

echo "------------------------------------------------------------------------------"
echo " AUDITING CRITICAL CAMPUS CANTEEN OBJECTS IN ARCHIVE"
echo "------------------------------------------------------------------------------"

EXPECTED_TABLES=("student" "vendor" "menu_item" "customer_order" "order_item" "queue_entry" "notification")
MISSING_TABLES=0

for tbl in "${EXPECTED_TABLES[@]}"; do
    if grep -E "TABLE (DATA )?public ${tbl} " "${TOC_LOG}" >/dev/null 2>&1; then
        echo "  [FOUND] Table: public.${tbl}"
    else
        echo "  [MISSING] Table: public.${tbl}"
        MISSING_TABLES=$((MISSING_TABLES + 1))
    fi
done

if [ ${MISSING_TABLES} -eq 0 ]; then
    echo "[PASS] All 7 Campus Canteen core relational tables confirmed in dump archive."
else
    echo "[WARNING] ${MISSING_TABLES} expected tables were not detected in archive TOC."
fi

cat <<EOF >> "${INSPECT_LOG}"
Inspection Executed : $(date '+%Y-%m-%d %H:%M:%S')
Archive File        : ${BACKUP_FILE}
Total TOC Objects   : ${TOTAL_ENTRIES}
Missing Core Tables : ${MISSING_TABLES}
TOC File Saved To   : ${TOC_LOG}
EOF

echo "=============================================================================="
echo " WHY ARCHIVE INSPECTION IS ESSENTIAL (TECHNICAL DBA PRINCIPLE):"
echo " Simply checking that a backup file exists on disk does NOT guarantee that"
echo " the file contains a valid, readable, or restorable database. Zero-byte files,"
echo " truncated streams, corrupted blocks, missing dependencies, or incompatible"
echo " encoding can result in a file being present while restoration fails completely."
echo " Inspecting the TOC with pg_restore --list proves archive structure and integrity"
echo " before committing to a restore operation."
echo "=============================================================================="

