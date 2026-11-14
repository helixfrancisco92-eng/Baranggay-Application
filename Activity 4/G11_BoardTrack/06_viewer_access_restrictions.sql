-- =========================================
-- TEST 2: VIEWER ACCESS RESTRICTIONS
-- =========================================

SELECT
    'boardtrack_viewer' AS username,
    has_table_privilege(
        'boardtrack_viewer',
        format('%I.%I', table_schema, table_name),
        'SELECT'
    ) AS can_select,
    has_table_privilege(
        'boardtrack_viewer',
        format('%I.%I', table_schema, table_name),
        'INSERT'
    ) AS can_insert,
    has_table_privilege(
        'boardtrack_viewer',
        format('%I.%I', table_schema, table_name),
        'UPDATE'
    ) AS can_update,
    has_table_privilege(
        'boardtrack_viewer',
        format('%I.%I', table_schema, table_name),
        'DELETE'
    ) AS can_delete
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';