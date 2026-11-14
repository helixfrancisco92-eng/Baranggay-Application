#!/usr/bin/env bash
# ==============================================================================
# COMP 018 - Database Administration | Activity 6
# Script: inspect-backup.sh
# Purpose: Non-destructive Archive Table-of-Contents (TOC) & Checksum Verification
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOGS_DIR="${WORKSPACE_ROOT}/logs"
BACKUP_DIR="${WORKSPACE_ROOT}/backups"

mkdir -p "${LOGS_DIR}"

echo "=============================================================================="
echo " COMP 018 Activity 6 - PostgreSQL Archive Inspection (Bash)"
echo " Project: Restaurant Online Ordering & Table Reservation System (Binary Sisters)"
echo "=============================================================================="

# Check for pg_restore
if ! command -v pg_restore &> /dev/null; then
    echo "ERROR: pg_restore utility not found on PATH." >&2
    exit 1
fi

# Identify target backup archive
BACKUP_FILE="${1:-}"
if [ -z "${BACKUP_FILE}" ]; then
    BACKUP_FILE=$(find "${BACKUP_DIR}" -name "*.dump" -type f | sort -r | head -n 1)
fi

if [ -z "${BACKUP_FILE}" ] || [ ! -f "${BACKUP_FILE}" ]; then
    echo "ERROR: No valid .dump archive file found in '${BACKUP_DIR}'." >&2
    exit 1
fi

FILENAME=$(basename "${BACKUP_FILE}")
CHECKSUM_FILE="${BACKUP_FILE}.sha256"
TOC_LOG="${LOGS_DIR}/archive-toc.txt"

echo "Inspecting Archive : ${FILENAME}"
echo "Full Path          : ${BACKUP_FILE}"

# Verify Checksum
if [ -f "${CHECKSUM_FILE}" ]; then
    echo "[1/3] Verifying SHA-256 Checksum..."
    if command -v sha256sum &> /dev/null; then
        CALCULATED_HASH=$(sha256sum "${BACKUP_FILE}" | awk '{print $1}')
    else
        CALCULATED_HASH=$(shasum -a 256 "${BACKUP_FILE}" | awk '{print $1}')
    fi
    RECORDED_HASH=$(awk '{print $1}' "${CHECKSUM_FILE}")

    if [ "${CALCULATED_HASH}" = "${RECORDED_HASH}" ]; then
        echo " -> CHECKSUM VERIFIED MATCH: ${CALCULATED_HASH}"
    else
        echo " -> ERROR: CHECKSUM MISMATCH!"
        echo "    Recorded   : ${RECORDED_HASH}"
        echo "    Calculated : ${CALCULATED_HASH}"
        exit 1
    fi
else
    echo "[1/3] Checksum file not found; skipping hash match."
fi

# Extract Table of Contents via pg_restore --list
echo "[2/3] Extracting Archive Table of Contents via pg_restore --list..."
pg_restore --list "${BACKUP_FILE}" > "${TOC_LOG}"
echo " -> TOC saved to: ${TOC_LOG}"

# Verify Core Expected Tables
echo "[3/3] Auditing Expected Relational Objects in Archive TOC..."
TABLES=("customer" "menu_item" "restaurant_table" "staff" "orders" "order_item" "reservation" "payment")
MISSING=0

for tbl in "${TABLES[@]}"; do
    if grep -q "TABLE public ${tbl} " "${TOC_LOG}"; then
        echo " [OK] Table public.${tbl} is present in archive."
    else
        echo " [FAIL] Table public.${tbl} is MISSING from archive!"
        MISSING=$((MISSING + 1))
    fi
done

# Audit Views
VIEWS=("v_customer_directory" "v_staff_directory" "v_order_summary" "v_reservation_schedule")
for vw in "${VIEWS[@]}"; do
    if grep -q "VIEW public ${vw} " "${TOC_LOG}"; then
        echo " [OK] View public.${vw} is present in archive."
    fi
done

# Audit Triggers
TRIGGERS=("trg_order_item_total" "trg_orders_require_items" "trg_order_item_keep_one" "trg_reservation_capacity")
for trg in "${TRIGGERS[@]}"; do
    if grep -q "TRIGGER public ${trg} " "${TOC_LOG}"; then
        echo " [OK] Trigger public.${trg} is present in archive."
    fi
done

echo "=============================================================================="
if [ ${MISSING} -eq 0 ]; then
    echo " INSPECTION RESULT: SUCCESS - All relational objects confirmed."
else
    echo " INSPECTION RESULT: FAILED - ${MISSING} table(s) missing from TOC."
    exit 1
fi
echo "=============================================================================="

