-- =============================================================================
-- CampusSafe (Group 7) — Constraint & Integrity Verification Script (07_verify_constraints.sql)
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp07_campussafedb_activity6_restore_test
-- =============================================================================

\echo '================================================================='
\echo ' CampusSafe Constraint & Referential Integrity Audit (Phase 6 - C)'
\echo ' Target: grp07_campussafedb_activity6_restore_test               '
\echo '================================================================='

-- Safety Check
SELECT current_database() AS connected_database;

\echo '--- 1. PRIMARY KEY CONSTRAINTS AUDIT (Expected: 9 PKs) ---'
SELECT 
    tc.table_name,
    tc.constraint_name,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name;

SELECT 
    COUNT(*) AS total_primary_keys,
    CASE WHEN COUNT(*) = 9 THEN 'PASS (9/9 Primary Keys Enforced)' ELSE 'FAIL' END AS evaluation
FROM information_schema.table_constraints
WHERE constraint_type = 'PRIMARY KEY' AND table_schema = 'public';

\echo '--- 2. FOREIGN KEY REFERENTIAL INTEGRITY CONSTRAINTS AUDIT ---'
SELECT 
    tc.table_name AS child_table,
    kcu.column_name AS child_column,
    ccu.table_name AS parent_table,
    ccu.column_name AS parent_column,
    rc.delete_rule,
    rc.update_rule
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.referential_constraints rc 
    ON tc.constraint_name = rc.constraint_name
JOIN information_schema.constraint_column_usage ccu 
    ON rc.unique_constraint_name = ccu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

\echo '--- 3. UNIQUE CONSTRAINTS AUDIT ---'
SELECT 
    tc.table_name,
    tc.constraint_name,
    string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) AS unique_columns
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'UNIQUE'
  AND tc.table_schema = 'public'
GROUP BY tc.table_name, tc.constraint_name
ORDER BY tc.table_name;

\echo '--- 4. DOMAIN CHECK CONSTRAINTS AUDIT ---'
SELECT 
    tc.table_name,
    tc.constraint_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc 
    ON tc.constraint_name = cc.constraint_name
WHERE tc.constraint_type = 'CHECK'
  AND tc.table_schema = 'public'
  AND tc.constraint_name NOT LIKE '%_not_null%'
ORDER BY tc.table_name, tc.constraint_name;

\echo '--- 5. LIVE CONSTRAINT VALIDATION QUERIES (ZERO VIOLATIONS EXPECTED) ---'

-- Check A: Verification Pair Rule (chk_verified_pair)
SELECT 
    COUNT(*) AS chk_verified_pair_violations,
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Zero Violations)' ELSE 'FAIL (Illegal State Detected)' END AS status
FROM hazard_report
WHERE (verified_by_user_id IS NULL AND verified_at IS NOT NULL)
   OR (verified_by_user_id IS NOT NULL AND verified_at IS NULL);

-- Check B: Resolution Date Obligation (chk_resolved_has_date)
SELECT 
    COUNT(*) AS chk_resolved_has_date_violations,
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Zero Violations)' ELSE 'FAIL (Un-timestamped Resolution)' END AS status
FROM hazard_report
WHERE status IN ('Resolved', 'Closed') AND resolved_at IS NULL;

-- Check C: Unverified Report Priority Check
SELECT 
    COUNT(*) AS unverified_with_priority_violations,
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Zero Violations)' ELSE 'FAIL' END AS status
FROM hazard_report
WHERE status = 'Submitted' AND priority IS NOT NULL;

-- Check D: Referential Integrity Orphan Audits
SELECT 
    (SELECT COUNT(*) FROM assignment a LEFT JOIN hazard_report r ON a.report_id = r.report_id WHERE r.report_id IS NULL) AS orphan_assignments,
    (SELECT COUNT(*) FROM report_status_history h LEFT JOIN hazard_report r ON h.report_id = r.report_id WHERE r.report_id IS NULL) AS orphan_histories,
    (SELECT COUNT(*) FROM maintenance_action m LEFT JOIN hazard_report r ON m.report_id = r.report_id WHERE r.report_id IS NULL) AS orphan_actions,
    (SELECT COUNT(*) FROM attachment att LEFT JOIN hazard_report r ON att.report_id = r.report_id WHERE r.report_id IS NULL) AS orphan_attachments;

