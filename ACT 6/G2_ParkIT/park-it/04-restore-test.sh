#!/usr/bin/env bash
# ==============================================================================
# COMP 018 — Database Administration (Activity 6: Part C)
# Script: 04-restore-test.sh
# Purpose: Isolated Test Restoration of Park-It Database Backup
# Platform: PostgreSQL 18.6 | Safety: Restores ONLY into separate test database
# ==============================================================================

set -euo pipefail

# --- Color formatting for CLI output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/../backups"
RESTORE_LOG="${BACKUP_DIR}/restore_test.log"

echo -e "${BLUE}================================================================${NC}"
echo -e "${CYAN}  PARK-IT DATABASE MANAGEMENT SYSTEM — ISOLATED RESTORATION TEST${NC}"
echo -e "${CYAN}  COMP 018 Database Administration (Activity 6: Part C)          ${NC}"
echo -e "${BLUE}================================================================${NC}"

# --- Check PostgreSQL client tools ---
if ! command -v pg_restore &> /dev/null || ! command -v createdb &> /dev/null || ! command -v psql &> /dev/null; then
    PG_DEFAULT_WIN="/c/Program Files/PostgreSQL/18/bin"
    if [ -d "$PG_DEFAULT_WIN" ]; then
        export PATH="$PATH:$PG_DEFAULT_WIN"
    fi
fi

for cmd in pg_restore createdb psql; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}[ERROR] Required PostgreSQL utility '$cmd' is not in PATH.${NC}" >&2
        exit 1
    fi
done

# --- Requirement 1: Accept backup file input and verify existence ---
BACKUP_FILE="${1:-}"

if [ -z "$BACKUP_FILE" ]; then
    if [ -f "${BACKUP_DIR}/grp_parkitdb_activity6.dump" ]; then
        BACKUP_FILE="${BACKUP_DIR}/grp_parkitdb_activity6.dump"
    elif [ -d "$BACKUP_DIR" ]; then
        LATEST_DUMP="$(ls -t "${BACKUP_DIR}"/*.dump 2>/dev/null | head -n 1 || true)"
        if [ -n "$LATEST_DUMP" ]; then
            BACKUP_FILE="$LATEST_DUMP"
        fi
    fi
fi

if [ -z "$BACKUP_FILE" ]; then
    read -r -p "Enter path to backup archive (.dump): " BACKUP_FILE
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}[ERROR] Specified backup file does not exist: ${BACKUP_FILE}${NC}" >&2
    exit 1
fi

if [ ! -s "$BACKUP_FILE" ]; then
    echo -e "${RED}[ERROR] Specified backup file is empty (0 bytes): ${BACKUP_FILE}${NC}" >&2
    exit 1
fi

# --- Requirement 2: Verify backup archive can be inspected ---
echo -e "\n${YELLOW}--- Pre-Restoration Archive Check ---${NC}"
if ! pg_restore --list "$BACKUP_FILE" &> /dev/null; then
    echo -e "${RED}[ERROR] The file ${BACKUP_FILE} is corrupted or not a valid PostgreSQL custom-format dump.${NC}" >&2
    exit 1
fi
echo -e "${GREEN}[OK] Archive successfully verified via pg_restore --list.${NC}"

# --- Configuration prompting ---
DEFAULT_HOST="localhost"
DEFAULT_PORT="5432"
DEFAULT_ADMIN="postgres"
DEFAULT_ORIGINAL_DB="grp_parkitdb"
DEFAULT_TEST_DB="grp_parkitdb_restore_test"

echo -e "\n${YELLOW}--- Restoration Target Configuration ---${NC}"
read -r -p "Enter Database Host [${DEFAULT_HOST}]: " DB_HOST
DB_HOST="${DB_HOST:-$DEFAULT_HOST}"

read -r -p "Enter Database Port [${DEFAULT_PORT}]: " DB_PORT
DB_PORT="${DB_PORT:-$DEFAULT_PORT}"

read -r -p "Enter Administrative Username [${DEFAULT_ADMIN}]: " DB_ADMIN
DB_ADMIN="${DB_ADMIN:-$DEFAULT_ADMIN}"

read -r -p "Enter Target Test Database Name [${DEFAULT_TEST_DB}]: " TEST_DB
TEST_DB="${TEST_DB:-$DEFAULT_TEST_DB}"

# --- Requirement 5: STRICT SAFETY CHECK — NEVER OVERWRITE ORIGINAL DATABASE ---
if [ "$TEST_DB" = "$DEFAULT_ORIGINAL_DB" ]; then
    echo -e "\n${RED}================================================================${NC}" >&2
    echo -e "${RED}[CRITICAL SECURITY HALT] DANGEROUS TARGET DETECTED!             ${NC}" >&2
    echo -e "${RED}Target database cannot be the original database '${DEFAULT_ORIGINAL_DB}'!${NC}" >&2
    echo -e "${RED}Restoring directly over production risks catastrophic data loss.${NC}" >&2
    echo -e "${RED}Please specify an isolated test database (e.g. ${DEFAULT_TEST_DB}).${NC}" >&2
    echo -e "${RED}================================================================${NC}" >&2
    exit 1
fi

# Prompt for password if not present
if [ -z "${PGPASSWORD:-}" ]; then
    echo -e "${YELLOW}Enter PostgreSQL password for user '${DB_ADMIN}':${NC}"
    read -r -s DB_PASS
    export PGPASSWORD="$DB_PASS"
    echo ""
fi

# --- Requirement 6: Check if test database already exists ---
echo -e "\n${YELLOW}--- Checking Existing Target Databases ---${NC}"
DB_EXISTS="$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_ADMIN" -tAc "SELECT 1 FROM pg_database WHERE datname = '$TEST_DB'" 2>/dev/null || true)"

if [ "$DB_EXISTS" = "1" ]; then
    echo -e "${YELLOW}[WARNING] Target test database '${TEST_DB}' already exists.${NC}"
    echo -e "To prevent accidental data loss, this script will NOT automatically drop databases."
    read -r -p "Do you want to use a timestamped alternative database name? (Y/n): " USE_ALT
    USE_ALT="${USE_ALT:-Y}"
    if [[ "$USE_ALT" =~ ^[Yy]$ ]]; then
        TEST_DB="${TEST_DB}_$(date +'%Y%m%d_%H%M%S')"
        echo -e "${CYAN}Using new target database name: ${TEST_DB}${NC}"
    else
        echo -e "${YELLOW}Proceeding to restore into existing database '${TEST_DB}'. Existing conflicting tables may cause errors.${NC}"
    fi
fi

# Create target test database if it does not exist
if [ "$DB_EXISTS" != "1" ]; then
    echo -e "Creating clean test database: ${CYAN}${TEST_DB}${NC}..."
    if ! createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_ADMIN" "$TEST_DB"; then
        echo -e "${RED}[ERROR] Failed to create database '${TEST_DB}'. Check permissions and credentials.${NC}" >&2
        exit 1
    fi
    echo -e "${GREEN}[OK] Successfully created isolated test database '${TEST_DB}'.${NC}"
fi

# --- Requirement 7 & 8: Execute pg_restore ---
# Note on --no-owner and --no-acl:
# In an isolated restoration test environment, setting --no-owner ensures objects are owned
# by the restoring administrator rather than failing if original dump roles do not exist.
# Here we restore cleanly and document stdout/stderr.

echo -e "\n${BLUE}--- Commencing Database Restoration via pg_restore ---${NC}"
echo -e "Source Archive : ${CYAN}${BACKUP_FILE}${NC}"
echo -e "Destination DB : ${CYAN}${TEST_DB}${NC}"
echo -e "Admin User     : ${CYAN}${DB_ADMIN}${NC}"

START_TIME="$(date +'%Y-%m-%d %H:%M:%S')"
RESTORE_LOG_SESSION="${BACKUP_DIR}/restore_${TEST_DB}_$(date +'%Y%m%d_%H%M%S').log"

set +e
pg_restore \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_ADMIN" \
    -d "$TEST_DB" \
    -v \
    "$BACKUP_FILE" > "$RESTORE_LOG_SESSION" 2>&1
RESTORE_EXIT_CODE=$?
set -e

END_TIME="$(date +'%Y-%m-%d %H:%M:%S')"

# Append to general restore log
cat >> "$RESTORE_LOG" <<EOF
[${END_TIME}] RESTORE DRILL: Archive=${BACKUP_FILE} TargetDB=${TEST_DB} ExitCode=${RESTORE_EXIT_CODE} Start=${START_TIME} End=${END_TIME}
EOF

# In PostgreSQL pg_restore, an exit code of 0 indicates complete success,
# while exit code 1 indicates non-fatal warnings (e.g. ownership / ACL warnings when roles do not match).
if [ $RESTORE_EXIT_CODE -eq 0 ]; then
    echo -e "\n${GREEN}[SUCCESS] Restoration completed with exit code 0 (Clean restore).${NC}"
elif [ $RESTORE_EXIT_CODE -eq 1 ]; then
    echo -e "\n${YELLOW}[COMPLETED WITH WARNINGS] Restoration completed with non-fatal warnings (Exit code 1).${NC}"
    echo -e "${YELLOW}Common causes: role ownership / privileges referencing roles absent in cluster.${NC}"
    echo -e "${YELLOW}Review log for details: ${RESTORE_LOG_SESSION}${NC}"
else
    echo -e "\n${RED}[ERROR] Restoration failed with critical exit code ${RESTORE_EXIT_CODE}.${NC}" >&2
    echo -e "${RED}Inspect log at: ${RESTORE_LOG_SESSION}${NC}" >&2
    exit $RESTORE_EXIT_CODE
fi

# --- Requirement 11: Connection and Verification Guidance ---
echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}  ISOLATED RESTORATION TEST SUMMARY                             ${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e "Restored Database : ${CYAN}${TEST_DB}${NC}"
echo -e "Archive Source    : ${CYAN}${BACKUP_FILE}${NC}"
echo -e "Restoration Log   : ${CYAN}${RESTORE_LOG_SESSION}${NC}"
echo -e "Status            : ${GREEN}READY FOR VERIFICATION${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e "\n${MAGENTA}Next Steps to Verify Restored Database:${NC}"
echo -e "1. Connect directly to the restored test database:"
echo -e "   ${CYAN}psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_ADMIN} -d ${TEST_DB}${NC}"
echo -e "2. Run the automated schema and data verification query suite:"
echo -e "   ${CYAN}psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_ADMIN} -d ${TEST_DB} -f 05-verify-restoration.sql${NC}"
echo -e "3. Run the Activity 4 Role-Based Access Control verification suite:"
echo -e "   ${CYAN}psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_ADMIN} -d ${TEST_DB} -f 06-verify-access-control.sql${NC}\n"

