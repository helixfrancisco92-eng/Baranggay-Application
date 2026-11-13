#!/usr/bin/env bash
# ==============================================================================
# COMP 018 – Activity 6: Database Restoration Script
# Target Project: Project OJT RMA System (OJT Management System)
# DBMS: PostgreSQL 18.x
# Description: Restores custom backup dump into a disposable test database
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../configuration/.env"

DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_NAME="ojt_management"
RESTORE_TEST_DB="ojt_management_restore_test"

if [[ -f "${CONFIG_FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${CONFIG_FILE}" 2>/dev/null || true
fi

BACKUP_FILE="${1:-}"
TARGET_DB="${2:-${RESTORE_TEST_DB}}"

if [[ -z "${BACKUP_FILE}" || ! -f "${BACKUP_FILE}" ]]; then
    echo "[ERROR] Please specify an existing backup archive file." >&2
    exit 1
fi

if [[ "${TARGET_DB,,}" == "${DB_NAME,,}" || "${TARGET_DB,,}" == "ojt_management" ]]; then
    echo "[FATAL] Safety Violation: Will not restore over primary database." >&2
    exit 1
fi

echo "====================================================================="
echo " Restoring: ${BACKUP_FILE}"
echo " Into Target Database: ${TARGET_DB}"
echo "====================================================================="

pg_restore -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d "${TARGET_DB}" --verbose "${BACKUP_FILE}" || true

echo "[INFO] Verifying restored tables:"
psql -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d "${TARGET_DB}" -c "\dt"

