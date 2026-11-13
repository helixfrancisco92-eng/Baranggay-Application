#!/usr/bin/env bash
# ==============================================================================
# Script: create-restore-db.sh
# System: BoardTrack — Boarding House & Rental Management System
# Purpose: Provision Isolated Empty PostgreSQL Restoration Test Database
# OS / Environment: Linux / macOS / POSIX / Git Bash
# ==============================================================================

set -euo pipefail

RESTORE_DB="${1:-boardtrack_db_activity6_restore_test}"
ORIGINAL_DB="${2:-boardtrack_db}"
ADMIN_USER="${3:-postgres}"
DB_HOST="${4:-localhost}"
DB_PORT="${5:-5432}"

echo "===================================================================="
echo "  BoardTrack Provision Isolated Restoration Database — COMP 018"
echo "===================================================================="
echo "Target Host     : ${DB_HOST}:${DB_PORT}"
echo "Admin User      : ${ADMIN_USER}"
echo "Restoration DB  : ${RESTORE_DB}"
echo "Live DB Guard   : ${ORIGINAL_DB}"
echo "===================================================================="

# CRITICAL SAFETY CHECK: NEVER TARGET LIVE DATABASE
if [[ "${RESTORE_DB,,}" == "${ORIGINAL_DB,,}" ]]; then
  echo "[FATAL ERROR] Restoration database name matches the live database name (${ORIGINAL_DB})!" >&2
  echo "[FATAL ERROR] Operation aborted to prevent overwriting production data." >&2
  exit 1
fi

echo "[INFO] Creating clean restoration database: '${RESTORE_DB}'..."
if createdb -h "${DB_HOST}" -p "${DB_PORT}" -U "${ADMIN_USER}" "${RESTORE_DB}"; then
  echo "===================================================================="
  echo "  ISOLATED TEST DATABASE PROVISIONED SUCCESSFULLY"
  echo "===================================================================="
  echo "Database Name   : ${RESTORE_DB}"
  echo "Status          : NEW AND EMPTY"
  echo "Live Isolation  : VERIFIED SEPARATE FROM ${ORIGINAL_DB}"
  echo "===================================================================="
else
  echo "[ERROR] Failed to create database '${RESTORE_DB}'." >&2
  exit 1
fi

