#!/usr/bin/env bash
# ==============================================================================
# Script: backup.sh
# System: BoardTrack — Boarding House & Rental Management System
# Purpose: Automated PostgreSQL Custom Format Logical Backup (pg_dump -Fc)
# OS / Environment: Linux / macOS / POSIX / Git Bash
# ==============================================================================

set -euo pipefail

# Configuration defaults
DB_NAME="${1:-boardtrack_db}"
DB_USER="${2:-postgres}"
DB_HOST="${3:-localhost}"
DB_PORT="${4:-5432}"
OUTPUT_DIR="${5:-/var/backups/boardtrack}"
DUMP_FILENAME="${6:-boardtrack_db_activity6.dump}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/../logs/backup.log"

mkdir -p "${OUTPUT_DIR}"
mkdir -p "$(dirname "${LOG_FILE}")"

TARGET_DUMP="${OUTPUT_DIR}/${DUMP_FILENAME}"

echo "===================================================================="
echo "  BoardTrack Database Logical Backup — COMP 018 Activity 6"
echo "===================================================================="
echo "Timestamp   : $(date '+%Y-%m-%d %H:%M:%S')"
echo "Target Host : ${DB_HOST}:${DB_PORT}"
echo "Database    : ${DB_NAME}"
echo "Backup User : ${DB_USER}"
echo "Output Path : ${TARGET_DUMP}"
echo "===================================================================="

START_TIME=$(date +%s)

echo "[INFO] Running pg_dump with custom compressed archive format (-Fc)..."
pg_dump \
  -h "${DB_HOST}" \
  -p "${DB_PORT}" \
  -U "${DB_USER}" \
  -d "${DB_NAME}" \
  -Fc \
  -v \
  -f "${TARGET_DUMP}" 2>&1 | tee "${LOG_FILE}"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [[ -f "${TARGET_DUMP}" ]]; then
  FILE_SIZE=$(wc -c < "${TARGET_DUMP}")
  FILE_SIZE_KB=$(awk "BEGIN {printf \"%.2f\", ${FILE_SIZE}/1024}")
  
  if command -v sha256sum &>/dev/null; then
    SHA256=$(sha256sum "${TARGET_DUMP}" | awk '{print $1}')
  elif command -v shasum &>/dev/null; then
    SHA256=$(shasum -a 256 "${TARGET_DUMP}" | awk '{print $1}')
  else
    SHA256="UNKNOWN_SHASUM_MISSING"
  fi
  
  echo "${SHA256}  ${TARGET_DUMP}" > "${TARGET_DUMP}.sha256"

  echo ""
  echo "===================================================================="
  echo "  BACKUP COMPLETED SUCCESSFULLY"
  echo "===================================================================="
  echo "Dump File       : ${TARGET_DUMP}"
  echo "File Size       : ${FILE_SIZE} bytes (${FILE_SIZE_KB} KB)"
  echo "Execution Time  : ${DURATION} seconds"
  echo "SHA-256 Checksum: ${SHA256}"
  echo "Execution Log   : ${LOG_FILE}"
  echo "===================================================================="
else
  echo "[ERROR] Backup archive was not created: ${TARGET_DUMP}" >&2
  exit 1
fi

