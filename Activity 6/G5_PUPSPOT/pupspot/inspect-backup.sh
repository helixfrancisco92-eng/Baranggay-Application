#!/usr/bin/env bash
# ==============================================================================
# PUP-SPOT (Group 5) — Backup Archive Inspector (Bash)
# Course: COMP 018 — Database Administration (Activity 6)
# Target Database: grp05_lostandfounddb
# Utility: pg_restore --list
# ==============================================================================

set -euo pipefail

BACKUP_FILE="${1:-../../backups/grp05_lostandfounddb_backup_20261112_235620.dump}"

if [ ! -f "${BACKUP_FILE}" ]; then
    LATEST=$(ls -t ../../backups/*.dump 2>/dev/null | head -n 1 || true)
    if [ -n "${LATEST}" ] && [ -f "${LATEST}" ]; then
        BACKUP_FILE="${LATEST}"
    else
        echo "[ERROR] Backup archive file not found: ${BACKUP_FILE}" >&2
        exit 1
    fi
fi

echo "================================================================="
echo " PUP-SPOT Backup Archive Inspector (pg_restore --list)           "
echo " Course: COMP 018 Database Administration (Activity 6)           "
echo "================================================================="

echo "[1/3] File Metadata Verification:"
echo " Archive Path    : ${BACKUP_FILE}"
FILE_SIZE=$(wc -c < "${BACKUP_FILE}" | tr -d ' ')
echo " File Size       : ${FILE_SIZE} bytes"

if command -v sha256sum >/dev/null 2>&1; then
    echo " SHA-256 Checksum: $(sha256sum "${BACKUP_FILE}" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
    echo " SHA-256 Checksum: $(shasum -a 256 "${BACKUP_FILE}" | awk '{print $1}')"
fi

echo ""
echo "[2/3] Verifying pg_restore..."
if ! command -v pg_restore >/dev/null 2>&1; then
    echo "[ERROR] pg_restore command not found in PATH." >&2
    exit 1
fi
echo " Utility Version : $(pg_restore --version)"

echo ""
echo "[3/3] Inspecting Table of Contents (TOC):"
echo "-----------------------------------------------------------------"
pg_restore --list "${BACKUP_FILE}"
echo "-----------------------------------------------------------------"
echo "[SUCCESS] Archive inspection verified successfully."

