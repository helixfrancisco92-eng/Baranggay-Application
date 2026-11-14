#!/usr/bin/env bash
# ==============================================================================
# COMP 018 - Database Administration | Activity 6
# Script: restore.sh
# Purpose: Execute Full Database Restoration into Isolated Test Database
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOGS_DIR="${WORKSPACE_ROOT}/logs"
BACKUP_DIR="${WORKSPACE_ROOT}/backups"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
ADMIN_USER="${ADMIN_USER:-postgres}"
ORIGINAL_DB="grp_binarysisters_projectdb"
RESTORE_DB="${RESTORE_DB:-grp_binarysisters_projectdb_activity6_restore_test}"

mkdir -p "${LOGS_DIR}"

echo "=============================================================================="
echo " COMP 018 Activity 6 - PostgreSQL Database Restoration (Bash)"
echo " Target Test Database : ${RESTORE_DB}"
echo " Host / Port          : ${DB_HOST}:${DB_PORT} | Admin: ${ADMIN_USER}"
echo "=============================================================================="

# CRITICAL SAFETY CHECK: NEVER RESTORE OVER ORIGINAL DATABASE
if [ "${RESTORE_DB}" = "${ORIGINAL_DB}" ]; then
    echo "FATAL SECURITY ERROR: Attempted restoration over original database '${ORIGINAL_DB}'!" >&2
    echo "Restoration aborted immediately." >&2
    exit 1
fi

if ! command -v pg_restore &> /dev/null || ! command -v psql &> /dev/null; then
    echo "ERROR: PostgreSQL utilities (pg_restore / psql) not found on PATH." >&2
    exit 1
fi

# Locate backup file
BACKUP_FILE="${1:-}"
if [ -z "${BACKUP_FILE}" ]; then
    BACKUP_FILE=$(find "${BACKUP_DIR}" -name "*.dump" -type f | sort -r | head -n 1)
fi

if [ -z "${BACKUP_FILE}" ] || [ ! -f "${BACKUP_FILE}" ]; then
    echo "ERROR: No valid .dump archive found in '${BACKUP_DIR}'." >&2
    exit 1
fi

FILENAME=$(basename "${BACKUP_FILE}")
RESTORE_LOG="${LOGS_DIR}/restore-execution.log"

# Password acquisition
if [ -z "${PGPASSWORD:-}" ]; then
    read -rsp "Enter password for administrative user '${ADMIN_USER}': " PGPASSWORD
    echo
    export PGPASSWORD
fi

# Confirm destination database exists
DB_EXISTS=$(psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${ADMIN_USER}" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${RESTORE_DB}';" || true)
if [ "${DB_EXISTS}" != "1" ]; then
    echo "ERROR: Destination database '${RESTORE_DB}' does not exist." >&2
    echo "Run scripts/create-restore-db.sh first to provision it." >&2
    exit 1
fi

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Initiating pg_restore..."
echo "Source Archive : ${FILENAME}"
echo "Target DB      : ${RESTORE_DB}"
echo "Logging To     : ${RESTORE_LOG}"

# Note on Flags: We execute pg_restore without blind suppression flags like --no-owner or --no-acl
# to ensure authentic replication of production permissions and table ownership.
RESTORE_STATUS=0
pg_restore -h "${DB_HOST}" -p "${DB_PORT}" -U "${ADMIN_USER}" -v -d "${RESTORE_DB}" "${BACKUP_FILE}" > "${RESTORE_LOG}" 2>&1 || RESTORE_STATUS=$?

echo "pg_restore finished with exit code: ${RESTORE_STATUS}"

# Inspect warnings vs errors
# pg_restore returns 0 on complete success, or 1 if warnings occurred (e.g. extension already exists)
if [ ${RESTORE_STATUS} -eq 0 ]; then
    echo " -> Restoration completed with ZERO errors or warnings."
elif [ ${RESTORE_STATUS} -eq 1 ]; then
    echo " -> Restoration completed with non-fatal informational notices/warnings (Exit Code 1)."
    echo "    (Common when pre-existing extensions or comments are processed)."
else
    echo " -> ERROR: Restoration failed with critical errors (Exit Code ${RESTORE_STATUS})."
    echo "    Review details in: ${RESTORE_LOG}"
    exit ${RESTORE_STATUS}
fi

echo "=============================================================================="
echo " RESTORATION COMPLETE: Proceeding to SQL verification suites."
echo " Next Steps: Execute scripts/verify-database.sql and verify-access-control.sql"
echo "=============================================================================="

