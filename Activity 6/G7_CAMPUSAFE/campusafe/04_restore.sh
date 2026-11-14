#!/usr/bin/env bash
# ==============================================================================
# CampusSafe (Group 7) — Isolated Database Restoration Script (POSIX Bash)
# Course: COMP 018 — Database Administration (Activity 6)
# Target Database: grp07_campussafedb_activity6_restore_test
# ==============================================================================

set -euo pipefail

# 1. Configurable Connection Parameters
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
ADMIN_USER="${ADMIN_USER:-postgres}" # Administrative role required for restoration
ORIGINAL_DB="${ORIGINAL_DB:-grp07_campussafedb}"
RESTORE_DB="${RESTORE_DB:-grp07_campussafedb_activity6_restore_test}"
BACKUP_DIR="${BACKUP_DIR:-$(dirname "$0")/../backups}"
BACKUP_FILE="${1:-${BACKUP_DIR}/grp07_campussafedb_activity6.dump}"

echo "================================================================="
echo " CampusSafe (Group 7) Isolated Database Restoration Utility     "
echo " Production Database:  ${ORIGINAL_DB} (STRICTLY UNTOUCHED)        "
echo " Restoration Target:   ${RESTORE_DB}                              "
echo " Backup Source Archive: ${BACKUP_FILE}                            "
echo "================================================================="

# 2. Strict Safety Verification: Target MUST NOT be Original Production DB
if [ "${RESTORE_DB}" = "${ORIGINAL_DB}" ]; then
    echo "[-] FATAL ERROR: Attempted to restore directly into the production database!" >&2
    echo "    Cardinal Rule Violation: Never restore over the original database." >&2
    exit 1
fi

# 3. Confirm Backup Archive Exists
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "[-] ERROR: Backup archive file not found: ${BACKUP_FILE}" >&2
    echo "    Please run '01_backup.sh' first to generate the dump file." >&2
    exit 1
fi

# 4. Verify Client Utilities
if ! command -v pg_restore >/dev/null 2>&1; then
    echo "[-] ERROR: 'pg_restore' utility not found in PATH." >&2
    exit 1
fi

# 5. Check if Destination Database Exists; If Missing, Create It
echo "[1/4] Checking destination test database '${RESTORE_DB}'..."
DB_EXISTS=$(psql -U "${ADMIN_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d postgres -tAc \
    "SELECT 1 FROM pg_database WHERE datname = '${RESTORE_DB}'" 2>/dev/null || true)

if [ "${DB_EXISTS}" != "1" ]; then
    echo "[*] Creating isolated restoration test database '${RESTORE_DB}'..."
    createdb -U "${ADMIN_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -O "${ADMIN_USER}" "${RESTORE_DB}"
else
    echo "[+] Test database '${RESTORE_DB}' exists."
fi

# 6. Verify Target Database is Clean
USER_TABLES=$(psql -U "${ADMIN_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d "${RESTORE_DB}" -tAc \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE'" 2>/dev/null || echo "0")

if [ "${USER_TABLES}" -gt 0 ]; then
    echo "[-] WARNING: Destination database '${RESTORE_DB}' already contains ${USER_TABLES} tables."
    echo "    For a clean Activity 6 test, consider dropping and recreating using '03_create_restore_database.sql'."
fi

# 7. Execute pg_restore
echo "[2/4] Executing pg_restore into '${RESTORE_DB}'..."
START_TIME=$(date +%s)

# Use --no-owner --no-privileges to ensure clean restore across environments where custom roles may not pre-exist
pg_restore \
    -U "${ADMIN_USER}" \
    -h "${DB_HOST}" \
    -p "${DB_PORT}" \
    -d "${RESTORE_DB}" \
    --no-owner \
    --no-privileges \
    --verbose \
    "${BACKUP_FILE}" 2>&1 | tee "${BACKUP_DIR}/restore_execution.log" || true

RESTORE_STATUS=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "[3/4] Restoration process concluded in ${DURATION}s."

# 8. Post-Restoration Sanity Audit
echo "[4/4] Conducting post-restoration object count audit:"
psql -U "${ADMIN_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d "${RESTORE_DB}" -c "
SELECT 
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE') AS restored_tables,
    (SELECT COUNT(*) FROM information_schema.sequences WHERE sequence_schema = 'public') AS restored_sequences,
    (SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public' AND indexname NOT LIKE '%_pkey' AND indexname NOT LIKE '%_key') AS restored_indexes;
"

echo "================================================================="
echo "[+] SUCCESS: Archive restored into isolated test database: ${RESTORE_DB}"
echo "    Next Step: Run verification scripts 05 through 08."
echo "================================================================="

