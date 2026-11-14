#!/usr/bin/env bash
# ==============================================================================
# COMP 018 — Database Administration (Activity 6: Part B)
# Script: 02-backup.sh
# Purpose: Interactive, secure custom-format backup generator for Park-It DBMS
# Platform: PostgreSQL 18.6 | Target DB: grp_parkitdb
# ==============================================================================

set -euo pipefail

# --- Color formatting for CLI output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Script directory and base paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/../backups"
LOG_FILE="${BACKUP_DIR}/backup_execution.log"

echo -e "${BLUE}================================================================${NC}"
echo -e "${CYAN}  PARK-IT DATABASE MANAGEMENT SYSTEM — AUTOMATED BACKUP UTILITY ${NC}"
echo -e "${CYAN}  COMP 018 Database Administration (Activity 6: Part B)          ${NC}"
echo -e "${BLUE}================================================================${NC}"

# --- Requirement 1: Check PostgreSQL client utility availability ---
if ! command -v pg_dump &> /dev/null; then
    # Check standard PostgreSQL 18 installation paths on Windows if not in PATH
    PG_DEFAULT_WIN="/c/Program Files/PostgreSQL/18/bin"
    if [ -d "$PG_DEFAULT_WIN" ]; then
        export PATH="$PATH:$PG_DEFAULT_WIN"
    fi
fi

if ! command -v pg_dump &> /dev/null; then
    echo -e "${RED}[ERROR] PostgreSQL utility 'pg_dump' was not found in PATH.${NC}" >&2
    echo -e "${YELLOW}Please ensure PostgreSQL 18 client tools are installed and added to PATH.${NC}" >&2
    exit 1
fi

PG_VERSION="$(pg_dump --version)"
echo -e "${GREEN}[OK] Detected backup tool: ${PG_VERSION}${NC}"

# --- Requirements 2 & 3: Configuration prompting with sensible defaults ---
DEFAULT_DB="grp_parkitdb"
DEFAULT_HOST="localhost"
DEFAULT_PORT="5432"
DEFAULT_USER="postgres"

echo -e "\n${YELLOW}--- Database Connection Configuration ---${NC}"
read -r -p "Enter Database Host [${DEFAULT_HOST}]: " DB_HOST
DB_HOST="${DB_HOST:-$DEFAULT_HOST}"

read -r -p "Enter Database Port [${DEFAULT_PORT}]: " DB_PORT
DB_PORT="${DB_PORT:-$DEFAULT_PORT}"

read -r -p "Enter Database Name [${DEFAULT_DB}]: " DB_NAME
DB_NAME="${DB_NAME:-$DEFAULT_DB}"

read -r -p "Enter Administrative Username [${DEFAULT_USER}]: " DB_USER
DB_USER="${DB_USER:-$DEFAULT_USER}"

# --- Requirement 4 & 5: Secure password prompting (Never hardcoded) ---
if [ -z "${PGPASSWORD:-}" ]; then
    echo -e "${YELLOW}Enter PostgreSQL password for user '${DB_USER}':${NC}"
    read -r -s DB_PASS
    export PGPASSWORD="$DB_PASS"
    echo ""
fi

# --- Requirement 6: Create protected backup directory ---
mkdir -p "$BACKUP_DIR"
# Enforce restricted permissions where supported (POSIX systems)
chmod 700 "$BACKUP_DIR" 2>/dev/null || true

# --- Requirement 7 & 10: Timestamped backup filename generation ---
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
BACKUP_FILENAME="${DB_NAME}_${TIMESTAMP}.dump"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILENAME}"
CHECKSUM_PATH="${BACKUP_PATH}.sha256"

# Also create the canonical activity6 name reference if requested
CANONICAL_LINK="${BACKUP_DIR}/${DB_NAME}_activity6.dump"

# --- Requirement 15: Prevent accidental overwriting of existing backups ---
if [ -f "$BACKUP_PATH" ]; then
    echo -e "${RED}[ERROR] Backup file already exists: ${BACKUP_PATH}${NC}" >&2
    echo -e "${RED}Aborting operation to prevent overwriting existing backup.${NC}" >&2
    exit 1
fi

echo -e "\n${BLUE}--- Commencing Logical Backup ---${NC}"
echo -e "Target Database : ${CYAN}${DB_NAME}${NC}"
echo -e "Host:Port       : ${CYAN}${DB_HOST}:${DB_PORT}${NC}"
echo -e "Database User   : ${CYAN}${DB_USER}${NC}"
echo -e "Output Archive  : ${CYAN}${BACKUP_PATH}${NC}"
echo -e "Archive Format  : ${CYAN}PostgreSQL Custom Format (-Fc, compressed)${NC}"

START_TIME="$(date +'%Y-%m-%d %H:%M:%S')"
echo -e "Execution Start : ${START_TIME}"

# --- Requirement 7, 8, 14: Execute pg_dump and capture exit status & logs ---
DUMP_OUTPUT=""
set +e
pg_dump \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    -Fc \
    -b \
    -v \
    -d "$DB_NAME" \
    -f "$BACKUP_PATH" 2> "${BACKUP_PATH}.err.tmp"
DUMP_EXIT_CODE=$?
set -e

END_TIME="$(date +'%Y-%m-%d %H:%M:%S')"

if [ $DUMP_EXIT_CODE -ne 0 ]; then
    echo -e "\n${RED}[ERROR] pg_dump failed with exit code ${DUMP_EXIT_CODE}.${NC}" >&2
    if [ -f "${BACKUP_PATH}.err.tmp" ]; then
        cat "${BACKUP_PATH}.err.tmp" >&2
    fi
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] FAILED: Backup of ${DB_NAME} failed with exit code ${DUMP_EXIT_CODE}" >> "$LOG_FILE"
    rm -f "${BACKUP_PATH}.err.tmp" "$BACKUP_PATH"
    exit $DUMP_EXIT_CODE
fi

# Clean up temp error log
rm -f "${BACKUP_PATH}.err.tmp"

# --- Requirement 9: Verify backup file exists and is not empty ---
if [ ! -s "$BACKUP_PATH" ]; then
    echo -e "${RED}[ERROR] Backup file was created but is empty (0 bytes).${NC}" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] FAILED: Backup file ${BACKUP_FILENAME} is empty" >> "$LOG_FILE"
    exit 1
fi

# --- Requirement 11 & 12: Record file size (bytes & human-readable) ---
FILE_SIZE_BYTES="$(wc -c < "$BACKUP_PATH" | tr -d ' ')"
if command -v numfmt &> /dev/null; then
    FILE_SIZE_HUMAN="$(numfmt --to=iec-i --suffix=B "$FILE_SIZE_BYTES")"
else
    FILE_SIZE_HUMAN="${FILE_SIZE_BYTES} bytes"
fi

# --- Requirement 13: Generate SHA-256 Checksum ---
if command -v sha256sum &> /dev/null; then
    SHA256_HASH="$(sha256sum "$BACKUP_PATH" | awk '{print $1}')"
elif command -v shasum &> /dev/null; then
    SHA256_HASH="$(shasum -a 256 "$BACKUP_PATH" | awk '{print $1}')"
else
    # Fallback to PowerShell if on Windows
    SHA256_HASH="$(powershell.exe -NoProfile -Command "(Get-FileHash -Path '$BACKUP_PATH' -Algorithm SHA256).Hash.ToLower()" | tr -d '\r\n')"
fi

echo "$SHA256_HASH  $BACKUP_FILENAME" > "$CHECKSUM_PATH"

# Create/update canonical copy for Activity 6 standard submission
cp -f "$BACKUP_PATH" "$CANONICAL_LINK" 2>/dev/null || true
if [ -f "$CANONICAL_LINK" ]; then
    echo "$SHA256_HASH  ${DB_NAME}_activity6.dump" > "${CANONICAL_LINK}.sha256"
fi

# Set restrictive permissions on the dump file
chmod 600 "$BACKUP_PATH" 2>/dev/null || true

# --- Requirement 10, 14: Log execution results ---
cat >> "$LOG_FILE" <<EOF
[${END_TIME}] SUCCESS: Backup completed successfully.
  Database       : ${DB_NAME}
  Host:Port      : ${DB_HOST}:${DB_PORT}
  Filename       : ${BACKUP_FILENAME}
  File Size      : ${FILE_SIZE_BYTES} bytes (${FILE_SIZE_HUMAN})
  SHA-256 Hash   : ${SHA256_HASH}
  Exit Code      : 0
  Start Time     : ${START_TIME}
  End Time       : ${END_TIME}
--------------------------------------------------------------------------------
EOF

# --- Display Execution Summary ---
echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}  BACKUP COMPLETED SUCCESSFULLY!                                ${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e "Database Name    : ${CYAN}${DB_NAME}${NC}"
echo -e "Backup File      : ${CYAN}${BACKUP_PATH}${NC}"
echo -e "Canonical File   : ${CYAN}${CANONICAL_LINK}${NC}"
echo -e "File Size        : ${CYAN}${FILE_SIZE_BYTES} bytes (${FILE_SIZE_HUMAN})${NC}"
echo -e "SHA-256 Checksum : ${CYAN}${SHA256_HASH}${NC}"
echo -e "Checksum File    : ${CYAN}${CHECKSUM_PATH}${NC}"
echo -e "Execution Log    : ${CYAN}${LOG_FILE}${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e "${YELLOW}Next Step: Run ./03-inspect-backup.sh to inspect the archive TOC.${NC}\n"

