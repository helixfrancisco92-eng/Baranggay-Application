#!/usr/bin/env bash
# ==============================================================================
# COMP 018 - Database Administration | Activity 6
# Script: create-restore-db.sh
# Purpose: Provision an isolated, clean test database for restoration testing
# Safety: CRITICAL - Enforces strict boundary checks against the live database
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOGS_DIR="${WORKSPACE_ROOT}/logs"

mkdir -p "${LOGS_DIR}"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
ADMIN_USER="${ADMIN_USER:-postgres}"
DB_OWNER="${DB_OWNER:-canteen_admin}"
ORIGINAL_DB="${ORIGINAL_DB:-canteen_db}"
RESTORE_DB="${RESTORE_DB:-canteen_db_activity6_restore_test}"

echo "=============================================================================="
echo " COMP 018 Activity 6 - Provision Isolated Restoration Test Database"
echo " Target Test Database : ${RESTORE_DB}"
echo " Host / Port          : ${DB_HOST}:${DB_PORT}"
echo " Admin User           : ${ADMIN_USER} | Database Owner: ${DB_OWNER}"
echo "=============================================================================="

# STRICT SAFETY CHECK
if [ "${RESTORE_DB}" = "${ORIGINAL_DB}" ]; then
    echo "FATAL SECURITY ERROR: Destination restore database cannot have the same name as the original live database ('${ORIGINAL_DB}')!" >&2
    echo "Aborting immediately to protect primary data." >&2
    exit 1
fi

# Locate psql and createdb
if ! command -v createdb >/dev/null 2>&1; then
    if [ -x "/c/Program Files/PostgreSQL/18/bin/createdb.exe" ]; then
        CREATEDB="/c/Program Files/PostgreSQL/18/bin/createdb.exe"
        PSQL="/c/Program Files/PostgreSQL/18/bin/psql.exe"
        DROPDB="/c/Program Files/PostgreSQL/18/bin/dropdb.exe"
    elif [ -x "/c/Program Files/PostgreSQL/16/bin/createdb.exe" ]; then
        CREATEDB="/c/Program Files/PostgreSQL/16/bin/createdb.exe"
        PSQL="/c/Program Files/PostgreSQL/16/bin/psql.exe"
        DROPDB="/c/Program Files/PostgreSQL/16/bin/dropdb.exe"
    else
        echo "ERROR: PostgreSQL client binaries (createdb/psql) not found." >&2
        exit 1
    fi
else
    CREATEDB="createdb"
    PSQL="psql"
    DROPDB="dropdb"
fi

if [ -z "${PGPASSWORD:-}" ]; then
    echo -n "Enter password for administrative user '${ADMIN_USER}': "
    read -s PGPASSWORD
    echo ""
    export PGPASSWORD
fi

# Check if target database already exists
DB_EXISTS=$("${PSQL}" -h "${DB_HOST}" -p "${DB_PORT}" -U "${ADMIN_USER}" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${RESTORE_DB}'" || echo "0")

if [ "${DB_EXISTS}" = "1" ]; then
    echo "WARNING: Test restoration database '${RESTORE_DB}' already exists from a prior test."
    echo -n "Do you want to drop and recreate '${RESTORE_DB}'? [y/N]: "
    read -r CONFIRM
    if [[ "${CONFIRM}" =~ ^[Yy]$ ]]; then
        echo "Dropping prior test database '${RESTORE_DB}'..."
        "${DROPDB}" -h "${DB_HOST}" -p "${DB_PORT}" -U "${ADMIN_USER}" "${RESTORE_DB}"
    else
        echo "Operation aborted by operator."
        unset PGPASSWORD
        exit 0
    fi
fi

echo "Creating empty test database '${RESTORE_DB}' with owner '${DB_OWNER}'..."
if "${CREATEDB}" -h "${DB_HOST}" -p "${DB_PORT}" -U "${ADMIN_USER}" -O "${DB_OWNER}" "${RESTORE_DB}"; then
    echo "[PASS] Successfully provisioned empty isolated test database: ${RESTORE_DB}"
else
    echo "ERROR: Failed to create test database '${RESTORE_DB}'." >&2
    unset PGPASSWORD
    exit 1
fi

unset PGPASSWORD
echo "Ready for restoration. Run 'restore.sh' to proceed."

