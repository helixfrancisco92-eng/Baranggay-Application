#!/usr/bin/env bash
# ==============================================================================
# HabalGo (Group 6) — Automated PostgreSQL Backup Script
# Course: COMP 018 — Database Administration (Activity 6)
# Platform: PostgreSQL 15+ / Target Database: grp00_habalgodb
# Backup Format: Custom Compressed Archive (-Fc)
# ==============================================================================

set -euo pipefail

# 1. Configurable Connection Parameters with Sensible Defaults
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-grp00_habalgodb}"
DB_USER="${DB_USER:-postgres}"
BACKUP_DIR="${BACKUP_DIR:-$(dirname "$0")/../backups}"

echo "================================================================="
echo " HabalGo Database Backup Utility (PostgreSQL pg_dump -Fc)        "
echo " Target Database: ${DB_NAME}                                     "
echo "================================================================="

# 2. Check Prerequisites: Verify pg_dump Utility
if ! command -v pg_dump >/dev/null 2>&1; then
    echo "[ERROR] pg_dump utility not found in PATH." >&2
    echo "Please install PostgreSQL client tools or update your PATH environment variable." >&2
    exit 1
fi

PG_VERSION="$(pg_dump --version)"
echo "[1/6] Detected Utility: ${PG_VERSION}"

# 3. Create Secure Backup Directory Outside Git Tracking
echo "[2/6] Preparing backup destination directory..."
mkdir -p "${BACKUP_DIR}"
chmod 700 "${BACKUP_DIR}" 2>/dev/null || true
RESOLVED_BACKUP_DIR="$(cd "${BACKUP_DIR}" && pwd)"
echo "      Backup Directory: ${RESOLVED_BACKUP_DIR}"

# 4. Generate Standardized Timestamp and Output Filename
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
BACKUP_FILENAME="${DB_NAME}_activity6_${TIMESTAMP}.dump"
BACKUP_FILEPATH="${RESOLVED_BACKUP_DIR}/${BACKUP_FILENAME}"
CHECKSUM_FILEPATH="${BACKUP_FILEPATH}.sha256"

echo "      Target Archive File: ${BACKUP_FILENAME}"

# 5. Execute pg_dump with Custom Format (-Fc)
echo "[3/6] Executing pg_dump (-Fc) against database '${DB_NAME}'..."
START_TIME="$(date +%s)"

# Run pg_dump safely without echoing credentials
if pg_dump -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -Fc -d "${DB_NAME}" -f "${BACKUP_FILEPATH}"; then
    EXIT_CODE=$?
else
    EXIT_CODE=$?
    echo "[FAILED] pg_dump failed with exit code: ${EXIT_CODE}" >&2
    exit "${EXIT_CODE}"
fi

END_TIME="$(date +%s)"
DURATION=$((END_TIME - START_TIME))

# 6. Validate Backup Archive Existence and Non-Zero Size
echo "[4/6] Validating generated backup file integrity..."
if [[ ! -s "${BACKUP_FILEPATH}" ]]; then
    echo "[FAILED] Generated backup file is missing or empty (0 bytes). Backup aborted." >&2
    rm -f "${BACKUP_FILEPATH}"
    exit 1
fi

FILE_SIZE="$(stat -c %s "${BACKUP_FILEPATH}" 2>/dev/null || stat -f %z "${BACKUP_FILEPATH}" 2>/dev/null || wc -c < "${BACKUP_FILEPATH}")"

# 7. Generate Cryptographic SHA-256 Checksum
echo "[5/6] Computing SHA-256 cryptographic checksum..."
if command -v sha256sum >/dev/null 2>&1; then
    SHA256_HASH="$(sha256sum "${BACKUP_FILEPATH}" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
    SHA256_HASH="$(shasum -a 256 "${BACKUP_FILEPATH}" | awk '{print $1}')"
else
    SHA256_HASH="SHA256 utility not found in PATH"
fi

echo "${SHA256_HASH}  ${BACKUP_FILENAME}" > "${CHECKSUM_FILEPATH}"

# 8. Record Completion Manifest
echo "[6/6] Backup process completed successfully!"
echo "================================================================="
echo " BACKUP METADATA MANIFEST                                        "
echo "================================================================="
echo " Database Name       : ${DB_NAME}"
echo " Host / Port         : ${DB_HOST}:${DB_PORT}"
echo " Backup Format       : PostgreSQL Custom Archive (-Fc, zlib compressed)"
echo " Output File Path    : ${BACKUP_FILEPATH}"
echo " File Size (Bytes)   : ${FILE_SIZE} bytes"
echo " SHA-256 Hash        : ${SHA256_HASH}"
echo " Checksum Manifest   : ${CHECKSUM_FILEPATH}"
echo " Execution Duration  : ${DURATION} second(s)"
echo " Timestamp           : $(date +'%Y-%m-%d %H:%M:%S %Z')"
echo " Exit Code           : ${EXIT_CODE}"
echo " Status              : SUCCESS"
echo "================================================================="

