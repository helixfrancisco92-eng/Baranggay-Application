
-- 01_create_roles.sql

-- GROUP ROLES
CREATE ROLE restaurant_admin NOLOGIN;
CREATE ROLE restaurant_manager NOLOGIN;
CREATE ROLE restaurant_staff NOLOGIN;
CREATE ROLE restaurant_customer NOLOGIN;
CREATE ROLE restaurant_readonly NOLOGIN;

-- LOGIN USERS
CREATE ROLE admin_user
LOGIN PASSWORD 'ChangeAdmin123';

CREATE ROLE manager_user
LOGIN PASSWORD 'ChangeManager123';

CREATE ROLE staff_user
LOGIN PASSWORD 'ChangeStaff123';

CREATE ROLE customer_user
LOGIN PASSWORD 'ChangeCustomer123';

CREATE ROLE viewer_user
LOGIN PASSWORD 'ChangeViewer123';

-- ASSIGN USERS TO GROUP ROLES
GRANT restaurant_admin TO admin_user;
GRANT restaurant_manager TO manager_user;
GRANT restaurant_staff TO staff_user;
GRANT restaurant_customer TO customer_user;
GRANT restaurant_readonly TO viewer_user;

-- VERIFY ROLE CREATION
SELECT
    rolname,
    rolsuper,
    rolcanlogin
FROM pg_roles
WHERE rolname LIKE 'restaurant_%'
   OR rolname IN (
       'admin_user',
       'manager_user',
       'staff_user',
       'customer_user',
       'viewer_user'
   )
ORDER BY rolname;
