#!/usr/bin/env bash
# ==============================================================================
# COMP 018 – Activity 6: Backup Archive Inspection Script
# Target Project: Project OJT RMA System (OJT Management System)
# DBMS: PostgreSQL 18.x
# Description: Validates custom archive readability using pg_restore --list
# ==============================================================================

set -euo pipefail

BACKUP_FILE="${1:-}"

if [[ -z "${BACKUP_FILE}" ]]; then
    echo "Usage: $0 <path_to_backup.dump>" >&2
    exit 1
fi

if [[ ! -f "${BACKUP_FILE}" ]]; then
    echo "[ERROR] File not found: ${BACKUP_FILE}" >&2
    exit 1
fi

if ! command -v pg_restore >/dev/null 2>&1; then
    echo "[ERROR] pg_restore utility not found on PATH." >&2
    exit 1
fi

echo "====================================================================="
echo " Inspecting Archive: ${BACKUP_FILE}"
echo " File Size: $(wc -c < "${BACKUP_FILE}") bytes"
echo " SHA-256: $(sha256sum "${BACKUP_FILE}" | awk '{print $1}')"
echo "====================================================================="

pg_restore --list "${BACKUP_FILE}" | head -n 40

