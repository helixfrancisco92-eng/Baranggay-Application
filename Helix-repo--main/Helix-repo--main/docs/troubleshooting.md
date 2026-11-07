# Troubleshooting Guide: iBarangay
**COMP 018 – Database Administration | Activity 3 Specification**

This guide documents the common setup and runtime errors encountered during deployment and testing on different machines, along with their solutions.

---

### 1. `FATAL: password authentication failed for user "postgres"`
* **Cause**: The PostgreSQL superuser password on your machine does not match the password specified in `src/main/resources/application.properties`.
* **Solution**:
  1. Open `src/main/resources/application.properties`.
  2. Set `spring.datasource.password` to match your local PostgreSQL password:
     ```properties
     spring.datasource.password=YOUR_LOCAL_PASSWORD
     ```
  3. Re-run `start.bat`.

---

### 2. `FATAL: database "PPGG_projectdb" does not exist`
* **Cause**: The target database has not been created in PostgreSQL yet.
* **Solution**:
  * **Automated**: The application now includes an automated pre-check in `IbaranggayApplication.java` and `setup_and_start.bat` that automatically connects to the default `postgres` maintenance database and executes `CREATE DATABASE "PPGG_projectdb";` if missing.
  * **Manual Alternative**: Open pgAdmin or Command Prompt and run:
    ```cmd
    psql -U postgres -c "CREATE DATABASE \"PPGG_projectdb\";"
    ```

---

### 3. `Web server failed to start. Port 8080 was already in use`
* **Cause**: An earlier instance of the application or another service is already listening on port 8080.
* **Solution**:
  * **Automated**: Running `start.bat` or `setup_and_start.bat` automatically identifies and terminates any zombie process holding the configured port.
  * **Manual via PowerShell**:
    ```powershell
    Stop-Process -Id (Get-NetTCPConnection -LocalPort 8080).OwningProcess -Force
    ```
  * **Change Port**: You can change the port in `application.properties`:
    ```properties
    server.port=8084
    ```

---

### 4. `'psql' command not found in your PATH`
* **Cause**: PostgreSQL is installed in a non-standard location (e.g. `D:\Postgre\bin`) and not registered in the Windows `PATH` environment variable.
* **Solution**:
  * The provided batch files automatically detect `D:\Postgre\pg_env.bat` and `D:\Postgre\bin\psql.exe`.
  * To add permanently: Open Windows Environment Variables $\rightarrow$ edit `Path` under System variables $\rightarrow$ add `D:\Postgre\bin` (or your PostgreSQL installation path).

---

### 5. `IdentifierGenerationException: ids for this class must be manually assigned before calling save()`
* **Cause**: An entity model has `@Id` without `@GeneratedValue(strategy = GenerationType.IDENTITY)`.
* **Solution**:
  * Ensure all JPA Entity models (`Admin.java`, `Citizen.java`, `DocumentRequest.java`, `DocumentType.java`, `Requirement.java`, `RequestStatusHistory.java`) have `@GeneratedValue(strategy = GenerationType.IDENTITY)` above `@Id`.

---

### 6. `FlywayException: relation "public.admins" does not exist`
* **Cause**: Starting with an empty database when only migration `V2` is present.
* **Solution**:
  * Ensure `V1__initial_schema.sql` is present in `src/main/resources/db/migration` so that base tables are generated before `V2` applies structural modifications.
