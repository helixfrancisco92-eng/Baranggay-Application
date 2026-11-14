#!/usr/bin/env bash
# ==============================================================================
# COMP 018 - Database Administration | Activity 6
# Script: create-restore-db.sh
# Purpose: Provision Isolated Empty Test Database for Restoration Validation
# ==============================================================================

set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
ADMIN_USER="${ADMIN_USER:-postgres}"
ORIGINAL_DB="grp_binarysisters_projectdb"
RESTORE_DB="${RESTORE_DB:-grp_binarysisters_projectdb_activity6_restore_test}"

echo "=============================================================================="
echo " COMP 018 Activity 6 - Provision Isolated Restoration Database (Bash)"
echo " Target Test Database : ${RESTORE_DB}"
echo " Host / Port          : ${DB_HOST}:${DB_PORT} | Admin: ${ADMIN_USER}"
echo "=============================================================================="

# CRITICAL SAFETY CHECK: NEVER RESTORE OVER ORIGINAL DATABASE
if [ "${RESTORE_DB}" = "${ORIGINAL_DB}" ]; then
    echo "FATAL SECURITY ERROR: Target restoration database cannot equal the live database '${ORIGINAL_DB}'!" >&2
    echo "Operation aborted immediately to protect production integrity." >&2
    exit 1
fi

if ! command -v createdb &> /dev/null || ! command -v psql &> /dev/null; then
    echo "ERROR: PostgreSQL client binaries (createdb / psql) not found on PATH." >&2
    exit 1
fi

# Acquire password securely if not set
if [ -z "${PGPASSWORD:-}" ]; then
    read -rsp "Enter password for administrative user '${ADMIN_USER}': " PGPASSWORD
    echo
    export PGPASSWORD
fi

# Check if target database already exists
echo "Checking if database '${RESTORE_DB}' exists..."
DB_EXISTS=$(psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${ADMIN_USER}" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${RESTORE_DB}';" || true)

if [ "${DB_EXISTS}" = "1" ]; then
    echo "Notice: Test database '${RESTORE_DB}' already exists."
    read -rp "Recreate empty test database? This drops only '${RESTORE_DB}' (y/N): " CONFIRM
    if [[ "${CONFIRM}" =~ ^[Yy]$ ]]; then
        echo "Terminating existing connections to '${RESTORE_DB}'..."
        psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${ADMIN_USER}" -d postgres -c \
            "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='${RESTORE_DB}' AND pid <> pg_backend_pid();" > /dev/null
        echo "Dropping '${RESTORE_DB}'..."
        dropdb -h "${DB_HOST}" -p "${DB_PORT}" -U "${ADMIN_USER}" "${RESTORE_DB}"
    else
        echo "Preserving existing test database. Exiting."
        exit 0
    fi
fi

# Provision fresh empty database
echo "Creating isolated test database '${RESTORE_DB}' owned by '${ADMIN_USER}'..."
createdb -h "${DB_HOST}" -p "${DB_PORT}" -U "${ADMIN_USER}" -O "${ADMIN_USER}" "${RESTORE_DB}"

# Enable required extensions in the test database
echo "Enabling necessary extensions in '${RESTORE_DB}'..."
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${ADMIN_USER}" -d "${RESTORE_DB}" -c "CREATE EXTENSION IF NOT EXISTS btree_gist; CREATE EXTENSION IF NOT EXISTS pgcrypto;"

echo "=============================================================================="
echo " PROVISIONING SUCCESSFUL: Test database '${RESTORE_DB}' is ready."
echo "=============================================================================="

