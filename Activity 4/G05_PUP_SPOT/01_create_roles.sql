-- Create group roles

CREATE ROLE lf_admin NOLOGIN;
CREATE ROLE lf_staff NOLOGIN;
CREATE ROLE lf_viewer NOLOGIN;

-- Create database login accounts

CREATE USER lf_admin_user
WITH PASSWORD 'AdminPassword123';

CREATE USER lf_staff_user
WITH PASSWORD 'StaffPassword123';

CREATE USER lf_viewer_user
WITH PASSWORD 'ViewerPassword123';

-- Assign group roles to users

GRANT lf_admin TO lf_admin_user;
GRANT lf_staff TO lf_staff_user;
GRANT lf_viewer TO lf_viewer_user;