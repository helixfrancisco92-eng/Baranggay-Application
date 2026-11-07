# iBarangay — Application User Roles & Database Role Mapping

**Project:** iBarangay – Barangay Document Request System  
**PostgreSQL Version:** 18.6  
**Application:** HTML, CSS, JavaScript, and Java  
**Database:** `PPGG_projectdb` 
**Schema:** `public`

---

## 1. Overview and Core Principle

iBarangay uses application user roles to control what each type of user can access and perform within the barangay system. These application roles are separate from PostgreSQL database roles, which determine what the application can access and modify directly in the database.

The system has three main application user groups:

- **Barangay Officials / Administrators** — manage barangay information, resident records, service requests, complaints, announcements, and other barangay transactions.
- **Barangay Staff** — assist in processing resident requests, documents, concerns, records, and assigned administrative transactions.
- **Barangay Citizens / Residents** — access barangay services, submit document requests and concerns, view announcements, and monitor their transactions.

The database includes an `admins` table with a `role` column for identifying administrative account roles, and a `citizens` table for storing resident information. However, the current database structure does not define a complete citizen login-account structure or a password/password-hash column for administrator accounts. These authentication details must be defined before all user groups can be considered fully supported for login.

End users do not need individual PostgreSQL accounts. Instead, the application can connect to PostgreSQL through one dedicated service account. The application authenticates each person and enforces application-level permissions, while PostgreSQL limits the service account to the database operations required by the system.

**Core security principle:** Role checks must be performed on the server for every protected page and action. Hiding a button in the browser is not sufficient. The server must reject unauthorized requests even when a user manually enters a URL or sends a direct request.

---

## 2. Application and Database Role Mapping Matrix

The following matrix describes the intended access policy. The exact values stored in `admins.role` must match the values checked by the application. The values `admin` and `staff` are suggested examples and are not confirmed values in the current database.

| Application Role | Responsibilities | Application Functions and Data Access | Database Role Mapping |
|---|---|---|---|
| **Barangay Official / Administrator** (`admin`, suggested) | Oversees barangay operations and manages barangay information and administrative transactions. | Manage resident records; manage document types and requirements; view and manage document requests; approve or reject requests; record processing remarks; manage administrative accounts where supported; manage announcements and barangay information where those modules are implemented. | Uses the shared application database service account, proposed as `ibarangay_app`, through `ibarangay_runtime_grp`. Administrator-specific restrictions are enforced by the application. |
| **Barangay Staff** (`staff`, suggested) | Assists with day-to-day processing of resident requests, documents, records, and assigned concerns. | View resident information needed for processing; review document requests and requirements; update request processing information and status history when authorized; assist with records and transactions assigned to them. Access to sensitive administrative account management and system-wide configuration should be restricted. | Uses the shared application database service account, `ibarangay_app`, through `ibarangay_runtime_grp`. Staff-specific restrictions are enforced by the application. |
| **Barangay Citizen / Resident** (`citizen` or `resident`, suggested) | Uses the portal to access barangay services and monitor personal transactions. | View available document types and requirements; submit document requests; view the status and history of their own requests; submit concerns where that module is implemented; view public announcements and barangay information. A resident must not view or modify another resident's private records. | Uses the shared application database service account, `ibarangay_app`, through `ibarangay_runtime_grp`. Resident-specific restrictions and ownership checks are enforced by the application. |
| **Application Runtime** *(System Account)* | Connects the application to PostgreSQL and performs approved database operations on behalf of signed-in users. | Reads records needed by the application; creates citizen and request records; reads document types and requirements; records request processing and status history; performs only the operations granted to the runtime account. | `ibarangay_app` *(member of `ibarangay_runtime_grp`)*. |

**Role-mapping note:** Administrator, Staff, and Citizen/Resident are application roles, not separate PostgreSQL login accounts in this proposed setup. When all users connect through the same backend database service account, PostgreSQL identifies the service account rather than the individual user. Therefore, the application backend must enforce the different permissions for each user role.

**Database scope limitation:** The current database contains seven tables: `citizens`, `admins`, `document_types`, `requirements`, `document_type_requirements`, `document_requests`, and `request_status_history`. Complaints, announcements, and citizen login credentials are not represented by separate tables in this database structure. Those features require additional database design if they are to be fully implemented and stored by the system.

---

## 3. Detailed Application User Roles

### 3.1 Barangay Official / Administrator

- **Role Purpose:** Oversees barangay operations and manages barangay information, resident records, document services, and administrative transactions.
- **Application Capabilities:**
  - **Resident Management:** View, register, and maintain resident records in the `citizens` table.
  - **Document Type Management:** Manage available document types, descriptions, processing periods, fees, and active status in `document_types`.
  - **Requirement Management:** Manage the requirements stored in `requirements` and their associations in `document_type_requirements`.
  - **Request Management:** View submitted document requests and their details in `document_requests`.
  - **Request Processing:** Approve or reject requests and record the responsible administrator, processing date, and remarks where applicable.
  - **Status History:** Ensure that request status changes are recorded in `request_status_history`.
  - **Administrative Accounts:** Manage authorized administrative accounts where the application provides this function. Account-management permissions must be protected.
  - **Information Management:** Manage announcements and other barangay information if those modules and their database structures are implemented.
  - **Record Integrity:** Preserve request and status-history records needed for transaction tracking and accountability.

### 3.2 Barangay Staff

- **Role Purpose:** Assists with authorized day-to-day barangay operations and the processing of resident requests.
- **Application Capabilities:**
  - **Resident Information:** View resident information required to verify and process requests.
  - **Request Review:** View submitted document requests, requested document types, purposes, and relevant request details.
  - **Requirements Checking:** Review the requirements associated with a requested document type.
  - **Request Processing:** Perform only the processing actions assigned or permitted by the barangay administrator.
  - **Status Recording:** Record authorized status changes and processing remarks in the request workflow. Each status-history entry must be associated with the responsible administrative account as supported by the database design.
  - **Transaction Monitoring:** Track request progress and identify requests that need attention.
  - **Restricted Administration:** Cannot change database credentials, PostgreSQL permissions, or protected system configuration. Access to administrative account management and master-data maintenance should be limited according to the permissions established for the system.

### 3.3 Barangay Citizen / Resident

- **Role Purpose:** Provides residents with a convenient way to access barangay services and monitor their own requests.
- **Application Capabilities:**
  - **View Barangay Services:** View available and active document types and their descriptions.
  - **View Requirements:** Check the requirements associated with a document type before submitting a request.
  - **Submit Document Requests:** Submit a request by selecting a document type and providing the required information.
  - **Track Requests:** View the status and progress of submitted document requests.
  - **View Request History:** Access the status history of personal requests, but not the private request history of other residents.
  - **Submit Concerns:** Submit concerns or complaints if the corresponding application module is implemented.
  - **View Announcements:** Read public barangay announcements and information if the corresponding module is implemented.
  - **Data Privacy:** View and manage only the resident's own information and transactions, subject to the functions provided by the application.

### 3.4 Application Runtime (System Account)

- **Role Purpose:** Provides the connection between the iBarangay application and the PostgreSQL database.
- **Responsibilities:**
  - Connect to the confirmed project database using a dedicated PostgreSQL login account.
  - Read records required by the application's functions.
  - Insert and update records only where the database permissions allow those operations.
  - Record document request status changes in the status-history table.
  - Avoid using a PostgreSQL superuser account for normal application operations.
  - Rely on the application backend to enforce the signed-in user's role and record ownership.

---

## 4. Intended PostgreSQL Database RBAC Setup

The PostgreSQL database roles provide a second layer of access control. The recommended setup uses a non-login group role for permissions and a dedicated login role for the application.

iBarangay follows the **Principle of Least Privilege**: the application database account should receive only the permissions required to run the implemented system.

The SQL below is a proposed example of a database-role setup. It creates PostgreSQL roles and grants permissions; it does **not** add, remove, or change any iBarangay tables or columns.

**Before running these statements:**

1. Confirm that the database is named `PPGG_projectdb`.
2. Confirm that all seven tables exist in the `public` schema: `citizens`, `admins`, `document_types`, `requirements`, `document_type_requirements`, `document_requests`, and `request_status_history`.
3. Review the application code and confirm which operations each module performs. Adjust the grants to match the implemented features.
4. Run the role-creation statements only once. If a role already exists, do not create it again.
5. Run these commands using a PostgreSQL account allowed to create roles and grant privileges.
6. Replace the sample password with a strong local password. Never commit the real password to Git.
7. The grants below apply to a shared runtime account. They do not replace application-level authorization checks.

### 4.1 Database Group Role (`NOLOGIN`)

```sql
-- Group role for the iBarangay application's database permissions.
CREATE ROLE ibarangay_runtime_grp WITH NOLOGIN;
```

### 4.2 Database Permissions

Connect to the confirmed project database before running these grants. The following example assumes the database is named `PPGG_projectdb`.

```sql
-- Allow the application group to connect to the database
-- and use the public schema.
GRANT CONNECT ON DATABASE "PPGG_projectdb" TO ibarangay_runtime_grp;
GRANT USAGE ON SCHEMA public TO ibarangay_runtime_grp;

-- Read the records needed by the application.
GRANT SELECT ON
    public.citizens,
    public.admins,
    public.document_types,
    public.requirements,
    public.document_type_requirements,
    public.document_requests,
    public.request_status_history
TO ibarangay_runtime_grp;

-- Create resident and document-request records.
GRANT INSERT ON
    public.citizens,
    public.document_requests
TO ibarangay_runtime_grp;

-- Update resident and request information when required
-- by the application's authorized workflows.
GRANT UPDATE ON
    public.citizens,
    public.document_requests
TO ibarangay_runtime_grp;

-- Record request status changes.
GRANT INSERT ON
    public.request_status_history
TO ibarangay_runtime_grp;
```

**Purpose of the permissions:**

- `citizens`: The application needs to read resident information and may need to register or update resident records.
- `admins`: The application needs to read administrative account information for the administrative workflow. The current table structure does not show a password field.
- `document_types`: The application needs to display available document services and their descriptions, fees, processing periods, and active status.
- `requirements`: The application needs to display the requirements for each document type.
- `document_type_requirements`: The application needs to retrieve the requirements associated with each document type.
- `document_requests`: The application needs to create requests, display request details, and update request processing information.
- `request_status_history`: The application needs to record and display request status changes.

**Important limitations:**

- These grants apply to the shared application database account. They do not distinguish Administrator, Staff, and Citizen/Resident permissions. The backend must enforce those application roles and verify that residents can access only their own records.
- The example does not grant `DELETE` on document requests or status history. This helps preserve transaction and processing history.
- The example does not grant `INSERT` or `UPDATE` on `admins`, `document_types`, `requirements`, or `document_type_requirements`. If the implemented administrator interface must manage these records, review and add only the necessary privileges.
- If the application does not allow public registration and resident records are created by authorized staff, remove `INSERT` on `citizens` from the runtime role.
- Before using these example grants in a deployed environment, check them against the actual database schema and application code.

### 4.3 Database Login Account (`LOGIN`)

```sql
-- Create a dedicated login account for the iBarangay application.
CREATE ROLE ibarangay_app WITH LOGIN PASSWORD 'CHANGE_THIS_PASSWORD';

-- Give the application account the permissions of the group role.
GRANT ibarangay_runtime_grp TO ibarangay_app;
```

The application's database connection should use `ibarangay_app` and the password set locally. The password must be kept outside the public Git repository.

### 4.4 Important Notes About IDs and Sequences

The primary-key columns are defined using `GENERATED ALWAYS AS IDENTITY` in the database design. The actual database definitions must be checked before adding sequence grants or changing ID-generation settings. Additional sequence permissions should not be assumed or applied broadly without verifying the PostgreSQL setup.

---

## 5. Existing Database Tables Used by iBarangay

The iBarangay database consists of the following seven tables:

| Existing Table | Purpose in iBarangay | Main Access Needed by the Application |
|---|---|---|
| `citizens` | Stores resident identity and contact information. | `SELECT`, `INSERT`, and, where supported, `UPDATE`. |
| `admins` | Stores administrator/staff information, username, role, active status, and account creation date. | `SELECT`; account-management permissions should be reviewed separately. |
| `document_types` | Stores the types of barangay documents, descriptions, processing days, fees, and active status. | `SELECT`; administrative maintenance permissions should be reviewed separately. |
| `requirements` | Stores the requirements that may be needed for barangay documents. | `SELECT`; administrative maintenance permissions should be reviewed separately. |
| `document_type_requirements` | Connects document types and requirements through a many-to-many relationship and indicates whether a requirement is required. | `SELECT`; administrative maintenance permissions should be reviewed separately. |
| `document_requests` | Stores each resident's document request, requested document type, date, purpose, status, remarks, and processing/release details. | `SELECT`, `INSERT`, and `UPDATE` for authorized workflows. |
| `request_status_history` | Stores request status changes, the administrative account associated with the change, timestamps, and remarks. | `SELECT` and `INSERT`; ordinary deletion should be avoided. |

**Database structure rule:** The user-role plan does not require any table or column changes. The existing seven-table database schema should remain unchanged unless a separate database-design update is approved and documented.

**Scope note:** Complaints and incident reports, announcements and information, and broader barangay records are also identified as application features. However, the seven-table relational schema does not represent those features through separate tables. Permissions should not be granted on tables that do not yet exist.

---

## 6. Security and Credential Isolation

1. **Password Storage:** Plain-text passwords must never be stored. The current `admins` table structure lists `username` and `role` but does not list a password or password-hash column. A secure authentication design must be defined before administrator/staff login is implemented. The current `citizens` table also does not define citizen login credentials.
2. **Application Role Checks:** After successful authentication, the application must identify the user's role and check it on the server for every restricted page and action. Hidden buttons or menu items alone do not provide security.
3. **Resident Record Ownership:** Residents must be able to view only their own requests and personal information. The backend must verify record ownership on every request-detail and history action.
4. **Database Account:** A dedicated, least-privilege account such as `ibarangay_app` should be used for the application. The PostgreSQL `postgres` superuser account should not be used for normal runtime operations.
5. **Prepared Statements:** Parameterized queries or prepared statements should be used for database operations to help prevent SQL injection.
6. **Session Protection:** A valid login session must be required before protected modules can be accessed. Sessions should be destroyed upon logout and protected against unauthorized access.
7. **Credential Safety:** Real database passwords, private configuration files, and production credentials must never be committed to GitHub. Example configuration files should use placeholders.
8. **Record Integrity:** Document requests and request status-history records should not be casually deleted. Processing history should be preserved for tracking and accountability.
9. **Status Validation:** The application should accept only the request statuses defined by the database design: `PENDING`, `APPROVED`, `REJECTED`, `READY`, `RELEASED`, and `CANCELLED`.
10. **Rejection Remarks:** A rejected request must contain a reason or remark, consistent with the stated business rule and the `chk_rejected_has_remarks` constraint in the sample SQL definition.
11. **Authorized Processing:** Only authorized administrators or staff should process requests and change their status. Each status change should be recorded with the responsible administrative account ID.
12. **Credential Separation:** Application login credentials must remain separate from PostgreSQL connection credentials. Residents and staff must never receive the database service-account password.

---

## 7. Implementation Status and Verification

This document describes the intended application role policy and a suggested PostgreSQL permission setup. It does not mean that every role restriction or database permission has already been implemented.

The following items must be verified before the role policy can be considered fully implemented:

- The actual project database name is confirmed and consistent across the application configuration and SQL scripts.
- All seven tables exist in the `public` schema.
- The values in `admins.role` match the role values checked by the backend.
- A secure method for storing and verifying administrator and staff passwords has been defined.
- The method of citizen authentication has been defined, or citizen access has been documented as not yet login-based.
- Administrator-only actions are enforced on the server, not only hidden in the interface.
- Staff cannot access restricted administrative actions by manually entering a URL or sending a direct request.
- Residents can access only their own personal information, document requests, and request history.
- Request approval, rejection, and other status changes are restricted to authorized users.
- Rejected requests require a reason or remark.
- Each request status change is recorded in `request_status_history` with the responsible administrative account.
- The application database configuration uses the intended dedicated runtime account rather than the PostgreSQL superuser account.
- PostgreSQL grants match the operations performed by the actual application code.
- Ordinary application functions cannot delete document requests or request status-history records.

**Database-name verification note:** The database plan identifies `PPGG_projectdb`, while the sample SQL setup shows `CREATE DATABASE grp_ibarangaydb;`. The actual database name must be confirmed and used consistently. A second database should not be created solely to match this document.

**Schema verification note:** The database setup reports seven tables in the `public` schema with primary and foreign keys. Its verification results did not find `UNIQUE`, business-rule `CHECK`, or column `DEFAULT` constraints at that point, while the later sample SQL definition includes examples of such constraints. The current database must be checked directly before assuming that every constraint in the sample SQL has already been applied.
