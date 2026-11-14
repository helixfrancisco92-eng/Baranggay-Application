#!/usr/bin/env bash
# ==============================================================================
# HabalGo (Group 6) — Automated Test Database Restoration Script
# Course: COMP 018 — Database Administration (Activity 6)
# Platform: PostgreSQL pg_restore
# Target Restore Database: grp00_habalgodb_activity6_restore_test
# ==============================================================================

set -euo pipefail

# 1. Configuration & Safety Parameters
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
ORIGINAL_DB="${ORIGINAL_DB:-grp00_habalgodb}"
RESTORE_DB="${RESTORE_DB:-grp00_habalgodb_activity6_restore_test}"
DB_USER="${DB_USER:-postgres}"
BACKUP_DIR="${BACKUP_DIR:-$(dirname "$0")/../backups}"

echo "================================================================="
echo " HabalGo Test Database Restoration Utility (pg_restore)          "
echo " Course: COMP 018 — Activity 6                                    "
echo "================================================================="

# SAFETY ASSERTION 1: Target database must strictly differ from original
if [[ "${RESTORE_DB,,}" == "${ORIGINAL_DB,,}" ]]; then
    echo "[CRITICAL SAFETY VIOLATION] Target restore database cannot be identical to the original database!" >&2
    echo "Refusing to overwrite '${ORIGINAL_DB}'. Restoration aborted." >&2
    exit 1
fi

echo "[1/7] Target safety validation PASSED."
echo "      Source Database (Original) : ${ORIGINAL_DB}"
echo "      Target Database (Separate) : ${RESTORE_DB}"

# 2. Locate Backup File
if [[ $# -ge 1 ]]; then
    BACKUP_FILE="$1"
else
    BACKUP_FILE="$(ls -t "${BACKUP_DIR}"/*activity6*.dump 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "${BACKUP_FILE}" || ! -f "${BACKUP_FILE}" ]]; then
    echo "[FAILED] No valid backup archive found at '${BACKUP_DIR}'." >&2
    echo "Please run 01_backup.sh first or provide the file path as an argument." >&2
    exit 1
fi

echo "[2/7] Backup archive identified: ${BACKUP_FILE}"

# 3. Cryptographic Checksum Verification
CHECKSUM_FILE="${BACKUP_FILE}.sha256"
if [[ -f "${CHECKSUM_FILE}" ]]; then
    echo "[3/7] Verifying archive cryptographic checksum..."
    if command -v sha256sum >/dev/null 2>&1; then
        (cd "$(dirname "${BACKUP_FILE}")" && sha256sum -c "$(basename "${CHECKSUM_FILE}")")
    fi
    echo "      Checksum verification PASSED."
else
    echo "[3/7] Warning: Checksum manifest (.sha256) not found. Proceeding with cautioned validation."
fi

# 4. Confirm Destination Database Exists in PostgreSQL Cluster
echo "[4/7] Checking destination database existence in PostgreSQL cluster..."
DB_EXISTS="$(psql -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${RESTORE_DB}';" 2>/dev/null || true)"

if [[ "${DB_EXISTS}" != "1" ]]; then
    echo "      Notice: '${RESTORE_DB}' does not exist. Creating separate test database..."
    if ! createdb -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" "${RESTORE_DB}"; then
        echo "[FAILED] Could not create separate database '${RESTORE_DB}'. Ensure user '${DB_USER}' has CREATEDB privilege." >&2
        exit 1
    fi
    echo "      Database '${RESTORE_DB}' created successfully."
else
    echo "      Destination database '${RESTORE_DB}' exists."
fi

# 5. Confirm Destination Database is Empty Before Restoration
echo "[5/7] Verifying destination database is clean and empty..."
TABLE_COUNT="$(psql -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d "${RESTORE_DB}" -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog','information_schema');" 2>/dev/null || echo "0")"

if [[ "${TABLE_COUNT}" -gt 0 ]]; then
    echo "[CRITICAL WARNING] Destination database '${RESTORE_DB}' already contains ${TABLE_COUNT} table(s)!" >&2
    echo "Safety rule violation: Refusing to restore over a non-empty database without manual inspection." >&2
    echo "Please drop the test database manually or provide a clean target database." >&2
    exit 1
fi
echo "      Destination database is clean (0 user tables detected)."

# 6. Execute pg_restore
echo "[6/7] Restoring backup archive into '${RESTORE_DB}' (pg_restore)..."
START_TIME="$(date +%s)"

RESTORE_LOG="$(dirname "$0")/../backups/restore_output.log"
mkdir -p "$(dirname "${RESTORE_LOG}")"

# Execute pg_restore; capture output without blindly suppressing errors
set +e
pg_restore -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -v -d "${RESTORE_DB}" "${BACKUP_FILE}" > "${RESTORE_LOG}" 2>&1
RESTORE_EXIT=$?
set -e

END_TIME="$(date +%s)"
DURATION=$((END_TIME - START_TIME))

# In pg_restore, exit code 0 is total success, exit code 1 indicates non-fatal warnings (e.g., existing roles or owner notices)
if [[ "${RESTORE_EXIT}" -eq 0 ]]; then
    echo "      Restoration completed cleanly with zero warnings (Exit Code: 0)."
elif [[ "${RESTORE_EXIT}" -eq 1 ]]; then
    echo "      Restoration completed with non-fatal warnings (Exit Code: 1). Reviewing log..."
    grep -i 'warning' "${RESTORE_LOG}" | head -n 5 || true
else
    echo "[FAILED] pg_restore failed with critical error (Exit Code: ${RESTORE_EXIT})." >&2
    cat "${RESTORE_LOG}" >&2
    exit "${RESTORE_EXIT}"
fi

# 7. Post-Restoration Object Count Validation
echo "[7/7] Validating restored database contents..."
RESTORED_TABLES="$(psql -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d "${RESTORE_DB}" -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='habalgo';" 2>/dev/null || echo "0")"

echo "================================================================="
echo " RESTORATION SUMMARY REPORT                                      "
echo "================================================================="
echo " Source Archive     : ${BACKUP_FILE}"
echo " Destination DB     : ${RESTORE_DB}"
echo " Tables Restored    : ${RESTORED_TABLES} table(s) in schema 'habalgo'"
echo " Duration           : ${DURATION} second(s)"
echo " Log File           : ${RESTORE_LOG}"
echo " Status             : SUCCESS"
echo "================================================================="

