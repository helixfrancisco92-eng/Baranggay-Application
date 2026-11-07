SELECT
    rolname,
    rolsuper,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin
FROM pg_roles
WHERE rolname IN (
    'lf_admin',
    'lf_staff',
    'lf_viewer',
    'lf_admin_user',
    'lf_staff_user',
    'lf_viewer_user'
);