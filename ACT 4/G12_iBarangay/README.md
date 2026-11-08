# iBarangay — Community Services Portal
**COMP 018 – Database Administration | Activity 3: From Database Design to a Working System**

---

## 📌 Project Overview
**iBarangay** is a web-based community services portal designed to automate and streamline local barangay document requests, resident registrations, and request tracking. It bridges citizens with barangay administrators, eliminating manual paperwork and physical queues.

---

## 🚀 Key Features
* **Automated Database Creation & Migration**: Powered by Flyway and Spring Boot, the PostgreSQL database and tables are created automatically on first run without manual SQL execution.
* **Document Services & Fee Calculation**: Online application for Barangay Clearance, Certificate of Indigency, Certificate of Residency, and Business Clearance.
* **Real-time Request Status Tracking**: Citizens can track document applications (`PENDING`, `PROCESSING`, `APPROVED`, `RELEASED`, `REJECTED`).
* **Resident / Citizen Management**: Full directory and registration of community members.
* **REST API Endpoints**: Modular backend exposing clean JSON endpoints for all resources.

---

## 🛠️ Technology Stack
* **Backend Framework**: Spring Boot 4.1.2 (Java 21 / 25)
* **ORM & Data**: Spring Data JPA / Hibernate
* **Database Platform**: PostgreSQL 16+
* **Database Migrations**: Flyway (Automated schema and seed data)
* **Frontend**: HTML5, CSS3, Bootstrap 5.3, Vanilla JavaScript (Fetch API)
* **Build Tool**: Apache Maven (via Maven Wrapper `mvnw`)

---

## 📋 Prerequisites
Before running the project on your machine, make sure you have:
1. **Java Development Kit (JDK 21 or higher)**
   * Download from: [Adoptium Eclipse Temurin](https://adoptium.net/)
2. **PostgreSQL 16 or higher**
   * Installed and running on default port `5432`.
   * Default superuser: `postgres`

---

## ⚙️ Quick Start (1-Click Run)

### Option A: Using the Windows Batch Launcher (Recommended)
1. Open the project root folder.
2. Double-click **`start.bat`** (or **`setup_and_start.bat`**).
   * It automatically detects your PostgreSQL path (`D:\Postgre` or `C:\Program Files\PostgreSQL`).
   * It automatically frees port 8080/8084 if previously in use.
   * It creates the PostgreSQL database `PPGG_projectdb` if it doesn't exist.
   * It compiles and launches the application.
3. Open your browser to: **[http://localhost:8084/](http://localhost:8084/)** (or `http://localhost:8080/`).

### Option B: Using Command Prompt / PowerShell
```bash
# 1. Navigate to the project directory
cd "E:\programming project\ibaranggay"

# 2. Run with Maven Wrapper
.\mvnw.cmd spring-boot:run
```

---

## 🗄️ Database Configuration
Database connection settings are located in:
`src/main/resources/application.properties`

```properties
# Server Port
server.port=8084

# PostgreSQL Database Configuration
spring.datasource.url=jdbc:postgresql://localhost:5432/PPGG_projectdb
spring.datasource.username=postgres
spring.datasource.password=YOUR_POSTGRES_PASSWORD

# JPA Configuration
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.show-sql=true

# Flyway Migration Configuration
spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration
spring.flyway.baseline-on-migrate=true
```

---

## 📡 REST API Documentation
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/citizens` | Retrieve all registered residents |
| `POST` | `/api/citizens` | Register a new resident |
| `GET` | `/api/document-types` | Retrieve available document clearances & fees |
| `GET` | `/api/document-requests` | Retrieve all filed document requests |
| `POST` | `/api/document-requests` | File a new document request |
| `PUT` | `/api/document-requests/{id}` | Update status or remarks of a request |
| `GET` | `/api/requirements` | Retrieve standard document prerequisites |
| `GET` | `/api/admins` | Retrieve barangay officials and staff |
| `GET` | `/api/request-status-history` | View status audit history log |

---

## 📂 Project Structure
```text
ibaranggay/
├── src/
│   ├── main/
│   │   ├── java/com/ibarangay/
│   │   │   ├── config/              # Application configurations
│   │   │   ├── controller/          # REST & Web MVC controllers
│   │   │   ├── dto/                 # Data Transfer Objects (Payloads & Responses)
│   │   │   ├── model/               # JPA Entity models (PostgreSQL tables)
│   │   │   ├── repository/          # Spring Data JPA repositories
│   │   │   ├── service/             # Business logic layer
│   │   │   └── IbaranggayApplication.java
│   │   └── resources/
│   │       ├── db/migration/        # Flyway SQL migrations (V1, V2, V3)
│   │       ├── static/              # Web portal frontend (index.html)
│   │       └── application.properties
│   └── test/
├── docs/                            # Activity 3 Documentation
│   ├── database-documentation.md
│   ├── user-roles.md
│   └── troubleshooting.md
├── .env.example                     # Environment template
├── start.bat                        # One-click startup script
├── setup_and_start.bat              # Setup and verification launcher
└── pom.xml                          # Maven dependencies
```
