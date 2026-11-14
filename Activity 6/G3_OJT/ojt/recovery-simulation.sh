#!/usr/bin/env bash
# ==============================================================================
# COMP 018 – Activity 6: Controlled Recovery Simulation Script
# Target Project: Project OJT RMA System (OJT Management System)
# DBMS: PostgreSQL 18.x
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../configuration/.env"

DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_NAME="ojt_management"
TEST_DB="ojt_management_restore_test"
RECOVERY_DB="ojt_management_recovery_test"

if [[ -f "${CONFIG_FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${CONFIG_FILE}" 2>/dev/null || true
fi

if [[ "${TEST_DB,,}" == "${DB_NAME,,}" || "${RECOVERY_DB,,}" == "${DB_NAME,,}" ]]; then
    echo "[FATAL] Safety guard triggered: Refusing to run simulation against primary database." >&2
    exit 1
fi

SIM_DIR="${SCRIPT_DIR}/../backups/simulation"
mkdir -p "${SIM_DIR}"
SIM_DUMP="${SIM_DIR}/sim_baseline.dump"

echo "====================================================================="
echo " STEP 1: Seeding disposable data into ${TEST_DB}"
echo "====================================================================="
psql -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d "${TEST_DB}" -f "${SCRIPT_DIR}/../sql/recovery-test-data.sql"

echo "====================================================================="
echo " STEP 2: Creating baseline simulation backup"
echo "====================================================================="
pg_dump -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -Fc -d "${TEST_DB}" -f "${SIM_DUMP}"

echo "====================================================================="
echo " STEP 3: Simulating accidental data loss in ${TEST_DB}"
echo "====================================================================="
psql -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d "${TEST_DB}" -c "DELETE FROM requirements WHERE title='DISPOSABLE_SIMULATION_CLEARANCE_DOC';"

echo "====================================================================="
echo " STEP 4: Restoring from baseline into fresh recovery DB: ${RECOVERY_DB}"
echo "====================================================================="
dropdb -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" --if-exists "${RECOVERY_DB}" || true
createdb -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -E UTF8 "${RECOVERY_DB}"
pg_restore -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d "${RECOVERY_DB}" "${SIM_DUMP}" || true

echo "====================================================================="
echo " STEP 5: Verifying recovered state"
echo "====================================================================="
psql -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -d "${RECOVERY_DB}" -c "SELECT req_id, title, is_mandatory FROM requirements WHERE title='DISPOSABLE_SIMULATION_CLEARANCE_DOC';"

