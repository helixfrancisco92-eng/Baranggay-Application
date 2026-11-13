#!/usr/bin/env bash
# ==============================================================================
# COMP 018 – Activity 6: Database Backup Automation Script
# Target Project: Project OJT RMA System (OJT Management System)
# DBMS: PostgreSQL 18.x
# Description: Generates logical compressed backup using pg_dump -Fc
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../configuration/.env"
BACKUP_DIR="${SCRIPT_DIR}/../backups"

# Default parameters
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="ojt_management"
DB_USER="postgres"

# Load config if present
if [[ -f "${CONFIG_FILE}" ]]; then
    echo "[INFO] Sourcing configuration from ${CONFIG_FILE}"
    # shellcheck disable=SC1090
    source "${CONFIG_FILE}" 2>/dev/null || true
fi

# Override from arguments
DB_NAME="${1:-${DB_NAME}}"
BACKUP_DIR="${2:-${BACKUP_DIR}}"

mkdir -p "${BACKUP_DIR}"

if ! command -v pg_dump >/dev/null 2>&1; then
    echo "[ERROR] pg_dump utility not found on PATH." >&2
    exit 1
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_backup_${TIMESTAMP}.dump"

echo "====================================================================="
echo " Starting pg_dump for database: ${DB_NAME}"
echo " Host: ${DB_HOST}:${DB_PORT} | User: ${DB_USER}"
echo " Destination: ${BACKUP_FILE}"
echo "====================================================================="

pg_dump -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -Fc -d "${DB_NAME}" -f "${BACKUP_FILE}"

if [[ -f "${BACKUP_FILE}" && -s "${BACKUP_FILE}" ]]; then
    FILE_SIZE=$(wc -c < "${BACKUP_FILE}")
    SHA256_HASH=$(sha256sum "${BACKUP_FILE}" | awk '{print $1}')
    echo "[SUCCESS] Backup created successfully!"
    echo "File: ${BACKUP_FILE}"
    echo "Size: ${FILE_SIZE} bytes"
    echo "SHA-256: ${SHA256_HASH}"
else
    echo "[ERROR] Backup failed or generated an empty file." >&2
    exit 1
fi

