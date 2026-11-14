#!/usr/bin/env bash
# ==============================================================================
# PUP-SPOT (Group 5) — Automated Database Restoration Test Script (Bash)
# Course: COMP 018 — Database Administration (Activity 6: Part C)
# Target Project: PUP-SPOT Lost and Found System
# Source Database: grp05_lostandfounddb
# Disposable Test Database: grp05_lostandfounddb_activity6_restore_test
# ==============================================================================

set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
SOURCE_DB="${SOURCE_DB:-grp05_lostandfounddb}"
TEST_DB="${TEST_DB:-grp05_lostandfounddb_activity6_restore_test}"
DB_USER="${DB_USER:-lf_admin_user}"
ADMIN_USER="${ADMIN_USER:-postgres}"
BACKUP_FILE="${1:-../../backups/grp05_lostandfounddb_backup_20261112_235620.dump}"

echo "================================================================="
echo " PUP-SPOT Isolated Database Restoration Test                     "
echo " Course: COMP 018 Database Administration (Activity 6)           "
echo "================================================================="

# 1. Safety Checks
if [ "${SOURCE_DB}" = "${TEST_DB}" ]; then
    echo "[FATAL] Source database and test database cannot be identical (${SOURCE_DB}). Overwrite prevented." >&2
    exit 1
fi
echo "[INFO] Source Database: ${SOURCE_DB}"
echo "[INFO] Test Database  : ${TEST_DB}"

# 2. Check Archive
if [ ! -f "${BACKUP_FILE}" ]; then
    LATEST=$(ls -t ../../backups/*.dump 2>/dev/null | head -n 1 || true)
    if [ -n "${LATEST}" ] && [ -f "${LATEST}" ]; then
        BACKUP_FILE="${LATEST}"
    else
        echo "[FATAL] Backup archive not found: ${BACKUP_FILE}" >&2
        exit 1
    fi
fi
echo "[INFO] Using Archive  : ${BACKUP_FILE}"

# 3. Inspect TOC
echo "[INFO] Inspecting Table of Contents..."
pg_restore --list "${BACKUP_FILE}" >/dev/null

# 4. Provision Test Database
echo "[INFO] Attempting test database creation (${TEST_DB})..."
if createdb -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" "${TEST_DB}" 2>/dev/null; then
    echo "[INFO] Test database created successfully using ${DB_USER}."
    DB_READY=true
else
    echo "[NOTICE] createdb with user '${DB_USER}' failed. Role lacks CREATEDB privilege."
    if createdb -U "${ADMIN_USER}" -h "${DB_HOST}" -p "${DB_PORT}" "${TEST_DB}" 2>/dev/null; then
        echo "[INFO] Test database created successfully using ${ADMIN_USER}."
        DB_READY=true
    else
        echo "[WARNING] Could not create test database. Execution requires cluster superuser."
        DB_READY=false
    fi
fi

# 5. Execute Restoration
if [ "${DB_READY}" = "true" ]; then
    echo "[INFO] Executing pg_restore into ${TEST_DB}..."
    pg_restore -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d "${TEST_DB}" --verbose "${BACKUP_FILE}"
    echo "[SUCCESS] Restoration completed."
else
    echo "[BLOCKED] Restoration skipped pending creation of test database."
fi

