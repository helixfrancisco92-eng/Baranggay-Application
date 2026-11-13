#!/usr/bin/env bash
# ==============================================================================
# COMP 018 – Activity 6: Create Restoration Test Database
# Target Project: Project OJT RMA System (OJT Management System)
# DBMS: PostgreSQL 18.x
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

TARGET_DB="${1:-${RESTORE_TEST_DB}}"

if [[ "${TARGET_DB,,}" == "${DB_NAME,,}" || "${TARGET_DB,,}" == "ojt_management" ]]; then
    echo "[FATAL] Safety Violation: Test database name matches primary database. Refusing to drop/recreate." >&2
    exit 1
fi

echo "[INFO] Recreating clean test database: ${TARGET_DB}"
dropdb -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" --if-exists "${TARGET_DB}" || true
createdb -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -E UTF8 "${TARGET_DB}"

echo "[SUCCESS] Isolated test database created: ${TARGET_DB}"

