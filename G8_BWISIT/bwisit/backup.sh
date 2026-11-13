#!/usr/bin/env bash
# ==============================================================================
# COMP 018 - Database Administration | Activity 6
# Script: backup.sh
# Target: Campus Canteen Pre-Order and Queue Management System (canteen_db)
# Role: canteen_admin (or authorized PostgreSQL administrator)
# Format: PostgreSQL Custom Archive (-Fc)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOGS_DIR="${WORKSPACE_ROOT}/logs"
DEFAULT_BACKUP_DIR="${WORKSPACE_ROOT}/backups"

mkdir -p "${LOGS_DIR}" "${DEFAULT_BACKUP_DIR}"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-canteen_db}"
DB_USER="${DB_USER:-canteen_admin}"
BACKUP_DIR="${BACKUP_DIR:-${DEFAULT_BACKUP_DIR}}"

echo "=============================================================================="
echo " COMP 018 Activity 6 - PostgreSQL Database Logical Backup"
echo " Project: Group 8 - Campus Canteen Pre-Order & Queue Management System"
echo " Target Database: ${DB_NAME}"
echo " Host: ${DB_HOST}:${DB_PORT} | User: ${DB_USER}"
echo "=============================================================================="

# Ensure pg_dump is available
if ! command -v pg_dump >/dev/null 2>&1; then
    if [ -x "/c/Program Files/PostgreSQL/18/bin/pg_dump.exe" ]; then
        PG_DUMP="/c/Program Files/PostgreSQL/18/bin/pg_dump.exe"
    elif [ -x "/c/Program Files/PostgreSQL/16/bin/pg_dump.exe" ]; then
        PG_DUMP="/c/Program Files/PostgreSQL/16/bin/pg_dump.exe"
    else
        echo "ERROR: pg_dump utility not found on PATH or standard PostgreSQL install paths." >&2
        exit 1
    fi
else
    PG_DUMP="pg_dump"
fi

# Ensure password is supplied securely without hardcoding
if [ -z "${PGPASSWORD:-}" ]; then
    echo -n "Enter password for database user '${DB_USER}': "
    read -s PGPASSWORD
    echo ""
    export PGPASSWORD
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="${DB_NAME}_${TIMESTAMP}.dump"
BACKUP_FILEPATH="${BACKUP_DIR}/${BACKUP_FILENAME}"
CHECKSUM_FILEPATH="${BACKUP_FILEPATH}.sha256"
LOG_FILE="${LOGS_DIR}/backup-execution.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting logical backup with pg_dump (-Fc)..."
echo "Destination: ${BACKUP_FILEPATH}"

# Execute pg_dump with custom format (-Fc), verbose (-v), and blobs (-b)
if "${PG_DUMP}" -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -Fc -b -v -d "${DB_NAME}" -f "${BACKUP_FILEPATH}" 2>> "${LOG_FILE}"; then
    echo "[OK] Backup dump completed successfully."
else
    EXIT_CODE=$?
    echo "ERROR: pg_dump failed with exit code ${EXIT_CODE}. Check ${LOG_FILE} for details." >&2
    [ -f "${BACKUP_FILEPATH}" ] && rm -f "${BACKUP_FILEPATH}"
    unset PGPASSWORD
    exit ${EXIT_CODE}
fi

# Clear password from environment
unset PGPASSWORD

# Validate that file exists and is not empty
if [ ! -s "${BACKUP_FILEPATH}" ]; then
    echo "ERROR: Backup archive was created but has 0 bytes size." >&2
    exit 1
fi

FILE_SIZE=$(wc -c < "${BACKUP_FILEPATH}" | tr -d ' ')

# Compute SHA-256 cryptographic checksum
if command -v sha256sum >/dev/null 2>&1; then
    SHA256_HASH=$(sha256sum "${BACKUP_FILEPATH}" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    SHA256_HASH=$(shasum -a 256 "${BACKUP_FILEPATH}" | awk '{print $1}')
else
    SHA256_HASH="SHA256-UTILITY-NOT-FOUND"
fi

echo "${SHA256_HASH}  ${BACKUP_FILENAME}" > "${CHECKSUM_FILEPATH}"

echo "=============================================================================="
echo " BACKUP METRICS AND RECORDING"
echo "=============================================================================="
echo " Database Name  : ${DB_NAME}"
echo " Backup File    : ${BACKUP_FILENAME}"
echo " Full Path      : ${BACKUP_FILEPATH}"
echo " File Size      : ${FILE_SIZE} bytes"
echo " SHA-256 Hash   : ${SHA256_HASH}"
echo " Completed At   : $(date '+%Y-%m-%d %H:%M:%S')"
echo " Checksum File  : ${CHECKSUM_FILEPATH}"
echo " Execution Log  : ${LOG_FILE}"
echo "=============================================================================="

# Append summary to backup execution log
cat <<EOF >> "${LOG_FILE}"
--------------------------------------------------------------------------------
Backup Executed : $(date '+%Y-%m-%d %H:%M:%S')
Target Database : ${DB_NAME}
Host / Port     : ${DB_HOST}:${DB_PORT}
User            : ${DB_USER}
Backup Archive  : ${BACKUP_FILENAME}
File Size       : ${FILE_SIZE} bytes
SHA-256 Hash    : ${SHA256_HASH}
Result          : SUCCESS (Exit Code 0)
--------------------------------------------------------------------------------
EOF

echo "Next step: Run 'inspect-backup.sh' to verify archive table-of-contents (TOC)."

