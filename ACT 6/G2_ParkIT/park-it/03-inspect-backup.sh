#!/usr/bin/env bash
# ==============================================================================
# COMP 018 — Database Administration (Activity 6: Part B)
# Script: 03-inspect-backup.sh
# Purpose: Inspect PostgreSQL Custom-Format Archive TOC and Validate Checksum
# Platform: PostgreSQL 18.6 | Target DB: grp_parkitdb
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

echo -e "${BLUE}================================================================${NC}"
echo -e "${CYAN}  PARK-IT DATABASE MANAGEMENT SYSTEM — ARCHIVE INSPECTION TOOL  ${NC}"
echo -e "${CYAN}  COMP 018 Database Administration (Activity 6: Part B)          ${NC}"
echo -e "${BLUE}================================================================${NC}"

# --- Requirement 1: Check PostgreSQL client utility availability ---
if ! command -v pg_restore &> /dev/null; then
    PG_DEFAULT_WIN="/c/Program Files/PostgreSQL/18/bin"
    if [ -d "$PG_DEFAULT_WIN" ]; then
        export PATH="$PATH:$PG_DEFAULT_WIN"
    fi
fi

if ! command -v pg_restore &> /dev/null; then
    echo -e "${RED}[ERROR] PostgreSQL utility 'pg_restore' was not found in PATH.${NC}" >&2
    exit 1
fi

# --- Requirement 2: Locate target backup file ---
TARGET_FILE="${1:-}"

if [ -z "$TARGET_FILE" ]; then
    # Look for canonical dump first, or latest dump in backup directory
    if [ -f "${BACKUP_DIR}/grp_parkitdb_activity6.dump" ]; then
        TARGET_FILE="${BACKUP_DIR}/grp_parkitdb_activity6.dump"
    elif [ -d "$BACKUP_DIR" ]; then
        LATEST_DUMP="$(ls -t "${BACKUP_DIR}"/*.dump 2>/dev/null | head -n 1 || true)"
        if [ -n "$LATEST_DUMP" ]; then
            TARGET_FILE="$LATEST_DUMP"
        fi
    fi
fi

if [ -z "$TARGET_FILE" ]; then
    read -r -p "Enter path to backup archive (.dump): " TARGET_FILE
fi

if [ ! -f "$TARGET_FILE" ]; then
    echo -e "${RED}[ERROR] Specified backup file does not exist: ${TARGET_FILE}${NC}" >&2
    exit 1
fi

if [ ! -s "$TARGET_FILE" ]; then
    echo -e "${RED}[ERROR] Backup file is empty (0 bytes): ${TARGET_FILE}${NC}" >&2
    exit 1
fi

FILE_BASENAME="$(basename "$TARGET_FILE")"
TOC_OUTPUT="${TARGET_FILE%.dump}_toc.txt"
CHECKSUM_FILE="${TARGET_FILE}.sha256"

echo -e "\n${BLUE}--- Inspecting Backup Archive ---${NC}"
echo -e "Archive Target   : ${CYAN}${TARGET_FILE}${NC}"
echo -e "File Size        : ${CYAN}$(wc -c < "$TARGET_FILE" | tr -d ' ') bytes${NC}"
echo -e "Evidence TOC Log : ${CYAN}${TOC_OUTPUT}${NC}"

# --- Requirement 7: Verify SHA-256 Checksum ---
echo -e "\n${YELLOW}--- Cryptographic Checksum Validation ---${NC}"
if command -v sha256sum &> /dev/null; then
    CURRENT_HASH="$(sha256sum "$TARGET_FILE" | awk '{print $1}')"
elif command -v shasum &> /dev/null; then
    CURRENT_HASH="$(shasum -a 256 "$TARGET_FILE" | awk '{print $1}')"
else
    CURRENT_HASH="$(powershell.exe -NoProfile -Command "(Get-FileHash -Path '$TARGET_FILE' -Algorithm SHA256).Hash.ToLower()" | tr -d '\r\n')"
fi

echo -e "Computed SHA-256 : ${CYAN}${CURRENT_HASH}${NC}"

if [ -f "$CHECKSUM_FILE" ]; then
    EXPECTED_HASH="$(awk '{print $1}' "$CHECKSUM_FILE")"
    echo -e "Recorded SHA-256 : ${CYAN}${EXPECTED_HASH}${NC}"
    if [ "$CURRENT_HASH" = "$EXPECTED_HASH" ]; then
        echo -e "${GREEN}[PASSED] Checksum integrity verified! File has not been modified or corrupted.${NC}"
    else
        echo -e "${RED}[FAILED] CHECKSUM MISMATCH! File may be corrupt or altered!${NC}" >&2
        exit 1
    fi
else
    echo -e "${YELLOW}[NOTICE] Checksum file '${CHECKSUM_FILE}' not found; created verification hash record.${NC}"
    echo "$CURRENT_HASH  $FILE_BASENAME" > "$CHECKSUM_FILE"
fi

# --- Requirement 3 & 4: Extract Table of Contents (TOC) using pg_restore --list ---
echo -e "\n${YELLOW}--- Extracting Archive Table of Contents (pg_restore --list) ---${NC}"
set +e
pg_restore --list "$TARGET_FILE" > "$TOC_OUTPUT" 2> "${TARGET_FILE}.inspect_err.tmp"
RESTORE_LIST_EXIT=$?
set -e

if [ $RESTORE_LIST_EXIT -ne 0 ]; then
    echo -e "${RED}[ERROR] Failed to read archive TOC using pg_restore (Exit code: ${RESTORE_LIST_EXIT}).${NC}" >&2
    if [ -f "${TARGET_FILE}.inspect_err.tmp" ]; then
        cat "${TARGET_FILE}.inspect_err.tmp" >&2
    fi
    rm -f "${TARGET_FILE}.inspect_err.tmp"
    exit $RESTORE_LIST_EXIT
fi
rm -f "${TARGET_FILE}.inspect_err.tmp"

echo -e "${GREEN}[OK] TOC listing successfully exported to: ${TOC_OUTPUT}${NC}"

# --- Requirement 6: Explain and summarize database objects found in TOC ---
echo -e "\n${BLUE}================================================================${NC}"
echo -e "${CYAN}  PARK-IT DATABASE ARCHIVE OBJECT BREAKDOWN                     ${NC}"
echo -e "${BLUE}================================================================${NC}"

echo -e "${MAGENTA}1. Table Definitions (TABLE):${NC}"
grep -E ";[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+TABLE[[:space:]]" "$TOC_OUTPUT" || echo "   None found or format difference"

echo -e "\n${MAGENTA}2. Sequences (SEQUENCE & SEQUENCE OWNED BY):${NC}"
grep -E ";[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+SEQUENCE" "$TOC_OUTPUT" || echo "   None found"

echo -e "\n${MAGENTA}3. Table Constraints (PRIMARY KEY, UNIQUE, CHECK, FOREIGN KEY):${NC}"
grep -E ";[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+CONSTRAINT[[:space:]]|;[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+FK CONSTRAINT[[:space:]]|;[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+CHECK CONSTRAINT[[:space:]]" "$TOC_OUTPUT" || echo "   None found"

echo -e "\n${MAGENTA}4. Table Data Blocks (TABLE DATA):${NC}"
grep -E ";[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+TABLE DATA[[:space:]]" "$TOC_OUTPUT" || echo "   None found"

# Check for critical Park-It tables specifically
echo -e "\n${YELLOW}--- Verifying Essential Park-It Entities in Archive ---${NC}"
CRITICAL_TABLES=("parking_zone" "vehicle" "staff_user" "transaction" "payment")
ALL_FOUND=true

for tbl in "${CRITICAL_TABLES[@]}"; do
    if grep -q "TABLE public $tbl " "$TOC_OUTPUT" || grep -q "TABLE DATA public $tbl " "$TOC_OUTPUT"; then
        echo -e "  [+] Entity '${tbl}' : ${GREEN}FOUND IN ARCHIVE${NC}"
    else
        echo -e "  [-] Entity '${tbl}' : ${RED}MISSING FROM ARCHIVE${NC}"
        ALL_FOUND=false
    fi
done

if [ "$ALL_FOUND" = true ]; then
    echo -e "\n${GREEN}[PASSED] All 5 core Park-It database entities are present in the backup archive.${NC}"
else
    echo -e "\n${RED}[WARNING] One or more core database tables are missing from the archive!${NC}" >&2
fi

# --- Requirement 8: Educational / Architectural Note ---
cat << 'EOF'

================================================================================
CRITICAL DATABASE ADMINISTRATION INSIGHT:
WHY BACKUP EXISTENCE DOES NOT EQUAL RESTORABILITY
================================================================================
A common operational fallacy is assuming that because a .dump file exists and
passes checksum inspection, the database is guaranteed to be recoverable. 

In enterprise database administration, a backup is NOT verified until a full
restoration drill has succeeded in an isolated environment. The reasons include:
  1. Role & Permission Dependencies: The dump may reference users, roles, or
     tablespaces that do not exist in the target PostgreSQL instance.
  2. Unresolvable Foreign Key Cycles: If restore ordering fails or constraints
     are violated by orphan rows, restoration can abort mid-process.
  3. Server Version / Extension Incompatibilities: Dumps from higher PostgreSQL
     versions may fail to restore on earlier engines or missing modules.
  4. Logical vs. Data Consistency: A corrupted table index or uncommitted block
     written to dump can trigger silent syntax or catalog errors during execution.

CONCLUSION: Proceed immediately to Part C: Isolated Restoration Test (04-restore-test.sh).
================================================================================
EOF

