#!/usr/bin/env bash
# ==============================================================================
# COMP 018 - Database Administration | Activity 6
# Script: backup.sh
# Target: Restaurant Online Ordering & Table Reservation System (grp_binarysisters_projectdb)
# Role: rors_backup (or authorized administrative user)
# Format: PostgreSQL Custom Archive (-Fc)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOGS_DIR="${WORKSPACE_ROOT}/logs"
BACKUP_DIR="${WORKSPACE_ROOT}/backups"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-grp_binarysisters_projectdb}"
DB_USER="${DB_USER:-rors_backup}"

mkdir -p "${LOGS_DIR}" "${BACKUP_DIR}"

echo "=============================================================================="
echo " COMP 018 Activity 6 - PostgreSQL Database Logical Backup (Bash)"
echo " Project: Restaurant Online Ordering & Table Reservation System (Binary Sisters)"
echo " Target Database: ${DB_NAME}"
echo " Host: ${DB_HOST}:${DB_PORT} | User: ${DB_USER}"
echo "=============================================================================="

# Check for pg_dump
if ! command -v pg_dump &> /dev/null; then
    echo "ERROR: pg_dump utility not found on PATH." >&2
    exit 1
fi

# Acquire password securely if not set
if [ -z "${PGPASSWORD:-}" ]; then
    read -rsp "Enter password for database user '${DB_USER}': " PGPASSWORD
    echo
    export PGPASSWORD
fi

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_FILENAME="${DB_NAME}_${TIMESTAMP}.dump"
BACKUP_FILEPATH="${BACKUP_DIR}/${BACKUP_FILENAME}"
CHECKSUM_FILEPATH="${BACKUP_FILEPATH}.sha256"
LOG_FILE="${LOGS_DIR}/backup-execution.log"

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Executing pg_dump (-Fc)..."
echo "Destination: ${BACKUP_FILEPATH}"

# Execute pg_dump with verbose logging
if pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -Fc -b -v -d "${DB_NAME}" -f "${BACKUP_FILEPATH}" 2>> "${LOG_FILE}"; then
    echo "pg_dump completed successfully."
else
    echo "ERROR: pg_dump failed. Check log: ${LOG_FILE}" >&2
    exit 1
fi

# Validate file size
FILE_SIZE=$(wc -c < "${BACKUP_FILEPATH}" | tr -d ' ')
if [ "${FILE_SIZE}" -le 0 ]; then
    echo "ERROR: Backup archive file was created with 0 bytes size." >&2
    exit 1
fi

# Compute SHA-256 checksum
if command -v sha256sum &> /dev/null; then
    SHA256_HASH=$(sha256sum "${BACKUP_FILEPATH}" | awk '{print $1}')
elif command -v shasum &> /dev/null; then
    SHA256_HASH=$(shasum -a 256 "${BACKUP_FILEPATH}" | awk '{print $1}')
else
    SHA256_HASH="Checksum utility missing"
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
echo " Completed At   : $(date +"%Y-%m-%d %H:%M:%S")"
echo " Checksum File  : ${CHECKSUM_FILEPATH}"
echo " Execution Log  : ${LOG_FILE}"
echo "=============================================================================="

# Append summary record to operational audit log
cat <<EOF >> "${LOGS_DIR}/backup-audit.log"
--------------------------------------------------------------------------------
Backup Executed : $(date +"%Y-%m-%d %H:%M:%S")
Target Database : ${DB_NAME}
Host / Port     : ${DB_HOST}:${DB_PORT}
User            : ${DB_USER}
Backup File     : ${BACKUP_FILENAME}
File Size       : ${FILE_SIZE} bytes
SHA-256 Hash    : ${SHA256_HASH}
Result          : SUCCESS (Exit Code 0)
--------------------------------------------------------------------------------
EOF

echo "Backup workflow certified complete."

