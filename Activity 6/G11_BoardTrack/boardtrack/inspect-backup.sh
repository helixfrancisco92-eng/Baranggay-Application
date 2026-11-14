#!/usr/bin/env bash
# ==============================================================================
# Script: inspect-backup.sh
# System: BoardTrack — Boarding House & Rental Management System
# Purpose: Inspect Table-of-Contents (TOC) of PostgreSQL custom dump archive
# OS / Environment: Linux / macOS / POSIX / Git Bash
# ==============================================================================

set -euo pipefail

DUMP_PATH="${1:-/var/backups/boardtrack/boardtrack_db_activity6.dump}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/../logs/inspect-backup.log"

mkdir -p "$(dirname "${LOG_FILE}")"

echo "===================================================================="
echo "  BoardTrack Backup Archive TOC Inspection — COMP 018 Activity 6"
echo "===================================================================="
echo "Timestamp   : $(date '+%Y-%m-%d %H:%M:%S')"
echo "Target Dump : ${DUMP_PATH}"
echo "===================================================================="

if [[ ! -f "${DUMP_PATH}" ]]; then
  echo "[ERROR] Dump archive not found: ${DUMP_PATH}" >&2
  echo "[INFO] Execute backup.sh first or provide valid archive path." >&2
  exit 1
fi

if command -v sha256sum &>/dev/null; then
  echo "[INFO] SHA-256: $(sha256sum "${DUMP_PATH}" | awk '{print $1}')"
fi

echo "[INFO] Extracting Table-of-Contents (pg_restore --list)..."
pg_restore --list "${DUMP_PATH}" > "${LOG_FILE}"

echo ""
echo "--- Schema Object Audit from Backup TOC ---"
MISSING=0
TABLES=("property" "room" "tenant" "lease" "payment" "utility_bill" "app_user" "schema_migrations")
for tbl in "${TABLES[@]}"; do
  if grep -q "TABLE public ${tbl} " "${LOG_FILE}"; then
    echo "  [FOUND] TABLE: ${tbl}"
  else
    echo "  [MISSING] TABLE: ${tbl}"
    MISSING=$((MISSING + 1))
  fi
done

if grep -q "VIEW public v_lease_summary " "${LOG_FILE}"; then
  echo "  [FOUND] VIEW: v_lease_summary"
else
  echo "  [MISSING] VIEW: v_lease_summary"
  MISSING=$((MISSING + 1))
fi

echo "===================================================================="
if [[ "${MISSING}" -eq 0 ]]; then
  echo "[SUCCESS] Archive TOC verified: All core tables and views present!"
else
  echo "[WARNING] ${MISSING} objects missing from TOC. See ${LOG_FILE}"
fi
echo "TOC recorded to: ${LOG_FILE}"
echo "===================================================================="

