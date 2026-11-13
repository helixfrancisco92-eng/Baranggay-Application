#!/usr/bin/env bash
# ==============================================================================
# CampusSafe (Group 7) — Archive Inspection Utility (POSIX Bash)
# Course: COMP 018 — Database Administration (Activity 6)
# Target Database: grp07_campussafedb
# Inspects the Table of Contents (TOC) of a pg_dump Custom Archive (-Fc)
# ==============================================================================

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-$(dirname "$0")/../backups}"
BACKUP_FILE="${1:-${BACKUP_DIR}/grp07_campussafedb_activity6.dump}"
TOC_OUTPUT="${BACKUP_DIR}/grp07_campussafedb_toc_listing.txt"

echo "================================================================="
echo " CampusSafe (Group 7) Archive TOC Inspection Utility             "
echo " Target Archive: ${BACKUP_FILE}                                  "
echo "================================================================="

if [ ! -f "${BACKUP_FILE}" ]; then
    echo "[-] ERROR: Backup archive file not found: ${BACKUP_FILE}" >&2
    echo "    Please execute '01_backup.sh' first to generate the dump archive." >&2
    exit 1
fi

if ! command -v pg_restore >/dev/null 2>&1; then
    echo "[-] ERROR: 'pg_restore' utility not found in PATH." >&2
    exit 1
fi

echo "[1/3] Extracting archive Table of Contents (TOC) via pg_restore --list..."
pg_restore --list "${BACKUP_FILE}" > "${TOC_OUTPUT}"

TOC_ENTRIES=$(wc -l < "${TOC_OUTPUT}")

echo "[2/3] Analyzing database object breakdown inside archive:"
TABLES_COUNT=$(grep -c "TABLE DATA public " "${TOC_OUTPUT}" || true)
INDEX_COUNT=$(grep -c "INDEX public " "${TOC_OUTPUT}" || true)
SEQ_COUNT=$(grep -c "SEQUENCE " "${TOC_OUTPUT}" || true)
FK_COUNT=$(grep -c "FK CONSTRAINT public " "${TOC_OUTPUT}" || true)
CHECK_COUNT=$(grep -c "CHECK CONSTRAINT public " "${TOC_OUTPUT}" || true)

echo "-----------------------------------------------------------------"
echo " Total Catalog TOC Items:     ${TOC_ENTRIES}"
echo " User Table Data Blocks:      ${TABLES_COUNT} / 9 expected"
echo " Performance B-Tree Indexes:  ${INDEX_COUNT} / 10 expected (+ PK/Unique)"
echo " Auto-Increment Sequences:    ${SEQ_COUNT} / 9 expected"
echo " Foreign Key Constraints:     ${FK_COUNT}"
echo " Domain CHECK Constraints:    ${CHECK_COUNT}"
echo "-----------------------------------------------------------------"

echo "[3/3] Previewing first 25 TOC catalog entries:"
head -n 25 "${TOC_OUTPUT}"

echo "================================================================="
echo "[+] Full Table of Contents exported to: ${TOC_OUTPUT}"
echo "================================================================="

