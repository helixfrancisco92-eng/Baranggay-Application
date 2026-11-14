#!/usr/bin/env bash
# ==============================================================================
# PUP-SPOT (Group 5) — Automated Database Backup Script (Bash)
# Course: COMP 018 — Database Administration (Activity 6)
# Target Project: PUP-SPOT Lost and Found System
# Database Engine: PostgreSQL 18.0 / 16+
# Target Database: grp05_lostandfounddb
# ==============================================================================

set -euo pipefail

# Configuration parameters
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-grp05_lostandfounddb}"
DB_USER="${DB_USER:-lf_admin_user}"
BACKUP_DIR="${BACKUP_DIR:-../../backups}"

echo "================================================================="
echo " PUP-SPOT Database Backup Utility (PostgreSQL pg_dump -Fc)       "
echo " Course: COMP 018 Database Administration (Activity 6)           "
echo "================================================================="

# 1. Verify client tools
if ! command -v pg_dump >/dev/null 2>&1; then
    echo "[ERROR] pg_dump utility not found in PATH." >&2
    exit 1
fi
echo "[INFO] Using pg_dump: $(pg_dump --version)"

# 2. Check Database Reachability
echo "[INFO] Testing connectivity to ${DB_HOST}:${DB_PORT} for database ${DB_NAME}..."
if command -v psql >/dev/null 2>&1; then
    if ! psql -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d "${DB_NAME}" -c "SELECT 1;" >/dev/null 2>&1; then
        echo "[WARNING] Pre-connection test failed. Ensure credentials and cluster are ready."
    else
        echo "[INFO] Connection verified successfully."
    fi
fi

# 3. Create destination folder
mkdir -p "${BACKUP_DIR}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_backup_${TIMESTAMP}.dump"

echo "[INFO] Creating backup archive: ${BACKUP_FILE}..."
START_TIME=$(date +%s)

# 4. Execute pg_dump
pg_dump -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -Fc -d "${DB_NAME}" -f "${BACKUP_FILE}"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# 5. Validate file integrity
if [ ! -s "${BACKUP_FILE}" ]; then
    echo "[ERROR] Backup failed or generated an empty file." >&2
    exit 1
fi

FILE_SIZE=$(wc -c < "${BACKUP_FILE}" | tr -d ' ')
if command -v sha256sum >/dev/null 2>&1; then
    FILE_HASH=$(sha256sum "${BACKUP_FILE}" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    FILE_HASH=$(shasum -a 256 "${BACKUP_FILE}" | awk '{print $1}')
else
    FILE_HASH="SHA256_UNAVAILABLE"
fi

echo "================================================================="
echo " BACKUP GENERATED SUCCESSFULLY"
echo "================================================================="
echo " Target Database : ${DB_NAME}"
echo " Archive Path    : ${BACKUP_FILE}"
echo " File Size       : ${FILE_SIZE} bytes"
echo " SHA-256 Hash    : ${FILE_HASH}"
echo " Duration        : ${DURATION} seconds"
echo " Timestamp       : $(date +"%Y-%m-%d %H:%M:%S")"
echo "================================================================="

