#!/usr/bin/env bash
# ==============================================================================
# COMP 018 – Activity 6: Restoration Verification Script
# Target Project: Project OJT RMA System (OJT Management System)
# DBMS: PostgreSQL 18.x
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../configuration/.env"
SQL_SCRIPT="${SCRIPT_DIR}/../sql/verification-queries.sql"

DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
RESTORE_TEST_DB="ojt_management_restore_test"

if [[ -f "${CONFIG_FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${CONFIG_FILE}" 2>/dev/null || true
fi

TARGET_DB="${1:-${RESTORE_TEST_DB}}"

echo "====================================================================="
echo " Running Verification Suite on: ${TARGET_DB}"
echo "====================================================================="

psql -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d "${TARGET_DB}" -f "${SQL_SCRIPT}"

