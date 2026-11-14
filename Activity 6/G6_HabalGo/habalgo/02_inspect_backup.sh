#!/usr/bin/env bash
# ==============================================================================
# HabalGo (Group 6) — Backup Archive Inspection Script
# Course: COMP 018 — Database Administration (Activity 6)
# Platform: PostgreSQL pg_restore --list
# ==============================================================================

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-$(dirname "$0")/../backups}"

echo "================================================================="
echo " HabalGo Backup Archive Table of Contents (TOC) Inspection       "
echo " Utility: pg_restore --list                                      "
echo "================================================================="

# 1. Locate Latest Backup File if not explicitly specified
if [[ $# -ge 1 ]]; then
    BACKUP_FILE="$1"
else
    # Find newest .dump file in BACKUP_DIR
    BACKUP_FILE="$(ls -t "${BACKUP_DIR}"/*activity6*.dump 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "${BACKUP_FILE}" || ! -f "${BACKUP_FILE}" ]]; then
    echo "[ERROR] No valid backup archive found to inspect." >&2
    echo "Usage: $0 [path_to_backup.dump]" >&2
    exit 1
fi

echo "[1/4] Target Backup Archive: ${BACKUP_FILE}"
FILE_SIZE="$(stat -c %s "${BACKUP_FILE}" 2>/dev/null || stat -f %z "${BACKUP_FILE}" 2>/dev/null || wc -c < "${BACKUP_FILE}")"
echo "      Archive Size: ${FILE_SIZE} bytes"

# 2. Verify SHA-256 Checksum if manifest exists
CHECKSUM_FILE="${BACKUP_FILE}.sha256"
if [[ -f "${CHECKSUM_FILE}" ]]; then
    echo "[2/4] Verifying SHA-256 cryptographic checksum against manifest..."
    if command -v sha256sum >/dev/null 2>&1; then
        (cd "$(dirname "${BACKUP_FILE}")" && sha256sum -c "$(basename "${CHECKSUM_FILE}")")
    else
        echo "      Stored Hash: $(cat "${CHECKSUM_FILE}")"
    fi
else
    echo "[2/4] Warning: No checksum manifest (.sha256) found alongside archive."
fi

# 3. Execute pg_restore --list to inspect Table of Contents (TOC)
echo "[3/4] Parsing Archive Table of Contents (TOC)..."
TOC_OUTPUT="$(pg_restore --list "${BACKUP_FILE}")"

TOTAL_OBJECTS="$(echo "${TOC_OUTPUT}" | grep -v '^;' | grep -v '^$' | wc -l)"
TABLES_FOUND="$(echo "${TOC_OUTPUT}" | grep -i ' TABLE ' | awk '{print $NF}' || true)"
SEQUENCES_FOUND="$(echo "${TOC_OUTPUT}" | grep -i ' SEQUENCE ' | awk '{print $NF}' || true)"
CONSTRAINTS_FOUND="$(echo "${TOC_OUTPUT}" | grep -i ' CONSTRAINT ' | awk '{print $NF}' || true)"
INDEXES_FOUND="$(echo "${TOC_OUTPUT}" | grep -i ' INDEX ' | awk '{print $NF}' || true)"

echo "-----------------------------------------------------------------"
echo " ARCHIVE TOC SUMMARY                                             "
echo "-----------------------------------------------------------------"
echo " Total Header Entries  : ${TOTAL_OBJECTS}"
echo ""
echo " Tables Cataloged in Archive:"
echo "${TABLES_FOUND}"
echo ""
echo " Sequences Cataloged in Archive:"
echo "${SEQUENCES_FOUND}"
echo ""
echo " Explicit Indexes Cataloged in Archive:"
echo "${INDEXES_FOUND}"
echo "-----------------------------------------------------------------"

# 4. Educational Note: What TOC Inspection Proves vs Does NOT Prove
echo "[4/4] ARCHIVE AUDIT EVALUATION:"
cat << 'EOF'
=================================================================
WHAT TOC INSPECTION PROVES:
1. The backup file is a valid, uncorrupted PostgreSQL custom-format archive.
2. The archive header and table of contents are readable and syntactically sound.
3. The listed database objects (schemas, tables, sequences, indexes, and ACLs)
   were successfully captured by pg_dump at the time of backup.

WHAT TOC INSPECTION DOES NOT PROVE (Why restore testing is mandatory):
1. It does NOT prove that table rows or data blocks are free from storage corruption.
2. It does NOT prove that foreign key constraints can be satisfied upon restoration.
3. It does NOT prove that target database roles, users, and permissions exist.
4. It does NOT prove that the application can successfully connect and execute queries.
5. True database recoverability can ONLY be established through successful restoration
   and semantic verification in an isolated test database.
=================================================================
EOF

