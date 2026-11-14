#!/usr/bin/env bash
# ==============================================================================
# Script: restore.sh
# System: BoardTrack — Boarding House & Rental Management System
# Purpose: Execute PostgreSQL Database Restoration into Isolated Test Database
# OS / Environment: Linux / macOS / POSIX / Git Bash
# ==============================================================================

set -euo pipefail

RESTORE_DB="${1:-boardtrack_db_activity6_restore_test}"
ORIGINAL_DB="${2:-boardtrack_db}"
DUMP_PATH="${3:-/var/backups/boardtrack/boardtrack_db_activity6.dump}"
ADMIN_USER="${4:-postgres}"
DB_HOST="${5:-localhost}"
DB_PORT="${6:-5432}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/../logs/restore.log"

mkdir -p "$(dirname "${LOG_FILE}")"

echo "===================================================================="
echo "  BoardTrack Database Restoration — COMP 018 Activity 6"
echo "===================================================================="
echo "Timestamp      : $(date '+%Y-%m-%d %H:%M:%S')"
echo "Target Host    : ${DB_HOST}:${DB_PORT}"
echo "Destination DB : ${RESTORE_DB}"
echo "Live DB Guard  : ${ORIGINAL_DB}"
echo "Admin User     : ${ADMIN_USER}"
echo "Source Archive : ${DUMP_PATH}"
echo "===================================================================="

# CRITICAL SAFETY CHECK: NEVER RESTORE OVER LIVE DATABASE
if [[ "${RESTORE_DB,,}" == "${ORIGINAL_DB,,}" ]]; then
  echo "[FATAL ERROR] Destination database matches live database (${ORIGINAL_DB})!" >&2
  echo "[FATAL ERROR] Operation aborted to protect original data." >&2
  exit 1
fi

if [[ ! -f "${DUMP_PATH}" ]]; then
  echo "[ERROR] Dump archive not found: ${DUMP_PATH}" >&2
  exit 1
fi

START_TIME=$(date +%s)

echo "[INFO] Restoring database archive via pg_restore..."
set +e
pg_restore \
  -h "${DB_HOST}" \
  -p "${DB_PORT}" \
  -U "${ADMIN_USER}" \
  -d "${RESTORE_DB}" \
  -v "${DUMP_PATH}" 2>&1 | tee "${LOG_FILE}"
RESTORE_STATUS=$?
set -e

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "===================================================================="
echo "  RESTORATION EXECUTION AUDIT SUMMARY"
echo "===================================================================="
echo "Destination DB : ${RESTORE_DB}"
echo "Execution Time : ${DURATION} seconds"
echo "Exit Code      : ${RESTORE_STATUS}"
echo "Execution Log  : ${LOG_FILE}"

if [[ "${RESTORE_STATUS}" -eq 0 ]]; then
  echo "[SUCCESS] pg_restore completed successfully with 0 warnings."
elif [[ "${RESTORE_STATUS}" -eq 1 ]]; then
  echo "[NOTICE] pg_restore completed with warnings (Exit code 1). Check ${LOG_FILE}"
else
  echo "[ERROR] pg_restore failed with exit code ${RESTORE_STATUS}." >&2
  exit "${RESTORE_STATUS}"
fi
echo "===================================================================="

