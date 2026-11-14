#!/usr/bin/env bash
# ==============================================================================
# CampusSafe (Group 7) — PostgreSQL Automated Backup Script (POSIX Bash)
# Course: COMP 018 — Database Administration (Activity 6)
# Evaluating Group: Group 12
# Target Database: grp07_campussafedb
# Backup Format: PostgreSQL Custom Compressed Archive (-Fc)
# ==============================================================================

set -euo pipefail

# 1. Configurable Environment Variables & Fallback Defaults
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-grp07_campussafedb}"
DB_USER="${DB_USER:-campussafe_backup}" # Member of app_backup_grp (PoLP)
BACKUP_DIR="${BACKUP_DIR:-$(dirname "$0")/../backups}"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_activity6.dump"
TIMESTAMPED_BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.dump"
MANIFEST_FILE="${BACKUP_DIR}/${DB_NAME}_manifest_${TIMESTAMP}.txt"

echo "================================================================="
echo " CampusSafe (Group 7) Database Backup Utility                    "
echo " Target Database: ${DB_NAME}                                     "
echo " Backup Operator: ${DB_USER}                                     "
echo " Host / Port:     ${DB_HOST}:${DB_PORT}                          "
echo "================================================================="

# 2. Verify Client Binaries
if ! command -v pg_dump >/dev/null 2>&1; then
    echo "[-] ERROR: 'pg_dump' utility not found in PATH." >&2
    echo "    Please verify PostgreSQL client tools are installed and configured." >&2
    exit 1
fi

# 3. Ensure Destination Directory Exists
if [ ! -d "${BACKUP_DIR}" ]; then
    echo "[*] Creating backup destination directory: ${BACKUP_DIR}"
    mkdir -p "${BACKUP_DIR}"
    chmod 700 "${BACKUP_DIR}" 2>/dev/null || true
fi

# 4. Check PostgreSQL Server Connectivity
echo "[1/5] Probing PostgreSQL server connectivity..."
if command -v pg_isready >/dev/null 2>&1; then
    if ! pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -d "${DB_NAME}" -U "${DB_USER}" >/dev/null 2>&1; then
        echo "[-] WARNING: pg_isready reported database '${DB_NAME}' may not be accepting connections."
        echo "    Proceeding with connection attempt..."
    else
        echo "[+] PostgreSQL server is reachable."
    fi
fi

# 5. Execute Custom-Format Logical Backup
echo "[2/5] Initiating pg_dump custom archive export (-Fc)..."
START_TIME=$(date +%s)

pg_dump \
    -U "${DB_USER}" \
    -h "${DB_HOST}" \
    -p "${DB_PORT}" \
    -Fc \
    -d "${DB_NAME}" \
    -f "${BACKUP_FILE}"

DUMP_STATUS=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [ ${DUMP_STATUS} -ne 0 ]; then
    echo "[-] FATAL: pg_dump failed with exit code ${DUMP_STATUS}." >&2
    exit ${DUMP_STATUS}
fi

# Maintain timestamped archive copy for retention management
cp "${BACKUP_FILE}" "${TIMESTAMPED_BACKUP_FILE}"

# 6. Compute File Size and Cryptographic SHA-256 Checksum
echo "[3/5] Computing file size and SHA-256 checksum..."
if command -v sha256sum >/dev/null 2>&1; then
    SHA256_HASH=$(sha256sum "${BACKUP_FILE}" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    SHA256_HASH=$(shasum -a 256 "${BACKUP_FILE}" | awk '{print $1}')
else
    SHA256_HASH="SHA256 utility not available in environment"
fi

if [ "$(uname)" = "Darwin" ]; then
    FILE_SIZE=$(stat -f%z "${BACKUP_FILE}")
else
    FILE_SIZE=$(stat -c%s "${BACKUP_FILE}" 2>/dev/null || wc -c < "${BACKUP_FILE}")
fi

# 7. Generate Manifest Record
cat <<EOF > "${MANIFEST_FILE}"
=================================================================
CampusSafe (Group 7) — Activity 6 Backup Manifest Record
=================================================================
Target Database:     ${DB_NAME}
Backup Operator:     ${DB_USER}
Host:Port:           ${DB_HOST}:${DB_PORT}
Backup File:         $(basename "${BACKUP_FILE}")
Timestamped File:    $(basename "${TIMESTAMPED_BACKUP_FILE}")
Backup Format:       PostgreSQL Custom Archive (-Fc, zlib compressed)
File Size (bytes):   ${FILE_SIZE}
SHA-256 Checksum:    ${SHA256_HASH}
Creation Date:       $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Duration (seconds):  ${DURATION}
Exit Status:         SUCCESS (Code 0)
=================================================================
EOF

# 8. Output Summary
echo "[4/5] Backup completed successfully in ${DURATION}s."
echo "[5/5] Backup Manifest:"
cat "${MANIFEST_FILE}"
echo "================================================================="
echo "[+] SUCCESS: Backup stored at: ${BACKUP_FILE}"
echo "================================================================="

