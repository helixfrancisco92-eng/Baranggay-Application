#!/usr/bin/env bash
# ==============================================================================
# COMP 018 - Database Administration | Activity 6
# Script: restore.sh
# Purpose: Restore PostgreSQL custom dump archive into isolated test database
# Target: canteen_db_activity6_restore_test
# Utility: pg_restore
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOGS_DIR="${WORKSPACE_ROOT}/logs"
BACKUP_DIR="${WORKSPACE_ROOT}/backups"

mkdir -p "${LOGS_DIR}"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
ADMIN_USER="${ADMIN_USER:-postgres}"
ORIGINAL_DB="${ORIGINAL_DB:-canteen_db}"
RESTORE_DB="${RESTORE_DB:-canteen_db_activity6_restore_test}"

# Determine backup file
if [ $# -ge 1 ]; then
    BACKUP_FILE="$1"
else
    BACKUP_FILE=$(find "${BACKUP_DIR}" -maxdepth 1 -name "*.dump" -type f 2>/dev/null | sort -r | head -n 1 || true)
fi

if [ -z "${BACKUP_FILE:-}" ] || [ ! -f "${BACKUP_FILE}" ]; then
    echo "ERROR: No backup dump file found. Provide path as argument or place dump in ${BACKUP_DIR}." >&2
    exit 1
fi

# CRITICAL BOUNDARY ENFORCEMENT
if [ "${RESTORE_DB}" = "${ORIGINAL_DB}" ]; then
    echo "FATAL SECURITY ERROR: Restoration directly into original database '${ORIGINAL_DB}' is forbidden!" >&2
    echo "Always restore into a separate test database (e.g. '${RESTORE_DB}')." >&2
    exit 1
fi

# Locate pg_restore and psql
if ! command -v pg_restore >/dev/null 2>&1; then
    if [ -x "/c/Program Files/PostgreSQL/18/bin/pg_restore.exe" ]; then
        PG_RESTORE="/c/Program Files/PostgreSQL/18/bin/pg_restore.exe"
        PSQL="/c/Program Files/PostgreSQL/18/bin/psql.exe"
    elif [ -x "/c/Program Files/PostgreSQL/16/bin/pg_restore.exe" ]; then
        PG_RESTORE="/c/Program Files/PostgreSQL/16/bin/pg_restore.exe"
        PSQL="/c/Program Files/PostgreSQL/16/bin/psql.exe"
    else
        echo "ERROR: pg_restore utility not found." >&2
        exit 1
    fi
else
    PG_RESTORE="pg_restore"
    PSQL="psql"
fi

echo "=============================================================================="
echo " COMP 018 Activity 6 - Database Restoration into Isolated Environment"
echo " Source Backup Archive : ${BACKUP_FILE}"
echo " Destination Database  : ${RESTORE_DB}"
echo " Host / Port           : ${DB_HOST}:${DB_PORT} | User: ${ADMIN_USER}"
echo "=============================================================================="

if [ -z "${PGPASSWORD:-}" ]; then
    echo -n "Enter password for administrative user '${ADMIN_USER}': "
    read -s PGPASSWORD
    echo ""
    export PGPASSWORD
fi

# Verify destination database exists and has no existing user tables
TABLE_COUNT=$("${PSQL}" -h "${DB_HOST}" -p "${DB_PORT}" -U "${ADMIN_USER}" -d "${RESTORE_DB}" -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public'" || echo "-1")

if [ "${TABLE_COUNT}" -gt 0 ]; then
    echo "WARNING: Destination database '${RESTORE_DB}' already contains ${TABLE_COUNT} public tables."
    echo -n "Proceed with restoration anyway? [y/N]: "
    read -r CONFIRM
    if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
        echo "Restoration aborted."
        unset PGPASSWORD
        exit 0
    fi
fi

RESTORE_LOG="${LOGS_DIR}/restore-execution.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Executing pg_restore..."
# Standard restore without --no-owner or --no-acl first to preserve exact schema permissions and ownership
set +e
"${PG_RESTORE}" -h "${DB_HOST}" -p "${DB_PORT}" -U "${ADMIN_USER}" -v -d "${RESTORE_DB}" "${BACKUP_FILE}" > "${RESTORE_LOG}" 2>&1
RESTORE_STATUS=$?
set -e

unset PGPASSWORD

echo "------------------------------------------------------------------------------"
echo " RESTORATION EXECUTION SUMMARY"
echo "------------------------------------------------------------------------------"
echo " Exit Code       : ${RESTORE_STATUS}"
echo " Log Destination : ${RESTORE_LOG}"

if [ ${RESTORE_STATUS} -eq 0 ]; then
    echo "[PASS] Database restored with ZERO errors."
elif [ ${RESTORE_STATUS} -eq 1 ]; then
    echo "[NOTICE] pg_restore completed with warnings / non-fatal issues (Exit Code 1)."
    echo "Review ${RESTORE_LOG} to examine ownership or permission notices."
else
    echo "[ERROR] pg_restore failed with severe errors (Exit Code ${RESTORE_STATUS})."
    echo "Check ${RESTORE_LOG} for detailed error diagnostics."
    exit ${RESTORE_STATUS}
fi

echo "=============================================================================="
echo " Next step: Execute 'verify-restore.sql' and 'verify-access-control.sql' via psql."
echo "=============================================================================="

